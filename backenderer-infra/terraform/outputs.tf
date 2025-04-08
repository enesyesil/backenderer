output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecr_repo_url" {
  value = aws_ecr_repository.app_repo.repository_url
}

output "log_group" {
  value = aws_cloudwatch_log_group.ecs_logs.name
}
