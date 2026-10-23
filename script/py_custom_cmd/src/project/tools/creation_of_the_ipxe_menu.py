#!/usr/bin/env python3
# --- Python library ----------------------------------------------------------
import os
import sys


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import (
    InfoCommon,
    check_root,
    generate_ipxe_menu,
)
from common.utils import (
    Argument,
    TimeElapsed,
    debug_logger,
    get_caller_name,
    infosystem,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    print_peak_memory,
)


# ruff: isort: on
# --- initialize -------------------------------------------------------------
@debug_logger
def initialize():
    """Initialize"""
    _caller = get_caller_name()
    if infosystem.debugout:
        for _message in (
            f"GUI mode : {getattr(infosystem, 'is_gui', '')}",
            f"Debug    : {getattr(infosystem, 'debug', '')}",
            f"Debugout : {getattr(infosystem, 'debugout', '')}",
            f"exec user: {getattr(infosystem.data, 'exec_user', '')}",
            f"home dir : {getattr(infosystem.data, 'home_dir', '')}",
        ):
            message_info(_caller, _message, omit=True)
    # -------------------------------------------------------------------------
    return InfoCommon()


# --- main -------------------------------------------------------------------
def main():
    _caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if not check_root(bypass=True):
            return 1
        # --- initialization --------------------------------------------------
        Argument("iPXE menu")
        _gui = (
            bool(os.getenv("DISPLAY"))
            if not getattr(infosystem.args, "force_cui", True)
            else False
        )
        infosystem.initialize(is_gui=_gui)
        _caller = get_caller_name()
        _time_elapsed = TimeElapsed()
        message_start(_caller)
        # --- processing block ------------------------------------------------
        initialize()
        if infosystem.args:
            info_comm = initialize()
            generate_ipxe_menu(info_comm=info_comm)
        # --- complete --------------------------------------------------------
        message_end(_caller)
        message_elapsed(_caller, _time_elapsed.elapsed(), omit=True)
        print_peak_memory()
    except (OSError, Exception) as e:
        raise SystemExit from e


if __name__ == "__main__":
    sys.exit(main())
# --- eof ---------------------------------------------------------------------
