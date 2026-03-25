variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "project_name" {
  type = string
}

variable "environment" {
  type    = string
  default = "develop"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "staging / develop true for cut costs"
}
