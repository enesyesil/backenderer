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

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
