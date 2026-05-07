terraform {
  required_version = ">= 1.7.0, < 2.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.20"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_kms_key_ring" "tf_state" {
  name     = "tf-state-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "tf_state" {
  name            = "tf-state-key"
  key_ring        = google_kms_key_ring.tf_state.id
  rotation_period = "7776000s" # 90 days
}

resource "google_storage_bucket" "tf_state" {
  name                        = var.state_bucket_name
  location                    = var.region
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.tf_state.id
  }
}

resource "google_service_account" "ci_runner" {
  account_id   = "ci-terraform-runner"
  display_name = "CI Terraform Runner"
}

resource "google_storage_bucket_iam_member" "ci_runner_state" {
  bucket = google_storage_bucket.tf_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci_runner.email}"
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "state_bucket_name" {
  type = string
}

output "state_bucket_name" {
  value = google_storage_bucket.tf_state.name
}

output "ci_runner_sa_email" {
  value = google_service_account.ci_runner.email
}
