#!/usr/bin/env python3
# encoding: utf-8

# python3 -m json.tool

import json

dirs_data = "/srv/user/share/conf/_data"
path_comm = dirs_data + "/common.cfg"
path_dist = dirs_data + "/distribution.dat"
path_medi = dirs_data + "/media.dat"

list_medi = []
with open(path_medi + ".json", "r", encoding='utf-8') as f:
    list_medi = json.load(f)

list_dist = []
with open(path_dist + ".json", "r", encoding='utf-8') as f:
    list_dist = json.load(f)

list_outp = []
for line_medi in list_medi:
    for line_dist in list_dist:
        if line_dist["version"] != line_medi["version"]:
           continue
        line_medi["release"] = line_dist["release"]
        if line_dist["long_term"] == "-":
            line_medi["support"] = line_dist["support"]
        else:
            line_medi["support"] = line_dist["long_term"]
    list_outp.append(line_medi)
with open("media.json", "w", encoding='utf-8') as f:
    json.dump(list_outp, f)
