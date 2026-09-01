# --- Python library ----------------------------------------------------------
import inspect
import json
import pandas as pd
import re
import pprint

# --- my library --------------------------------------------------------------
from py_common.my_colors                import color
from py_common.my_debug                 import debugout

# -----------------------------------------------------------------------------
# descript: Encoding whitespace characters and html on a per-list basis
#   input : data             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_encode4md(data: list) -> list:
    conv = data.copy()
    for line in conv:
        for key, value in line.items():
            if not isinstance(value, str): break
            value = re.sub('^`(http[|s]:[^ ]+)`', '\1', value)
            value = re.sub(' ', '%20', value)
            line[key] = value
            eprint(line[key])
#           line[key] = urllib.parse.unquote(value)
    return conv

# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters and html on a per-list basis (sub)
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_decode4md_sub(data: list) -> list:
    conv = data.copy()
    for key, value in conv.items():
        value = conv[key]
        if not isinstance(value, str): break
        value = re.sub('^(http[|s]:[^ ]+)', r"`\1`", value)
        value = re.sub('%20', ' ', value)
        value = re.sub(':_', r":\\_", value)
        value = re.sub('_:', r"\\_:", value)
        conv[key] = value
    return conv

# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters and html on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_decode4md(data: list) -> list:
    url_pattern = re.compile(
        r'^(?:http[s]?://)?'
        r'(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+'
        r'[a-zA-Z]{2,}'
        r'(?:/[a-zA-Z0-9._~:/?#\[\]@!$&\'()*+,;=%-]*)?$'
    )
    conv = list()
    for line in data.copy():
        for key, value in line.items():
            if isinstance(value, str):
                match = url_pattern.search(value)
                if match:
                    for group in match.group(0).splitlines():
                        value = re.sub(f"({group})", r"`\1`", value)
                value = re.sub('^(http[|s]:[^ ]+)', r"`\1`", value)
                value = re.sub('%20', ' ', value)
#               value = re.sub(' ', '&nbsp;', value)
                value = re.sub(':_', r":\\_", value)
                value = re.sub('_:', r"\\_:", value)
                match = re.match('^#', value)
                if match:
                    value = f"`{value}`"
            line[key] = value
        conv.append(line)
    return conv

def spc_decode4md2(data: list) -> list:
    conv = list()
    if isinstance(data, dict):
        eprint("dict")
        conv.append(spc_decode4md_sub(data))
    elif isinstance(data, list):
        eprint("list")
        for line in data:
            conv.append(spc_decode4md_sub(line))
    return conv

# -----------------------------------------------------------------------------
# descript: markdown output of json data
#   input : path             : unused
#   input : title            : unused
#   input : data             : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def json2markdown(path: str, title: str, data: list):
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    text      = spc_decode4md(data.copy())
    colssize  = []
    spc = ' ' * 2
    header    = ''
    align     = ''
    df = pd.DataFrame(text)
    for name in df.columns.to_list():
        values = df[name].values
        max_val = max(values, key=len)
        colsize = len(max_val) if len(max_val) >= len(name) else len(name)
        colssize.append(colsize)
        header += f"|{name:^{colsize}}"
        align += '|:' + '-' * (colsize - 1)
    header += '|'
    align += '|'
    md_text = f"# Data table\n\n* {title}\n\n{spc}{header}\n{spc}{align}\n"
    for index, row in df.iterrows():
        md_line = ''
        for i, name in enumerate(df.columns.to_list()):
            colsize = colssize[i]
            md_line += f"|{row[name]:<{colsize}}"
        md_text += f"{spc}{md_line}|\n"
    with open(path, 'w', encoding='utf-8') as f:
        f.write(md_text)
     # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# --- eof ---------------------------------------------------------------------
