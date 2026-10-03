"""async i/o"""

# --- python library ----------------------------------------------------------
import asyncio
import threading
from typing import Any


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import get_web_file_info  # 💡 本来の通信関数を確実にインポート
from common.utils import get_caller_name, message_warn


# --- main --------------------------------------------------------------------
class AsyncProcessHandler:
    ui_def: dict

    def __init__(self, window_instance: Any) -> None:
        self.win = window_instance  # MainWindowインスタンスへの参照
        self.is_cancelled = False  # キャンセルフラグを初期化

    def start_async_process(self) -> None:
        """バックグラウンドで非同期通信処理スレッドを安全に起動する"""
        _caller = get_caller_name()
        if self.win.is_running_async:
            message = self.ui_def["msg_warn_already_running"]
            message_warn(func_name=_caller, message=message, omit=False)
            return

        # 💡 🌟 重要: 実際に通信処理を通過する項目だけを
        # 正確にフィルタリングして分母(total_count)にする
        self.target_items = [
            item
            for item in self.win.info_comm.mdia.data
            if getattr(item, "is_target", False)
            and getattr(item, "entry_name", "") != "menu-entry"
        ]
        self.total_count = len(self.target_items)

        if self.total_count == 0:
            self.win.append_log("⚠ 処理対象がチェックされていません。")
            self.win.update_progress(0, 0, is_complete=True)  # 完了状態にする
            return

        self.is_cancelled = False
        self.win.append_log(f"［通信開始］対象件数: {self.total_count} 件")
        # 💡 初期状態を通知
        self.win.update_progress(0, self.total_count, is_complete=False)

        self.win.is_running_async = True

        if hasattr(self.win, "refresh_exec_button_text"):
            self.win.refresh_exec_button_text()

        t = threading.Thread(target=self._thread_entry, daemon=True)
        t.start()

    def cancel_async_process(self) -> None:
        """外部から通信中断を要求された際にフラグを立てるメソッド"""
        if self.win.is_running_async:
            self.is_cancelled = True
            self.win.append_log(
                "⏳ キャンセル処理を受け付けました。"
                "現在の通信タスク終了後に停止します..."
            )

    def _thread_entry(self) -> None:
        """💡 サブスレッドのエントリポイント"""
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        self.current_processed_count = 0

        def progress_notifier(log_msg: str) -> None:
            self.win.root.after(0, self.win.append_log, log_msg)

            if "✓ 完了" in log_msg:
                self.current_processed_count += 1
                # 💡 通信中は is_complete=False
                self.win.root.after(
                    0,
                    self.win.update_progress,
                    self.current_processed_count,
                    self.total_count,
                    False,
                )
            self.win.root.after(0, self.win.root.update)

        try:
            loop.run_until_complete(
                get_web_file_info(
                    self.win.info_comm, on_progress_callback=progress_notifier
                )
            )

            # 💡 通信ループが正常終了したら、バーを最大値にして「完了状態」へ更新する
            self.win.root.after(
                0,
                self.win.update_progress,
                self.total_count,
                self.total_count,
                True,  # is_complete = True
            )

        except Exception as e:
            message = f"❌ {self.ui_def.get('msg_error', 'Error')}: {e}"
            self.win.root.after(0, self.win.append_log, message)
        finally:
            loop.close()
            self.win.root.after(0, self._on_complete)

    def _on_complete(self) -> None:
        """【メインスレッド側】完了後の全体UI更新"""
        self.win.is_running_async = False
        if self.is_cancelled:
            self.win.append_log("🎉 キャンセル処理が完了しました。")
        else:
            self.win.append_log(
                "🎉 すべての通信処理が完了しました。データモデルを再読込します。"
            )
        # 表のデータのみを最新状態にクリア＆再ロード
        if hasattr(self.win, "reload_table_data"):
            self.win.reload_table_data()
        # ボタンのテキストを「更新/実行」に戻す
        if hasattr(self.win, "refresh_exec_button_text"):
            self.win.refresh_exec_button_text()
