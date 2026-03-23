variable "repo" {
  description = "GitHub repository in org/repo form, e.g., Fisor-Analytics/backenderer"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the existing GitHub OIDC provider (bootstrap-created)"
  type        = string
}

variable "role_name" {
  description = "Name for the GitHub Actions IAM role"
  type        = string
  default     = "Backenderer-GitHubActions-Role"
}

variable "audience" {
  description = "OIDC audience for GitHub"
  type        = string
  default     = "sts.amazonaws.com"
}

variable "allowed_refs" {
  description = "List of allowed refs for CI runs (branches/tags). Examples: repo:ORG/REPO:ref:refs/heads/main"
  type        = list(string)
  default     = [] # empty = allow all refs in the repo
}

variable "ecr_repository_name" {
  description = "Managed ECR repository name for the environment."
  type        = string
}

variable "env" {
  description = "Environment name used to scope instance-tag access."
  type        = string
}

variable "resource_prefix" {
  description = "Prefix used for Terraform-managed IAM resources in this environment."
  type        = string
}

variable "route53_zone_id" {
  description = "Optional Route53 zone ID used by the environment."
  type        = string
  default     = ""
}

variable "state_bucket_name" {
  description = "Terraform state bucket name used by CI."
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "create_resources" {
  description = "Whether to create IAM resources. Disable only for policy-document tests."
  type        = bool
  default     = true
}
