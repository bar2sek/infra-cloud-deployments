terraform {
  required_version = ">= 1.10.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
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
  backend "s3" {
    key          = "cloudflare-workloads/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
