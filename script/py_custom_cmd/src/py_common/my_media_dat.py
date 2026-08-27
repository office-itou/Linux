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
from dataclasses import dataclass, asdict

#@dataclass_json
@dataclass
class Data_media:
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

class Info_media:
    def __init__(self):
        self.data = Data_media
    def load(self, path):
        self.data = load(path)
    def save(self, path):
        save(path, self.data)

# ----------------------------# -----------------------------------------------------------------------------
# descript: hook function for load
#   input : dict             : input
#   output:                  : unused
#   return: result           : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def from_json(dict):
    return Data_media(**dict)

# -----------------------------------------------------------------------------
# descript: hook function for save
#   input : dict             : input
#   output:                  : unused
#   return: result           : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def to_json(objs):
    return [asdict(obj) for obj in objs]

# -----------------------------------------------------------------------------
# descript: load distribution information in json format
#   input : path             : input
#   output:                  : unused
#   return: obj              : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def load(path):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    obj = None
    with open(path, "r", encoding='utf-8') as f:
        obj = json.load(f, object_hook=from_json)
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")
    return obj

# -----------------------------------------------------------------------------
# descript: save distribution information in json format
#   input : path             : input
#   input : items            : input
#   output:                  : unused
#   return:                  : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def save(path, items):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    obj = to_json(items)
    with open(path, "w", encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=4)
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")

# --- eof ---------------------------------------------------------------------
