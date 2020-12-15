# AWS authentication control variables
variable "aws_profile" {
  type = string
  description = "the AWS credentials profile for authenticating"
}

# AWS tagging variables
variable "aws_region" {
  type = string
  description = "the AWS AZ region for the deployment"
}

variable "build_version" {
  type = string
  description = "the build version for tagging the deployment"
}

variable "commit_hash" {
  type = string
  description = "the commit hash for tagging the deployment"
}

variable "environment" {
  type = string
  description = "the build environment for the deployment"
}

# VPC variables
variable "availability_zone_names" {
  type = list(string)
  description = "the list of AZ names to create VPC subnets in"
}

# EC2 control variables
variable "ec2_image_id" {
  type = string
  description = "the AMI to use when launching an EC2 instance"
  default = ""
}

variable "ec2_instance_type" {
  type = string
  description = "the instance type for the EC2 instance"
}

variable "ec2_ssh_key_pair" {
  type = string
  description = "the name of the SSH key pair for EC2 remote access"
}
