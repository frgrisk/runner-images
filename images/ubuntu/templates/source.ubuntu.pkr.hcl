local "aws_ami_name_x86_64" {
  expression = "GitHub Actions Runner Ubuntu 24.04 ${formatdate("YYYY-MM-DD hh.mm ZZZ", timestamp())} x86_64"
}

local "ami_users" {
  expression = [
    "702719119055",
    "630261574551",
    "042008443740",
  ]
}

packer {
  required_plugins {
    amazon = {
      version = "= 1.3.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "build_image" {
  ami_name = local.aws_ami_name_x86_64

  ami_users = local.ami_users

  subnet_filter {
    filters = {
      "tag:Environment" : "github-actions-runners*"
      "tag:Name" : "*-public-*"
    }
    random = true
  }

  associate_public_ip_address = true

  ssh_interface = "public_ip"

  spot_instance_types = [
    "c7i-flex.xlarge",
  ]

  spot_price = "auto"

  region = var.region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ubuntu"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_type           = "gp3"
    volume_size           = 120
    delete_on_termination = true
  }
}

local "aws_ami_name_arm64" {
  expression = "GitHub Actions Runner Ubuntu 24.04 ${formatdate("YYYY-MM-DD hh.mm ZZZ", timestamp())} arm64"
}

source "amazon-ebs" "build_image_arm64" {
  ami_name = local.aws_ami_name_arm64

  ami_users = local.ami_users

  subnet_filter {
    filters = {
      "tag:Environment" : "github-actions-runners*"
      "tag:Name" : "*-public-*"
    }
    random = true
  }

  associate_public_ip_address = true

  ssh_interface = "public_ip"

  spot_instance_types = [
    "c7g.xlarge",
    "c6g.xlarge",
  ]

  spot_price = "auto"

  region = var.region

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-arm64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ubuntu"

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_type           = "gp3"
    volume_size           = 120
    delete_on_termination = true
  }
}
