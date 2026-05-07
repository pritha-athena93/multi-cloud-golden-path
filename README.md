# Multi-Cloud Golden Path

Production-grade Kubernetes infrastructure on AWS (EKS) or GCP (GKE) via Terraform, GitOps delivery via ArgoCD, and a Python demo app shipped through GitHub Actions CI/CD.

## What's Inside

| Layer | Tech |
|---|---|
| Infrastructure | Terraform (AWS EKS / GCP GKE), VPC, KMS, RDS/CloudSQL, ECR/Artifact Registry |
| Autoscaling | Karpenter (AWS), GKE native node autoscaling (GCP) |
| GitOps | ArgoCD + ArgoCD Image Updater |
| Secrets | HashiCorp Vault (KMS auto-unseal, Kubernetes auth, KV v2) |
| TLS | cert-manager + Let's Encrypt |
| Ingress | NGINX ingress controller (optional AWS ALB / GCP GLB) |
| Monitoring | kube-prometheus-stack + Loki |
| App | FastAPI + uvicorn, distroless container, Vault-injected secrets |
| CI/CD | GitHub Actions — OIDC auth, Trivy, tfsec, checkov |
| Security | Pod Security Standards (restricted), default-deny NetworkPolicy, IRSA/Workload Identity |

---

## Prerequisites

- Terraform >= 1.7.0
- AWS CLI (for AWS path) or `gcloud` CLI (for GCP path)
- `kubectl`
- `helm` >= 3.x
- `argocd` CLI (for manual operations)
- A GitHub repo forked/cloned from this one with Actions enabled
- For AWS: an AWS account with permissions to create IAM, EKS, VPC, RDS, KMS, ECR
- For GCP: a GCP project with APIs enabled: `container`, `sqladmin`, `cloudkms`, `artifactregistry`, `servicenetworking`, `iap`

---

## Quick Start

### 0. Clone and Configure

```bash
git clone https://github.com/pritha-athena93/multi-cloud-golden-path.git
cd multi-cloud-golden-path
```

#### AWS profile setup

```bash
# Configure a named profile (interactive)
aws configure --profile my-org

# Or export for the current shell session
export AWS_PROFILE=my-org
export AWS_REGION=us-east-1

# Verify
aws sts get-caller-identity --profile my-org
```

Replace `<account>` placeholders (your 12-digit AWS account ID) in workflow files and backend configs:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# macOS
grep -rl '<account>' .github/ terraform/aws/ | xargs sed -i '' "s/<account>/${AWS_ACCOUNT_ID}/g"

# Linux
grep -rl '<account>' .github/ terraform/aws/ | xargs sed -i "s/<account>/${AWS_ACCOUNT_ID}/g"
```

#### GCP project setup

```bash
# Authenticate
gcloud auth login
gcloud auth application-default login

# Set active project
gcloud config set project MY_GCP_PROJECT
export GOOGLE_CLOUD_PROJECT=MY_GCP_PROJECT

# Enable required APIs (one-time per project)
gcloud services enable \
  container.googleapis.com \
  sqladmin.googleapis.com \
  cloudkms.googleapis.com \
  artifactregistry.googleapis.com \
  servicenetworking.googleapis.com \
  iap.googleapis.com

# Verify
gcloud config list
```

Manually replace `<project>` with your GCP project ID in these files:

- `.github/workflows/tf-plan.yml`
- `.github/workflows/tf-apply.yml`
- `.github/workflows/docker-build.yml`
- `helm/demo-app/values.yaml`

These are GitHub Actions and Helm files — Terraform variables don't apply to them, so the project ID must be set directly.

---

### 1. Bootstrap State Backend (run once per account)

**AWS:**
```bash
cd terraform/bootstrap/aws
terraform init
terraform apply -var="state_bucket_name=my-org-tf-state-aws"
```

**GCP:**
```bash
cd terraform/bootstrap/gcp
terraform init
terraform apply \
  -var="project_id=my-gcp-project" \
  -var="state_bucket_name=my-org-tf-state-gcp"
```

After bootstrap, update `<account>`, `<key-id>`, and `<project>` placeholders in `terraform/aws/backends/*.hcl` and `terraform/gcp/backends/*.hcl`.

---

### 2. Provision Infrastructure

**AWS:**
```bash
cd terraform/aws
terraform init -backend-config=backends/dev.hcl
terraform apply -var-file=environments/dev.tfvars
```

**GCP:**
```bash
cd terraform/gcp
terraform init -backend-config=backends/dev.hcl
terraform apply -var-file=environments/dev.tfvars -var="project_id=my-gcp-project"
```

This provisions: VPC, EKS/GKE cluster, IAM/service accounts, KMS keys, RDS/CloudSQL, ECR/Artifact Registry, cert-manager, and ArgoCD.

---

### 3. Configure kubectl

**AWS:**
```bash
aws eks update-kubeconfig --name dev-eks-cluster --region us-east-1
```

**GCP:**
```bash
gcloud container clusters get-credentials dev-gke-cluster \
  --region us-central1 --project my-gcp-project
```

### 3a. Whitelisting IPs for Private GKE API Access (GCP)

The GKE control plane uses a private endpoint only (`enable_private_endpoint = true`). `kubectl` must originate from a CIDR in `master_authorized_networks_config` — the bastion subnet (`10.0.0.0/24`) is whitelisted by default via Terraform.

**To add additional CIDRs** (e.g. another bastion, VPN CIDR), edit `master_authorized_cidr_blocks` in [terraform/gcp/main.tf](terraform/gcp/main.tf):

```hcl
module "gke" {
  ...
  master_authorized_cidr_blocks = [
    module.vpc.public_subnet_cidr,  # bastion subnet — always include
    "10.100.0.0/24",                # example: additional VPN subnet
  ]
}
```

Then apply:
```bash
cd terraform/gcp
terraform apply -var-file=environments/dev.tfvars -var="project_id=<your-project>"
```

**To reach the cluster via IAP SSH tunnel through the bastion:**

```bash
# Terminal 1 — SSH to bastion with dynamic SOCKS5 port forwarding on local port 8888
# -D 8888 opens a SOCKS5 proxy; -N skips executing a remote command
gcloud compute ssh dev-bastion \
  --tunnel-through-iap \
  --zone=us-central1-a \
  -- -D 8888 -N
```

```bash
# Terminal 2 — point kubectl at the SOCKS5 proxy, then fetch credentials
export HTTPS_PROXY=socks5://localhost:8888
gcloud container clusters get-credentials dev-gke-cluster \
  --region us-central1 --project <your-project>

# Verify
kubectl get nodes
```

Keep Terminal 1 open for the duration of your session. The bastion originates traffic from `10.0.0.0/24`, which is already in `master_authorized_networks_config`.

---

### 3b. Install cert-manager and ArgoCD (GCP — must run via IAP tunnel)

The GKE cluster uses a private endpoint only. Helm cannot reach it from your local machine. Run these after opening the IAP tunnel (Step 3a):

```bash
# cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version 1.14.4 \
  -f helm/cert-manager/values.yaml

# ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --version 6.7.3 \
  -f helm/argocd/install/values.yaml

# NGINX ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --version 4.10.1 \
  --set controller.service.type=LoadBalancer
```

---

### 4. Apply ArgoCD Applications

Replace `<org>` with your GitHub org in all `helm/argocd/apps/*.yaml` files, then:

```bash
kubectl apply -f helm/argocd/apps/cert-manager-app.yaml
kubectl apply -f helm/argocd/apps/vault-app.yaml
kubectl apply -f helm/argocd/apps/monitoring-app.yaml
kubectl apply -f helm/argocd/apps/demo-app-appset.yaml
kubectl apply -f helm/argocd/apps/image-updater-app.yaml
```

ArgoCD will deploy Vault → Vault auto-unseals via KMS → Vault auth-backend Job runs → demo-app starts automatically.

---

### 5. Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080
# Get initial admin password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

## Environment Configuration

Each cloud has three environments with separate Terraform state keys and sizing:

| | dev | staging | prod |
|---|---|---|---|
| Nodes (AWS) | t3.medium 1–3 | m5.large 2–5 | m5.xlarge 3–10 |
| Nodes (GCP) | e2-medium 1–3 | n2-standard-2 2–5 | n2-standard-4 3–10 |
| DB HA | No | Yes | Yes |
| DB backup | 7d | 14d | 30d |
| Deletion protection | No | No | Yes |
| NAT GW | 1 | 1 per AZ | 1 per AZ |
| Vault HA | No | Yes (3 replicas) | Yes (3 replicas) |
| ArgoCD auto-sync | Yes | Yes | Manual gate |

To deploy a different environment:
```bash
terraform init -backend-config=backends/prod.hcl
terraform apply -var-file=environments/prod.tfvars
```

**Production requires GitHub environment approval** — configure a GitHub Actions environment named `prod` with required reviewers to gate `tf-apply.yml`.

---

## Workload Type: Deployment vs StatefulSet

The demo-app Helm chart supports both:

```yaml
# helm/demo-app/values.yaml
workloadType: deployment   # default
# or
workloadType: statefulset  # requires persistence.enabled: true
```

StatefulSet without persistence fails at render time (`helm template` will error). This is intentional.

---

## Vault Cold-Start Flow

No manual intervention required after `terraform apply`:

```
terraform apply
  → RDS/CloudSQL created with random password
  → bootstrap K8s Secret written to vault namespace

ArgoCD deploys Vault
  → Vault auto-unseals via KMS (AWS KMS or GCP Cloud KMS)
  → auth-backend Job:
      reads bootstrap K8s Secret
      writes DB creds to Vault KV (secret/demo-app/db)
      deletes bootstrap K8s Secret

ArgoCD deploys demo-app
  → init container waits for Vault unsealed + secret present
  → Vault agent sidecar injects /vault/secrets/db.env
  → app starts
```

After first boot, rotate the Vault init keys stored in `vault-init-keys` secret:
```bash
kubectl get secret vault-init-keys -n vault -o json
# Store root token and recovery keys in a secure location, then delete the secret
kubectl delete secret vault-init-keys -n vault
```

---

## CI/CD Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `tf-plan.yml` | PR touching `terraform/**` | fmt, validate, tfsec, checkov, plan (both clouds), posts plan to PR |
| `tf-apply.yml` | Push to main touching `terraform/**` | Applies changed cloud for detected environment |
| `docker-build.yml` | Push to main touching `docker/**` | Multi-stage build, Trivy scan, push to ECR/Artifact Registry |
| `image-tag-update.yml` | After docker-build succeeds | Updates `helm/demo-app/values.yaml` with new SHA tag, opens PR |
| `argocd-sync.yml` | Push to main touching `helm/**` | Syncs dev + staging ArgoCD apps |

### GitHub Secrets Required

| Secret | Used by |
|---|---|
| `ARGOCD_SERVER` | `argocd-sync.yml` |
| `ARGOCD_TOKEN` | `argocd-sync.yml` |
| `BOT_GITHUB_TOKEN` | `image-tag-update.yml` (needs `contents: write`) |

### GitHub Variables Required

| Variable | Value |
|---|---|
| `CLOUD_PROVIDER` | `aws` or `gcp` |

### OIDC Setup (Recommended over static keys)

**AWS:** Create an IAM OIDC provider for `token.actions.githubusercontent.com` and two roles:
- `github-actions-tf-plan` — read-only Terraform permissions + state read
- `github-actions-tf-apply` — full Terraform permissions + state write
- `github-actions-ecr-push` — `ecr:GetAuthorizationToken` + push to ECR repo

**GCP:** Configure Workload Identity Federation for GitHub Actions and create service accounts:
- `github-actions-tf` — `roles/editor` (or fine-grained) + storage objectAdmin on state bucket
- `github-actions-registry` — `roles/artifactregistry.writer`

Replace `<account>`, `<num>`, `<pool>`, `<provider>`, `<project>` placeholders in the workflow files.

---

## Customization

### Use a Custom Domain

1. Update `helm/argocd/install/values.yaml`: replace `argocd.example.com`
2. Update `helm/cert-manager/templates/cluster-issuer.yaml`: replace `platform@example.com`
3. Update `helm/demo-app/values.yaml`: replace `demo-app.example.com`
4. Update `helm/monitoring/values.yaml`: replace `grafana.example.com`
5. Point DNS to the load balancer IP after deployment

### Change Cloud Region

AWS: Edit `region` in `terraform/aws/environments/*.tfvars` and `backends/*.hcl`

GCP: Edit `region` in `terraform/gcp/environments/*.tfvars` and `backends/*.hcl`

### Enable GCP Global Load Balancer

```hcl
# terraform/gcp/environments/prod.tfvars
enable_cloud_lb = true
```

### Disable Bastion

```hcl
enable_bastion = false
```

### Access Bastion

**AWS (SSM — no SSH key, no port 22):**
```bash
aws ssm start-session --target <instance-id>
```

**GCP (IAP tunnel — no public IP):**
```bash
gcloud compute ssh dev-bastion --tunnel-through-iap --zone us-central1-a
```

---

## Security Notes

- All nodes in private subnets. EKS/GKE API endpoint private-only.
- Secrets encrypted at rest via KMS (distinct keys per service).
- Vault is the sole secret store for application credentials. Bootstrap K8s Secret deleted after Vault initialization.
- Pod Security Standards `restricted` enforced on all app namespaces.
- Default-deny NetworkPolicy on every app namespace; per-app allowlist in `helm/demo-app/templates/networkpolicy.yaml`.
- Container runs as UID 1000, non-root, read-only root filesystem, all capabilities dropped.
- Images use distroless base. Trivy blocks CRITICAL CVEs before push.
- IRSA (AWS) / Workload Identity (GCP) for workload-to-cloud authentication — no static credentials in pods.
- tfsec + checkov gate PRs on HIGH/CRITICAL Terraform findings.

---

## Out of Scope

- DNS / Route53 / Cloud DNS zone management (configure externally, then set hostnames)
- Multi-region / disaster recovery
- Service mesh (Istio / Linkerd)
- Cost management tooling
