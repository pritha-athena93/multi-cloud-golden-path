environment          = "prod"
region               = "us-east-1"
enable_nginx_ingress = true
enable_cloud_lb      = true
backend_type         = "remote"
enable_bastion       = true

eks_version         = "1.29"
node_instance_types = ["m5.xlarge"]
node_min            = 3
node_max            = 10

db_instance_class   = "db.m5.xlarge"
db_multi_az         = true
db_backup_retention = 30

az_count = 3
