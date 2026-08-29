#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import inspect
import json
import pandas as pd
import re
import pprint

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
from py_common.my_colors            import color
#from py_common.my_string            import eprint, count_width
#from py_common.my_message           import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert
from py_common.my_debug             import debugout
#from py_common.my_process           import run_subprocess
#from py_common.my_json              import load_json, save_json, get_text2json, put_json2text
#from py_common.my_markdown          import json2markdown, spc_encode4md, spc_decode4md

#from py_common.my_common_cfg        import InfoConfiguration, conv2data, conv2variable
#from py_common.my_distribution_dat  import InfoDistribution
#from py_common.my_media_dat         import InfoMedia, conv2data, conv2variable

#from py_common.my_infoweb           import Infoweb, get_webinfo
#from py_common.my_infofile          import Infofile, get_fileinfo
#from py_common.my_infodata          import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
# descript: Encoding whitespace characters and html on a per-list basis
#   input : data             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_encode4md(data: list) -> list:
    conv = data.copy()
    for line in conv:
        for key, value in line.items():
            if not isinstance(value, str): break
            value = re.sub('^`(http[|s]:[^ ]+)`', '\1', value)
            value = re.sub(' ', '%20', value)
            line[key] = value
            print(line[key])
#           line[key] = urllib.parse.unquote(value)
    return conv

# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters and html on a per-list basis (sub)
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_decode4md_sub(data: list) -> list:
    conv = data.copy()
    for key, value in conv.items():
        value = conv[key]
        if not isinstance(value, str): break
        value = re.sub('^(http[|s]:[^ ]+)', r"`\1`", value)
        value = re.sub('%20', ' ', value)
        value = re.sub(':_', r":\\_", value)
        value = re.sub('_:', r"\\_:", value)
        conv[key] = value
    return conv

# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters and html on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_decode4md(data: list) -> list:
    url_pattern = re.compile(
        r'^(?:http[s]?://)?'
        r'(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+'
        r'[a-zA-Z]{2,}'
        r'(?:/[a-zA-Z0-9._~:/?#\[\]@!$&\'()*+,;=%-]*)?$'
    )
    conv = list()
    for line in data.copy():
        for key, value in line.items():
            if isinstance(value, str):
                match = url_pattern.search(value)
                if match:
                    for group in match.group(0).splitlines():
                        value = re.sub(f"({group})", r"`\1`", value)
                value = re.sub('^(http[|s]:[^ ]+)', r"`\1`", value)
                value = re.sub('%20', ' ', value)
#               value = re.sub(' ', '&nbsp;', value)
                value = re.sub(':_', r":\\_", value)
                value = re.sub('_:', r"\\_:", value)
                match = re.match('^#', value)
                if match:
                    value = f"`{value}`"
            line[key] = value
        conv.append(line)
    return conv

def spc_decode4md2(data: list) -> list:
    conv = list()
    if isinstance(data, dict):
        print("dict")
        conv.append(spc_decode4md_sub(data))
    elif isinstance(data, list):
        print("list")
        for line in data:
            conv.append(spc_decode4md_sub(line))
    return conv

# -----------------------------------------------------------------------------
# descript: markdown output of json data
#   input : path             : unused
#   input : title            : unused
#   input : data             : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def json2markdown(path: str, title: str, data: list):
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, 'Start', color.yellow, f"({path})")
    # -------------------------------------------------------------------------
    text      = spc_decode4md(data.copy())
    colssize  = []
    spc = ' ' * 2
    header    = ''
    align     = ''
    df = pd.DataFrame(text)
    for name in df.columns.to_list():
        values = df[name].values
        max_val = max(values, key=len)
        colsize = len(max_val) if len(max_val) >= len(name) else len(name)
        colssize.append(colsize)
        header += f"|{name:^{colsize}}"
        align += '|:' + '-' * (colsize - 1)
    header += '|'
    align += '|'
    md_text = f"# Data table\n\n* {title}\n\n{spc}{header}\n{spc}{align}\n"
    for index, row in df.iterrows():
        md_line = ''
        for i, name in enumerate(df.columns.to_list()):
            colsize = colssize[i]
            md_line += f"|{row[name]:<{colsize}}"
        md_text += f"{spc}{md_line}|\n"
    with open(path, 'w', encoding='utf-8') as f:
        f.write(md_text)
     # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, f"({path})")

# --- eof ---------------------------------------------------------------------
