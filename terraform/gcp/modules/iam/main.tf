resource "google_service_account" "node" {
  account_id   = "${var.environment}-gke-node"
  display_name = "${var.environment} GKE Node SA"
  project      = var.project_id
}

resource "google_project_iam_member" "node_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "node_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_service_account" "demo_app" {
  account_id   = "${var.environment}-demo-app"
  display_name = "${var.environment} Demo App GSA"
  project      = var.project_id
}

resource "google_project_iam_member" "demo_app_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.demo_app.email}"
}

resource "google_project_iam_member" "demo_app_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.demo_app.email}"
}

resource "google_service_account_iam_binding" "demo_app_workload_identity" {
  service_account_id = google_service_account.demo_app.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[demo-app/demo-app]"
  ]
}

resource "google_service_account" "vault" {
  account_id   = "${var.environment}-vault"
  display_name = "${var.environment} Vault GSA"
  project      = var.project_id
}

resource "google_service_account_iam_binding" "vault_workload_identity" {
  service_account_id = google_service_account.vault.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[vault/vault]"
  ]
}

resource "google_service_account" "bastion" {
  account_id   = "${var.environment}-bastion"
  display_name = "${var.environment} Bastion SA"
  project      = var.project_id
}
