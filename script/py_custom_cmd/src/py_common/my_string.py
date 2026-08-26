#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
#from pathlib import Path
#import argparse
#import inspect
#from datetime import datetime
#import time
#import shutil
#import os
import re
import unicodedata

# --- my library --------------------------------------------------------------
#topdir = "/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

#import py_common.my_config as my_config
#from py_common.my_config import debug_flag, debugout_flag, program_name, col_size, row_size
#from py_common.my_colors import color
#from py_common.my_string import count_width
#from py_common.my_string import eprint
#from py_common.my_debug  import debugout
#from py_common.my_message import message_debug

#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

#from py_common.my_infoweb  import Infoweb, get_webinfo
#from py_common.my_infofile import Infofile, get_fileinfo
#from py_common.my_infodata import Infodata, debug_info, get_infodata

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
    return count_full_width(text) + count_half_width(text)

# -----------------------------------------------------------------------------
# descript: character count for full-width and half-width characters on the screen
#   input : char             : input
#   output:                  : unused
#   return: length           : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def get_char_width(char: str):
  return 2 if unicodedata.east_asian_width(char) in ("W", "F", "A") else 1

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
    current_line = ""
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
#   escape_cd = r"\x1b"
    ptn_escpe = r"\x1b\[[0-9;]*[mG]"
    txt_split = text
    txt_plain = re.sub(ptn_escpe, "", text)
    len_split = count_half_width(txt_split) + count_full_width(txt_split) * 2
    len_plain = count_half_width(txt_plain) + count_full_width(txt_plain) * 2
    len_escpe = len_split - len_plain
    if len(txt_plain) > max_width:      # txt_plain text length > console width
        while True:
            txt_split = split_by_width(txt_split, max_width + len_escpe)
            txt_plain = re.sub(ptn_escpe, "", txt_split)
            len_split = count_half_width(txt_split) + count_full_width(txt_split) * 2
            len_plain = count_half_width(txt_plain) + count_full_width(txt_plain) * 2
            len_escpe = len_split - len_plain
            if len_plain <= max_width: break

    print(f"{txt_split}")

# --- eof ---------------------------------------------------------------------
