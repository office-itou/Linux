#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import os
import sys
import time
from pathlib import Path

# --- my library --------------------------------------------------------------

execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))

from py_common.my_argument import Argument
from py_common.my_colors import color

# from py_common.my_process              import run_subprocess
# from py_common.my_json                 import load_json, save_json, get_text2json, put_json2text
# from py_common.my_markdown             import list2markdown, spc_encode4md, spc_decode4md
from py_common.my_config import infosystem
from py_common.my_debug import debug_logger
from py_common.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
)
from py_common.my_string import eprint

# from py_common.my_infoweb              import Infoweb, get_webinfo
# from py_common.my_infofile             import Infofile, get_fileinfo
# from py_common.my_infodata             import Infodata, debug_info, get_infodata


# -----------------------------------------------------------------------------
# descript: initialize
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def initialize():
    if infosystem.debug == True:
        message_info(get_caller_name(), "Debug mode on")
    if infosystem.debugout == True:
        message_info(get_caller_name(), "Debugout mode on")


# -----------------------------------------------------------------------------
# descript: test
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def test():
    strhalf = "1234567890123456798012345678901234567980"
    strwide = "１２３４５６７８９０１２３４５６７８９０"
    strmixd = f"12345678901234567980{color.underline}１２３４５６７８９０"
    strslid = f"12345678901234567980 {color.underline}１２３４５６７８９０"

    list_text = [
        f"{color.reset}{strhalf}{color.green}{strhalf}{color.yellow}{strhalf}{color.red}{strhalf}{color.magenta}{strhalf}{color.reset}",
        f"{color.reset}{strwide}{color.green}{strwide}{color.yellow}{strwide}{color.red}{strwide}{color.magenta}{strwide}{color.reset}",
        f"{color.reset}{strhalf}{color.green}{strmixd}{color.yellow}{strwide}{color.red}{strwide}{color.magenta}{strwide}{color.reset}",
        f"{color.reset}{strhalf}{color.green}{strslid}{color.yellow}{strwide}{color.red}{strwide}{color.magenta}{strwide}{color.reset}",
    ]

    for text in list_text:
        eprint(text, infosystem.columns)


# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def main():
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        print(
            f"{color.reset}{color.br_green}{infosystem.program_name}:\n{color.br_yellow} You have standard user privileges. {color.underline}Please run this with sudo.{color.reset}"
        )
        sys.exit(1)
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- startup process -----------------------------------------------------
    message_start(get_caller_name())
    # --- processing block ----------------------------------------------------
    arg_manager = Argument()
    #   arg_manager.add('--add', type=str, help='add args')
    args = arg_manager.parse()
    if args:
        initialize()
        test()
    # --- termination process -------------------------------------------------
    message_end(get_caller_name())
    # --- elapsed end ---------------------------------------------------------
    end = time.perf_counter()
    elapsed = end - start
    message_elapsed(get_caller_name(), elapsed)
    # --- exit ----------------------------------------------------------------
    sys.exit(0)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    main()

# --- eof ---------------------------------------------------------------------
