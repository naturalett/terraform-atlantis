resource "github_repository_webhook" "atlantis" {
  count = var.create ? length(var.webhook_list) : 0

  repository = var.webhook_list[count.index]

  configuration {
    url          = "${module.atlantis.url}/events"
    content_type = "application/json"
    insecure_ssl = false
    secret       = random_password.webhook_secret.result
  }

  events = [
    "issue_comment",
    "pull_request",
    "pull_request_review",
    "pull_request_review_comment",
  ]
}

resource "random_password" "webhook_secret" {
  length  = 32
  special = false
}

module "secrets_manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.0"

  for_each = {
    github-webhook-secret = {
      secret_string = random_password.webhook_secret.result
    }
  }

  # Secret
  name_prefix             = each.key
  recovery_window_in_days = 0
  secret_string           = each.value.secret_string

}
