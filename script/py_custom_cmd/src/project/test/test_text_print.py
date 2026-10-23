#!/usr/bin/env python3
"""Test text output"""

# --- Python library ----------------------------------------------------------
import sys


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    Color,
    TimeElapsed,
    debug_logger,
    eprint,
    get_caller_name,
    handle_fatal_error,
    infosystem,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    print_peak_memory,
)
from common.shared import (
    check_root,
    initarg,
)


# ruff: isort: on
# =============================================================================
# --- check -------------------------------------------------------------------
# --- initialize --------------------------------------------------------------
@debug_logger
def initialize():
    """Initialize"""
    _caller = get_caller_name()
    if infosystem.debug:
        message_info(_caller, "Debug mode on")
    if infosystem.debugout:
        message_info(_caller, "Debugout mode on")
    message_info(_caller, f"exec user:{infosystem.exec_user}")
    message_info(_caller, f"home dir :{infosystem.home_dir}")
    # -------------------------------------------------------------------------


# --- procsee -----------------------------------------------------------------
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


# --- main --------------------------------------------------------------------
@debug_logger
def main():
    """Main"""
    _caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if not check_root(bypass=True):
            return 1
        # --- startup process -------------------------------------------------
        time_elapsed = TimeElapsed()
        message_start(_caller)
        # --- processing block ------------------------------------------------
        initarg("Test text output")
        if infosystem.args:
            initialize()
            test()
        # --- termination process ---------------------------------------------
        message_end(_caller)
        message_elapsed(_caller, time_elapsed.elapsed(), omit=True)
        # --- exit ------------------------------------------------------------
        print_peak_memory()
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=True)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    infosystem.initialize(is_gui=False)
    sys.exit(main())
# --- eof ---------------------------------------------------------------------
