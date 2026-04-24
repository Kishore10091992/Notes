resource "aws_security_group" "windows_ec2_sg" {
  name = ""
  vpc_id = var.vpc_id

  ingress {
   from_port = 3389
   to_port = 3389
   protocol = "Tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
   from_port = 443
   to_port = 443
   protocol = "Tcp"
   cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
   from_port = 3306
   to_port = 3306
   protocol = "Tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
   from_port = 443
   to_port = 443
   protocol = "Tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "windows_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "windows_keypair" {
  key_name   = ""
  public_key = tls_private_key.windows_key.public_key_openssh
}

resource "aws_s3_object" "pem_file" {
  bucket       = <provide already created bucket>
  key          = "<pem file name>.pem"
  content      = tls_private_key.windows_key.private_key_pem
  acl          = "private"
}

resource "aws_instance" "windows_ec2" {
  ami           = "ami-04b1756cd8ff18ec6"
  instance_type = "t3.medium"
  key_name      = aws_key_pair.windows_keypair.key_name
  vpc_security_group_ids = [aws_security_group.windows_ec2_sg.id]
  subnet_id              = var.ec2_frontend_subnet
  associate_public_ip_address = false

  tags = {
   Name = ""
  }
}