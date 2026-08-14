#!/usr/bin/env python3
# encoding: utf-8

# python3 -m json.tool

import csv
import re
from io import StringIO
import json

dirs_data = "/srv/user/share/conf/_data"
path_comm = dirs_data + "/common.cfg"
path_dist = dirs_data + "/distribution.dat"
path_medi = dirs_data + "/media.dat"

def fnConv(path):
    proc_line = (re.sub(r"[ \t]+", ",", line.strip()) for line in open(path, "r", encoding="utf-8", newline=""))
    list_data = list(csv.DictReader(proc_line))
    with open(path + ".json", "w", encoding="utf-8") as f:
        json.dump(list_data, f, ensure_ascii=False, indent=4)

fnConv(path_dist)
fnConv(path_medi)
