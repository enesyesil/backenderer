locals {
  is_none = var.mode == "none"
  is_le   = var.mode == "letsencrypt"
  is_alb  = var.mode == "alb_acm"

  need_dns_records_to_ip = (local.is_none || local.is_le) && var.create_dns_records && var.instance_public_ip != null && var.hosted_zone_id != null
  need_alb               = local.is_alb
  need_acm               = local.is_alb
}

# Basic input validations that depend on multiple vars
# (Terraform will evaluate these at plan time.)
locals {
  _valid_alb_inputs = local.is_alb ? (var.vpc_id != null && length(var.domain_names) > 0 && var.hosted_zone_id != null) : true
}
# Fail fast if inputs are inconsistent
resource "null_resource" "validate_inputs" {
  triggers = {
    valid = local._valid_alb_inputs ? "ok" : "invalid"
  }
  lifecycle {
    precondition {
      condition     = local._valid_alb_inputs
      error_message = "For mode=alb_acm you must provide vpc_id, hosted_zone_id, and at least one domain_names entry."
    }
  }
}

##########
# Route53 A records to the instance IP (for mode none/letsencrypt)
##########
resource "aws_route53_record" "a_to_instance" {
  for_each = local.need_dns_records_to_ip ? toset(var.domain_names) : []

  zone_id = var.hosted_zone_id
  name    = each.value
  type    = "A"
  ttl     = 60
  records = [var.instance_public_ip]
}

##########
# ALB + ACM path (HTTPS with DNS validation + alias records)
##########
# Subnets for ALB: use provided or discover default VPC subnets
data "aws_subnets" "in_vpc" {
  count = local.need_alb && length(var.subnet_ids) == 0 ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [var.vpc_id != null ? var.vpc_id : "vpc-00000000000000000"]
  }
}

locals {
  alb_subnets = local.need_alb ? (length(var.subnet_ids) > 0 ? var.subnet_ids : try(data.aws_subnets.in_vpc[0].ids, [])) : []
}

# Security group for ALB
resource "aws_security_group" "alb" {
  count       = local.need_alb ? 1 : 0
  name        = "backenderer-alb-sg"
  description = "Allow 80/443 to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Application Load Balancer
resource "aws_lb" "this" {
  count              = local.need_alb ? 1 : 0
  name               = "backenderer-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = local.alb_subnets

  enable_deletion_protection = false

  tags = var.tags
}

# Target group -> EC2 instance on port 80
resource "aws_lb_target_group" "tg" {
  count    = local.need_alb ? 1 : 0
  name     = "backenderer-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = "/"
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-399"
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = local.need_alb && var.target_instance_id != null ? 1 : 0
  target_group_arn = aws_lb_target_group.tg[0].arn
  target_id        = var.target_instance_id
  port             = 80
}

# ACM certificate with DNS validation for all domains
resource "aws_acm_certificate" "cert" {
  count                     = local.need_acm ? 1 : 0
  domain_name               = var.domain_names[0]
  subject_alternative_names = length(var.domain_names) > 1 ? slice(var.domain_names, 1, length(var.domain_names)) : []
  validation_method         = "DNS"

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation records
resource "aws_route53_record" "cert_validation" {
  for_each = local.need_acm && var.hosted_zone_id != null ? {
    for dvo in aws_acm_certificate.cert[0].domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  } : {}

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

resource "aws_acm_certificate_validation" "cert" {
  count                   = local.need_acm ? 1 : 0
  certificate_arn        = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# HTTPS listener (443)
resource "aws_lb_listener" "https" {
  count             = local.need_alb ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.cert[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }
}

# HTTP listener (80) -> redirect to HTTPS
resource "aws_lb_listener" "http" {
  count             = local.need_alb ? 1 : 0
  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Alias A/AAAA records to ALB
resource "aws_route53_record" "alias_a" {
  for_each = local.need_alb && var.create_dns_records ? toset(var.domain_names) : []

  zone_id = var.hosted_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_lb.this[0].dns_name
    zone_id                = aws_lb.this[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alias_aaaa" {
  for_each = local.need_alb && var.create_dns_records ? toset(var.domain_names) : []

  zone_id = var.hosted_zone_id
  name    = each.value
  type    = "AAAA"

  alias {
    name                   = aws_lb.this[0].dns_name
    zone_id                = aws_lb.this[0].zone_id
    evaluate_target_health = true
  }
}
