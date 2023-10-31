terraform {
    required_providers {
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = ">= 1.7"  
        }

    }
    required_version = "~> 1.5.0"
}

provider "kubernetes" {
  host                   = local.outputs.eks_cluster_endpoint.value
  cluster_ca_certificate = base64decode(local.outputs.eks_cluster_ca.value)
  token                  = data.aws_eks_cluster_auth.token.token
}
