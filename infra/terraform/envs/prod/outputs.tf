#############################
# Production Environment Outputs
#############################

# GitHub OIDC deploy role
output "role_arn" {
  description = "IAM role ARN for GitHub OIDC deploys."
  value       = module.iam_github_oidc.role_arn
}

# EC2 host
output "instance_id" {
  description = "EC2 instance ID."
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "EC2 public IP address."
  value       = module.compute.instance_public_ip
}

# ECR repo URL (module name/attr may differ; try handles either)
output "ecr_repo_url" {
  description = "ECR repo URL if created."
  value       = try(module.ecr.repo_url, module.ecr.ecr_repo_url, null)
}

# ALB DNS name (only if TLS module created an ALB)
output "alb_dns_name" {
  description = "ALB DNS name (if using ALB/TLS)."
  value       = try(module.dns_tls.alb_dns_name, null)
}
