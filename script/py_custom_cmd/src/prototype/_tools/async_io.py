"""async i/o"""

# --- python library ----------------------------------------------------------
import asyncio
import threading
from typing import Any


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import get_web_file_info
from common.utils import get_caller_name, message_alert, message_warn


# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# --- main --------------------------------------------------------------------
class AsyncProcessHandler:
    ui_def: dict

    def __init__(self, window_instance: Any) -> None:
        self.win = window_instance  # MainWindowのインスタンスへの参照

    def start_async_process(self) -> None:
        """バックグラウンドで非同期通信処理スレッドを安全に起動する"""
        _caller = get_caller_name()
        if self.win.is_running_async:
            message = self.ui_def["msg_warn_already_running"]
            message_warn(
                func_name=_caller,
                message=message,
                omit=False,
            )
            return
        self._sync_view_to_model()
        self.win.is_running_async = True
        threading.Thread(target=self._run_async_loop, daemon=True).start()

    def _sync_view_to_model(self):
        pass

    def _run_async_loop(self):
        """【サブスレッド側で動作】独立したイベントループで非同期通信を処理"""
        _caller = get_caller_name()
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(get_web_file_info(self.win.info_comm))
            loop.close()
        except Exception as e:  # noqa: BLE001
            message = f"❌ {self.ui_def["msg_error"]}: {e}"
            message_alert(
                func_name=_caller,
                message=message,
                omit=False,
            )
        finally:
            # メインスレッドに対してスレッドセーフに完了通知を送る
            self.win.root.after(0, self._on_complete)

    def _on_complete(self) -> None:
        """【メインスレッド側で動作】完了後のUI更新トリガー"""
        self.win.is_running_async = False
        self.win.generate_window()
        self._highlight_updated_rows()

    def _highlight_updated_rows(self) -> None:
        pass
