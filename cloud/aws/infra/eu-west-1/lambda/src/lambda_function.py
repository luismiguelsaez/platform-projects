import boto3, botocore
from os import environ
import sys
import json
import logging

def lambda_handler(event, context):

  logger = logging.getLogger('main')
  logger.setLevel(environ["LOG_LEVEL"])
  consoleHandler = logging.StreamHandler(sys.stdout)
  formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
  consoleHandler.setFormatter(formatter)
  consoleHandler.setLevel(environ["LOG_LEVEL"])
  logger.addHandler(consoleHandler)

  logger.info("botocore:{}, boto:{}".format(botocore.__version__, boto3.__version__))

  ecr = boto3.client("ecr")

  logger.debug(f'Received event: [{str(event)}]')

  if "errorCode" in event["detail"] and event["detail"]["errorCode"] == "RepositoryNotFoundException":
    logger.info(f'Attempting repository creation [{event["detail"]["requestParameters"]["repositoryName"]}]')
    try:
      response = ecr.create_repository(
        repositoryName=event["detail"]["requestParameters"]["repositoryName"],
        tags=[
          {
            'Key':'auto-create',
            'Value':'true'
          },
          {
            'Key':'creation-date',
            'Value': event["detail"]["eventTime"]
          },
          {
            'Key':'creation-user',
            'Value': event["detail"]["userIdentity"]["principalId"]
          },
        ],
        imageScanningConfiguration={
          'scanOnPush': bool(environ["SCAN_ON_PUSH"])
        },
        encryptionConfiguration={
          'encryptionType': environ["ENCRYPTION_TYPE"]
        },
        imageTagMutability=environ["IMAGE_TAB_MUTABILITY"]
      )
    except Exception:
      logger.warning(f'Repository [{event["detail"]["requestParameters"]["repositoryName"]}] already exists')

    logger.info(f'Assigning policy to repository')

    response_policy = ecr.set_repository_policy(
      repositoryName=event["detail"]["requestParameters"]["repositoryName"],
      policyText=json.dumps(json.loads(environ["REPOSITORY_POLICY_TEXT"]), separators=(',', ':')),
      force=True
    )

    logger.info(f'Assigning lifecycle policy to repository')
    response_lifecycle = ecr.put_lifecycle_policy(
        repositoryName=event["detail"]["requestParameters"]["repositoryName"],
        lifecyclePolicyText=json.dumps(json.loads(environ["LIFECYCLE_POLICY_TEXT"]), separators=(',', ':'))
    )

if __name__ == "__main__":
  # Only intended for local testing
  environ['LIFECYCLE_POLICY_TEXT'] = "{\n  \"rules\": [\n    {\n      \"rulePriority\": 1,\n      \"description\": \"Expire images older than 14 days\",\n      \"selection\": {\n        \"tagStatus\": \"any\",\n        \"countType\": \"sinceImagePushed\",\n        \"countUnit\": \"days\",\n        \"countNumber\": 14\n      },\n      \"action\": {\n          \"type\": \"expire\"\n      }\n    }\n  ]\n}\n"
  environ['REPOSITORY_POLICY_TEXT'] = "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Sid\": \"AllowCrossAccountRO\",\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"AWS\": [\"*\"]\n      },\n      \"Action\": [\n        \"ecr:BatchGetImage\",\n        \"ecr:BatchCheckLayerAvailability\",\n        \"ecr:GetDownloadUrlForLayer\"\n      ],\n      \"Condition\": {\n        \"StringLike\": {\n          \"aws:PrincipalArn\": [\"arn:aws:iam::484308071187:role/lok-k8s-main-app-*\",\"arn:aws:iam::632374391739:role/lok-k8s-main-app-*\",\"arn:aws:iam::046350321864:role/lok-k8s-main-app-*\"]\n        }\n      }\n    },\n    {\n      \"Sid\": \"AllowCrossAccountRW\",\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"AWS\": [\"*\"]\n      },\n      \"Action\": [\n        \"ecr:BatchGetImage\",\n        \"ecr:BatchCheckLayerAvailability\",\n        \"ecr:CompleteLayerUpload\",\n        \"ecr:GetDownloadUrlForLayer\",\n        \"ecr:InitiateLayerUpload\",\n        \"ecr:PutImage\",\n        \"ecr:UploadLayerPart\"\n      ],\n      \"Condition\": {\n        \"StringLike\": {\n          \"aws:PrincipalArn\": [\"arn:aws:iam::053497547689:role/cicd-jenkins-fleet-build*\"]\n        }\n      }\n    }\n  ]\n}\n"
  environ['AWS_PROFILE'] = 'lokalise-admin-prod'
  environ['LOG_LEVEL'] = 'INFO'
  with open('files/event.json') as user_file:
    json_event_contents = json.loads(user_file.read())
  lambda_handler(json_event_contents,"{}")
