"""main window"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import InfoCommon
from common.utils import load_ui_definition


# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
from gui_main_event import MainWindowEvent
from gui_main_build import MainWindowBuild
from gui_async_handler import AsyncProcessHandler


# ruff: isort: on
# --- main --------------------------------------------------------------------
class MainWindow(MainWindowEvent, MainWindowBuild):
    def __init__(self, root: tk.Tk) -> None:
        """initialization
        Args:
            root (tk.Tk): the generated window object
        """
        super().__init__(root)
        self.root.geometry("1024x768")
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
            "event_switch_monitor": self.event_switch_monitor,
            "event_toggle_all_checks": self.event_toggle_all_checks,
            "event_quit_app": self.event_quit_app,
            "event_switch_language": self.event_switch_language,
            "event_exec": self.event_exec,
            "event_confirm": self.event_confirm,
            "event_debug_mon": self.event_debug_mon,
            "event_update": self.event_update,
            "event_download": self.event_download,
            "event_markdown": self.event_markdown,
            "event_custom_iso": self.event_custom_iso,
            "event_custom_live": self.event_custom_live,
            "event_ipxe_menu": self.event_ipxe_menu,
            "event_active_select_all": lambda *args: self.event_toggle_all_checks(
                "active_table", "☑"
            ),
            "event_active_deselect_all": lambda *args: self.event_toggle_all_checks(
                "active_table", "☐"
            ),
        }

    def _get_variable_map(self) -> dict[str, tk.Variable]:
        """variables mapping
        Returns:
            dict[str, tk.Variable]: _description_
        """
        # 💡 重複定義を排除し、言語設定とモニター設定の両方を網羅した1つの関数に統合
        return {
            "current_lang_strvar": self.current_lang_strvar,
            "current_monitor_boolvar": self.current_monitor_boolvar,
        }
