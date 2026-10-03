"""main window build buttons"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import build_buttons


# --- main --------------------------------------------------------------------
class MainWindowBuildButtons:
    # 型チェッカー用の定義（親・他クラスで初期化される変数）
    root: tk.Tk
    ui_def: dict
    current_messages: dict[str, str]
    
    # 💡 制御対象となるボタンインスタンスの保持用リスト
    exec_buttons_list: list[ttk.Button]

    def _generate_bottom_buttons(self, cmd_map: dict[str, Callable]) -> None:
        """ボトムエリアのボタン群を構築して配置する"""
        # 💡 リストを安全に初期化・クリーンアップ
        if not hasattr(self, "exec_buttons_list") or self.exec_buttons_list is None:
            self.exec_buttons_list = []
        else:
            self.exec_buttons_list.clear()

        _bottom_frame = ttk.Frame(self.root, padding=10)
        _bottom_frame.pack(fill="x", side="bottom")

        _layout_info = self.ui_def.get("button_layout", {})
        _side_input = _layout_info.get("side", "right")
        _padx = _layout_info.get("padx", 0)
        _pady = _layout_info.get("pady", 0)
        _button_container = ttk.Frame(_bottom_frame)

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

        # 💡 重複ループを解消し、フラットに1つずつボタンのコマンド属性を検証して格納
        for child in _button_container.winfo_children():
            if isinstance(child, ttk.Button):
                cmd_str = str(child.cget("command"))
                if "event_update" in cmd_str or "event_exec" in cmd_str:
                    self.exec_buttons_list.append(child)

    def refresh_exec_button_text(self) -> None:
        """💡 通信状態に合わせて対象ボタンのテキストを『
        実行/更新』⇄『キャンセル』に切り替える"""
        if not hasattr(self, "exec_buttons_list"):
            return

        is_running = getattr(self, "is_running_async", False)

        for btn in self.exec_buttons_list:
            if not btn.winfo_exists():
                continue

            if is_running:
                # 通信中は「キャンセル」表示にする
                cancel_text = self.current_messages.get("btn_cancel", "❌ キャンセル")
                btn.configure(text=cancel_text)
            else:
                # 待機・完了時は元のコマンド名に応じた文言に戻す
                cmd_str = str(btn.cget("command"))
                if "event_update" in cmd_str:
                    exec_text = self.current_messages.get("btn_update", "Update")
                else:
                    exec_text = self.current_messages.get("btn_exec", "Run")
                btn.configure(text=exec_text)
