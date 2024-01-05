terraform {
  backend "s3" {
    bucket         = "terraform-state"
    key            = "ecs"
    region         = "us-east-1"
    dynamodb_table = "Terraform"

    role_arn = "arn:aws:iam::<ACCOUNT ID>:role/Terraform"
  }
}
