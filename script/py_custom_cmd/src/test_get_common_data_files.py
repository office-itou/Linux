#!/usr/bin/env python3
# encoding: utf-8

import os
#topdir = os.getcwd()

#topdir = "/home/master/linux/script/py_custom_cmd/src"
import sys
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

from collections import defaultdict

from py_common          import config
from py_common.colors   import color
from py_common.debug    import debugout

from py_common.common_cfg       import Common_cfg
from py_common.distribution_dat import Distribution_dat
from py_common.media_dat        import Media_dat

#from py_common.infoweb  import Infoweb, get_webinfo
#from py_common.infofile import Infofile, get_fileinfo
#from py_common.infodata import Infodata, debug_info, get_infodata

def output_cfg2md(path, data):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    max_key, max_val = max(data.items(), key=lambda x: len(x[1]))
    len_max_key = len(max_key)
    len_max_val = len(max_val)
    item_key = "key"
    item_val = "value"
    align    = "|:" + "-" * (len_max_key - 2) + ":|:" + "-" * (len_max_val - 1) + "|"
    md_text = f"|{item_key:^{len_max_key}}|{item_val:^{len_max_val}}|\n{align}\n"
    for key in data.keys():
        value = data[key]
        value = re.sub(r":_", ":\\_", value)
        value = re.sub(r"_:", "\\_:", value)
        md_text = md_text + f"|{key:^{len_max_key}}|{value:<{len_max_val}}|\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(md_text)
    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    return

def output_dat2md(path, data):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    colssize  = []
    header    = ""
    align     = ""
    df = pd.DataFrame(data)
#    colcount = df.shape[1]
#    rowcount = df.shape[0]
#    print(f"colcount:{colcount}")
#    print(f"rowcount:{rowcount}")
#    datalist  = defaultdict(dict)
    for name in df.columns.to_list():
        list = df[name].values
        max_val = max(list, key=len)
        colsize = len(max_val) if len(max_val) >= len(name) else len(name)
        colssize.append(colsize)
        header += f"|{name:^{colsize}}"
        align += "|:" + "-" * (colsize - 1)
#        for i, line in enumerate(list):
#            datalist[i][name] = line
    header += "|"
    align += "|"
#    print(datablock)
    md_text = f"{header}\n{align}\n"
    for index, row in df.iterrows():
        md_line = ""
        for i, name in enumerate(df.columns.to_list()):
            colsize = colssize[i]
            md_line += f"|{row[name]:<{colsize}}"
        md_text += md_line + f"|\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(md_text)
    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    return

def main():
    start = time.perf_counter()
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")

    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug', help='Debug mode', action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    args = parser.parse_args()
    config.debug = args.debug
    config.debugout = args.debugout
    if config.debug == True:
        config.debugout = True

    debugout(config.debugout, color.yellow, func_name, "info", "Debug mode on")

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

    output_cfg2md("./Readme_table_common_cfg.md"      , conf)
    output_dat2md("./Readme_table_distribution_dat.md", dist)
    output_dat2md("./Readme_table_media_dat.md"       , mdia)

    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    end = time.perf_counter()
    elapsed = end - start
    print(f"elapsed time: {elapsed:.4f} 秒")

if __name__ == "__main__":
    main()
