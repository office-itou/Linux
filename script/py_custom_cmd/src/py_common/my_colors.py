#!/usr/bin/env python3
# encoding: utf-8

# --- Python library ----------------------------------------------------------
import dataclasses

# --- my library --------------------------------------------------------------

# --- color code --------------------------------------------------------------
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
@dataclasses.dataclass
class color:
    reset           : str = "\x1b[0m"   # reset all attributes
    bold            : str = "\x1b[1m"   #
    faint           : str = "\x1b[2m"   #
    italic          : str = "\x1b[3m"   #
    underline       : str = "\x1b[4m"   # set underline
    blink           : str = "\x1b[5m"   #
    fast_blink      : str = "\x1b[6m"   #
    reverse         : str = "\x1b[7m"   # set reverse display
    conceal         : str = "\x1b[8m"   #
    strike          : str = "\x1b[9m"   #
    gothic          : str = "\x1b[20m"  #
    double_underline: str = "\x1b[21m"  #
    normal          : str = "\x1b[22m"  #
    no_italic       : str = "\x1b[23m"  #
    no_underline    : str = "\x1b[24m"  # reset underline
    no_blink        : str = "\x1b[25m"  #
    no_reverse      : str = "\x1b[27m"  # reset reverse display
    no_conceal      : str = "\x1b[28m"  #
    no_strike       : str = "\x1b[29m"  #
    black           : str = "\x1b[30m"  # text dark black
    red             : str = "\x1b[31m"  # text dark red
    green           : str = "\x1b[32m"  # text dark green
    yellow          : str = "\x1b[33m"  # text dark yellow
    blue            : str = "\x1b[34m"  # text dark blue
    magenta         : str = "\x1b[35m"  # text dark purple
    cyan            : str = "\x1b[36m"  # text dark light blue
    white           : str = "\x1b[37m"  # text dark white
    default         : str = "\x1b[39m"  #
    bg_black        : str = "\x1b[40m"  # text reverse black
    bg_red          : str = "\x1b[41m"  # text reverse red
    bg_green        : str = "\x1b[42m"  # text reverse green
    bg_yellow       : str = "\x1b[43m"  # text reverse yellow
    bg_blue         : str = "\x1b[44m"  # text reverse blue
    bg_magenta      : str = "\x1b[45m"  # text reverse purple
    bg_cyan         : str = "\x1b[46m"  # text reverse light blue
    bg_white        : str = "\x1b[47m"  # text reverse white
    bg_default      : str = "\x1b[49m"  #
    br_black        : str = "\x1b[90m"  # text black
    br_red          : str = "\x1b[91m"  # text red
    br_green        : str = "\x1b[92m"  # text green
    br_yellow       : str = "\x1b[93m"  # text yellow
    br_blue         : str = "\x1b[94m"  # text blue
    br_magenta      : str = "\x1b[95m"  # text purple
    br_cyan         : str = "\x1b[96m"  # text light blue
    br_white        : str = "\x1b[97m"  # text white
    br_default      : str = "\x1b[99m"  #

# --- eof ---------------------------------------------------------------------
