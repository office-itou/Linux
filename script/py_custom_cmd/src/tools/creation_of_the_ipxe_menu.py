#!/usr/bin/env python3
# --- Python library ----------------------------------------------------------
import sys


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import (
    InfoCommon,
    check_root,
    generate_ipxe_menu,
    initarg,
)
from common.utils import (
    TimeElapsed,
    debug_logger,
    get_caller_name,
    handle_fatal_error,
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
    if infosystem.debug:
        message_info(_caller, "Debug mode on", omit=True)
    if infosystem.debugout:
        message_info(_caller, "Debugout mode on", omit=True)
    if infosystem.data.exec_user:
        message_info(_caller, f"exec user:{infosystem.data.exec_user}", omit=True)
    if infosystem.data.home_dir:
        message_info(_caller, f"home dir :{infosystem.data.home_dir}", omit=True)
    # -------------------------------------------------------------------------
    return InfoCommon()


# --- main -------------------------------------------------------------------
def main():
    _caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if not check_root(bypass=True):
            return 1
        # --- startup process -------------------------------------------------
        time_elapsed = TimeElapsed()
        message_start(_caller)
        # --- processing block ------------------------------------------------
        initarg("iPXE menu")
        if infosystem.args:
            info_comm = initialize()
            generate_ipxe_menu(info_comm=info_comm)
        # --- termination process ---------------------------------------------
        message_end(_caller, omit=True)
        message_elapsed(_caller, time_elapsed.elapsed(), omit=True)
        # --- exit ------------------------------------------------------------
        print_peak_memory()
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    infosystem.initialize(is_gui=False)
    sys.exit(main())
# --- eof ---------------------------------------------------------------------
