variable "repo_name" {
  description = "ECR repository name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the repository"
  type        = map(string)
  default     = {}
}
