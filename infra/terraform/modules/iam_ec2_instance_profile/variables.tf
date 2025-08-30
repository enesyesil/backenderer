variable "name_prefix" {
  description = "Prefix for IAM resources (e.g., backenderer-dev)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}


