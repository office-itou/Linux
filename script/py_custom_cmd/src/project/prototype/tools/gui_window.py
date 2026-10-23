# gui_window.py
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk

from my_config import infosystem
from my_gui_build_helper import build_buttons, build_menu_bar, load_ui_definition
from my_gui_build_log_monitor import DebugLogWindow
from my_shared import InfoCommon
from my_string import eprint, set_gui_log_window

from gui_async_handler import AsyncProcessHandler  # 💡 先ほど分けたハンドラをインポート
from gui_build_table import build_tables


class MainWindow:
    def __init__(self, root: tk.Tk) -> None:
        self.root: tk.Tk = root
        self.root.geometry("800x600")
        # 1. 状態変数の初期化
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
        self.ui_def = load_ui_definition("ui_definition.json")
        self.info_comm = InfoCommon()
        self.is_running_async = False
        # 2. 💡 分割した非同期処理ハンドラのインスタンスを生成
        self.async_handler = AsyncProcessHandler(self)
        # 3. 画面の構築
        self.generate_window()

    def _get_command_map(self) -> dict[str, Callable]:
        return {
            "event_open_file": self.event_open_file,
            "event_save_file": self.event_save_file,
            "event_save_file_as": self.event_save_file_as,
            "event_quit_app": self.event_quit_app,
            "event_switch_language": self.event_switch_language,
            "event_exec": self.event_exec,
            "event_confirm": self.event_confirm,
            "event_debug_mon": self.event_debug_mon,
            "event_active_select_all": lambda: self.toggle_all_checks(
                "active_table", "☑"
            ),
            "event_active_deselect_all": lambda: self.toggle_all_checks(
                "active_table", "☐"
            ),
        }

    def _get_variable_map(self) -> dict[str, tk.Variable]:
        return {"current_lang_strvar": self.current_lang_strvar}

    def generate_window(self) -> None:
        """画面全体の再構築（クリーンアップを伴う再呼出）"""
        for child in self.root.winfo_children():
            if child.winfo_exists() and "debug_log_win" not in str(child):
                try:
                    child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        lang = self.current_lang_strvar.get()
        current_messages = self.ui_def["messages"].get(lang, {})
        self.root.title(current_messages.get("title", "Window"))
        cmd_map = self._get_command_map()
        var_map = self._get_variable_map()
        # 1. メニューバー生成
        build_menu_bar(
            root=self.root,
            menu_data=self.ui_def["menus"],
            messages=current_messages,
            commands=cmd_map,
            variables=var_map,
        )
        # 2. 下部ボタンフレーム生成
        bottom_frame = ttk.Frame(self.root, padding=10)
        bottom_frame.pack(fill="x", side="bottom")
        build_buttons(
            parent=bottom_frame,
            button_data=self.ui_def["buttons"],
            messages=current_messages,
            commands=cmd_map,
        )
        # 3. 中央のメインフレーム生成
        main_frame = ttk.Frame(self.root, padding=10)
        main_frame.pack(fill=tk.BOTH, expand=True)
        main_frame.columnconfigure(0, weight=1)
        main_frame.rowconfigure(0, weight=1)
        main_frame.rowconfigure(1, weight=1)
        # 📊 複数テーブル用データのマッピング
        tables_config = self.ui_def.get("tables", [])
        self.datas_map = {}
        for table_config in tables_config:
            t_id = table_config.get("table_id", "")
            if t_id == "active_table":
                self.datas_map[t_id] = [
                    item
                    for item in self.info_comm.mdia.data
                    if getattr(item, "entry_flag", "") == "o"
                ]
            elif t_id == "archive_table":
                self.datas_map[t_id] = [
                    item
                    for item in self.info_comm.mdia.data
                    if getattr(item, "entry_flag", "") != "o"
                ]
        # 4. 複数テーブルの動的生成＆配置を実行
        self.table_widgets = build_tables(
            parent=main_frame,
            tables_data=tables_config,
            messages=current_messages,
            datas_map=self.datas_map,
        )
        # 💡 前回の非同期処理で「更新あり」となった行があれば再生成直後に復元適用
        self._restore_updated_row_styles()

    def _restore_updated_row_styles(self) -> None:
        for table_id, tree in self.table_widgets.items():
            target_data = self.datas_map.get(table_id, [])
            items = tree.get_children()
            columns = list(tree["columns"])
            memo_idx = columns.index("memo") if "memo" in columns else -1
            for idx, item_id in enumerate(items):
                if idx < len(target_data) and getattr(
                    target_data[idx], "is_updated_data", False
                ):
                    tree.item(item_id, tags=(f"{table_id}_updated",))
                    if memo_idx != -1:
                        vals = list(tree.item(item_id, "values"))
                        vals[memo_idx] = "🔄 データを更新しました"
                        tree.item(item_id, values=vals)

    def toggle_all_checks(self, table_id: str, check_char: str) -> None:
        if table_id not in self.table_widgets:
            return
        tree = self.table_widgets[table_id]
        target_data = self.datas_map.get(table_id, [])
        is_target_bool = check_char == "☑"
        for item in target_data:
            item.is_target = is_target_bool
        columns = list(tree["columns"])
        if "is_checked" not in columns:
            return
        check_idx = columns.index("is_checked")
        for item_id in tree.get_children():
            current_values = list(tree.item(item_id, "values"))
            current_values[check_idx] = check_char
            tree.item(item_id, values=current_values)

    # --- ボタンイベント群 --------------------------------------------------------
    def event_exec(self) -> None:
        eprint("ボタン：実行がクリックされました")
        # 💡 分割したハンドラへ処理を完全に委譲
        self.async_handler.start_async_process()

    def event_open_file(self, event=None) -> None:
        eprint("メニュー：ファイルを開く")

    def event_save_file(self, event=None) -> None:
        eprint("メニュー：上書き保存")

    def event_save_file_as(self, event=None) -> None:
        eprint("メニュー：名前を付けて保存")

    def event_quit_app(self, event=None) -> None:
        eprint("アプリケーションを終了します")
        infosystem.log_window_active = False
        set_gui_log_window(None)
        for child in self.root.winfo_children():
            if isinstance(child, tk.Toplevel) and child.winfo_exists():
                try:
                    child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        self.root.quit()

    def event_switch_language(self) -> None:
        eprint(f"言語を切り替えました: {self.current_lang_strvar.get()}")
        self.generate_window()

    def event_confirm(self) -> None:
        eprint("ボタン：確定して戻るがクリックされました")

    def event_debug_mon(self) -> None:
        eprint("ボタン：デバッグがクリックされました")
        new_log_win = DebugLogWindow(self.root)
        set_gui_log_window(new_log_win)
