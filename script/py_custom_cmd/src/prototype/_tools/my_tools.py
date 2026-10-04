#!/usr/bin/env python3
"""main task"""

# --- python library ----------------------------------------------------------
import sys
import tkinter as tk

# --- my library --------------------------------------------------------------
from common.utils import (
    TimeElapsed,
    get_caller_name,
    infosystem,
    message_elapsed,
    message_end,
    message_start,
    print_peak_memory,
)


# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
from gui_main import MainWindow

# from gui_main_build import build_main_window
# from gui_main_event import event_main_window
# from gui_async_handler import async_handler
# from async_io import async_io
# from gui_custom_iso import CustomIsoWindow
# from gui_custom_live import CustomLiveWindow
# from gui_download import DownloadWindow
# from gui_edit import EditWindow
# from gui_ipxe import IpxeWindow
# from gui_markdown import MarkdownWindow
# ruff: isort: on
# --- main --------------------------------------------------------------------
if __name__ == "__main__":
    try:
        # --- initialization ------------------------------------------------------
        infosystem.initialize(is_gui=True)
        _caller = get_caller_name()
        _time_elapsed = TimeElapsed()
        message_start(_caller)
        # --- main window creation ------------------------------------------------
        root: tk.Tk = tk.Tk()
        app: MainWindow = MainWindow(root)
        setattr(root, "app", app)
        # --- binding the termination protocol and starting the main loop ---------
        root.protocol("WM_DELETE_WINDOW", app.event_quit_app)
        root.mainloop()
        # --- complete ------------------------------------------------------------
        message_end(_caller)
        message_elapsed(_caller, _time_elapsed.elapsed(), omit=True)
        print_peak_memory()
        root.destroy()
    except (OSError, Exception) as e:
        sys.exit(e)

# --- eof ---------------------------------------------------------------------
