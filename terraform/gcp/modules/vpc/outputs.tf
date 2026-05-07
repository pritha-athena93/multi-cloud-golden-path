output "vpc_id" {
  value = google_compute_network.this.id
}

output "vpc_name" {
  value = google_compute_network.this.name
}

output "public_subnet_id" {
  value = google_compute_subnetwork.public.id
}

output "public_subnet_cidr" {
  value = google_compute_subnetwork.public.ip_cidr_range
}

output "private_subnet_id" {
  value = google_compute_subnetwork.private.id
}

output "isolated_subnet_id" {
  value = google_compute_subnetwork.isolated.id
}
