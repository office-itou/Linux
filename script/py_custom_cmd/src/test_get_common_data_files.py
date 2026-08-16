#!/usr/bin/env python3
# encoding: utf-8

# python3 -m json.tool

import re
import sys

import py_common

# --- get common data file ----------------------------------------------------
conf = py_common.common_cfg.get()                       # get common configuration file
#py_common.common_cfg.debug(conf)

list_dist = py_common.distribution_dat.get(conf)        # get distribution data file
#py_common.distribution_dat.debug(list_dist)

list_mdia = py_common.media_dat.get(conf, list_dist)    # get media data file
#py_common.media_dat.debug(list_mdia)


print("start conv2data")
list = py_common.common_cfg.conv2data(conf, list_mdia)
py_common.media_dat.debug(list)
print("end conv2data")

print("start conv2variable")
list = py_common.common_cfg.conv2variable(conf, list)
py_common.media_dat.debug(list)
print("end conv2variable")

#py_common.media_dat.put(conf, list)
#py_common.media_dat.json2text(conf, list_dist)

sys.exit(0)

def t():
    while True:
        match = re.search(r":_[a-zA-Z0-9]+_[a-zA-Z0-9]+_:", line)
        if not match:
            break
        match_text = match.group()
        match_key  = re.sub(r"^:_", "", match_text)
        match_key  = re.sub(r"_:$", "", match_key)
        line       = re.sub(r":_" + match_key + "_:", conf[match_key], line)
    print(line)
