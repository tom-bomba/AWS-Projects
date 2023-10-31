output "tags" {
    value = local.tags
}
output "reader_endpoint" {
  description = "Reader endpoint for the RDS cluster"
  value       = aws_rds_cluster.app_db_cluster_1.reader_endpoint
}

output "primary_endpoint" {
  description = "Primary endpoint for the RDS cluster"
  value       = aws_rds_cluster.app_db_cluster_1.endpoint
}

output "load_balancer_dns" {
    description = "Primary endpoint for the RDS cluster"
  value       = aws_lb.app_load_balancer.dns_name
}
