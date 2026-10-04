"""main window event"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from pathlib import Path
from typing import Any


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
from gui_async_handler import AsyncProcessHandler
from gui_main_build import MainWindowBuild


# ruff: isort: on
# --- main --------------------------------------------------------------------
class MainWindowEvent(MainWindowBuild):
    info_comm: InfoCommon

    def __init__(self, root: tk.Tk) -> None:
        self.root: tk.Tk = root
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
        self.current_monitor_boolvar: tk.BooleanVar = tk.BooleanVar(value=False)
        self.monitor_window_instance: Any = None
        self.current_messages: dict[str, str] = {}
        self.async_handler = AsyncProcessHandler(self)
        self._is_switching_lang = False

    @debug_logger
    def event_open_file(self) -> None:
        """open event"""
        pass

    @debug_logger
    def event_save_file(self) -> None:
        """save event"""
        self.info_comm.dist.save(self.info_comm.dist_json)
        self.info_comm.mdia.save(self.info_comm.mdia_json)

    @debug_logger
    def event_save_file_as(self) -> None:
        """save as event"""
        pass

    @debug_logger
    def event_quit_app(self) -> None:
        """quit event"""
        infosystem.log_window_active = False
        set_gui_log_window(None)
        for _child in self.root.winfo_children():
            if isinstance(_child, tk.Toplevel) and _child.winfo_exists():
                try:
                    _child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        self.root.quit()

    # @debug_logger
    def event_switch_monitor(self) -> None:
        """switch monitor event"""
        _is_on = self.current_monitor_boolvar.get()
        if _is_on:
            if (
                self.monitor_window_instance is None
                or not hasattr(self.monitor_window_instance, "win")
                or not self.monitor_window_instance.win.winfo_exists()
            ):
                self.monitor_window_instance = DebugLogWindow(self.root)
                self.monitor_window_instance.saved_debug = infosystem.debug
                self.monitor_window_instance.saved_debugout = infosystem.debugout
                infosystem.debug = True
                infosystem.debugout = True
                infosystem.log_window_active = True
                self.monitor_window_instance = DebugLogWindow(self.root)
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

    @debug_logger
    def event_switch_language(self) -> None:
        """switch language event"""
        if self._is_switching_lang:
            return
        try:
            self._is_switching_lang = True
            self.generate_window()
        finally:
            self._is_switching_lang = False

    @debug_logger
    def event_update(self) -> None:
        """update event"""
        if getattr(self, "is_running_async", False):
            self.async_handler.cancel_async_process()
        else:
            self.async_handler.start_async_process()

    @debug_logger
    def event_download(self) -> None:
        """download event"""
        pass

    @debug_logger
    def event_markdown(self) -> None:
        """markdown event"""
        _doc_dir = self.info_comm.conf.get_path("DOCS_TOPS")
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

    @debug_logger
    def event_custom_iso(self) -> None:
        """custom iso event"""
        pass

    @debug_logger
    def event_custom_live(self) -> None:
        """custom live event"""
        pass

    @debug_logger
    def event_ipxe_menu(self) -> None:
        """ipxe menu event"""
        generate_ipxe_menu(info_comm=self.info_comm)

    @debug_logger
    def event_exec(self) -> None:
        """exec event"""
        pass

    @debug_logger
    def event_confirm(self) -> None:
        """confirm event"""
        pass

    @debug_logger
    def event_debug_mon(self) -> None:
        """debug monitor event"""
        self.current_monitor_boolvar.set(not self.current_monitor_boolvar.get())
        self.event_switch_monitor()

    @debug_logger
    def event_toggle_all_checks(
        self, table_id: str = "active_table", check_char: str = "☑"
    ) -> None:
        """Checkbox "Select All" / "Deselect All" event"""
        if not isinstance(table_id, str):
            table_id = "active_table"
        if not hasattr(self, "table_widgets") or not hasattr(self, "datas_map"):
            return
        target_data = self.datas_map.get(table_id, [])
        if not target_data:
            return
        is_target_value = check_char == "☑"
        for item in target_data:
            if getattr(item, "entry_name", "") != "menu-entry":
                item.is_target = is_target_value
        if hasattr(self, "reload_table_data"):
            self.reload_table_data()
