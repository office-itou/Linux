from collections.abc import Callable
from tkinter import ttk
from typing import Any


def create_action_button(
    parent: ttk.Frame, text: str, command: Callable[[], None], style: str = ""
) -> ttk.Button:
    """汎用的な押しボタン（型宣言・Ruff対応版）

    Args:
        parent: ボタンを配置する親フレーム
        text: ボタンに表示する文字
        command: クリック時に実行される関数
        style: ttkのスタイル名（オプション）
    """
    btn = ttk.Button(parent, text=text, command=command)
    if style:
        btn.config(style=style)
    return btn


def create_button_row(
    parent_frame: ttk.Frame, button_configs: list[dict[str, Any]]
) -> list[ttk.Button]:
    """複数のボタンを1行（横並び）にまとめて配置するサンプル関数

    Args:
        parent_frame: ボタンを横並びにする親フレーム
        button_configs: ボタン設定が入った辞書のリスト
                        [{"text": "保存", "command": func}, ...]
    """
    created_buttons: list[ttk.Button] = []

    for config in button_configs:
        text: str = config.get("text", "Button")
        command: Callable[[], None] = config.get("command", lambda: None)
        style: str = config.get("style", "")

        # ボタンを生成して横並び(pack)で敷き詰める
        btn = create_action_button(
            parent_frame, text=text, command=command, style=style
        )
        btn.pack(side="left", padx=10, pady=5)
        created_buttons.append(btn)

    return created_buttons
