terraform {
  backend "s3" {
    bucket         = "your-tf-state-bucket"
    key            = "backenderer/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
