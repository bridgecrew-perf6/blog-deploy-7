variable "ansible_playbook" {
    type = string
    description = "the Ansible playbook for the provisioner to use"
}

# AWS configuration variables
variable "aws_profile" {
    type = string
    description = "the AWS credentials profile to use"
}

variable "aws_region" {
    type = string
    description = "the AWS AZ region for the image to be built in"
}

variable "base_image_id" {
    type = string
    description = "the AMI ID to use for the base image"
}

# Ghost environment configuration variables
variable "build_version" {
    type = string
    description = "the version of the image being built"
}

variable "commit_hash" {
    type = string
    description = "the git commit hash of the repo when the image was built"
}

variable "environment" {
    type = string
    description = "the build environment for the image"
} 
