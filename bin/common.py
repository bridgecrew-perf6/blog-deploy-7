from asyncio import AbstractEventLoop, get_event_loop
from logging import DEBUG, Formatter, INFO, Logger, StreamHandler, getLogger
from typing import IO, Iterator, List, Optional


def get_logger(debug: bool = False) -> Logger:
    formatter = Formatter(
        fmt="[{asctime}][{levelname}] (pid:{process}) {filename}:{lineno} | "
        + "{funcName}:\t{message}",
        datefmt="%y/%m/%d %H:%M:%S %z",
        style="{",
    )

    handler = StreamHandler()
    handler.setFormatter(formatter)

    log = getLogger(__name__)
    log.addHandler(handler)
    log.setLevel(DEBUG if debug else INFO)

    return log


def get_loop() -> AbstractEventLoop:
    return get_event_loop()
