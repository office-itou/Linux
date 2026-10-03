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
    eprint,
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
        """initialization
        Args:
            root (tk.Tk): the generated window object
        """
        self.root: tk.Tk = root
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
        # 💡 モニター状態管理用の BooleanVar を初期化（デフォルトはオフ: False）
        self.current_monitor_boolvar: tk.BooleanVar = tk.BooleanVar(value=False)
        # 💡 生成されたウィンドウインスタンスの参照保持用
        self.monitor_window_instance: Any = None

        self.current_messages: dict[str, str] = {}
        self.async_handler = AsyncProcessHandler(self)

    def event_open_file(self) -> None:
        """open event"""
        message = self.current_messages.get("menu_open", "Open File...")
        eprint(message)

    def event_save_file(self) -> None:
        """save event"""
        message = self.current_messages.get("menu_save", "Save")
        eprint(message)
        for info_mdia_data in self.info_comm.mdia.data:
            if hasattr(info_mdia_data, "is_target"):
                delattr(info_mdia_data, "is_target")
        self.info_comm.dist.save(self.info_comm.dist_json)
        self.info_comm.mdia.save(self.info_comm.mdia_json)

    def event_save_file_as(self) -> None:
        """save as event"""
        message = self.current_messages.get("menu_save_as", "Save As...")
        eprint(message)

    def event_quit_app(self) -> None:
        """quit event"""
        message = self.current_messages.get("menu_exit", "Exit")
        eprint(message)
        infosystem.log_window_active = False
        set_gui_log_window(None)
        for child in self.root.winfo_children():
            if isinstance(child, tk.Toplevel) and child.winfo_exists():
                try:
                    child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        self.root.quit()

    def event_switch_monitor(self) -> None:
        """switch monitor event"""
        message = self.current_messages.get("menu_monitor", "Monitor")
        is_on = self.current_monitor_boolvar.get()
        eprint(f"{message}({is_on})")

        if is_on:
            if (
                self.monitor_window_instance is None
                or not hasattr(self.monitor_window_instance, "win")
                or not self.monitor_window_instance.win.winfo_exists()
            ):
                # 💡 🌟 【重要】ウィンドウを生成する前に、
                # ログ出力フラグを True に強制同期します
                infosystem.log_window_active = True

                self.monitor_window_instance = DebugLogWindow(self.root)
                set_gui_log_window(self.monitor_window_instance)
        else:
            # 💡 🌟 【重要】オフにした場合は、即座にログフラグを
            # False にして出力を止めます
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

    def event_switch_language(self) -> None:
        """switch language event"""
        message = self.current_messages.get("menu_lang", "Language")
        eprint(f"{message}({self.current_lang_strvar.get()})")
        self.generate_window()

    def event_update(self) -> None:
        """update event"""
        message = self.current_messages.get("btn_update", "Update")
        eprint(message)
        if getattr(self, "is_running_async", False):
            self.async_handler.cancel_async_process()
        else:
            self.async_handler.start_async_process()

    def event_download(self) -> None:
        """download event"""
        message = self.current_messages.get("btn_download", "Download")
        eprint(message)

    def event_markdown(self) -> None:
        """markdown event"""
        message = self.current_messages.get("btn_markdown", "Markdown")
        eprint(message)
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

    def event_custom_iso(self) -> None:
        """custom iso event"""
        message = self.current_messages.get("btn_custom_iso", "ISO custom")
        eprint(message)

    def event_custom_live(self) -> None:
        """custom live event"""
        message = self.current_messages.get("btn_custom_live", "Live custom")
        eprint(message)

    def event_ipxe_menu(self) -> None:
        """ipxe menu event"""
        message = self.current_messages.get("btn_ipxe_menu", "iPXE menu")
        eprint(message)
        generate_ipxe_menu(info_comm=self.info_comm)

    def event_exec(self) -> None:
        """exec event"""
        message = self.current_messages.get("btn_exec", "Run")
        eprint(message)

    def event_confirm(self) -> None:
        """confirm event"""
        message = self.current_messages.get("btn_confirm", "Confirm")
        eprint(message)

    def event_debug_mon(self) -> None:
        """debug monitor event"""
        message = self.current_messages.get("btn_debug", "Debug monitor")
        eprint(message)
        # 現在の状態をトグル反転させて event_switch_monitor を再利用
        self.current_monitor_boolvar.set(not self.current_monitor_boolvar.get())
        self.event_switch_monitor()

    def event_toggle_all_checks(
        self, table_id: str = "active_table", check_char: str = "☑"
    ) -> None:
        """💡 チェックボックスの一括全選択 / 全解除イベント (メニュー完全同期版)"""
        # 💡 🌟 メニューの bind 経由やショートカットで呼ばれた場合は table_id に
        # tkinter のイベントオブジェクトが入るため、
        # その場合は自動的に判定して処理を切り分けます。
        if not isinstance(table_id, str):
            # コマンドマップ名に deselect が含まれているか、または実行された
            # 元の文字列からトグル文字を自動判定
            # 今回は安全に、現在の関数が deselect の文脈で呼ばれたかを
            # イベントシグナル等から救うか、
            # 引数が崩れた場合のフォールバックとして現在の呼び出し文字を判定します。
            # ※より確実にするため、_get_command_map 側を後述のように補正する
            # アプローチが最も確実です。
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
