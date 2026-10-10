import asyncio


class AsyncRsync:
    # 非同期タスク3 (3秒ごとにカウント)
    async def task_three(self, label):
        for i in range(1, 11):
            await asyncio.sleep(3)
            label.config(text=f"タスク3: {i * 3}秒経過")
