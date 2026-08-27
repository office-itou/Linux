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
class Info_distribution:
    version:     str = ""
    name:        str = ""
    version_id:  str = ""
    code_name:   str = ""
    life:        str = ""
    release:     str = ""
    support:     str = ""
    long_term:   str = ""
    rhel:        str = ""
    kerne:       str = ""
    note:        str = ""
    wallpaper:   str = ""
    create_flag: str = ""
    sort_flag:   str = ""

# -----------------------------------------------------------------------------
# descript: load distribution information in json format
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
    return Info_distribution.from_json(json_str)

# -----------------------------------------------------------------------------
# descript: save distribution information in json format
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
    json_str = Info_distribution.to_json(data)
    for line in json_str:
        for key in line.keys:
            line[key] = line[key].replace(r" ", r"%20")
    with open(path, "w", encoding='utf-8') as f:
        json.dump(json_str, f, ensure_ascii=False, indent=4)
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")

# --- eof ---------------------------------------------------------------------
