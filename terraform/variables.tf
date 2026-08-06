variable "aws_region" {
  description = "The AWS region to deploy into"
  default     = "us-east-1"
}

variable "project_name" {
  description = "The base name for project resources"
  default     = "event-ticketing"
}

variable "github_repo" {
  description = "Your GitHub repository (Format: username/repo-name)"
  default     = "Manu-world/serveless-event-ticketing"
}

# Required for GitHub's immutable OIDC subject claims (repos created after 2026-07-15)
variable "github_owner_id" {
  description = "Numeric GitHub owner/org ID used in OIDC sub claims"
  default     = "138615921"
}

variable "github_repo_id" {
  description = "Numeric GitHub repository ID used in OIDC sub claims"
  default     = "1325358812"
}

locals {
  github_owner = split("/", var.github_repo)[0]
  github_name  = split("/", var.github_repo)[1]

  # Support both legacy and immutable GitHub Actions OIDC subject formats
  github_oidc_subs = [
    "repo:${var.github_repo}:ref:refs/heads/main",
    "repo:${local.github_owner}@${var.github_owner_id}/${local.github_name}@${var.github_repo_id}:ref:refs/heads/main",
  ]

  common_tags = {
    Project     = var.project_name
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "manu"
  }
}
