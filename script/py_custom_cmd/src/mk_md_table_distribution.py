#!/usr/bin/env python3
# encoding: utf-8

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

#import py_common
from py_common.common_cfg       import Common_cfg
from py_common.distribution_dat import Distribution_dat
from py_common.media_dat        import Media_dat

# --- get common data file ----------------------------------------------------
comm_conf = Common_cfg()
dist_data = Distribution_dat()
mdia_data = Media_dat()

def initialize():
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}() START")
    comm_conf.load()
    dist_data.load(comm_conf.conf)
    mdia_data.load(comm_conf.conf, dist_data.data)
    print(f"{func_name}() END")

def debug():
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}() START")
    comm_conf.debug()
    dist_data.debug()
    mdia_data.debug()
    print(f"{func_name}() END")

def generate_table_debian(list):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({list[0]['name']}) START")
    md_dist = list[0]['name']
    md_text = f"""
* <details><summary>{md_dist}</summary>

  | version_id               | code_name                                | life             | release          | support          | long_term        | kerne                        | note                         |
  | :----------------------: | :--------------------------------------- | :--------------: | :--------------: | :--------------: | :--------------: | :--------------------------- | :--------------------------- |
"""
    for line in list:
        md_text = md_text + f"  | {line['version_id']:<24} | {line['code_name']:<40} | {line['life']:<16} | {line['release']:<16} | {line['support']:<16} | {line['long_term']:<16} | {line['kerne']:<28} | {line['note']:<28} |\n"
    md_text = md_text + f"""
</details>
"""
    print(f"{func_name}({list[0]['name']}) END")
    return md_text

def generate_table_fedora(list):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({list[0]['name']}) START")
    md_dist = list[0]['name']
    md_text = f"""
* <details><summary>{md_dist}</summary>

  | version_id               | code_name                                | life             | release          | support          | long_term        | rhel             | kerne                        | note                         |
  | :----------------------: | :--------------------------------------- | :--------------: | :--------------: | :--------------: | :--------------: | :--------------: | :--------------------------- | :--------------------------- |
"""
    for line in list:
        md_text = md_text + f"  | {line['version_id']:<24} | {line['code_name']:<40} | {line['life']:<16} | {line['release']:<16} | {line['support']:<16} | {line['long_term']:<16} | {line['rhel']:<16} | {line['kerne']:<28} | {line['note']:<28} |\n"
    md_text = md_text + f"""
</details>
"""
    print(f"{func_name}({list[0]['name']}) END")
    return md_text

#def version_key(v):
#    v = re.sub(r"^[^0-9]*([0-9.]+).*$", r"\1", v)
#    return [int(x) for x in v.split(".")]

def generate_table():
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
    md_text = """
# Distribution list
"""

    dist = dist_data.exports()
    df = pd.DataFrame(dist)
#    result = df.query("version.str.match('debian-[0-9]+')", engine='python')
#    print(result[['version','name']])

#    sys.exit(0)

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
                md_text = md_text + generate_table_debian(list)
            case \
              "fedora"        | \
              "centos"        | \
              "centos-stream" | "centos stream" | \
              "almalinux"     | "alma linux"    | \
              "rockylinux"    | "rocky linux"   | \
              "miraclelinux"  | "miracle linux":
                md_text = md_text + generate_table_fedora(list)
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
                md_text = md_text + generate_table_debian(list)

    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md_text)

    print(f"{func_name}() END")


def main():
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}() START")
    initialize()
#   debug()
    generate_table()
    print(f"{func_name}() END")

if __name__ == "__main__":
    main()
