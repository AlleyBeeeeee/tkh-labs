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
