terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  backend "s3" {
    bucket         = "landing-zone-terraform-state-723298837109"
    key            = "security/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    use_lockfile   = true
  }
}

provider "aws" { 
  region           = var.aws_region 
  profile          = var.aws_profile
}

# Bucket esistente usato come state e per CloudTrail/Config
data "aws_s3_bucket" "state" {
  bucket = "landing-zone-terraform-state-${var.account_id}"
}


resource "aws_kms_key" "security" {
  description             = "KMS key for security resources - ${var.project_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail Encrypt"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:s3:arn" = "arn:aws:s3:::landing-zone-terraform-state-${var.account_id}/cloudtrail/*"
          }
        }
      },
      {
        Sid    = "Allow CloudTrail Decrypt"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:DecryptDataKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${var.account_id}:log-group:*"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "security" {
  name          = "alias/${var.project_name}-security"
  target_key_id = aws_kms_key.security.key_id
}


####### S3 Bucket Configuration ##########


resource "aws_s3_bucket_versioning" "state" {
  bucket = data.aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = data.aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.security.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = data.aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Policy unificata: CloudTrail + Config sullo stesso bucket
resource "aws_s3_bucket_policy" "state" {
  bucket = data.aws_s3_bucket.state.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudTrail
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = data.aws_s3_bucket.state.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${data.aws_s3_bucket.state.arn}/cloudtrail/AWSLogs/${var.account_id}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      },
      # Config
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketVersioning"
        Resource  = data.aws_s3_bucket.state.arn
      },
      {
        Sid       = "AWSConfigBucketExistenceCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:ListBucket"
        Resource  = data.aws_s3_bucket.state.arn
      },
      {
        Sid       = "AWSConfigBucketGetAcl"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = data.aws_s3_bucket.state.arn
      },
      {
        Sid       = "AWSConfigBucketPutObject"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${data.aws_s3_bucket.state.arn}/config/AWSLogs/${var.account_id}/*"
        Condition = { StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
      }
    ]
  })
}



######### CloudTrail #########


resource "aws_cloudtrail" "main" {
  name                          = "${var.project_name}-cloudtrail"
  s3_bucket_name                = data.aws_s3_bucket.state.id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn
  kms_key_id                    = aws_kms_key.security.arn

 
  depends_on = [
    aws_s3_bucket_policy.state,
    aws_iam_role_policy.cloudtrail,
    aws_cloudwatch_log_group.cloudtrail
  ]

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.security.arn
  tags              = local.common_tags
}

resource "aws_iam_role" "cloudtrail" {
  name = "${var.project_name}-cloudtrail-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail" {
  role = aws_iam_role.cloudtrail.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}



####### GuardDuty ########


resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = local.common_tags
}



######## AWS Config ########


resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-config-channel"
  s3_bucket_name = data.aws_s3_bucket.state.id
  s3_key_prefix  = "config"
  depends_on     = [
    aws_config_configuration_recorder.main,
    aws_s3_bucket_policy.state
  ]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_iam_role" "config" {
  name = "${var.project_name}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}



######## Config Rules #######


locals {
  config_rules = {
    "s3-bucket-public-read-prohibited"  = { identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED" }
    "s3-bucket-public-write-prohibited" = { identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED" }
    "s3-bucket-versioning-enabled"      = { identifier = "S3_BUCKET_VERSIONING_ENABLED" }
    "encrypted-volumes"                 = { identifier = "ENCRYPTED_VOLUMES" }
    "root-account-mfa-enabled"          = { identifier = "ROOT_ACCOUNT_MFA_ENABLED" }
    "iam-password-policy"               = { identifier = "IAM_PASSWORD_POLICY" }
    "cloudtrail-enabled"                = { identifier = "CLOUD_TRAIL_ENABLED" }
    "guardduty-enabled-centralized"     = { identifier = "GUARDDUTY_ENABLED_CENTRALIZED" }
    "vpc-flow-logs-enabled"             = { identifier = "VPC_FLOW_LOGS_ENABLED" }
    "restricted-ssh"                    = { identifier = "RESTRICTED_INCOMING_TRAFFIC" }
    "restricted-common-ports"           = { identifier = "RESTRICTED_INCOMING_TRAFFIC" }
  }

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_config_config_rule" "managed" {
  for_each = local.config_rules
  name     = each.key
  source {
    owner             = "AWS"
    source_identifier = each.value.identifier
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}



######## Security Hub ########


resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}