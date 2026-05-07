resource "google_compute_network" "this" {
  name                    = "${var.environment}-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.environment}-public"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = "10.0.0.0/24"
  project       = var.project_id
}

resource "google_compute_subnetwork" "private" {
  name          = "${var.environment}-private"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = "10.0.1.0/24"
  project       = var.project_id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

resource "google_compute_subnetwork" "isolated" {
  name          = "${var.environment}-isolated"
  region        = var.region
  network       = google_compute_network.this.id
  ip_cidr_range = "10.0.2.0/24"
  project       = var.project_id
}

resource "google_compute_router" "this" {
  name    = "${var.environment}-router"
  region  = var.region
  network = google_compute_network.this.id
  project = var.project_id
}

resource "google_compute_router_nat" "this" {
  name                               = "${var.environment}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  project                            = var.project_id

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_global_address" "private_service_access" {
  name          = "${var.environment}-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.this.id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_access.name]
}

resource "google_compute_firewall" "deny_all_ingress" {
  name      = "${var.environment}-deny-all-ingress"
  network   = google_compute_network.this.name
  project   = var.project_id
  priority  = 65534
  direction = "INGRESS"

  deny { protocol = "all" }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "${var.environment}-allow-iap-ssh"
  network   = google_compute_network.this.name
  project   = var.project_id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["bastion"]
}

resource "google_compute_firewall" "allow_nodes_to_master" {
  name      = "${var.environment}-nodes-to-master"
  network   = google_compute_network.this.name
  project   = var.project_id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }
  source_ranges = [google_compute_subnetwork.private.ip_cidr_range]
  target_tags   = ["gke-master"]
}

resource "google_compute_firewall" "allow_nodes_to_cloudsql" {
  name      = "${var.environment}-nodes-to-cloudsql"
  network   = google_compute_network.this.name
  project   = var.project_id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }
  source_ranges = [google_compute_subnetwork.private.ip_cidr_range]
  target_tags   = ["cloudsql"]
}
