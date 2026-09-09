#!/usr/bin/env python3

"""Test text output"""

# --- Python library ----------------------------------------------------------
import os
import sys
import time
from pathlib import Path

# --- my library --------------------------------------------------------------
execusr = os.getenv("SUDO_USER", os.getenv("USER"))
homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
if str(libsdir) not in sys.path:
    sys.path.append(str(libsdir))

from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
)
from common.utils.my_string import eprint


@debug_logger
def initialize():
    """Initialize"""
    if infosystem.debug == True:
        message_info(get_caller_name(), "Debug mode on")
    if infosystem.debugout == True:
        message_info(get_caller_name(), "Debugout mode on")


@debug_logger
def test():
    """Test"""
    strhalf = "1234567890123456798012345678901234567980"
    strwide = "１２３４５６７８９０１２３４５６７８９０"
    strmixd = f"12345678901234567980{Color.underline}１２３４５６７８９０"
    strslid = f"12345678901234567980 {Color.underline}１２３４５６７８９０"

    list_text = [
        f"{Color.reset}{strhalf}{Color.green}{strhalf}{Color.yellow}{strhalf}{Color.red}{strhalf}{Color.magenta}{strhalf}{Color.reset}",
        f"{Color.reset}{strwide}{Color.green}{strwide}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}{Color.reset}",
        f"{Color.reset}{strhalf}{Color.green}{strmixd}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}{Color.reset}",
        f"{Color.reset}{strhalf}{Color.green}{strslid}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}{Color.reset}",
    ]

    for text in list_text:
        eprint(text, infosystem.columns)


@debug_logger
def main():
    """Main"""
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        print(
            f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n{Color.br_yellow} You have standard user privileges. {Color.underline}Please run this with sudo.{Color.reset}"
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
