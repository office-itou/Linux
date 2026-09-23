import re
import tkinter as tk
from collections.abc import Callable
from tkinter import filedialog, ttk
from typing import Any

from buttons import create_action_button
from menu_data import EXEC_BTN_DATA, FILE_MENU_DATA, LANG_MENU_DATA
from messages import MESSAGES


class MainWindow:
    def __init__(self, root: tk.Tk) -> None:
        self.root: tk.Tk = root
        # ---------------------------------------------------------------------
        # 画面の基本初期化
        self.root.geometry("800x600")
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value="ja")
        # ---------------------------------------------------------------------
        # データの保持用変数
        self.data: list[dict[str, str]] = []
        self.file_path: str = ""
        self.current_columns: list[str] = []
        # ---------------------------------------------------------------------
        # インポートデータのクラス変数化
        self.file_menu_data: list[dict[str, str]] = FILE_MENU_DATA
        self.lang_menu_data: list[dict[str, str]] = LANG_MENU_DATA
        self.exec_btn_data: dict[str, dict[str, str]] = EXEC_BTN_DATA
        # メンバ変数の初期化宣言（初期はNone）
        self.menubar: tk.Menu | None = None
        self.bottom_frame: ttk.Frame | None = None
        # ---------------------------------------------------------------------
        # ショートカットキーの一括自動バインド
        # for item in self.file_menu_data:
        #    if "cmd_name" in item:
        #        cmd_func=getattr(self, item["cmd_name"])
        #        if "bind" in item:
        #            # ラムダ式でイベントを安全にキャッチ
        #            self.root.bind(item["bind"], lambda event, c=cmd_func: c())
        # ---------------------------------------------------------------------
        self.create_main()
        # 📌 【重要】Altキー単体、または Alt + F / Alt + L をOSのイベントとして強制的にバインドする
        # self.root.bind("<Alt_L>", lambda event: self.menubar.focus_set() if self.menubar else None)
        self.root.bind("<F10>", lambda event: self.menubar.focus_set() if self.menubar else None)
        # self.root.bind("<Tab>", lambda event: self._on_tab_press(event) if self.menubar else None)
        # self.root.bind("<Key>", lambda event: self._function(event.keysym) if self.menubar else None)

    def _function(self, text: str) -> None:
        print(type(text))
        print(type(dir))
        print(text)

    def _on_tab_press(self, event=None) -> None:
        print("Tabキーが押されました")

    def _underline(self, menubar: tk.Menu, menu: tk.Menu, label: str) -> None:
        """ローカルのmenuオブジェクトを受け取るように変更"""
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
        
        # self.menu ではなく ローカル変数にする
        menu = tk.Menu(self.menubar, tearoff=0)
        self._underline(self.menubar, menu, label)
        # ---------------------------------------------------------------------
        for _item_dict in menu_items:
            if _item_dict.get("separator"):
                menu.add_separator()
            elif isinstance(_item_dict, dict):
                _msg_key = _item_dict.get("msg_key", "")
                _label = self.message.get(_msg_key, "")
                _bind = _item_dict.get("bind", "")
                _cmd = _item_dict.get("cmd_name", "")
                _acc = _item_dict.get("acc", "")
                # -------------------------------------------------------------
                _call: Callable[[Any], None] = getattr(self, _cmd, lambda e=None: None)
                menu.add_command(label=_label, command=lambda c=_call: c(), accelerator=_acc)
                # -------------------------------------------------------------
                if _bind:
                    # キーマッピング表記のエラー回避のため小文字化等が必要な場合があるが、ここでは安全にラムダでラップ
                    self.root.bind(_bind, _call)

    def _build_radio_menu(self, label: str, menu_items: list[dict[str, Any]]) -> None:
        if not self.menubar:
            return
        # ---------------------------------------------------------------------
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
                    label=_label,
                    variable=_var,
                    value=_val,
                    command=_call,
                )


    def _build_execute_button(self, bottom_frame: ttk.Frame, btn_config: dict[str, str]) -> None:
        _text: str = btn_config["text"]
        _cmd: str = btn_config["cmd_name"]
        _call: Callable[[Any], None] = getattr(self, _cmd, lambda e=None: None)

        btn = create_action_button(
            parent=bottom_frame,
            text=_text,
            command=lambda: _call(),  # イベント引数なしで安全に呼び出し
            style="",
        )
        btn.pack(expand=True, pady=10)

    def create_main(self) -> None:
        # 📌 古いメニューバーを完全に破棄（メモリリーク・重複防止）
        if self.menubar:
            self.root.config(menu="")
            self.menubar.destroy()
        # ---------------------------------------------------------------------
        lang = self.current_lang_strvar.get()
        self.message = MESSAGES[lang]
        self.root.title(self.message["title"])
        # ---------------------------------------------------------------------
        self.menubar = tk.Menu(self.root)
        self.root.config(menu=self.menubar)
        # ---------------------------------------------------------------------
        self._build_command_menu(f"{self.message['menu_file']} (F)", self.file_menu_data)
        self._build_radio_menu(f"{self.message['menu_lang']} (L)", self.lang_menu_data)
        # ---------------------------------------------------------------------
        # 古いボトムフレームを確実に削除
        if self.bottom_frame:
            self.bottom_frame.destroy()
        # ---------------------------------------------------------------------
        self.bottom_frame = ttk.Frame(self.root, padding=20)
        self.bottom_frame.pack(fill="x", side="bottom")
        # ---------------------------------------------------------------------
        btn_config = self.exec_btn_data[lang]
        self._build_execute_button(bottom_frame=self.bottom_frame, btn_config=btn_config)

    # --- menu event ----------------------------------------------------------
    def open_file(self, event=None) -> None:
        path: str = filedialog.askopenfilename(
            title=self.message["menu_open"],
            filetypes=[("JSON Files", "*.json"), ("All Files", "*.*")],
        )
        if not path:
            return
        self.file_path = path

    def save_file(self, event=None) -> None:
        print("save_file")

    def save_file_as(self, event=None) -> None:
        print("save_file_as")

    def quit_app(self, event=None) -> None:
        self.root.quit()

    # --- button event --------------------------------------------------------
    def create_md(self, event=None) -> None:
        print("create_md")

    # --- radio menu event ----------------------------------------------------
    def switch_language(self) -> None:
        # 言語切り替え時にUIを再構築
        self.create_main()


if __name__ == "__main__":
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    root.mainloop()
