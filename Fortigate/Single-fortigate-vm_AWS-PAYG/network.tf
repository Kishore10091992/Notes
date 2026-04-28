resource "aws_vpc" "fgtvm-vpc" {
  cidr_block           = var.vpccidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.az
  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_subnet" "privatesubnet" {
  vpc_id            = aws_vpc.fgtvm-vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.az
  tags = {
    Name = var.private_subnet_name
  }
}

# S3 endpoint inside the VPC
# use s3 bucket for bootstrap
resource "aws_vpc_endpoint" "s3-endpoint-fgtvm-vpc" {
  count           = var.bucket ? 1 : 0
  vpc_id          = aws_vpc.fgtvm-vpc.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.fgtvmpublicrt.id]
  policy          = <<POLICY
{
    "Statement": [
        {
            "Action": "*",
            "Effect": "Allow",
            "Resource": "*",
            "Principal": "*"
        }
    ]
}
POLICY
  tags = {
    Name = var.fgtvm-vpc_endpoint-to-s3
  }
}

resource "aws_internet_gateway" "fgtvmigw" {
  vpc_id = aws_vpc.fgtvm-vpc.id
  tags = {
    Name = var.igw
  }
}

resource "aws_route_table" "fgtvmpublicrt" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = var.fgtvm-public-rt
  }
}

resource "aws_route_table" "fgtvmprivatert" {
  vpc_id = aws_vpc.fgtvm-vpc.id

  tags = {
    Name = var.fgtvm-private-rt
  }
}

resource "aws_route" "externalroute" {
  route_table_id         = aws_route_table.fgtvmpublicrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fgtvmigw.id
}

resource "aws_route" "internalroute" {
  depends_on             = [aws_instance.fgtvm]
  route_table_id         = aws_route_table.fgtvmprivatert.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.eth1.id

}

resource "aws_route_table_association" "public1associate" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.fgtvmpublicrt.id
}

resource "aws_route_table_association" "internalassociate" {
  subnet_id      = aws_subnet.privatesubnet.id
  route_table_id = aws_route_table.fgtvmprivatert.id
}

resource "aws_eip" "FGTPublicIP" {
  depends_on        = [aws_instance.fgtvm]
  domain            = "vpc"
  network_interface = aws_network_interface.public-eth0.id
}

resource "aws_network_interface" "public-eth0" {
  description = "fgtvm-port1"
  subnet_id   = aws_subnet.publicsubnet.id
}

resource "aws_network_interface" "private-eth1" {
  description       = "fgtvm-port2"
  subnet_id         = aws_subnet.privatesubnet.id
  source_dest_check = false
}

resource "aws_network_interface_sg_attachment" "publicattachment" {
  depends_on           = [aws_network_interface.public-eth0]
  security_group_id    = aws_security_group.public-sg.id
  network_interface_id = aws_network_interface.public-eth0.id
}

resource "aws_network_interface_sg_attachment" "internalattachment" {
  depends_on           = [aws_network_interface.private-eth1]
  security_group_id    = aws_security_group.private-sg.id
  network_interface_id = aws_network_interface.private-eth1.id
}