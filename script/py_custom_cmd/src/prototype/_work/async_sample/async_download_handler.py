import asyncio


class AsyncDownload:
    # 非同期タスク2 (2秒ごとにカウント)
    async def task_two(self, label):
        for i in range(1, 11):
            await asyncio.sleep(2)
            label.config(text=f"タスク2: {i * 2}秒経過")
