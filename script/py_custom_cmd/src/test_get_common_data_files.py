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

# --- my library --------------------------------------------------------------
#topdir = "/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

import py_common.my_config as my_config
#from py_common.my_config import debug_flag, debugout_flag, program_name, col_size, row_size
from py_common.my_colors import color
#from py_common.my_string import count_width
#from py_common.my_string import eprint
from py_common.my_debug  import debugout
from py_common.my_message import message_start, message_end, message_elapsed, message_debug

from py_common.my_common_cfg       import Common_cfg
from py_common.my_distribution_dat import Info_distribution
from py_common.my_media_dat        import Info_media

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
# descript: get data
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def get_data():
#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Info_distribution
#from py_common.my_media_dat        import Info_media
    dist = Info_distribution()
    dist.load("/srv/user/share/conf/_data/distribution.dat.json")
    mdia = Info_media()
    mdia.load("/srv/user/share/conf/_data/media.dat.json")
    print("-" * my_config.col_size)
    for line in dist.data:
        print(line.version)
    print("-" * my_config.col_size)
#    for line in mdia.data:
#        print(line)
#    print("-" * my_config.col_size)

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
    my_config.debug_flag = args.debug
    my_config.debugout_flag = args.debugout if my_config.debug_flag != True else True
    # --- system parameters ---------------------------------------------------
    my_config.program_name = Path(__file__).name
    my_config.col_size = shutil.get_terminal_size().columns
    my_config.row_size = shutil.get_terminal_size().lines
    function_name = inspect.currentframe().f_code.co_name
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        message_debug(function_name, "Warning", color.br_yellow, "You have standard user privileges. Please run this with sudo.")
        exit(1)
    # --- startup process -----------------------------------------------------
    message_start(function_name)
    # --- processing block ----------------------------------------------------
    initialize()
    get_data()
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
