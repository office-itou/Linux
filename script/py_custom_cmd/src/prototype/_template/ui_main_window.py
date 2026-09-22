# --- Python library ----------------------------------------------------------
import tkinter as tk

# from collections.abc import Callable
# from tkinter import filedialog, messagebox, ttk
from tkinter import ttk
from typing import Any


# ruff: isort: off
# --- my library --------------------------------------------------------------
from my_gui_buttons import create_action_button
# ruff: isort: on

# ruff: isort: off
# --- my modules --------------------------------------------------------------
from messages import MESSAGES


# ruff: isort: on
# -----------------------------------------------------------------------------
# @debug_logger
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

    def init_main_window(self) -> None:
        # --- basic screen initialization -------------------------------------
        self.root.geometry("800x600")
        self.root.bind(
            "<F10>", lambda event: self.menubar.focus_set() if self.menubar else None
        )
        # self.root.bind(
        #    "<Alt_L>", lambda event: self.menubar.focus_set() if self.menubar else None
        # )
        # self.root.bind(
        #    "<Tab>", lambda event: self._on_tab_press(event) if self.menubar else None
        # )
        # self.root.bind(
        #    "<Key>",
        #    lambda event: self._function(event.keysym) if self.menubar else None,
        # )
        self.create_main_window()

    def create_main_window(self) -> None:
        # --- destroy ---------------------------------------------------------
        if self.menubar:
            self.root.config(menu="")
            self.menubar.destroy()
        if self.top_frame:
            self.top_frame.destroy()
        if self.table_frame:
            self.table_frame.destroy()
        if self.bottom_frame:
            self.bottom_frame.destroy()
        # --- member variable initialization declaration (initially none) -----
        self.menubar: tk.Menu | None = None
        self.bottom_frame: ttk.Frame | None = None
        # ---------------------------------------------------------------------
        lang = self.current_lang_strvar.get()
        self.message = MESSAGES[lang]
        self.root.title(self.message["title"])
        # --- menubar ---------------------------------------------------------
        self.menubar = tk.Menu(self.root)
        self.root.config(menu=self.menubar)
        # --- bottom frame ----------------------------------------------------
        self.bottom_frame = ttk.Frame(self.root, padding=20)
        self.bottom_frame.pack(fill="x", side="bottom")
        # --- title -----------------------------------------------------------
        self.root.title(self.message["title"])
        # --- menu ------------------------------------------------------------
        _menu = tk.Menu(self.menubar, tearoff=0)
        _menu.add_command(
            label=self.message["menu_open"], command=lambda: self.event_open_file()
        )
        _menu.add_command(
            label=self.message["menu_save"], command=lambda: self.event_save_file()
        )
        _menu.add_command(
            label=self.message["menu_save_as"],
            command=lambda: self.event_save_file_as(),
        )
        _menu.add_separator()
        _menu.add_command(
            label=self.message["menu_exit"], command=lambda: self.event_quit_app()
        )
        self.menubar.add_cascade(label=self.message["menu_file"], menu=_menu)
        # --- radio button ----------------------------------------------------
        lang = self.current_lang_strvar.get()
        _menu = tk.Menu(self.menubar, tearoff=0)
        _menu.add_radiobutton(
            label=self.message["rdo_lang_en"],
            variable=self.current_lang_strvar,
            value="en",
            command=lambda: self.event_switch_language(),
        )
        _menu.add_radiobutton(
            label=self.message["rdo_lang_ja"],
            variable=self.current_lang_strvar,
            value="ja",
            command=lambda: self.event_switch_language(),
        )
        self.menubar.add_cascade(label=self.message["menu_lang"], menu=_menu)
        # --- button ----------------------------------------------------------
        _btn = create_action_button(
            parent=self.bottom_frame,
            text=self.message["btn_exec"],
            command=lambda: self.event_exec(),
            style="",
        )
        _btn.pack(expand=True, pady=10)
        _btn = create_action_button(
            parent=self.bottom_frame,
            text=self.message["btn_exit"],
            command=lambda: self.event_quit_app(),
            style="",
        )
        _btn.pack(expand=True, pady=10)
