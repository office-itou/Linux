#!/usr/bin/env python3
import tkinter as tk

from gui_main_build import MainWindow


def main() -> None:
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    root.protocol("WM_DELETE_WINDOW", app.quit)
    app.build()  # 【重要】mainloopの前に画面（UIパーツ）を組み立てて、スレッドを起動する
    root.mainloop()  # 画面を起動し、イベントを待機する（ここが終了するまで下には進まない）
    root.destroy()


if __name__ == "__main__":
    main()
