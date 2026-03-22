# Try to find existing GitHub OIDC provider
data "aws_iam_openid_connect_provider" "github" {
  count = var.create_provider ? 0 : 1
  url   = "https://token.actions.githubusercontent.com"
}

# Create the OIDC provider if it doesn't exist
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_provider ? 1 : 0
  url   = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1", # GitHub's primary thumbprint
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"  # GitHub's backup thumbprint
  ]

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # Use created provider if var.create_provider is true, otherwise use data source
  oidc_provider_arn = var.create_provider ? aws_iam_openid_connect_provider.github[0].arn : data.aws_iam_openid_connect_provider.github[0].arn
}



