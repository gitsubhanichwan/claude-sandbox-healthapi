terraform {
  required_version = ">= 1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.71"
    }
  }

  # Bucket is passed at init time so the account ID never lands in the repo:
  #   terraform init -backend-config="bucket=<state_bucket output of infra/bootstrap>"
  backend "s3" {
    key          = "healthapi/terraform.tfstate"
    region       = "ap-southeast-3"
    encrypt      = true
    use_lockfile = true
  }
}

locals {
  common_tags = {
    Project   = "claude-code-trial"
    Owner     = "subhan"
    ManagedBy = "terraform"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = merge(local.common_tags, { Environment = "shared" })
  }
}

provider "aws" {
  alias  = "staging"
  region = var.region

  default_tags {
    tags = merge(local.common_tags, { Environment = "staging" })
  }
}

provider "aws" {
  alias  = "production"
  region = var.region

  default_tags {
    tags = merge(local.common_tags, { Environment = "production" })
  }
}
