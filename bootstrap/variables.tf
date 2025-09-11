variable "project" {
  description = "Short project slug used in names/tags (e.g., backenderer)"
  type        = string
}

variable "region" {
  description = "AWS region for state storage"
  type        = string
  default     = "ca-central-1"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
