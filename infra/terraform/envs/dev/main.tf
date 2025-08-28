terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.region
}


# OIDC IAM Role for GitHub Actions
module "iam_github_oidc" {
  source = "../../modules/iam_github_oidc"

  org            = var.github_org
  repo           = var.github_repo
  branch         = var.github_branch
  role_name      = "${var.env}-gh-actions-role"
  policy_name    = "${var.env}-gh-actions-policy"
  region         = var.region
  ecr_repo_name  = var.ecr_repo_name
  env            = var.env
  tags           = var.tags
}

# Minimal network (default VPC + subnet)
module "network" {
  source = "../../modules/network_minimal"
}

# ECR registry (optional)
module "ecr" {
  source     = "../../modules/registry_ecr"
  create_ecr = var.create_ecr
  repo_name  = var.ecr_repo_name
}

# Compute instance with Docker + Nginx
module "compute" {
  source               = "../../modules/compute_vm_docker_nginx"
  name_prefix          = var.env
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  subnet_id            = module.network.subnet_id
  security_group_ids   = []
  iam_instance_profile = var.instance_profile
  env                  = var.env
}


# TLS / DNS (Let’s Encrypt or ACM/ALB)
module "dns_tls" {
  source   = "../../modules/dns_tls"
  env      = var.env
  tls_mode = var.tls_mode
  zone_id  = var.route53_zone_id
}
