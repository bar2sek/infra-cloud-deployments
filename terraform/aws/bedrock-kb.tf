# ==============================================================================
# Amazon Bedrock Knowledge Base (managed RAG) on S3 Vectors
#
#   kb-corpus/*.md --(CI: aws s3 sync)--> docs bucket --(ingestion job)--> Titan
#   Text Embeddings V2 --> S3 vector index <--(Retrieve / RetrieveAndGenerate)
#
# Source documents are NOT Terraform resources: every plan would re-read them,
# and the PR plan role is denied object reads outside the state bucket. The
# apply job syncs kb-corpus/ to the bucket and starts an ingestion job instead.
# See docs/bedrock-knowledge-base.md.
# ==============================================================================

# 1. Source document bucket ------------------------------------------------------
resource "aws_s3_bucket" "bedrock_docs" {
  bucket        = local.s3_bedrock_docs_bucket_name
  force_destroy = false

  tags = {
    Name    = local.s3_bedrock_docs_bucket_name
    Purpose = "bedrock-kb-source-documents"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bedrock_docs" {
  bucket = aws_s3_bucket.bedrock_docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bedrock_docs" {
  bucket                  = aws_s3_bucket.bedrock_docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Vector store ------------------------------------------------------------------
# Encryption type and index dimension are immutable: changing either replaces
# the resource (and, for the index, requires re-ingestion).
resource "aws_s3vectors_vector_bucket" "bedrock" {
  vector_bucket_name = local.s3v_bedrock_vector_bucket

  encryption_configuration = [{
    sse_type    = "AES256"
    kms_key_arn = null
  }]
}

resource "aws_s3vectors_index" "bedrock_kb" {
  vector_bucket_name = aws_s3vectors_vector_bucket.bedrock.vector_bucket_name
  index_name         = local.s3v_bedrock_kb_index
  data_type          = "float32"
  dimension          = local.bedrock_embedding_dimensions # must equal the embedding model's output
  distance_metric    = "cosine"

  # Bedrock stores each chunk's text and its own bookkeeping as metadata on the
  # vector. Declared non-filterable so they don't count against the (small)
  # filterable-metadata limit per vector.
  metadata_configuration {
    non_filterable_metadata_keys = ["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]
  }
}

# 3. Knowledge Base service role ------------------------------------------------
# Bedrock assumes this role to read documents, call the embedding model, and
# write vectors. The trust is limited to this account's knowledge bases
# (aws:SourceAccount + aws:SourceArn) to prevent confused-deputy use.
resource "aws_iam_role" "bedrock_kb" {
  name                 = local.iam_role_bedrock_kb
  permissions_boundary = local.workload_boundary_arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "bedrock.amazonaws.com" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
          ArnLike      = { "aws:SourceArn" = "arn:aws:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*" }
        }
      }
    ]
  })

  tags = {
    Name = local.iam_role_bedrock_kb
  }
}

# Exact resources only; the boundary is the ceiling, this is the actual grant.
resource "aws_iam_role_policy" "bedrock_kb" {
  name = "bedrock-kb-access"
  role = aws_iam_role.bedrock_kb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EmbedDocuments"
        Effect   = "Allow"
        Action   = "bedrock:InvokeModel"
        Resource = local.bedrock_embedding_model_arn
      },
      {
        Sid      = "ListSourceBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.bedrock_docs.arn
        Condition = {
          StringEquals = { "aws:ResourceAccount" = data.aws_caller_identity.current.account_id }
        }
      },
      {
        Sid      = "ReadSourceDocuments"
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.bedrock_docs.arn}/*"
        Condition = {
          StringEquals = { "aws:ResourceAccount" = data.aws_caller_identity.current.account_id }
        }
      },
      {
        Sid    = "ReadWriteVectorIndex"
        Effect = "Allow"
        Action = [
          "s3vectors:GetIndex",
          "s3vectors:PutVectors",
          "s3vectors:GetVectors",
          "s3vectors:QueryVectors",
          "s3vectors:DeleteVectors",
        ]
        Resource = aws_s3vectors_index.bedrock_kb.index_arn
      }
    ]
  })
}

# IAM is eventually consistent: a role can exist before Bedrock is able to
# assume it, and CreateKnowledgeBase validates the role immediately.
resource "time_sleep" "bedrock_kb_role_propagation" {
  create_duration = "20s"

  triggers = {
    role_policy = aws_iam_role_policy.bedrock_kb.policy
  }
}

# 4. Knowledge Base ----------------------------------------------------------------
resource "aws_bedrockagent_knowledge_base" "company_handbook" {
  name        = local.bedrock_kb_name
  description = "Synthetic company policy handbook (lab corpus) for RAG demos"
  role_arn    = aws_iam_role.bedrock_kb.arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = local.bedrock_embedding_model_arn

      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = local.bedrock_embedding_dimensions
          embedding_data_type = "FLOAT32"
        }
      }
    }
  }

  storage_configuration {
    type = "S3_VECTORS"

    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.bedrock_kb.index_arn
    }
  }

  tags = {
    Name = local.bedrock_kb_name
  }

  depends_on = [time_sleep.bedrock_kb_role_propagation]
}

# 5. Data source -------------------------------------------------------------------
resource "aws_bedrockagent_data_source" "company_handbook" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.company_handbook.id
  name              = "s3-company-handbook"

  # DELETE: removing this data source also removes its vectors, so nothing is
  # orphaned in the index.
  data_deletion_policy = "DELETE"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = aws_s3_bucket.bedrock_docs.arn
    }
  }

  # ~300-token chunks with 20% overlap: small policy documents, so each chunk
  # stays on one topic and an answer rarely straddles a boundary.
  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"

      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}
