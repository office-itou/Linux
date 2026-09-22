#!/usr/bin/env python3

"""Test text output"""

# --- Python library ----------------------------------------------------------
import os
import sys

from my_argument import Argument
from my_colors import Color

# --- my library --------------------------------------------------------------
from my_config import infosystem
from my_debug import debug_logger
from my_error import handle_fatal_error
from my_mem_usage import print_peak_memory
from my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
)
from my_string import eprint
from my_time import TimeElapsed


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
        f"{strhalf}{Color.green}{strhalf}{Color.yellow}{strhalf}{Color.red}{strhalf}{Color.magenta}{strhalf}",
        f"{strwide}{Color.green}{strwide}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}",
        f"{strhalf}{Color.green}{strmixd}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}",
        f"{strhalf}{Color.green}{strslid}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}",
    ]

    for text in list_text:
        eprint(f"{Color.reset}{text}{text}{Color.reset}", infosystem.columns)
    for text in list_text:
        eprint(f"{Color.reset}{text}{text}{Color.reset}", infosystem.columns, wrap=True)


debug_logger
def check_root(bypass: bool = False) -> bool:
    if bypass or os.geteuid() == 0:
        return True
    print(
        f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n"
        f"{Color.br_yellow} You have standard user privileges. "
        f"{Color.underline}Please run this with sudo.{Color.reset}"
    )
    return False


def main():
    """Main"""
    caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if not check_root(True):
            return 1
        # --- elapsed start----------------------------------------------------
        time_elapsed = TimeElapsed()
        # --- startup process -------------------------------------------------
        message_start(caller)
        # --- processing block ------------------------------------------------
        initarg()
        if infosystem.args:
            initialize()
            test()
        # --- termination process ---------------------------------------------
        message_end(get_caller_name())
        # --- elapsed end -----------------------------------------------------
        message_elapsed(caller, time_elapsed.elapsed(), omit=True)
        # --- exit ------------------------------------------------------------
        print_peak_memory()
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e, omit=True)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    infosystem.initialize(is_gui=False)
    sys.exit(main())

# --- eof ---------------------------------------------------------------------
