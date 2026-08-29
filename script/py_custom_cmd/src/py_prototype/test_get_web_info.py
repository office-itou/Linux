#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
from pathlib import Path
import argparse
import inspect
from datetime import datetime
import time
import shutil
import os
import asyncio
import aiohttp                          # sudo apt-get install python3-aiohttp
from aiohttp import ClientError, ClientTimeout
import json
import pandas as pd                     # sudo apt-get install python3-pandas

# --- my library --------------------------------------------------------------
#topdir = "/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

import py_common.my_config as my_config
#from py_common.my_config import debug_flag, debugout_flag, program_name, col_size, row_size
from py_common.my_colors import color
#from py_common.my_string import count_width
#from py_common.my_string import eprint
from py_common.my_debug  import debugout
from py_common.my_message import message_start, message_end, message_elapsed, message_debug

#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

from py_common.my_infoweb  import Infoweb, get_webinfo
from py_common.my_infofile import Infofile, get_fileinfo
from py_common.my_infodata import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
# descript: args parser
#   input :                  : unused
#   output:                  : unused
#   return: parse_args       : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def argsparser():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug', help='Debug mode', action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    return parser.parse_args()

# -----------------------------------------------------------------------------
# descript: initialize
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def initialize():
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    debugout(function_name, "Info", color.yellow, "Debug mode on")
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")
    return

# -----------------------------------------------------------------------------
# descript: generate markdown table
#   input : infodatas        : input
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def generate_md_table(infodatas):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    path = "./web_info.md"
    title = "web info"
    list = []
    for infodata in infodatas:
        line = {
            "web.regexp"  : f"`{infodata.web.regexp}`" if hasattr(infodata, "web")  and hasattr(infodata.web,  "regexp")   else "-",
            "web.urlh"    : f"`{infodata.web.url}`"    if hasattr(infodata, "web")  and hasattr(infodata.web,  "url")      else "-",
            "web.tmstamp" : str(infodata.web.tmstamp)  if hasattr(infodata, "web")  and hasattr(infodata.web,  "tmstamp")  else "-",
            "web.size"    : str(infodata.web.size)     if hasattr(infodata, "web")  and hasattr(infodata.web,  "size")     else "-",
            "web.check"   : str(infodata.web.check)    if hasattr(infodata, "web")  and hasattr(infodata.web,  "check")    else "-",
            "web.status"  : str(infodata.web.status)   if hasattr(infodata, "web")  and hasattr(infodata.web,  "status")   else "-",
            "web.reason"  : str(infodata.web.reason)   if hasattr(infodata, "web")  and hasattr(infodata.web,  "reason")   else "-",
            "web.contents": str(infodata.web.contents) if hasattr(infodata, "web")  and hasattr(infodata.web,  "contents") else "-",
            "web.output"  : str(infodata.output)       if hasattr(infodata, "web")  and hasattr(infodata.web,  "output")   else "-",
            "file.path"   : str(infodata.file.path)    if hasattr(infodata, "file") and hasattr(infodata.file, "path")     else "-",
            "file.tmstamp": str(infodata.file.tmstamp) if hasattr(infodata, "file") and hasattr(infodata.file, "tmstamp")  else "-",
            "file.size"   : str(infodata.file.size)    if hasattr(infodata, "file") and hasattr(infodata.file, "size")     else "-",
            "file.volume" : str(infodata.file.volume)  if hasattr(infodata, "file") and hasattr(infodata.file, "volume")   else "-"
        }
        list.append(line)
    data = list
    # -------------------------------------------------------------------------
    colssize  = []
    spc = " " * 2
    header    = ""
    align     = ""
    df = pd.DataFrame(data)
    for name in df.columns.to_list():
        list = df[name].values
        max_val = max(list, key=len)
        colsize = len(max_val) if len(max_val) >= len(name) else len(name)
        colssize.append(colsize)
        header += f"|{name:^{colsize}}"
        align += "|:" + "-" * (colsize - 1)
    header += "|"
    align += "|"
    md_text = f"# Data table\n\n* {title}\n\n{spc}{header}\n{spc}{align}\n"
    for index, row in df.iterrows():
        md_line = ""
        for i, name in enumerate(df.columns.to_list()):
            colsize = colssize[i]
            md_line += f"|{row[name]:<{colsize}}"
        md_text += f"{spc}{md_line}|\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(md_text)
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")

# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global: debug_flag       : read/write
#   global: debugout_flag    : read/write
#   global: program_name     : read/write
#   global: col_size         : read/write
#   global: row_size         : read/write
# -----------------------------------------------------------------------------
async def main():
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- global variable -----------------------------------------------------
#   global debug_flag
#   global debugout_flag
#   global program_name
#   global col_size
#   global row_size
    # --- command options -----------------------------------------------------
    args = argsparser()
    my_config.debug_flag = args.debug
    my_config.debugout_flag = args.debugout if my_config.debug_flag != True else True
    # --- system parameters ---------------------------------------------------
    my_config.program_name = Path(__file__).name
    my_config.col_size = shutil.get_terminal_size().columns
    my_config.row_size = shutil.get_terminal_size().lines
    function_name = inspect.currentframe().f_code.co_name
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        message_debug(function_name, "Warning", color.br_yellow, "You have standard user privileges. Please run this with sudo.")
        exit(1)
    # --- startup process -----------------------------------------------------
    message_start(function_name)
    # --- processing block ----------------------------------------------------
    initialize()
    path = "/home/master/linux/script/py_custom_cmd/src/py_prototype/list.json"
    with open(path, "r", encoding="utf-8") as f:
        list = json.load(f)
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(timeout=timeout, raise_for_status=False) as session:
        infodatas = await get_infodata(session, list)
#        for infodata in infodatas:
#            debug_info(infodata)

    generate_md_table(infodatas)
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
    asyncio.run(main())

# --- eof ---------------------------------------------------------------------
