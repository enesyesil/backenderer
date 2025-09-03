terraform {
  required_version = ">= 1.11.0"


  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = ">= 5.0"
    }
  }

}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "state" {
  bucket        = "${var.project}-tf-state"
  force_destroy = false

  tags = merge(var.tags, {
    project = var.project
    purpose = "terraform-state"
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

data "aws_iam_policy_document" "s3_tls_enforce" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals { 
    type = "*"
    identifiers = ["*"] 
    
    }

    resources = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id
  policy = data.aws_iam_policy_document.s3_tls_enforce.json
}