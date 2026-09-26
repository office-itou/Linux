"""main window build"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk


# --- my library --------------------------------------------------------------
# ruff: isort: off
from my_gui_build_helper import build_menu_bar

# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
from gui_main_build_buttons import MainWindowBuildButtons
from gui_main_build_tables import MainWindowBuildTables


# ruff: isort: on
# --- main --------------------------------------------------------------------
# 🌟 パーツクラスたちを多重継承で合体させる
class MainWindowBuild(MainWindowBuildButtons, MainWindowBuildTables):
    root: tk.Tk
    current_lang_strvar: tk.StringVar
    current_messages: dict[str, str]
    ui_def: dict
    _get_command_map: Callable[[], dict[str, Callable]]
    _get_variable_map: Callable[[], dict[str, tk.Variable]]

    def generate_window(self) -> None:
        """generate screen"""
        for child in self.root.winfo_children():
            if child.winfo_exists() and "debug_log_win" not in str(child):
                try:
                    child.destroy()
                except Exception:
                    pass
        # --- language settings and message updates ---------------------------
        from my_config import infosystem

        infosystem.lang = self.current_lang_strvar.get()
        self.current_messages = self.ui_def["messages"].get(infosystem.lang, {})
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
        # --- 🌟 ボタン処理の呼び出し (別ファイルから引き継いだメソッド) -----------
        self._generate_bottom_buttons(cmd_map=_cmd_map)
        # --- generate center mainframe  --------------------------------------
        _main_frame = ttk.Frame(self.root, padding=10)
        _main_frame.pack(fill=tk.BOTH, expand=True)
        _main_frame.columnconfigure(0, weight=1)
        _main_frame.rowconfigure(0, weight=1)
        _main_frame.rowconfigure(1, weight=1)
        # --- 🌟 テーブル処理の呼び出し (別ファイルから引き継いだメソッド) ---------
        self._generate_center_tables(parent_frame=_main_frame)
