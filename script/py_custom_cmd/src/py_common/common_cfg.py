import re

def debug(conf):
    for key in conf.keys():
        print("conf[" + key + "]='" + conf[key] + "'")

def get(path):
    conf={}
    # --- get setting items ---------------------------------------------------
    for line in open(path, "r", encoding='utf-8'):
        match = re.search(r"^[A-Z]", line)      # get parameter row
        if not match:
            continue
        line  = re.sub(r"[\n|\r\n]$", "", line)  # remove lf or crlf
        line  = re.sub(r"#.*$", "", line)        # remove comment
        line  = re.sub(r"[ \t]+$", "", line)     # remove trailing whitespace
        key   = re.sub(r"=.*$", "", line)        # get the key
        value = re.sub(key + r"=", "", line)     # get the value
        value = re.sub(r"^\"", "", value)        # remove the first double quotation mark
        value = re.sub(r"\"$", "", value)        # remove the last double quotation mark
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
