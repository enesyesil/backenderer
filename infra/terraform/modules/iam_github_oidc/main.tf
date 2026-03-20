locals {
  # If allowed_refs is empty, allow the whole repo (all branches/tags)
  sub_values = length(var.allowed_refs) > 0 ? var.allowed_refs : ["repo:${var.repo}:*"]
}

data "aws_iam_policy_document" "gh_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = [var.audience]
    }

    # Only your repo (and, if provided, only specific refs)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.sub_values
    }
  }
}

resource "aws_iam_role" "gh_actions" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.gh_trust.json
  tags               = var.tags
}

# ---- Minimal inline policy for CI (tighten as needed) ----
# Scope this to what your workflows actually touch.
data "aws_iam_policy_document" "gh_ci" {
  statement {
    sid = "S3State"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRPushPull"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:CreateRepository"
    ]
    resources = ["*"]
  }

  statement {
    sid = "EC2DescribeAndSSM"
    actions = [
      "ec2:Describe*",
      "ssm:SendCommand",
      "ssm:ListCommands",
      "ssm:ListCommandInvocations",
      "iam:PassRole"
    ]
    resources = ["*"]
  }

  statement {
    sid = "Route53andACM"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListHostedZonesByName",
      "route53:GetChange",
      "acm:RequestCertificate",
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:DeleteCertificate"
    ]
    resources = ["*"]
  }

  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "gh_actions" {
  role   = aws_iam_role.gh_actions.id
  policy = data.aws_iam_policy_document.gh_ci.json
}
