#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
from pathlib import Path
#import argparse
#import inspect
from datetime import datetime
#import time
#import shutil
#import os

# --- my library --------------------------------------------------------------
#topdir = "/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

import py_common.my_config as my_config
#from py_common.my_config import debug_flag, debugout_flag, program_name, col_size, row_size
from py_common.my_colors import color
from py_common.my_string import count_width
from py_common.my_string import eprint
#from py_common.my_debug  import debugout
#from py_common.my_message import message_debug

#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

#from py_common.my_infoweb  import Infoweb, get_webinfo
#from py_common.my_infofile import Infofile, get_fileinfo
#from py_common.my_infodata import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
# descript: message output for common
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : date_time        : input
#   output: stdout           : output
#   return:                  : unused
#   global: col_size         : read
# -----------------------------------------------------------------------------
def message_common(function_name, mode, message_color, date_time):
    message = f"{function_name}:{mode:^10}:--- {date_time} "
    message += "-" * (my_config.col_size - count_width(message))
    eprint(f"{color.reset}{message_color}{message}{color.reset}", my_config.col_size)

# -----------------------------------------------------------------------------
# descript: message output for startup
#   input : function_name    : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_start(function_name):
    date_time = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
    message_common(f"{my_config.program_name}({function_name})", "Start", color.green, date_time)

# -----------------------------------------------------------------------------
# descript: message output for termination
#   input : function_name    : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_end(function_name):
    date_time = datetime.now().strftime("%Y/%m/%d %H:%M:%S")
    message_common(f"{my_config.program_name}({function_name})", "Complete", color.green, date_time)

# -----------------------------------------------------------------------------
# descript: message output for elapsed time
#   input : function_name    : input
#   input : elapsed          : input
#   output: stdout           : output
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def message_elapsed(function_name, elapsed):
    message_debug(function_name, "Elapsed", color.yellow, f"{elapsed:.4f} sec")

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_debug(function_name, mode, message_color, message):
    eprint(f"{color.reset}{message_color}{my_config.program_name}({function_name}):{mode:^10}:{message}{color.reset}", my_config.col_size)

# --- eof ---------------------------------------------------------------------
