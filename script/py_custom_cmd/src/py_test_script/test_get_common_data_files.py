#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import os
import inspect
import time
import argparse

from collections.abc import Iterable
from dataclasses import dataclass, fields
from datetime import datetime
from pathlib import Path
import pandas as pd                     # sudo apt-get install python3-pandas

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
#from pathlib import Path
#import sys
#topdir = Path(Path.home(), '/linux/script/py_custom_cmd/src')
#sys.path.append(topdir)


#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------

# --- my library --------------------------------------------------------------
topdir = "/home/master/linux/script/py_custom_cmd/src"
import sys
sys.path.append(topdir)

from py_common.my_config            import infosystem
from py_common.my_colors            import color
#from py_common.my_string            import eprint, count_width
from py_common.my_message           import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert
from py_common.my_debug             import debugout
#from py_common.my_process           import run_subprocess
#from py_common.my_json              import load_json, save_json, get_text2json, put_json2text
#from py_common.my_markdown          import json2markdown, spc_encode4md, spc_decode4md

from py_common.my_common_cfg        import InfoConfiguration
from py_common.my_distribution_dat  import InfoDistribution
from py_common.my_media_dat         import InfoMedia

#from py_common.my_infoweb           import Infoweb, get_webinfo
#from py_common.my_infofile          import Infofile, get_fileinfo
#from py_common.my_infodata          import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
# descript: args parser
#   input :                  : unused
#   output:                  : unused
#   return: parse_args       : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def argsparser():
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug'   , help='Debug mode'                 , action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    try:
        args = parser.parse_args()
    except:
        pass
    else:
        infosystem.data.args = args
    if infosystem.data.args:
        infosystem.data.debug    = infosystem.data.args.debug
        infosystem.data.debugout = infosystem.data.args.debugout if infosystem.data.debug != True else True

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
    if infosystem.data.debug == True:
        message_info(function_name, 'Debug mode on')
    if infosystem.data.debugout == True:
        message_info(function_name, 'Debugout mode on')
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
    mkdw_conf = './Readme_configuration.md'
    mkdw_dist = './Readme_distribution.md'
    mkdw_mdia = './Readme_media.md'
    mkdw_mda2 = './Readme_media(data).md'
    mkdw_mda3 = './Readme_media(revert).md'
    titl_conf = 'common configuration file (common.cfg)'
    titl_dist = 'distribution data file (distribution.dat)'
    titl_mdia = 'media data file (media.dat)'
    titl_mda2 = 'media data file (data)'
    titl_mda3 = 'media data file (revert)'

    conf = InfoConfiguration()
    conf.load()
#   conf.dump()
    conf.markdown(mkdw_conf, titl_conf)

    dist = InfoDistribution()
    dist.load(path_dist)
#   dist.dump()
    dist.markdown(mkdw_dist, titl_dist)

    mdia = InfoMedia()
    mdia.load(path_mdia)
#   mdia.dump()
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
#   global:                  : unused
# -----------------------------------------------------------------------------
def main():
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        print(f"{color.reset}{color.br_green}{infosystem.data.program_name}:\n{color.br_yellow} You have standard user privileges. {color.underline}Please run this with sudo.{color.reset}")
        exit(1)
    # --- system parameters ---------------------------------------------------
    function_name = inspect.currentframe().f_code.co_name
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- global variable -----------------------------------------------------
#   global debug_flag
#   global debugout_flag
#   global program_name
#   global col_size
#   global row_size
    # --- startup process -----------------------------------------------------
    message_start(function_name)
    # --- processing block ----------------------------------------------------
    argsparser()
    if infosystem.data.args:
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
