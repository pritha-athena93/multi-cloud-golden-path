output "key_ring_id" {
  value = google_kms_key_ring.this.id
}

output "gke_key_id" {
  value = google_kms_crypto_key.gke.id
}

output "cloudsql_key_id" {
  value = google_kms_crypto_key.cloudsql.id
}

output "gcs_key_id" {
  value = google_kms_crypto_key.gcs.id
}

output "vault_key_id" {
  value = google_kms_crypto_key.vault.id
}

output "vault_key_name" {
  value = google_kms_crypto_key.vault.name
}
