variable "environment" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "oidc_provider" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "vault_kms_key_arn" {
  type = string
}

variable "ecr_repository_arn" {
  type    = string
  default = "*"
}
