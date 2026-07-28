provider "aws" {
  region = "us-east-1"
}

# 1. Base S3 Bucket (Removed acl = "public-read")
resource "aws_s3_bucket" "vulnerable_vault" {
  bucket        = "tkh-exposed-vault-${random_id.id.hex}"
  force_destroy = true
}

# 2. Block All Public Access (Fixes aws-s3-no-public-access-block)
resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.vulnerable_vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Enable Server-Side Encryption (Fixes aws-s3-encryption-customer-key)
resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.vulnerable_vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 4. Enable Bucket Versioning (Fixes aws-s3-enable-versioning)
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.vulnerable_vault.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Random ID Generator
resource "random_id" "id" {
  byte_length = 4
}