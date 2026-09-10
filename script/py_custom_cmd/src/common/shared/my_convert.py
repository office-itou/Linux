"""File I/O processing"""

# --- Python library ----------------------------------------------------------
import copy
import csv
import re

# --- my library --------------------------------------------------------------
from ..utils.my_debug import debug_logger
from ..utils.my_fileio import file_read, file_write


def spc_encode(src_list: list) -> list:
    """Encoding whitespace characters on a per-list basis

    Args:
        src_list (list): Source data

    Returns:
        list: Conversion data
    """
    conv_list = []
    for item in src_list:
        conv_dict = {}
        for key, value in item.items():
            if isinstance(value, str):
                value = value.replace(" ", "%20")
                value = value.strip("`")
            if not value:
                value = "-"
            conv_dict[key] = value
        conv_list.append(conv_dict)
    return conv_list


def spc_decode(src_list: list) -> list:
    """Decoding whitespace characters on a per-list basis

    Args:
        src_list (list): Source data

    Returns:
        list: Conversion data
    """
    conv_list = []
    for item in src_list:
        conv_dict = {}
        for key, value in item.items():
            if isinstance(value, str):
                value = value.replace("%20", " ")
                value = re.sub(r"^-$", "", value) if key != "entry_flag" else value
            conv_dict[key] = value
        conv_list.append(conv_dict)
    return conv_list


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


@debug_logger
def get_text2list(src_path: str) -> list[dict[str, str]]:
    """Text file to list

    Args:
        src_path (str): Source path

    Returns:
        list[dict[str, str]]: Conversion data
    """
    read_data = file_read(src_path)
    lines = (line.strip() for line in read_data.splitlines() if line.strip())
    sanitized_lines = (re.sub(r"[ \t]+", ",", line) for line in lines)
    return list(csv.DictReader(sanitized_lines))


@debug_logger
def put_list2text(dst_path: str, src_data: list, format_str: str) -> None:
    """list to text file

    Args:
        dst_path (str): Destination path
        src_data (list): Source data
        format_str (str): Output format
    """
    if not src_data:
        return
    header_dict = {k: k for d in src_data for k in d}
    cleaned_data_list = spc_encode(
        [{k: str(v) for k, v in d.items()} for d in src_data]
    )
    text_list = [format_str.format(**header_dict)] + [
        format_str.format(**d) for d in cleaned_data_list
    ]
    write_data = "\n".join(text_list) + "\n"
    file_write(dst_path, write_data, text=True, backup=True)


# --- eof ---------------------------------------------------------------------
