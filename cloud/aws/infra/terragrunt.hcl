locals {
  name              = "testing"
  vpc_cidr          = "172.24.0.0/22"
  az_num            = 3
  aws_region        = "eu-west-1"
  s3_backend_region = "eu-west-1"

  # Database initialization variables
  # Must be stored in a secrets engine like Vault or AWS secrets
  app_db_name = "ips"
  app_db_user = "app"
  app_db_pass = "Str0ngP4sS"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "aws" {
  region = "${local.aws_region}"
}
EOF
}

#remote_state {
#  backend = "s3"
#
#  config = {
#    encrypt        = false
#    bucket         = "terraform-backend"
#    key            = "${path_relative_to_include()}/terraform.tfstate"
#    region         = local.s3_backend_region
#    dynamodb_table = "terraform-state-lock"
#
#    skip_bucket_versioning   = true
#    skip_bucket_ssencryption = true
#    skip_bucket_enforced_tls = true
#  }
#
#  generate = {
#    path      = "backend.tf"
#    if_exists = "overwrite"
#  }
#}
