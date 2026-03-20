variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in owner/repo form."
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

# If your module supports passing an existing instance profile name/arn for SSM/ECR.
variable "instance_profile" {
  type        = string
  description = "Optional instance profile name/arn for the EC2 host (SSM/ECR access)."
  default     = null
}

variable "create_ecr" {
  type        = bool
  description = "Create an ECR repository for images."
  default     = true
}

variable "ecr_repo_name" {
  type        = string
  description = "Optional ECR repository name override."
  default     = null
}

variable "tls_mode" {
  type        = string
  description = "TLS mode: none or alb_acm."
  default     = "none"
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
