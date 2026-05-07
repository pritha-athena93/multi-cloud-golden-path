environment          = "prod"
region               = "us-central1"
enable_nginx_ingress = true
enable_cloud_lb      = true
backend_type         = "remote"
enable_bastion       = true

node_machine_type = "n2-standard-4"
node_min          = 3
node_max          = 10
