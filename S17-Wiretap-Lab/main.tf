provider "aws" {
  region = "us-east-1"
}

# 1. The Target Network (Pre-built to save time)
resource "aws_vpc" "target_vpc" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "TKH-Target-VPC"
  }
}

# NEW: INTERNET ACCESS & SUBNET 
# Front Door to the Internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.target_vpc.id

  tags = {
    Name = "TKH-IGW"
  }
}

# Public Subnet (availability_zone set to us-east-1a to prevent instance errors)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.target_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "TKH-Public-Subnet"
  }
}

# Route Table connecting Subnet -> Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.target_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "TKH-Public-RouteTable"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#  NEW: FIREWALL & EC2 HONEYPOT

# Security Group with ZERO Inbound Rules (All inbound traffic gets REJECTed)
resource "aws_security_group" "locked_sg" {
  name        = "tkh-locked-sg"
  description = "Block all inbound traffic to force REJECT records"
  vpc_id      = aws_vpc.target_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TKH-Locked-SG"
  }
}

# Fetch latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Target EC2 Instance
resource "aws_instance" "target_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.locked_sg.id]

  tags = {
    Name = "TKH-Target-Server"
  }
}
# 4. IAM ROLES FOR FLOW LOGS
#  The IAM Role for Flow Logs (Provided to reduce IAM friction)
resource "aws_iam_role" "flow_log_role" {
  name = "TKH-Flow-Log-Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name = "TKH-Flow-Log-Policy"
  role = aws_iam_role.flow_log_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# --- STUDENTS WILL ADD THEIR FLOW LOG AND CLOUDWATCH RESOURCES BELOW ---

#  FLOW LOG & CLOUDWATCH
# CloudWatch Log Group (/tkh/vpc-flow-logs)
resource "aws_cloudwatch_log_group" "flow_log_group" {
  name              = "/tkh/vpc-flow-logs"
  retention_in_days = 1

  tags = {
    Name = "tkh-vpc-flow-logs"
  }
}

# VPC Flow Log Resource
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.target_vpc.id
}