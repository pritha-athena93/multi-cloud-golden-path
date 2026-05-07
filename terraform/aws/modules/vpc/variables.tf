variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "az_count" {
  type    = number
  default = 2
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "enable_single_nat_gw" {
  type    = bool
  default = false
}
