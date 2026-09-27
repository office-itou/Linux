"""File I/O processing"""

# --- Python library ----------------------------------------------------------
import csv
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    file_write,
    handle_fatal_error,
    get_caller_name,
    message_warn,
)


# ruff: isort: on
# =============================================================================
def spc_encode(src_datas: list[dict[str, str]]) -> list[dict[str, str]]:
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


def spc_decode(src_datas: list[dict[str, str]]) -> list[dict[str, str]]:
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
def get_text2list(src_path: Path) -> list[dict[str, str]]:
    """Text file to list
    Args:
        src_path (str): Source path
    Returns:
        list[dict[str, str]]: Conversion data
    """
    _caller = get_caller_name()
    _result: list[dict[str, str]] = []
    try:
        _src_path = src_path.resolve()
        with open(_src_path, mode="r", encoding="utf-8", newline=None) as f:
            _data_reader = csv.reader(f, delimiter=" ", skipinitialspace=True)
            _headers = next(_data_reader)
            for _row in _data_reader:
                _row_dict = {}
                for i, _header in enumerate(_headers):
                    _row_dict[_header] = _row[i] if i < len(_row) else ""
                _result.append(_row_dict)
    except (OSError, Exception) as e:
        handle_fatal_error(_caller, e)
    return _result


@debug_logger
def put_list2text(
    dst_path: Path, src_datas: list[dict[str, str]], format_str: str
) -> None:
    """list to text file
    Args:
        dst_path (str): Destination path
        src_data (list): Source data
        format_str (str): Output format
    """
    _caller = get_caller_name()
    if not src_datas:
        message_warn(_caller, "No data")
        return
    _header_dict = {k: k for d in src_datas for k, v in d.items()}
    _data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in src_datas]
    _text_list = [format_str.format(**_header_dict)] + [
        format_str.format(**d) for d in _data_dicts
    ]
    _write_data = "\n".join(_text_list) + "\n"
    file_write(dst_path, _write_data, text=True, backup=True)


# --- eof ---------------------------------------------------------------------
