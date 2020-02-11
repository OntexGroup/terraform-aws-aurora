include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "git::git@github.com:OntexGroup/terraform-aws-aurora.git?ref=v4.0.2"
}

dependency "bastion" {
  config_path = "../ec2-bastion"
}

dependency "vpc" {
  config_path = "../vpc"
}

locals {
  aws_region    = basename(dirname(get_terragrunt_dir()))
  project       = "My_Project"
  namespace     = "My_Company"
  env           = "development"
  custom_tags   = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("custom_tags.yaml")}"))
  replica_count = 1
}

inputs = {
  "project"         = local.project
  "custom_tags"     = local.custom_tags
  "namespace"       = local.namespace
  "stage"           = local.env
  "env"             = local.env
  "replica_count"   = local.replica_count
  "security_groups" = dependency.bastion.outputs.security_group_id
  "azs"             = dependency.vpc.outputs.availability_zones
  "vpc_id"          = dependency.vpc.outputs.vpc_id
  "subnets"         = dependency.vpc.outputs.private_subnet_ids

  aws = {
    "region" = local.aws_region
  }
}