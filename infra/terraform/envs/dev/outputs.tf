output "role_arn" {
  value = module.iam_github_oidc.role_arn
}

output "instance_public_ip" {
  value = module.compute.public_ip
}

output "instance_id" {
  value = module.compute.instance_id
}

output "ecr_repo_url" {
  value       = module.ecr.repository_url
  description = "Null if create_ecr=false"
}

output "tls_mode" {
  value = module.dns_tls.mode
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
  value = module.iam_ec2_instance_profile.instance_profile_name
}
