# main.py
import json
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from typing import Any


# import os
# import sys
# from pathlib import Path
# ruff: isort: off
# --- my library --------------------------------------------------------------
# execusr = os.getenv("SUDO_USER", os.getenv("USER"))
# homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
# libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
# if str(libsdir) not in sys.path:
#    sys.path.append(str(libsdir))
# common functions
#
# lib_path = os.path.abspath("/srv/hgfs/linux/script/py_custom_cmd/src/")
# current_dir = os.path.dirname(os.path.abspath(__file__))
# utils_path = os.path.abspath(os.path.join(lib_path, "common/utils"))
# shared_path = os.path.abspath(os.path.join(lib_path, "common/shared"))
# if current_dir not in sys.path:
#    sys.path.insert(0, current_dir)
# if lib_path not in sys.path:
#    sys.path.insert(0, lib_path)
# if utils_path not in sys.path:
#    sys.path.insert(0, utils_path)
# if shared_path not in sys.path:
#    sys.path.insert(0, shared_path)
from my_colors import Color
from my_config import infosystem  # 共通設定を読み込み
from my_string import eprint, set_gui_log_window  # 📌 追加

# --- my modules --------------------------------------------------------------
from card_editor import CardEditorWindow
from log_monitor import DebugLogWindow  # 📌 追加
from menu_data import EXEC_BTN_DATA, FILE_MENU_DATA, LANG_MENU_DATA
from ui_layout import MainWindowUI  # 📌 描画サブファイルをインポート
from utils import clean_value, detect_language
# ruff: isort: on

class MainWindow(MainWindowUI):  # 📌 UIクラスを継承
    def __init__(self, root: tk.Tk) -> None:
        # 親クラス（UI側）の初期化ルーチンを呼び出し
        super().__init__()

        self.root: tk.Tk = root

        # GUIモードへの切り替えとコールバック登録
        infosystem.is_gui = True
        infosystem.gui_error_callback = messagebox.showerror
        infosystem.gui_info_callback = messagebox.showinfo
        infosystem.debugout = True
        infosystem.log_window_active = True

        # 📌 デバッグログウィンドウをサブウィンドウとして起動
        # (debugやdebugoutモードが有効な場合のみ起動させる条件分岐にしても良いです)
        if infosystem.debugout:
            # 1. ログウィンドウインスタンスを作成
            self.log_win = DebugLogWindow(self.root)
            # 2. 唯一の出力管理を行っている my_string にインスタンスを登録
            set_gui_log_window(self.log_win)

        # 画面とデータの初期設定
        self.root.geometry("800x600")
        self.lang: str = detect_language()
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=self.lang)

        self.data: list[dict[str, Any]] = []
        self.file_path: str = ""
        self.current_columns: list[str] = []

        self.file_menu_data: list[dict[str, str]] = FILE_MENU_DATA
        self.lang_menu_data: list[dict[str, Any]] = LANG_MENU_DATA
        self.exec_btn_data: dict[str, dict[str, str]] = EXEC_BTN_DATA

        # 📌 ui_layout.py から継承したUI生成関数を実行
        self.create_main()

        self.root.bind(
            "<F10>", lambda event: self.menubar.focus_set() if self.menubar else None
        )
        self.test()

    def test(self) -> None:
        """Test"""
        strhalf = "1234567890123456798012345678901234567980"
        strwide = "１２３４５６７８９０１２３４５６７８９０"
        strmixd = f"12345678901234567980{Color.underline}１２３４５６７８９０"
        strslid = f"12345678901234567980 {Color.underline}１２３４５６７８９０"

        list_text = [
            f"{Color.reset}{strhalf}{Color.green}{strhalf}{Color.yellow}{strhalf}{Color.red}{strhalf}{Color.magenta}{strhalf}{Color.reset}",
            f"{Color.reset}{strwide}{Color.green}{strwide}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}{Color.reset}",
            f"{Color.reset}{strhalf}{Color.green}{strmixd}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}{Color.reset}",
            f"{Color.reset}{strhalf}{Color.green}{strslid}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}{Color.reset}",
        ]

        for text in list_text:
            eprint(text, infosystem.columns)

    # --- テーブル・ロジック処理 ---------------------------------------------------
    def setup_table_columns(self) -> None:
        if not self.data or not self.table_frame:
            return

        all_keys: list[str] = list(self.data[0].keys())
        self.current_columns = all_keys[:8]

        if self.tree:
            self.tree.destroy()

        self.tree = ttk.Treeview(
            self.table_frame,
            columns=self.current_columns,
            show="headings",
            yscrollcommand=self.scrollbar_y.set,
            xscrollcommand=self.scrollbar_x.set,
        )
        self.tree.pack(fill="both", expand=True)
        self.scrollbar_y.config(command=self.tree.yview)
        self.scrollbar_x.config(command=self.tree.xview)

        for col in self.current_columns:
            display_title: str = self.message.get(col, col)
            self.tree.heading(col, text=display_title)
            self.tree.column(col, width=120, anchor="w")

        self.tree.bind("<Double-1>", self.on_row_double_click)

    def refresh_table(self) -> None:
        if not self.tree:
            return

        for row in self.tree.get_children():
            self.tree.delete(row)

        for index, item in enumerate(self.data):
            row_values: list[str] = []
            for col in self.current_columns:
                val: Any = item.get(col, "-")
                row_values.append(clean_value(val))

            self.tree.insert("", "end", iid=str(index), values=row_values)

    def on_row_double_click(self, event: tk.Event) -> None:
        if not self.tree:
            return
        selected_items: tuple = self.tree.selection()
        if not selected_items:
            return
        data_index: int = int(selected_items[0])

        CardEditorWindow(
            parent_root=self.root,
            data=self.data,
            start_index=data_index,
            lang_dict=self.message,
            on_confirm_callback=self.refresh_table,
        )

    # --- メニューイベント (Menu Events) --------------------------------------------
    def open_file(self, event=None) -> None:
        path: str = filedialog.askopenfilename(
            title=self.message["menu_open"],
            filetypes=[("JSON Files", "*.json"), ("All Files", "*.*")],
        )
        if not path:
            return

        try:
            with open(path, "r", encoding="utf-8") as f:
                self.data = json.load(f)
            self.file_path = path

            if self.info_label:
                self.info_label.config(
                    text=self.message["info_loading"].format(
                        path=self.file_path, count=len(self.data)
                    ),
                    font=("Arial", 10, "normal"),
                )
            self.setup_table_columns()
            self.refresh_table()
        except Exception as e:  # noqa: BLE001
            messagebox.showerror(
                self.message["msg_err_title"], self.message["msg_err_load"].format(e=e)
            )

    def save_file(self, event=None) -> None:
        if not self.file_path:
            self.save_file_as()
            return
        try:
            with open(self.file_path, "w", encoding="utf-8") as f:
                json.dump(self.data, f, ensure_ascii=False, indent=4)
            messagebox.showinfo(
                self.message["msg_save_title"],
                self.message["msg_save_success"].format(path=self.file_path),
            )
        except Exception as e:  # noqa: BLE001
            messagebox.showerror(
                self.message["msg_err_title"], self.message["msg_err_save"].format(e=e)
            )

    def save_file_as(self, event=None) -> None:
        path: str = filedialog.asksaveasfilename(
            title=self.message["menu_save_as"],
            filetypes=[("JSON Files", "*.json")],
            defaultextension=".json",
        )
        if not path:
            return
        self.file_path = path
        self.save_file()
        if self.info_label:
            self.info_label.config(
                text=self.message["info_open"].format(
                    path=self.file_path, count=len(self.data)
                )
            )

    def quit_app(self, event=None) -> None:
        self.root.quit()

    # --- ボタンアクションイベント (Button Events) ----------------------------------
    def create_md(self, event=None) -> None:
        print("create_md イベントが実行されました")

    # --- ラジオメニューイベント (Radio Menu Events) ----------------------------------
    def switch_language(self) -> None:
        # UIクラス側で定義された一括再描画を呼び出す
        self.create_main()


if __name__ == "__main__":
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    root.mainloop()
