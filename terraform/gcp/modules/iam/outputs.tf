output "node_sa_email" {
  value = google_service_account.node.email
}

output "demo_app_sa_email" {
  value = google_service_account.demo_app.email
}

output "vault_sa_email" {
  value = google_service_account.vault.email
}

output "bastion_sa_email" {
  value = google_service_account.bastion.email
}
