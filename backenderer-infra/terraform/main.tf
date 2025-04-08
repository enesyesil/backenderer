# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"
}

# ECR Repository
resource "aws_ecr_repository" "app_repo" {
  name = "${var.app_name}-repo"
}

# CloudWatch Logs for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7
}
