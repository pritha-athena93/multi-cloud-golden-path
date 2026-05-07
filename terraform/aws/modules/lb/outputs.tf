output "nginx_enabled" {
  value = var.enable_nginx_ingress
}

output "alb_controller_enabled" {
  value = var.enable_cloud_lb
}
