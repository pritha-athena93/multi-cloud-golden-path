resource "aws_kms_key" "eks" {
  description             = "${var.environment} EKS etcd secrets encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

resource "aws_kms_key" "rds" {
  description             = "${var.environment} RDS storage encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_kms_key" "s3" {
  description             = "${var.environment} S3 encryption (ECR, logs)"
  enable_key_rotation     = true
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_kms_key" "vault" {
  description             = "${var.environment} Vault auto-unseal"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Vault IRSA"
        Effect = "Allow"
        Principal = {
          AWS = var.vault_irsa_role_arn != "" ? var.vault_irsa_role_arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${var.environment}-vault"
  target_key_id = aws_kms_key.vault.key_id
}

data "aws_caller_identity" "current" {}
