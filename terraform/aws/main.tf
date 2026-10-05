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

# Backup Retention Lifecycle
#
# Object Lock (GOVERNANCE, 30-day default retention) and the bucket policy are
# guardrails owned by personal-technology/bootstrap/aws, not by this pipeline;
# the CI apply role is explicitly denied from changing them. Lifecycle stays here
# because it cannot weaken them: S3 lifecycle never deletes a locked version.
#
# Timeline per backup: locked days 0-30, current version expires (becomes
# noncurrent) on day 35, permanently removed on day 36.
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  depends_on = [aws_s3_bucket_versioning.backups]

  rule {
    id     = "expire-backups-after-35-days"
    status = "Enabled"

    filter {}

    expiration {
      days = 35
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  rule {
    id     = "remove-expired-delete-markers"
    status = "Enabled"

    filter {}

    expiration {
      expired_object_delete_marker = true
    }
  }
}

# 2. AWS EKS Connector IAM Role
resource "aws_iam_role" "eks_connector" {
  name                 = local.iam_role_eks_connector
  permissions_boundary = local.workload_boundary_arn

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
