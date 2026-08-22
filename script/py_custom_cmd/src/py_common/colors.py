#!/usr/bin/env python3
# encoding: utf-8

import dataclasses

@dataclasses.dataclass
class color:
    reset           : str = "\033[0m"   # reset all attributes
    bold            : str = "\033[1m"   #
    faint           : str = "\033[2m"   #
    italic          : str = "\033[3m"   #
    underline       : str = "\033[4m"   # set underline
    blink           : str = "\033[5m"   #
    fast_blink      : str = "\033[6m"   #
    reverse         : str = "\033[7m"   # set reverse display
    conceal         : str = "\033[8m"   #
    strike          : str = "\033[9m"   #
    gothic          : str = "\033[20m"  #
    double_underline: str = "\033[21m"  #
    normal          : str = "\033[22m"  #
    no_italic       : str = "\033[23m"  #
    no_underline    : str = "\033[24m"  # reset underline
    no_blink        : str = "\033[25m"  #
    no_reverse      : str = "\033[27m"  # reset reverse display
    no_conceal      : str = "\033[28m"  #
    no_strike       : str = "\033[29m"  #
    black           : str = "\033[30m"  # text dark black
    red             : str = "\033[31m"  # text dark red
    green           : str = "\033[32m"  # text dark green
    yellow          : str = "\033[33m"  # text dark yellow
    blue            : str = "\033[34m"  # text dark blue
    magenta         : str = "\033[35m"  # text dark purple
    cyan            : str = "\033[36m"  # text dark light blue
    white           : str = "\033[37m"  # text dark white
    default         : str = "\033[39m"  #
    bg_black        : str = "\033[40m"  # text reverse black
    bg_red          : str = "\033[41m"  # text reverse red
    bg_green        : str = "\033[42m"  # text reverse green
    bg_yellow       : str = "\033[43m"  # text reverse yellow
    bg_blue         : str = "\033[44m"  # text reverse blue
    bg_magenta      : str = "\033[45m"  # text reverse purple
    bg_cyan         : str = "\033[46m"  # text reverse light blue
    bg_white        : str = "\033[47m"  # text reverse white
    bg_default      : str = "\033[49m"  #
    br_black        : str = "\033[90m"  # text black
    br_red          : str = "\033[91m"  # text red
    br_green        : str = "\033[92m"  # text green
    br_yellow       : str = "\033[93m"  # text yellow
    br_blue         : str = "\033[94m"  # text blue
    br_magenta      : str = "\033[95m"  # text purple
    br_cyan         : str = "\033[96m"  # text light blue
    br_white        : str = "\033[97m"  # text white
    br_default      : str = "\033[99m"  #
