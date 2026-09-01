#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import os
import inspect
import time
import argparse
from time import sleep

from aiohttp import ClientError, ClientTimeout
#from bs4 import BeautifulSoup
#from dataclasses import dataclass
#from dataclasses import dataclass, asdict
#from datetime import datetime
#from datetime import datetime, timedelta
#from datetime import datetime, timezone
#from natsort import natsort_keygen
from pathlib import Path
#from tqdm import tqdm
#from urllib.parse import urlparse
import aiohttp # sudo apt-get install python3-aiohttp
import asyncio
#import csv
#import dataclasses
import json
#import magic # sudo apt-get install python3-magic
import pandas as pd
import re
#import shutil
#import subprocess
#import sys
#import unicodedata
#import __main__

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
from py_common.my_string               import eprint
from py_common.my_message               import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert
from py_common.my_debug                 import debugout
#from py_common.my_process              import run_subprocess
#from py_common.my_json                 import load_json, save_json, get_text2json, put_json2text
#from py_common.my_markdown             import json2markdown, spc_encode4md, spc_decode4md

from py_common.my_common_cfg            import InfoConfiguration
from py_common.my_distribution_dat      import InfoDistribution
from py_common.my_media_dat             import InfoMedia
import py_common.my_media_dat

from py_common.my_infoweb               import InfoWeb
from py_common.my_infofile              import InfoFile
from py_common.my_infodata              import InfoData

# -----------------------------------------------------------------------------
# descript: args parser
#   input :                  : unused
#   output:                  : unused
#   return: parse_args       : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def argsparser():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug'   , help='Debug mode'                 , action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    try:
        args = parser.parse_args()
    except:
        pass
    else:
        infosystem.data.args = args
    if infosystem.data.args:
        infosystem.data.debug    = infosystem.data.args.debug
        infosystem.data.debugout = infosystem.data.args.debugout if infosystem.data.debug != True else True

# -----------------------------------------------------------------------------
# descript: initialize
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def initialize():
    function_name = inspect.currentframe().f_code.co_name
    debugout(Path(__file__).stem + '('+ function_name + ')', "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    if infosystem.data.debug == True:
        message_info(function_name, 'Debug mode on')
    if infosystem.data.debugout == True:
        message_info(function_name, 'Debugout mode on')
    # -------------------------------------------------------------------------
    debugout(Path(__file__).stem + '('+ function_name + ')', "Complete", color.yellow, "")
    return

# -----------------------------------------------------------------------------
# descript: generate markdown table
#   input : infodatas        : input
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def generate_md_table(list_infodata: list):
    function_name = inspect.currentframe().f_code.co_name
    debugout(Path(__file__).stem + '('+ function_name + ')', "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    path = "./web_info.md"
    title = "web info"
    data = list()
    for infodata in list_infodata:
        infoweb  = infodata.web
        infofile = infodata.file
        contents = "-"
        if re.sub(r"/[^/]+$", '', infoweb.mime) == 'text':
            contents = str(infoweb.contents) if hasattr(infoweb, "data")  and hasattr(infoweb.data,  "contents") else "-"
        data.append(
            {
                "web.regexp"  : f"`{infoweb.regexp}`" if hasattr(infoweb,  "regexp")   else "-",
                "web.url"     : f"`{infoweb.url}`"    if hasattr(infoweb,  "url")      else "-",
                "web.tmstamp" : str(infoweb.tmstamp)  if hasattr(infoweb,  "tmstamp")  else "-",
                "web.size"    : str(infoweb.size)     if hasattr(infoweb,  "size")     else "-",
                "web.check"   : str(infoweb.check)    if hasattr(infoweb,  "check")    else "-",
                "web.status"  : str(infoweb.status)   if hasattr(infoweb,  "status")   else "-",
                "web.reason"  : str(infoweb.reason)   if hasattr(infoweb,  "reason")   else "-",
                "web.mime"    : str(infoweb.mime)     if hasattr(infoweb,  "mime")     else "-",
                "web.contents": f"`{contents}`",
                "web.output"  : str(infoweb.output)   if hasattr(infoweb,  "output")   else "-",
                "file.path"   : str(infofile.path)    if hasattr(infofile, "path")     else "-",
                "file.tmstamp": str(infofile.tmstamp) if hasattr(infofile, "tmstamp")  else "-",
                "file.size"   : str(infofile.size)    if hasattr(infofile, "size")     else "-",
                "file.volume" : str(infofile.volume)  if hasattr(infofile, "volume")   else "-"
            }
        )
    # -------------------------------------------------------------------------
    colssize  = []
    spc = " " * 2
    header    = ""
    align     = ""
    df = pd.DataFrame(data)
    for name in df.columns.to_list():
        max_val = max(df[name].values, key=len)
        colsize = len(max_val) if len(max_val) >= len(name) else len(name)
        colssize.append(colsize)
        header += f"|{name:^{colsize}}"
        match re.sub(r"^[^.]+.", '', name):
            case 'size':
                align += '|' + '-' * (colsize - 1) + ':'
            case 'tmstamp' | 'check' | 'status' | 'reason' | 'mime':
                align += '|:' + '-' * (colsize - 2) + ':'
            case _:
                align += '|:' + '-' * (colsize - 1)
    header += '|'
    align += '|'
    md_text = f"# Data table\n\n* {title}\n\n{spc}{header}\n{spc}{align}\n"
    for index, row in df.iterrows():
        md_line = ''
        for i, name in enumerate(df.columns.to_list()):
            colsize = colssize[i]
            md_line += f"|{row[name]:<{colsize}}"
        md_text += f"{spc}{md_line}|\n"
    with open(path, 'w', encoding='utf-8') as f:
        f.write(md_text)
    # -------------------------------------------------------------------------
    debugout(Path(__file__).stem + '('+ function_name + ')', "Complete", color.yellow, "")

# -----------------------------------------------------------------------------
def debug(info):
    eprint("# --------------------------------------------------------------------------- #")
    data = info
    if hasattr(data, "web"):
        eprint("info data for web")
        data_infoweb = data.web.data
        if hasattr(data_infoweb, "regexp"  ): eprint(f"web.regexp  : [{data_infoweb.regexp}]")
        if hasattr(data_infoweb, "url"     ): eprint(f"web.urlh    : [{data_infoweb.url}]")
        if hasattr(data_infoweb, "tmstamp" ): eprint(f"web.tmstamp : [{data_infoweb.tmstamp}]")
        if hasattr(data_infoweb, "size"    ): eprint(f"web.size    : [{data_infoweb.size}]")
        if hasattr(data_infoweb, "check"   ): eprint(f"web.check   : [{data_infoweb.check}]")
        if hasattr(data_infoweb, "status"  ): eprint(f"web.status  : [{data_infoweb.status}]")
        if hasattr(data_infoweb, "reason"  ): eprint(f"web.reason  : [{data_infoweb.reason}]")
        if hasattr(data_infoweb, "mime"    ): eprint(f"web.mime    : [{data_infoweb.mime}]")
        if hasattr(data_infoweb, "contents"): eprint(f"web.contents: [{data_infoweb.contents}]") if re.sub(r"/[^/]+$", '', data_infoweb.mime) == 'text' else ''
        if hasattr(data_infoweb, "output"  ): eprint(f"web.output  : [{data_infoweb.output}]")
    if hasattr(data, "file"):
        eprint("info data for file")
        data_infofile = data.file.data
        if hasattr(data_infofile, "path"   ): eprint(f"file.path   : [{data_infofile.path}]")
        if hasattr(data_infofile, "tmstamp"): eprint(f"file.tmstamp: [{data_infofile.tmstamp}]")
        if hasattr(data_infofile, "size"   ): eprint(f"file.size   : [{data_infofile.size}]")
        if hasattr(data_infofile, "volume" ): eprint(f"file.volume : [{data_infofile.volume}]")
    eprint("# --------------------------------------------------------------------------- #")

# -----------------------------------------------------------------------------
# descript: get web /file information data
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
async def get_info() -> list:
    path = "/home/master/linux/script/py_custom_cmd/src/py_prototype/list.json"
    with open(path, "r", encoding="utf-8") as f:
        list_url_file = json.load(f)
    list_infodata = list()
    infodata = InfoData()
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(timeout=timeout, raise_for_status=False) as session:
        count = 0
        for line in list_url_file:
            if line["allow"].lower() != "true":
                continue
            target_regexp = line["url"]
            target_path   = line["path"]
            infodata.data = await infodata.get_info(session, target_regexp, target_path)
#            infodata.data = await infodata.get_data()
            list_infodata.append(infodata.data)
#            count += 1
#            if count > 3: break
#            if infodata.data.web.data.status != 200:
#                debug(infodata)
#            await asyncio.sleep(1)
#            break
    return list_infodata

# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
async def main():
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        eprint(f"{color.reset}{color.br_green}{infosystem.data.program_name}:\n{color.br_yellow} You have standard user privileges. {color.underline}Please run this with sudo.{color.reset}")
        exit(1)
    # --- system parameters ---------------------------------------------------
    function_name = inspect.currentframe().f_code.co_name
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- global variable -----------------------------------------------------
    # --- startup process -----------------------------------------------------
    message_start(function_name)
    # --- processing block ----------------------------------------------------
    argsparser()
    if infosystem.data.args:
        initialize()
        list_infodata = await get_info()
        generate_md_table(list_infodata)
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
