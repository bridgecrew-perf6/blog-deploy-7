output "ec2_instance" {
  value = {
    dns = module.ec2.eip_dns
    ip  = module.ec2.eip_address
  }
}
