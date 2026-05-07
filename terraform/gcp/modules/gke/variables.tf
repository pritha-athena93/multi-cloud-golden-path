variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "project_id" {
  type = string
}

variable "gke_version" {
  type    = string
  default = "1.29"
}

variable "node_machine_type" {
  type    = string
  default = "e2-medium"
}

variable "node_min" {
  type    = number
  default = 1
}

variable "node_max" {
  type    = number
  default = 3
}

variable "private_subnet_id" {
  type = string
}

variable "vpc_name" {
  type    = string
  default = ""
}

variable "master_ipv4_cidr" {
  type    = string
  default = "172.16.0.0/28"
}

variable "kms_key_id" {
  type = string
}

variable "node_sa_email" {
  type = string
}
