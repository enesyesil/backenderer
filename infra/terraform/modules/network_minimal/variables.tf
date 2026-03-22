variable "name_prefix" {
  description = "Prefix for network resource names."
  type        = string
}

variable "private_app_host" {
  description = "Whether to place the app host in a private subnet."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to network resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the managed VPC."
  type        = string
  default     = "10.0.0.0/16"
}
