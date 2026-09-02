# --- Python library ----------------------------------------------------------
import re
import unicodedata

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_colors                import color

# -----------------------------------------------------------------------------
# descript: character count for full-width characters only
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_full_width(text: str) -> int:
    return sum(1 for c in text if unicodedata.east_asian_width(c) in 'FWA')

# -----------------------------------------------------------------------------
# descript: character count for half-width characters only
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_half_width(text: str) -> int:
    return sum(1 for c in text if not unicodedata.east_asian_width(c) in 'FWA')

# -----------------------------------------------------------------------------
# descript: character count for full-width and half-width characters
#   input : text             : input
#   output:                  : unused
#   return: count            : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def count_width(text: str) -> int:
    return count_full_width(text) * 2 + count_half_width(text)

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
def split_by_width(text: str, max_width = 80) -> str:
    lines = []
    current_line = ''
    current_width = 0

    for char in text:
        w = get_char_width(char)
        if current_width + w > max_width:
            lines.append(current_line)
            current_line = char
            current_width = w
        else:
            current_line += char
            current_width += w

    if current_line:
        lines.append(current_line)

    return lines[0]

# -----------------------------------------------------------------------------
# descript: Screen output with character splitting that supports escape characters and full-width/half-width characters.
#   input : text             : input
#   input : max_width        : input
#   output:                  : unused
#   return: lines[0]         : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def eprint(text: str, max_width = 0):
    match_ptrn = r"\x1b\[[0-9;]*[mG]"
    plain_text = re.sub(match_ptrn, '', text)
    plain_len  = count_width(plain_text)
    split_text = text
    split_len  = count_width(split_text)
    escpe_len  = split_len - plain_len
    if max_width > 0 and plain_len > max_width:
        while True:
            split_text = split_by_width(split_text, max_width + escpe_len)
            plain_text = re.sub(match_ptrn, '', split_text)
            plain_len  = count_width(plain_text)
            split_len  = count_width(split_text)
            escpe_len  = split_len - plain_len
            if plain_len <= max_width: break
    print(f"{color.reset}{split_text}{color.reset}")

# -----------------------------------------------------------------------------
# descript: Encoding whitespace characters on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_encode(list) -> str:
    for line in list:
        for key, value in line.items():
            if not isinstance(value, str): continue
            line[key] = value.replace(' ', '%20')
#           line[key] = urllib.parse.quote(value, safe='')
    return list

# -----------------------------------------------------------------------------
# descript: Decoding whitespace characters on a per-list basis
#   input : list             : input
#   output:                  : unused
#   return: list             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def spc_decode(list) -> str:
    for line in list:
        for key, value in line.items():
            if not isinstance(value, str): break
            line[key] = value.replace('%20', ' ')
#           line[key] = urllib.parse.unquote(value)
    return list

# -----------------------------------------------------------------------------
# descript: Omit the intermediate characters.
#   input : text             : input
#   input : max_len          : input
#   input : placeholder      : input
#   output:                  : unused
#   return: text             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def omit_middle(text, max_len=80, placeholder='..') -> str:
    if (plain_len := count_width(re.sub(r"\x1b\[[0-9;]*[mG]", '', text))) <= max_len:
        return text
    front_len  = (max_len - count_width(placeholder)) // 4
    back_len   = (max_len - count_width(placeholder)) - front_len
    front_part = text[:front_len]
    back_part  = text[-back_len:] if back_len > 0 else ""
    return front_part + placeholder + back_part

# -----------------------------------------------------------------------------
# descript: Omit the intermediate characters.
#   input : text             : input
#   input : max_len          : input
#   input : placeholder      : input
#   output:                  : unused
#   return: text             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def generate_comment(modu_name: str, func_name: str, para=''):
    from py_common.my_message import colsize_func, colsize_mode, colsize_mesg
    text_modu = re.sub(r"^[^.]+.", '', modu_name)
    if (colsize_modu := count_width(text_modu)) > 20: colsize_modu = 20
    if (colsize_call := count_width(func_name)) > 20: colsize_call = 20
    colsize_para = colsize_mesg - (colsize_modu + colsize_call + 2)
    text_modu = omit_middle(text_modu, colsize_modu)
    text_func = omit_middle(func_name, colsize_call)
    text_para = omit_middle(f":{para}", colsize_para) if para else ''
    text_retn = f"{text_modu}({text_func}){text_para}"
    return text_retn

# --- eof ---------------------------------------------------------------------
