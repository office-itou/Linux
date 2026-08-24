#!/usr/bin/env python3
# encoding: utf-8

import os
#topdir = os.getcwd()

topdir = "/home/master/linux/script/py_custom_cmd/src"
import sys
sys.path.append(topdir)

import argparse
from pathlib import Path
import re
import inspect

import aiohttp                          # sudo apt-get install python3-aiohttp
from aiohttp import ClientError, ClientTimeout
import asyncio

import json
import time

from py_common          import config
from py_common.colors   import color
from py_common.debug    import debugout

from py_common.common_cfg       import Common_cfg
from py_common.distribution_dat import Distribution_dat
from py_common.media_dat        import Media_dat

from py_common.infoweb  import Infoweb, get_webinfo
from py_common.infofile import Infofile, get_fileinfo
from py_common.infodata import Infodata, debug_info, get_infodata

async def main():
    start = time.perf_counter()
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")

    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug', help='Debug mode', action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    args = parser.parse_args()
    config.debug = args.debug
    config.debugout = args.debugout
    if config.debug == True:
        config.debugout = True

    debugout(config.debugout, color.yellow, func_name, "info", "Debug mode on")

    if os.geteuid() != 0:
        print(f"{color.br_yellow}You have standard user privileges. Please run this with sudo.{color.reset}")
        exit(1)

    path = "/home/master/linux/script/py_custom_cmd/src/py_prototype/list.json"
    with open(path, "r", encoding="utf-8") as f:
        list = json.load(f)
    infodata = Infodata
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(timeout=timeout, raise_for_status=False) as session:
        infodatas = await get_infodata(session, list)
        for infodata in infodatas:
            debug_info(infodata)

    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    end = time.perf_counter()
    elapsed = end - start
    print(f"elapsed time: {elapsed:.4f} 秒")

if __name__ == "__main__":
    asyncio.run(main())
