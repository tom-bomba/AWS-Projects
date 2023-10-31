terraform {
    required_providers {
        aws         = {
            source  = "hashicorp/aws"
            version = "~> 4.67.0"
        }
        kubernetes  = {
            source  = "hashicorp/kubernetes"
            version = ">= 1.7"  
        }
    }
    required_version = "~> 1.5.0"
}


provider "aws" {
    region = var.region
    shared_config_files      = [ var.aws_config_file ]
    shared_credentials_files = [ var.aws_cred_file ]
    profile                  = var.aws_profile
}

provider "kubernetes" {
  # Point to the cluster endpoint
  host                   = aws_eks_cluster.cluster.endpoint
  # Configure the cluster certificate
  cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority.0.data)
  # Configure the token
  token                  = data.aws_eks_cluster_auth.cluster.token
}
