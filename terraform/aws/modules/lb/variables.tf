variable "environment" {
  type = string
}

variable "region" {
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

variable "cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_controller_role_arn" {
  type    = string
  default = ""
}
