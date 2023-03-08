{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCrossAccountRO",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": ${jsonencode([for arn in principal_arns_ro : "${arn}"])}
        }
      }
    },
    {
      "Sid": "AllowCrossAccountRW",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": ${jsonencode([for arn in principal_arns_rw : "${arn}"])}
        }
      }
    }
  ]
}
