output "mode" {
  value = var.mode
}

output "a_record_fqdns" {
  description = "FQDNs created as A records to instance (none/letsencrypt)."
  value       = [for r in aws_route53_record.a_to_instance : r.fqdn]
}

output "alb_dns_name" {
  description = "ALB DNS name (mode=alb_acm)."
  value       = try(aws_lb.this[0].dns_name, null)
}

output "alb_zone_id" {
  description = "ALB hosted zone id (mode=alb_acm)."
  value       = try(aws_lb.this[0].zone_id, null)
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN (mode=alb_acm)."
  value       = try(aws_acm_certificate_validation.cert[0].certificate_arn, null)
}
