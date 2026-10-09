#!/usr/bin/env python3
"""main task"""

# --- python library ----------------------------------------------------------
# import os
# import sys
import tkinter as tk

# from pathlib import Path
# --- my library --------------------------------------------------------------
from common.shared import (
    # InfoCommon,
    # check_root,
    # generate_markdown,
    # initarg,
    proc_comp,
    proc_init,
)
from common.utils import (
    debug_logger,
    get_caller_name,
    # handle_fatal_error,
    infosystem,
    # list2markdown,
    # message_elapsed,
    # message_end,
    # message_info,
    # message_start,
    # print_peak_memory,
    # Argument,
    # TimeElapsed,
)


# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# --- definition --------------------------------------------------------------
_ARGS_LIST = [
    {"arg": "--t2j", "help": "Text -> json convert", "action": "store_true"},
    {"arg": "--j2t", "help": "Text -> json convert", "action": "store_true"},
    {"arg": "--md", "help": "json -> Markdown generate", "default": "", "type": "str"},
]


# --- initialize --------------------------------------------------------------
@debug_logger
def initialize():
    """Initialize"""


# --- main --------------------------------------------------------------------
@debug_logger
def main_cui() -> None:
    """main for cui"""


@debug_logger
def main_gui() -> None:
    """main for gui"""
    from gui_main_build import MainWindow

    # --- main window creation ------------------------------------------------
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    # --- binding the termination protocol and starting the main loop ---------
    root.protocol("WM_DELETE_WINDOW", app.quit)
    root.mainloop()
    root.destroy()


if __name__ == "__main__":
    #    try:
    # --- initialization --------------------------------------------------
    _caller = get_caller_name()
    proc_init(description="My tools", list_args=_ARGS_LIST, caller=_caller)
    # --- processing block ------------------------------------------------
    initialize()
    if infosystem.args:
        if not infosystem.is_gui:
            main_cui()
        else:
            main_gui()
    # --- complete --------------------------------------------------------
    proc_comp(caller=_caller)
#    except (OSError, Exception) as e:
#        raise SystemExit from e
# --- eof ---------------------------------------------------------------------
