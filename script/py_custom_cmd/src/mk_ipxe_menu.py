#!/usr/bin/env python3

"""Template"""

# --- Python library ----------------------------------------------------------
import os
import re
import sys
import time
from operator import attrgetter
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
# execusr = os.getenv("SUDO_USER", os.getenv("USER"))
# homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
# libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
# if str(libsdir) not in sys.path:
#    sys.path.append(str(libsdir))
from common.shared.my_common_cfg import InfoConfiguration
from common.shared.my_distribution_dat import DistributionData, InfoDistribution
from common.shared.my_media_dat import InfoMedia
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger
from common.utils.my_fileio import file_backup
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    message_warn,
)
from packaging.version import InvalidVersion
from packaging.version import parse as parse_version

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
def put_menufile(
    src_path: str, dst_path: str, info_conf: InfoConfiguration, pattern: re.Pattern
) -> None:
    """Convert the source file and save it to the destination file.

    Args:
        src_path (str): Source path
        dst_path (str): Destination path
        info_conf (InfoConfiguration): common.cfg interface class
        pattern (re.Pattern): re.Pattern
    """
    with open(src_path, "r", encoding="utf-8") as f:
        content = f.read()
        conv = pattern.sub(lambda m: info_conf.find(key=m.group(1)).value, content)
        file_backup(dst_path)
        with open(dst_path, "w", encoding="utf-8") as f:
            f.write(conv)


def sort_distribution_data(
    data: DistributionData, distribution: str = "", reverse: bool = False
) -> list[DistributionData]:
    match = re.compile(rf"^{re.escape(distribution)}-.+$")
    selected_data = [item for item in data if match.match(item.version)]

    def make_universal_sort_key(item):
        v_str = item.version
        if distribution and v_str.startswith(f"{distribution}-"):
            v_str = v_str[len(distribution) + 1 :]
        base_match = re.match(
            r"^([a-zA-Z0-9_-]+?)-(?=\d|testing|sid|tumbleweed|x86|x64)", v_str
        )
        if base_match:
            base_name = base_match.group(1)
            version_part = v_str[len(base_name) + 1 :]
        else:
            base_name = ""
            version_part = v_str
        version_part = re.sub(
            r"(\d+)h(\d+)", r"\1.\2", version_part, flags=re.IGNORECASE
        )
        num_match = re.search(r"(\d+(?:\.\d+)*\S*)", version_part)
        if num_match:
            try:
                return (base_name, 2, parse_version(num_match.group(1)))
            except InvalidVersion:
                pass
        if version_part:
            return (base_name, 3, version_part)
        return (base_name, 0, parse_version("0.0.0"))

    def sort_key(item):
        v_str = item.version
        if distribution and v_str.startswith(f"{distribution}-"):
            v_str = v_str[len(distribution) + 1 :]
        v_str = re.sub(r"[^0-9-.]+", "9", v_str).replace(r"-", r".")
        return parse_version(v_str)

    step1 = sorted(selected_data, key=make_universal_sort_key, reverse=reverse)
    sorted_datas = sorted(step1, key=attrgetter("sort_flag"), reverse=reverse)
    return sorted_datas


@debug_logger
def generate_ipxe_menu(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
) -> None:
    """Generate ipxe menu

    Args:
        info_conf (InfoConfiguration): common.cfg interface class
        info_dist (InfoDistribution): distribution.dat interface class
        info_mdia (InfoMedia): media.dat interface class
    """
    path_template = Path(str(info_conf.find(key="DIRS_TMPL").value))
    path_template_ipxe = path_template / "ipxe"
    path_autexec = Path(str(info_conf.find(key="PATH_IPXE").value))
    dir_ipxe = path_autexec.parent
    template_files = [
        file for file in path_template_ipxe.glob("*.ipxe") if file.is_file()
    ]

    pattern_value = r":_([A-Z0-9_]+)_:"
    match_value = re.compile(pattern_value)
    pattern_file = r"^[^_]+_([^.]+)\.ipxe"
    match_file = re.compile(pattern_file)

    for file in template_files:
        match file.name:
            case path_autexec.name:
                dst_path = Path(dir_ipxe) / f"{file.name}.temp"
                put_menufile(file, dst_path, info_conf, match_value)
            case "menu.ipxe":
                pass
            case _ if match_file.match(file.name):
                distribution = match_file.sub(r"\1", file.name)
                print(f"type(distribution):{type(distribution)}")
                print(f"distribution:{distribution}")
                print()
                list_item = sort_distribution_data(
                    info_dist.data, str(distribution), reverse=True
                )
                for line in list_item:
                    print(line)
                print()
                list_item = sort_distribution_data(
                    list_item, str(distribution), reverse=False
                )
                for line in list_item:
                    print(line)
            #                for line in info_dist.get_descending(str(distribution)):
            #                    print(line)
            case _:
                dst_path = Path(dir_ipxe) / "menu" / f"{file.name}.temp"
                put_menufile(file, dst_path, info_conf, match_value)


# autoexec.ipxe
# booting.ipxe
# menu.ipxe
# menu_almalinux.ipxe
# menu_centos.ipxe
# menu_custom_live.ipxe
# menu_debian.ipxe
# menu_fedora.ipxe
# menu_live.ipxe
# menu_miraclelinux.ipxe
# menu_opensuse.ipxe
# menu_rockylinux.ipxe
# menu_ubuntu.ipxe
# menu_windows.ipxe


# autoexec.ipxe
# menu/booting.ipxe
# menu/menu.ipxe
# menu/menu_almalinux.ipxe
# menu/menu_centos.ipxe
# menu/menu_custom_live.ipxe
# menu/menu_debian.ipxe
# menu/menu_fedora.ipxe
# menu/menu_live.ipxe
# menu/menu_miraclelinux.ipxe
# menu/menu_opensuse.ipxe
# menu/menu_rockylinux.ipxe
# menu/menu_ubuntu.ipxe
# menu/menu_windows.ipxe


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
    args = arg_manager.parse()
    if args:
        info_conf, info_dist, info_mdia = initialize()
        generate_ipxe_menu(info_conf, info_dist, info_mdia)
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
