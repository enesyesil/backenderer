output "repository_url" {
  description = "ECR repository URL (or null if not created)"
  value       = var.create_ecr ? aws_ecr_repository.this[0].repository_url : null
}
