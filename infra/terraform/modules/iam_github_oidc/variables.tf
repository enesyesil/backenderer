variable "org" {
  description = "GitHub org"
  type        = string
}

variable "repo" {
  description = "GitHub repo"
  type        = string
}

variable "branch" {
  description = "Branch allowed to assume role"
  type        = string
  default     = "main"
}

variable "role_name" {
  description = "IAM Role name"
  type        = string
}

variable "policy_name" {
  description = "Inline policy name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "ecr_repo_name" {
  description = "ECR repo name to scope permissions"
  type        = string
}

variable "env" {
  description = "Environment tag (e.g. dev, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
