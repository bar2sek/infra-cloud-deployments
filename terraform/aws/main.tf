# ==============================================================================
# AWS Cloud Infrastructure Workloads
# Deployed automatically via GitHub Actions (infra-cloud-deployments)
# ==============================================================================

# 1. Encrypted Offsite Backup S3 Bucket
resource "aws_s3_bucket" "backups" {
  bucket        = local.s3_backup_bucket_name
  force_destroy = false

  tags = {
    Name    = local.s3_backup_bucket_name
    Purpose = "offsite-backups"
  }
}

# Enable Server-Side Encryption (AES256) on Backup Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "backups_crypto" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access on Backup S3 Bucket
resource "aws_s3_bucket_public_access_block" "backups_privacy" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable Object Versioning on Backup S3 Bucket
resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 2. AWS EKS Connector IAM Role
resource "aws_iam_role" "eks_connector" {
  name = local.iam_role_eks_connector

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = local.iam_role_eks_connector
  }
}

# Customer-Managed Policy for EKS Connector Agent (per official AWS EKS Connector specifications)
resource "aws_iam_policy" "eks_connector_agent" {
  name        = "policy-aws-eks-connector-agent-prod-001"
  description = "Allows the Amazon EKS Connector agent to connect external Kubernetes clusters to AWS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SsmControlChannel"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel"
        ]
        Resource = "arn:aws:eks:*:*:cluster/*"
      },
      {
        Sid    = "SsmDataplaneOperations"
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenDataChannel",
          "ssmmessages:OpenControlChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_connector_policy" {
  role       = aws_iam_role.eks_connector.name
  policy_arn = aws_iam_policy.eks_connector_agent.arn
}
