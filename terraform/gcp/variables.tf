variable "cloud_provider" {
  type    = string
  default = "gcp"
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "project_id" {
  type = string
}

variable "enable_nginx_ingress" {
  type    = bool
  default = true
}

variable "enable_cloud_lb" {
  type    = bool
  default = false
}

variable "backend_type" {
  type    = string
  default = "remote"
}

variable "enable_bastion" {
  type    = bool
  default = true
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

variable "master_ipv4_cidr" {
  type    = string
  default = "172.16.0.0/28"
}
