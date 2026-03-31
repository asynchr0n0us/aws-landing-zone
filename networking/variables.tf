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
  description  = "tfstate file name"
  type         = string
  default      = "landing-zone-terraform-state"
}

variable "project_name" {
  description  = "Project name prefix for all resources"
  default      = "landing-zone"
  type = string 
}

variable "account_id" {
  description = "AWS account id"
  type        = string
  default     = "723298837109"
}

variable "environment" {
  description = "Environment name" 
  type = string 
  default = "develop" 
}

variable "vpc_cidr"  {
  description = "VPC subnet" 
  type = string
  default = "10.0.0.0/16" 
 }

variable "azs"  { 
  description = "Availability zone"
  type = list(string)
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"] 
}

variable "single_nat_gateway"  {
  description = "Sigle NAT GW for staging / develop true for cut costs " 
  type = bool 
  default = true 
}
