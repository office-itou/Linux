"""gui main build"""

# --- Python library ----------------------------------------------------------
import asyncio
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk

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
#from async_base_handler import BaseAsyncProcessHandler
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
    MainWindowButtons,
    MainWindowEvents,
    MainWindowStatus,
    MainWindowTables,
):
    _geometry = "1024x768"
    _ui_file = "ui_definition.json"
    _ui_path = infosystem.program_path.parent / _ui_file

    def __init__(self, root: tk.Tk) -> None:
        # --- common ----------------------------------------------------------
        self.info_comm: InfoCommon = InfoCommon()
        # --- gui -------------------------------------------------------------
        self.root: tk.Tk = root
        self.root.geometry(self._geometry)
        self.ui_def = load_ui_definition(self._ui_path)
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
        self.current_monitor_boolvar: tk.BooleanVar = tk.BooleanVar(value=False)
        self.current_messages = self.ui_def["messages"].get(infosystem.lang, {})
        self._is_switching_lang: bool = False
        # --- debug console ---------------------------------------------------
        self.monitor_window_instance = None
        # --- async -----------------------------------------------------------
        #self.base_async_handler = BaseAsyncProcessHandler(win=self)
        self.web_info_handler = AsyncWebInfo(win=self)
        self.download_handler = AsyncDownload(win=self)
        self.rsync_handler = AsyncRsync(win=self)

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

    async def task(self, target_coro) -> None:
        try:
            timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
            async with aiohttp.ClientSession(
                timeout=timeout, raise_for_status=False
            ) as session:
                self.session = session
                await target_coro
        finally:
            # 処理完了（またはキャンセル）時にフラグやボタン表示を元に戻す共通処理
            self.base_async_handler._on_complete()

    def start_async_loop(self, target_coro):
        asyncio.run(self.task(target_coro))

    def on_handler_complete(self) -> None:
        if hasattr(self, "refresh_exec_button_text"):
            self.refresh_exec_button_text()
        if hasattr(self, "reload_table_data"):
            self.reload_table_data()

    #def start_web_info_process(self) -> None:
    #    if self._prepare_start():
    #        self._process_prefix = "web_info"
    #        coro = self.get_infowebs()
    #        self._start_thread(lambda: self.start_async_loop(coro))

    #def start_download_process(self) -> None:
    #    if self._prepare_start():
    #        self._process_prefix = "download"
    #        coro = self.get_downloads()
    #        self._start_thread(lambda: self.start_async_loop(coro))

    #def start_rsync_process(self) -> None:
    #    if self._prepare_start():
    #        self._process_prefix = "rsync"
    #        coro = self.get_rsyncs()
    #        self._start_thread(lambda: self.start_async_loop(coro))


# --- eof ---------------------------------------------------------------------
