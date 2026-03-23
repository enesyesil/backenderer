locals {
  resource_prefix = "${var.name_prefix}-${var.env}"
  repository_name = "backenderer-apps-${var.env}"
  common_tags = merge(
    {
      env     = var.env
      project = "backenderer"
    },
    var.tags,
  )
}

module "iam_github_oidc" {
  source              = "../../modules/iam_github_oidc"
  repo                = var.github_repo
  oidc_provider_arn   = var.oidc_provider_arn
  role_name           = "${local.resource_prefix}-github-actions-role"
  allowed_refs        = ["repo:${var.github_repo}:ref:refs/heads/main"]
  ecr_repository_name = local.repository_name
  env                 = var.env
  resource_prefix     = local.resource_prefix
  route53_zone_id     = var.route53_zone_id
  state_bucket_name   = var.state_bucket_name
  tags                = local.common_tags
}

module "network" {
  source           = "../../modules/network_minimal"
  name_prefix      = local.resource_prefix
  private_app_host = var.tls_mode == "alb_acm"
  tags             = local.common_tags
}

module "iam_ec2_instance_profile" {
  source      = "../../modules/iam_ec2_instance_profile"
  name_prefix = local.resource_prefix
  tags        = local.common_tags
}

module "ecr" {
  source    = "../../modules/registry_ecr"
  repo_name = local.repository_name
  tags      = local.common_tags
}

module "compute" {
  source                    = "../../modules/compute_vm_docker_nginx"
  name_prefix               = local.resource_prefix
  ami_id                    = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = module.network.app_subnet_id
  assign_public_ip          = var.tls_mode == "none"
  public_ingress_enabled    = var.tls_mode == "none"
  public_ingress_port       = 80
  security_group_ids        = []
  iam_instance_profile      = coalesce(var.instance_profile, module.iam_ec2_instance_profile.instance_profile_name)
  env                       = var.env
  register_script_content   = file("${path.root}/../../../../scripts/register.sh")
  unregister_script_content = file("${path.root}/../../../../scripts/unregister.sh")
}

module "dns_tls" {
  source             = "../../modules/dns_tls"
  mode               = var.tls_mode
  name_prefix        = local.resource_prefix
  domain_names       = trimspace(var.server_name) != "" && var.server_name != "_" ? [var.server_name] : []
  hosted_zone_id     = var.route53_zone_id
  create_dns_records = trimspace(var.route53_zone_id) != "" && trimspace(var.server_name) != "" && var.server_name != "_"
  health_path        = var.health_path
  instance_public_ip = module.compute.public_ip
  target_instance_id = module.compute.instance_id
  subnet_ids         = module.network.alb_subnet_ids
  vpc_id             = module.network.vpc_id
  env                = var.env
  tags               = local.common_tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_app" {
  count = var.tls_mode == "alb_acm" ? 1 : 0

  security_group_id            = module.compute.security_group_id
  referenced_security_group_id = module.dns_tls.alb_security_group_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}
