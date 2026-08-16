import json
import re
import csv

def debug(list):
    print("=== debug out: " + __name__ + " ===")
    for line in list:
        print(line)

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
