resource "google_kms_key_ring" "this" {
  name     = "${var.environment}-keyring"
  location = var.region
  project  = var.project_id
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
