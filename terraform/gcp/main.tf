terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.20"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.25"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  load_config_file       = false
}

module "kms" {
  source      = "./modules/kms"
  environment = var.environment
  region      = var.region
  project_id  = var.project_id
}

module "vpc" {
  source      = "./modules/vpc"
  environment = var.environment
  region      = var.region
  project_id  = var.project_id
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment
  project_id  = var.project_id
}

module "gke" {
  source           = "./modules/gke"
  environment      = var.environment
  region           = var.region
  project_id       = var.project_id
  gke_version      = var.gke_version
  node_machine_type = var.node_machine_type
  node_min         = var.node_min
  node_max         = var.node_max
  private_subnet_id = module.vpc.private_subnet_id
  master_ipv4_cidr = var.master_ipv4_cidr
  kms_key_id       = module.kms.gke_key_id
  node_sa_email    = module.iam.node_sa_email
}

module "artifact_registry" {
  source      = "./modules/artifact_registry"
  environment = var.environment
  region      = var.region
  project_id  = var.project_id
  node_sa_email = module.iam.node_sa_email
}

module "cloudsql" {
  source            = "./modules/cloudsql"
  environment       = var.environment
  region            = var.region
  project_id        = var.project_id
  private_network   = module.vpc.vpc_id
  kms_key_id        = module.kms.cloudsql_key_id
  depends_on        = [module.gke]
}

module "lb" {
  source               = "./modules/lb"
  environment          = var.environment
  enable_nginx_ingress = var.enable_nginx_ingress
  enable_cloud_lb      = var.enable_cloud_lb
  depends_on           = [module.gke]
}

module "bastion" {
  count        = var.enable_bastion ? 1 : 0
  source       = "./modules/bastion"
  environment  = var.environment
  region       = var.region
  project_id   = var.project_id
  subnet_id    = module.vpc.public_subnet_id
  bastion_sa_email = module.iam.bastion_sa_email
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.14.4"
  namespace        = "cert-manager"
  create_namespace = true
  values           = [file("${path.module}/../../helm/cert-manager/values.yaml")]
  depends_on       = [module.gke]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "6.7.3"
  namespace        = "argocd"
  create_namespace = true
  depends_on       = [helm_release.cert_manager]
  values           = [file("${path.module}/../../helm/argocd/install/values.yaml")]
}
