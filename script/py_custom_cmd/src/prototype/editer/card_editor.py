# card_editor.py
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk
from typing import Any


class CardEditorWindow:
    def __init__(
        self,
        parent_root: tk.Tk,
        data: list[dict[str, Any]],
        start_index: int,
        lang_dict: dict[str, str],
        on_confirm_callback: Callable[[], None],
    ) -> None:
        self.root: tk.Tk = parent_root
        self.data: list[dict[str, Any]] = data
        self.card_index: int = start_index
        self.t: dict[str, str] = lang_dict
        self.on_confirm_callback: Callable[[], None] = on_confirm_callback
        self.card_entries: dict[str, ttk.Entry] = {}

        # サブウィンドウの構築
        self.win: tk.Toplevel = tk.Toplevel(self.root)
        self.win.geometry("600x720")
        self.win.wait_visibility()
        self.win.grab_set()

        # UIコンポーネントの作成
        self.title_label: ttk.Label = ttk.Label(
            self.win, text="", font=("Arial", 12, "bold"), padding=10
        )
        self.title_label.pack(fill="x")

        # 中央メインフレーム（スクロール領域）
        main_frame: ttk.Frame = ttk.Frame(self.win)
        main_frame.pack(fill="both", expand=True, padx=10, pady=5)

        self.canvas: tk.Canvas = tk.Canvas(
            main_frame, borderwidth=0, highlightthickness=0
        )
        self.v_scroll: ttk.Scrollbar = ttk.Scrollbar(
            main_frame, orient="vertical", command=self.canvas.yview
        )
        self.scroll_frame: ttk.Frame = ttk.Frame(self.canvas, padding=10)

        self.canvas.configure(yscrollcommand=self.v_scroll.set)
        self.canvas_window: int = self.canvas.create_window(
            (0, 0), window=self.scroll_frame, anchor="nw"
        )

        self.scroll_frame.bind(
            "<Configure>",
            lambda e: self.canvas.configure(scrollregion=self.canvas.bbox("all")),
        )
        self.canvas.bind(
            "<Configure>",
            lambda e: self.canvas.itemconfig(self.canvas_window, width=e.width),
        )

        self.v_scroll.pack(side="right", fill="y")
        self.canvas.pack(side="left", fill="both", expand=True)

        # 下部操作コントロール用フレーム
        bottom_frame: ttk.Frame = ttk.Frame(self.win, padding=10)
        bottom_frame.pack(fill="x", side="bottom")

        nav_frame: ttk.Frame = ttk.Frame(bottom_frame)
        nav_frame.pack(pady=5)

        self.btn_prev: ttk.Button = ttk.Button(
            nav_frame,
            text="◀ "
            + (
                "前へ"
                if self.t.get("btn_confirm") == "✅ 変更を確定して戻る"
                else "Prev"
            ),
            command=self.go_prev,
        )
        self.btn_prev.pack(side="left", padx=15)

        self.btn_next: ttk.Button = ttk.Button(
            nav_frame,
            text=(
                "次へ"
                if self.t.get("btn_confirm") == "✅ 変更を確定して戻る"
                else "Next"
            )
            + " ▶",
            command=self.go_next,
        )
        self.btn_next.pack(side="left", padx=15)

        btn_save: ttk.Button = ttk.Button(
            bottom_frame, text=self.t["btn_confirm"], command=self.confirm_and_close
        )
        btn_save.pack(pady=5)

        # 初期データの読み込み
        self.load_record_to_ui()

    def load_record_to_ui(self) -> None:
        item_data: dict[str, Any] = self.data[self.card_index]

        # ウィンドウタイトルの動的設定
        title_key: str = (
            "version"
            if "version" in item_data
            else ("entry_name" if "entry_name" in item_data else "")
        )
        title_val: Any = (
            item_data.get(title_key, self.card_index) if title_key else self.card_index
        )
        self.win.title(self.t["card_title"].format(ver=title_val))

        # 上部ステータスの更新
        status_text: str = f"Record: {self.card_index + 1} / {len(self.data)}"
        self.title_label.config(
            text=f"📌 {status_text}  -  [{title_val}]", anchor="center"
        )

        # 既存のエントリをクリアして再描画
        for widget in self.scroll_frame.winfo_children():
            widget.destroy()

        self.card_entries.clear()
        for key, val in item_data.items():
            row_frame: ttk.Frame = ttk.Frame(self.scroll_frame)
            row_frame.pack(fill="x", pady=4, padx=5)

            lbl_text: str = self.t.get(key, key)
            label: ttk.Label = ttk.Label(
                row_frame,
                text=lbl_text,
                font=("Arial", 10, "bold"),
                width=18,
                anchor="w",
            )
            label.pack(side="left", padx=5)

            entry: ttk.Entry = ttk.Entry(row_frame, font=("Arial", 10))
            entry.pack(side="left", fill="x", expand=True, padx=5)
            entry.insert(0, str(val))

            self.card_entries[key] = entry

        # ボタンの有効/無効化
        self.btn_prev.config(state="normal" if self.card_index > 0 else "disabled")
        self.btn_next.config(
            state="normal" if self.card_index < len(self.data) - 1 else "disabled"
        )

    def save_ui_to_memory(self) -> None:
        if self.card_entries:
            for k, entry in self.card_entries.items():
                self.data[self.card_index][k] = entry.get()

    def go_prev(self) -> None:
        self.save_ui_to_memory()
        if self.card_index > 0:
            self.card_index -= 1
            self.load_record_to_ui()

    def go_next(self) -> None:
        self.save_ui_to_memory()
        if self.card_index < len(self.data) - 1:
            self.card_index += 1
            self.load_record_to_ui()

    def confirm_and_close(self) -> None:
        self.save_ui_to_memory()
        self.on_confirm_callback()  # メイン画面のテーブルをリフレッシュ
        self.win.destroy()
