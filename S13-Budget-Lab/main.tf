resource "aws_instance" "my_first_server" {
  ami           = "ami-04b70fa74e45c3917"
  instance_type = "t3.micro"

  tags = {
    Name = "TKH-Phase2-Instance"
  }
}