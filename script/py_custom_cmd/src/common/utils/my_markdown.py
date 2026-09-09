"""Markdown processing"""

# --- Python library ----------------------------------------------------------
import copy
import re

import pandas as pd

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_fileio import file_read, file_write
from .my_string import count_width


# -----------------------------------------------------------------------------
@debug_logger
def spc_encode4md(src_list_data: list) -> list:
    """Encoding whitespace characters and html on a per-list basis

    Args:
        src_list_data (list): Source data

    Returns:
        list: Conversion data
    """
    conv_list_data = copy.deepcopy(src_list_data)
    for i, word in enumerate(conv_list_data):
        if not isinstance(word, str):
            continue
        word = re.sub(r"^`([^`]+)`$", r"\1", word)
        word = word.replace(" ", "%20")
        word = word.replace(r":\_", ":_")
        word = word.replace(r"\_:", "_:")
        conv_list_data[i] = word
    return conv_list_data


# -----------------------------------------------------------------------------
@debug_logger
def spc_decode4md(src_list_data: list[dict]) -> list:
    """Decoding whitespace characters and html on a per-list basis

    Args:
        src_list_data (list[dict]): Source data

    Returns:
        list: Conversion data
    """
    url_pattern = re.compile(
        r"^https?://(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}"
        r"(?:/[a-zA-Z0-9._~:/?#\[\]@!$&\'()*+,;=%-]*)?$"
    )
    conv_list_data = []
    for item in src_list_data:
        dict_orig = {}
        for key, value in item.items():
            if isinstance(value, str):
                if url_pattern.match(value):
                    value = f"`{value}`"
                value = re.sub(r"^(https?:/[^ ]+)", r"`\1`", value)
                value = value.replace("%20", " ")
                value = value.replace(":_", r":\_")
                value = value.replace("_:", r"\_:")
                if value.startswith("#"):
                    value = f"`{value}`"
            dict_orig[key] = value
        conv_list_data.append(dict_orig)
    return conv_list_data


# -----------------------------------------------------------------------------
@debug_logger
def list2markdown(dst_path: str, md_title: str, src_data: list) -> None:
    """Markdown output of list data

    Args:
        dst_path (str): Destination path
        md_title (str): Markdown title
        src_data (list): Source data
    """
    spc = " " * 2

    def generate(data: list):
        text = spc_decode4md(data)
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
        return (header, align, md_rows)

    # --- output --------------------------------------------------------------
    md_text = "# Data table\n"
    if src_data and isinstance(src_data[0], list):
        md_text += f"\n## {md_title}\n"
        for data in src_data:
            md_text += f"\n* <details><summary>{data[:1][0]}</summary>\n"
            header, align, md_rows = generate(data[1:])
            md_text += f"\n{spc}{header}\n{spc}{align}\n"
            md_text += "\n".join(md_rows) + f"\n\n{spc}</details>\n"
    else:
        md_text += f"\n* {md_title}\n"
        header, align, md_rows = generate(src_data)
        md_text += f"\n{spc}{header}\n{spc}{align}\n"
        md_text += "\n".join(md_rows) + "\n"
    file_write(dst_path, md_text, text=True, backup=True)


# -----------------------------------------------------------------------------
def markdown2list(src_path: str) -> list:
    """List data output of markdown

    Args:
        src_path (str): Source path

    Returns:
        list: Destination data
    """
    table_rows = []
    headers = []
    read_data = file_read(src_path)
    for line in read_data:
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


# --- eof ---------------------------------------------------------------------
