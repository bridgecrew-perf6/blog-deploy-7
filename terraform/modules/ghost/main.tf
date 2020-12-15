locals {
  default_tags = {
    Region = var.aws_region
    BuildVersion = var.build_version
    CommitHash = var.commit_hash
    Environment = var.environment
  }
}

module "vpc" {
  source = "./modules/vpc"

  availability_zone_names = var.availability_zone_names

  default_tags = local.default_tags
}

module "security" {
  source = "./modules/security"

  vpc_id = module.vpc.vpc_id

  default_tags = local.default_tags
}

module "ec2" {
  source = "./modules/ec2"

  security_group_ids = module.security.security_group_ids
  subnet_id = module.vpc.subnet_ids[0]
  vpc_id = module.vpc.vpc_id

  image_id = var.ec2_image_id
  instance_type = var.ec2_instance_type
  ssh_key_pair = var.ec2_ssh_key_pair

  default_tags = local.default_tags
}
