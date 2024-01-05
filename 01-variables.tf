variable "atlantis_repo_allowlist" {
  default = ["github.com/example/*"]
}

variable "webhook_list" {
  default = ["terraform-atlantis"]
}

variable "create" {
  description = "Whether to create Github repository webhook for Atlantis"
  type        = bool
  default     = true
}

variable "repository_owner" {
  default = "example"
}

variable "env" {}
variable "account_id" {}
variable "region" {}
variable "certificate_domain_name" {}
variable "route53_zone_id" {}
