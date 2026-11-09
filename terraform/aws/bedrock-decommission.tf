# ==============================================================================
# Bedrock Knowledge Base decommission (2026-11-09)
#
# The Bedrock lab (Knowledge Base, data source, S3 Vectors index, Guardrail and
# KB service role) is retired. Deleting bedrock-kb.tf / bedrock-guardrail.tf
# makes this apply DESTROY those resources.
#
# The two buckets are different: the CI apply role is deliberately denied
# s3:DeleteBucket and s3vectors:DeleteVectorBucket ("configuration only, never
# delete a bucket"). Destroying them here would fail the apply half-way, so
# these `removed` blocks drop them from state WITHOUT touching AWS. An
# administrator then deletes them by hand (personal-technology docs/413,
# stage 3).
#
# Follow-up PR, after stage 3: delete this file and the `time` provider in
# providers.tf. Both must stay until then: Terraform needs the `time` provider
# to destroy time_sleep.bedrock_kb_role_propagation, which is still in state.
# ==============================================================================

removed {
  from = aws_s3_bucket.bedrock_docs

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3_bucket_server_side_encryption_configuration.bedrock_docs

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3_bucket_public_access_block.bedrock_docs

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_s3vectors_vector_bucket.bedrock

  lifecycle {
    destroy = false
  }
}
