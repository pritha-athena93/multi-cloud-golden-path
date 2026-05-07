environment          = "dev"
region               = "us-east-1"
enable_nginx_ingress = true
enable_cloud_lb      = false
backend_type         = "remote"
enable_bastion       = true

eks_version         = "1.29"
node_instance_types = ["t3.medium"]
node_min            = 1
node_max            = 3

db_instance_class   = "db.t3.micro"
db_multi_az         = false
db_backup_retention = 7

az_count = 2
