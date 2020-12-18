#! /usr/bin/env bash

set -Eeuo pipefail
set -o xtrace

function usage() {
  printf "usage: %s [flags] <environment>" "$0"
}

function help() {
  usage
  printf
  printf "%s is a build script for seamlessly creating Packer images and " "$0"
  printf "deploying them with Terraform"
  printf
  printf "options and arguments:"
  printf "\t-h|--help:\t print this help message and exit"
  printf "\t-p|--no-packer: skip building a Packer image"
  printf "\t-t|--no-terraform: skip deploying with Terraform"
  printf "\t-n|--noninteractive: auto approve Terraform changes"
  printf 
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
