output "vpc_id" {
  description = "Managed VPC ID."
  value       = aws_vpc.main.id
}

output "alb_subnet_ids" {
  description = "Public subnet IDs used by the ALB."
  value       = aws_subnet.public[*].id
}

output "app_subnet_id" {
  description = "Subnet ID where the EC2 host is launched."
  value       = var.private_app_host ? aws_subnet.private[0].id : aws_subnet.public[0].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for the app host."
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs in the managed VPC."
  value       = aws_subnet.public[*].id
}
