terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eventbridge.git//.?ref=v1.15.1"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

dependency "lambda" {
  config_path = "../lambda"
  mock_outputs = {
    lambda_function_arn = "arn:aws:lambda:eu-central-1:123456789012:function:mock-function"
  }
}

################################################################################################
# View all available inputs for this module:
# https://registry.terraform.io/modules/terraform-aws-modules/eventbridge/aws/1.15.1?tab=inputs
################################################################################################

inputs = {

  create_bus = false

  create_role = false

  rules = {
    ecr-repo-autoprovision = {
      description   = "Capture cloudtrail ECR events"
      enabled       = true
      event_pattern = <<EOF
{
  "source": [
    "aws.ecr"
  ],
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ecr.amazonaws.com"
    ],
    "eventName": [
      "InitiateLayerUpload"
    ],
    "errorCode": [
      "RepositoryNotFoundException"
    ]
  }
}
EOF
    }
  }

  targets = {
    ecr-repo-autoprovision = [
      {
        name  = "lambda-ecr"
        arn   = dependency.lambda.outputs.lambda_function_arn
      }
    ]
  }
}
