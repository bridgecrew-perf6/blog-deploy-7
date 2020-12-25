data "aws_caller_identity" "current" {

}

data "aws_ami" "ghost" {
  count = var.image_id == "" ? 1 : 0

  most_recent = true

  owners = [data.aws_caller_identity.current.id]

  filter {
    name   = "tag:Service"
    values = ["ghost"]
  }

  filter {
    name   = "tag:BuildVersion"
    values = [var.default_tags["BuildVersion"]]
  }

  filter {
    name   = "tag:CommitHash"
    values = [var.default_tags["CommitHash"]]
  }

  filter {
    name   = "tag:Environment"
    values = [var.default_tags["Environment"]]
  }
}

resource "aws_network_interface" "ghost" {
  security_groups = flatten(var.security_group_ids)
  subnet_id       = var.subnet_id

  tags = merge(
    var.default_tags,
    {
      Name = "${var.default_tags["Environment"]}.${var.default_tags["Region"]}.ni.ghost"
    }
  )
}

resource "aws_eip" "ghost" {
  network_interface = aws_network_interface.ghost.id

  public_ipv4_pool = "amazon"
  vpc              = true

  tags = merge(
    var.default_tags,
    {
      Name = "${var.default_tags["Environment"]}.${var.default_tags["Region"]}.eip.ghost"
    }
  )
}

resource "aws_instance" "ghost" {
  ami           = var.image_id == "" ? data.aws_ami.ghost.0.id : var.image_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_pair

  monitoring = true

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ghost.id
  }

  tags = merge(
    var.default_tags,
    {
      Name = "${var.default_tags["Environment"]}.${var.default_tags["Region"]}.ec2.ghost"
    }
  )
}
