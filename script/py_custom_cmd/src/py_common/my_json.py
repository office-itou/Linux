#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
#from pathlib import Path
#import argparse
import inspect
#from datetime import datetime
#import time
#import shutil
#import os
import re
import json
import csv

# --- my library --------------------------------------------------------------
#topdir = '/home/master/linux/script/py_custom_cmd/src'
#import sys
#sys.path.append(topdir)

import py_common.my_config as my_config
#from py_common.my_config import debug_flag, debugout_flag, program_name, col_size, row_size
from py_common.my_colors  import color
#from py_common.my_string import count_width
#from py_common.my_string  import eprint
from py_common.my_debug   import debugout
#from py_common.my_message import message_debug

#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

#from py_common.my_infoweb  import Infoweb, get_webinfo
#from py_common.my_infofile import Infofile, get_fileinfo
#from py_common.my_infodata import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
# descript: load data in json format
#   input : path             : input
#   output:                  : unused
#   return: obj              : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def load_json(path, hook):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    obj = None
    with open(path, 'r', encoding='utf-8') as f:
        obj = json.load(f, object_hook=hook)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return obj

# -----------------------------------------------------------------------------
# descript: save distridata in json format
#   input : path             : input
#   input : obj              : input
#   output:                  : unused
#   return:                  : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def save_json(path, obj):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=4)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# -----------------------------------------------------------------------------
# descript: text file to json
#   input : path             : input
#   output:                  : unused
#   return: data             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def get_text2json(path):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    text = list(csv.DictReader(re.sub(r"[ \t]+", ",", line.strip()) for line in open(path, 'r', encoding='utf-8', newline='')))
    data = json.dumps(text, ensure_ascii=False)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return data

# -----------------------------------------------------------------------------
# descript: json to text file
#   input : path             : input
#   input : data             : input
#   input : format           : input
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def put_json2text(path, data, format):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    list = json.loads(data)
    keys = dict()
    for key, value in list[0].items():
        keys[key] = key
    text = [format.format(**keys)]
    for line in list:
        text.append(format.format(**line))
    with open(path, 'w', encoding='utf-8') as f:
        f.write(f"\n".join(text) + f"\n")
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# --- eof ---------------------------------------------------------------------
