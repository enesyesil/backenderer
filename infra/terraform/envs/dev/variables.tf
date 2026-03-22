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

variable "health_path" {
  description = "Application health-check path served by the deployed app."
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.health_path, "/")
    error_message = "health_path must start with '/'."
  }
}

variable "oidc_provider_arn" {
  description = "ARN of the shared GitHub OIDC provider created by bootstrap."
  type        = string
}

variable "state_bucket_name" {
  description = "Terraform state bucket name used by CI and IAM policies."
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
