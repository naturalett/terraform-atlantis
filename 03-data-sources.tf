data "aws_secretsmanager_secret_version" "github_token" {
  secret_id = "/github/token"
}

data "aws_secretsmanager_secret_version" "github_token_plaintext" {
  secret_id = "/github/token_plaintext"
}

data "aws_secretsmanager_secret_version" "datadog_api_key_plaintext" {
  secret_id = "/datadog/api_key_plaintext"
}

data "github_ip_ranges" "ip_list" {}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "subnet_ids_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}

data "aws_subnets" "subnet_ids_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["public"]
  }
}
