#! /usr/bin/env python3

import json
import sys
from argparse import ArgumentParser
from asyncio import AbstractEventLoop, create_subprocess_exec
from dataclasses import dataclass
from logging import Logger
from pathlib import Path
from typing import Dict, List

import build_packer
import build_terraform
from builder import run_build_command, FinishedProcessError
from common import get_logger, get_loop


_CWD = Path(".").resolve()


@dataclass
class Args:
    environment: str
    aws_profile: str

    ansible_playbook: Path
    packer_dir: Path
    terraform_dir: Path

    packer_flags: List[str]
    terraform_flags: List[str]

    availability_zones: str
    ec2_image_id: str
    ec2_instance_type: str
    ec2_ssh_key_pair: str

    no_init: bool
    no_packer: bool
    no_terraform: bool
    debug: bool
    dry_run: bool


def _parse_args() -> Args:
    parser = ArgumentParser()

    parser.add_argument(
        "environment",
        choices=["development", "production"],
        help="the build environment for deploying to",
    )
    parser.add_argument(
        "--aws-profile", required=True, help="name of the AWS credentials profile"
    )

    parser.add_argument(
        "--ansible-playbook",
        default="ansible/main.yml",
        help="path to the Ansible playbook for Packer builds",
    )
    parser.add_argument(
        "--packer-dir",
        required=True,
        help="path to the directory containing the Packer configs",
    )
    parser.add_argument(
        "--terraform-dir",
        required=True,
        help="path to the directory containing the Terraform configs",
    )

    parser.add_argument(
        "--packer-flags",
        default="",
        help="additional flags to pass when calling packer",
    )
    parser.add_argument(
        "--terraform-flags",
        default="",
        help="additional flags to pass when calling terraform",
    )

    parser.add_argument(
        "--availability-zones",
        default="us-west-2a",
        help="a comma-separated list of AWS AZs for creating VPC subnets",
    )
    parser.add_argument(
        "--ec2-image-id",
        default="",
        help="explicitly set the AMI for launched EC2 instances; implies --no-packer",
    )
    parser.add_argument(
        "--ec2-instance-type",
        default="t3.micro",
        help="instance type for launched EC2 instances",
    )
    parser.add_argument(
        "--ec2-ssh-key-pair",
        required=True,
        help="name of the SSH key pair for ubuntu@ access to EC2 instances",
    )

    parser.add_argument(
        "--no-init",
        default=False,
        action="store_true",
        help="skip running `terraform init` before Terraform steps",
    )
    parser.add_argument(
        "--no-packer",
        default=False,
        action="store_true",
        help="skip performing Packer steps",
    )
    parser.add_argument(
        "--no-terraform",
        default=False,
        action="store_true",
        help="skip performing Terraform steps",
    )

    parser.add_argument(
        "--debug",
        default=False,
        action="store_true",
        help="enable debug-level log output",
    )
    parser.add_argument(
        "--dry-run",
        default=False,
        action="store_true",
        help="display the terraform plan instead of deploying",
    )

    cwd = Path(".").resolve()
    opts = parser.parse_args()

    return Args(
        environment=f"{opts.environment}",
        aws_profile=f"{opts.aws_profile}",
        ansible_playbook=Path(opts.ansible_playbook),
        packer_dir=Path(opts.packer_dir),
        terraform_dir=Path(opts.terraform_dir),
        packer_flags=[f for f in opts.packer_flags.split(" ")],
        terraform_flags=[f for f in opts.terraform_flags.split(" ")],
        availability_zones=opts.availability_zones,
        ec2_image_id=f"{opts.ec2_image_id}",
        ec2_instance_type=f"{opts.ec2_instance_type}",
        ec2_ssh_key_pair=f"{opts.ec2_ssh_key_pair}",
        no_init=bool(opts.no_init),
        no_packer=bool(opts.no_packer),
        no_terraform=bool(opts.no_terraform),
        debug=bool(opts.debug),
        dry_run=bool(opts.dry_run),
    )


def _parse_packer_image_id(stdout: str) -> str:
    # e.g. 'us-west-2: ami-000000000000000000' => 'ami-000000000000000000'
    return stdout.split("\n")[-1].split(": ")[-1]


def _read_config_file(environment: str) -> Dict:
    with open(_CWD / "config" / f"{environment}.json") as f:
        return json.load(f)


async def _get_commit_hash(loop: AbstractEventLoop, log: Logger) -> str:
    commit_hash = ""
    try:
        proc = await run_build_command(
            "git",
            "rev-parse",
            "HEAD",
            cwd=_CWD,
            log=log,
            loop=loop,
        )
        commit_hash = proc.stdout.replace("\n", "")
    except Exception as e:
        log.warn(
            "unhandled exception, '%s', while trying to determine git commit hash; defaulting to empty-string",
            e,
        )

    return commit_hash


async def main(loop: AbstractEventLoop, log: Logger, args: Args) -> int:
    commit_hash = await _get_commit_hash(loop, log)
    config = _read_config_file(args.environment)

    if args.ec2_image_id != "":
        if not args.no_packer:
            log.warn(
                "'--ec2-image-id' flag passed, but not '--no-packer'; '--no-packer' implied"
            )

        args.no_packer = True

    image_id = args.ec2_image_id

    if not args.no_packer:
        packer_args = build_packer.Args(
            aws_profile=args.aws_profile,
            aws_region=config["aws_region"],
            build_version=config["build_version"],
            commit_hash=commit_hash,
            environment=args.environment,
            ansible_playbook=args.ansible_playbook,
            packer_dir=args.packer_dir,
            packer_flags=args.packer_flags,
            debug=args.debug,
        )

        log.info("starting Packer build step")
        try:
            packer_proc = await build_packer.run_build(loop, log, packer_args)
        except FinishedProcessError as e:
            log.exception("error while running Packer build step commands")
            return e.proc.return_code
        except Exception as e:
            log.exception("unhandled exception '%s' during Packer build step")
            return 1

        image_id = _parse_packer_image_id(packer_proc.stdout.rstrip())
        log.info("finished Packer build step, using AMI '%s'", image_id)

    if not args.no_terraform:
        terraform_args = build_terraform.Args(
            environment=args.environment,
            subcmd="apply",
            aws_profile=args.aws_profile,
            aws_region=config["aws_region"],
            build_version=config["build_version"],
            commit_hash=commit_hash,
            terraform_dir=args.terraform_dir,
            terraform_flags=args.terraform_flags,
            availability_zones=args.availability_zones,
            ec2_image_id=image_id,
            ec2_instance_type=args.ec2_instance_type,
            ec2_ssh_key_pair=args.ec2_ssh_key_pair,
            no_init=args.no_init,
            debug=args.debug,
            dry_run=args.dry_run,
        )

        try:
            terraform_proc = await build_terraform.run_build(loop, log, terraform_args)
        except FinishedProcessError as e:
            log.exception("error while running Terraform build step commands")
            return e.proc.return_code
        except Exception as e:
            log.exception("unhandled exception '%s' during Packer build step")
            return 1

        log.info("finished Terraform build step")

    return 0


if __name__ == "__main__":
    args = _parse_args()
    loop = get_loop()
    log = get_logger(debug=args.debug)

    rc = loop.run_until_complete(main(loop, log, args))
    sys.exit(rc)
