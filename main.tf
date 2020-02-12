// DB Security Group
resource "aws_security_group" "aurora_security_group" {
  name        = "${var.namespace}-${var.env}-${var.project}-aurora-sg"
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
  name        = "${var.namespace}-${var.env}-${var.project}-subnet-group"
  description = "Group of DB subnets"
  subnet_ids  = var.subnets
  tags        = merge(var.custom_tags)
}

resource "aws_db_parameter_group" "aurora_db_parameter_group" {
  family      = var.family
  name        = "${var.namespace}-${var.env}-${var.project}-db-parameter-group"
  description = "${var.namespace}-${var.env}-${var.project}-db-parameter-group"
}

resource "aws_rds_cluster_parameter_group" "aurora_cluster_parameter_group" {
  family      = var.family
  name        = "${var.namespace}-${var.env}-${var.project}-cluster-parameter-group"
  description = "${var.namespace}-${var.env}-${var.project}-cluster-parameter-group"
}

// Create single DB instance
resource "aws_rds_cluster_instance" "cluster_instance_0" {
  count      = var.enabled ? 1 : 0
  depends_on = [aws_iam_role_policy_attachment.rds-enhanced-monitoring-policy-attach]

  identifier                   = var.identifier_prefix != "" ? format("%s-node-0", var.identifier_prefix) : format("%s-aurora-node-0", var.env)
  cluster_identifier           = aws_rds_cluster.default[0].id
  engine                       = var.engine
  engine_version               = var.engine_version
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
  identifier                   = var.identifier_prefix != "" ? format("%s-node-%d", var.identifier_prefix, count.index + 1) : format("%s-aurora-node-%d", var.env, count.index + 1)
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
  cluster_identifier                  = var.identifier_prefix != "" ? format("%s-cluster", var.identifier_prefix) : format("%s-aurora-cluster", var.env)
  availability_zones                  = var.azs
  engine                              = var.engine
  engine_version                      = var.engine_version
  master_username                     = var.username
  master_password                     = var.password
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

  tags = merge(var.custom_tags)

  lifecycle {
    ignore_changes = [ "master_password" ]
  }
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
  name_prefix        = "rds-enhanced-mon-${var.env}-"
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
