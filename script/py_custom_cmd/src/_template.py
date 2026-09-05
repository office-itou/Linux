#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import os
import sys
import time

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
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger

# from common.utils.my_string               import eprint, count_width
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    message_warn,
)

# from common.utils.my_process              import run_subprocess
# from common.utils.my_fileio               import get_text2list, put_list2text, conv_text2json, conv_json2text
# from common.utils.my_json                 import load_json, save_json
# from common.utils.my_markdown             import list2markdown, spc_encode4md, spc_decode4md

# from common.shared.my_common_cfg          import InfoConfiguration
# from common.shared.my_distribution_dat    import InfoDistribution
# from common.shared.my_media_dat           import InfoMedia

# from common.utils.my_infoweb              import Infoweb, get_webinfo
# from common.utils.my_infofile             import Infofile, get_fileinfo
# from common.utils.my_infodata             import Infodata, debug_info, get_infodata


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
    message_info(get_caller_name(), f"exec user:{infosystem.data.exec_user}")
    message_info(get_caller_name(), f"home dir :{infosystem.data.home_dir}")
    # -------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def main():
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
        initialize()
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
