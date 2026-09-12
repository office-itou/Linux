"""File I/O processing"""

# --- Python library ----------------------------------------------------------
import copy
import csv
import re

# --- my library --------------------------------------------------------------
from ..utils.my_debug import debug_logger
from ..utils.my_fileio import file_read, file_write


def spc_encode(src_datas: list) -> list:
    """Encoding whitespace characters on a per-list basis

    Args:
        src_datas (list): Source data

    Returns:
        list: Conversion data
    """
    _converted_data = []
    for _src_data in src_datas:
        _converted_dicts = {}
        for _key, _value in _src_data.items():
            if not _value:
                _value = "-"
            if isinstance(_value, (int, float)):
                _value = str(_value)
            if isinstance(_value, str):
                _value = _value.replace(" ", "%20")
                _value = _value.strip("`")
                if _value.endswith("/"):
                    _value = _value + "-"
            _converted_dicts[_key] = _value
        _converted_data.append(_converted_dicts)
    return _converted_data


def spc_decode(src_datas: list) -> list:
    """Decoding whitespace characters on a per-list basis

    Args:
        src_data (list): Source data

    Returns:
        list: Conversion data
    """
    _converted_data = []
    for _src_data in src_datas:
        _converted_dicts = {}
        if hasattr(_src_data, "items"):
            for _key, _value in _src_data.items():
                if isinstance(_value, str):
                    _value = _value.replace("%20", " ").strip("-")
                _converted_dicts[_key] = _value
        _converted_data.append(_converted_dicts)
    return _converted_data


@debug_logger
def get_text2list(src_path: str) -> list[dict[str, str]]:
    """Text file to list

    Args:
        src_path (str): Source path

    Returns:
        list[dict[str, str]]: Conversion data
    """
    _read_data = file_read(src_path)
    _lines = (l.strip() for l in _read_data.splitlines() if l.strip())
    _sanitized_lines = (re.sub(r"[ \t]+", ",", l) for l in _lines)
    return list(csv.DictReader(_sanitized_lines))


@debug_logger
def put_list2text(dst_path: str, src_datas: list, format_str: str) -> None:
    """list to text file

    Args:
        dst_path (str): Destination path
        src_data (list): Source data
        format_str (str): Output format
    """
    if not src_datas:
        return
    _header_dict = {k: k for d in src_datas for k, v in d.items()}
    _data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in src_datas]
    _text_list = [format_str.format(**_header_dict)] + [
        format_str.format(**d) for d in _data_dicts
    ]
    _write_data = "\n".join(_text_list) + "\n"
    file_write(dst_path, _write_data, text=True, backup=True)


# --- eof ---------------------------------------------------------------------
