output "role_arn" {
  description = "IAM role ARN for GitHub OIDC deploys."
  value       = module.iam_github_oidc.role_arn
}

output "instance_public_ip" {
  description = "EC2 public IP address in tls_mode=none, otherwise null."
  value       = module.compute.public_ip
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = module.compute.instance_id
}

output "ecr_repo_url" {
  value       = module.ecr.repository_url
  description = "ECR repository URL."
}

output "tls_mode" {
  description = "Configured TLS mode."
  value       = module.dns_tls.mode
}

output "a_record_fqdns" {
  value       = module.dns_tls.a_record_fqdns
  description = "Only when DNS records are created in none mode"
}

output "alb_dns_name" {
  value       = module.dns_tls.alb_dns_name
  description = "Only when tls_mode = alb_acm"
}

output "acm_certificate_arn" {
  value       = module.dns_tls.acm_certificate_arn
  description = "Only when tls_mode = alb_acm"
}

output "instance_profile_name" {
  description = "EC2 instance profile attached to the host."
  value       = module.iam_ec2_instance_profile.instance_profile_name
}
