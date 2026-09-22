# --- Python library ----------------------------------------------------------
# import re
import tkinter as tk

# from collections.abc import Callable
# from tkinter import filedialog, messagebox, ttk


# from typing import Any
# ruff: isort: off
# --- my library --------------------------------------------------------------
# from my_colors import Color
from my_config import infosystem
from my_debug import debug_logger

# from my_error import handle_fatal_error
# from my_gui_buttons import create_action_button
from my_gui_log_monitor import DebugLogWindow
from my_mem_usage import print_peak_memory
from my_message import (
    get_caller_name,
    message_elapsed,
    # message_end,
    # message_info,
    # message_start,
)
from my_string import eprint, set_gui_log_window

# from my_string import eprint
from my_time import TimeElapsed

# ruff: isort: on
# ruff: isort: off
# --- my modules --------------------------------------------------------------
from functions import test

# from messages import MESSAGES
from ui_main_window import MainWindowUI


# ruff: isort: on
# -----------------------------------------------------------------------------
class MainWindow(MainWindowUI):
    def __init__(self, root: tk.Tk) -> None:
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
        super().__init__()
        self.root: tk.Tk = root
        self.init_main_window()

    # --- menu event ----------------------------------------------------------
    @debug_logger
    def event_open_file(self, event=None) -> None:
        eprint("開く")

    @debug_logger
    def event_save_file(self, event=None) -> None:
        eprint("保存")

    @debug_logger
    def event_save_file_as(self, event=None) -> None:
        eprint("名前を付けて保存")

    @debug_logger
    def event_quit_app(self, event=None) -> None:
        eprint("終了")
        infosystem.log_window_active = False
        set_gui_log_window(None)
        for child in self.root.winfo_children():
            if isinstance(child, tk.Toplevel) and child.winfo_exists():
                try:
                    child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        self.root.quit()

    # --- radio button --------------------------------------------------------
    @debug_logger
    def event_switch_language(self, event=None) -> None:
        eprint("言語")
        self.create_main_window()

    # --- button event --------------------------------------------------------
    @debug_logger
    def event_exec(self, event=None) -> None:
        eprint("実行")
        self.log_win = DebugLogWindow(self.root)
        set_gui_log_window(self.log_win)
        test()


# -----------------------------------------------------------------------------
if __name__ == "__main__":
    infosystem.initialize(is_gui=True)
    caller = get_caller_name()
    time_elapsed = TimeElapsed()
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    root.protocol("WM_DELETE_WINDOW", app.event_quit_app)
    root.mainloop()
    message_elapsed(caller, time_elapsed.elapsed(), omit=True)
    print_peak_memory()
    root.destroy()
