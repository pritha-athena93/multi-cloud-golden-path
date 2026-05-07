output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_endpoint" {
  value     = module.gke.cluster_endpoint
  sensitive = true
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "artifact_registry_url" {
  value = module.artifact_registry.repository_url
}

output "cloudsql_connection_name" {
  value     = module.cloudsql.connection_name
  sensitive = true
}

output "bastion_instance_name" {
  value = var.enable_bastion ? module.bastion[0].instance_name : null
}
