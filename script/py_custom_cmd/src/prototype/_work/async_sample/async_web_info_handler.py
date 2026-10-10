import asyncio


class AsyncWebInfo:
    # 非同期タスク1 (1秒ごとにカウント)
    async def task_one(self, label):
        for i in range(1, 11):
            await asyncio.sleep(1)
            label.config(text=f"タスク1: {i}秒経過")
