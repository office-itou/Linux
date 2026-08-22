#!/usr/bin/env python3
# encoding: utf-8

topdir = "/home/master/linux/script/py_custom_cmd/src"
#import os
import sys
sys.path.append(topdir) # (os.getcwd())

import json
import subprocess

from py_common.colors import color
from py_common.web import Info, get_fileinfo, get_webinfo

path = "/home/master/linux/script/py_custom_cmd/src/py_prototype/list.json"
with open(path, "r", encoding="utf-8") as f:
    urls = json.load(f)

def get_volume_uuid(device):
    res = subprocess.run(['blkid', '-s', 'UUID', '-o', 'value', device], capture_output=True, text=True)
    return res.stdout.strip()

def get_volume_label(device):
    res = subprocess.run(['blkid', '-s', 'LABEL', '-o', 'value', device], capture_output=True, text=True)
    return res.stdout.strip()

info = Info()
for url in urls:
    if url["allow"] == "true":
        info.file = get_fileinfo(url["path"])
        if True:
            print(f"{color.yellow}# --------------------------------------------------------------------------- #{color.reset}")
            print(f"info.file.path   : [{info.file.path}]")
            print(f"info.file.tmstamp: [{info.file.tmstamp}]")
            print(f"info.file.size   : [{info.file.size}]")
            print(f"info.file.volume : [{info.file.volume}]")
            print(f"{color.yellow}# --------------------------------------------------------------------------- #{color.reset}")
