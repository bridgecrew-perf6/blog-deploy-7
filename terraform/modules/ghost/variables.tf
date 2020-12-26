# Default global tag variables
variable "aws_region" {
  type        = string
  description = "the AWS AZ region for the image to be built in"
}

variable "build_version" {
  type        = string
  description = "the version of the image for the build environment"
}

variable "commit_hash" {
  type        = string
  description = "the commit hash of the image for the build environment"
  default     = ""
}

variable "environment" {
  type        = string
  description = "the build environment being built"
}

# VPC variables
variable "availability_zone_names" {
  type        = list(string)
  description = "the list of AZ names to create VPC subnets in"
}

# EC2 variables
variable "ec2_image_id" {
  type        = string
  description = "the AMI to use when launching an EC2 instance"
}

variable "ec2_instance_type" {
  type        = string
  description = "the instance type for the EC2 instance"
}

variable "ec2_ssh_key_pair" {
  type        = string
  description = "the name of the SSH key pair for EC2 remote access"
}

# Route53 variables
variable "domain_name" {
  type        = string
  description = "the domain name for the deployment"
}
