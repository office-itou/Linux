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
from dataclasses import dataclass, fields
import re
# sudo apt-get install python3-pandas
import pandas as pd
import json
from collections.abc import Iterable

# --- my library --------------------------------------------------------------
topdir = "/home/master/linux/script/py_custom_cmd/src"
import sys
sys.path.append(topdir)

#import py_common.my_config as my_config
from py_common.my_config  import infosystem
from py_common.my_colors   import color
#from py_common.my_string  import count_width
#from py_common.my_string  import eprint
from py_common.my_debug    import debugout
from py_common.my_message  import message_start, message_end, message_elapsed, message_debug
from py_common.my_markdown import json2markdown

from py_common.my_common_cfg       import InfoConfiguration
from py_common.my_distribution_dat import InfoDistribution
from py_common.my_media_dat        import InfoMedia, MediaData

#from py_common.my_infoweb  import Infoweb, get_webinfo
#from py_common.my_infofile import Infofile, get_fileinfo
#from py_common.my_infodata import Infodata, debug_info, get_infodata

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
# descript: test
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def get_field_list(obj):
    list_field = []
    for field in fields(obj):
        list_field.append(field.name)
    return f" ".join(list_field)

def dump_dict(data):
    width = infosystem.data.columns
    print(color.yellow + '-' * width + color.reset)
    if isinstance(data, Iterable):
        if isinstance(data, dict):
            try:
                for key, value in data.items():
                    text = f"{key}: {value}"
                    print(f"{color.green}{text:.{width}s}{color.reset}")
            except Exception as e:
                print(f"{color.bg_red}Exception error: {e}{color.reset}")
                raise
    print(color.yellow + '-' * width + color.reset)

def dump(data):
    width = infosystem.data.columns
    print(color.yellow + '-' * width + color.reset)
    try:
        for line in data:
            text = str(line)
            print(f"{color.green}{text:.{width}s}{color.reset}")
    except Exception as e:
        print(f"{color.bg_red}Exception error: {e}{color.reset}")
        raise
    print(color.yellow + '-' * width + color.reset)

# -----------------------------------------------------------------------------
# descript: test
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def test():
#    path_conf = '/srv/user/share/conf/_data/common.cfg'
    path_dist = '/srv/user/share/conf/_data/distribution.dat.json'
    path_mdia = '/srv/user/share/conf/_data/media.dat.json'
    mkdw_conf = './Radme_configuration.md'
    mkdw_dist = './Radme_distribution.md'
    mkdw_mdia = './Radme_media.md'
    mkdw_mda2 = './Radme_media(data).md'
    mkdw_mda3 = './Radme_media(revert).md'
    titl_conf = 'common configuration file (common.cfg)'
    titl_dist = 'distribution data file (distribution.dat)'
    titl_mdia = 'media data file (media.dat)'
    titl_mda2 = 'media data file (data)'
    titl_mda3 = 'media data file (revert)'

    conf = InfoConfiguration()
    conf.load()
#    dump_dict(conf.data)

    dist = InfoDistribution()
    dist.load(path_dist)
#    dump(dist.data)

    mdia = InfoMedia()
    mdia.load(path_mdia)
#    dump(mdia.data)

#    conf.markdown(mkdw_conf, titl_conf)
    dist.markdown(mkdw_dist, titl_dist)
    mdia.markdown(mkdw_mdia, titl_mdia)

    mdia.conv2data(conf)
    mdia.markdown(mkdw_mda2, titl_mda2)
    mdia.conv2variable(conf)
    mdia.markdown(mkdw_mda3, titl_mda3)

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
def main():
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
    infosystem.data.debug = args.debug
    infosystem.data.debugout = args.debugout if infosystem.data.debug != True else True
    # --- system parameters ---------------------------------------------------
    function_name = inspect.currentframe().f_code.co_name
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        message_debug(function_name, "Warning", color.br_yellow, "You have standard user privileges. Please run this with sudo.")
        exit(1)
    # --- startup process -----------------------------------------------------
    message_start(function_name)
    # --- processing block ----------------------------------------------------
    initialize()
    test()
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
