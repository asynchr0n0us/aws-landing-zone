variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "local_test profile"
  type        = string
  default     = "local_test"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "landing-zone"
}

variable "tf_state_bucket_name" {
  description = "tfstate file name"
  type        = string
  default     = "landing-zone-terraform-state"
}

variable "account_id" {
  description = "723298837109"
  type        = string
}

variable "owner" {
  description = "Owner tag value"
  type        = string
  default     = "landing-zone"
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
