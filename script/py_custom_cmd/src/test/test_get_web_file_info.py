#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import asyncio

# import unicodedata
# import __main__
# import glob
# import csv
# import dataclasses
import os

# import magic # sudo apt-get install python3-magic
# import pandas as pd
# import re
# import shutil
# import subprocess
import sys
import time

# from bs4 import BeautifulSoup
# from dataclasses import dataclass
# from dataclasses import asdict
# from datetime import datetime
# from datetime import datetime, timedelta
# from datetime import datetime, timezone
# from natsort import natsort_keygen
from pathlib import Path

# from zoneinfo import ZoneInfo
# from tqdm import tqdm
# from urllib.parse import urlparse
import aiohttp  # sudo apt-get install python3-aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))

from common.shared.my_common_cfg import InfoConfiguration
from common.shared.my_distribution_dat import InfoDistribution

# from common.utils.my_markdown             import list2markdown, spc_encode4md, spc_decode4md
from common.shared.my_media_dat import InfoMedia
from common.shared.my_shared import Text_fmat
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger

# from common.utils.my_process              import run_subprocess
from common.utils.my_infofile import InfoFile
from common.utils.my_infoweb import InfoWeb

# from common.utils.my_string               import eprint, count_width
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
)

# from common.utils.my_infodata              import InfoData


# -----------------------------------------------------------------------------
# descript: initialize
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def initialize():
    if infosystem.debug == True:
        message_info(get_caller_name(), "Debug mode on")
    if infosystem.debugout == True:
        message_info(get_caller_name(), "Debugout mode on")
    # -------------------------------------------------------------------------
    info_conf = InfoConfiguration()
    path_dist = info_conf.find(key="PATH_DIST")
    path_mdia = info_conf.find(key="PATH_MDIA")
    info_dist = InfoDistribution(path_dist.value + ".json")
    info_mdia = InfoMedia(path_mdia.value + ".json", info_conf)
    # -------------------------------------------------------------------------
    return info_conf, info_dist, info_mdia


# -----------------------------------------------------------------------------
@debug_logger
def generate_md(
    dirs: str,
    info_conf: InfoConfiguration,
    info_dist: InfoDistribution,
    info_mdia: InfoMedia,
):
    path_conf = info_conf.find(key="PATH_CONF")
    path_dist = info_conf.find(key="PATH_DIST")
    path_mdia = info_conf.find(key="PATH_MDIA")
    info_conf.markdown(
        Path(dirs) / "Readme_Configuration.md",
        f"Configuration data({Path(path_conf.value).name})",
    )
    info_dist.markdown(
        Path(dirs) / "Readme_Distribution.md",
        f"Distribution data({Path(path_dist.value).name})",
    )
    info_mdia.markdown(
        Path(dirs) / "Readme_Media.md",
        f"Media data({Path(path_mdia.value).name})",
    )


# -----------------------------------------------------------------------------
@debug_logger
def data_save(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
):
    path_dist = info_conf.find(key="PATH_DIST")
    path_mdia = info_conf.find(key="PATH_MDIA")
    # -------------------------------------------------------------------------
    info_dist.save(f"{path_dist.value}.json")
    info_mdia.save(f"{path_mdia.value}.json", info_conf)
    # -------------------------------------------------------------------------
    info_dist.put_list2text(path_dist.value, Text_fmat.dist)
    info_mdia.put_list2text(
        path_mdia.value,
        Text_fmat.mdia,
        info_conf,
    )


# -----------------------------------------------------------------------------
@debug_logger
async def get_web_file_info(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
):
    info_web = InfoWeb()
    info_file = InfoFile()
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(
        timeout=timeout, raise_for_status=False
    ) as session:
        for tget_mdia in info_mdia.data:
            if (
                tget_mdia.entry_flag != "o"
                or tget_mdia.web_regexp == "-"
                or tget_mdia.iso_path == "-"
            ):
                continue
            message_info(get_caller_name(), tget_mdia.web_regexp, True)
            await info_web.get_info(session, tget_mdia.web_regexp, tget_mdia.iso_path)
            tget_mdia.web_path = info_web.data.url
            tget_mdia.web_tstamp = info_web.data.tmstamp
            tget_mdia.web_size = info_web.data.size
            tget_mdia.web_check = info_web.data.check
            tget_mdia.web_status = info_web.data.status
            if info_web.data.status != 200:
                continue
            if Path(info_web.data.output).exists():
                info_file.get_info(info_web.data.output)
                tget_mdia.iso_path = info_file.data.path
                tget_mdia.iso_tstamp = info_file.data.tmstamp
                tget_mdia.iso_size = info_file.data.size
                tget_mdia.iso_volume = info_file.data.volume
            else:
                tget_mdia.iso_path = info_web.data.output
                tget_mdia.iso_tstamp = "-"
                tget_mdia.iso_size = "-"
                tget_mdia.iso_volume = "-"
    return info_mdia.data


# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
async def main():
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        print(
            f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n{Color.br_yellow} You have standard user privileges. {Color.underline}Please run this with sudo.{Color.reset}"
        )
        sys.exit(1)
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- startup process -----------------------------------------------------
    message_start(get_caller_name())
    # --- processing block ----------------------------------------------------
    arg_manager = Argument()
    arg_manager.add(
        "--t2j", help="Text -> json convert", default=False, action="store_true"
    )
    arg_manager.add(
        "--j2t", help="json -> Text convert", default=False, action="store_true"
    )
    arg_manager.add("--md", help="json -> Markdown generate", default="", type=str)
    arg_manager.add(
        "--info", help="Get ISO file information for web", default="", type=str
    )
    arg_manager.add("--save", help="Save data", default=False, action="store_true")
    args = arg_manager.parse()
    if args:
        info_conf, info_dist, info_mdia = initialize()
        if infosystem.args.t2j == True:
            path_dist = info_conf.find(key="PATH_DIST")
            path_mdia = info_conf.find(key="PATH_MDIA")
            info_dist.get_text2list(path_dist)
            info_mdia.get_text2list(path_mdia, info_conf)
        if infosystem.args.j2t == True:
            path_dist = info_conf.find(key="PATH_DIST")
            path_mdia = info_conf.find(key="PATH_MDIA")
            info_dist.get_text2list(f"{path_dist}.json")
            info_mdia.get_text2list(f"{path_mdia}.json", info_conf)
            info_dist.put_list2text(path_dist)
            info_mdia.put_list2text(path_mdia, info_conf)
        if target := infosystem.args.info:
            if target == "a":
                pass
            await get_web_file_info(info_conf, info_dist, info_mdia)
            generate_md("./", info_conf, info_dist, info_mdia)
            data_save(info_conf, info_dist, info_mdia)
        if dirs := infosystem.args.md:
            generate_md(dirs, info_conf, info_dist, info_mdia)
        if infosystem.args.save == True:
            data_save(info_conf, info_dist, info_mdia)
    # --- termination process -------------------------------------------------
    message_end(get_caller_name())
    # --- elapsed end ---------------------------------------------------------
    end = time.perf_counter()
    elapsed = end - start
    message_elapsed(get_caller_name(), elapsed)
    # --- exit ----------------------------------------------------------------
    sys.exit(0)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    asyncio.run(main())

# --- eof ---------------------------------------------------------------------
