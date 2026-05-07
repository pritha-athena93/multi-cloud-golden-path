resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.isolated_subnet_ids
}

resource "aws_db_parameter_group" "postgres" {
  name   = "${var.environment}-postgres-params"
  family = "postgres15"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.environment}-postgres"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_name                = "appdb"
  username               = "appuser"
  password               = random_password.db.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  parameter_group_name   = aws_db_parameter_group.postgres.name
  storage_encrypted      = true
  kms_key_id             = var.kms_key_arn
  multi_az               = var.db_multi_az
  backup_retention_period = var.db_backup_retention
  deletion_protection    = var.environment == "prod"
  publicly_accessible    = false
  skip_final_snapshot    = var.environment != "prod"
}

resource "kubernetes_secret" "db_bootstrap" {
  metadata {
    name      = "db-bootstrap-credentials"
    namespace = "vault"
  }

  data = {
    DB_HOST     = aws_db_instance.this.address
    DB_PORT     = "5432"
    DB_NAME     = aws_db_instance.this.db_name
    DB_USER     = aws_db_instance.this.username
    DB_PASSWORD = random_password.db.result
  }
}
