output "public_ip" {
  description = "Public IPv4 address for the EC2 host, if assigned."
  value       = aws_instance.web.public_ip
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.web.id
}

output "security_group_id" {
  description = "Security group ID attached to the EC2 host."
  value       = aws_security_group.vm_sg.id
}
