terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds//.?ref=v5.2.3"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

dependency "ec2_azs" {
  config_path                             = "${get_terragrunt_dir()}/../ec2-azs"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info"]
  mock_outputs = {
    aws_availability_zones = [ "eu-west-1a", "eu-west-1b", "eu-west-1c" ]
  }
}

dependency "vpc" {
  config_path                             = "${get_terragrunt_dir()}/../vpc"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info"]
  mock_outputs = {
    vpc_id          = "mocked-vpc-id"
    private_subnets = ["subnet-1", "subnet-2"]
  }
}

dependency "sg_shared_eks" {
  config_path                             = "${get_terragrunt_dir()}/../sg/shared"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info"]
  mock_outputs = {
    security_group_id = "sg-000000000"
  }
}

#######################################################################################
# View all available inputs for this module:
# https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/5.2.3?tab=inputs
#######################################################################################

inputs = {
  identifier = include.locals.name
  engine     = "mysql"
  engine_version       = "8.0.28"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.small"

  allocated_storage     = 10
  max_allocated_storage = 20
  storage_type          = "gp2"

  multi_az               = true
  create_db_subnet_group = true

  subnet_ids = dependency.vpc.outputs.private_subnets

  # Associating to EKS nodes security group for simplicity
  vpc_security_group_ids = [dependency.sg_shared_eks.outputs.security_group_id]
  publicly_accessible    = false

  backup_retention_period = 0
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sat:14:00-Sat:15:00"
  copy_tags_to_snapshot   = true

  # Initialize the database for the application to work
  db_name                = "ips"
  # For real life environments, get these values from either AWS secrets or any other service like Hashicorp Vault
  username               = "app"
  password               = "Str0ngP4sS"
  create_random_password = false

  create_db_option_group    = true
  create_db_parameter_group = true

  parameter_group_name = include.locals.name

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 7
  enabled_cloudwatch_logs_exports = [
    "error",
    "audit",
    "slowquery",
  ]

  # To be enabled in real life environments
  deletion_protection = false
  # To be disabled in real life environments
  skip_final_snapshot = true
}

