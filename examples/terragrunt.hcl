include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "git::git@github.com:OntexGroup/terraform-aws-aurora.git?ref=v5.0.0"
}

dependency "bastion" {
  config_path = "../bastion"
}

dependency "vpc" {
  config_path = "../vpc"
}



locals {
  aws_region                     = basename(dirname(get_terragrunt_dir()))
  project                        = "lbc"
  namespace                      = "company"
  short_env                      = "dev"
  cluster-name                   = "all-dev"
  role                           = "mutualise"
  env                            = "development"
  custom_tags                    = yamldecode(file("${find_in_parent_folders("custom_tags.yaml")}"))
  instance_type                  = "db.t3.small"
  performance_insights_enabled   = false
  monitoring_interval            = 5
  enable_cloudwatch_logs_exports = [ "error" ]
  backup_retention_period        = 3
  deletion_protection            = true
  replica_count                  = 0
  security_group                 = [ "security_group_id" ]
  # Logs parameters
  enable_cloudwatch_alerts = false
  enable_general_log       = false
  enable_slow_query_log    = false
}


inputs = {
  "cloudwatch_sns_topic_arn"       = dependency.sns.outputs.sns_topic_arn
  "enable_cloudwatch_alerts"       = local.enable_cloudwatch_alerts
  "project"                        = local.project
  "custom_tags"                    = local.custom_tags
  "instance_type"                  = local.instance_type
  "namespace"                      = local.namespace
  "stage"                          = local.env
  "env"                            = local.env
  "replica_count"                  = local.replica_count
  "role"                           = local.role
  "azs"                            = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  "security_groups"                = local.security_groups 
  "enable_general_log"             = local.enable_general_log
  "enable_slow_query_log"          = local.enable_slow_query_log
  "enable_cloudwatch_logs_exports" = local.enable_cloudwatch_logs_exports


  #name = "aurora-db-mysql-devel"

  "vpc_id"  = trimspace(run_cmd("terragrunt", "output", "vpc_id", "--terragrunt-working-dir", "../vpc"))
  "subnets" = trimspace(run_cmd("terragrunt", "output", "private_subnet_ids", "--terragrunt-working-dir", "../vpc"))

  aws = {
    "region" = local.aws_region
  }
}

dependency "sns" {
  config_path = "../sns-cw-alerts"

  mock_outputs = {
    aws_sns_topic_arn = "arn:aws:sns:eu-west-1:000000000000:topic"
  }
}

# Uncomment this if you want monitoring

# generate "cloudwatch" {
#   path      = "cloudwatch.tf"
#   if_exists = "overwrite"
#   contents  = file("${get_terragrunt_dir()}/../../monitoring/aurora/cloudwatch.tf")
# }
