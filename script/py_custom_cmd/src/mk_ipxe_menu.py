#!/usr/bin/env python3

"""Template"""

# --- Python library ----------------------------------------------------------
import os
import re
import sys
import time
from pathlib import Path

# from aiohttp import ClientError, ClientTimeout
# from bs4 import BeautifulSoup
# from dataclasses import dataclass
# from dataclasses import dataclass, asdict
# from dataclasses import asdict
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
# import textwrap
# import unicodedata
# import __main__
# --- my library --------------------------------------------------------------
# execusr = os.getenv("SUDO_USER", os.getenv("USER"))
# homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
# libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
# if str(libsdir) not in sys.path:
#    sys.path.append(str(libsdir))
from common.shared.my_common_cfg import (
    InfoConfiguration,
)
from common.shared.my_distribution_dat import (
    InfoDistribution,
    sort_distribution_data,
    sort_distribution_name,
)
from common.shared.my_media_dat import InfoMedia
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger
from common.utils.my_fileio import file_backup
from common.utils.my_message import (
    get_caller_name,
    message_alert,
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


def generate_ipxe_menu_file(
    src_path: Path,
    dst_path: Path,
    info_conf: InfoConfiguration,
    info_dist: InfoDistribution,
):
    target_distribution = re.sub(r"^[^_]+_([^.]+)\.ipxe", r"\1", src_path.name)
    if target_distribution == "windows":
        query_version = r"^(windows-|winpe-|ati[0-9]{4}|memtest86plus-).+$"
    else:
        query_version = rf"^{target_distribution}-.+$"
    queries = [{"version": query_version}, {"life": r"^(?!EOL).*$"}]
    find_results = info_dist.findregexp(queries)
    sort_results = sort_distribution_data(find_results, "", reverse=True)
    # def sort_distribution_data(data: DistributionData, distribution: str = "", reverse: bool = False) -> list[DistributionData]:
    # -------------------------------------------------------------------------
    pattern = r":_([A-Z0-9_]+)_:"
    match = re.compile(pattern)
    try:
        with open(src_path, "r", encoding="utf-8") as f:
            conv_dist = match.sub(
                lambda m: str(info_conf.find(key=m.group(1)).value), f.read()
            )
    except Exception as e:  # noqa: BLE001
        message_alert(get_caller_name(), f"Fatal error: {e}")
        raise SystemExit
    # -------------------------------------------------------------------------
    item_width = 47
    item_data = []
    for read_line in conv_dist.splitlines():
        if r"<items>" in read_line:  # --- items -------------------------------
            for data_dist in sort_results:
                goto_name = re.sub(
                    r" ", "_", f"{data_dist.name}-{data_dist.version_id}"
                )
                item_text = f"{f'item -- {goto_name}':<{item_width}} - {data_dist.name} ${{edition}} {data_dist.version_id}"
                if data_dist.code_name != "-":
                    item_text += rf" ({data_dist.code_name})"
                item_data.append(item_text)
        elif r"<goto selection>" in read_line:
            for data_dist in sort_results:
                goto_name = re.sub(
                    r" ", "_", f"{data_dist.name}-{data_dist.version_id}"
                )
                item_text = rf"{f'iseq ${{selected}} {goto_name}':<{item_width}} && goto {data_dist.name}-{data_dist.version_id}"
                item_data.append(item_text)
        elif r"<goto target>" in read_line:
            for data_dist in sort_results:
                goto_name = re.sub(
                    r" ", "_", f"{data_dist.name}-{data_dist.version_id}"
                )
                item_text = rf":{goto_name}"
                item_data.append(item_text)
        elif r"<code selection>" in read_line:
            for data_dist in sort_results:
                goto_name = re.sub(
                    r" ", "_", f"{data_dist.name}-{data_dist.version_id}"
                )
                item_text = rf"{f'iseq ${{selected}} {goto_name}':<{item_width}} && set vers {data_dist.version_id} ||"
                item_data.append(item_text)
        else:
            item_data.append(read_line)
    # -------------------------------------------------------------------------
    try:
        file_backup(dst_path)
        dst_path.parent.mkdir(parents=True, exist_ok=True)
        with open(dst_path, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(item_data) + "\n")
            f.flush()
            os.fsync(f.fileno())
    except OSError as e:
        message_alert(get_caller_name(), f"Fatal error: {e}")
        raise SystemExit
    except Exception as e:  # noqa: BLE001
        message_alert(get_caller_name(), f"Fatal error: {e}")
        raise SystemExit
    if not dst_path.exists:
        message_alert(get_caller_name(), f"failed: {dst_path}")


@debug_logger
def generate_ipxe_menu(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
) -> None:
    # -------------------------------------------------------------------------
    path_autexec = Path(str(info_conf.find(key="PATH_IPXE").value))
    path_ipxe_dir = path_autexec.parent
    path_tplt_ipxe_dir = Path(str(info_conf.find(key="DIRS_TMPL").value)) / "ipxe"
    list_tplt_files = sort_distribution_name(
        [file for file in path_tplt_ipxe_dir.glob(r"*.ipxe") if file.is_file()]
    )
    # -------------------------------------------------------------------------
    for src_path in list_tplt_files:
        if src_path.name == path_autexec.name:
            dst_path = path_ipxe_dir / src_path.name
        else:
            dst_path = path_ipxe_dir / "menu" / src_path.name
        message_info(get_caller_name(), str(dst_path))
        generate_ipxe_menu_file(src_path, dst_path, info_conf, info_dist)


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
