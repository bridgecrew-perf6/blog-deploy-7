resource "aws_security_group" "ghost" {
  name = "${var.default_tags["Environment"]}.${var.default_tags["Region"]}.sg.ghost"
  
  ingress {
    from_port  = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  vpc_id = var.vpc_id
}
