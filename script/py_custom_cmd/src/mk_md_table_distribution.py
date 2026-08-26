#!/usr/bin/env python3
# encoding: utf-8

import os
#topdir = os.getcwd()

#topdir = "/home/master/linux/script/py_custom_cmd/src"
#import sys
#sys.path.append(topdir)

import argparse

import inspect

# sudo apt-get install python3-pandas
import pandas as pd

# sudo apt-get install python3-natsort
#from natsort import index_natsorted
#import numpy as np
from natsort import natsort_keygen
from packaging.version import parse as parse_version
#from packaging.version import Version
import re
#import argparse
#import os
#import subprocess
#import sys
import time

from py_common.my_config           import debug_flag, debugout_flag
from py_common.my_colors           import color
from py_common.my_debug            import debugout

from py_common.my_common_cfg       import Common_cfg
from py_common.my_distribution_dat import Distribution_dat
from py_common.my_media_dat        import Media_dat

# --- get common data file ----------------------------------------------------
common_cfg       = Common_cfg()
distribution_dat = Distribution_dat()
media_dat        = Media_dat()

def initialize():
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}() START")

    common_cfg.load()
    conf = common_cfg.exports()

    distribution_dat.load(conf)
    dist = distribution_dat.exports()

    media_dat.load(conf, dist)
    mdia = media_dat.exports()

    print(f"{func_name}() END")

    return conf, dist, mdia

def debug():
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}() START")
    common_cfg.debug()
    distribution_dat.debug()
    media_dat.debug()
    print(f"{func_name}() END")

def generate_md_table(dist, data):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", "")
    df = pd.DataFrame(data)
    colssize  = []
    spc = " " * 2
    header    = ""
    align     = ""
    md_text = ""
    # -------------------------------------------------------------------------
    md_text += f"* <details><summary>{data[0]['name']}</summary>\n\n"
    # -------------------------------------------------------------------------
    for name in df.columns.to_list():
        list = df[name].values
        for i, line in enumerate(list):
            line = re.sub(r"^(http[|s]:[^ ]+)", r"`\1`", line)
            list[i] = line
        max_val = max(list, key=len)
        colsize = len(max_val) if len(max_val) >= len(name) else len(name)
        colssize.append(colsize)
        match dist:
            case "debian":
                match name:
                    case "version_id" | "code_name" | "kerne" | "note":
                        header += f"|{name:^{colsize}}"
                        align += "|:" + "-" * (colsize - 1)
                    case "life" | "release" | "support" | "long_term":
                        header += f"|{name:^{colsize}}"
                        align += "|:" + "-" * (colsize - 2) + ":"
                    case _:
                        continue
            case \
              "fedora":
                match name:
                    case "version_id" | "code_name" | "kerne" | "note":
                        header += f"|{name:^{colsize}}"
                        align += "|:" + "-" * (colsize - 1)
                    case "life" | "release" | "support" | "long_term" | "rhel":
                        header += f"|{name:^{colsize}}"
                        align += "|:" + "-" * (colsize - 2) + ":"
                    case _:
                        continue
            case _:
                        continue
    header += "|"
    align += "|"
    md_text += f"{spc}{header}\n{spc}{align}\n"
    # -------------------------------------------------------------------------
    for index, row in df.iterrows():
        md_line = ""
        for i, name in enumerate(df.columns.to_list()):
            colsize = colssize[i]
            match dist:
                case "debian":
                    match name:
                        case "version_id" | "code_name" | "kerne" | "note":
                            md_line += f"|{row[name]:<{colsize}}"
                        case "life" | "release" | "support" | "long_term":
                            md_line += f"|{row[name]:^{colsize}}"
                        case _:
                            continue
                case \
                "fedora":
                    match name:
                        case "version_id" | "code_name" | "kerne" | "note":
                            md_line += f"|{row[name]:<{colsize}}"
                        case "life" | "release" | "support" | "long_term" | "rhel":
                            md_line += f"|{row[name]:^{colsize}}"
                        case _:
                            continue
                case _:
                            continue
        md_text += f"{spc}{md_line}|\n"
    # -------------------------------------------------------------------------
    md_text += f"\n</details>\n\n"
    # -------------------------------------------------------------------------
    debugout(debugout_flag, color.yellow, func_name, "Complete", "")
    return md_text

def generate_table(conf, dist, mdia):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}() START")
    list_dist = [
        'debian-([0-9.]+|testing|sid)',
        'ubuntu-[0-9.]+',
        'fedora-[0-9.]+',
        'centos-[0-9.]+',
        'centos-stream-[0-9.]+',
        'almalinux-[0-9.]+',
        'rockylinux-[0-9.]+',
        'miraclelinux-[0-9.]+',
        'opensuse-(leap-[0-9.]+|tumbleweed)',
        'windows-[0-9.]+-[0-9]+h[0-9]+',
        'winpe-.+',
        'ati.+',
        'memtest86plus'
    ]
    md_path = "./Readme_table_distribution.md"
    md_list = []
    md_text = f"# Distribution list\n\n"
    df = pd.DataFrame(dist)

    for line in list_dist:
        dist = line.lower()
        list = df.query("version.str.match(@dist)").sort_values(by=['sort_flag', 'version_id'], key=natsort_keygen(), ascending=[False, False]).to_dict('records')
        if not list:
            print(f"error: {dist}")
            continue
        match re.sub('-.+', '', dist):
            case \
              "debian" | \
              "ubuntu":
                md_text = md_text + generate_md_table("debian", list)
            case \
              "fedora"        | \
              "centos"        | \
              "centos-stream" | "centos stream" | \
              "almalinux"     | "alma linux"    | \
              "rockylinux"    | "rocky linux"   | \
              "miraclelinux"  | "miracle linux":
                md_text = md_text + generate_md_table("fedora", list)
#            case \
#              "opensuse":
#                return
#            case \
#              "windows":
#                return
#            case \
#              "winpe":
#                return
#            case \
#              "ati":
#                return
#            case \
#              "memtest86plus":
#                return
            case _:
                md_text = md_text + generate_md_table("debian", list)

    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md_text)

    print(f"{func_name}() END")


def main():
    start = time.perf_counter()
    func_name = inspect.currentframe().f_code.co_name
    debugout(True, color.yellow, func_name, "Start", "")

    global debug_flag
    global debugout_flag

    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug', help='Debug mode', action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    args = parser.parse_args()
    debug_flag = args.debug
    debugout_flag = args.debugout
    if debug_flag == True:
        debugout_flag = True

    debugout(debugout_flag, color.yellow, func_name, "info", "Debug mode on")

    if os.geteuid() != 0:
       print(f"{color.br_yellow}You have standard user privileges. Please run this with sudo.{color.reset}")
       exit(1)

    conf, dist, mdia = initialize()
#   debug()
    generate_table(conf, dist, mdia)

    debugout(True, color.yellow, func_name, "Complete", "")
    end = time.perf_counter()
    elapsed = end - start
    print(f"elapsed time: {elapsed:.4f} 秒")

if __name__ == "__main__":
    main()
