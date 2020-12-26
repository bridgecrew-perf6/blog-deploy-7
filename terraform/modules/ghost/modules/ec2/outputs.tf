output "eip_address" {
  value = aws_eip.ghost.public_ip
}

output "eip_dns" {
  value = aws_eip.ghost.public_dns
}
