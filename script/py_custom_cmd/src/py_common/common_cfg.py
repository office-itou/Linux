import os
import sys
import re

from .color import Color_code

# common configuration file
class Common_cfg():
    def __init__(self):
        self.conf = dict()
    def debug(self):
        debug(self.conf)
    def load(self):
        self.conf = get()
#   def save(self):
#       put(self.data)
    def get(self, key):
        return self.conf.get(key, "")
#   def set(self, key, value):
#       self.conf[key] = value
    def exports(self):
        return self.data
#   def imports(self, data):
#       self.data = json.dump(data, ensure_ascii=False, indent=4)

def debug(list):
    color = Color_code()
    print(f"{color.code['br_green']}=== debug out: {__name__} : start ==={color.code['reset']}")
    for key in list.keys():
        value = list[key]
        print(f"{color.code['yellow']}    conf[{key}]='{value}'{color.code['reset']}")
    print(f"{color.code['br_green']}=== debug out: {__name__} : complete ==={color.code['reset']}")

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
    if not path_conf:
        print("file not found: " + file_conf)
        sys.exit(1)
    # --- get setting items ---------------------------------------------------
    conf=dict()
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

# --- convert to data format --------------------------------------------------
def conv2data(conf, list_inpt):
    list_outp = []
    for line in list_inpt:
        for key in line.keys():
            while True:
                match = re.search(r":_[a-zA-Z0-9]+_[a-zA-Z0-9]+_:", line[key])
                if not match:
                    break
                match_text = match.group()
                match_key  = re.sub(r"^:_", "", match_text)
                match_key  = re.sub(r"_:$", "", match_key)
                line[key]  = re.sub(r":_" + match_key + "_:", conf[match_key], line[key])
        list_outp.append(line)
    return(list_outp)

# --- convert to variable format ----------------------------------------------
def conv2variable(conf, list_inpt):
    list_outp = []
    for line in list_inpt:
        for key in line.keys():
            for conf_key in reversed(conf):
                match = re.search(r"DIRS_[a-zA-Z0-9]+", conf_key)
                if not match:
                    continue
                match = re.search(r"^/", conf[conf_key])
                if not match:
                    continue
                line[key]  = re.sub(conf[conf_key], r":_" + conf_key + "_:", line[key])
        list_outp.append(line)
    return(list_outp)
