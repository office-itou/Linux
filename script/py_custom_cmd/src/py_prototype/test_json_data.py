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
from dataclasses import dataclass, asdict

# --- my library --------------------------------------------------------------
topdir = '/home/master/linux/script/py_custom_cmd/src'
import sys
sys.path.append(topdir)

import py_common.my_config as my_config
#from py_common.my_config import debug_flag, debugout_flag, program_name, col_size, row_size
from py_common.my_colors  import color
#from py_common.my_string import count_width
from py_common.my_string  import eprint
from py_common.my_debug   import debugout
from py_common.my_message import message_debug

from py_common.my_json    import load_json, save_json, get_text2json, put_json2text
#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

#from py_common.my_infoweb  import Infoweb, get_webinfo
#from py_common.my_infofile import Infofile, get_fileinfo
#from py_common.my_infodata import Infodata, debug_info, get_infodata

# --- distribution.dat --------------------------------------------------------
path = '/srv/user/share/conf/_data/distribution.dat'
dist = get_text2json(path)

path = '/srv/user/share/conf/_data/test_distribution.dat'
format = '{version:<23} {name:<23} {version_id:<23} {code_name:<39} {life:<15} {release:<15} {support:<15} {long_term:<15} {rhel:<15} {kerne:<27} {note:<27} {wallpaper:<87} {create_flag:<11} {sort_flag:<11} '
put_json2text(path, dist, format)

# --- media.dat ---------------------------------------------------------------
path = '/srv/user/share/conf/_data/media.dat'
mdia = get_text2json(path)

path = '/srv/user/share/conf/_data/test_media.dat'
format = '{type:<11} {entry_flag:<11} {entry_name:<39} {entry_disp:<39} {version:<23} {latest:<23} {release:<15} {support:<15} {web_regexp:<143} {web_path:<143} {web_tstamp:<47} {web_size:<15} {web_check:<47} {web_status:<15} {iso_path:<87} {iso_tstamp:<47} {iso_size:<15} {iso_volume:<43} {rmk_path:<87} {rmk_tstamp:<47} {rmk_size:<15} {rmk_volume:<43} {ldr_initrd:<87} {ldr_kernel:<87} {cfg_path:<87} {cfg_tstamp:<47} {lnk_path:<87} {options:<59} {create_flag:<11} '
put_json2text(path, mdia, format)
