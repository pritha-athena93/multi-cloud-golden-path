resource "random_password" "db" {
  length  = 24
  special = false
}

resource "google_sql_database_instance" "this" {
  name                = "${var.environment}-postgres"
  database_version    = "POSTGRES_15"
  region              = var.region
  project             = var.project_id
  encryption_key_name = var.kms_key_id

  deletion_protection = var.environment == "prod"

  settings {
    tier              = var.db_tier
    availability_type = var.environment != "dev" ? "REGIONAL" : "ZONAL"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network
      require_ssl     = true
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 30 : 7
      }
    }
  }
}

resource "google_sql_database" "app" {
  name     = "appdb"
  instance = google_sql_database_instance.this.name
  project  = var.project_id
}

resource "google_sql_user" "app" {
  name     = "appuser"
  instance = google_sql_database_instance.this.name
  password = random_password.db.result
  project  = var.project_id
}
