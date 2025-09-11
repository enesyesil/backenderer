resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = var.tags
}

locals { sub = "repo:${var.org}/${var.repo}:ref:refs/heads/${var.branch}" }

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals { 
      type = "Federated" 
      identifiers = [aws_iam_openid_connect_provider.github.arn] 
      }
    condition { 
      test = "StringEquals" 
      variable = "token.actions.githubusercontent.com:aud" 
      values = ["sts.amazonaws.com"] 
      }
    condition { 
      test = "StringEquals" 
      variable = "token.actions.githubusercontent.com:sub" 
      values = [local.sub] 
      }
  }
}

resource "aws_iam_role" "gha" {
  name               = "backenderer-gha-${var.repo}"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "gha_policy" {
  statement {
    sid     = "Backenderer"
    effect  = "Allow"
    actions = [
      "sts:AssumeRole","iam:PassRole",
      "s3:*","ec2:*","ecr:*","ssm:*","logs:*","cloudwatch:*",
      "route53:*","acm:*","elasticloadbalancing:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "gha" {
  role   = aws_iam_role.gha.id
  policy = data.aws_iam_policy_document.gha_policy.json
}

output "role_arn" { value = aws_iam_role.gha.arn }