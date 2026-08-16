import os
import sys
import re

def debug(list):
    print("=== debug out: " + __name__ + " ===")
    for key in list.keys():
        print("conf[" + key + "]='" + list[key] + "'")

def get():
    dirs_data = "/srv/user/share/conf/_data"    # data file                                 : '/srv/user/share/conf/_data'
    file_conf = "common.cfg"                    # common configuration file
    path_conf = ""                              # common configuration file
    for dirs in [".", dirs_data]:
        path = os.path.join(dirs, file_conf)
        if not os.path.exists(path):
            continue
        path_conf = path
        break
    if path_conf == "":
        print("file not found: " + file_conf)
        sys.exit(1)
    # --- get setting items ---------------------------------------------------
    conf={}
    for line in open(path_conf, "r", encoding='utf-8'):
        match = re.search(r"^[A-Z]", line)      # get parameter row
        if not match:
            continue
        line  = re.sub(r"[\n|\r\n]$", "", line) # remove lf or crlf
        line  = re.sub(r"#.*$", "", line)       # remove comment
        line  = re.sub(r"[ \t]+$", "", line)    # remove trailing whitespace
        key   = re.sub(r"=.*$", "", line)       # get the key
        value = re.sub(key + r"=", "", line)    # get the value
        value = re.sub(r"^\"", "", value)       # remove the first double quotation mark
        value = re.sub(r"\"$", "", value)       # remove the last double quotation mark
        conf[key] = value
    # --- convert setting items -----------------------------------------------
    for key in conf.keys():
        value = conf[key]
        while True:
            match = re.search(r":_[a-zA-Z0-9]+_[a-zA-Z0-9]+_:", value)
            if not match:
                break
            match_text  = match.group()
            match_key   = re.sub(r"^:_", "", match_text)
            match_key   = re.sub(r"_:$", "", match_key)
            match_value = conf[match_key]
            value = re.sub(r":_" + match_key + "_:", match_value, value)
        conf[key] = value
    # --- return --------------------------------------------------------------
    return conf
