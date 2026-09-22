# ui_layout.py
import re
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk
from typing import Any

from buttons import create_action_button
from messages import MESSAGES


class MainWindowUI:
    """MainWindowのUI描画レイアウトのみを担当するクラス"""

    def __init__(self) -> None:
        # MainWindow側で初期化されるため、ここでは型宣言のみ定義
        self.root: tk.Tk
        self.current_lang_strvar: tk.StringVar
        self.file_menu_data: list[dict[str, str]]
        self.lang_menu_data: list[dict[str, Any]]
        self.exec_btn_data: dict[str, dict[str, str]]
        self.data: list[dict[str, Any]]
        self.file_path: str
        self.message: dict[str, str]

        self.menubar: tk.Menu | None = None
        self.top_frame: ttk.Frame | None = None
        self.table_frame: ttk.Frame | None = None
        self.bottom_frame: ttk.Frame | None = None
        self.tree: ttk.Treeview | None = None
        self.info_label: ttk.Label | None = None
        self.scrollbar_y: ttk.Scrollbar | None = None
        self.scrollbar_x: ttk.Scrollbar | None = None

    def _underline(self, menubar: tk.Menu, menu: tk.Menu, label: str) -> None:
        _pattern = re.compile(r"^.+\(([0-9a-zA-Z]+)\).*$")
        _match = _pattern.search(label)
        if _match:
            _find_start = _match.start(1)
            menubar.add_cascade(label=label, menu=menu, underline=_find_start)
        else:
            menubar.add_cascade(label=label, menu=menu)

    def _build_command_menu(self, label: str, menu_items: list[dict[str, str]]) -> None:
        if not self.menubar:
            return
        menu = tk.Menu(self.menubar, tearoff=0)
        self._underline(self.menubar, menu, label)

        for _item_dict in menu_items:
            if _item_dict.get("separator"):
                menu.add_separator()
            elif isinstance(_item_dict, dict):
                _msg_key = _item_dict.get("msg_key", "")
                _label = self.message.get(_msg_key, "")
                _bind = _item_dict.get("bind", "")
                _cmd = _item_dict.get("cmd_name", "")
                _acc = _item_dict.get("acc", "")

                # メインクラス(self)側にあるイベント関数を取得
                _call: Callable[[Any], None] = getattr(self, _cmd, lambda e=None: None)
                menu.add_command(
                    label=_label, command=lambda c=_call: c(), accelerator=_acc
                )

                if _bind:
                    self.root.bind(_bind, _call)

    def _build_radio_menu(self, label: str, menu_items: list[dict[str, Any]]) -> None:
        if not self.menubar:
            return
        menu = tk.Menu(self.menubar, tearoff=0)
        self._underline(self.menubar, menu, label)

        for _item_dict in menu_items:
            if isinstance(_item_dict, dict):
                _label = _item_dict.get("label", "")
                _var = self.current_lang_strvar
                _val = _item_dict.get("value", "")
                _cmd = _item_dict.get("cmd_name", "")
                _call: Callable[[], None] = getattr(self, _cmd, lambda: None)
                menu.add_radiobutton(
                    label=_label, variable=_var, value=_val, command=_call
                )

    def _build_execute_button(
        self, bottom_frame: ttk.Frame, btn_config: dict[str, str]
    ) -> None:
        _text: str = btn_config["text"]
        _cmd: str = btn_config["cmd_name"]
        _call: Callable[[Any], None] = getattr(self, _cmd, lambda e=None: None)

        btn = create_action_button(
            parent=bottom_frame, text=_text, command=lambda: _call(), style=""
        )
        btn.pack(expand=True, pady=10)

    def create_main(self) -> None:
        """UI全体のクリアと再構築を行うレイアウト関数"""
        if self.menubar:
            self.root.config(menu="")
            self.menubar.destroy()
        if self.top_frame:
            self.top_frame.destroy()
        if self.table_frame:
            self.table_frame.destroy()
        if self.bottom_frame:
            self.bottom_frame.destroy()

        lang = self.current_lang_strvar.get()
        self.message = MESSAGES[lang]
        self.root.title(self.message["title"])

        # 1. メニュー
        self.menubar = tk.Menu(self.root)
        self.root.config(menu=self.menubar)
        self._build_command_menu(
            f"{self.message['menu_file']} (F)", self.file_menu_data
        )
        self._build_radio_menu(f"{self.message['menu_lang']} (L)", self.lang_menu_data)

        # 2. 上部インフォ
        self.top_frame = ttk.Frame(self.root, padding=5)
        self.top_frame.pack(fill="x", padx=10)

        if self.file_path:
            info_text = self.message["info_open"].format(
                path=self.file_path, count=len(self.data)
            )
            font_style = ("Arial", 10, "normal")
        else:
            info_text = self.message["info_start"]
            font_style = ("Arial", 10, "italic")

        self.info_label = ttk.Label(self.top_frame, text=info_text, font=font_style)
        self.info_label.pack(side="left", fill="x", expand=True)

        # 3. 中央テーブル
        self.table_frame = ttk.Frame(self.root)
        self.table_frame.pack(fill="both", expand=True, padx=15, pady=5)

        self.scrollbar_y = ttk.Scrollbar(self.table_frame, orient="vertical")
        self.scrollbar_y.pack(side="right", fill="y")
        self.scrollbar_x = ttk.Scrollbar(self.table_frame, orient="horizontal")
        self.scrollbar_x.pack(side="bottom", fill="x")

        self.tree = ttk.Treeview(self.table_frame, show="headings")
        self.tree.pack(fill="both", expand=True)
        self.scrollbar_y.config(command=self.tree.yview)
        self.scrollbar_x.config(command=self.tree.xview)

        # 4. 下部ボタン
        self.bottom_frame = ttk.Frame(self.root, padding=20)
        self.bottom_frame.pack(fill="x", side="bottom")

        btn_config = self.exec_btn_data[lang]
        self._build_execute_button(
            bottom_frame=self.bottom_frame, btn_config=btn_config
        )

        # メイン側にあるテーブル再描画メソッドを安全に呼び出す
        if (
            self.data
            and hasattr(self, "setup_table_columns")
            and hasattr(self, "refresh_table")
        ):
            self.setup_table_columns()
            self.refresh_table()
