variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "env" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

variable "github_repo" {
  description = "GitHub repository in owner/repo form"
  type        = string
}

# Compute module inputs
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "name_prefix" {
  description = "Prefix for naming AWS resources (e.g., repo or project name)"
  type        = string
  default     = "backenderer"
}

variable "create_ecr" {
  description = "Whether to create the ECR repository"
  type        = bool
  default     = true
}

variable "ecr_repo_name" {
  description = "Optional ECR repository name override"
  type        = string
  default     = null
}

variable "tls_mode" {
  description = "TLS mode: none | alb_acm"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "alb_acm"], var.tls_mode)
    error_message = "tls_mode must be one of: none, alb_acm."
  }
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

variable "server_name" {
  description = "Primary hostname served by this environment"
  type        = string
  default     = ""
}

variable "instance_profile" {
  type        = string
  description = "Optional instance profile name/arn for the EC2 host (SSM/ECR access)."
  default     = null
}

# Tags
variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
