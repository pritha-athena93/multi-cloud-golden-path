environment          = "dev"
region               = "us-central1"
enable_nginx_ingress = true
enable_cloud_lb      = false
backend_type         = "remote"
enable_bastion       = true

node_machine_type = "e2-medium"
node_min          = 1
node_max          = 3
