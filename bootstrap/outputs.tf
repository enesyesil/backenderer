output "state_bucket" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.state.bucket
}



output "region" {
  description = "Region where the backend is hosted"
  value       = var.region
}
