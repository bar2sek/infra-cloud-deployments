output "s3_backup_bucket_name" {
  description = "Encrypted backup S3 bucket name"
  value       = aws_s3_bucket.backups.bucket
}

output "s3_backup_bucket_arn" {
  description = "Encrypted backup S3 bucket ARN"
  value       = aws_s3_bucket.backups.arn
}

output "eks_connector_role_arn" {
  description = "AWS EKS Connector IAM Role ARN"
  value       = aws_iam_role.eks_connector.arn
}
