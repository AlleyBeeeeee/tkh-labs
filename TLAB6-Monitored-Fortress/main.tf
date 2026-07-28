provider "aws" {
  region = "us-east-1"
}

# ====================================================================
# TITAN FINTECH: THE MONITORED FORTRESS
# Build your VPC, Subnets, Flow Logs, Security Group, and EC2 instance below.
# 
# Hint: When your EC2 instance needs an IAM profile, use:
# iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
# 
# Hint: When your Flow Log needs an IAM role, use:
# iam_role_arn = aws_iam_role.flow_log_role.arn
# ====================================================================

# the PERIMETER 

# Main VPC
resource "aws_vpc" "titan_prod_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "Titan-Prod-VPC"
  }
}

# IGW 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.titan_prod_vpc.id

  tags = {
    Name = "Titan-IGW"
  }
}

#Public Subnet (10.0.1.0/24)
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.titan_prod_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone =  "us-east-1a"

  tags = {
    Name = "Titan-Public-Subnet"
  }
}

#Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.titan_prod_vpc.id

route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
  }

tags = {
  Name = "Titan-Public-RouteTable"
  }
}

# Route Table Association
resource "aws_route_table_association" "public_assoc" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# VPC Flow Logs 
#Cloudwatch Log Group (/tkh/titan-prod-vpc-logs)
resource"aws_cloudwatch_log_group" "flow_log_group" {
  name = "/tkh/titan-prod-vpc-logs"
  retention_in_days = 1
  
  tags = {
    Name = "titan-prod-vpc-logs"
  }
}

#VPC Flow Log resource
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.flow_log_group.arn
  traffic_type ="ALL"
  vpc_id = aws_vpc.titan_prod_vpc.id
}


# Security and EC2
# ZERO-inbound Security Group (outbound only)
resource "aws_security_group" "zero_trust_sg" {
  name = "titan-zero-trust-sg"
  description = "Allows ZERO inbound traffic. Outbound Only."
  vpc_id = aws_vpc.titan_prod_vpc.id


  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

tags = {
    Name = "Titan-Zero-Trust-SG"
  }
}

#Fetch lastest LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
# Zero Trust instance
resource "aws_instance" "zero_trust_node" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet.id
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
 
  vpc_security_group_ids = [
    aws_security_group.zero_trust_sg.id
  ]

  tags = {
    Name = "Titan-Zero-Trust-Server"
  }
}
