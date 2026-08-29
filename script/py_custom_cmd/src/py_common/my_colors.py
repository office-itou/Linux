#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
from dataclasses import dataclass

#import os
#import inspect
#import time
#import argparse

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


#from py_common.my_config            import infosystem
#from py_common.my_colors            import color
#from py_common.my_string            import eprint, count_width
#from py_common.my_message           import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert
#from py_common.my_debug             import debugout
#from py_common.my_process           import run_subprocess
#from py_common.my_json              import load_json, save_json, get_text2json, put_json2text
#from py_common.my_markdown          import json2markdown, spc_encode4md, spc_decode4md

#from py_common.my_common_cfg        import InfoConfiguration, conv2data, conv2variable
#from py_common.my_distribution_dat  import InfoDistribution
#from py_common.my_media_dat         import InfoMedia, conv2data, conv2variable

#from py_common.my_infoweb           import Infoweb, get_webinfo
#from py_common.my_infofile          import Infofile, get_fileinfo
#from py_common.my_infodata          import Infodata, debug_info, get_infodata

# --- escape code -------------------------------------------------------------
@dataclass
class code:
    escape          : str = f"\x1b"

# --- color code --------------------------------------------------------------
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
@dataclass
class color:
    reset           : str = f"{code.escape}[0m"             # reset all attributes
    bold            : str = f"{code.escape}[1m"             #
    faint           : str = f"{code.escape}[2m"             #
    italic          : str = f"{code.escape}[3m"             #
    underline       : str = f"{code.escape}[4m"             # set underline
    blink           : str = f"{code.escape}[5m"             #
    fast_blink      : str = f"{code.escape}[6m"             #
    reverse         : str = f"{code.escape}[7m"             # set reverse display
    conceal         : str = f"{code.escape}[8m"             #
    strike          : str = f"{code.escape}[9m"             #
    gothic          : str = f"{code.escape}[20m"            #
    double_underline: str = f"{code.escape}[21m"            #
    normal          : str = f"{code.escape}[22m"            #
    no_italic       : str = f"{code.escape}[23m"            #
    no_underline    : str = f"{code.escape}[24m"            # reset underline
    no_blink        : str = f"{code.escape}[25m"            #
    no_reverse      : str = f"{code.escape}[27m"            # reset reverse display
    no_conceal      : str = f"{code.escape}[28m"            #
    no_strike       : str = f"{code.escape}[29m"            #
    black           : str = f"{code.escape}[30m"            # text dark black
    red             : str = f"{code.escape}[31m"            # text dark red
    green           : str = f"{code.escape}[32m"            # text dark green
    yellow          : str = f"{code.escape}[33m"            # text dark yellow
    blue            : str = f"{code.escape}[34m"            # text dark blue
    magenta         : str = f"{code.escape}[35m"            # text dark purple
    cyan            : str = f"{code.escape}[36m"            # text dark light blue
    white           : str = f"{code.escape}[37m"            # text dark white
    default         : str = f"{code.escape}[39m"            #
    bg_black        : str = f"{code.escape}[40m"            # text reverse black
    bg_red          : str = f"{code.escape}[41m"            # text reverse red
    bg_green        : str = f"{code.escape}[42m"            # text reverse green
    bg_yellow       : str = f"{code.escape}[43m"            # text reverse yellow
    bg_blue         : str = f"{code.escape}[44m"            # text reverse blue
    bg_magenta      : str = f"{code.escape}[45m"            # text reverse purple
    bg_cyan         : str = f"{code.escape}[46m"            # text reverse light blue
    bg_white        : str = f"{code.escape}[47m"            # text reverse white
    bg_default      : str = f"{code.escape}[49m"            #
    br_black        : str = f"{code.escape}[90m"            # text black
    br_red          : str = f"{code.escape}[91m"            # text red
    br_green        : str = f"{code.escape}[92m"            # text green
    br_yellow       : str = f"{code.escape}[93m"            # text yellow
    br_blue         : str = f"{code.escape}[94m"            # text blue
    br_magenta      : str = f"{code.escape}[95m"            # text purple
    br_cyan         : str = f"{code.escape}[96m"            # text light blue
    br_white        : str = f"{code.escape}[97m"            # text white
    br_default      : str = f"{code.escape}[99m"            #

# --- eof ---------------------------------------------------------------------
