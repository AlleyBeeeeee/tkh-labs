provider "aws" {  
  region = "us-east-1"
}

# The Target IAM Role
resource "aws_iam_role" "ec2_admin_role" {  
  name = "TKH-EC2-Admin-Role"  
  
  # REMEDIATED 1: Fixed Trust Policy
  assume_role_policy = jsonencode({    
    Version = "2012-10-17"    
    Statement = [      
      {        
        Action = "sts:AssumeRole"        
        Effect = "Allow"        
        Principal = {          
          # FIX: Changed "ec3" to the correct service principal "ec2"
          Service = "ec2.amazonaws.com"        
        }      
      }    
    ]  
  })
}

# REMEDIATED 2: Scoped-down, safe permissions
resource "aws_iam_role_policy" "admin_policy" {  
  name = "TKH-EC2-Scoped-Admin-Policy"  
  role = aws_iam_role.ec2_admin_role.id  
  
  policy = jsonencode({    
    Version = "2012-10-17"    
    Statement = [      
      {        
        # FIX: Scope permissions to EC2 operations only, instead of global "*"
        Action = [
          "ec2:Describe*",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]        
        Effect   = "Allow"        
        Resource = "*"  # Keeps resource flexible for all EC2 instances, or scope further to specific tags/ARNs
      }    
    ]  
  })
}

# 1. Keep Dave's User Resource exactly as it is
resource "aws_iam_user" "dave_user" {
  name = "Dave_The_Dev"
}

# 2. Give Dave his own Scoped Inline Policy Block directly
resource "aws_iam_user_policy" "dave_inline_policy" {
  name = "Dave-Restricted-Finance-Policy"
  user = aws_iam_user.dave_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::finance-bucket-name",   # <-- Just make sure this is your lab's real bucket name string!
          "arn:aws:s3:::finance-bucket-name/*" 
        ]
      }
    ]
  })
}