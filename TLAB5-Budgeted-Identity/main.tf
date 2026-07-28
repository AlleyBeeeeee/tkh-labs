provider "aws" {  
  region = "us-east-1"
}

# The Guardrail
resource "aws_budgets_budget" "tlab_budget" {  
  name              = "TLAB-Strict-Budget"  
  budget_type       = "COST"  
  limit_amount      = "10.0" #fixed  
  limit_unit        = "USD"  
  time_period_start = "2026-07-01_00:00" # Current year tracking
  time_unit         = "MONTHLY"  

  notification {    
    comparison_operator        = "GREATER_THAN"    
    notification_type          = "ACTUAL"    
    threshold                  = 80  # Fixed: Alert at 80% ($8) instead of 100% ($50)    
    threshold_type             = "PERCENTAGE"    
    subscriber_email_addresses = ["alleyb.cruz@gmail.com"]  
  }
}

# private S3 bucket - 1. generate 4 byte string
resource "random_id" "id" {
  byte_length = 4
}

#storage vault
resource "aws_s3_bucket" "vault" {
  bucket = "titan-fintech-vault-ab-${random_id.id.hex}"
  force_destroy = true # allows clean teardown during terraform destory
}

#block all public access 
resource "aws_s3_bucket_public_access_block" "vault_privacy" {
  bucket = aws_s3_bucket.vault.id
  
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# 1. The Trust Policy: Dictates WHO can wear this role (Only EC2)
resource "aws_iam_role" "vault_role" {
  name = "Titan-EC2-Vault-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. The Permissions Policy: Defines WHAT they can do (Surgical PutObject only)
resource "aws_iam_policy" "vault_put_only" {
  name        = "Titan-Vault-PutObject-Only"
  description = "Allows only uploading files to our specific secure vault"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        # Interpolates the exact bucket ARN and appends "/*" to target objects inside it
        Resource = ["${aws_s3_bucket.vault.arn}/*"] 
      }
    ]
  })
}

# 3. Attach the Permissions Policy to the Role
resource "aws_iam_role_policy_attachment" "vault_attach" {
  role       = aws_iam_role.vault_role.name
  policy_arn = aws_iam_policy.vault_put_only.arn
}

# 4. Create the Instance Profile (The bridge that lets EC2 run with this role)
resource "aws_iam_instance_profile" "vault_profile" {
  name = "Titan-EC2-Vault-Profile"
  role = aws_iam_role.vault_role.name
}
# Query AWS to find the latest official Ubuntu 22.04 LTS image
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical's official AWS Account ID (ensures security)
}

# The Virtual Machine
resource "aws_instance" "secure_node" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.micro" # Keeps it free-tier eligible
  iam_instance_profile = aws_iam_instance_profile.vault_profile.name # Assigns our secure role profile

  tags = {
    Name = "Titan-Secure-Compute-Node"
  }
}