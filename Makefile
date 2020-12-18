pwd := $(shell pwd)

AWS_REGION ?= us-west-2
BUILD_ENVIRONMENT ?= development
BUILD_VERSION ?= 0.0.0
COMMIT_HASH ?= 

ANSIBLE_DIR ?= ${pwd}/ansible
PACKER_DIR ?= ${pwd}/packer
TERRAFORM_DIR ?= ${pwd}/terraform

PACKER_FLAGS ?= 
TERRAFORM_FLAGS ?= 

terraform:
	./bin/build-terraform.sh

clean-terraform:
	./bin/destroy-terraform.sh

packer:
	./bin/build-packer.sh

clean: clean-terraform

deploy:
	pushd ${TERRAFORM_DIR}
	terraform apply -auto-approve 

.EXPORT_ALL_VARIABLES:

.PHONY: .EXPORT_ALL_VARIABLES terraform packer deploy
