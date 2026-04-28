data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "config"
    content_type = "text/x-shellscript"
    content = templatefile("${var.bootstrap-fgtvm}", {
      adminsport = var.adminsport
    })
  }
}

resource "tls_private_key" "fgtvm_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "fgtvm_keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.fgtvm_key.public_key_openssh
}

resource "aws_s3_object" "pem_file" {
  bucket       = aws_s3_bucket.s3_bucket.key_name
  key          = "pem file name.pem"
  content      = tls_private_key.fgtvm_key.private_key_pem
  acl          = "private"
}

resource "aws_instance" "fgtvm" {
  ami               = var.fgtami[var.region][var.arch][var.license_type]
  instance_type     = var.size
  availability_zone = var.az
  key_name          = aws_key_pair.fgtvm_keypair.key_name

  user_data = data.cloudinit_config.config.rendered

  root_block_device {
    volume_type = "gp2"
    volume_size = 2
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_size = 30
    volume_type = "gp2"
  }

  primary_network_interface {
    network_interface_id = aws_network_interface.public-eth0.id
  }

  tags = {
    Name = var.fgvm_name
  }
}

resource "aws_network_interface_attachment" "eth1-attach" {
  instance_id          = aws_instance.fgtvm.id
  network_interface_id = aws_network_interface.private-eth1.id
  device_index         = 1
}
