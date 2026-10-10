"""gui main build"""

# --- Python library ----------------------------------------------------------
import asyncio
import threading
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk
from types import SimpleNamespace

import aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
from common.shared import InfoCommon
from common.utils import (
    build_menu_bar,
    infosystem,
    load_ui_definition,
)

# --- import module -----------------------------------------------------------
from async_download_handler import AsyncDownload
from async_rsync_handler import AsyncRsync
from async_web_info_handler import AsyncWebInfo
from gui_main_buttons import MainWindowButtons
from gui_main_events import MainWindowEvents
from gui_main_status import MainWindowStatus
from gui_main_tables import MainWindowTables


# --- class and function ------------------------------------------------------
class MainWindow(
    InfoCommon,
    AsyncDownload,
    AsyncRsync,
    AsyncWebInfo,
    MainWindowButtons,
    MainWindowEvents,
    MainWindowStatus,
    MainWindowTables,
):
    _geometry = "1024x768"
    _ui_file = "ui_definition.json"
    _ui_path = infosystem.program_path.parent / _ui_file

    def __init__(self, root: tk.Tk) -> None:
        self.info_comm: InfoCommon = InfoCommon()
        # --- gui -------------------------------------------------------------
        self.root: tk.Tk = root
        self.root.geometry(self._geometry)
        self.ui_def = load_ui_definition(self._ui_path)
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
        self.current_monitor_boolvar: tk.BooleanVar = tk.BooleanVar(value=False)
        self.current_messages = self.ui_def["messages"].get(infosystem.lang, {})
        self._is_switching_lang: bool = False
        # --- async -----------------------------------------------------------
        self.semaphore = SimpleNamespace()
        self.semaphore.infowebs = 5
        self.semaphore.download = 3
        self.semaphore.rsync = 2

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

    def quit(self) -> None:
        for _child in self.root.winfo_children():
            if isinstance(_child, tk.Toplevel) and _child.winfo_exists():
                try:
                    _child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        self.root.quit()

    def build(self) -> None:
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

        threading.Thread(
            target=self.start_async_loop,
            daemon=True,
        ).start()

    async def task(self) -> None:
        self.semaphore.infowebs = asyncio.Semaphore(self.semaphore.infowebs)
        self.semaphore.download = asyncio.Semaphore(self.semaphore.download)
        self.semaphore.rsync = asyncio.Semaphore(self.semaphore.rsync)

        timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
        async with aiohttp.ClientSession(
            timeout=timeout, raise_for_status=False
        ) as session:
            self.session = session

            await asyncio.gather(
                self.get_infowebs(), self.get_downloads(), self.get_rsyncs()
            )

    def start_async_loop(self):
        asyncio.run(self.task())


# --- eof ---------------------------------------------------------------------
