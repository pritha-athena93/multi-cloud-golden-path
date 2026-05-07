output "node_role_arn" {
  value = aws_iam_role.node.arn
}

output "demo_app_irsa_role_arn" {
  value = aws_iam_role.demo_app_irsa.arn
}

output "vault_irsa_role_arn" {
  value = aws_iam_role.vault_irsa.arn
}

output "karpenter_role_arn" {
  value = aws_iam_role.karpenter_irsa.arn
}

output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller_irsa.arn
}

output "bastion_instance_profile_name" {
  value = aws_iam_instance_profile.bastion.name
}
