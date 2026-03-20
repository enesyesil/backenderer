variable "create_provider" {
  description = "Create the GitHub OIDC provider if it does not exist. Set to the false if the provider already exists in your AWS acc."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the OIDC provider if actually created"
  type        = map(string)
  default     = {}
}



