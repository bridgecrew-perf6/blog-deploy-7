terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

module "ghost" {
  source = "./modules/ghost"

  aws_region    = var.aws_region
  build_version = var.build_version
  commit_hash   = var.commit_hash
  environment   = var.environment

  availability_zone_names = var.availability_zone_names

  ec2_image_id      = var.ec2_image_id
  ec2_instance_type = var.ec2_instance_type
  ec2_ssh_key_pair  = var.ec2_ssh_key_pair
}
