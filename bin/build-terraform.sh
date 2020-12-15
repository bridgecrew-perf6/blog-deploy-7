#! /usr/bin/env bash

set -Eeuo pipefail
set -o xtrace

aws_region=${AWS_REGION:-us-west-2}
build_version=${BUILD_VERSION:-}
commit_hash=${COMMIT_HASH:-}
environment=${BUILD_ENVIRONMENT:-development}
packer_image_id=${PACKER_AMI_ID}

packer_flags=${PACKER_FLAGS:-}
terraform_dir=${TERRAFORM_DIR:-}
terraform_flags=${TERRAFORM_FLAGS:-}


pushd ${terraform_dir}

terraform init

terraform apply \
  -var "aws_profile=pangu" \
  -var "aws_region=${aws_region}" \
  -var "build_version=${build_version}" \
  -var "commit_hash=${commit_hash}" \
  -var "environment=${environment}" \
  -var "availability_zone_names=[\"us-west-2a\"]" \
  -var "ec2_image_id=${packer_image_id}" \
  -var "ec2_instance_type=t3.micro" \
  -var "ec2_ssh_key_pair=pangu" \
  ${terraform_flags}

popd
