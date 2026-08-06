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

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "manu"
  }
}
