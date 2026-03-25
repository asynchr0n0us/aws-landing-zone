variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
}

variable "account_id" {
  description = "AWS account id"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "develop"
}
