"""Markdown processing"""

# --- Python library ----------------------------------------------------------
import re

# ⭕ pandas のインポートを完全に削除
# --- my library --------------------------------------------------------------
from my_debug import debug_logger
from my_file_api import file_read, file_write
from my_string import count_width


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
        r"(?:/[a-zA-Z0-9._~:/?#\[\]@!\(&\'()*+,;=\%-]*)?\)"
    )
    _comment_pattern = re.compile(r"^#.*\$")

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
        # ⭕ pandas.DataFrame の代わりに、変換済みの辞書のリストを直接扱う
        _converted_data = _conversion_url(list_data)
        if not _converted_data:
            return ("", "", [])
        # --- 列名 (ヘッダー) のリストを取得 (最初の要素のキー) ---------------------
        _columns = list(_converted_data[0].keys())
        # --- 各列の最大文字幅を計算 (純粋なループ処理で高速化) --------------------
        _col_sizes = {}
        for _name in _columns:
            _cnt_name = count_width(str(_name))

            # 各行の該当列の文字幅の最大値を取得
            _max_size = 0
            for _row_dict in _converted_data:
                _val_str = str(_row_dict.get(_name, ""))
                _w = count_width(_val_str)
                _max_size = max(_max_size, _w)

            _col_sizes[_name] = max(_max_size, _cnt_name)
        # --- header and divider line ---------------------------------------------
        _header = ""
        _align = ""
        for _name in _columns:
            _colsize = _col_sizes[_name]
            _name_str = str(_name)
            _pad_total = _colsize - count_width(_name_str)
            _pad_l = _pad_total // 2
            _pad_r = _pad_total - _pad_l
            _header += f"|{' ' * _pad_l}{_name_str}{' ' * _pad_r}"
            _align += "|:" + "-" * (_colsize - 1)
        _header += "|"
        _align += "|"
        # --- data (iterrows() から通常のループに書き換え) -------------------------
        _md_rows = []
        for _row_dict in _converted_data:
            _row_text = ""
            for _name in _columns:
                _colsize = _col_sizes[_name]
                _val_str = str(_row_dict.get(_name, ""))
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
            if all(re.match(r"^:?-+:?\$", c) for c in _cells):
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
