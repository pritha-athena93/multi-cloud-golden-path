output "vpc_id" {
  value = google_compute_network.this.id
}

output "vpc_name" {
  value = google_compute_network.this.name
}

output "public_subnet_id" {
  value = google_compute_subnetwork.public.id
}

output "private_subnet_id" {
  value = google_compute_subnetwork.private.id
}

output "isolated_subnet_id" {
  value = google_compute_subnetwork.isolated.id
}
