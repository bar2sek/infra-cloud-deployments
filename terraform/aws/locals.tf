data "aws_caller_identity" "current" {}

locals {
  # Permissions boundary owned by personal-technology/bootstrap/aws. The CI apply
  # role may only create or modify IAM roles that carry exactly this boundary, so
  # every workload role here MUST set `permissions_boundary = local.workload_boundary_arn`.
  workload_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/policy-${var.platform}-workload-boundary-${var.env}-${var.iteration}"

  # AWS Resource Pattern: <abbrev>-aws-<product>-<env>-<region-code>-<iteration>
  s3_backup_bucket_name  = "s3-${var.platform}-${var.product}-${var.env}-${var.region_code}-${var.iteration}"
  iam_role_eks_connector = "role-${var.platform}-eks-connector-${var.env}-admin"
}
