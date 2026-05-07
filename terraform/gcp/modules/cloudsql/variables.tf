variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "project_id" {
  type = string
}

variable "private_network" {
  type = string
}

variable "kms_key_id" {
  type = string
}

variable "db_tier" {
  type    = string
  default = "db-f1-micro"
}
