# --- Python library ----------------------------------------------------------
import re
import tkinter as tk
from tkinter import ttk


# ruff: isort: off
# --- my library --------------------------------------------------------------
from common.utils import infosystem


# ruff: isort: on
# ruff: isort: off
# --- my modules --------------------------------------------------------------
# ruff: isort: on
# -----------------------------------------------------------------------------
class DebugLogWindow:
    def __init__(self, parent_root: tk.Tk) -> None:
        self.parent_root = parent_root  # 💡 親の参照を保持
        self.win = tk.Toplevel(parent_root, name="debug_log_win")
        self.win.title("📂 Debug Log Monitor")

        # 💡 修正: OS全体の最前面指定（-topmost）をやめ、
        # 親ウィンドウ（parent_root）に対してのみ常に前面に位置付ける
        # （背後に隠れない）設定にします
        self.win.transient(parent_root)

        # 親の最新の座標・サイズ情報を同期
        parent_root.update_idletasks()
        parent_x = parent_root.winfo_x()
        parent_y = parent_root.winfo_y()

        # 📌 基準となるタイトルの高さ（約35px）を「ずらし幅」として使用
        title_height = 35

        from common.utils import infosystem

        current_step = getattr(infosystem, "win_cascade_step", 0)

        # 📌 位置計算
        target_x = parent_x + ((current_step + 1) * title_height)
        target_y = parent_y - ((current_step + 3) * title_height)

        if target_y < 40:
            target_y = parent_y + (current_step * title_height)

        self.win.geometry(f"800x600+{target_x}+{target_y}")

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
        """💡 ウィンドウが閉じられる時の処理"""
        # 1. ログウィンドウのグローバル管理リストから自分を削除
        from common.utils import remove_gui_log_window

        remove_gui_log_window(self)

        from common.utils import gui_log_windows

        if not gui_log_windows:
            infosystem.log_window_active = False

        infosystem.debug = getattr(self, "saved_debug", False)
        infosystem.debugout = getattr(self, "saved_debugout", False)

        # 2. 💡 【重要】親ウィンドウ(MainWindow)にアタッチされている
        # app インスタンスを探し、ラジオボタンの連動変数を False にリセットします。
        # これによりXで閉じてもメニューが「オフ」になります。
        main_window = getattr(self.parent_root, "app", None)
        if main_window and hasattr(main_window, "current_monitor_boolvar"):
            main_window.current_monitor_boolvar.set(False)

        # 3. 実際のウィンドウ破棄
        self.win.destroy()
