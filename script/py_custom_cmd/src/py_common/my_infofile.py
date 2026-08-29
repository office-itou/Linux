#!/usr/bin/env python3
# encoding: utf-8

# -----------------------------------------------------------------------------
from datetime import datetime, timezone
from pathlib import Path
import inspect
import magic                            # sudo apt-get install python3-magic

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
from py_common.my_debug             import debugout
from py_common.my_process           import run_subprocess
#from py_common.my_json              import load_json, save_json, get_text2json, put_json2text
#from py_common.my_markdown          import json2markdown, spc_encode4md, spc_decode4md

#from py_common.my_common_cfg        import InfoConfiguration, conv2data, conv2variable
#from py_common.my_distribution_dat  import InfoDistribution
#from py_common.my_media_dat         import InfoMedia, conv2data, conv2variable

#from py_common.my_infoweb           import Infoweb, get_webinfo
from py_common.my_infofile          import Infofile, get_fileinfo
#from py_common.my_infodata          import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
import dataclasses
@dataclasses.dataclass
class Infofile:
    path:     str = ""
    tmstamp:  str = ""
    size:     int = 0
    volume:   str = ""

# -----------------------------------------------------------------------------
def get_volume_uuid(device):
    parameter = ['blkid', '-s', 'UUID', '-o', 'value', device]
    return run_subprocess(parameter)

def get_volume_label(device):
    parameter = ['blkid', '-s', 'LABEL', '-o', 'value', device]
    return run_subprocess(parameter)

# -----------------------------------------------------------------------------
def get_fileinfo(target_path):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", f"({target_path})")
    # -------------------------------------------------------------------------
    info = Infofile()
    path = Path(target_path)
    info.path = str(path.resolve())
    if path.exists():
        kind = magic.from_file(info.path, mime=True)
        if kind:
            if kind == "application/x-iso9660-image":
                info.volume  = get_volume_label(info.path)
        info.tmstamp = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat()
        info.size    = path.stat().st_size
    else:
        debugout(debugout_flag, color.bg_red, func_name, "Error", f"File not exist: {target_path}")
    # -------------------------------------------------------------------------
    debugout(debugout_flag, color.yellow, func_name, "Complete", f"({target_path})")
#    print(f"{color.white}{func_name}({target_path}) END{color.reset}")
    return info
