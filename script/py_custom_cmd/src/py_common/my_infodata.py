#!/usr/bin/env python3
# encoding: utf-8

# -----------------------------------------------------------------------------
from pathlib import Path
import asyncio
import inspect
import re

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

from py_common.my_infoweb           import Infoweb, get_webinfo
from py_common.my_infofile          import Infofile, get_fileinfo
from py_common.my_infodata          import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
class Infodata:
    web:  Infoweb
    file: Infofile

# -----------------------------------------------------------------------------
def debug_info(infodata):
    print("# --------------------------------------------------------------------------- #")
    if hasattr(infodata, "web"):
        if hasattr(infodata.web, "regexp"  ): print(f"web.regexp  : [{infodata.web.regexp}]")
        if hasattr(infodata.web, "url"     ): print(f"web.urlh    : [{infodata.web.url}]")
        if hasattr(infodata.web, "tmstamp" ): print(f"web.tmstamp : [{infodata.web.tmstamp}]")
        if hasattr(infodata.web, "size"    ): print(f"web.size    : [{infodata.web.size}]")
        if hasattr(infodata.web, "check"   ): print(f"web.check   : [{infodata.web.check}]")
        if hasattr(infodata.web, "status"  ): print(f"web.status  : [{infodata.web.status}]")
        if hasattr(infodata.web, "reason"  ): print(f"web.reason  : [{infodata.web.reason}]")
        if hasattr(infodata.web, "contents"): print(f"web.contents: [{infodata.web.contents}]")
        if hasattr(infodata.web, "output"  ): print(f"web.output  : [{infodata.web.output}]")
    if hasattr(infodata, "file"):
        if hasattr(infodata.file, "path"   ): print(f"file.path   : [{infodata.file.path}]")
        if hasattr(infodata.file, "tmstamp"): print(f"file.tmstamp: [{infodata.file.tmstamp}]")
        if hasattr(infodata.file, "size"   ): print(f"file.size   : [{infodata.file.size}]")
        if hasattr(infodata.file, "volume" ): print(f"file.volume : [{infodata.file.volume}]")
    print("# --------------------------------------------------------------------------- #")

# -----------------------------------------------------------------------------
async def get_infodata(session, list):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", "")
    # -------------------------------------------------------------------------
    tasks = []
    for line in list:
        if line["allow"].lower() == "true":
            tasks.append(get_webinfo(session, line["url"], line["path"]))
    infodatas_web = await asyncio.gather(*tasks)
    infodatas = []
    for infodata_web in infodatas_web:
        infodata = infodata_web
        infodata.web = infodata_web
        # ---------------------------------------------------------------------
        if infodata.web.status == 200:
            target_url = infodata.web.url
            target_path = infodata.web.output
            dirname  = str(Path(target_path).parent)
            filename = Path(target_url).name
            if filename == "mini.iso":
                codename = target_url
                architecture = target_url
                match = re.search(r"^.+/dists/[a-zA-Z0-9_-]+/main/.+$", codename)
                if match:
                    codename = re.sub(r"^.+/dists/", "", codename)
                    codename = re.sub(r"/main/.+$", "", codename)
                    codename = re.sub(r"-.+$", "", codename)
                    architecture = re.sub(r"^.+/installer-", "", architecture)
                    architecture = re.sub(r"/current/.+$", "", architecture)
                else:
                    codename = "testing-daily"
                    architecture = re.sub(r"^.+/daily-images/", "", architecture)
                    architecture = re.sub(r"/daily/.+$", "", architecture)
                filename = f"mini-{codename}-{architecture}.iso"
            else:
                match = re.search(r"^debian-testing-[a-zA-Z0-9]+-[a-zA-Z0-9]+.iso$", filename)
                if match:
                    build        = target_url
                    edition      = target_url
                    architecture = target_url
                    media        = target_url
                    build = re.sub(r"^.+/cdimage/", "", build)
                    build = re.sub(r"-.+$", "", build)
                    edition = re.sub(r"/[^/]+/[^/]+/[^/]+$", "", edition)
                    edition = re.sub(r"^.+/", "", edition)
                    architecture = re.sub(r"/iso-cd/.+$", "", architecture)
                    architecture = re.sub(r"^.+/", "", architecture)
                    media = re.sub(r".+-" + architecture + "-", "", media)
                    media = re.sub(r"\.[^.]+$", "", media)
                    if build == "daily":
                        filename = f"debian-testing-{build}-{edition}-{architecture}-{media}.iso"
                    else:
                        filename = f"debian-testing-{build}-{architecture}-{media}.iso"
            target_path = str(Path(dirname, filename))
            infodata.file = get_fileinfo(target_path)
        # ---------------------------------------------------------------------
        infodatas.append(infodata)
    # -------------------------------------------------------------------------
#   debug_info(infodata)
#   await asyncio.sleep(1)
    debugout(debugout_flag, color.yellow, func_name, "Complete", "")
    return infodatas
