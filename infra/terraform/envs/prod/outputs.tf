output "role_arn" {
  value       = module.iam_github_oidc.role_arn
  description = "IAM role ARN for GitHub OIDC deploys."
}

output "instance_id" {
  value       = module.compute.instance_id
  description = "EC2 instance ID."
}

output "instance_public_ip" {
  value       = module.compute.public_ip
  description = "EC2 public IP address."
}

output "ecr_repo_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL if created."
}

output "tls_mode" {
  value       = module.dns_tls.mode
  description = "Configured TLS mode."
}

output "a_record_fqdns" {
  value       = module.dns_tls.a_record_fqdns
  description = "Only when DNS records are created in none mode."
}

output "alb_dns_name" {
  value       = module.dns_tls.alb_dns_name
  description = "Only when tls_mode = alb_acm."
}

output "acm_certificate_arn" {
  value       = module.dns_tls.acm_certificate_arn
  description = "Only when tls_mode = alb_acm."
}

output "instance_profile_name" {
  value       = module.iam_ec2_instance_profile.instance_profile_name
  description = "EC2 instance profile attached to the host."
}
