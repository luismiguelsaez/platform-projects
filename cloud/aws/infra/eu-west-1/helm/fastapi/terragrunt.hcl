terraform {
  source = "git::https://github.com/cloudposse/terraform-aws-helm-release.git//?ref=0.7.0"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

# Generating helm provider to get the needed credentials
generate "helm-provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "helm" {
  kubernetes {
    host                   = "${dependency.eks.outputs.cluster_endpoint}"
    token                  = "${dependency.eks_auth.outputs.token}"
    cluster_ca_certificate = <<-CERT
${base64decode(dependency.eks.outputs.cluster_certificate_authority_data)}
    CERT
  }
}
EOF
}

# Using locally defined module to get EKS auth data
dependency "eks_auth" {
  config_path = "${get_terragrunt_dir()}/../../eks-auth"
  mock_outputs = {
    token = "mocked-token"
  }
}

dependency "eks" {
  config_path                             = "${get_terragrunt_dir()}/../../eks"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info"]
  mock_outputs = {
    cluster_oidc_issuer_url            = "https://oidc.eks.eu-central-1.amazonaws.com/id/MOCKED"
    cluster_endpoint                   = "https://mock-cluster.endpoint.cloud"
    cluster_certificate_authority_data = "cmFuZG9tLWRhdGEK"
  }
}

dependency "rds" {
  config_path                             = "${get_terragrunt_dir()}/../../rds"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info"]
  mock_outputs = {
    db_instance_address  = "testing.uniqueid.aws-region.rds.amazonaws.com"
    db_instance_username = "user"
    db_instance_password = "pass"
  }
}

dependency "ecr" {
  config_path                             = "${get_terragrunt_dir()}/../../ecr"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "terragrunt-info"]
  mock_outputs = {
    repository_url = "aws-account-id.dkr.ecr.aws-region.amazonaws.com/apps/fastapi"
  }
}

#####################################################################################################################
# View all available inputs for this module:
# https://registry.terraform.io/modules/cloudposse/helm-release/aws/0.7.0?tab=inputs
#####################################################################################################################

inputs = {
  name  = "fastapi"
  chart = "${get_terragrunt_dir()}/../../../helm/fastapi"

  create_namespace     = true
  kubernetes_namespace = "frontend"

  atomic          = false
  cleanup_on_fail = false
  timeout         = "300"
  wait            = false

  eks_cluster_oidc_issuer_url = dependency.eks.outputs.cluster_oidc_issuer_url

  # Using template, in case something needs to be customized in the values file
  values = [templatefile("${get_terragrunt_dir()}/files/values.yaml", {
    rds_endpoint = dependency.rds.outputs.db_instance_address,
    rds_user     = include.locals.app_db_user,
    rds_pass     = include.locals.app_db_pass,
    rds_db       = include.locals.app_db_name,
    repo_url     = dependency.ecr.outputs.repository_url
  })]
}
