#! /usr/bin/env python3

import shlex
import sys
from argparse import ArgumentParser
from asyncio import AbstractEventLoop, create_subprocess_exec
from dataclasses import dataclass
from logging import Logger
from pathlib import Path
from typing import List

from builder import FinishedProcess, run_build_command
from common import get_logger, get_loop


@dataclass
class Args:
    aws_profile: str
    aws_region: str
    build_version: str
    commit_hash: str
    environment: str

    ansible_playbook: Path
    packer_dir: Path
    packer_flags: List[str]

    debug: bool


def _parse_args() -> Args:
    parser = ArgumentParser()

    parser.add_argument("environment")
    parser.add_argument("--aws-profile", required=True)
    parser.add_argument("--aws-region", default="us-west-2")
    parser.add_argument("--build-version", default="0.0.0")
    parser.add_argument("--commit-hash", default="")
    parser.add_argument("--ansible-playbook", default="ansible/main.yml")

    parser.add_argument("--packer-dir", required=True)
    parser.add_argument("--packer-flags", default="")

    parser.add_argument("--debug", default=False, action="store_true")

    opts = parser.parse_args()
    return Args(
        aws_profile=str(opts.aws_profile),
        aws_region=str(opts.aws_region),
        build_version=str(opts.build_version),
        commit_hash=str(opts.commit_hash),
        environment=str(opts.environment),
        ansible_playbook=Path(opts.ansible_playbook),
        packer_dir=Path(opts.packer_dir),
        packer_flags=[f for f in opts.packer_flags.split(" ")],
        debug=opts.debug,
    )


async def run_build(
    loop: AbstractEventLoop, log: Logger, args: Args
) -> FinishedProcess:
    env = {
        "PACKER_NO_COLOR": "true",
    }

    build_args = [
        "packer",
        "build",
        f"-var-file={args.environment}.pkrvars.hcl",
        f"-var=ansible_playbook={args.ansible_playbook.resolve()}",
        f"-var=aws_profile={args.aws_profile}",
        f"-var=aws_region={args.aws_region}",
        f"-var=build_version={args.build_version}",
        f"-var=commit_hash={args.commit_hash}",
        ".",
    ]

    if len(args.packer_flags) > 0 and args.packer_flags[0] != "":
        # insert flags for Packer before -var arguments
        build_args.insert(2, " ".join(args.packer_flags))

    return await run_build_command(
        *build_args,
        env=env,
        cwd=args.packer_dir,
        log=log,
        loop=loop,
    )


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
