resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic" # Added description

  ingress {
    description = "SSH from personal host IP" # Added description
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["68.237.55.102/32"]
  }

  egress {
    description = "Allow all outbound traffic" # Added description
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}