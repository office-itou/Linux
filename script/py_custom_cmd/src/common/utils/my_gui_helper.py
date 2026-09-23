#!/usr/bin/env python3
import json
import tkinter as tk

from collections.abc import Callable
from tkinter import ttk
from typing import Any


def load_ui_definition(json_path: str) -> dict[str, Any]:
    """JSONファイルからUI定義を読み込む"""
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)


def build_menu_bar(
    root: tk.Tk,
    menu_data: list[dict[str, Any]],
    messages: dict[str, str],
    commands: dict[str, Callable[[Any], None]],
    variables: dict[str, tk.Variable],
) -> tk.Menu:
    """JSONデータからTkinterメニューバーを動的に構築する汎用関数"""
    menubar = tk.Menu(root)

    for block in menu_data:
        menu_block = tk.Menu(menubar, tearoff=0)

        for item in block.get("items", []):
            item_type = item.get("type")

            if item_type == "separator":
                menu_block.add_separator()
                continue

            label = messages.get(item.get("label_key", ""), "")
            cmd = commands.get(item.get("command_name", ""), None)

            if item_type == "command":
                acc = item.get("accelerator", "")
                bind = item.get("bind", "")

                menu_block.add_command(label=label, command=cmd, accelerator=acc)
                if bind and cmd:
                    root.unbind_all(bind)
                    root.bind(bind, cmd)

            elif item_type == "radio":
                var = variables.get(item.get("variable_name", ""), None)
                val = item.get("value")

                menu_block.add_radiobutton(
                    label=label, variable=var, value=val, command=cmd
                )

        block_title = messages.get(block.get("title_key", ""), "")
        menubar.add_cascade(label=block_title, menu=menu_block)

    root.config(menu=menubar)
    return menubar


def build_buttons(
    parent: tk.Widget,
    button_data: list[dict[str, Any]],
    messages: dict[str, str],
    commands: dict[str, Callable[[Any], None]],
) -> list[ttk.Button]:
    """
    JSONデータから親要素（ウィンドウやフレーム）内にボタンを動的に配置する汎用関数

    :param parent: ボタンを配置する親ウィジェット (tk.Tk, tk.Frame など)
    :param button_data: JSONのボタン定義リスト
    :param messages: 現在の言語のメッセージ辞書
    :param commands: 文字列キーと実際の関数をマッピングした辞書
    """
    created_buttons = []

    for btn_info in button_data:
        label = messages.get(btn_info.get("label_key", ""), "")
        cmd = commands.get(btn_info.get("command_name", ""), None)

        # ttk.Buttonの作成
        btn = ttk.Button(parent, text=label, command=cmd)

        # gridレイアウトの設定取得
        grid_info = btn_info.get("grid_layout", {})

        # gridのパラメータを動的にマッピング (省略された場合はデフォルト値)
        grid_kwargs = {
            "row": grid_info.get("row", 0),
            "column": grid_info.get("column", 0),
            "rowspan": grid_info.get("row_span", 1),
            "columnspan": grid_info.get("column_span", 1),
            "padx": grid_info.get("padx", 0),
            "pady": grid_info.get("pady", 0),
            "sticky": grid_info.get("sticky", ""),
        }

        # グリッド配置を実行
        btn.grid(**grid_kwargs)
        created_buttons.append(btn)

    return created_buttons
