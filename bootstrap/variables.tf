variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
}

variable "account_id" {
  description = "AWS account ID (used in bucket naming)"
  type        = string
}

variable "owner" {
  description = "Owner tag value"
  type        = string
  default     = "platform-infra"
}

#variable "environment" {
#  description = "Environment name (staging / develop / production)"
#  type        = string
#  default     = "staging"
#}

#  validation {
#    condition     = contains(["staging", "develop", "production"], var.environment)
#    error_message = "Environment must be staging, develop or production."
#  }
