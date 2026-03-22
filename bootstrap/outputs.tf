output "state_bucket" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.state.bucket
}

output "region" {
  description = "Region where the backend is hosted"
  value       = var.region
}

output "oidc_provider_arn" {
  description = "ARN of the shared GitHub OIDC provider."
  value       = module.iam_github_oidc_provider.arn
}

output "oidc_provider_url" {
  description = "URL of the shared GitHub OIDC provider."
  value       = module.iam_github_oidc_provider.url
}
