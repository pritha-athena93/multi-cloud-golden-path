bucket         = "my-org-tf-state-aws"
key            = "multi-cloud-golden-path/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
kms_key_id     = "arn:aws:kms:us-east-1:<account>:key/<key-id>"
dynamodb_table = "tf-state-lock"
