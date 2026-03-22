variable "mode" {
  description = "TLS mode: none | alb_acm"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "alb_acm"], var.mode)
    error_message = "mode must be one of: none, alb_acm."
  }
}

variable "domain_names" {
  description = "Fully-qualified domain names (FQDNs) to serve."
  type        = list(string)
  default     = []
}

variable "name_prefix" {
  description = "Prefix for DNS and load balancer resource names."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID that holds the domains (required for ALB/ACM and for creating A/ALIAS records)."
  type        = string
  default     = ""
}

variable "create_dns_records" {
  description = "Create Route53 A/ALIAS records for the domains."
  type        = bool
  default     = false
}

variable "instance_public_ip" {
  description = "Public IPv4 of the VM (used to create A-records when mode != alb_acm)."
  type        = string
  default     = ""
}

variable "target_instance_id" {
  description = "EC2 instance ID to target behind the ALB (mode=alb_acm)."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID (required for ALB)."
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnets for the ALB."
  type        = list(string)
  default     = []
}

variable "health_path" {
  description = "Path used for ALB and deploy-time application health checks."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}

variable "env" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}
