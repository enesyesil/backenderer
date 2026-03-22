variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in owner/repo form."
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
  type        = string
  description = "ARN of the shared GitHub OIDC provider created by bootstrap."
}

variable "state_bucket_name" {
  type        = string
  description = "Terraform state bucket name used by CI and IAM policies."
}

variable "env" {
  type        = string
  description = "Environment name (should be 'prod' for this folder)."
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 host (e.g., Amazon Linux 2023 for your region)."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the host."
  # modest prod default; adjust as needed
  default = "t3.small"
}

variable "name_prefix" {
  type        = string
  description = "Prefix for naming AWS resources (e.g., repo or project name)."
  default     = "backenderer"
}

# If your module supports passing an existing instance profile name/arn for SSM/ECR.
variable "instance_profile" {
  type        = string
  description = "Optional instance profile name/arn for the EC2 host (SSM/ECR access)."
  default     = null
}

variable "tls_mode" {
  type        = string
  description = "TLS mode: none or alb_acm."
  default     = "alb_acm"
  validation {
    condition     = contains(["none", "alb_acm"], var.tls_mode)
    error_message = "tls_mode must be one of: none, alb_acm."
  }
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 Hosted Zone ID (required if tls_mode uses DNS)."
  default     = ""
}

variable "server_name" {
  type        = string
  description = "Primary hostname served by this environment."
  default     = ""
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
