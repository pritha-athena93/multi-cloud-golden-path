resource "google_artifact_registry_repository" "demo_app" {
  location      = var.region
  repository_id = "demo-app"
  format        = "DOCKER"
  project       = var.project_id
}

resource "google_artifact_registry_repository_iam_member" "node_pull" {
  location   = google_artifact_registry_repository.demo_app.location
  repository = google_artifact_registry_repository.demo_app.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.node_sa_email}"
  project    = var.project_id
}
