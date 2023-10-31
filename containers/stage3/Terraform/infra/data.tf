data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "amzn-linux-ami" {  
   name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_secretsmanager_secret_version" "db_secrets" {
  secret_id = var.aws_secrets_loc
}

data "aws_region" "current" {}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.cluster.name
}

data "aws_secretsmanager_secret" "master_secret" {
  arn = aws_rds_cluster.app_db_cluster_1.master_user_secret[0].secret_arn
}

output "master_secret_name" {
  value = data.aws_secretsmanager_secret.master_secret.name
}
