variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "project_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "bastion_sa_email" {
  type = string
}

variable "iap_members" {
  type    = list(string)
  default = []
}
