"""base_handler.py"""

# --- python library ----------------------------------------------------------
import asyncio
import threading
import tkinter as tk
from typing import Any, Callable


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import (
    InfoCommon,
    InfoWebFile,
)
from common.utils import debug_logger, get_caller_name, message_warn
# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
# ruff: isort: on


class BaseAsyncProcessHandler:
    _process_prefix: str = "async"

    root: tk.Tk

    current_messages: dict[str, str]

    info_comm: InfoCommon
    info_webfile: InfoWebFile
    datas_map: dict[str, list[Any]]

    append_log: Callable
    refresh_exec_button_text: Callable
    reload_table_data: Callable
    update_progress: Callable

    def __init__(self) -> None:
        self._loop: asyncio.AbstractEventLoop | None = None
        self.total_count = 0
        self.current_processed_count = 0

    # 💡 機能ごとの個別フラグを動的に参照・退避させるプロパティ群
    @property
    def is_running_async(self) -> bool:
        return getattr(self, f"is_running_{self._process_prefix}", False)

    @is_running_async.setter
    def is_running_async(self, value: bool) -> None:
        setattr(self, f"is_running_{self._process_prefix}", value)

    @property
    def is_cancelled(self) -> bool:
        return getattr(self, f"is_cancelled_{self._process_prefix}", False)

    @is_cancelled.setter
    def is_cancelled(self, value: bool) -> None:
        setattr(self, f"is_cancelled_{self._process_prefix}", value)

    # 💡 画面上の「いずれかの非同期処理が走っているか」を確認するための
    # グローバル判定メソッド
    def is_any_process_running(self) -> bool:
        return any(
            [
                getattr(self, "is_running_download", False),
                getattr(self, "is_running_rsync", False),
                getattr(self, "is_running_web_info", False),
            ]
        )

    @debug_logger
    def _on_complete(self) -> None:
        """処理完了時のGUI側イベント（共通化）"""
        self.is_running_async = False  # 個別フラグが False になる
        if self.is_cancelled:
            _message = self.current_messages.get(
                "msg_info_cancel_complete", "🎉 Cancellation completed."
            )
        else:
            _message = self.current_messages.get(
                "msg_info_complete_reload", "🎉 Process completed successfully."
            )
        self.append_log(_message)
        if hasattr(self, "reload_table_data"):
            self.reload_table_data()
        if hasattr(self, "refresh_exec_button_text"):
            self.refresh_exec_button_text()

    @debug_logger
    def cancel_async_process(self) -> None:
        """外部（GUIボタン等）から非同期タスクを即時キャンセルする共通インターフェース"""
        if not self.is_running_async:
            return

        self.is_cancelled = True  # 個別フラグが True になる
        _message = self.current_messages.get(
            "msg_info_cancel_accepted", "⏳ Cancellation request accepted. Stopping..."
        )
        self.append_log(_message)

        if self._loop and self._loop.is_running():

            def _instant_cancel():
                if hasattr(self, "info_webfile") and hasattr(
                    self.info_webfile, "_active_tasks"
                ):
                    for _task in self.info_webfile._active_tasks:
                        if not _task.done():
                            _task.cancel()
                for _task in asyncio.all_tasks(self._loop):
                    if not _task.done():
                        _task.cancel()

            self._loop.call_soon_threadsafe(_instant_cancel)

    @debug_logger
    def _progress_notifier(self, log_msg: str, is_item_complete: bool = False) -> None:
        """ログ出力とプログレスバーを更新するコールバック関数"""
        if self.is_cancelled:
            if self._loop and self._loop.is_running():
                self._loop.call_soon_threadsafe(
                    lambda: [
                        t.cancel()
                        for t in asyncio.all_tasks(self._loop)
                        if not t.done()
                    ]
                )
            return

        self.root.after(0, self.append_log, log_msg)

        if is_item_complete:
            self.current_processed_count += 1
            self.root.after(
                0,
                self.update_progress,
                self.current_processed_count,
                self.total_count,
                False,
            )

    @debug_logger
    def _prepare_start(self) -> bool:
        """スレッド起動前の共通バリデーション"""
        _caller = get_caller_name()
        # 💡 個別ではなく「アプリ全体で何か1つでも実行中なら多重起動を防止」にする
        if self.is_any_process_running():
            _message = self.current_messages.get(
                "msg_warn_already_running", "Already running"
            )
            message_warn(func_name=_caller, message=_message, omit=False)
            return False

        self.is_cancelled = False  # 個別フラグをリセット
        self.current_processed_count = 0
        return True

    @debug_logger
    def _start_thread(self, target_method) -> None:
        """バックグラウンドスレッドで処理を開始する共通メソッド"""
        self.is_running_async = True  # 個別フラグが True になる
        if hasattr(self, "refresh_exec_button_text"):
            self.refresh_exec_button_text()

        _t = threading.Thread(target=target_method, daemon=True)
        _t.start()
