#! /usr/bin/env bash

set -Eeuo pipefail
set -o xtrace

ansible_dir=${ANSIBLE_DIR:-}
aws_region=${AWS_REGION:-us-west-2}
commit_hash=${COMMIT_HASH:-}
environment=${BUILD_ENVIRONMENT:-development}

ansible_dir=${ANSIBLE_DIR:-}
packer_dir=${PACKER_DIR:-}

pushd "${packer_dir}"

PACKER_AMI_ID=$( \
    /usr/bin/packer build \
        -var-file "${environment}.pkrvars.hcl" \
        -var "ansible_playbook=${ansible_dir}/main.yml" \
        -var "aws_region=${aws_region}" \
        -var "commit_hash=${commit_hash}" \
        -var "environment=${environment}" \
        . \
    | grep "${aws_region}" \
    | tail -n1 \
    | awk '{print $2}')

export PACKER_AMI_ID=${PACKER_AMI_ID}

popd
