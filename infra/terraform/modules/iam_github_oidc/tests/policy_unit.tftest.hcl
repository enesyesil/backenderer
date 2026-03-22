override_data {
  target = data.aws_caller_identity.current
  values = {
    account_id = "123456789012"
  }
}

override_data {
  target = data.aws_partition.current
  values = {
    partition = "aws"
  }
}

override_data {
  target = data.aws_region.current
  values = {
    name = "us-east-1"
  }
}

variables {
  repo                = "owner/repo"
  oidc_provider_arn   = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  role_name           = "backenderer-dev-github-actions-role"
  ecr_repository_name = "backenderer-apps-dev"
  env                 = "dev"
  resource_prefix     = "backenderer-dev"
  route53_zone_id     = ""
  state_bucket_name   = "backenderer-tf-state"
  tags                = {}
  create_resources    = false
}

run "policy_includes_expected_permissions" {
  command = plan

  assert {
    condition     = strcontains(data.aws_iam_policy_document.gh_ci.json, "\"ec2:AssociateRouteTable\"")
    error_message = "Expected ec2:AssociateRouteTable in the CI policy."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.gh_ci.json, "\"ssm:resourceTag/Backenderer\"")
    error_message = "Expected the SSM statement to scope access by the Backenderer tag."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.gh_ci.json, "\"dev\"")
    error_message = "Expected the environment tag scope to match the dev environment."
  }

  assert {
    condition     = strcontains(data.aws_iam_policy_document.gh_ci.json, "arn:aws:ecr:us-east-1:123456789012:repository/backenderer-apps-dev")
    error_message = "Expected the generated policy to use the mocked us-east-1 region."
  }
}
