#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import os
import inspect
import time
import argparse

from aiohttp import ClientError, ClientTimeout
#from bs4 import BeautifulSoup
#from dataclasses import dataclass
#from dataclasses import dataclass, asdict
#from datetime import datetime
#from datetime import datetime, timedelta
#from datetime import datetime, timezone
#from natsort import natsort_keygen
from pathlib import Path
#from tqdm import tqdm
#from urllib.parse import urlparse
import aiohttp # sudo apt-get install python3-aiohttp
import asyncio
#import csv
#import dataclasses
import json
#import magic # sudo apt-get install python3-magic
#import pandas as pd
#import re
#import shutil
#import subprocess
import sys
#import unicodedata
#import __main__

# --- my library --------------------------------------------------------------
from pathlib        import Path
import os
import sys
execusr = os.getenv('USER')
execusr = os.getenv('SUDO_USER', execusr)
homedir = os.getenv('HOME')
homedir = os.getenv('SUDO_HOME', homedir)
libsdir = '/linux/script/py_custom_cmd/src/'
libsdir = Path(homedir) / libsdir.strip('/')
sys.path.append(str(libsdir))

from py_common.my_config                import infosystem
from py_common.my_colors                import color
#from py_common.my_string               import eprint, count_width
from py_common.my_message               import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert
from py_common.my_debug                 import debugout
#from py_common.my_process              import run_subprocess
from py_common.my_fileio                import get_text2list, put_list2text, conv_text2json, conv_json2text
from py_common.my_json                  import load_json, save_json
#from py_common.my_markdown             import json2markdown, spc_encode4md, spc_decode4md
from py_common.my_markdown              import json2markdown

from py_common.my_common_cfg            import InfoConfiguration
from py_common.my_distribution_dat      import InfoDistribution
from py_common.my_media_dat             import InfoMedia

from py_common.my_infoweb              import InfoWeb
from py_common.my_infofile             import InfoFile
#from py_common.my_infodata              import InfoData

# -----------------------------------------------------------------------------
# descript: args parser
#   input :                  : unused
#   output:                  : unused
#   return: parse_args       : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def argsparser():
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    parser = argparse.ArgumentParser(allow_abbrev=False)
    # -------------------------------------------------------------------------
    parser.add_argument('--debug'   , help='Debug mode'                 , default=False, action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', default=False, action='store_true')
    # -------------------------------------------------------------------------
    parser.add_argument('--t2j'     , help='Text -> json convert', default=False, action='store_true')
    parser.add_argument('--j2t'     , help='json -> Text convert', default=False, action='store_true')
    # -------------------------------------------------------------------------
    parser.add_argument('--md'      , help='json -> Markdown generate', default='', type=str)
    # -------------------------------------------------------------------------
    parser.add_argument('--info'    , help='Get ISO file information for web', default='', type=str)
    # -------------------------------------------------------------------------
    try:
        args = parser.parse_args()
    except:
        pass
    else:
        infosystem.data.args = args
    # -------------------------------------------------------------------------
    if infosystem.data.args:
        infosystem.data.debug    = infosystem.data.args.debug
        infosystem.data.debugout = infosystem.data.args.debugout if infosystem.data.debug != True else True
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# -----------------------------------------------------------------------------
# descript: initialize
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def initialize():
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    if infosystem.data.debug == True:
        message_info(function_name, 'Debug mode on')
    if infosystem.data.debugout == True:
        message_info(function_name, 'Debugout mode on')
    # -------------------------------------------------------------------------
    info_conf = InfoConfiguration()
    path_dist = info_conf.get('PATH_DIST')
    path_mdia = info_conf.get('PATH_MDIA')
    info_dist = InfoDistribution(path_dist + '.json')
    info_mdia = InfoMedia(path_mdia + '.json', info_conf)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return info_conf, info_dist, info_mdia

# -----------------------------------------------------------------------------
def generate_md(dirs: str, info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia):
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    info_conf.markdown(Path(dirs) / 'Readme_Configuration.md', f"Configuration data({Path(info_conf.get('PATH_CONF')).name})")
    info_dist.markdown(Path(dirs) / 'Readme_Distribution.md' , f"Distribution data({Path(info_conf.get('PATH_DIST')).name})")
    info_mdia.markdown(Path(dirs) / 'Readme_Media.md'        , f"Media data({Path(info_conf.get('PATH_MDIA')).name})")
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# -----------------------------------------------------------------------------
async def get_web_file_info(info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia):
    info_web  = InfoWeb()
    info_file = InfoFile()
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(timeout=timeout, raise_for_status=False) as session:
        count = 0
        for tget_mdia in info_mdia.data:
#            if tget_mdia.entry_flag != 'o' \
            if tget_mdia.web_regexp == '-' \
            or tget_mdia.iso_path   == '-':
                continue
            await info_web.get_info(session, tget_mdia.web_regexp, tget_mdia.iso_path)
            tget_mdia.web_path   = info_web.data.url
            tget_mdia.web_tstamp = info_web.data.tmstamp
            tget_mdia.web_size   = info_web.data.size
            tget_mdia.web_check  = info_web.data.check
            tget_mdia.web_status = info_web.data.status
            if info_web.data.status != 200:
                continue
            if Path(info_web.data.output).exists():
                info_file.get_info(info_web.data.output)
                tget_mdia.iso_path   = info_file.data.path
                tget_mdia.iso_tstamp = info_file.data.tmstamp
                tget_mdia.iso_size   = info_file.data.size
                tget_mdia.iso_volume = info_file.data.volume
            else:
                tget_mdia.iso_path   = info_web.data.output
                tget_mdia.iso_tstamp = '-'
                tget_mdia.iso_size   = '-'
                tget_mdia.iso_volume = '-'
    return info_mdia.data

# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
async def main():
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        print(f"{color.reset}{color.br_green}{infosystem.data.program_name}:\n{color.br_yellow} You have standard user privileges. {color.underline}Please run this with sudo.{color.reset}")
        exit(1)
    # --- system parameters ---------------------------------------------------
    function_name = inspect.currentframe().f_code.co_name
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- global variable -----------------------------------------------------
    # --- startup process -----------------------------------------------------
    message_start(function_name)
    # --- processing block ----------------------------------------------------
    argsparser()
    if infosystem.data.args:
        info_conf, info_dist, info_mdia = initialize()
        if infosystem.data.args.t2j == True:
            conv_text2json(info_conf, info_dist, info_mdia)
        if infosystem.data.args.j2t == True:
            conv_json2text(info_conf, info_dist, info_mdia)
        if (dirs := infosystem.data.args.info):
            await get_web_file_info(info_conf, info_dist, info_mdia)
        if (dirs := infosystem.data.args.md):
            generate_md(dirs, info_conf, info_dist, info_mdia)
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
    asyncio.run(main())

# --- eof ---------------------------------------------------------------------
