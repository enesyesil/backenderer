locals {
  resource_prefix = "${var.name_prefix}-${var.env}"
  common_tags = merge(
    {
      env     = var.env
      project = "backenderer"
    },
    var.tags,
  )
}

module "iam_github_oidc_provider" {
  source          = "../../modules/iam_github_oidc_provider"
  create_provider = true
  tags            = local.common_tags
}

module "iam_github_oidc" {
  source            = "../../modules/iam_github_oidc"
  repo              = var.github_repo
  oidc_provider_arn = module.iam_github_oidc_provider.arn
  role_name         = "${local.resource_prefix}-github-actions-role"
  tags              = local.common_tags
}

module "network" {
  source = "../../modules/network_minimal"
}

module "iam_ec2_instance_profile" {
  source      = "../../modules/iam_ec2_instance_profile"
  name_prefix = local.resource_prefix
  tags        = local.common_tags
}

module "ecr" {
  source     = "../../modules/registry_ecr"
  create_ecr = var.create_ecr
  repo_name  = coalesce(var.ecr_repo_name, "backenderer-apps-${var.env}")
  tags       = local.common_tags
}

module "compute" {
  source                    = "../../modules/compute_vm_docker_nginx"
  name_prefix               = local.resource_prefix
  ami_id                    = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = module.network.subnet_id
  security_group_ids        = []
  iam_instance_profile      = coalesce(var.instance_profile, module.iam_ec2_instance_profile.instance_profile_name)
  env                       = var.env
  register_script_content   = file("${path.root}/../../../../scripts/register.sh")
  unregister_script_content = file("${path.root}/../../../../scripts/unregister.sh")
}

module "dns_tls" {
  source             = "../../modules/dns_tls"
  mode               = var.tls_mode
  domain_names       = trimspace(var.server_name) != "" && var.server_name != "_" ? [var.server_name] : []
  hosted_zone_id     = var.route53_zone_id
  create_dns_records = trimspace(var.route53_zone_id) != "" && trimspace(var.server_name) != "" && var.server_name != "_"
  instance_public_ip = module.compute.public_ip
  target_instance_id = module.compute.instance_id
  vpc_id             = module.network.vpc_id
  env                = var.env
  tags               = local.common_tags
}
