variable "environment" {
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
