#!/usr/bin/env python3

"""Template"""

# --- Python library ----------------------------------------------------------
import os
import sys
import time
from dataclasses import asdict
from pathlib import Path

# from aiohttp import ClientError, ClientTimeout
# from bs4 import BeautifulSoup
# from dataclasses import dataclass
# from dataclasses import dataclass, asdict
# from datetime import datetime
# from datetime import datetime, timedelta
# from datetime import datetime, timezone
# from natsort import natsort_keygen
# from pathlib import Path
# from tqdm import tqdm
# from urllib.parse import urlparse
# import aiohttp # sudo apt-get install python3-aiohttp
# import asyncio
# import csv
# import dataclasses
# import json
# import magic # sudo apt-get install python3-magic
# import pandas as pd
# import re
# import shutil
# import subprocess
# import unicodedata
# import __main__
# --- my library --------------------------------------------------------------
execusr = os.getenv("SUDO_USER", os.getenv("USER"))
homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
if str(libsdir) not in sys.path:
    sys.path.append(str(libsdir))
from common.shared.my_common_cfg import InfoConfiguration
from common.shared.my_distribution_dat import InfoDistribution
from common.shared.my_media_dat import InfoMedia
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger
from common.utils.my_markdown import list2markdown
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    message_warn,
)

# from common.utils.my_string import count_width, eprint

# from common.utils.my_process              import run_subprocess
# from common.utils.my_fileio               import get_text2list, put_list2text, conv_text2json, conv_json2text
# from common.utils.my_json                 import load_json, save_json
# from common.utils.my_markdown             import list2markdown, spc_encode4md, spc_decode4md

# from common.utils.my_infoweb              import Infoweb, get_webinfo
# from common.utils.my_infofile             import Infofile, get_fileinfo
# from common.utils.my_infodata             import Infodata, debug_info, get_infodata


@debug_logger
def initialize() -> tuple[InfoConfiguration, InfoDistribution, InfoMedia]:
    """Initialize

    Returns:
        tuple[InfoConfiguration, InfoDistribution, InfoMedia]: info_conf, info_dist, info_mdia
    """
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


@debug_logger
def generate_markdown(
    dst_dir: str,
    info_conf: InfoConfiguration,
    info_dist: InfoDistribution,
    info_mdia: InfoMedia,
) -> None:
    """Generate markdown (Latest version of the distribution)

    Args:
        dst_dir (str): Destination path
        info_conf (InfoConfiguration): common.cfg interface class
        info_dist (InfoDistribution): distribution.dat interface class
        info_mdia (InfoMedia): media.dat interface class
    """
    # path_conf = info_conf.find(key="PATH_CONF").value
    path_dist = info_conf.find(key="PATH_DIST").value
    # path_mdia = info_conf.find(key="PATH_MDIA").value
    dst_path = Path(dst_dir) / "Readme_table_distribution.md"
    md_title = f"Distribution data({Path(path_dist).name})"
    distributions = [
        "debian",
        "ubuntu",
        "fedora",
        "centos",
        "almalinux",
        "rockylinux",
        "miraclelinux",
        "opensuse",
        "windows",
        "memtest86plus",
        "winpe",
        "ati2020",
    ]
    list_data = []
    for distribution in distributions:
        dict_list = [distribution]
        list_item = info_dist.sort(distribution, reverse=True)
        dict_list += [asdict(item) for item in list_item]
        list_data.append(dict_list)
    list2markdown(dst_path, md_title, list_data)


@debug_logger
def main():
    """Main"""
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        message_warn(
            get_caller_name(),
            "You have standard user privileges.",
        )
        message_warn(
            get_caller_name(),
            f"{Color.underline}Please run this with sudo.",
        )
        sys.exit(1)
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- startup process -----------------------------------------------------
    message_start(get_caller_name())
    # --- processing block ----------------------------------------------------
    arg_manager = Argument()
    #   arg_manager.add('--add', type=str, help='add args')
    arg_manager.add("--md", help="Generate markdown sheet", default="", type=str)
    args = arg_manager.parse()
    if args:
        info_conf, info_dist, info_mdia = initialize()
        if dst_dir := infosystem.args.md:
            generate_markdown(dst_dir, info_conf, info_dist, info_mdia)
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
    main()

# --- eof ---------------------------------------------------------------------
