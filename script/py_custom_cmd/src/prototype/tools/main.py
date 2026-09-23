#!/usr/bin/env python3
# --- Python library ----------------------------------------------------------
# import re
import tkinter as tk

from collections.abc import Callable
from dataclasses import asdict
from tkinter import ttk
from typing import Any

# from typing import Any
# ruff: isort: off
# --- my library --------------------------------------------------------------
from my_config import infosystem
from my_gui_helper import build_buttons, build_menu_bar, load_ui_definition
from my_gui_log_monitor import DebugLogWindow
from my_mem_usage import print_peak_memory
from my_message import get_caller_name, message_elapsed
from my_string import eprint, set_gui_log_window

# from my_string import eprint
from my_shared import InfoCommon
from my_time import TimeElapsed


# ruff: isort: on
# ruff: isort: off
# --- my modules --------------------------------------------------------------
from functions import test


class MainWindow:
    def __init__(self, root: tk.Tk) -> None:
        self.root: tk.Tk = root
        self.root.geometry("800x600")

        # 1. 状態変数の初期化
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
        # self.current_lang_strvar = tk.StringVar(value="ja")

        # 2. 定義ファイルの読み込み
        self.ui_def = load_ui_definition("ui_definition.json")

        # 3. data loading
        self.info_comm = InfoCommon()

        # 4. 画面の構築
        self.generate_window()

    def _get_command_map(self) -> dict[str, Callable[[Any], None]]:
        """JSON内のイベント文字列と、実際のクラスメソッドのマッピング"""
        return {
            "event_open_file": self.event_open_file,
            "event_save_file": self.event_save_file,
            "event_save_file_as": self.event_save_file_as,
            "event_quit_app": self.event_quit_app,
            "event_switch_language": self.event_switch_language,
            "event_exec": self.event_exec,
            "event_confirm": self.event_confirm,
            "event_debug_mon": self.event_debug_mon,
        }

    def _get_variable_map(self) -> dict[str, tk.Variable]:
        """JSON内の変数文字列と、実際のTk変数オブジェクトのマッピング"""
        return {"current_lang_strvar": self.current_lang_strvar}

    def generate_window(self) -> None:
        """画面全体の再構築（言語変更時にもクリーンアップして再呼出）"""
        # ウィジェットのクリーンアップ（デバッグウィンドウ等は除外）
        for child in self.root.winfo_children():
            if child.winfo_exists() and "debug_log_win" not in str(child):
                try:
                    child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass

        # 現在選択されている言語の文言を取得
        lang = self.current_lang_strvar.get()
        current_messages = self.ui_def["messages"].get(lang, {})

        # ウィンドウタイトルの設定
        self.root.title(current_messages.get("title", "Window"))

        # 🤝 コマンドと変数のマッピングを取得
        cmd_map = self._get_command_map()
        var_map = self._get_variable_map()

        # 1. メニューバーの動的生成
        build_menu_bar(
            root=self.root,
            menu_data=self.ui_def["menus"],
            messages=current_messages,
            commands=cmd_map,
            variables=var_map,
        )

        #main_frame = ttk.Frame(self.root, padding=20)
        #main_frame.pack(fill=tk.BOTH, expand=True, padx=15, pady=5)

        # 2. 中央テーブル
        table_frame = ttk.Frame(self.root)
        table_frame.pack(fill="both", expand=True, padx=15, pady=5)

        scrollbar_y = ttk.Scrollbar(table_frame, orient="vertical")
        scrollbar_y.pack(side="right", fill="y")
        scrollbar_x = ttk.Scrollbar(table_frame, orient="horizontal")
        scrollbar_x.pack(side="bottom", fill="x")

        tree = ttk.Treeview(table_frame, show="headings")
        tree.pack(fill="both", expand=True)
        scrollbar_y.config(command=tree.yview)
        scrollbar_x.config(command=tree.xview)

        #dict_data = asdict(self.info_comm.mdia.data[0])
        #all_keys: list[str] = list(dict_data.keys())
        #current_columns = all_keys[:8]

        row_keys: list[str] = []
        for key, val in self.info_comm.mdia.data[0].__dict__.items():
            if key == "type" or key == "entry_disp" or key == "release":
                row_keys.append(key)
        current_columns = row_keys[:8]


        if tree:
            tree.destroy()
        tree = ttk.Treeview(
            table_frame,
            columns=current_columns,
            show="headings",
            yscrollcommand=scrollbar_y.set,
            xscrollcommand=scrollbar_x.set,
        )
        tree.pack(fill="both", expand=True)
        scrollbar_y.config(command=tree.yview)
        scrollbar_x.config(command=tree.xview)

        for col in current_columns:
            display_title: str = current_messages.get(col, col)
            tree.heading(col, text=display_title)
            tree.column(col, width=120, anchor="w")

        for row in tree.get_children():
            tree.delete(row)

        index=0
        for item in self.info_comm.mdia.data:
            row_values: list[str] = []
            if item.__dict__["entry_flag"] == "o":
                for key, val in item.__dict__.items():
                    if key == "type" or key == "entry_disp" or key == "release":
                        row_values.append(val)
                index += 1
                tree.insert("", "end", iid=str(index), values=row_values)

        return
        main_frame.columnconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)

        # ボタンの配置用ベースフレームを作成 (Grid引き延ばし用設定)
        # 2. ボタン群の動的生成＆グリッド配置
        build_buttons(
            parent=main_frame,
            button_data=self.ui_def["buttons"],
            messages=current_messages,
            commands=cmd_map,
        )



    # --- 共通イベントハンドラ ----------------------------------------------------
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

    def event_exec(self) -> None:
        eprint("ボタン：実行がクリックされました")

    def event_confirm(self) -> None:
        eprint("ボタン：確定して戻るがクリックされました")

    def event_debug_mon(self) -> None:
        eprint("ボタン：デバッグがクリックされました")
        new_log_win = DebugLogWindow(self.root)
        set_gui_log_window(new_log_win)
        test()


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
