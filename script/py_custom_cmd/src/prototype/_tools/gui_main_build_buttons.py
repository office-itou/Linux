"""main window build buttons"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk


# --- my library --------------------------------------------------------------
# ruff: isort: off
from my_gui_build_helper import build_buttons


# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# --- main --------------------------------------------------------------------
class MainWindowBuildButtons:
    # 型チェッカー用の定義（親・他クラスで初期化される変数）
    root: tk.Tk
    ui_def: dict
    current_messages: dict[str, str]

    def _generate_bottom_buttons(self, cmd_map: dict[str, Callable]) -> None:
        """ボトムエリアのボタン群を構築して配置する"""
        _bottom_frame = ttk.Frame(self.root, padding=10)
        _bottom_frame.pack(fill="x", side="bottom")
        # JSONからボタン配置全体の指示を取得
        _layout_info = self.ui_def.get("button_layout", {})
        _side_input = _layout_info.get("side", "right")
        _padx = _layout_info.get("padx", 0)
        _pady = _layout_info.get("pady", 0)
        _button_container = ttk.Frame(_bottom_frame)
        # 配置位置の出し分け解決
        if _side_input == "left":
            _button_container.pack(side="left", padx=_padx, pady=_pady)
        elif _side_input == "center":
            _button_container.pack(side="top", anchor="center", padx=_padx, pady=_pady)
        else:
            _button_container.pack(side="right", padx=_padx, pady=_pady)
        build_buttons(
            parent=_button_container,
            button_data=self.ui_def["buttons"],
            messages=self.current_messages,
            commands=cmd_map,
        )
