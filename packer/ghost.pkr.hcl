source "amazon-ebs" "ghost" {
    profile = var.aws_profile
    region = var.aws_region
    source_ami = var.base_image_id

    ami_name = "packer-ghost-${var.environment}-${var.build_version}-{{ timestamp }}"
    ami_virtualization_type = "hvm"
    instance_type = "t3.micro"
    ssh_username = "ubuntu"

    tags = {
        Service = "ghost"
     
        BuildVersion = var.build_version
        CommitHash = var.commit_hash
        Environment = var.environment
    }

    subnet_filter {
        filters = {
            "tag:Class": "build"
        }
        most_free = true
        random = false
    }
}

build {
    sources = [
        "source.amazon-ebs.ghost"
    ]

    provisioner "ansible" {
        playbook_file = var.ansible_playbook

        ansible_env_vars = [
            "GHOST_AWS_REGION=${var.aws_region}",
            "GHOST_BASE_DIR=${var.base_dir}",
            "GHOST_BUILD_VERSION=${var.build_version}",
            "GHOST_COMMIT_HASH=${var.commit_hash}",
            "GHOST_ENVIRONMENT=${var.environment}"
        ]
    }
}
