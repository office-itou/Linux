###############################################################################
#
#	string processing
#
#	developer   : J.Itou
#	release     : 2026/09/03
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
from typing                             import Any, Callable
import re
import unicodedata

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
#from py_common.my_debug                 import debug_logger
from py_common.my_colors                import color

# -----------------------------------------------------------------------------
# descript: character count for full-width characters only
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_full_width(text: str) -> int:
    plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", '', text)
    return sum(1 for c in plain_text if unicodedata.east_asian_width(c) in 'FWA')

# -----------------------------------------------------------------------------
# descript: character count for half-width characters only
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_half_width(text: str) -> int:
    plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", '', text)
    return sum(1 for c in plain_text if not unicodedata.east_asian_width(c) in 'FWA')

# -----------------------------------------------------------------------------
# descript: character count for full-width and half-width characters
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_width(text: str) -> int:
    plain_text = re.sub(r"\x1b\[[0-9;]*[mG]", '', text)
    return sum(get_char_width(c) for c in plain_text)

# -----------------------------------------------------------------------------
# descript: character count for full-width and half-width characters on the screen
#   input : char             : input
#   output:                  : unused
#   return: length           : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def get_char_width(char: str) -> int:
    return 2 if unicodedata.east_asian_width(char) in ('W', 'F', 'A') else 1

# -----------------------------------------------------------------------------
# descript: character splitting for full-width and half-width characters on the screen
#   input : text             : input
#   input : max_width        : input
#   output:                  : unused
#   return: lines[0]         : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def split_by_width(text: str, target_width: int, from_back: bool = False, omit: bool = False) -> list:
    ansi_pattern = re.compile(r"(\x1b\[[0-9;]*[mG])")
    tokens = ansi_pattern.split(text)
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
                if current_width + w > target_width:
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
            if current_width + w > target_width:
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

# -----------------------------------------------------------------------------
# descript: Screen output with character splitting that supports escape characters and full-width/half-width characters.
#   input : text             : input
#   input : max_width        : input
#   output:                  : unused
#   return: lines[0]         : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def eprint(text: str, max_width: int = 0, wrap: bool = False):
    reset_code = color.reset if color.reset else "\x1b[0m" 
    display_text = text
    if max_width > 0:
        lines = split_by_width(text, max_width)
        if lines:
            display_text = "\n".join(lines) if wrap else lines[0]
    print(f"{reset_code}{display_text}{reset_code}")

# -----------------------------------------------------------------------------
# descript: Encoding whitespace characters on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_encode(list_orig: list) -> list:
    list_conv = []
    for item in list_orig:
        dict_orig = {}
        for key, value in item.items():
            if isinstance(value, str):
                value = value.replace(' ', '%20')
            dict_orig[key] = value
        list_conv.append(dict_orig)
    return list_conv

# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_decode(list_orig: list) -> list:
    list_conv = []
    for item in list_orig:
        dict_orig = {}
        for key, value in item.items():
            if isinstance(value, str):
                value = value.replace('%20', ' ')
            dict_orig[key] = value
        list_conv.append(dict_orig)
    return list_conv

# -----------------------------------------------------------------------------
# descript: Omit the intermediate characters.
#   input : text             : input
#   input : max_len          : input
#   input : placeholder      : input
#   output:                  : unused
#   return: text             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def omit_middle(text: str, max_len: int = 80, placeholder: str = '..') -> str:
    text_orig = str(text)
    if count_width(text) <= max_len:
        return text_orig
    ph_width = count_width(placeholder)
    available_width = max_len - ph_width
    if available_width <= 0:
        return split_by_width(placeholder, max_len, from_back=False, omit=True)
    front_width = available_width // 2
    back_width = available_width - front_width
    front_part = split_by_width(text_orig, front_width, from_back=False, omit=True)
    back_part = split_by_width(text_orig, back_width, from_back=True, omit=True) if back_width > 0 else ""
    return f"{front_part[0]}{placeholder}{back_part[0]}"

# -----------------------------------------------------------------------------
# descript: Omit the intermediate characters.
#   input : text             : input
#   input : max_len          : input
#   input : placeholder      : input
#   output:                  : unused
#   return: text             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def generate_comment(modu_name: str, func_name: str, para: str = '') -> str:
    from py_common.my_message import colsize_func, colsize_mode, colsize_mesg
    text_modu = re.sub(r"^[^.]+.", '', modu_name)
    colsize_modu = min(count_width(text_modu), 20)
    colsize_call = min(count_width(func_name), 20)
    colsize_para = colsize_mesg - (colsize_modu + colsize_call + 2)
    text_modu = omit_middle(text_modu, colsize_modu)
    text_func = omit_middle(func_name, colsize_call)
    text_para = ""
    if para:
        text_para = omit_middle(f":{para}", colsize_para)
    return f"{text_modu}({text_func}){text_para}"

# --- eof ---------------------------------------------------------------------
