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
from datetime import datetime
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
import shutil
#import subprocess
import sys
#import unicodedata
#import __main__
import glob

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
from py_common.my_argument              import Argument
from py_common.my_colors                import color
#from py_common.my_string               import eprint, count_width
from py_common.my_message               import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert, get_caller_name
from py_common.my_debug                 import debug_logger
#from py_common.my_process              import run_subprocess
from py_common.my_fileio                import get_text2list, put_list2text, conv_text2json, conv_json2text
from py_common.my_json                  import load_json, save_json
#from py_common.my_markdown             import list2markdown, spc_encode4md, spc_decode4md
from py_common.my_markdown              import list2markdown

from py_common.my_common_cfg            import InfoConfiguration
from py_common.my_distribution_dat      import InfoDistribution
from py_common.my_media_dat             import InfoMedia

from py_common.my_infoweb              import InfoWeb
from py_common.my_infofile             import InfoFile
#from py_common.my_infodata              import InfoData

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
    info_conf = InfoConfiguration()
    path_dist = info_conf.get('PATH_DIST')
    path_mdia = info_conf.get('PATH_MDIA')
    info_dist = InfoDistribution(path_dist + '.json')
    info_mdia = InfoMedia(path_mdia + '.json', info_conf)
    # -------------------------------------------------------------------------
    return info_conf, info_dist, info_mdia

# -----------------------------------------------------------------------------
@debug_logger
def generate_md(dirs: str, info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia):
    info_conf.markdown(Path(dirs) / 'Readme_Configuration.md', f"Configuration data({Path(info_conf.get('PATH_CONF')).name})")
    info_dist.markdown(Path(dirs) / 'Readme_Distribution.md' , f"Distribution data({Path(info_conf.get('PATH_DIST')).name})")
    info_mdia.markdown(Path(dirs) / 'Readme_Media.md'        , f"Media data({Path(info_conf.get('PATH_MDIA')).name})")

# -----------------------------------------------------------------------------
@debug_logger
def data_save(info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia):
    path_dist = info_conf.get('PATH_DIST')
    path_mdia = info_conf.get('PATH_MDIA')
    fmat_dist = r"{version:<23} {name:<23} {version_id:<23} {code_name:<39} {life:<15} {release:<15} {support:<15} {long_term:<15} {rhel:<15} {kerne:<27} {note:<27} {wallpaper:<87} {create_flag:<11} {sort_flag:<11} "
    fmat_mdia = r"{type:<11} {entry_flag:<11} {entry_name:<39} {entry_disp:<39} {version:<23} {latest:<23} {release:<15} {support:<15} {web_regexp:<143} {web_path:<143} {web_tstamp:<47} {web_size:<15} {web_check:<47} {web_status:<15} {iso_path:<87} {iso_tstamp:<47} {iso_size:<15} {iso_volume:<43} {rmk_path:<87} {rmk_tstamp:<47} {rmk_size:<15} {rmk_volume:<43} {ldr_initrd:<87} {ldr_kernel:<87} {cfg_path:<87} {cfg_tstamp:<47} {lnk_path:<87} {options:<59} {create_flag:<11} "
    # -------------------------------------------------------------------------
    paths_to_check = [p for p in [path_dist, f"{path_dist}.json", path_mdia, f"{path_mdia}.json"] if p and p != ".json"]
    for file_path_str in paths_to_check:
        file_path = Path(file_path_str)
        if file_path.exists() and file_path.is_file():
            # --- backup ------------------------------------------------------
            timestamp = datetime.now().strftime("%Y%m%d%H%M%S_%f")
            base_name = file_path.stem
            ext = file_path.suffix
            backup_path = file_path.with_name(f"{base_name}_{timestamp}{ext}")
            shutil.copy2(file_path, backup_path)
            # --- history -----------------------------------------------------
            search_pattern = str(file_path.with_name(f"{base_name}_*{ext}"))
            backups = glob.glob(search_pattern)
            backups = [b for b in backups if b != str(file_path)]
            backups.sort(key=os.path.getmtime)
            # --- cleanup -----------------------------------------------------
            while len(backups) > 3:
                oldest_backup = backups.pop(0)
                try:
                    os.remove(oldest_backup)
                except OSError as e:
                    message_alert(get_caller_name(), f"Backup deletion failed: {oldest_backup} ({e})")
    # -------------------------------------------------------------------------
    info_dist.save(f"{path_dist}.json")
    info_mdia.save(f"{path_mdia}.json", info_conf)
    # -------------------------------------------------------------------------
    put_list2text(path_dist, info_dist.data, fmat_dist)
    put_list2text(path_mdia, info_mdia.conv2variable(info_conf), fmat_mdia)

# -----------------------------------------------------------------------------
@debug_logger
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
@debug_logger
async def main():
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
    arg_manager.add('--t2j' , help='Text -> json convert', default=False, action='store_true')
    arg_manager.add('--j2t' , help='json -> Text convert', default=False, action='store_true')
    arg_manager.add('--md'  , help='json -> Markdown generate', default='', type=str)
    arg_manager.add('--info', help='Get ISO file information for web', default='', type=str)
    arg_manager.add('--save', help='Save data', default=False, action='store_true')
    args = arg_manager.parse()
    if args:
        info_conf, info_dist, info_mdia = initialize()
        if infosystem.args.t2j == True:    conv_text2json(info_conf, info_dist, info_mdia)
        if infosystem.args.j2t == True:    conv_json2text(info_conf, info_dist, info_mdia)
        if (target := infosystem.args.info):
            await get_web_file_info(info_conf, info_dist, info_mdia)
            generate_md('./', info_conf, info_dist, info_mdia)
            data_save(info_conf, info_dist, info_mdia)
        if (dirs := infosystem.args.md):   generate_md(dirs, info_conf, info_dist, info_mdia)
        if infosystem.args.save == True:   data_save(info_conf, info_dist, info_mdia)
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
    asyncio.run(main())

# --- eof ---------------------------------------------------------------------
