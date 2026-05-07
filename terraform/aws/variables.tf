variable "cloud_provider" {
  type    = string
  default = "aws"
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
  default = "us-east-1"
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

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "db_backup_retention" {
  type    = number
  default = 7
}

variable "az_count" {
  type    = number
  default = 2
}
