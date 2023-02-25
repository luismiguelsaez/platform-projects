terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-security-group.git//.?ref=v4.17.1"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

dependency "vpc" {
  config_path                             = "${get_terragrunt_dir()}/../../vpc"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info"]
  mock_outputs = {
    vpc_id = "mocked-vpc-id"
  }
}


####################################################################################################
# View all available inputs for this module:
# https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws/4.17.1?tab=inputs
####################################################################################################

inputs = {

  name        = "${include.locals.name}-shared"
  description = "${include.locals.name} SG for shared access"

  vpc_id = dependency.vpc.outputs.vpc_id

  ingress_with_self = [
    {
      rule = "all-all"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}
