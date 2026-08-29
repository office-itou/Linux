#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import json

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
#from py_common.my_debug             import debugout
#from py_common.my_process           import run_subprocess
#from py_common.my_json              import load_json, save_json, get_text2json, put_json2text
#from py_common.my_markdown          import json2markdown, spc_encode4md, spc_decode4md
from py_common.my_markdown          import json2markdown

#from py_common.my_common_cfg        import InfoConfiguration, conv2data, conv2variable
from py_common.my_common_cfg        import InfoConfiguration
#from py_common.my_distribution_dat  import InfoDistribution
#from py_common.my_media_dat         import InfoMedia, conv2data, conv2variable

#from py_common.my_infoweb           import Infoweb, get_webinfo
#from py_common.my_infofile          import Infofile, get_fileinfo
#from py_common.my_infodata          import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
#from dataclasses_json import dataclass_json
from dataclasses import dataclass, asdict

#@dataclass_json
@dataclass
class MediaData:
    type:        str = ''
    entry_flag:  str = ''
    entry_name:  str = ''
    entry_disp:  str = ''
    version:     str = ''
    latest:      str = ''
    release:     str = ''
    support:     str = ''
    web_regexp:  str = ''
    web_path:    str = ''
    web_tstamp:  str = ''
    web_size:    str = ''
    web_check:   str = ''
    web_status:  str = ''
    iso_path:    str = ''
    iso_tstamp:  str = ''
    iso_size:    str = ''
    iso_volume:  str = ''
    rmk_path:    str = ''
    rmk_tstamp:  str = ''
    rmk_size:    str = ''
    rmk_volume:  str = ''
    ldr_initrd:  str = ''
    ldr_kernel:  str = ''
    cfg_path:    str = ''
    cfg_tstamp:  str = ''
    lnk_path:    str = ''
    options:     str = ''
    create_flag: str = ''

class InfoMedia:
    def __init__(self):
        self.data: MediaData = MediaData()

    def load(self, path: str):
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        self.data = [MediaData(**item) for item in data]

    def save(self, path: str):
        data = asdict(self.data)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)

    def from_json(self, data: list):
        self.data = [MediaData(**item) for item in data]

    def to_json(self) -> dict:
        return [asdict(data) for data in self.data]

    def markdown(self, path: str, title: str):
        json2markdown(path, title, self.to_json())

    def conv2data(self, info_conf :InfoConfiguration):
        conv = info_conf.conv2data(self.data)
        self.from_json(json.loads(conv))

    def conv2variable(self, info_conf :InfoConfiguration):
        conv = info_conf.conv2variable(self.data)
        self.from_json(json.loads(conv))

    def dump(self):
        for line in self.data:
            text = f"{str(line):.{infosystem.data.columns}s}"
            print(f"{color.yellow}{text}{color.reset}")
