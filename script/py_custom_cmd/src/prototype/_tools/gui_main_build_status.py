"""main window build status"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from tkinter import ttk


# --- main --------------------------------------------------------------------
class MainWindowBuildStatus:
    # 型チェッカー用の定義（親クラスや他モジュールで初期化される変数）
    root: tk.Tk
    ui_def: dict
    current_messages: dict[str, str]

    # インスタンス変数として参照を保持
    log_text_widget: tk.Text
    progress_bar: ttk.Progressbar
    progress_label: ttk.Label  # 「0 / 5 件」のようなテキスト表示用

    def _generate_status_monitor(self, parent_frame: tk.Widget) -> None:
        """テーブルの下部に5行のログモニターと処理件数バーを構築する"""
        # ステータス表示用のコンテナフレームを作成
        if hasattr(self, "log_text_widget") and self.log_text_widget.winfo_exists():
            return

        # ステータス表示用のコンテナフレームを作成
        status_frame = ttk.Frame(parent_frame, padding=(0, 10, 0, 0))
        status_frame.grid(row=3, column=0, columnspan=2, sticky="ew")

        status_frame.columnconfigure(0, weight=1)  # ログモニター側を伸縮
        status_frame.columnconfigure(1, weight=0)  # プログレスバー側は固定幅

        # --- 5行分のログモニター (Text + Scrollbar) ---
        log_container = ttk.Frame(status_frame)
        log_container.grid(row=0, column=0, sticky="nsew", padx=(0, 10))
        log_container.columnconfigure(0, weight=1)

        # 概ね5行分の高さ(height=5)を指定
        self.log_text_widget = tk.Text(
            log_container,
            height=5,
            wrap="char",
            state="disabled",
            font=("", 9),
            background="#f8fafc",
            foreground="#334155",
        )
        self.log_text_widget.grid(row=0, column=0, sticky="ew")

        log_scroll = ttk.Scrollbar(
            log_container, orient=tk.VERTICAL, command=self.log_text_widget.yview
        )
        self.log_text_widget.configure(yscrollcommand=log_scroll.set)
        log_scroll.grid(row=0, column=1, sticky="ns")

        # --- 処理件数のバー＆ラベルのコンテナ ---
        bar_container = ttk.Frame(status_frame)
        bar_container.grid(row=0, column=1, sticky="ns")

        self.progress_label = ttk.Label(
            bar_container, text="待機中 (0/0 件)", font=("", 9)
        )
        self.progress_label.pack(anchor="w", pady=(0, 2))

        self.progress_bar = ttk.Progressbar(
            bar_container, orient=tk.HORIZONTAL, length=220, mode="determinate"
        )
        self.progress_bar.pack(anchor="w")

        self.append_log("アプリケーションが起動しました。準備完了です。")

    def append_log(self, text: str) -> None:
        """ログモニターに1行追加し、最下部へ自動スクロールする"""
        if (
            not hasattr(self, "log_text_widget")
            or not self.log_text_widget.winfo_exists()
        ):
            return

        # 💡 サブスレッドから呼ばれた場合、メインスレッドへ安全にディスパッチする
        import threading

        if threading.current_thread() != threading.main_thread():
            self.root.after(0, self.append_log, text)
            return

        self.log_text_widget.configure(state="normal")
        self.log_text_widget.insert(tk.END, f"{text}\n")
        self.log_text_widget.configure(state="disabled")
        self.log_text_widget.see(tk.END)  # 最新ログへスクロール

    def update_progress(
        self, current: int, total: int, is_complete: bool = False
    ) -> None:
        """プログレスバーと進捗テキストを更新する"""
        if not hasattr(self, "progress_bar") or not self.progress_bar.winfo_exists():
            return

        import threading

        if threading.current_thread() != threading.main_thread():
            self.root.after(0, self.update_progress, current, total, is_complete)
            return

        if total > 0:
            percent = (current / total) * 100
            self.progress_bar["value"] = percent

            # 💡 🌟 完了フラグまたは進捗率が100%に達した場合はメッセージを変更する
            if is_complete or current >= total:
                # 多言語対応メッセージから取得。なければデフォルトテキスト
                complete_text = self.current_messages.get(
                    "lbl_status_complete", "✨ 処理完了"
                )
                self.progress_label.configure(
                    text=f"{complete_text} ({current} / {total} 件)"
                )
            else:
                self.progress_label.configure(
                    text=f"処理中... ({current} / {total} 件)"
                )
        else:
            self.progress_bar["value"] = 0
            self.progress_label.configure(text="対象データなし (0/0 件)")
