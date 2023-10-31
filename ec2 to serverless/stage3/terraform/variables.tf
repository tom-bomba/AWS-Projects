variable "project_name" {
    description = "Name of the project"
    type        = string
    default     = "webserver-v3"
}

variable "environment" {
    description = "Name of the environment"
    type        = string
    default     = "dev"
}

variable "resource_tags" {
    description = "Tags to set for all resources"
    type        = map(string)
    default     = { }
}

variable "region" {
    description = "The AWS region to use (singular)"
    type = string
    default = "us-east-1"
}
variable "key_name" {
  description = "Name of the key pair to use."
  type        = string
}

variable "my_cidr" {
  description = "The IP range that can connect to the instance."
  type        = string
  default     = "0.0.0.0/0"
}

variable "ami_id" {
  description = "The ID of the Amazon Machine Image (AMI)"
  type        = string
}
variable "db_name" {
    description = "Name of the db"
    type        = string
    default     = "fortunes"
}