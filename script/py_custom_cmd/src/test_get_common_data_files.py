#!/usr/bin/env python3
# encoding: utf-8

#import os
#topdir = os.getcwd()

#topdir = "/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

import argparse
#from pathlib import Path
import re
import inspect

#import aiohttp                          # sudo apt-get install python3-aiohttp
#from aiohttp import ClientError, ClientTimeout
#import asyncio

#import json
import time

# sudo apt-get install python3-pandas
import pandas as pd

#from collections import defaultdict

from py_common.my_config           import debug_flag, debugout_flag
from py_common.my_colors           import color
from py_common.my_debug            import debugout

from py_common.my_common_cfg       import Common_cfg
from py_common.my_distribution_dat import Distribution_dat
from py_common.my_media_dat        import Media_dat

#from py_common.my_infoweb  import Infoweb, get_webinfo
#from py_common.my_infofile import Infofile, get_fileinfo
#from py_common.my_infodata import Infodata, debug_info, get_infodata

def output_cfg2md(path, title, data):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", "")
    max_key, max_val = max(data.items(), key=lambda x: len(x[1]))
    len_max_key = len(max_key)
    len_max_val = len(max_val)
    item_key = "key"
    item_val = "value"
    spc = " " * 2
    align    = "|:" + "-" * (len_max_key - 2) + ":|:" + "-" * (len_max_val - 1) + "|"
    md_text = f"# Data table\n\n* {title}\n\n{spc}|{item_key:^{len_max_key}}|{item_val:^{len_max_val}}|\n{spc}{align}\n"
    for key in data.keys():
        value = data[key]
        value = re.sub(r":_", ":\\_", value)
        value = re.sub(r"_:", "\\_:", value)
        md_text = md_text + f"{spc}|{key:^{len_max_key}}|{value:<{len_max_val}}|\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(md_text)
    debugout(debugout_flag, color.yellow, func_name, "Complete", "")
    return

def output_dat2md(path, title, data):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", "")
    colssize  = []
    spc = " " * 2
    header    = ""
    align     = ""
    df = pd.DataFrame(data)
#    colcount = df.shape[1]
#    rowcount = df.shape[0]
#    print(f"colcount:{colcount}")
#    print(f"rowcount:{rowcount}")
#    datalist = defaultdict(dict)
    for name in df.columns.to_list():
        list = df[name].values
        for i, line in enumerate(list):
            line = re.sub(r"^(http[|s]:[^ ]+)", r"`\1`", line)
            list[i] = line
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
    return

def main():
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

#   if os.geteuid() != 0:
#       print(f"{color.br_yellow}You have standard user privileges. Please run this with sudo.{color.reset}")
#       exit(1)

    common_cfg       = Common_cfg()
    distribution_dat = Distribution_dat()
    media_dat        = Media_dat()

    common_cfg.load()
    conf = common_cfg.exports()

    distribution_dat.load(conf)
    dist = distribution_dat.exports()

    media_dat.load(conf, dist)
    mdia = media_dat.exports()

    output_cfg2md("./Readme_table_common_cfg.md"      , "common configuration file (common.cfg)"   , conf)
    output_dat2md("./Readme_table_distribution_dat.md", "distribution data file (distribution.dat)", dist)
    output_dat2md("./Readme_table_media_dat.md"       , "media data file (media.dat)"              , mdia)

    debugout(True, color.yellow, func_name, "Complete", "")
    end = time.perf_counter()
    elapsed = end - start
    print(f"elapsed time: {elapsed:.4f} 秒")

if __name__ == "__main__":
    main()
