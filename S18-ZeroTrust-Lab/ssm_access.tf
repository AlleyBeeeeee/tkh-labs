provider "aws" {
  region = "us-east-1"
}

# 1. The Zero-Inbound Security Group
resource "aws_security_group" "zero_trust_sg" {
  name        = "TKH-Zero-Trust-SG"
  description = "Allows ZERO inbound traffic. Outbound only."

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. The Identity Hat (IAM Role)
resource "aws_iam_role" "ssm_role" {
  name = "TKH-SSM-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# SABOTAGE: The IAM Role exists, but it has NO permissions attached!
# The SSM Agent on the EC2 instance will fail to phone home to AWS.

# THE FIX : attach AmazonSSMManagedInstanceCore policy to ssm_role
resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "TKH-SSM-Profile"
  role = aws_iam_role.ssm_role.name
}

# 3. The Target Server
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "zero_trust_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids      = [aws_security_group.zero_trust_sg.id]
  associate_public_ip_address = true # Guarantees the SSM Agent can dial out to the internet
  
  # Notice: NO SSH KEY PAIR IS ASSIGNED!
  tags = {
    Name = "TKH-Zero-Trust-Node"
  }
}