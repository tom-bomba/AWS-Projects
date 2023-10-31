data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_secretsmanager_secret_version" "db_secrets" {
  secret_id = var.aws_secrets_loc
}

data "aws_region" "current" {}

data "template_file" "deployment_main" {
  template = file("${path.module}/k8s/deployment_main.tmpl")
  vars = {
    container_image = var.image
    cw_container_image = var.cw_image
    db_writer       = local.outputs.rds_endpoint.value
    db_reader       = local.outputs.rds_reader_endpoint.value
    db_username     = local.db_creds.db_root_user
    db_pass         = local.db_creds.db_root_pass
    db_name         = var.db_name
    db_usersTable   = "users"
    db_appTable     = "fortunes"
    k8_namespace    = var.k8_namespace
  }
}

data "aws_eks_cluster_auth" "token" {
  name = local.outputs.eks_cluster_name.value
}

