resource "google_compute_instance" "bastion" {
  name         = "${var.environment}-bastion"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
  }

  service_account {
    email  = var.bastion_sa_email
    scopes = ["cloud-platform"]
  }

  tags = ["bastion"]

  shielded_instance_config {
    enable_secure_boot          = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
  }
}

resource "google_iap_tunnel_instance_iam_binding" "bastion" {
  project  = var.project_id
  zone     = "${var.region}-a"
  instance = google_compute_instance.bastion.name
  role     = "roles/iap.tunnelResourceAccessor"
  members  = var.iap_members
}
