#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import re
import unicodedata

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

# -----------------------------------------------------------------------------
# descript: character count for full-width characters only
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_full_width(text: str):
    return sum(1 for c in text if unicodedata.east_asian_width(c) in 'FWA')

# -----------------------------------------------------------------------------
# descript: character count for half-width characters only
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_half_width(text: str):
    return sum(1 for c in text if not unicodedata.east_asian_width(c) in 'FWA')

# -----------------------------------------------------------------------------
# descript: character count for full-width and half-width characters
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_width(text: str):
    return count_full_width(text) * 2 + count_half_width(text)

# -----------------------------------------------------------------------------
# descript: character count for full-width and half-width characters on the screen
#   input : char             : input
#   output:                  : unused
#   return: length           : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def get_char_width(char: str):
  return 2 if unicodedata.east_asian_width(char) in ('W', 'F', 'A') else 1

# -----------------------------------------------------------------------------
# descript: character splitting for full-width and half-width characters on the screen
#   input : text             : input
#   input : max_width        : input
#   output:                  : unused
#   return: lines[0]         : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def split_by_width(text: str, max_width = 80):
    lines = []
    current_line = ''
    current_width = 0

    for char in text:
        w = get_char_width(char)
        if current_width + w > max_width:
            lines.append(current_line)
            current_line = char
            current_width = w
        else:
            current_line += char
            current_width += w

    if current_line:
        lines.append(current_line)

    return lines[0]

# -----------------------------------------------------------------------------
# descript: Screen output with character splitting that supports escape characters and full-width/half-width characters.
#   input : text             : input
#   input : max_width        : input
#   output:                  : unused
#   return: lines[0]         : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def eprint(text: str, max_width = 80):
#   escape_cd = '\x1b'
    ptn_escpe = r"\x1b\[[0-9;]*[mG]"    # escape codes are also treated as strings.
    txt_split = text
    txt_plain = re.sub(ptn_escpe, '', text)
    len_split = count_width(txt_split)
    len_plain = count_width(txt_plain)
    len_escpe = len_split - len_plain
    if count_width(txt_plain) > max_width:  # txt_plain text length > console width
        while True:
            txt_split = split_by_width(txt_split, max_width + len_escpe)
            txt_plain = re.sub(ptn_escpe, '', txt_split)
            len_split = count_width(txt_split)
            len_plain = count_width(txt_plain)
            len_escpe = len_split - len_plain
            if len_plain <= max_width: break

    print(f"{color.reset}{txt_split}{color.reset}")

# -----------------------------------------------------------------------------
# descript: Encoding whitespace characters on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_encode(list):
    for line in list:
        for key, value in line.items():
            if not isinstance(value, str): continue
            line[key] = value.replace(' ', '%20')
#           line[key] = urllib.parse.quote(value, safe='')
    return list

# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_decode(list):
    for line in list:
        for key, value in line.items():
            if not isinstance(value, str): break
            line[key] = value.replace('%20', ' ')
#           line[key] = urllib.parse.unquote(value)
    return list

# -----------------------------------------------------------------------------
# descript: Omit the intermediate characters.
#   input : text             : input
#   input : max_len          : input
#   input : placeholder      : input
#   output:                  : unused
#   return: text             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def omit_middle(text, max_len=80, placeholder="..."):
    if count_width(text) <= max_len:
        return text
    n = (max_len - count_width(placeholder)) // 2
    front = text[:n + (max_len - count_width(placeholder)) % 2]
    back = text[-n:]
    return front + placeholder + back

# --- eof ---------------------------------------------------------------------
