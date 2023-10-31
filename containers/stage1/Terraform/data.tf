data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "amzn-linux-ami" {  
   name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_secretsmanager_secret_version" "db_secrets" {
  secret_id = "dev/db_creds/webserver_v2"
}

data "aws_region" "current" {}
