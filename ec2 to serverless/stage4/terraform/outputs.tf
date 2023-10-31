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

output "result_entry" {
  value = jsondecode(aws_lambda_invocation.lambda_execute.result)
}

output "aws_s3_bucket_website_configuration_bucket_website_config" {
  value = aws_s3_bucket_website_configuration_bucket_website_config.website_endpoint
}
