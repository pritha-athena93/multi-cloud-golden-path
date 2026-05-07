output "endpoint" {
  value     = aws_db_instance.this.address
  sensitive = true
}

output "db_name" {
  value = aws_db_instance.this.db_name
}
