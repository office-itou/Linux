"""main window"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable


# --- my library --------------------------------------------------------------
# ruff: isort: off
from my_gui_build_helper import load_ui_definition
from my_shared import InfoCommon

# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
from gui_main_event import MainWindowEvent
from gui_main_build import MainWindowBuild
from async_io import AsyncProcessHandler


# ruff: isort: on
# --- main --------------------------------------------------------------------
class MainWindow(MainWindowEvent, MainWindowBuild):
    def __init__(self, root: tk.Tk) -> None:
        """initialization
        Args:
            root (tk.Tk): the generated window object
        """
        super().__init__(root)
        self.root.geometry("800x600")
        # --- initialization of state variables -------------------------------
        self.ui_def = load_ui_definition("ui_definition.json")
        self.info_comm = InfoCommon()
        # --- instantiation of an asynchronous processing handler -------------
        self.is_running_async = False
        self.async_handler = AsyncProcessHandler(self)
        # --- screen construction ---------------------------------------------
        self.generate_window()

    def _get_command_map(self) -> dict[str, Callable]:
        """commands mapping
        Returns:
            dict[str, Callable]: _description_
        """
        return {
            "event_open_file": self.event_open_file,
            "event_save_file": self.event_save_file,
            "event_save_file_as": self.event_save_file_as,
            "event_quit_app": self.event_quit_app,
            "event_switch_language": self.event_switch_language,
            "event_exec": self.event_exec,
            "event_confirm": self.event_confirm,
            "event_debug_mon": self.event_debug_mon,
            "event_active_select_all": lambda: self.event_toggle_all_checks(
                "active_table", "☑"
            ),
            "event_active_deselect_all": lambda: self.event_toggle_all_checks(
                "active_table", "☐"
            ),
        }

    def _get_variable_map(self) -> dict[str, tk.Variable]:
        """variables mapping
        Returns:
            dict[str, tk.Variable]: _description_
        """
        return {"current_lang_strvar": self.current_lang_strvar}
