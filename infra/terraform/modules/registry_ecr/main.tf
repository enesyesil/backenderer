resource "aws_ecr_repository" "this" {
  count = var.create_ecr ? 1 : 0

  name         = var.repo_name
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}
