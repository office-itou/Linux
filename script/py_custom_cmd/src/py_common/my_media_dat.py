#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
from pathlib import Path
#import argparse
import inspect
from datetime import datetime
#import time
#import shutil
#import os
import re
import json
import csv

# --- my library --------------------------------------------------------------
#topdir = "/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

import py_common.my_config as my_config
#from py_common.my_config import debug_flag, debugout_flag, program_name, col_size, row_size
from py_common.my_colors  import color
#from py_common.my_string import count_width
from py_common.my_string  import eprint
from py_common.my_debug   import debugout
from py_common.my_message import message_debug

#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

#from py_common.my_infoweb  import Infoweb, get_webinfo
#from py_common.my_infofile import Infofile, get_fileinfo
#from py_common.my_infodata import Infodata, debug_info, get_infodata


# -----------------------------------------------------------------------------
from dataclasses_json import dataclass_json
from dataclasses import dataclass

@dataclass_json
@dataclass
class Info_media:
    type:        str = ""
    entry_flag:  str = ""
    entry_name:  str = ""
    entry_disp:  str = ""
    version:     str = ""
    latest:      str = ""
    release:     str = ""
    support:     str = ""
    web_regexp:  str = ""
    web_path:    str = ""
    web_tstamp:  str = ""
    web_size:    str = ""
    web_check:   str = ""
    web_status:  str = ""
    iso_path:    str = ""
    iso_tstamp:  str = ""
    iso_size:    str = ""
    iso_volume:  str = ""
    rmk_path:    str = ""
    rmk_tstamp:  str = ""
    rmk_size:    str = ""
    rmk_volume:  str = ""
    ldr_initrd:  str = ""
    ldr_kernel:  str = ""
    cfg_path:    str = ""
    cfg_tstamp:  str = ""
    lnk_path:    str = ""
    options:     str = ""
    create_flag: str = ""

# -----------------------------------------------------------------------------
# descript: load media information in json format
#   input : path             : input
#   output:                  : unused
#   return: data             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def load(path):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    debugout(function_name, "Info", color.yellow, "Debug mode on")
    with open(path, "r", encoding='utf-8') as f:
        json_str = json.load(f)
    for line in json_str:
        for key in line.keys:
            line[key] = line[key].replace(r" ", r"%20")
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")
    return Info_media.from_json(json_str)

# -----------------------------------------------------------------------------
# descript: save media information in json format
#   input : path             : input
#   input : data             : input
#   output:                  : unused
#   return:                  : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def save(path, data):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    debugout(function_name, "Info", color.yellow, "Debug mode on")
    json_str = Info_media.to_json(data)
    for line in json_str:
        for key in line.keys:
            line[key] = line[key].replace(r" ", r"%20")
    with open(path, "w", encoding='utf-8') as f:
        json.dump(json_str, f, ensure_ascii=False, indent=4)
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")

# --- eof ---------------------------------------------------------------------
