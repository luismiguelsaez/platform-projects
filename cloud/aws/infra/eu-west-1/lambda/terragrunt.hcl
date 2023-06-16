terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-lambda.git//.?ref=v4.7.0"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

##########################################################################################
# View all available inputs for this module:
# https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/4.7.0?tab=inputs
##########################################################################################

inputs = {
  function_name = "${include.locals.name}-ecr-repo-autoprovision"

  publish = true

  handler = "lambda_function.lambda_handler"
  runtime = "python3.9"

  source_path = ["src"]

  environment_variables = {
    LOG_LEVEL              = "INFO"
    SCAN_ON_PUSH           = "True"
    ENCRYPTION_TYPE        = "AES256"
    IMAGE_TAB_MUTABILITY   = "IMMUTABLE"
    LIFECYCLE_POLICY_TEXT  = templatefile("files/lifecycle-policy.hcl", {})
    REPOSITORY_POLICY_TEXT = templatefile("files/permissions-policy.hcl",
        { 
          # Add role name template for all node-groups in the different environments
          principal_arns_ro = [],
          # Add Jenkins build nodes role names
          principal_arns_rw = []
        }
    )
  }

  create_role        = true
  attach_policy_json = true
  policy_json        = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CreateRepository",
            "Effect": "Allow",
            "Action": [
              "ecr:CreateRepository",
              "ecr:SetRepositoryPolicy",
              "ecr:PutLifecyclePolicy",
              "ecr:TagResource"
            ],
            "Resource": "*"
        },
        {
            "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*",
            "Effect": "Allow"
        }
    ]
}
EOF

  allowed_triggers = {
    EventbridgeRule = {
      principal  = "events.amazonaws.com"
      source_arn = "arn:aws:events:*:*:rule/ecr-repo-autoprovision-rule"
    }
  }
}
