variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS profile"
  type        = string
  default     = "local_test"
}

variable "tf_state_bucket_name" {
  description  = "tfstate file"
  type         = string
  default      = "landing-zone-terraform-state"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "landing-zone"
}

variable "account_id" {
  description = "AWS account id"
  type        = string
  default     = "723298837109"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "develop"
}
