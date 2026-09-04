###############################################################################
#
# 	markdown processing
#
# 	developer   : J.Itou
# 	release     : 2026/09/03
#
# 	history     :
# 	   data    version    developer    point
# 	---------- -------- -------------- ----------------------------------------
# 	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
import copy
import re

import pandas as pd

# --- my library --------------------------------------------------------------
from py_common.my_debug import debug_logger
from py_common.my_string import count_width


# -----------------------------------------------------------------------------
# descript: Encoding whitespace characters and html on a per-list basis
#   input : data             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def spc_encode4md(data: list) -> list:
    conv = copy.deepcopy(data)
    for i, word in enumerate(conv):
        if not isinstance(word, str):
            continue
        word = re.sub(r"^`([^`]+)`$", r"\1", word)
        word = word.replace(" ", "%20")
        word = word.replace(r":\_", ":_")
        word = word.replace(r"\_:", "_:")
        conv[i] = word
    return conv


# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters and html on a per-list basis (sub)
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def spc_decode4md_sub(data: list) -> list:
    conv = copy.deepcopy(data)
    for i, word in enumerate(conv):
        if not isinstance(word, str):
            continue
        word = re.sub(r"^(https?:/[^ ]+)", r"`\1`", word)
        word = word.replace("%20", " ")
        word = word.replace(":_", r":\_")
        word = word.replace("_:", r"\_:")
        conv[i] = word
    return conv


# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters and html on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def spc_decode4md(data: list) -> list:
    url_pattern = re.compile(
        r"^https?://(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}"
        r"(?:/[a-zA-Z0-9._~:/?#\[\]@!$&\'()*+,;=%-]*)?$"
    )
    processed_data = copy.deepcopy(data)
    for line in processed_data:
        for key, value in line.items():
            if not isinstance(value, str):
                continue
            if url_pattern.match(value):
                value = f"`{value}`"
            value = re.sub(r"^(https?:/[^ ]+)", r"`\1`", value)
            value = value.replace("%20", " ")
            value = value.replace(":_", r":\_")
            value = value.replace("_:", r"\_:")
            if value.startswith("#"):
                value = f"`{value}`"
            line[key] = value
    return processed_data


# -----------------------------------------------------------------------------
# descript: markdown output of list data
#   input : path             : unused
#   input : title            : unused
#   input : data             : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def list2markdown(path: str, title: str, data: list):
    text = spc_decode4md(data.copy())
    spc = " " * 2
    header = ""
    align = ""
    df = pd.DataFrame(text)
    # --- get the width of each column ----------------------------------------
    col_sizes = {}
    for name in df.columns:
        cnt_name = count_width(str(name))
        max_size = df[name].apply(lambda x: count_width(str(x))).max()
        col_sizes[name] = max(max_size, cnt_name)
    # --- header and divider line ---------------------------------------------
    for name in df.columns:
        colsize = col_sizes[name]
        name_str = str(name)
        pad_total = colsize - count_width(name_str)
        pad_l = pad_total // 2
        pad_r = pad_total - pad_l
        header += f"|{' ' * pad_l}{name_str}{' ' * pad_r}"
        align += "|:" + "-" * (colsize - 1)
    header += "|"
    align += "|"
    # --- data ----------------------------------------------------------------
    md_rows = []
    for index, row in df.iterrows():
        row_text = ""
        for name in df.columns:
            colsize = col_sizes[name]
            val_str = str(row[name])
            pad_r = colsize - count_width(val_str)
            row_text += f"|{val_str}{' ' * pad_r}"
        row_text += "|"
        md_rows.append(f"{spc}{row_text}")
    # --- output --------------------------------------------------------------
    md_text = f"# Data table\n\n* {title}\n\n{spc}{header}\n{spc}{align}\n"
    md_text += "\n".join(md_rows) + "\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(md_text)


# -----------------------------------------------------------------------------
# descript: list data output of markdown
#   input : path             : unused
#   input : title            : unused
#   input : data             : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def markdown2list(path: str) -> list:
    table_rows = []
    headers = []
    try:
        with open(path, "r", encoding="utf-8") as f:
            for line in f:
                line_str = line.strip()
                if line_str.startswith("|") and line_str.endswith("|"):
                    cells = [cell.strip() for cell in line_str.split("|")[1:-1]]
                    if all(re.match(r"^:?-+:?$", c) for c in cells):
                        continue
                    if not headers:
                        headers = cells
                    else:
                        row_dict = {}
                        for i, head in enumerate(headers):
                            row_dict[head] = cells[i] if i < len(cells) else ""
                        table_rows.append(row_dict)
                elif headers and table_rows:
                    break
        return table_rows
    except FileNotFoundError:
        print(f"Error: {path} not found")
        return []


# --- eof ---------------------------------------------------------------------
