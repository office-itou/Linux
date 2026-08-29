#!/usr/bin/env python3
# encoding: utf-8

#import os
#topdir = os.getcwd()

topdir = "/home/master/linux/script/py_custom_cmd/src"
import sys
sys.path.append(topdir)

import shutil
import re

from py_common.my_colors import color
from py_common.my_string import eprint, count_full_width, count_half_width, count_width

## -----------------------------------------------------------------------------
size = shutil.get_terminal_size().columns
strhalf = "1234567890123456798012345678901234567980"
strwide = "１２３４５６７８９０１２３４５６７８９０"
strmixd = "12345678901234567980１２３４５６７８９０"
strslid = "12345678901234567980 １２３４５６７８９０"

#print(count_full_width(strwide))
#print(count_half_width(strwide))
#print(count_width(strwide))

list_text = [
    f"{color.reset}{strhalf}{color.green}{strhalf}{color.yellow}{strhalf}{color.red}{strhalf}{color.magenta}{strhalf}{color.reset}",
    f"{color.reset}{strwide}{color.green}{strwide}{color.yellow}{strwide}{color.red}{strwide}{color.magenta}{strwide}{color.reset}",
    f"{color.reset}{strhalf}{color.green}{strmixd}{color.yellow}{strwide}{color.red}{strwide}{color.magenta}{strwide}{color.reset}",
    f"{color.reset}{strhalf}{color.green}{strslid}{color.yellow}{strwide}{color.red}{strwide}{color.magenta}{strwide}{color.reset}"
]

for text in list_text:
#   text = re.sub(r"\x1b\[[0-9;]*[mG]", '', text)
#   print(count_full_width(text))
#   print(count_half_width(text))
#   print(count_width(text))
    eprint(text, size)
