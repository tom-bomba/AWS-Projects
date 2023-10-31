variable "project_name" {
    description = "Name of the project"
    type        = string
    default     = "webserver-k8s"
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

variable "my_cidr" {
  description = "The IP range that can connect to the instance."
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_name" {
    description = "Name of the db"
    type        = string
    default     = "fortunes"
}

variable "image" {
    description = "URI of image to use"
    type        = string
}

variable "cw_image" {
    description = "URI of image to use"
    type        = string
}

variable "k8_namespace" {
    description = "namespace of the kubernetes resources created within"
    type = string
    default = "default"
}

variable "aws_secrets_loc" {
    description = "The location of the secret within Secrets Manager"
    type = string
    default = "path/to/secret"
}