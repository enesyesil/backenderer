variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "env" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
  default     = "dev"
}

# GitHub OIDC inputs
variable "github_org" {
  description = "GitHub org name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name"
  type        = string
}

variable "github_branch" {
  description = "Branch for OIDC trust"
  type        = string
  default     = "main"
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

variable "instance_profile" {
  description = "IAM instance profile for EC2"
  type        = string
}

# ECR module inputs
variable "create_ecr" {
  description = "Whether to create the ECR repository"
  type        = bool
  default     = true
}

variable "ecr_repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "backenderer"
}

# TLS / DNS inputs
variable "tls_mode" {
  description = "TLS mode: none | letsencrypt | alb_acm"
  type        = string
  default     = "none"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
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
