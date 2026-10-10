"""main window event"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import (
    InfoCommon,
    generate_ipxe_menu,
    generate_markdown,
)
from common.shared.my_distribution_dat import ORDERED_DISTRIBUTIONS
from common.utils import (
    DebugLogWindow,
    debug_logger,
    infosystem,
    list2markdown,
    set_gui_log_window,
)


# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
# from gui_async_handler import AsyncProcessHandler
#from async_base_handler import BaseAsyncProcessHandler
#from async_download_handler import DownloadAsyncHandler
#from async_rsync_handler import RsyncAsyncHandler
#from async_web_info_handler import WebInfoAsyncHandler


# ruff: isort: on
# --- main --------------------------------------------------------------------
class MainWindowEvents:
    root: tk.Tk
    current_lang_strvar: tk.StringVar
    current_monitor_boolvar: tk.BooleanVar
    _is_switching_lang: bool
    quit: Callable
    info_comm: InfoCommon
    build: Callable
    datas_map: dict
    reload_table_data: Callable
    # async_handler: AsyncProcessHandler
    # async_base_handler: BaseAsyncProcessHandler
    # async_download_handler: DownloadAsyncHandler
    # async_rsync_handler: RsyncAsyncHandler
    # async_web_info_handler: WebInfoAsyncHandler
    append_log: Callable
    current_messages: dict[str, str]
    ui_def: dict
    monitor_window_instance: DebugLogWindow = None

    cancel_async_process: Callable
    start_web_info_process: Callable
    start_async_download_process: Callable

    # def __init__(self, root: tk.Tk) -> None:
    #    self.root: tk.Tk = root
    #    self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
    #    self.current_monitor_boolvar: tk.BooleanVar = tk.BooleanVar(value=False)
    #    self._is_switching_lang = False

    # --- menu: file ----------------------------------------------------------
    @debug_logger
    def event_open_file(self) -> None:
        """open event"""

    @debug_logger
    def event_save_file(self) -> None:
        """save event"""
        self.info_comm.dist.save(self.info_comm.dist_json)
        self.info_comm.mdia.save(self.info_comm.mdia_json)

    @debug_logger
    def event_save_file_as(self) -> None:
        """save as event"""

    @debug_logger
    def event_quit_app(self) -> None:
        """quit event"""
        self.quit()

    @debug_logger
    def event_switch_language(self) -> None:
        """switch language event"""
        if self._is_switching_lang:
            return
        try:
            self._is_switching_lang = True
            self.build()
        finally:
            self._is_switching_lang = False

    @debug_logger
    def event_switch_monitor(self) -> None:
        """switch monitor event"""
        _btn_label = self.current_messages.get("btn_debug", "Monitor")
        _is_on = self.current_monitor_boolvar.get()
        if _is_on:
            if (
                self.monitor_window_instance is None
                or not hasattr(self.monitor_window_instance, "win")
                or not self.monitor_window_instance.win.winfo_exists()
            ):
                _message = self.current_messages.get(
                    "msg_info_processing", "Processing..."
                )
                self.append_log(f"{_btn_label}: {_message}")
                self.monitor_window_instance = DebugLogWindow(self.root)
                self.monitor_window_instance.saved_debug = infosystem.debug
                self.monitor_window_instance.saved_debugout = infosystem.debugout
                infosystem.debug = True
                infosystem.debugout = True
                infosystem.log_window_active = True
                # self.monitor_window_instance = DebugLogWindow(self.root)
                set_gui_log_window(self.monitor_window_instance)
        else:
            infosystem.log_window_active = False
            if self.monitor_window_instance is not None:
                if (
                    hasattr(self.monitor_window_instance, "win")
                    and self.monitor_window_instance.win.winfo_exists()
                ):
                    try:
                        self.monitor_window_instance.on_close()
                    except Exception:
                        pass
            self.monitor_window_instance = None
            set_gui_log_window(None)
            _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
            self.append_log(f"{_btn_label}: {_message}")

    @debug_logger
    def event_toggle_all_checks(
        self, table_id: str = "active_table", check_char: str = "☑"
    ) -> None:
        """Checkbox "Select All" / "Deselect All" event"""
        if not isinstance(table_id, str):
            table_id = "active_table"
        if not hasattr(self, "main_center_table_widgets") or not hasattr(
            self, "datas_map"
        ):
            return
        target_data = self.datas_map.get(table_id, [])
        if not target_data:
            return
        target_flag_value = check_char == "☑"
        for item in target_data:
            if getattr(item, "entry_name", "") != "menu-entry":
                item.target_flag = "o" if target_flag_value else "x"
        if hasattr(self, "reload_table_data"):
            self.reload_table_data()

    @debug_logger
    def event_exec(self) -> None:
        """exec event"""
        _btn_label = self.current_messages.get("btn_exec", "Run")
        _message = self.current_messages.get("msg_info_processing", "Processing...")
        self.append_log(f"{_btn_label}: {_message}")
        _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        self.append_log(f"{_btn_label}: {_message}")

    @debug_logger
    def event_confirm(self) -> None:
        """confirm event"""
        _btn_label = self.current_messages.get("btn_confirm", "✅ Confirm")
        _message = self.current_messages.get("msg_info_processing", "Processing...")
        self.append_log(f"{_btn_label}: {_message}")
        _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        self.append_log(f"{_btn_label}: {_message}")

    @debug_logger
    def event_debug_mon(self) -> None:
        """debug monitor event"""
        _btn_label = self.current_messages.get("btn_debug", "Monitor")
        _message = self.current_messages.get("msg_info_processing", "Processing...")
        self.append_log(f"{_btn_label}: {_message}")
        self.current_monitor_boolvar.set(not self.current_monitor_boolvar.get())
        self.event_switch_monitor()
        _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        self.append_log(f"{_btn_label}: {_message}")

    @debug_logger
    def event_update(self) -> None:
        """update event"""
        # _btn_label = self.current_messages.get("btn_update", "Update")
        # _message = self.current_messages.get("msg_info_processing", "Processing...")
        # self.append_log(f"{_btn_label}: {_message}")
        if getattr(self, "is_running_async", False):
            self.cancel_async_process()
        else:
            self.start_web_info_process()
        # _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        # self.append_log(f"{_btn_label}: {_message}")

    @debug_logger
    def event_download(self) -> None:
        """download event"""
        # _btn_label = self.current_messages.get("btn_download", "Download")
        # _message = self.current_messages.get("msg_info_processing", "Processing...")
        # self.append_log(f"{_btn_label}: {_message}")
        if getattr(self, "is_running_async", False):
            self.cancel_async_process()
        else:
            self.start_async_download_process()
        # _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        # self.append_log(f"{_btn_label}: {_message}")

    @debug_logger
    def event_markdown(self) -> None:
        """markdown event"""
        _btn_label = self.current_messages.get("btn_markdown", "Markdown")
        _message = self.current_messages.get("msg_info_processing", "Processing...")
        _doc_dir = self.info_comm.conf.get_path("DOCS_TOPS")
        self.append_log(f"{_btn_label}: {_message} -> {_doc_dir}")
        generate_markdown(dest_dir_path=Path(_doc_dir), info_comm=self.info_comm)
        # ---------------------------------------------------------------------
        dest_path = Path(_doc_dir) / "Readme_tbl_distribution.md"
        md_title = f"Distribution data({self.info_comm.dist_path.name})"
        list_data = []
        for distribution in ORDERED_DISTRIBUTIONS:
            list_sort = self.info_comm.dist.sort(distribution, reverse=True)
            dict_list = [distribution]
            dict_list += [
                d.__dict__ if hasattr(d, "__dict__") else d for d in list_sort
            ]
            list_data.append(dict_list)
        list2markdown(dest_path, md_title, list_data)
        _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        self.append_log(f"{_btn_label}: {_message} -> {_doc_dir}")

    @debug_logger
    def event_custom_iso(self) -> None:
        """custom iso event"""
        _btn_label = self.current_messages.get("btn_custom_iso", "ISO custom")
        _message = self.current_messages.get("msg_info_processing", "Processing...")
        self.append_log(f"{_btn_label}: {_message}")
        _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        self.append_log(f"{_btn_label}: {_message}")

    @debug_logger
    def event_custom_live(self) -> None:
        """custom live event"""
        _btn_label = self.current_messages.get("btn_custom_live", "Live custom")
        _message = self.current_messages.get("msg_info_processing", "Processing...")
        self.append_log(f"{_btn_label}: {_message}")
        _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        self.append_log(f"{_btn_label}: {_message}")

    @debug_logger
    def event_ipxe_menu(self) -> None:
        """ipxe menu event"""
        _btn_label = self.current_messages.get("btn_ipxe_menu", "iPXE menu")
        _message = self.current_messages.get("msg_info_processing", "Processing...")
        self.append_log(f"{_btn_label}: {_message}")
        generate_ipxe_menu(info_comm=self.info_comm)
        _message = self.current_messages.get("msg_info_complete", "✓ Completed.")
        self.append_log(f"{_btn_label}: {_message}")
