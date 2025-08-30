output "instance_profile_name" {
  description = "Name of the EC2 IAM instance profile"
  value       = aws_iam_instance_profile.ec2.name
}

output "role_name" {
  description = "Name of the EC2 role"
  value       = aws_iam_role.ec2.name
}
