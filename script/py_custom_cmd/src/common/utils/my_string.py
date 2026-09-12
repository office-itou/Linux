"""String processing"""

# --- Python library ----------------------------------------------------------
import re
import unicodedata

# --- my library --------------------------------------------------------------
from .my_colors import Color


def count_full_width(src_text: str) -> int:
    """Character count for full-width characters only

    Args:
        src_text (str): Source text

    Returns:
        int: Count
    """
    _plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", "", src_text)
    return sum(1 for c in _plain_text if unicodedata.east_asian_width(c) in "FWA")


def count_half_width(src_text: str) -> int:
    """Character count for half-width characters only

    Args:
        src_text (str): Source text

    Returns:
        int: Count
    """
    _plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", "", src_text)
    return sum(1 for c in _plain_text if not unicodedata.east_asian_width(c) in "FWA")


def count_width(src_text: str) -> int:
    """Character count for full-width and half-width characters

    Args:
        src_text (str): Source text

    Returns:
        int: Count
    """
    _plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", "", src_text)
    return sum(get_char_width(c) for c in _plain_text)


def get_char_width(src_char: str) -> int:
    """character count for full-width and half-width characters on the screen

    Args:
        char (str): Source character

    Returns:
        int: Length
    """
    return 2 if unicodedata.east_asian_width(src_char) in ("W", "F", "A") else 1


def split_by_width(
    src_text: str, max_width: int, from_back: bool = False, omit: bool = False
) -> list:
    """Character splitting for full-width and half-width characters on the screen

    Args:
        src_text (str): Source text
        max_width (int): Max width
        from_back (bool, optional): From back. Defaults to False.
        omit (bool, optional): Omit. Defaults to False.

    Returns:
        list: _description_
    """
    _ansi_pattern = re.compile(r"(\x1b\[[0-9;]*[mG])")
    _tokens = _ansi_pattern.split(src_text)
    # --- omit=True -----------------------------------------------------------
    if omit:
        if from_back:
            _tokens.reverse()
        _result_tokens = []
        _current_width = 0
        for _token in _tokens:
            if not _token:
                continue
            if _ansi_pattern.match(_token):
                _result_tokens.append(_token)
                continue
            _chars = list(_token)
            if from_back:
                _chars.reverse()
            for _char in _chars:
                _char_width = get_char_width(_char)
                if _current_width + _char_width > max_width:
                    break
                _result_tokens.append(_char)
                _current_width += _char_width
            else:
                continue
            break
        if from_back:
            _result_tokens.reverse()
        return ["".join(_result_tokens)] if _result_tokens else []
    # --- omit=False ----------------------------------------------------------
    _lines = []
    _current_line = []
    _current_width = 0
    _active_escapes = []
    for _token in _tokens:
        if not _token:
            continue
        if _ansi_pattern.match(_token):
            _current_line.append(_token)
            if _token == "\x1b[0m":
                _active_escapes.clear()
            else:
                _active_escapes.append(_token)
            continue
        for _char in _token:
            _char_width = get_char_width(_char)
            if _current_width + _char_width > max_width:
                if _active_escapes:
                    _current_line.append("\x1b[0m")
                _lines.append("".join(_current_line))
                _current_line = list(_active_escapes) + [_char]
                _current_width = _char_width
            else:
                _current_line.append(_char)
                _current_width += _char_width
    if _current_line:
        _lines.append("".join(_current_line))
    return _lines


def eprint(src_text: str, max_width: int = 0, wrap: bool = False):
    """Screen output with character splitting that supports escape characters and full-width/half-width characters.

    Args:
        src_text (str): Source text
        max_width (int, optional): Max width. Defaults to 0.
        wrap (bool, optional): Wrap. Defaults to False.
    """
    _reset_code = Color.reset if Color.reset else "\x1b[0m"
    _display_text = src_text
    if max_width > 0 and (_lines := split_by_width(src_text, max_width)):
        _display_text = "\n".join(_lines) if wrap else _lines[0]
    print(f"{_reset_code}{_display_text}{_reset_code}")


def omit_middle(src_text: str, max_len: int = 80, placeholder: str = "..") -> str:
    """Omit the intermediate characters.

    Args:
        src_text (str): Source text
        max_len (int, optional): Max length. Defaults to 80.
        placeholder (str, optional): Placeholder. Defaults to "..".

    Returns:
        str: _description_
    """
    _orig_text = str(src_text)
    if count_width(src_text) <= max_len:
        return _orig_text
    _ph_width = count_width(placeholder)
    _available_width = max_len - _ph_width
    if _available_width <= 0:
        return split_by_width(placeholder, max_len, from_back=False, omit=True)
    _front_width = _available_width // 2
    _back_width = _available_width - _front_width
    _front_part = split_by_width(_orig_text, _front_width, from_back=False, omit=True)
    _back_part = (
        split_by_width(_orig_text, _back_width, from_back=True, omit=True)
        if _back_width > 0
        else ""
    )
    return f"{_front_part[0]}{placeholder}{_back_part[0]}"


# --- eof ---------------------------------------------------------------------
