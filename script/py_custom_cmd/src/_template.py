#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import os
import inspect
import time
import argparse

#from aiohttp import ClientError, ClientTimeout
#from bs4 import BeautifulSoup
#from dataclasses import dataclass
#from dataclasses import dataclass, asdict
#from datetime import datetime
#from datetime import datetime, timedelta
#from datetime import datetime, timezone
#from natsort import natsort_keygen
#from pathlib import Path
#from tqdm import tqdm
#from urllib.parse import urlparse
#import aiohttp # sudo apt-get install python3-aiohttp
#import asyncio
#import csv
#import dataclasses
#import json
#import magic # sudo apt-get install python3-magic
#import pandas as pd
#import re
#import shutil
#import subprocess
#import sys
#import unicodedata
#import __main__

# --- my library --------------------------------------------------------------
#from pathlib        import Path
#import os
#import sys
#execusr = os.getenv('USER')
#execusr = os.getenv('SUDO_USER', execusr)
#homedir = os.getenv('HOME')
#homedir = os.getenv('SUDO_HOME', homedir)
#libsdir = '/linux/script/py_custom_cmd/src/'
#libsdir = Path(homedir) / libsdir.strip('/')
#sys.path.append(str(libsdir))

from py_common.my_config                import infosystem
from py_common.my_argument              import Argument
from py_common.my_colors                import color
#from py_common.my_string               import eprint, count_width
from py_common.my_message               import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert, get_caller_name
from py_common.my_debug                 import debug_logger
#from py_common.my_process              import run_subprocess
#from py_common.my_fileio               import get_text2list, put_list2text, conv_text2json, conv_json2text
#from py_common.my_json                 import load_json, save_json
#from py_common.my_markdown             import list2markdown, spc_encode4md, spc_decode4md

#from py_common.my_common_cfg           import InfoConfiguration
#from py_common.my_distribution_dat     import InfoDistribution
#from py_common.my_media_dat            import InfoMedia

#from py_common.my_infoweb              import Infoweb, get_webinfo
#from py_common.my_infofile             import Infofile, get_fileinfo
#from py_common.my_infodata             import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
# descript: initialize
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def initialize():
    if infosystem.debug == True:
        message_info(get_caller_name(), 'Debug mode on')
    if infosystem.debugout == True:
        message_info(get_caller_name(), 'Debugout mode on')
    # -------------------------------------------------------------------------
    return

# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def main():
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        print(f"{color.reset}{color.br_green}{infosystem.program_name}:\n{color.br_yellow} You have standard user privileges. {color.underline}Please run this with sudo.{color.reset}")
        exit(1)
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- startup process -----------------------------------------------------
    message_start(get_caller_name())
    # --- processing block ----------------------------------------------------
    arg_manager = Argument()
#   arg_manager.add('--add', type=str, help='add args')
    args = arg_manager.parse()
    if args:
        initialize()
    # --- termination process -------------------------------------------------
    message_end(get_caller_name())
    # --- elapsed end ---------------------------------------------------------
    end = time.perf_counter()
    elapsed = end - start
    message_elapsed(get_caller_name(), elapsed)
    # --- exit ----------------------------------------------------------------
    exit(0)
    # -------------------------------------------------------------------------

if __name__ == "__main__":
    main()

# --- eof ---------------------------------------------------------------------
