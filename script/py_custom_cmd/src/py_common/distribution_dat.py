import json
import urllib.parse
import re
import csv

from .color import Color_code

# distribution data file
class Distribution_dat():
    def __init__(self):
        self.data = dict()
    def debug(self):
        debug(self.data)
    def load(self, conf):
        data = get(conf)
        self.data = decode(data)
    def save(self, conf):
        data = encode(self.data)
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
    color = Color_code()
    print(f"{color.code['br_green']}=== debug out: {__name__} : start ==={color.code['reset']}")
    for line in list:
        print(f"{color.code['yellow']}    list_dist='{line}'{color.code['reset']}")
    print(f"{color.code['br_green']}=== debug out: {__name__} : complete ==={color.code['reset']}")

def get(conf):
    path_dist = conf["PATH_DIST"]       # distribution data file    : '/srv/user/share/conf/_data/distribution.dat'
    list_dist = []
    with open(path_dist + ".json", "r", encoding='utf-8') as f:
        list_dist = json.load(f)
    # --- return --------------------------------------------------------------
    return list_dist

def put(conf, list_dist):
    path_dist = conf["PATH_DIST"]       # distribution data file    : '/srv/user/share/conf/_data/distribution.dat'
    with open(path_dist + ".json", "w", encoding="utf-8") as f:
        json.dump(list_dist, f, ensure_ascii=False, indent=4)

def encode(list):
    for line in list:
        for key, value in line.items():
            if isinstance(value, str):
                line[key] = value.replace(' ', '%20')
#               line[key] = urllib.parse.quote(value, safe='')
    return list

def decode(list):
    for line in list:
        for key, value in line.items():
            if isinstance(value, str):
                line[key] = value.replace('%20', ' ')
#               line[key] = urllib.parse.unquote(value)
    return list

def text2json(conf):
    path_dist = conf["PATH_DIST"]       # distribution data file    : '/srv/user/share/conf/_data/distribution.dat'
    proc_line = (re.sub(r"[ \t]+", ",", line.strip()) for line in open(path_dist, "r", encoding="utf-8", newline=""))
    list_data = list(csv.DictReader(proc_line))
    with open(path_dist + ".json", "w", encoding="utf-8") as f:
        json.dump(list_data, f, ensure_ascii=False, indent=4)

def json2text(conf):
    path_dist = conf["PATH_DIST"]       # distribution data file    : '/srv/user/share/conf/_data/distribution.dat'
    list = get(conf)
    text = [f"{'version':<23} {'name':<23} {'version_id':<23} {'code_name':<39} {'life':<15} {'release':<15} {'support':<15} {'long_term':<15} {'rhel':<15} {'kerne':<27} {'note':<27} {'wallpaper':<87} {'create_flag':<11} {'sort_flag':<11} "]
    for line in list:
        data = f"{line["version"]:<23} {line["name"]:<23} {line["version_id"]:<23} {line["code_name"]:<39} {line["life"]:<15} {line["release"]:<15} {line["support"]:<15} {line["long_term"]:<15} {line["rhel"]:<15} {line["kerne"]:<27} {line["note"]:<27} {line["wallpaper"]:<87} {line["create_flag"]:<11} {line["sort_flag"]:<11} "
        text.append(data)
    text.append("")
    with open(path_dist, "w", encoding="utf-8") as f:
        f.write("\n".join(text))
