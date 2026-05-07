variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "eks_version" {
  type    = string
  default = "1.29"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_min" {
  type    = number
  default = 1
}

variable "node_max" {
  type    = number
  default = 3
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "secrets_kms_key_arn" {
  type = string
}

variable "node_role_arn" {
  type = string
}
