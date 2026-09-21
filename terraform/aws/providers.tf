terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Partial backend configuration.
  #
  # `bucket` is deliberately omitted: the state bucket name embeds the AWS
  # account ID, and backend blocks cannot interpolate variables (the backend
  # initializes before any variable is evaluated). It is injected at init time:
  #
  #   CI:    terraform init -backend-config="bucket=${{ vars.AWS_TF_STATE_BUCKET }}"
  #   Local: terraform init -backend-config=backend.hcl   # gitignored, see backend.hcl.example
  #
  # Do NOT hardcode the bucket name here — this repository is public-by-default.
  backend "s3" {
    key            = "aws-workloads/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "ddb-aws-tflocks-prod-use2-001"
    encrypt        = true
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
