output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value     = module.eks.cluster_endpoint
  sensitive = true
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "rds_endpoint" {
  value     = module.rds.endpoint
  sensitive = true
}

output "bastion_instance_id" {
  value = var.enable_bastion ? module.bastion[0].instance_id : null
}
