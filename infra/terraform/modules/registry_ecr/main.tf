resource "aws_ecr_repository" "this" {
  count = var.create_ecr ? 1 : 0

  name = var.repo_name

  image_scanning_configuration {
    scan_on_push = true
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = var.tags
}
