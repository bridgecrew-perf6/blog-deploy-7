output "eip_address" {
  value = aws_eip.ghost.public_dns
}
