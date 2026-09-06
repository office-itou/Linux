#!/usr/bin/env python3
# encoding: utf-8

import os
#topdir = os.getcwd()

#topdir = "/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

import argparse
from pathlib import Path
import re
import inspect

import aiohttp                          # sudo apt-get install python3-aiohttp
from aiohttp import ClientError, ClientTimeout
import asyncio

import json
import time

# sudo apt-get install python3-pandas
import pandas as pd

from py_common.my_config           import debug_flag, debugout_flag
from py_common.my_colors           import color
from py_common.my_debug            import debugout

#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

from py_common.my_infoweb  import Infoweb, get_webinfo
from py_common.my_infofile import Infofile, get_fileinfo
from py_common.my_infodata import Infodata, debug_info, get_infodata

def generate_md_table(infodatas):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", "")
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
#    print("-" * 80)
#    print(type(data))
#    print("-" * 80)
#    print(data)
#    print("-" * 80)
#    with open("./py_prototype/test.json", "w", encoding="utf-8") as f:
#        json.dump(data, f, ensure_ascii=False, indent=4)
    # -------------------------------------------------------------------------
    colssize  = []
    spc = " " * 2
    header    = ""
    align     = ""
    df = pd.DataFrame(data)
    for name in df.columns.to_list():
        list = df[name].values
#       print(line)
#        for i, line in enumerate(list):
#            line = re.sub(r"^(http[|s]:[^ ]+)", r"`\1`", line)
#            list[i] = line
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
    debugout(debugout_flag, color.yellow, func_name, "Complete", "")

async def main():
    start = time.perf_counter()
    func_name = inspect.currentframe().f_code.co_name
    debugout(True, color.yellow, func_name, "Start", "")

    global debug_flag
    global debugout_flag

    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug', help='Debug mode', action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    args = parser.parse_args()
    debug_flag = args.debug
    debugout_flag = args.debugout
    if debug_flag == True:
        debugout_flag = True

    debugout(debugout_flag, color.yellow, func_name, "info", "Debug mode on")

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
#        for infodata in infodatas:
#            debug_info(infodata)

    generate_md_table(infodatas)

    debugout(True, color.yellow, func_name, "Complete", "")
    end = time.perf_counter()
    elapsed = end - start
    print(f"elapsed time: {elapsed:.4f} 秒")

if __name__ == "__main__":
    asyncio.run(main())
