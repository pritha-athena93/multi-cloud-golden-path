output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  value = aws_subnet.isolated[*].id
}

output "sg_alb_id" {
  value = aws_security_group.alb.id
}

output "sg_bastion_id" {
  value = aws_security_group.bastion.id
}

output "sg_nodes_id" {
  value = aws_security_group.nodes.id
}

output "sg_rds_id" {
  value = aws_security_group.rds.id
}
