import os
import sys
from asyncio import AbstractEventLoop, create_subprocess_exec, get_event_loop
from asyncio.subprocess import Process
from dataclasses import dataclass
from io import StringIO
from logging import Logger, NullHandler, getLogger
from pathlib import Path
from subprocess import PIPE
from typing import Any, Dict, Iterable, Optional


@dataclass
class FinishedProcess:
    args: Iterable[str]
    command: str
    cwd: Optional[Path]

    return_code: int
    stderr: str
    stdout: str


class FinishedProcessError(Exception):
    msg: str
    proc: FinishedProcess

    def __init__(self, msg: str, proc: FinishedProcess) -> None:
        self.msg = msg
        self.proc = proc

    def __str__(self) -> str:
        return f"{self.msg}: '{self.proc.command}'"


def _ensure_log(log: Optional[Logger]) -> Logger:
    if log is None:
        log = getLogger("__null__")
        log.addHandler(NullHandler())

    return log


def _ensure_loop(loop: Optional[AbstractEventLoop]) -> AbstractEventLoop:
    return loop or get_event_loop()


async def run_build_command(
    *args: str,
    cwd: Path = None,
    env: Dict[str, str] = None,
    log: Logger = None,
    loop: AbstractEventLoop = None,
) -> FinishedProcess:
    log = _ensure_log(log)
    loop = _ensure_loop(loop)

    cmd = args[0]
    proc_args = args[1:]

    # copy the current process' env vars before adding our own
    old_env = {k: v for k, v in os.environ.items()}
    old_env.update(env or {})
    env = old_env

    log.debug("executing command '%s'", " ".join(args))
    subproc = await create_subprocess_exec(
        cmd,
        *proc_args,
        cwd=cwd,
        env=env,
        loop=_ensure_loop(loop),
        stderr=PIPE,
        stdout=PIPE,
    )
    stdout, stderr = await subproc.communicate()
    return_code = await subproc.wait()

    done = FinishedProcess(
        command=cmd,
        args=proc_args,
        cwd=cwd,
        return_code=return_code,
        stderr=stderr.decode("unicode_escape").rstrip() if stderr else "",
        stdout=stdout.decode("unicode_escape").rstrip() if stdout else "",
    )

    log.debug("stdout: %s", done.stdout)
    log.debug("stderr: %s", done.stderr)

    if done.return_code != 0:
        raise FinishedProcessError(
            "command '{}' has non-zero return code {}".format(
                " ".join(args),
                done.return_code,
            ),
            done,
        )

    return done
