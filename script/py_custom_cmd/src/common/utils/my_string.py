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
    plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", "", src_text)
    return sum(1 for c in plain_text if unicodedata.east_asian_width(c) in "FWA")


def count_half_width(src_text: str) -> int:
    """Character count for half-width characters only

    Args:
        src_text (str): Source text

    Returns:
        int: Count
    """
    plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", "", src_text)
    return sum(1 for c in plain_text if not unicodedata.east_asian_width(c) in "FWA")


def count_width(src_text: str) -> int:
    """Character count for full-width and half-width characters

    Args:
        src_text (str): Source text

    Returns:
        int: Count
    """
    plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", "", src_text)
    return sum(get_char_width(c) for c in plain_text)


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
    ansi_pattern = re.compile(r"(\x1b\[[0-9;]*[mG])")
    tokens = ansi_pattern.split(src_text)
    # --- omit=True -----------------------------------------------------------
    if omit:
        if from_back:
            tokens.reverse()
        result_tokens = []
        current_width = 0
        for token in tokens:
            if not token:
                continue
            if ansi_pattern.match(token):
                result_tokens.append(token)
                continue
            chars = list(token)
            if from_back:
                chars.reverse()
            for char in chars:
                w = get_char_width(char)
                if current_width + w > max_width:
                    break
                result_tokens.append(char)
                current_width += w
            else:
                continue
            break
        if from_back:
            result_tokens.reverse()
        return ["".join(result_tokens)] if result_tokens else []
    # --- omit=False ----------------------------------------------------------
    lines = []
    current_line = []
    current_width = 0
    active_escapes = []
    for token in tokens:
        if not token:
            continue
        if ansi_pattern.match(token):
            current_line.append(token)
            if token == "\x1b[0m":
                active_escapes.clear()
            else:
                active_escapes.append(token)
            continue
        for char in token:
            w = get_char_width(char)
            if current_width + w > max_width:
                if active_escapes:
                    current_line.append("\x1b[0m")
                lines.append("".join(current_line))
                current_line = list(active_escapes) + [char]
                current_width = w
            else:
                current_line.append(char)
                current_width += w
    if current_line:
        lines.append("".join(current_line))
    return lines


def eprint(src_text: str, max_width: int = 0, wrap: bool = False):
    """Screen output with character splitting that supports escape characters and full-width/half-width characters.

    Args:
        src_text (str): Source text
        max_width (int, optional): Max width. Defaults to 0.
        wrap (bool, optional): Wrap. Defaults to False.
    """
    reset_code = Color.reset if Color.reset else "\x1b[0m"
    display_text = src_text
    if max_width > 0:
        lines = split_by_width(src_text, max_width)
        if lines:
            display_text = "\n".join(lines) if wrap else lines[0]
    print(f"{reset_code}{display_text}{reset_code}")


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
            conv_dict[key] = value
        conv_list.append(conv_dict)
    return conv_list


def omit_middle(src_text: str, max_len: int = 80, placeholder: str = "..") -> str:
    """Omit the intermediate characters.

    Args:
        src_text (str): Source text
        max_len (int, optional): Max length. Defaults to 80.
        placeholder (str, optional): Placeholder. Defaults to "..".

    Returns:
        str: _description_
    """
    text_orig = str(src_text)
    if count_width(src_text) <= max_len:
        return text_orig
    ph_width = count_width(placeholder)
    available_width = max_len - ph_width
    if available_width <= 0:
        return split_by_width(placeholder, max_len, from_back=False, omit=True)
    front_width = available_width // 2
    back_width = available_width - front_width
    front_part = split_by_width(text_orig, front_width, from_back=False, omit=True)
    back_part = (
        split_by_width(text_orig, back_width, from_back=True, omit=True)
        if back_width > 0
        else ""
    )
    return f"{front_part[0]}{placeholder}{back_part[0]}"


def generate_comment(modu_name: str, func_name: str, para: str = "") -> str:
    """Omit the intermediate characters.

    Args:
        modu_name (str): Module name
        func_name (str): Function name
        para (str, optional): Parameter. Defaults to "".

    Returns:
        str: Comment message
    """
    from .my_message import colsize_mesg

    front_part = ""
    colsize_para = colsize_mesg
    if modu_name:
        text_modu = re.sub(r"^[^.]+.", "", modu_name)
        colsize_modu = min(count_width(text_modu), 20)
        colsize_call = min(count_width(func_name), 20)
        colsize_para -= colsize_modu + colsize_call + 2
        text_modu = omit_middle(text_modu, colsize_modu)
        text_func = omit_middle(func_name, colsize_call)
        front_part = f"{text_modu}({text_func}):"
    text_para = ""
    if para:
        text_para = omit_middle(f"{para}", colsize_para)
    return f"{front_part}{text_para}"


# --- eof ---------------------------------------------------------------------
