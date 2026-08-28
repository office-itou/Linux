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
#topdir = r"/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

import py_common.my_config as my_config
#from py_common.my_config import debug_flag, debugout_flag, program_name, col_size, row_size
from py_common.my_colors import color
#from py_common.my_string import count_width
from py_common.my_string import eprint
#from py_common.my_debug  import debugout
from py_common.my_message import message_debug

#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

#from py_common.my_infoweb  import Infoweb, get_webinfo
#from py_common.my_infofile import Infofile, get_fileinfo
#from py_common.my_infodata import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
# descript: debug output for scale
#   input : size             : input
#   output: stdout           : output
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def debugout_scale(size):
        gap = '-' * size
        scale_u = ''
        scale_m = ''
        scale_l = ''
        for i in range(1, size + 1):
            u, m = divmod(i, 100)
            m, l = divmod(i, 10)
            scale_u += str(u)[-1] if l == 0 else ' '
            scale_m += str(m)[-1] if l == 0 else ' '
            scale_l += str(l)
#       print(gap)
#       print(scale_u)
        print(scale_m)
        print(scale_l)

# -----------------------------------------------------------------------------
# descript:  debug output
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: debugout_flag    : read
# -----------------------------------------------------------------------------
def debugout(function_name, mode, message_color, message):
    if my_config.debugout_flag == False: return
    message_debug(function_name, mode, message_color, message)

# --- eof ---------------------------------------------------------------------
