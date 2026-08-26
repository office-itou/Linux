#!/usr/bin/env python3
# encoding: utf-8

#import os
#topdir = os.getcwd()

topdir = "/home/master/linux/script/py_custom_cmd/src"
import sys
sys.path.append(topdir)

## -----------------------------------------------------------------------------
import shutil
import pprint
#import io
import re
#from contextlib import redirect_stdout
import unicodedata

## -----------------------------------------------------------------------------
from py_common          import config
from py_common.colors   import color
from py_common.debug    import debugout

def count_full_width(text):
    return sum(1 for c in text if unicodedata.east_asian_width(c) in 'FWA')

def count_half_width(text):
    return sum(1 for c in text if not unicodedata.east_asian_width(c) in 'FWA')

def get_char_width(char):
  return 2 if unicodedata.east_asian_width(char) in ("W", "F", "A") else 1

def split_by_width(text, max_width):
    lines = []
    current_line = ""
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

def debug_printf(text: str, size = 80):
    escape_cd = r"\x1b"
    ptn_escpe = r"\x1b\[[0-9;]*[mG]"
    txt_split = text
    txt_plain = re.sub(ptn_escpe, "", text)
    len_split = count_half_width(txt_split) + count_full_width(txt_split) * 2
    len_plain = count_half_width(txt_plain) + count_full_width(txt_plain) * 2
    len_escpe = len_split - len_plain
    if len(txt_plain) > size:               # txt_plain text length > console width
        while True:
            txt_split = split_by_width(txt_split, size + len_escpe)
            txt_plain = re.sub(ptn_escpe, "", txt_split)
            len_split = count_half_width(txt_split) + count_full_width(txt_split) * 2
            len_plain = count_half_width(txt_plain) + count_full_width(txt_plain) * 2
            len_escpe = len_split - len_plain
            if len_plain <= size: break

    print(f"{color.reset}{txt_split}{color.reset}")
    return

size = shutil.get_terminal_size().columns
#                                                                                                                                                    1                                                                                                                             2
#                               1         2         3         4                      5         6         7         8                       9         0         1         2                    3         4         5         6                        7         8         9         0
text1 = f"{color.reset}1234567890123456798012345678901234567980{color.green}1234567890123456798012345678901234567980{color.yellow}1234567890123456798012345678901234567980{color.red}1234567890123456798012345678901234567980{color.magenta}1234567890123456798012345678901234567980{color.reset}"
text2 = f"{color.reset}１２３４５６７８９０１２３４５６７８９０{color.green}１２３４５６７８９０１２３４５６７８９０{color.yellow}１２３４５６７８９０１２３４５６７８９０{color.red}１２３４５６７８９０１２３４５６７８９０{color.magenta}１２３４５６７８９０１２３４５６７８９０{color.reset}"
text3 = f"{color.reset}1234567890123456798012345678901234567980{color.green}12345678901234567980１２３４５６７８９０{color.yellow}１２３４５６７８９０１２３４５６７８９０{color.red}１２３４５６７８９０１２３４５６７８９０{color.magenta}１２３４５６７８９０１２３４５６７８９０{color.reset}"

debug_printf(text1)
debug_printf(text2)
debug_printf(text3)

sys.exit(0)

print(len(text1))
print(len(text2))
pprint.pprint(text1, width=10)
pprint.pprint(text2, width=10)

string1=str(text1)
string2=str(text2)
print(len(string1))
print(len(string2))
pprint.pprint(string1, width=10)
pprint.pprint(string2, width=10)

txt_plain1 = re.sub(r"\x1b\[[0-9;]*[mG]", "", text1)
txt_plain2 = re.sub(r"\x1b\[[0-9;]*[mG]", "", text2)
print(len(txt_plain1))
print(len(txt_plain2))

pprint.pprint(txt_plain1, width=10)
pprint.pprint(txt_plain2, width=10)

