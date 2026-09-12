#!/usr/bin/env python3

"""Template"""

# --- Python library ----------------------------------------------------------
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
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    message_warn,
)


@debug_logger
def initialize():
    """Initialize"""
    if infosystem.debug == True:
        message_info(get_caller_name(), "Debug mode on")
    if infosystem.debugout == True:
        message_info(get_caller_name(), "Debugout mode on")
    message_info(get_caller_name(), f"exec user:{infosystem.data.exec_user}")
    message_info(get_caller_name(), f"home dir :{infosystem.data.home_dir}")
    # -------------------------------------------------------------------------
    info_comm = InfoCommon()
    # -------------------------------------------------------------------------
    return info_comm


@debug_logger
def main():
    """Main"""
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        message_warn(
            get_caller_name(),
            "You have standard user privileges.",
        )
        message_warn(
            get_caller_name(),
            f"{Color.underline}Please run this with sudo.",
        )
        return 1
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- startup process -----------------------------------------------------
    message_start(get_caller_name())
    # --- processing block ----------------------------------------------------
    arg_manager = Argument()
    #   arg_manager.add('--add', type=str, help='add args')
    args = arg_manager.parse()
    if args:
        info_comm = initialize()
        print(f"dir(info_comm):{dir(info_comm)}")
        print(f"info_comm.path.conf:{info_comm.conf.json}")
        print(f"info_comm.path.dist:{info_comm.dist.json}")
        print(f"info_comm.path.mdia:{info_comm.mdia.json}")
    # --- termination process -------------------------------------------------
    message_end(get_caller_name())
    # --- elapsed end ---------------------------------------------------------
    end = time.perf_counter()
    elapsed = end - start
    message_elapsed(get_caller_name(), elapsed)
    # --- exit ----------------------------------------------------------------
    return 0
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    sys.exit(main())

# --- eof ---------------------------------------------------------------------
