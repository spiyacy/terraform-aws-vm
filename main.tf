terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.buildTags
  }
}

data "terraform_remote_state" "foundation" {
  backend = "remote"

  config = {
    organization = var.org
    workspaces = {
      name = var.foundation_workspace
    }
  }
}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Canonical
  owners = [var.ami_owner]
}

locals {
  # ami_id precedence:
  # 1. var.ami_id
  # 2. aws_ami
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.ami.id
}

resource "aws_instance" "instance" {
  count                       = var.instance_count
  subnet_id                   = element(data.terraform_remote_state.foundation.outputs.public_subnets, count.index)
  ami                         = local.ami_id
  instance_type               = var.instance_type
  vpc_security_group_ids      = [data.terraform_remote_state.foundation.outputs.ingress_security_group_id, data.terraform_remote_state.foundation.outputs.egress_security_group_id]
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  root_block_device {
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
  }
  get_password_data = true

  #user_data                   = data.template_file.user_data.rendered
  tags = {
    Name = "${var.prefix}-build"
  }
}

output "instance_password" {
  value = ["${resource.aws_instance.instance[*].password_data}"]
}