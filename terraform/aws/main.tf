terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
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

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = "multi-cloud-golden-path"
    }
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

module "kms" {
  source      = "./modules/kms"
  environment = var.environment
  region      = var.region
}

module "vpc" {
  source               = "./modules/vpc"
  environment          = var.environment
  region               = var.region
  az_count             = var.az_count
  enable_single_nat_gw = var.environment == "dev"
}

module "iam" {
  source           = "./modules/iam"
  environment      = var.environment
  cluster_name     = "${var.environment}-eks-cluster"
  oidc_provider    = module.eks.oidc_provider
  oidc_provider_arn = module.eks.oidc_provider_arn
  vault_kms_key_arn = module.kms.vault_key_arn
  ecr_repository_arn = module.ecr.repository_arn
}

module "eks" {
  source              = "./modules/eks"
  environment         = var.environment
  region              = var.region
  eks_version         = var.eks_version
  node_instance_types = var.node_instance_types
  node_min            = var.node_min
  node_max            = var.node_max
  private_subnet_ids  = module.vpc.private_subnet_ids
  secrets_kms_key_arn = module.kms.eks_key_arn
  node_role_arn       = module.iam.node_role_arn
}

module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  node_role_arn = module.iam.node_role_arn
}

module "rds" {
  source              = "./modules/rds"
  environment         = var.environment
  isolated_subnet_ids = module.vpc.isolated_subnet_ids
  security_group_id   = module.vpc.sg_rds_id
  kms_key_arn         = module.kms.rds_key_arn
  db_instance_class   = var.db_instance_class
  db_multi_az         = var.db_multi_az
  db_backup_retention = var.db_backup_retention
  depends_on          = [module.eks]
}

module "lb" {
  source               = "./modules/lb"
  environment          = var.environment
  region               = var.region
  enable_nginx_ingress = var.enable_nginx_ingress
  enable_cloud_lb      = var.enable_cloud_lb
  cluster_name         = module.eks.cluster_name
  vpc_id               = module.vpc.vpc_id
  alb_controller_role_arn = module.iam.alb_controller_role_arn
  depends_on           = [module.eks]
}

module "autoscaler" {
  source          = "./modules/autoscaler"
  environment     = var.environment
  region          = var.region
  cluster_name    = module.eks.cluster_name
  private_subnet_ids = module.vpc.private_subnet_ids
  node_role_arn   = module.iam.node_role_arn
  karpenter_role_arn = module.iam.karpenter_role_arn
  depends_on      = [module.eks]
}

module "bastion" {
  count           = var.enable_bastion ? 1 : 0
  source          = "./modules/bastion"
  environment     = var.environment
  public_subnet_id = module.vpc.public_subnet_ids[0]
  security_group_id = module.vpc.sg_bastion_id
  instance_profile_name = module.iam.bastion_instance_profile_name
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "1.14.4"
  namespace        = "cert-manager"
  create_namespace = true
  values           = [file("${path.module}/../../helm/cert-manager/values.yaml")]
  depends_on       = [module.eks]
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
