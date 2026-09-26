# --- Python library ----------------------------------------------------------
import re
import tkinter as tk
from tkinter import ttk

# ruff: isort: off
# --- my library --------------------------------------------------------------
from my_config import infosystem


# ruff: isort: on
# ruff: isort: off
# --- my modules --------------------------------------------------------------
# ruff: isort: on
# -----------------------------------------------------------------------------
class DebugLogWindow:
    def __init__(self, parent_root: tk.Tk) -> None:
        self.win = tk.Toplevel(parent_root, name="debug_log_win")
        self.win.title("📂 Debug Log Monitor")
        self.win.attributes("-topmost", True)

        # 親の最新の座標・サイズ情報を同期
        parent_root.update_idletasks()
        parent_x = parent_root.winfo_x()
        parent_y = parent_root.winfo_y()
        #parent_w = parent_root.winfo_width()

        # 📌 基準となるタイトルの高さ（約35px）を「ずらし幅」として使用
        title_height = 35  
        
        from my_config import infosystem
        current_step = getattr(infosystem, "win_cascade_step", 0)

        # 📌 最初の1個目は「親の右上端」にピタッと合わせる
        # 2個目以降は、タイトルの高さ分だけ「右」かつ「上」へずらしていく
        target_x = parent_x + ((current_step + 1) * title_height)
        target_y = parent_y - ((current_step + 3) * title_height)

        # Ubuntuの上部黒バー（システムバー）に潜り込まないための安全対策（Y座標の最低値）
        # もし画面上部（バーの下）に収まらない場合は下方向へカスケードさせます
        if target_y < 40:
            target_y = parent_y + (current_step * title_height)

        # 📌 geometryの適用（位置を設定）
        self.win.geometry(f"600x400+{target_x}+{target_y}")

        # カスケードのステップ更新（最大4枚まで重ねたらリセット）
        if current_step >= 3:
            infosystem.win_cascade_step = 0
        else:
            infosystem.win_cascade_step = current_step + 1
        # ---------------------------------------------------------------------
        cols = infosystem.columns if infosystem.columns > 0 else 80
        self.win.protocol("WM_DELETE_WINDOW", self.on_close)
        infosystem.log_window_active = True
        # ---------------------------------------------------------------------
        frame = ttk.Frame(self.win)
        frame.pack(fill="both", expand=True, padx=5, pady=5)
        self.text_area = tk.Text(
            frame,
            wrap="none",
            font=("Consolas", 9),
            bg="#1e1e1e",
            fg="#d4d4d4",
            width=cols,
            height=25,
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
        self.text_area.tag_configure("red", foreground="#ff6b6b")
        self.text_area.tag_configure("green", foreground="#4caf50")
        self.text_area.tag_configure("yellow", foreground="#ffeb3b")
        self.text_area.tag_configure("blue", foreground="#64b5f6")
        self.text_area.tag_configure("magenta", foreground="#e040fb")
        self.text_area.tag_configure("cyan", foreground="#00e5ff")
        self.text_area.tag_configure("underline", underline=True)
        self.ansi_regex = re.compile(r"\x1b\[([0-9;]*)m")

    def append_ansi_text(self, text: str) -> None:
        if not infosystem.log_window_active:
            return
        current_tags = set()
        parts = self.ansi_regex.split(text)
        for i, part in enumerate(parts):
            if i % 2 == 1:
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
            else:
                if part:
                    self.text_area.insert("end", part, tuple(current_tags))
        self.text_area.see("end")

    def on_close(self) -> None:
        # 📌 自分が閉じられたら、my_string の管理リストから自分自身を削除する
        from my_string import remove_gui_log_window
        remove_gui_log_window(self)
        
        # もし開いているサブウィンドウが完全にゼロになったらアクティブフラグを落とす
        from my_string import _gui_log_windows
        if not _gui_log_windows:
            infosystem.log_window_active = False

        self.win.destroy()
