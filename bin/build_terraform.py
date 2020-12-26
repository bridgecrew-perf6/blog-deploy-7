#! /usr/bin/env python3

import shlex
import sys
from argparse import ArgumentParser
from asyncio import AbstractEventLoop, create_subprocess_exec
from dataclasses import dataclass
from logging import Logger
from pathlib import Path
from typing import List

from builder import run_build_command, FinishedProcess
from common import get_logger, get_loop


@dataclass
class Args:
    environment: str
    subcmd: str

    aws_profile: str
    aws_region: str
    build_version: str
    commit_hash: str

    terraform_dir: Path
    terraform_flags: List[str]

    availability_zones: str
    ec2_image_id: str
    ec2_instance_type: str
    ec2_ssh_key_pair: str

    domain_name: str

    no_init: bool
    debug: bool
    dry_run: bool


def _parse_args() -> Args:
    parser = ArgumentParser()

    parser.add_argument("environment")
    parser.add_argument("subcmd")
    parser.add_argument("--aws-profile", required=True)
    parser.add_argument("--aws-region", default="us-west-2")
    parser.add_argument("--build-version", default="0.0.0")
    parser.add_argument("--commit-hash", default="")

    parser.add_argument("--terraform-dir", required=True)
    parser.add_argument("--terraform-flags", default="")

    parser.add_argument("--availability-zones", default="us-west-2a")
    parser.add_argument("--ec2-image-id", default="")
    parser.add_argument("--ec2-instance-type", default="t3.micro")
    parser.add_argument("--ec2-ssh-key-pair", required=True)

    parser.add_argument("--domain-name", required=True)

    parser.add_argument("--no-init", default=False, action="store_true")
    parser.add_argument("--debug", default=False, action="store_true")
    parser.add_argument("--dry-run", default=False, action="store_true")

    opts = parser.parse_args()
    return Args(
        environment=f"{opts.environment}",
        subcmd=f"{opts.subcmd}",
        aws_profile=f"{opts.aws_profile}",
        aws_region=f"{opts.aws_region}",
        build_version=f"{opts.build_version}",
        commit_hash=f"{opts.commit_hash}",
        terraform_dir=Path(opts.terraform_dir),
        terraform_flags=[f for f in opts.terraform_flags.split(" ")],
        availability_zones=f"{opts.availability_zones}",
        ec2_image_id=f"{opts.ec2_image_id}",
        ec2_instance_type=f"{opts.ec2_instance_type}",
        ec2_ssh_key_pair=f"{opts.ec2_ssh_key_pair}",
        domain_name=f"{opts.domain_name}",
        no_init=bool(opts.no_init),
        debug=bool(opts.debug),
        dry_run=bool(opts.dry_run),
    )


async def run_build(
    loop: AbstractEventLoop, log: Logger, args: Args
) -> FinishedProcess:
    cwd = args.terraform_dir
    availability_zones = '["{}"]'.format(
        '", "'.join(args.availability_zones.split(","))
    )

    additional_flags = ["-no-color"]
    if args.dry_run:
        args.subcmd = "plan"
    else:
        additional_flags.append("-auto-approve")

    build_args = [
        "terraform",
        args.subcmd,
        *additional_flags,
        f"-var=aws_profile={args.aws_profile}",
        f"-var=aws_region={args.aws_region}",
        f"-var=build_version={args.build_version}",
        f"-var=commit_hash={args.commit_hash}",
        f"-var=environment={args.environment}",
        f"-var=availability_zone_names={availability_zones}",
        f"-var=ec2_image_id={args.ec2_image_id}",
        f"-var=ec2_instance_type={args.ec2_instance_type}",
        f"-var=ec2_ssh_key_pair={args.ec2_ssh_key_pair}",
        f"-var=domain_name={args.domain_name}",
    ]

    if len(args.terraform_flags) > 0 and args.terraform_flags[0] != "":
        # insert flags for Terraform before -var arguments
        build_args.insert(2, " ".join(args.terraform_flags))

    if not args.no_init:
        log.info("starting `terraform init` build step")
        _ = await run_build_command(
            "terraform",
            "init",
            "-no-color",
            cwd=cwd,
            log=log,
            loop=loop,
        )

    log.info("starting `terraform %s` build step", args.subcmd)
    proc = await run_build_command(
        *build_args,
        cwd=cwd,
        log=log,
        loop=loop,
    )
    log.info("finished `terraform %s` build step", args.subcmd)

    tf_output = await run_build_command(
        "terraform",
        "output",
        "-json",
        cwd=cwd,
        log=log,
        loop=loop,
    )
    log.info("terraform output:\n%s", tf_output.stdout)

    return tf_output


async def main(loop: AbstractEventLoop, log: Logger, args: Args) -> int:
    try:
        proc = await run_build(loop, log, args)
        return proc.return_code
    except Exception as e:
        log.exception("unhandled exception in main: '%s'", e)
        return 1


if __name__ == "__main__":
    args = _parse_args()
    loop = get_loop()
    log = get_logger(debug=args.debug)

    rc = loop.run_until_complete(main(loop, log, args))
    sys.exit(rc)
