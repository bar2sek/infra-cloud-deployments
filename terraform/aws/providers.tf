terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.27.0 is the first release where aws_bedrockagent_knowledge_base supports
      # S3 Vectors storage (S3_VECTORS). The exact version is pinned by the lock file.
      version = "~> 6.27"
    }
  }

  # Partial backend configuration.
  #
  # `bucket` is deliberately omitted: the state bucket name embeds the AWS
  # account ID, and backend blocks cannot interpolate variables (the backend
  # initializes before any variable is evaluated). It is injected at init time:
  #
  #   CI:    terraform init -backend-config="bucket=${{ secrets.AWS_TF_STATE_BUCKET }}"
  #   Local: terraform init -backend-config=backend.hcl   # gitignored, see backend.hcl.example
  #
  # State locking uses S3 native lockfiles (Terraform 1.10+) via conditional writes,
  # eliminating the need for an external DynamoDB lock table.
  #
  # Do NOT hardcode the bucket name here — this repository is public-by-default.
  backend "s3" {
    key          = "aws-workloads/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.env
      ManagedBy   = "github-actions"
      Repository  = "infra-cloud-deployments"
    }
  }
}
