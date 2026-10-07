data "aws_caller_identity" "current" {}

locals {
  # Permissions boundary owned by personal-technology/bootstrap/aws. The CI apply
  # role may only create or modify IAM roles that carry exactly this boundary, so
  # every workload role here MUST set `permissions_boundary = local.workload_boundary_arn`.
  workload_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/policy-${var.platform}-workload-boundary-${var.env}-${var.iteration}"

  # AWS Resource Pattern: <abbrev>-aws-<product>-<env>-<region-code>-<iteration>
  s3_backup_bucket_name  = "s3-${var.platform}-${var.product}-${var.env}-${var.region_code}-${var.iteration}"
  iam_role_eks_connector = "role-${var.platform}-eks-connector-${var.env}-admin"

  # Bedrock Knowledge Base. The s3-/s3v-/role- "bedrock" prefixes are what the
  # workload boundary and apply role in personal-technology/bootstrap/aws allow.
  s3_bedrock_docs_bucket_name  = "s3-${var.platform}-bedrock-${var.env}-${var.region_code}-${var.iteration}"
  s3v_bedrock_vector_bucket    = "s3v-${var.platform}-bedrock-${var.env}-${var.region_code}-${var.iteration}"
  s3v_bedrock_kb_index         = "idx-company-handbook-${var.iteration}"
  bedrock_kb_name              = "kb-${var.platform}-company-handbook-${var.env}-${var.region_code}-${var.iteration}"
  iam_role_bedrock_kb          = "role-${var.platform}-bedrock-kb-${var.env}-admin"
  bedrock_embedding_model_arn  = "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v2:0"
  bedrock_embedding_dimensions = 1024
}
