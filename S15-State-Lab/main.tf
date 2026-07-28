# The Target IAM Role
resource "aws_iam_role" "ec2_admin_role" {
  name = "TKH-EC2-Admin-Role"

  # FIX 1: Corrected "ec3" typo to "ec2"
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

# Restrictive Policy
resource "aws_iam_role_policy" "admin_policy" {
  name = "TKH-Safely-Scoped-Policy"
  role = aws_iam_role.ec2_admin_role.id

  # FIX 2: Restricting administrative wildcard "*" to specific Describe actions
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}