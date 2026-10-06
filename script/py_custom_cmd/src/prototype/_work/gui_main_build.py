"""main window"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable
from pathlib import Path
from tkinter import ttk


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import InfoCommon
from common.utils import (
    build_menu_bar,
    debug_logger,
    infosystem,
    load_ui_definition,
)

# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
from gui_main_buttons import MainWindowButtons
from gui_main_status import MainWindowStatus
from gui_main_tables import MainWindowTables

from gui_main_events import MainWindowEvents


# ruff: isort: on
_GEOMETRY = "1024x768"
_UI_FILE_PATH = infosystem.program_path.parent / Path("ui_definition.json")


# --- main --------------------------------------------------------------------
class MainWindow(
    MainWindowEvents,
    MainWindowButtons,
    MainWindowTables,
    MainWindowStatus,
):
    root: tk.Tk
    current_lang_strvar: tk.StringVar
    current_monitor_boolvar: tk.BooleanVar
    current_messages: dict[str, str]
    ui_def: dict

    def __init__(self, root: tk.Tk) -> None:
        super().__init__(root)
        self.root: tk.Tk = root
        self.root.geometry(_GEOMETRY)
        self.ui_def = load_ui_definition(_UI_FILE_PATH)
        self.info_comm: InfoCommon = InfoCommon()
        self.build()

    def _get_command_map(self) -> dict[str, Callable]:
        return {
            "event_open_file": self.event_open_file,
            "event_save_file": self.event_save_file,
            "event_save_file_as": self.event_save_file_as,
            "event_quit_app": self.event_quit_app,
            "event_switch_language": self.event_switch_language,
            "event_switch_monitor": self.event_switch_monitor,
            "event_toggle_all_checks": self.event_toggle_all_checks,
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
        return {
            "current_lang_strvar": self.current_lang_strvar,
            "current_monitor_boolvar": self.current_monitor_boolvar,
        }

    @debug_logger
    def quit(self) -> None:
        for _child in self.root.winfo_children():
            if isinstance(_child, tk.Toplevel) and _child.winfo_exists():
                try:
                    _child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        self.root.quit()

    @debug_logger
    def build(self) -> None:
        """generate screen"""
        for _child in self.root.winfo_children():
            if _child.winfo_exists():
                try:
                    _child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        # --- language settings and message updates ---------------------------
        _lang = self.current_lang_strvar.get()
        self.current_messages = self.ui_def["messages"].get(_lang, {})
        # --- screen title setting --------------------------------------------
        self.root.title(self.current_messages.get("title", "Window"))
        _cmd_map = self._get_command_map()
        _var_map = self._get_variable_map()
        # --- generate menu bar -----------------------------------------------
        build_menu_bar(
            root=self.root,
            menu_data=self.ui_def["menus"],
            messages=self.current_messages,
            commands=_cmd_map,
            variables=_var_map,
        )
        # --- calling the button handling routine -----------------------------
        self._generate_bottom_buttons(cmd_map=_cmd_map)
        # --- generate center mainframe  --------------------------------------
        self._main_frame = ttk.Frame(self.root, padding=10)
        self._main_frame.pack(fill=tk.BOTH, expand=True)
        self._main_frame.columnconfigure(0, weight=1)
        self._main_frame.rowconfigure(0, weight=1)
        self._main_frame.rowconfigure(1, weight=1)
        # --- set row weights to reserve space for the status display area. ---
        self._main_frame.rowconfigure(3, weight=0)
        # --- calling a table operation ---------------------------------------
        self._generate_center_tables()
        # --- call the methods that generate the log monitor and the bar. -----
        self._generate_status_monitor()
