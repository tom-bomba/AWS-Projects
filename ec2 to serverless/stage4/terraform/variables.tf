variable "project_name" {
    description = "Name of the project"
    type        = string
    default     = "webserver-v4"
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
  description = "The IP range that can connect to the resources."
  type        = string
  default     = "0.0.0.0/0"
}
variable "my_ip" {
  description = "The IP that can connect to the resources."
  type        = string
  default     = "0.0.0.0"
}

variable "db_name" {
    description = "Name of the db"
    type        = string
    default     = "fortunes"
}
variable "api_status_response" {
  description = "define list to use in the API creation"
  type        = list(string)
  default     = ["200", "400", "500"]
}
variable "cognito_pool_arn" {
    description = "arn of cognito user pool to use for auth"
    type        = string
    default     = "arn:aws:cognito-idp:us-east-1:accntno:userpool/userpool"
}