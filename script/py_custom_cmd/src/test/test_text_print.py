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
from common.utils.my_error import handle_fatal_error
from common.utils.my_mem_usage import print_peak_memory
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
    caller = get_caller_name()
    if infosystem.debug == True:
        message_info(caller, "Debug mode on")
    if infosystem.debugout == True:
        message_info(caller, "Debugout mode on")
    message_info(caller, f"exec user:{infosystem.data.exec_user}")
    message_info(caller, f"home dir :{infosystem.data.home_dir}")
    # -------------------------------------------------------------------------


@debug_logger
def initarg() -> None:
    """Initialize argument"""
    description = "Get web information\n"
    arg_manager = Argument(description)
    list_args = []
    if list_args:
        for line_arg in list_args:
            arg_name = line_arg.pop("arg")
            if isinstance(arg_name, tuple):
                arg_manager.add(*arg_name, **line_arg)
            else:
                arg_manager.add(arg_name, **line_arg)

    infosystem.args = arg_manager.parse()


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
    caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if os.geteuid() != 0:
            print(
                f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n"
                f"{Color.br_yellow} You have standard user privileges. "
                f"{Color.underline}Please run this with sudo.{Color.reset}"
            )
            return 1
        # --- elapsed start----------------------------------------------------
        start = time.perf_counter()
        # --- startup process -------------------------------------------------
        caller = get_caller_name()
        message_start(caller)
        # --- processing block ------------------------------------------------
        initarg()
        if infosystem.args:
            initialize()
            test()
        # --- termination process ---------------------------------------------
        message_end(get_caller_name())
        # --- elapsed end -----------------------------------------------------
        end = time.perf_counter()
        elapsed = end - start
        message_elapsed(caller, elapsed)
        # --- exit ------------------------------------------------------------
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    return_code = main()
    sys.exit(print_peak_memory() or return_code)

# --- eof ---------------------------------------------------------------------
