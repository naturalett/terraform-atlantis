terraform {
  required_version = ">= 1.2.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.23.1"
    }
  }
}

provider "github" {
  token = jsondecode(nonsensitive(data.aws_secretsmanager_secret_version.github_token.secret_string))["key"]
  owner = var.repository_owner
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      CreatedBy   = "terraform"
      Environment = var.env
    }
  }
}
