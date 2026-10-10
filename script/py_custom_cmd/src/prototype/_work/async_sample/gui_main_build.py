import asyncio
import threading
import tkinter as tk

# 提示された別ファイルのクラスをインポート
from async_download_handler import AsyncDownload
from async_rsync_handler import AsyncRsync
from async_web_info_handler import AsyncWebInfo


class MainWindow(AsyncDownload, AsyncRsync, AsyncWebInfo):
    def __init__(self, root: tk.Tk) -> None:
        self.root: tk.Tk = root
        self.root.title("asyncio.run + Tkinter")
        self.root.geometry("300x200")

        # メンバ変数としてUIパーツを初期化
        self.label1 = None
        self.label2 = None
        self.label3 = None

    def quit(self) -> None:
        self.root.quit()

    def build(self) -> None:
        # インスタンス変数（self.）にして、他のメソッドからアクセス可能にする
        self.label1 = tk.Label(self.root, text="タスク1: 待機中", font=("Meiryo", 12))
        self.label1.pack(pady=10)

        self.label2 = tk.Label(self.root, text="タスク2: 待機中", font=("Meiryo", 12))
        self.label2.pack(pady=10)

        self.label3 = tk.Label(self.root, text="タスク3: 待機中", font=("Meiryo", 12))
        self.label3.pack(pady=10)

        # argsには引数（今回は不要、またはself）をタプルで渡します
        threading.Thread(
            target=self.start_async_loop,
            daemon=True,
        ).start()

    async def task(self) -> None:
        # 各継承元クラスの非同期メソッドを、作成したラベルを渡して同時に並行実行
        await asyncio.gather(
            self.task_one(self.label1),
            self.task_two(self.label2),
            self.task_three(self.label3),
        )

    def start_async_loop(self):
        # 自身のtaskメソッドを実行
        asyncio.run(self.task())
