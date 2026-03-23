data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

locals {
  # If allowed_refs is empty, allow the whole repo (all branches/tags)
  sub_values                   = length(var.allowed_refs) > 0 ? var.allowed_refs : ["repo:${var.repo}:*"]
  account_id                   = data.aws_caller_identity.current.account_id
  partition                    = data.aws_partition.current.partition
  region                       = data.aws_region.current.name
  state_bucket_arn             = "arn:${local.partition}:s3:::${var.state_bucket_name}"
  ecr_repository_arn           = "arn:${local.partition}:ecr:${local.region}:${local.account_id}:repository/${var.ecr_repository_name}"
  route53_zone_arn             = trimspace(var.route53_zone_id) != "" ? "arn:${local.partition}:route53:::hostedzone/${var.route53_zone_id}" : null
  certificate_arn_pattern      = "arn:${local.partition}:acm:${local.region}:${local.account_id}:certificate/*"
  role_arn_pattern             = "arn:${local.partition}:iam::${local.account_id}:role/${var.resource_prefix}-*"
  instance_profile_arn_pattern = "arn:${local.partition}:iam::${local.account_id}:instance-profile/${var.resource_prefix}-*"
  aws_run_shell_script_arn     = "arn:${local.partition}:ssm:${local.region}::document/AWS-RunShellScript"
  instance_arn_pattern         = "arn:${local.partition}:ec2:${local.region}:${local.account_id}:instance/*"
  command_arn_pattern          = "arn:${local.partition}:ssm:${local.region}:${local.account_id}:command/*"
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
  count              = var.create_resources ? 1 : 0
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
    resources = [local.state_bucket_arn, "${local.state_bucket_arn}/*"]
  }

  statement {
    sid = "ECRAuth"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRRepositoryRead"
    actions = [
      "ecr:CreateRepository",
      "ecr:DescribeRepositories"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECRRepositoryWrite"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DeleteRepository",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:PutImageScanningConfiguration",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:UploadLayerPart"
    ]
    resources = [local.ecr_repository_arn]
  }

  statement {
    sid = "TerraformComputeAndNetworking"
    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:Describe*",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateAddress",
      "ec2:DisassociateRouteTable",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:ReplaceRoute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RunInstances",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }

  statement {
    sid = "LoadBalancing"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveTags"
    ]
    resources = ["*"]
  }

  statement {
    sid = "Route53Read"
    actions = [
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = trimspace(var.route53_zone_id) != "" ? [local.route53_zone_arn] : []

    content {
      sid = "Route53Write"
      actions = [
        "route53:ChangeResourceRecordSets"
      ]
      resources = [statement.value]
    }
  }

  statement {
    sid = "ACMReadAndRequest"
    actions = [
      "acm:ListCertificates",
      "acm:RequestCertificate"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ACMCertificateManagement"
    actions = [
      "acm:AddTagsToCertificate",
      "acm:DeleteCertificate",
      "acm:DescribeCertificate",
      "acm:ListTagsForCertificate",
      "acm:RemoveTagsFromCertificate"
    ]
    resources = [local.certificate_arn_pattern]
  }

  statement {
    sid = "SSMSendCommandDocument"
    actions = [
      "ssm:SendCommand"
    ]
    resources = [
      local.aws_run_shell_script_arn
    ]
  }

  statement {
    sid = "SSMSendCommandInstances"
    actions = [
      "ssm:SendCommand"
    ]
    resources = [
      local.instance_arn_pattern
    ]

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/Backenderer"
      values   = [var.env]
    }
  }

  statement {
    sid = "SSMCommandRead"
    actions = [
      "ssm:GetCommandInvocation",
      "ssm:ListCommandInvocations",
      "ssm:ListCommands"
    ]
    resources = ["*"]
  }

  statement {
    sid = "IAMRead"
    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListOpenIDConnectProviders",
      "iam:ListRolePolicies"
    ]
    resources = ["*"]
  }

  statement {
    sid = "IAMCreateManagedRoles"
    actions = [
      "iam:CreateRole"
    ]
    resources = ["*"]
  }

  statement {
    sid = "IAMManagedRoles"
    actions = [
      "iam:AttachRolePolicy",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy"
    ]
    resources = [local.role_arn_pattern]
  }

  statement {
    sid = "IAMCreateInstanceProfiles"
    actions = [
      "iam:CreateInstanceProfile"
    ]
    resources = ["*"]
  }

  statement {
    sid = "IAMInstanceProfiles"
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:TagInstanceProfile",
      "iam:UntagInstanceProfile"
    ]
    resources = [local.instance_profile_arn_pattern]
  }
}

resource "aws_iam_role_policy" "gh_actions" {
  count  = var.create_resources ? 1 : 0
  role   = aws_iam_role.gh_actions[0].id
  policy = data.aws_iam_policy_document.gh_ci.json
}
