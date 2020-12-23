pwd := $(shell pwd)

AWS_REGION ?= us-west-2
BUILD_ENVIRONMENT ?= development
BUILD_VERSION ?= 0.0.0
COMMIT_HASH ?= 
PACKER_IMAGE_ID ?=

ANSIBLE_DIR ?= ${pwd}/ansible
PACKER_DIR ?= ${pwd}/packer
TERRAFORM_DIR ?= ${pwd}/terraform

PACKER_FLAGS ?= 
TERRAFORM_FLAGS ?= 

terraform:
	./bin/build_terraform.py \
		"${BUILD_ENVIRONMENT}" \
		"apply" \
		--aws-profile=pangu \
		--aws-region="${AWS_REGION}" \
		--build-version="${BUILD_VERSION}" \
		--commit-hash="${COMMIT_HASH}" \
		--terraform-dir="${TERRAFORM_DIR}" \
		--terraform-flags="${TERRAFORM_FLAGS}" \
		--ec2-image-id="${PACKER_IMAGE_ID}" \
		--ec2-ssh-key-pair=pangu

clean-terraform:
	./bin/build_terraform.py \
		"${BUILD_ENVIRONMENT}" \
		"destroy" \
		--aws-profile=pangu \
		--aws-region="${AWS_REGION}" \
		--build-version="${BUILD_VERSION}" \
		--commit-hash="${COMMIT_HASH}" \
		--terraform-dir="${TERRAFORM_DIR}" \
		--terraform-flags="${TERRAFORM_FLAGS}" \
		--ec2-image-id="${PACKER_IMAGE_ID}" \
		--ec2-ssh-key-pair=pangu

packer:
	./bin/build_packer.py \
		"${BUILD_ENVIRONMENT}" \
		--ansible-playbook="${ANSIBLE_DIR}/main.yml" \
		--aws-profile=pangu \
		--aws-region="${AWS_REGION}" \
		--build-version="${BUILD_VERSION}" \
		--commit-hash="${COMMIT_HASH}" \
		--packer-dir="${PACKER_DIR}" \
		--packer-flags="${PACKER_FLAGS}"

clean: clean-terraform

deploy:
	./deploy.py \
		"${BUILD_ENVIRONMENT}" \
		--aws-profile=pangu \
		--packer-dir="${PACKER_DIR}" \
		--packer-flags="${PACKER_FLAGS}" \
		--terraform-dir="${TERRAFORM_DIR}" \
		--terraform-flags="${TERRAFORM_FLAGS}" \
		--ec2-ssh-key-pair=pangu

.EXPORT_ALL_VARIABLES:

.PHONY: .EXPORT_ALL_VARIABLES terraform packer deploy
