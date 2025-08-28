data "aws_caller_identity" "current" {}

# GitHub Actions OIDC identity provider
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = var.tags
}

# Exact subject restriction (org/repo/branch)
locals {
  sub = "repo:${var.org}/${var.repo}:ref:refs/heads/${var.branch}"
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "gh_actions" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
      Action    = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub" = local.sub
        }
      }
    }]
  })

  tags = var.tags
}

# Inline IAM Policy — least privilege
resource "aws_iam_role_policy" "gh_actions_inline" {
  name = var.policy_name
  role = aws_iam_role.gh_actions.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EcrPushPull",
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:DescribeRepositories"
        ],
        # Scoped to the ECR repo only
        Resource = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repo_name}"
      },
      {
        Sid    = "SsmSendCommandScoped",
        Effect = "Allow",
        Action = [
          "ssm:SendCommand",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations"
        ],
        # Only AWS-RunShellScript document
        Resource = "arn:aws:ssm:*:*:document/AWS-RunShellScript",
        Condition = {
          StringEquals = {
            # Limit to instances with this tag (set on EC2 in compute module)
            "ssm:resourceTag/Backenderer" = var.env
          }
        }
      },
      {
        Sid    = "Ec2Describe",
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ],
        Resource = "*"
      }
    ]
  })
}
