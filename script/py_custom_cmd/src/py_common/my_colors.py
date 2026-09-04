###############################################################################
#
# 	definitions
#
# 	developer   : J.Itou
# 	release     : 2026/09/03
#
# 	history     :
# 	   data    version    developer    point
# 	---------- -------- -------------- ----------------------------------------
# 	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
# from typing import Any, Callable
from dataclasses import dataclass

# --- my library --------------------------------------------------------------
# from py_common.my_config                import infosystem
# from py_common.my_debug                 import debug_logger


# --- escape code -------------------------------------------------------------
@dataclass
class code:
    escape: str = "\x1b"


# --- color code --------------------------------------------------------------
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
@dataclass
class color:
    reset: str = f"{code.escape}[0m"  # reset all attributes
    bold: str = f"{code.escape}[1m"  # (no comments)
    faint: str = f"{code.escape}[2m"  # (no comments)
    italic: str = f"{code.escape}[3m"  # (no comments)
    underline: str = f"{code.escape}[4m"  # set underline
    blink: str = f"{code.escape}[5m"  # (no comments)
    fast_blink: str = f"{code.escape}[6m"  # (no comments)
    reverse: str = f"{code.escape}[7m"  # set reverse display
    conceal: str = f"{code.escape}[8m"  # (no comments)
    strike: str = f"{code.escape}[9m"  # (no comments)
    gothic: str = f"{code.escape}[20m"  # (no comments)
    double_underline: str = f"{code.escape}[21m"  # (no comments)
    normal: str = f"{code.escape}[22m"  # (no comments)
    no_italic: str = f"{code.escape}[23m"  # (no comments)
    no_underline: str = f"{code.escape}[24m"  # reset underline
    no_blink: str = f"{code.escape}[25m"  # (no comments)
    no_reverse: str = f"{code.escape}[27m"  # reset reverse display
    no_conceal: str = f"{code.escape}[28m"  # (no comments)
    no_strike: str = f"{code.escape}[29m"  # (no comments)
    black: str = f"{code.escape}[30m"  # text dark black
    red: str = f"{code.escape}[31m"  # text dark red
    green: str = f"{code.escape}[32m"  # text dark green
    yellow: str = f"{code.escape}[33m"  # text dark yellow
    blue: str = f"{code.escape}[34m"  # text dark blue
    magenta: str = f"{code.escape}[35m"  # text dark purple
    cyan: str = f"{code.escape}[36m"  # text dark light blue
    white: str = f"{code.escape}[37m"  # text dark white
    default: str = f"{code.escape}[39m"  # (no comments)
    bg_black: str = f"{code.escape}[40m"  # text reverse black
    bg_red: str = f"{code.escape}[41m"  # text reverse red
    bg_green: str = f"{code.escape}[42m"  # text reverse green
    bg_yellow: str = f"{code.escape}[43m"  # text reverse yellow
    bg_blue: str = f"{code.escape}[44m"  # text reverse blue
    bg_magenta: str = f"{code.escape}[45m"  # text reverse purple
    bg_cyan: str = f"{code.escape}[46m"  # text reverse light blue
    bg_white: str = f"{code.escape}[47m"  # text reverse white
    bg_default: str = f"{code.escape}[49m"  # (no comments)
    br_black: str = f"{code.escape}[90m"  # text black
    br_red: str = f"{code.escape}[91m"  # text red
    br_green: str = f"{code.escape}[92m"  # text green
    br_yellow: str = f"{code.escape}[93m"  # text yellow
    br_blue: str = f"{code.escape}[94m"  # text blue
    br_magenta: str = f"{code.escape}[95m"  # text purple
    br_cyan: str = f"{code.escape}[96m"  # text light blue
    br_white: str = f"{code.escape}[97m"  # text white
    br_default: str = f"{code.escape}[99m"  # (no comments)


# --- eof ---------------------------------------------------------------------
