#############################
# Production Environment Vars
#############################

variable "github_org" {
  type        = string
  description = "GitHub organization or username that owns the app repo."
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name."
}

variable "github_branch" {
  type        = string
  description = "Branch to deploy from."
  default     = "main"
}

variable "env" {
  type        = string
  description = "Environment name (should be 'prod' for this folder)."
}

# ==== Compute ====
variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 host (e.g., Amazon Linux 2023 for your region)."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the host."
  # modest prod default; adjust as needed
  default     = "t3.small"
}

# If your module supports passing an existing instance profile name/arn for SSM/ECR.
variable "instance_profile" {
  type        = string
  description = "Optional instance profile name/arn for the EC2 host (SSM/ECR access)."
  default     = null
}

# ==== Container Registry ====
variable "create_ecr" {
  type        = bool
  description = "Create an ECR repository for images."
  default     = true
}

variable "ecr_repo_name" {
  type        = string
  description = "ECR repository name (if create_ecr = true)."
  default     = "backenderer-apps"
}

# ==== DNS / TLS ====
variable "tls_mode" {
  type        = string
  description = "TLS mode: 'none', 'letsencrypt', or 'alb_acm'."
  default     = "none"
  validation {
    condition     = contains(["none", "letsencrypt", "alb_acm"], var.tls_mode)
    error_message = "tls_mode must be one of: none, letsencrypt, alb_acm."
  }
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 Hosted Zone ID (required if tls_mode uses DNS)."
  default     = null
}

variable "base_domain" {
  type        = string
  description = "Base domain for apps (e.g., apps.example.com). Required if using DNS/TLS."
  default     = null
}

# Tags
variable "tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    project = "Backenderer"
    owner   = "dev-team"
  }
}
