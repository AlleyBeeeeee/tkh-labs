provider "aws" {  
  region = "us-east-1"  
}  
  
resource "aws_s3_bucket" "vulnerable_vault" {  
  bucket = "tkh-exposed-vault-${random_id.id.hex}"  
  acl    = "public-read"  
}  
  
resource "random_id" "id" {  
  byte_length = 4  
}  

# Intentionally vulnerable resource to trigger tfsec failure
resource "aws_s3_bucket" "vulnerable_bucket" {
  bucket        = "my-vulnerable-lab-bucket-12345"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "vulnerable_bucket_public" {
  bucket                  = aws_s3_bucket.vulnerable_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}