terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "s3-aws-tfstate-prod-use2-REDACTED_ACCOUNT_ID"
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
