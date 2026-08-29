#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
from datetime import datetime
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
#from py_common.my_colors            import color
#from py_common.my_string            import eprint, count_width
#from py_common.my_message           import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert
from py_common.my_message           import message_debug
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
# descript: debug output for scale
#   input : size             : input
#   output: stdout           : output
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def debugout_scale(size):
        gap = '-' * size
        scale_u = ''
        scale_m = ''
        scale_l = ''
        for i in range(1, size + 1):
            u, m = divmod(i, 100)
            m, l = divmod(i, 10)
            scale_u += str(u)[-1] if l == 0 else ' '
            scale_m += str(m)[-1] if l == 0 else ' '
            scale_l += str(l)
#       print(gap)
#       print(scale_u)
        print(scale_m)
        print(scale_l)

# -----------------------------------------------------------------------------
# descript:  debug output
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: debugout_flag    : read
# -----------------------------------------------------------------------------
def debugout(function_name, mode, message_color, message):
    if infosystem.data.debugout == False: return
    message_debug(function_name, mode, message_color, message)

# --- eof ---------------------------------------------------------------------
