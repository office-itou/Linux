#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import inspect
import json
import os
import re
import sys

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
#from py_common.my_string            import eprint, count_width
#from py_common.my_message           import message_start, message_end, message_elapsed, message_debug, message_info, message_warn, message_alert
from py_common.my_message           import message_alert
from py_common.my_debug             import debugout
#from py_common.my_process           import run_subprocess
#from py_common.my_json              import load_json, save_json, get_text2json, put_json2text
#from py_common.my_markdown          import json2markdown, spc_encode4md, spc_decode4md
from py_common.my_markdown          import json2markdown

#from py_common.my_common_cfg        import InfoConfiguration
#from py_common.my_distribution_dat  import InfoDistribution
#from py_common.my_media_dat         import InfoMedia

#from py_common.my_infoweb           import Infoweb, get_webinfo
#from py_common.my_infofile          import Infofile, get_fileinfo
#from py_common.my_infodata          import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
#from dataclasses_json import dataclass_json
from dataclasses import dataclass, asdict

#@dataclass_json
@dataclass
class ConfigurationData:
    pass

class InfoConfiguration:
    def __init__(self):
        self.data: ConfigurationData = ConfigurationData()

    def load(self):
        self.data = load()

    def markdown(self, path: str, title: str):
        json2markdown(path, title, self.data)

    def conv2data(self, data: list) -> str:
        return conv2data(self.data, data)

    def conv2variable(self, data: list) -> str:
        return conv2variable(self.data, data)

    def dump(self):
        for line in self.data:
            text = f"{str(line):.{infosystem.data.columns}s}"
            print(f"{color.yellow}{text}{color.reset}")

# -----------------------------------------------------------------------------
# descript: load data in common.cfg
#   input :                       : unused
#   output:                       : unused
#   return: json.dumps(dict_conf) : output
#   global:                       : unused
# -----------------------------------------------------------------------------
def load() -> dict:
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    dirs_data = '/srv/user/share/conf/_data'    # data file                                 : '/srv/user/share/conf/_data'
    file_conf = 'common.cfg'                    # common configuration file
    path_conf = ''                              # common configuration file
    for dirs in ['.', dirs_data]:
        path = os.path.join(dirs, file_conf)
        if not os.path.exists(path):
            continue
        path_conf = path
        break
    if not path_conf:
        message_alert(f"file not found: {file_conf}")
        sys.exit(1)
    # --- get setting items ---------------------------------------------------
    list_conf = list()
    dict_conf = dict()
    for line in open(path_conf, 'r', encoding='utf-8'):
        match = re.search('^[A-Z]', line)      # get parameter row
        if not match:
            continue
        comnt = line
        line  = re.sub(r"[\n|\r\n]$", '', line)     # remove lf or crlf
        line  = re.sub('#.*$'       , '', line)     # remove comment
        line  = re.sub(r"[ \t]+$"   , '', line)     # remove trailing whitespace
        comnt = re.sub('^' + line   , '', comnt)    # get the comment
        key   = re.sub('=.*$'       , '', line)     # get the key
        value = re.sub(key + '='    , '', line)     # get the value
        value = re.sub(r"^\""       , '', value)    # remove the first double quotation mark
        value = re.sub(r"\"$"       , '', value)    # remove the last double quotation mark
        dict_conf[key] = value
        list_conf.append({'key': key, 'value': value, 'comment': comnt.strip()})

    # --- convert setting items -----------------------------------------------
    for i, line in enumerate(list_conf):
        (k1, key), (k2, value), (k3, comnt) = line.items()
        while True:
            match = re.search(':_[a-zA-Z0-9]+_[a-zA-Z0-9]+_:', value)
            if not match:
                break
            match_text  = match.group()
            match_key   = re.sub('^:_', '', match_text)
            match_key   = re.sub('_:$', '', match_key)
            match_value = dict_conf[match_key]
            value = re.sub(':_' + match_key + '_:', match_value, value)
        dict_conf[key] = value
        list_conf[i] = {'key': key, 'value': value, 'comment': comnt}
    # --- return --------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return list_conf

# -----------------------------------------------------------------------------
# descript: convert to data format
#   input : data_conf             : input
#   input : data_orig             : input
#   output:                       : unused
#   return: json.dumps(data_conv) : output
#   global:                       : unused
# -----------------------------------------------------------------------------
def conv2data(data_conf: str, data_orig: dict) -> list:
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    dict_conf = dict()
    for i, line in enumerate(data_conf):
        (k1, key), (k2, value), (k3, comnt) = line.items()
        dict_conf[key] = value
    data_conv = list()
    for line in [asdict(d) for d in data_orig]:
        for key, value in line.items():
            while True:
                match = re.search(':_[a-zA-Z0-9]+_[a-zA-Z0-9]+_:', value)
                if not match:
                    break
                match_text = match.group()
                match_key  = re.sub('^:_', '', match_text)
                match_key  = re.sub('_:$', '', match_key)
                value      = re.sub(':_' + match_key + '_:', dict_conf[match_key], value)
            line[key] = value
        data_conv.append(line)
    # --- return --------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return json.dumps(data_conv, ensure_ascii=False)

# -----------------------------------------------------------------------------
# descript: convert to variable format
#   input : data_conf             : input
#   input : data_orig             : input
#   output:                       : unused
#   return: json.dumps(data_conv) : output
#   global:                       : unused
# -----------------------------------------------------------------------------
def conv2variable(data_conf: str, data_orig: dict) -> list:
    function_name = inspect.currentframe().f_code.co_name
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    dict_conf = dict()
    for i, line in enumerate(data_conf):
        (k1, key), (k2, value), (k3, comnt) = line.items()
        dict_conf[key] = value
    data_conv = list()
    for line in [asdict(d) for d in data_orig]:
        for key, value in line.items():
            for conf_key in reversed(dict_conf):
                match = re.search('DIRS_[a-zA-Z0-9]+', conf_key)
                if not match:
                    continue
                match = re.search('^/', dict_conf[conf_key])
                if not match:
                    continue
                value = re.sub(dict_conf[conf_key], ':_' + conf_key + '_:', value)
            line[key] = value
        data_conv.append(line)
    # --- return --------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return json.dumps(data_conv, ensure_ascii=False)

# --- eof ---------------------------------------------------------------------
