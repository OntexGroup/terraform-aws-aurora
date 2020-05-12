data "aws_caller_identity" "account_id" {}

// Random password
resource "random_password" "password" {
  length  = 16
  special = false
}

resource "random_string" "resource_id" {
  length  = 3
  upper   = false
  special = false
}

locals {
  name_identifier = "${var.project}-${lookup(var.short_env, var.env, "WTF-fixenv")}-${var.role}-${random_string.resource_id.id}"
  account_id      = data.aws_caller_identity.account_id.account_id
}

// DB Security Group
resource "aws_security_group" "aurora_security_group" {
  name        = local.name_identifier
  description = "Allow mysql port 3306"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    protocol    = "tcp"
    to_port     = 3306
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// DB Subnet Group creation
resource "aws_db_subnet_group" "main" {
  count       = var.enabled ? 1 : 0
  name        = local.name_identifier
  description = "Group of DB subnets"
  subnet_ids  = var.subnets
  tags        = merge(var.custom_tags)
}

resource "aws_db_parameter_group" "aurora_db_parameter_group" {
  family      = var.family
  name        = local.name_identifier
  description = "aws_db_parameter_group ${local.name_identifier}"

  parameter {
    name  = "general_log"
    value = var.enable_general_log ? 1 : 0
  }

  parameter {
    name  = "slow_query_log"
    value = var.enable_slow_query_log ? 1 : 0
  }
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_parameter_group" {
  family      = var.family
  name        = local.name_identifier
  description = "aws_rds_cluster_parameter_group ${local.name_identifier}"

  parameter {
    name  = "general_log"
    value = var.enable_general_log ? 1 : 0
  }

  parameter {
    name  = "slow_query_log"
    value = var.enable_slow_query_log ? 1 : 0
  }
}

// Create single DB instance
resource "aws_rds_cluster_instance" "cluster_instance_0" {
  count                        = var.enabled ? 1 : 0
  depends_on                   = [aws_iam_role_policy_attachment.rds-enhanced-monitoring-policy-attach]
  engine                       = var.engine
  engine_version               = var.engine_version
  identifier                   = format("%s-node-0", local.name_identifier)
  cluster_identifier           = aws_rds_cluster.default[0].id
  instance_class               = var.instance_type
  publicly_accessible          = var.publicly_accessible
  db_subnet_group_name         = aws_db_subnet_group.main[0].name
  db_parameter_group_name      = aws_db_parameter_group.aurora_db_parameter_group.name
  preferred_maintenance_window = var.preferred_maintenance_window
  apply_immediately            = var.apply_immediately
  monitoring_role_arn          = join("", aws_iam_role.rds-enhanced-monitoring.*.arn)
  monitoring_interval          = var.monitoring_interval
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  promotion_tier               = "0"
  performance_insights_enabled = var.performance_insights_enabled
  tags                         = merge(var.custom_tags)
}

// Create 'n' number of additional DB instance(s) in same cluster
resource "aws_rds_cluster_instance" "cluster_instance_n" {
  depends_on                   = [aws_rds_cluster_instance.cluster_instance_0]
  count                        = var.enabled ? var.replica_scale_enabled ? var.replica_scale_min : var.replica_count : 0
  engine                       = var.engine
  engine_version               = var.engine_version
  identifier                   = format("%s-node-%d", local.name_identifier, count.index + 1)
  cluster_identifier           = aws_rds_cluster.default[0].id
  instance_class               = var.instance_type
  publicly_accessible          = var.publicly_accessible
  db_subnet_group_name         = aws_db_subnet_group.main[0].name
  db_parameter_group_name      = aws_db_parameter_group.aurora_db_parameter_group.name
  preferred_maintenance_window = var.preferred_maintenance_window
  apply_immediately            = var.apply_immediately
  monitoring_role_arn          = join("", aws_iam_role.rds-enhanced-monitoring.*.arn)
  monitoring_interval          = var.monitoring_interval
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  promotion_tier               = count.index + 1
  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(var.custom_tags)
}

// Create DB Cluster
resource "aws_rds_cluster" "default" {
  count                               = var.enabled ? 1 : 0
  cluster_identifier                  = local.name_identifier
  availability_zones                  = var.azs
  engine                              = var.engine
  engine_version                      = var.engine_version
  iam_roles                           = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"]
  master_username                     = var.username
  master_password                     = random_password.password.result
  final_snapshot_identifier           = "${var.final_snapshot_identifier}-${random_id.server[0].hex}"
  skip_final_snapshot                 = var.skip_final_snapshot
  backup_retention_period             = var.backup_retention_period
  preferred_backup_window             = var.preferred_backup_window
  preferred_maintenance_window        = var.preferred_maintenance_window
  port                                = var.port
  db_subnet_group_name                = aws_db_subnet_group.main[0].name
  vpc_security_group_ids              = [aws_security_group.aurora_security_group.id]
  snapshot_identifier                 = var.snapshot_identifier
  storage_encrypted                   = var.storage_encrypted
  apply_immediately                   = var.apply_immediately
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.aurora_cluster_parameter_group.name
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  enabled_cloudwatch_logs_exports     = var.enable_cloudwatch_logs_exports
  deletion_protection                 = var.deletion_protection

  tags = merge(var.custom_tags)

}

// Geneate an ID when an environment is initialised
resource "random_id" "server" {
  count = var.enabled ? 1 : 0
  keepers = {
    id = aws_db_subnet_group.main[0].name
  }

  byte_length = 8
}

// IAM Role + Policy attach for Enhanced Monitoring
data "aws_iam_policy_document" "monitoring-rds-assume-role-policy" {
  count = var.enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds-enhanced-monitoring" {
  count              = var.enabled && var.monitoring_interval > 0 ? 1 : 0
  name_prefix        = "${local.name_identifier}-"
  assume_role_policy = data.aws_iam_policy_document.monitoring-rds-assume-role-policy[0].json
}

resource "aws_iam_role_policy_attachment" "rds-enhanced-monitoring-policy-attach" {
  count      = var.enabled && var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds-enhanced-monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

// Autoscaling
resource "aws_appautoscaling_target" "autoscaling" {
  count              = var.enabled && var.replica_scale_enabled ? 1 : 0
  max_capacity       = var.replica_scale_max
  min_capacity       = var.replica_scale_min
  resource_id        = "cluster:${aws_rds_cluster.default[0].cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "autoscaling" {
  count              = var.enabled && var.replica_scale_enabled ? 1 : 0
  depends_on         = [aws_appautoscaling_target.autoscaling]
  name               = "target-metric"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "cluster:${aws_rds_cluster.default[0].cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }

    scale_in_cooldown  = var.replica_scale_in_cooldown
    scale_out_cooldown = var.replica_scale_out_cooldown
    target_value       = var.replica_scale_cpu
  }
}