provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


# ###############################
# AWS Networking: VPC Resources
# ###############################

locals {
  azs = data.aws_availability_zones.available_zones.names
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

resource "random_id" "random" {
  byte_length = 2
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.namespace}-vpc-${random_id.random.dec}"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.namespace}-igw-${random_id.random.dec}"
  }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.namespace}-public-route-table-${random_id.random.dec}"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}


resource "aws_default_route_table" "private_route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "${var.namespace}-private-route-table-${random_id.random.dec}"
  }
}


resource "aws_subnet" "public_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "${var.namespace}-public-subnet-${random_id.random.dec}-${count.index + 1}"
  }
}


resource "aws_subnet" "private_subnet" {
  count                   = length(local.azs)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, length(local.azs) + count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index]

  tags = {
    Name = "${var.namespace}-private-subnet-${random_id.random.dec}-${count.index + 1}"
  }
}


resource "aws_route_table_association" "public_route_association" {
  count          = length(local.azs)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_security_group" "public_security_group" {
  name        = "public-security-group"
  description = "Security Group for public instances"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Name" = "${var.namespace}-public-security-group-${random_id.random.dec}"
  }
}


resource "aws_security_group_rule" "ingress_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [var.access_ip]
  security_group_id = aws_security_group.public_security_group.id
}


resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.public_security_group.id
}


# ###############################
# AWS Compute: EC2 Resources
# ###############################

data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
}

resource "random_id" "node_id" {
  byte_length = 2
  count       = var.instance_count
}


resource "aws_key_pair" "ec2_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}


resource "aws_instance" "main_instance" {
  count                  = var.instance_count
  instance_type          = var.instance_type
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.ec2_auth.id
  vpc_security_group_ids = [aws_security_group.public_security_group.id]
  subnet_id              = aws_subnet.public_subnet[count.index].id
  root_block_device {
    volume_size = var.main_vol_size
  }

  tags = {
    "Name" = "${var.namespace}-main-instance-${random_id.node_id[count.index].dec}"
  }
}
