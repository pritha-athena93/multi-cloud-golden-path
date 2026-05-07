variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_role_arn" {
  type = string
}

variable "karpenter_role_arn" {
  type = string
}
