output "arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = local.oidc_provider_arn
}

output "url" {
  description = "URL of the GitHub OIDC provider"
  value       = "https://token.actions.githubusercontent.com"
}



