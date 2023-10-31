output "tags" {
    value = local.tags
}

output "eks_cluster_name" {
  value = aws_eks_cluster.cluster.name
  description = "The name of the EKS cluster"
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
  description = "Endpoint for the EKS cluster"
}

output "eks_cluster_ca" {
  value = aws_eks_cluster.cluster.certificate_authority.0.data
  description = "Certificate authority data for the EKS cluster"
}

output "rds_endpoint" {
  value = aws_rds_cluster.app_db_cluster_1.endpoint
  description = "Endpoint for the RDS cluster"
}

output "rds_reader_endpoint" {
  value = aws_rds_cluster.app_db_cluster_1.reader_endpoint
  description = "Reader endpoint for the RDS cluster"
}

output "db_root_user" {
  value = local.db_creds.db_root_user
  description = "Database root user"
  sensitive = true
}

output "db_root_pass" {
  value = local.db_creds.db_root_pass
  description = "Database root password"
  sensitive = true
}

output "result_entry" {
  value = jsondecode(aws_lambda_invocation.lambda_execute.result)
}

output "rds_cluster_arn" {
  value = aws_rds_cluster.app_db_cluster_1.arn
}

output "vpc_id" {
  value = aws_vpc.app_vpc.id
}

output "redis_reader" {
  value = aws_elasticache_replication_group.app_cache_rep_group.reader_endpoint_address
}

output "redis_writer" {
  value = aws_elasticache_replication_group.app_cache_rep_group.primary_endpoint_address
}

output "users_table_name" {
  value = var.users_table_name
}

output "app_table_name" {
  value = var.app_table_name
}