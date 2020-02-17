// The 'writer' endpoint for the cluster
output "cluster_endpoint" {
  value = join("", aws_rds_cluster.default.*.endpoint)
}

// Comma separated list of all DB instance endpoints running in cluster
output "all_instance_endpoints_list" {
  value = [concat(
    aws_rds_cluster_instance.cluster_instance_0.*.endpoint,
    aws_rds_cluster_instance.cluster_instance_n.*.endpoint,
  )]
  description = "Aurora endpoint(s)."
}

// A read-only endpoint for the Aurora cluster, automatically load-balanced across replicas
output "reader_endpoint" {
  value = join("", aws_rds_cluster.default.*.reader_endpoint)
  description = "Aurora reader endpoint."
}

// The ID of the RDS Cluster
output "cluster_identifier" {
  value = join("", aws_rds_cluster.default.*.id)
  description = "Aurora identifier id."
}

output "cluster_security_group_id" {
  value = aws_security_group.aurora_security_group.id
  description = "Security group id attach to the aurora cluster."
}

output "db_master_password" {
  value = aws_rds_cluster.default[0].master_password
  description = "Aurora master password."
}

output "db_master_user" {
  value = aws_rds_cluster.default[0].master_username
  description = "Aurora master user."
}
