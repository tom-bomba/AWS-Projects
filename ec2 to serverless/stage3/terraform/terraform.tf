terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.67.0"
        }
    }
    required_version = "~> 1.4.0"
}


provider "aws" {
    region = var.region
    shared_config_files      = ["/path/to/config"]
    shared_credentials_files = ["/path/to/cred"]
    profile                  = "iamadmin-general"
}