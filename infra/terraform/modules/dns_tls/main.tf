locals {
  is_none = var.mode == "none"
  is_alb  = var.mode == "alb_acm"

  need_dns_records_to_ip = local.is_none && var.create_dns_records && trimspace(var.instance_public_ip) != "" && trimspace(var.hosted_zone_id) != ""
  need_alb               = local.is_alb
  need_acm               = local.is_alb
  alb_name               = substr("${var.name_prefix}-alb", 0, 32)
  alb_security_group     = "${var.name_prefix}-alb-sg"
  target_group_name      = substr("${var.name_prefix}-tg", 0, 32)
}

locals {
  valid_alb_inputs = !local.is_alb || (
    trimspace(var.vpc_id) != "" &&
    length(var.domain_names) > 0 &&
    trimspace(var.hosted_zone_id) != "" &&
    length(var.subnet_ids) >= 2
  )
}

check "alb_inputs" {
  assert {
    condition     = local.valid_alb_inputs
    error_message = "For mode=alb_acm you must provide vpc_id, hosted_zone_id, at least one domain_names entry, and two ALB subnets."
  }
}

resource "aws_route53_record" "a_to_instance" {
  for_each = local.need_dns_records_to_ip ? toset(var.domain_names) : []

  zone_id = var.hosted_zone_id
  name    = each.value
  type    = "A"
  ttl     = 60
  records = [var.instance_public_ip]
}

resource "aws_security_group" "alb" {
  count       = local.need_alb ? 1 : 0
  name        = local.alb_security_group
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

resource "aws_lb" "this" {
  count              = local.need_alb ? 1 : 0
  name               = local.alb_name
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_target_group" "tg" {
  count    = local.need_alb ? 1 : 0
  name     = local.target_group_name
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    path                = var.health_path
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-399"
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = local.need_alb && trimspace(coalesce(var.target_instance_id, "")) != "" ? 1 : 0
  target_group_arn = aws_lb_target_group.tg[0].arn
  target_id        = var.target_instance_id
  port             = 80
}

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

resource "aws_route53_record" "cert_validation" {
  for_each = local.need_acm && trimspace(var.hosted_zone_id) != "" ? {
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
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

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
