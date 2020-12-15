locals {
  public_subnet_cidr_blocks = {
    for index, availability_zone in var.availability_zone_names:
    availability_zone => cidrsubnet(data.aws_vpc.vpc.cidr_block, 8, index)
  }

  public_subnet_ipv6_cidr_blocks = {
    for index, availability_zone in var.availability_zone_names:
    availability_zone => cidrsubnet(data.aws_vpc.vpc.ipv6_cidr_block, 8, index)
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Environment = var.default_tags["Environment"]
    Region = var.default_tags["Region"]
  }
}

data "aws_internet_gateway" "gateway" {
  filter {
    name = "attachment.vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

resource "aws_subnet" "public" {
  for_each = toset(var.availability_zone_names)

  vpc_id = data.aws_vpc.vpc.id

  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch = true

  availability_zone = each.key
  cidr_block = local.public_subnet_cidr_blocks[each.key]
  ipv6_cidr_block = local.public_subnet_ipv6_cidr_blocks[each.key]

  tags = merge(
    var.default_tags,
    {
      Name = "${var.default_tags["Environment"]}.${each.key}.subnet.public.ghost"
    }
  )  
}

resource "aws_route_table" "ghost" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.gateway.id
  }

  tags = merge(
    var.default_tags,
    {
      Name = "${var.default_tags["Environment"]}.${var.default_tags["Region"]}.rtb.ghost"
    }
  )
}

resource "aws_route_table_association" "ghost" {
  for_each = aws_subnet.public

  subnet_id = each.value.id
  route_table_id = aws_route_table.ghost.id
}
