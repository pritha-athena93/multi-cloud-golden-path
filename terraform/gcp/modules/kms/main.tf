data "google_project" "this" {
  project_id = var.project_id
}

locals {
  project_number = data.google_project.this.number
}

resource "google_kms_key_ring" "this" {
  name     = "${var.environment}-keyring"
  location = var.region
  project  = var.project_id
}

# GKE service agent needs encrypt/decrypt for etcd encryption and node boot disks
resource "google_kms_crypto_key_iam_member" "gke_service_agent" {
  crypto_key_id = google_kms_crypto_key.gke.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${local.project_number}@container-engine-robot.iam.gserviceaccount.com"
}

# Compute service agent needs encrypt/decrypt for node boot disk encryption
resource "google_kms_crypto_key_iam_member" "compute_service_agent_gke" {
  crypto_key_id = google_kms_crypto_key.gke.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${local.project_number}@compute-system.iam.gserviceaccount.com"
}

# Ensure CloudSQL service agent exists before granting KMS permissions
resource "google_project_service_identity" "cloudsql" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"
}

# CloudSQL service agent needs encrypt/decrypt for database encryption
resource "google_kms_crypto_key_iam_member" "cloudsql_service_agent" {
  crypto_key_id = google_kms_crypto_key.cloudsql.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_project_service_identity.cloudsql.email}"
  depends_on    = [google_project_service_identity.cloudsql]
}

resource "google_kms_crypto_key" "gke" {
  name            = "gke-etcd"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = "7776000s"
}

resource "google_kms_crypto_key" "cloudsql" {
  name            = "cloudsql"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = "7776000s"
}

resource "google_kms_crypto_key" "gcs" {
  name            = "gcs"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = "7776000s"
}

resource "google_kms_crypto_key" "vault" {
  name            = "vault-unseal"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = "7776000s"
}
