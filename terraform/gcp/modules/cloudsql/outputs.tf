output "connection_name" {
  value = google_sql_database_instance.this.connection_name
}

output "private_ip" {
  value     = google_sql_database_instance.this.private_ip_address
  sensitive = true
}

output "db_name" {
  value = google_sql_database.app.name
}

output "db_user" {
  value = google_sql_user.app.name
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
