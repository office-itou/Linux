#!/usr/bin/env python3
# encoding: utf-8

## -----------------------------------------------------------------------------
import inspect

import re
import json
import csv

from . import config
from .colors import color
from .debug  import debugout
from .common_cfg import conv2data, conv2variable

# media data file
class Media_dat():
    def __init__(self):
        self.data = dict()
    def debug(self):
        debug(self.data)
    def load(self, conf, dist):
        data = get(conf, dist)
        data = decode(data)
        self.data = conv2data(conf, data)
    def save(self, conf):
        data = conv2variable(conf, self.data)
        data = encode(data)
        put(conf, data)
    def get(self, key):
        return self.data.get(key, "")
    def set(self, key, value):
        self.data[key] = value
    def exports(self):
        return self.data
    def imports(self, data):
        self.data = json.dump(data, ensure_ascii=False, indent=4)

def debug(list):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    print(f"{color.br_green}=== debug out: {__name__} : start ==={color.reset}")
    for line in list:
        print(f"{color.yellow}    list_dist='{line}'{color.reset}")
    print(f"{color.br_green}=== debug out: {__name__} : complete ==={color.reset}")
    debugout(config.debugout, color.yellow, func_name, "Complete", "")

def get(conf, list_dist):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    path_mdia = conf["PATH_MDIA"]       # media data file           : '/srv/user/share/conf/_data/media.dat'
    list_mdia = []
    with open(path_mdia + ".json", "r", encoding='utf-8') as f:
        list_mdia = json.load(f)
        # --- update release and support end date -----------------------------
        for line_mdia in list_mdia:
            for line_dist in list_dist:
                if line_dist["version"] != line_mdia["version"]:
                    continue
                line_mdia["release"] = line_dist["release"]
                if line_dist["long_term"] == "-":
                    line_mdia["support"] = line_dist["support"]
                else:
                    line_mdia["support"] = line_dist["long_term"]
    # --- return --------------------------------------------------------------
    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    return list_mdia

def put(conf, list_mdia):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    path_mdia = conf["PATH_MDIA"]       # media data file           : '/srv/user/share/conf/_data/media.dat'
    with open(path_mdia + ".json", "w", encoding="utf-8") as f:
        json.dump(list_mdia, f, ensure_ascii=False, indent=4)
    debugout(config.debugout, color.yellow, func_name, "Complete", "")

def encode(list):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    for line in list:
        for key, value in line.items():
            if isinstance(value, str):
                line[key] = value.replace(' ', '%20')
#               line[key] = urllib.parse.quote(value, safe='')
    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    return list

def decode(list):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    for line in list:
        for key, value in line.items():
            if isinstance(value, str):
                line[key] = value.replace('%20', ' ')
#               line[key] = urllib.parse.unquote(value)
    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    return list

def text2json(conf):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    path_mdia = conf["PATH_MDIA"]       # media data file           : '/srv/user/share/conf/_data/media.dat'
    proc_line = (re.sub(r"[ \t]+", ",", line.strip()) for line in open(path_mdia, "r", encoding="utf-8", newline=""))
    list_data = list(csv.DictReader(proc_line))
    with open(path_mdia + ".json", "w", encoding="utf-8") as f:
        json.dump(list_data, f, ensure_ascii=False, indent=4)
    debugout(config.debugout, color.yellow, func_name, "Complete", "")

def json2text(conf, list_dist):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    path_mdia = conf["PATH_MDIA"]       # media data file           : '/srv/user/share/conf/_data/media.dat'
    list = get(conf, list_dist)
    text = [f"{'type':<11} {'entry_flag':<11} {'entry_name':<39} {'entry_disp':<39} {'version':<23} {'latest':<23} {'release':<15} {'support':<15} {'web_regexp':<143} {'web_path':<143} {'web_tstamp':<47} {'web_size':<15} {'web_check':<47} {'web_status':<15} {'iso_path':<87} {'iso_tstamp':<47} {'iso_size':<15} {'iso_volume':<43} {'rmk_path':<87} {'rmk_tstamp':<47} {'rmk_size':<15} {'rmk_volume':<43} {'ldr_initrd':<87} {'ldr_kernel':<87} {'cfg_path':<87} {'cfg_tstamp':<47} {'lnk_path':<87} {'options':<59} {'create_flag':<11} "]
    for line in list:
        data = f"{line["type"]:<11} {line["entry_flag"]:<11} {line["entry_name"]:<39} {line["entry_disp"]:<39} {line["version"]:<23} {line["latest"]:<23} {line["release"]:<15} {line["support"]:<15} {line["web_regexp"]:<143} {line["web_path"]:<143} {line["web_tstamp"]:<47} {line["web_size"]:<15} {line["web_check"]:<47} {line["web_status"]:<15} {line["iso_path"]:<87} {line["iso_tstamp"]:<47} {line["iso_size"]:<15} {line["iso_volume"]:<43} {line["rmk_path"]:<87} {line["rmk_tstamp"]:<47} {line["rmk_size"]:<15} {line["rmk_volume"]:<43} {line["ldr_initrd"]:<87} {line["ldr_kernel"]:<87} {line["cfg_path"]:<87} {line["cfg_tstamp"]:<47} {line["lnk_path"]:<87} {line["options"]:<59} {line["create_flag"]:<11} "
        text.append(data)
    text.append("")
    with open(path_mdia, "w", encoding="utf-8") as f:
        f.write("\n".join(text))
    debugout(config.debugout, color.yellow, func_name, "Complete", "")
