#!/usr/bin/env python3

import asyncio
import os
import sys
import time
from pathlib import Path

import aiohttp  # sudo apt-get install python3-aiohttp
from aiohttp import ClientTimeout

execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))
from common.utils.my_infoweb import InfoWeb
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_start,
)
from common.utils.my_web_api import get_contents


async def main():
    caller = get_caller_name()
    start = time.perf_counter()
    message_start(caller)
    if True:
        request_url: str = "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso"
        local_file_path: str = "./debian/mini-trixie-amd64.iso"
    else:
        request_url: str = (
            "https://releases.ubuntu.com/24.04/ubuntu-24.04.5.1-desktop-amd64.iso"
        )
        local_file_path: str = "./ubuntu/ubuntu-24.04.5.1-desktop-amd64.iso"
    overwrite: bool = False
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    if True:
        async with aiohttp.ClientSession(
            timeout=timeout, raise_for_status=False
        ) as session:
            _web_data = await get_contents(
                session, request_url, local_file_path, overwrite
            )
        if not local_file_path:
            for _key, _value in _web_data.__dict__.items():
                print(f"{_key}:{_value}")
    else:
        infoweb = InfoWeb()
        async with aiohttp.ClientSession(
            timeout=timeout, raise_for_status=False
        ) as session:
            _web_data = await infoweb.get_header(session, request_url)
            for _key, _value in _web_data.__dict__.items():
                print(f"{_key}:{_value}")
            _web_data = await infoweb.get_text(session, request_url)
            for _key, _value in _web_data.__dict__.items():
                print(f"{_key}:{_value}")
    message_end(caller)
    end = time.perf_counter()
    elapsed = end - start
    message_elapsed(caller, elapsed)


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
