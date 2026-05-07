environment          = "staging"
region               = "us-east-1"
enable_nginx_ingress = true
enable_cloud_lb      = true
backend_type         = "remote"
enable_bastion       = true

eks_version         = "1.29"
node_instance_types = ["m5.large"]
node_min            = 2
node_max            = 5

db_instance_class   = "db.m5.large"
db_multi_az         = true
db_backup_retention = 14

az_count = 3
