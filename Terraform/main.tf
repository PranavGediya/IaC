provider "aws" {
  region = "eu-north-1"
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform-key"
  public_key = file("") 
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP and SSH"
  vpc_id      = ""

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Web-server2" {
  ami               = "ami-0f50f13aefb6c0a5d"
  instance_type     = "t3.micro"
  subnet_id         = "--"
  key_name          = aws_key_pair.terraform_key.key_name
  
  vpc_security_group_ids = [
    aws_security_group.allow_http.id
  ]

  associate_public_ip_address = true

  # Load userdata normally
  user_data = file("${path.module}/userdata.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "TerraformEC2V7"
  }
}
