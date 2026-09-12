"""Markdown processing"""

# --- Python library ----------------------------------------------------------
import re

import pandas as pd

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_fileio import file_read, file_write
from .my_string import count_width


# -----------------------------------------------------------------------------
@debug_logger
def list2markdown(dest_path: str, md_title: str, src_datas: list) -> None:
    """Markdown output of list data

    Args:
        dest_path (str): Destination path
        md_title (str): Markdown title
        src_data (list): Source data
    """
    _spc_str = " " * 2
    _url_pattern = re.compile(
        r"^https?://(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}"
        r"(?:/[a-zA-Z0-9._~:/?#\[\]@!$&\'()*+,;=%-]*)?$"
    )
    _comment_pattern = re.compile(r"^#.*$")
    # _addr_pattern = re.compile(r"^[A-Z0-9]+_ADDR$")
    # _ip_pattern = re.compile(r"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$")

    def _conversion_url(list_data: list) -> list:
        _conv_list_data = []
        for _dict_data in list_data:
            _dict_orig = {
                _key: f"`{_value}`"
                if (
                    isinstance(_value, str)
                    and (_url_pattern.match(_value) or _comment_pattern.match(_value))
                )
                else _value
                for _key, _value in _dict_data.items()
            }
            _conv_list_data.append(_dict_orig)
        return _conv_list_data

    def _generate(list_data: list):
        _df = pd.DataFrame(_conversion_url(list_data))
        # --- get the width of each column ----------------------------------------
        _col_sizes = {}
        for _name in _df.columns:
            _cnt_name = count_width(str(_name))
            _max_size = _df[_name].apply(lambda x: count_width(str(x))).max()
            _col_sizes[_name] = max(_max_size, _cnt_name)
        # --- header and divider line ---------------------------------------------
        _header = ""
        _align = ""
        for _name in _df.columns:
            _colsize = _col_sizes[_name]
            _name_str = str(_name)
            _pad_total = _colsize - count_width(_name_str)
            _pad_l = _pad_total // 2
            _pad_r = _pad_total - _pad_l
            _header += f"|{' ' * _pad_l}{_name_str}{' ' * _pad_r}"
            _align += "|:" + "-" * (_colsize - 1)
        _header += "|"
        _align += "|"
        # --- data ----------------------------------------------------------------
        _md_rows = []
        for _index, _row in _df.iterrows():
            _row_text = ""
            for _name in _df.columns:
                _colsize = _col_sizes[_name]
                _val_str = str(_row[_name])
                _pad_r = _colsize - count_width(_val_str)
                _row_text += f"|{_val_str}{' ' * _pad_r}"
            _row_text += "|"
            _md_rows.append(f"{_spc_str}{_row_text}")
        return (_header, _align, _md_rows)

    # --- output --------------------------------------------------------------
    _md_text = "# Data table\n"
    if src_datas and isinstance(src_datas[0], list):
        _md_text += f"\n## {md_title}\n"
        for _data in src_datas:
            _md_text += f"\n* <details><summary>{_data[:1][0]}</summary>\n"
            _header, _align, _md_rows = _generate(_data[1:])
            _md_text += f"\n{_spc_str}{_header}\n{_spc_str}{_align}\n"
            _md_text += "\n".join(_md_rows) + f"\n\n{_spc_str}</details>\n"
    else:
        _md_text += f"\n* {md_title}\n"
        _header, _align, _md_rows = _generate(src_datas)
        _md_text += f"\n{_spc_str}{_header}\n{_spc_str}{_align}\n"
        _md_text += "\n".join(_md_rows) + "\n"
    file_write(dest_path, _md_text, text=True, backup=True)


# -----------------------------------------------------------------------------
def markdown2list(src_path: str) -> list:
    """List data output of markdown

    Args:
        src_path (str): Source path

    Returns:
        list: Destination data
    """
    _table_rows = []
    _headers = []
    _read_data = file_read(src_path)
    for _line in _read_data:
        _line_str = _line.strip()
        if _line_str.startswith("|") and _line_str.endswith("|"):
            _cells = [_cell.strip() for _cell in _line_str.split("|")[1:-1]]
            if all(re.match(r"^:?-+:?$", c) for c in _cells):
                continue
            if not _headers:
                _headers = _cells
            else:
                _row_dict = {}
                for i, _head in enumerate(_headers):
                    _row_dict[_head] = _cells[i] if i < len(_cells) else ""
                _table_rows.append(_row_dict)
        elif _headers and _table_rows:
            break
    return _table_rows


# --- eof ---------------------------------------------------------------------
