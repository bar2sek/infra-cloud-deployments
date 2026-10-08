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

output "bedrock_kb_id" {
  description = "Bedrock Knowledge Base ID (used by the CI ingestion step and Retrieve calls)"
  value       = aws_bedrockagent_knowledge_base.company_handbook.id
}

output "bedrock_kb_data_source_id" {
  description = "Bedrock Knowledge Base S3 data source ID"
  value       = aws_bedrockagent_data_source.company_handbook.data_source_id
}

output "bedrock_docs_bucket_name" {
  description = "S3 bucket the CI apply job syncs kb-corpus/ into"
  value       = aws_s3_bucket.bedrock_docs.bucket
}

output "bedrock_guardrail_id" {
  description = "Bedrock Guardrail ID (pass as guardrailIdentifier)"
  value       = aws_bedrock_guardrail.company_handbook.guardrail_id
}

output "bedrock_guardrail_version" {
  description = "Published, immutable Guardrail version for callers to pin"
  value       = aws_bedrock_guardrail_version.company_handbook.version
}
