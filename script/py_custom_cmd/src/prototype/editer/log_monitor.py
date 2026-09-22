# log_monitor.py
import re
import tkinter as tk
from tkinter import ttk

from my_config import infosystem


class DebugLogWindow:
    def __init__(self, parent_root: tk.Tk) -> None:
        self.win = tk.Toplevel(parent_root)
        self.win.title("📂 Debug Log Monitor")

        cols = infosystem.columns if infosystem.columns > 0 else 80

        self.win.protocol("WM_DELETE_WINDOW", self.on_close)
        infosystem.log_window_active = True

        frame = ttk.Frame(self.win)
        frame.pack(fill="both", expand=True, padx=5, pady=5)

        # 📌 width=cols を指定することで、指定文字数がぴったり収まる幅になります。
        # height=20 などで縦の行数（高さ）も指定できます。
        self.text_area = tk.Text(
            frame, wrap="none", font=("Consolas", 10), bg="#1e1e1e", fg="#d4d4d4",
            width=cols, height=25
        )
        scrollbar_y = ttk.Scrollbar(
            frame, orient="vertical", command=self.text_area.yview
        )
        scrollbar_x = ttk.Scrollbar(
            frame, orient="horizontal", command=self.text_area.xview
        )

        self.text_area.configure(
            yscrollcommand=scrollbar_y.set, xscrollcommand=scrollbar_x.set
        )

        scrollbar_y.pack(side="right", fill="y")
        scrollbar_x.pack(side="bottom", fill="x")
        self.text_area.pack(side="left", fill="both", expand=True)

        # 📌 Tkinterのタグ設定（色や装飾の定義）
        # my_colors.py の定義に合わせて適宜追加してください
        self.text_area.tag_configure("red", foreground="#ff6b6b")
        self.text_area.tag_configure("green", foreground="#4caf50")
        self.text_area.tag_configure("yellow", foreground="#ffeb3b")
        self.text_area.tag_configure("blue", foreground="#64b5f6")
        self.text_area.tag_configure("magenta", foreground="#e040fb")
        self.text_area.tag_configure("cyan", foreground="#00e5ff")
        self.text_area.tag_configure("underline", underline=True)

        # ANSI カラーコード解析用の正規表現
        self.ansi_regex = re.compile(r"\x1b\[([0-9;]*)m")

    def append_ansi_text(self, text: str) -> None:
        """ANSIカラーコードを解析して色付きでテキストを挿入する"""
        if not infosystem.log_window_active:
            return

        # 状態保持用 (現在適用されているタグのセット)
        current_tags = set()

        parts = self.ansi_regex.split(text)

        for i, part in enumerate(parts):
            if i % 2 == 1:
                # カラーコード部分の処理 (例: "31", "4", "0")
                codes = part.split(";")
                for code in codes:
                    if code == "0" or code == "":
                        current_tags.clear()  # リセット
                    elif code == "4":
                        current_tags.add("underline")  # 下線
                    elif code in ("31", "91"):
                        current_tags.add("red")
                    elif code in ("32", "92"):
                        current_tags.add("green")
                    elif code in ("33", "93"):
                        current_tags.add("yellow")
                    elif code in ("34", "94"):
                        current_tags.add("blue")
                    elif code in ("35", "95"):
                        current_tags.add("magenta")
                    elif code in ("36", "96"):
                        current_tags.add("cyan")
                    # 背景色(41〜47)やその他の装飾も必要ならここに追加可能
            else:
                # 通常の文字列部分の処理
                if part:
                    # 現在有効なタグのリストを渡して挿入
                    self.text_area.insert("end", part, tuple(current_tags))

        self.text_area.see("end")  # 自動スクロール

    def on_close(self) -> None:
        infosystem.log_window_active = False
        self.win.destroy()
