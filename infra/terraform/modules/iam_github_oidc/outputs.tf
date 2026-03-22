output "role_arn" {
  description = "IAM Role ARN for GitHub Actions to assume"
  value       = var.create_resources ? aws_iam_role.gh_actions[0].arn : null
}
