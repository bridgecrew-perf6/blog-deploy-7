#! /usr/bin/env bash

set -Eeuo pipefail
set -o xtrace

aws_region="${AWS_REGION}"
commit_hash="${COMMIT_HASH:-}"
environment="${BUILD_ENVIRONMENT:-development}"

ansible_dir="${ANSIBLE_DIR:-}"
packer_dir="${PACKER_DIR:-}"
packer_flags="${PACKER_FLAGS:-}"

pushd "${packer_dir}"

/usr/bin/packer build \
    -var-file "${environment}.pkrvars.hcl" \
    -var "ansible_playbook=${ansible_dir}/main.yml" \
    -var "aws_region=${aws_region}" \
    -var "commit_hash=${commit_hash}" \
    -var "environment=${environment}" \
    ${packer_flags} \
    .

popd
