#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
from datetime import datetime, timedelta
from pathlib import Path

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


from py_common.my_config            import infosystem
from py_common.my_colors            import color
from py_common.my_string            import eprint, count_width, omit_middle
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

#colsize_func = 30 if infosystem.data.columns < 80 else 40 if infosystem.data.columns < 100 else 50
colsize_func = infosystem.data.columns // 2 if infosystem.data.columns < 100 else 50
colsize_mode = 10

# -----------------------------------------------------------------------------
# descript: message output for datetime
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : date_time        : input
#   output: stdout           : output
#   return:                  : unused
#   global: col_size         : read
# -----------------------------------------------------------------------------
def message_date(function_name, mode, message_color, date_time):
#    message = f"{function_name:<{colsize_func}}:{mode:^{colsize_mode}}:--- {date_time} "
#    message += '-' * (infosystem.data.columns - count_width(message))
#    eprint(f"{color.reset}{message_color}{message}{color.reset}", infosystem.data.columns)
    message = f"--- {date_time} " + '-' * (infosystem.data.columns - (colsize_func + colsize_mode + 2))
    eprint(f"{color.reset}{message_color}{function_name:<{colsize_func}}:{mode:^{colsize_mode}}:{message}{color.reset}", infosystem.data.columns)

# -----------------------------------------------------------------------------
# descript: message output for startup
#   input : function_name    : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_start(function_name):
    date_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    message_date(text_prog, 'Start', color.green, date_time)

# -----------------------------------------------------------------------------
# descript: message output for termination
#   input : function_name    : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_end(function_name):
    date_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    message_date(text_prog, 'Complete', color.green, date_time)

# -----------------------------------------------------------------------------
# descript: message output for elapsed time
#   input : function_name    : input
#   input : elapsed          : input
#   output: stdout           : output
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def message_elapsed(function_name, elapsed):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    text_time = timedelta(seconds=elapsed)
    eprint(f"{color.reset}{color.yellow}{text_prog:<{colsize_func}}:{'Elapsed':^{colsize_mode}}:{text_time}{color.reset}", infosystem.data.columns)

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_debug(function_name, mode, message_color, message):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    eprint(f"{color.reset}{message_color}{text_prog:<{colsize_func}}:{mode:^{colsize_mode}}:{message}{color.reset}", infosystem.data.columns)

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_info(function_name, message):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    print(f"{color.reset}{color.br_green}{text_prog:<{colsize_func}}:{'info':^{colsize_mode}}:{message}{color.reset}")

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_warn(function_name, message):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    print(f"{color.reset}{color.br_yellow}{text_prog:<{colsize_func}}:{'warn':^{colsize_mode}}:{message}{color.reset}")

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_alert(function_name, message):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    print(f"{color.reset}{color.br_red}{text_prog:<{colsize_func}}:{'alert':^{colsize_mode}}:{message}{color.reset}")

# --- eof ---------------------------------------------------------------------
