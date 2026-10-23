# main.py
import tkinter as tk

# --- my library --------------------------------------------------------------
from my_config import infosystem
from my_mem_usage import print_peak_memory
from my_message import get_caller_name, message_elapsed, message_end, message_start
from my_time import TimeElapsed

# --- GUI Window Module ------------------------------------------------------
from gui_window import MainWindow  # 💡 切り出した画面クラスをインポート


if __name__ == "__main__":
    # システム初期化とプロファイル計測のセットアップ
    infosystem.initialize(is_gui=True)
    caller = get_caller_name()
    time_elapsed = TimeElapsed()
    message_start(caller)
    # メインウィンドウ生成
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    # 終了プロトコルの紐付けとメインループ開始
    root.protocol("WM_DELETE_WINDOW", app.event_quit_app)
    root.mainloop()
    # 終了後のパフォーマンスログ出力
    message_end(caller)
    message_elapsed(caller, time_elapsed.elapsed(), omit=True)
    print_peak_memory()
    root.destroy()
