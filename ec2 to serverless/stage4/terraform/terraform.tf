terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 4.67.0"
        }
        random = {
        source = "hashicorp/random"
        }
    }
    required_version = "~> 1.4.0"
}

provider "aws" {
    region = var.region
    shared_config_files      = ["/path/to/.aws/config"]
    shared_credentials_files = ["/path/to/.aws/credentials"]
    profile                  = "iamadmin-general"
}