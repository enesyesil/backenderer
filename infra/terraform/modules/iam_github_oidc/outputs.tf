output "role_arn" {
  description = "IAM Role ARN for GitHub Actions to assume"
  value       = aws_iam_role.gh_actions.arn
}

