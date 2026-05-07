variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "vault_irsa_role_arn" {
  type    = string
  default = ""
}
