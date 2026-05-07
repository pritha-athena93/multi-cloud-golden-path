environment          = "staging"
region               = "us-central1"
enable_nginx_ingress = true
enable_cloud_lb      = true
backend_type         = "remote"
enable_bastion       = true

node_machine_type = "n2-standard-2"
node_min          = 2
node_max          = 5
