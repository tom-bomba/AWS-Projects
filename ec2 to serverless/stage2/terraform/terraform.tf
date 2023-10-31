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
    shared_config_files      = ["/home/zack/.aws/config"]
    shared_credentials_files = ["/home/zack/.aws/credentials"]
    profile                  = "iamadmin-general"
}