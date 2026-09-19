#!/usr/bin/env python3

"""Test web/file information"""

# --- Python library ----------------------------------------------------------
import inspect
import os
import sys
import time

# --- my library --------------------------------------------------------------
# execusr = os.getenv("SUDO_USER", os.getenv("USER"))
# homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
# libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
# if str(libsdir) not in sys.path:
#    sys.path.append(str(libsdir))
from common.shared.my_shared import InfoCommon
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
    return InfoCommon()


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
            info_comm = initialize()
            print("*" * 80)
            for target in info_comm, info_comm.conf, info_comm.dist, info_comm.mdia:
                for name, obj in inspect.getmembers(target):
                    if not name.startswith("__"):
                        if callable(obj):
                            print(f"{Color.cyan}{name}({type(obj)}){Color.reset}")
                        else:
                            print(f"{Color.yellow}{name}({type(obj)}){Color.reset}")
                print("*" * 80)
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
