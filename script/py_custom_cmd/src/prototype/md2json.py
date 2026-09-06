#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import os
import inspect
import time
import argparse

#from aiohttp import ClientError, ClientTimeout
#from bs4 import BeautifulSoup
#from dataclasses import dataclass
#from dataclasses import dataclass, asdict
#from datetime import datetime
#from datetime import datetime, timedelta
#from datetime import datetime, timezone
#from natsort import natsort_keygen
#from pathlib import Path
#from tqdm import tqdm
#from urllib.parse import urlparse
#import aiohttp # sudo apt-get install python3-aiohttp
#import asyncio
#import csv
#import dataclasses
import json
#import magic # sudo apt-get install python3-magic
#import pandas as pd
import re
#import shutil
#import subprocess
#import sys
#import unicodedata
#import __main__
from typing import Any

# --- my library --------------------------------------------------------------
from pathlib        import Path
import os
import sys
execusr = os.getenv('USER')
execusr = os.getenv('SUDO_USER', execusr)
homedir = os.getenv('HOME')
homedir = os.getenv('SUDO_HOME', homedir)
libsdir = '/linux/script/py_custom_cmd/src/'
libsdir = Path(homedir) / libsdir.strip('/')
sys.path.append(str(libsdir))

from py_common.my_config                import infosystem
from py_common.my_colors                import color
#from py_common.my_string               import eprint, count_width
from py_common.my_message               import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert
from py_common.my_debug                 import debugout
#from py_common.my_process              import run_subprocess
from py_common.my_fileio                import get_text2list, put_list2text, conv_text2json, conv_json2text
from py_common.my_json                  import load_json, save_json
from py_common.my_markdown              import list2markdown, spc_encode4md, spc_decode4md

from py_common.my_common_cfg            import InfoConfiguration
from py_common.my_distribution_dat      import InfoDistribution
from py_common.my_media_dat             import InfoMedia

#from py_common.my_infoweb              import Infoweb, get_webinfo
#from py_common.my_infofile             import Infofile, get_fileinfo
#from py_common.my_infodata             import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
# descript: args parser
#   input :                  : unused
#   output:                  : unused
#   return: parse_args       : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def argsparser():
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug'   , help='Debug mode'                 , action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    parser.add_argument('--md2json' , help='Markdown -> json convert'   , default='', type=str)
    try:
        args = parser.parse_args()
    except:
        pass
    else:
        infosystem.args = args
    if infosystem.args:
        infosystem.debug    = infosystem.args.debug
        infosystem.debugout = infosystem.args.debugout if infosystem.debug != True else True
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# -----------------------------------------------------------------------------
# descript: initialize
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def initialize():
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    if infosystem.debug == True:
        message_info(function_name, 'Debug mode on')
    if infosystem.debugout == True:
        message_info(function_name, 'Debugout mode on')
    # -------------------------------------------------------------------------
    info_conf = InfoConfiguration()
    path_dist = info_conf.get('PATH_DIST')
    path_mdia = info_conf.get('PATH_MDIA')
    info_dist = InfoDistribution(path_dist + '.json')
    info_mdia = InfoMedia(path_mdia + '.json', info_conf)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return info_conf, info_dist, info_mdia

# -----------------------------------------------------------------------------
def md2list(path: str) -> list:
    table_rows = []
    headers = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line_str = line.strip()
                if line_str.startswith("|") and line_str.endswith("|"):
                    cells = [cell.strip() for cell in line_str.split("|")[1:-1]]
                    if all(re.match(r"^:?-+:?$", c) for c in cells):
                        continue
                    if not headers:
                        headers = cells
                    else:
                        row_dict = {}
                        for i, head in enumerate(headers):
                            row_dict[head] = cells[i] if i < len(cells) else ""
                        table_rows.append(row_dict)
                elif headers and table_rows:
                    break
        return table_rows
    except FileNotFoundError:
        print(f"Error: {path} not found")
        return []

# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def main():
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        print(f"{color.reset}{color.br_green}{infosystem.program_name}:\n{color.br_yellow} You have standard user privileges. {color.underline}Please run this with sudo.{color.reset}")
        exit(1)
    # --- system parameters ---------------------------------------------------
    function_name = inspect.currentframe().f_code.co_name
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- global variable -----------------------------------------------------
#   global debug_flag
#   global debugout_flag
#   global program_name
#   global col_size
#   global row_size
    # --- startup process -----------------------------------------------------
    message_start(function_name)
    # --- processing block ----------------------------------------------------
    argsparser()
    if infosystem.args:
        info_conf, info_dist, info_mdia = initialize()
        if (path := infosystem.args.md2json):
            fmat_mdia = r"{type:<11} {entry_flag:<11} {entry_name:<39} {entry_disp:<39} {version:<23} {latest:<23} {release:<15} {support:<15} {web_regexp:<143} {web_path:<143} {web_tstamp:<47} {web_size:<15} {web_check:<47} {web_status:<15} {iso_path:<87} {iso_tstamp:<47} {iso_size:<15} {iso_volume:<43} {rmk_path:<87} {rmk_tstamp:<47} {rmk_size:<15} {rmk_volume:<43} {ldr_initrd:<87} {ldr_kernel:<87} {cfg_path:<87} {cfg_tstamp:<47} {lnk_path:<87} {options:<59} {create_flag:<11} "
            list_data = md2list(path)
            list_data = spc_encode4md(list_data)
            save_json('./test.json', list_data)
            put_list2text('./test.dat', list_data, fmat_mdia)
    # --- termination process -------------------------------------------------
    message_end(function_name)
    # --- elapsed end ---------------------------------------------------------
    end = time.perf_counter()
    elapsed = end - start
    message_elapsed(function_name, elapsed)
    # --- exit ----------------------------------------------------------------
    exit(0)
    # -------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --- eof ---------------------------------------------------------------------
