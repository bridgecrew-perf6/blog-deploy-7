#! /usr/bin/env bash

set -Eeuo pipefail
set -o xtrace

function usage() {
  echo "usage: $0 [flags] <environment>"
}

function help() {
  usage
  echo
  echo "$0 is a build script for seamlessly creating Packer images and "
  echo "deploying them with Terraform"
  echo
  echo "options and arguments:"
  echo "\t-h|--help:\t print this help message and exit"
  echo "\t-p|--no-packer: skip building a Packer image"
  echo "\t-t|--no-terraform: skip deploying with Terraform"
  echo "\t-n|--noninteractive: auto approve Terraform changes"
  echo 
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

environment=
skip_packer=false
skip_terraform=false
terraform_flags=

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      help
      exit 2
      shift
      ;;
    -p|--no-packer)
      skip_packer=true
      shift
      ;;
    -t|--no-terraform)
      skip_terraform=true
      shift
      ;;
    --noninteractive)
      terraform_flags="${terraform_flags} -auto-approve"
      shift
      ;;
    *)
      environment=$1
      shift
      ;;
  esac
done

if [[ -z "${environment}" ]]; then
  usage
  exit 1
fi

commit_hash=$(git rev-parse HEAD)
config_file="config/${environment}.json"
aws_region=$(
  jq ".aws_region" "${config_file}" |
  sed -e 's/^"//' -e 's/"$//')
build_version=$(
  jq ".build_version" "${config_file}" |
  sed -e 's/^"//' -e 's/"$//')

export AWS_REGION="${aws_region}"
export BUILD_ENVIRONMENT="${environment}"
export BUILD_VERSION="${build_version}"
export COMMIT_HASH="${commit_hash}"
export TERRAFORM_FLAGS="${TERRAFORM_FLAGS:-} ${terraform_flags}"

if [[ "${skip_packer}" != "true" ]]; then
  make packer
fi

if [[ "${skip_terraform}" != "true" ]]; then
  make terraform
fi
