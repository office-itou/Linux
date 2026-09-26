"""main task"""

# --- python library ----------------------------------------------------------
import tkinter as tk


# --- my library --------------------------------------------------------------
# ruff: isort: off
from my_config import infosystem
from my_mem_usage import print_peak_memory
from my_message import get_caller_name, message_elapsed, message_end, message_start
from my_time import TimeElapsed

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
    # --- initialization ------------------------------------------------------
    infosystem.initialize(is_gui=True)
    caller = get_caller_name()
    time_elapsed = TimeElapsed()
    message_start(caller)
    # --- main window creation ------------------------------------------------
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    # --- binding the termination protocol and starting the main loop ---------
    root.protocol("WM_DELETE_WINDOW", app.event_quit_app)
    root.mainloop()
    # --- complete ------------------------------------------------------------
    message_end(caller)
    message_elapsed(caller, time_elapsed.elapsed(), omit=True)
    print_peak_memory()
    root.destroy()
# --- eof ---------------------------------------------------------------------
