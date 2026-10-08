"""async i/o"""

# --- python library ----------------------------------------------------------
import asyncio
import threading
from typing import Any

# --- my library --------------------------------------------------------------
# ruff: isort: of
from common.utils import (
    get_caller_name,
    message_warn,
)


# --- main --------------------------------------------------------------------
class AsyncProcessHandler:
    current_messages: dict[str, str]

    def __init__(self, window_instance: Any) -> None:
        self.win = window_instance
        self.is_cancelled = False

    # @debug_logger
    def _on_complete(self) -> None:
        self.win.is_running_async = False
        if self.is_cancelled:
            _message = self.win.current_messages.get(
                "msg_info_cancel_complete",
                "🎉 The cancellation process has been completed.",
            )
        else:
            _message = self.win.current_messages.get(
                "msg_info_complete_reload",
                "🎉 All communication processes have completed.\n"
                "Reloading the data model.",
            )
        self.win.append_log(_message)
        if hasattr(self.win, "reload_table_data"):
            self.win.reload_table_data()
        if hasattr(self.win, "refresh_exec_button_text"):
            self.win.refresh_exec_button_text()

    # -------------------------------------------------------------------------
    # @debug_logger
    def cancel_async_process(self) -> None:
        _message = f"{
            self.win.current_messages.get(
                'msg_info_cancel_accepted',
                (
                    '⏳ The cancellation request has been accepted.\n'
                    'It will stop after the current communication task completes....'
                ),
            )
        }:"
        if self.win.is_running_async:
            self.is_cancelled = True
            self.win.append_log(_message)
            if hasattr(self, "_loop") and self._loop.is_running():

                def _instant_cancel():
                    if hasattr(self.win.info_webfile, "_active_tasks"):
                        for _task in self.win.info_webfile._active_tasks:
                            if not _task.done():
                                _task.cancel()
                    for _task in asyncio.all_tasks(self._loop):
                        if not _task.done():
                            _task.cancel()

                self._loop.call_soon_threadsafe(_instant_cancel)

    # =========================================================================
    # a block that retrieves file information from the web.
    # =========================================================================
    # @debug_logger
    def _thread_entry(self) -> None:
        _loop = asyncio.new_event_loop()
        asyncio.set_event_loop(_loop)
        self._loop = _loop
        self.current_processed_count = 0

        # ---------------------------------------------------------------------
        def _progress_notifier(log_msg: str) -> None:
            if self.is_cancelled:

                def _safe_cancel():
                    for _task in asyncio.all_tasks(_loop):
                        _task.cancel()

                _loop.call_soon_threadsafe(_safe_cancel)
                return
            self.win.root.after(0, self.win.append_log, log_msg)
            _message = self.win.current_messages.get(
                "msg_info_complete", "✓ Completed."
            )
            if _message in log_msg:
                self.current_processed_count += 1
                self.win.root.after(
                    0,
                    self.win.update_progress,
                    self.current_processed_count,
                    self.total_count,
                    False,
                )
            # self.win.root.after(0, self.win.root.update)

        # ---------------------------------------------------------------------
        try:
            self.win.info_webfile.on_progress_callback = _progress_notifier
            _loop.run_until_complete(self.win.info_webfile.get_web_file_info())
            # -----------------------------------------------------------------
            if not self.is_cancelled:
                self.win.root.after(
                    0,
                    self.win.update_progress,
                    self.total_count,
                    self.total_count,
                    True,
                )
        except asyncio.CancelledError:
            _message = self.win.current_messages.get(
                "msg_info_cancel_progress", "⏳ Cancellation in progress..."
            )
            self.win.root.after(0, self.win.append_log, _message)
        except Exception as e:
            _message = (
                f"{self.win.current_messages.get('msg_error', 'Already Error')}: {e}"
            )
            self.win.root.after(0, self.win.append_log, _message)
        finally:
            try:
                pending_tasks = asyncio.all_tasks(_loop)
                if pending_tasks:
                    _loop.run_until_complete(asyncio.wait(pending_tasks, timeout=2.0))
            except Exception:
                pass
            _loop.close()
            # print("session close")
            self.win.root.after(0, self._on_complete)

    # @debug_logger
    def start_async_process(self) -> None:
        """Safely launch an asynchronous communication thread in the background."""
        _caller = get_caller_name()
        if self.win.is_running_async:
            _message = self.win.current_messages.get(
                "msg_warn_already_running", "Already running"
            )
            message_warn(func_name=_caller, message=_message, omit=False)
            return
        # --- listing ---------------------------------------------------------
        _active_data = self.win.datas_map.get("active_table", [])
        self.target_items = [
            _item
            for _item in _active_data
            if getattr(_item, "target_flag", "x") == "o"
            and getattr(_item, "entry_flag", "") == "o"
        ]
        # --- counter ---------------------------------------------------------
        self.total_count = len(self.target_items)
        if self.total_count == 0:
            _message = self.win.current_messages.get(
                "msg_warn_not_selected", "⚠ No items have been selected for processing."
            )
            self.win.append_log(_message)
            self.win.update_progress(0, 0, is_complete=True)
            return
        _key = "msg_info_target_info"
        _default = "Communication target"
        _message = (
            f"{self.win.current_messages.get(_key, _default)}:"
            f" {self.total_count} "
            f"{self.win.current_messages.get('msg_info_target_items', 'items')}"
        )
        self.win.append_log(_message)
        # ---------------------------------------------------------------------
        self.is_cancelled = False
        self.win.update_progress(0, self.total_count, is_complete=False)
        self.win.is_running_async = True
        if hasattr(self.win, "refresh_exec_button_text"):
            self.win.refresh_exec_button_text()
        _t = threading.Thread(target=self._thread_entry, daemon=True)
        _t.start()

    # =========================================================================
    # a block that downloads a file.
    # =========================================================================
    def _thread_download_entry(self) -> None:
        import asyncio
        from datetime import datetime

        _loop = asyncio.new_event_loop()
        asyncio.set_event_loop(_loop)
        self._loop = _loop  # 即時キャンセル用に保持
        self.current_processed_count = 0

        _active_data = self.win.datas_map.get("active_table", [])
        _selected_items = [
            _item
            for _item in _active_data
            if getattr(_item, "target_flag", "x") == "o"
            and getattr(_item, "entry_flag", "") == "o"
        ]
        self.total_count = len(_selected_items)
        self._is_download_phase = False

        def _progress_notifier(log_msg: str) -> None:
            if self.is_cancelled:

                def _safe_cancel():
                    for _task in asyncio.all_tasks(_loop):
                        _task.cancel()

                _loop.call_soon_threadsafe(_safe_cancel)
                return
            self.win.root.after(0, self.win.append_log, log_msg)
            _message = self.win.current_messages.get(
                "msg_info_complete", "✓ Completed."
            )
            if self._is_download_phase:
                if _message in log_msg:
                    self.current_processed_count += 1
                    self.win.root.after(
                        0,
                        self.win.update_progress,
                        self.current_processed_count,
                        self.total_count,
                        False,
                    )

        try:
            self.win.info_webfile.on_progress_callback = _progress_notifier

            # -----------------------------------------------------------------
            # 💡【要件①】ダウンロードの前にまずWeb上の最新情報を取得する
            # -----------------------------------------------------------------
            self.win.root.after(
                0,
                self.win.append_log,
                "⏳ Fetching latest web information before download...",
            )
            _loop.run_until_complete(self.win.info_webfile.get_web_file_info())

            if self.is_cancelled:
                raise asyncio.CancelledError

            # -----------------------------------------------------------------
            # 💡【判定処理】最新化された情報を使って、Webの方が新しいアイテムのみに絞り込む
            # -----------------------------------------------------------------
            _active_data = self.win.datas_map.get("active_table", [])
            _selected_items = [
                _item
                for _item in _active_data
                if getattr(_item, "target_flag", "x") == "o"
                and getattr(_item, "entry_flag", "") == "o"
            ]

            self.target_items = []
            for _item in _selected_items:
                _should_download = False
                _web_ts_str = getattr(_item, "web_tstamp", "")
                _iso_ts_str = getattr(_item, "iso_tstamp", "")

                if not _iso_ts_str:
                    _should_download = True
                elif _web_ts_str:
                    try:
                        if datetime.fromisoformat(_web_ts_str) > datetime.fromisoformat(
                            _iso_ts_str
                        ):
                            _should_download = True
                    except ValueError:
                        _should_download = True
                else:
                    _should_download = True

                if _should_download:
                    self.target_items.append(_item)
                else:
                    _disp_name = getattr(_item, "entry_disp", _item.entry_name)
                    _msg_skip = self.win.current_messages.get(
                        "msg_info_skipped", "✓ Skipped (Latest)"
                    )
                    self.win.root.after(
                        0, self.win.append_log, f"{_msg_skip}: {_disp_name}"
                    )

            # カウンターの動的再設定
            self.total_count = len(self.target_items)
            self.current_processed_count = 0
            self._is_download_phase = True
            if self.total_count == 0:
                _message = self.win.current_messages.get(
                    "msg_warn_not_selected", "⚠ All items are already up to date."
                )
                self.win.root.after(0, self.win.append_log, _message)
                self.win.root.after(0, self.win.update_progress, 0, 0, True)
                return

            # プログレスバーの最大値を実際のダウンロード件数に更新
            self.win.root.after(0, self.win.update_progress, 0, self.total_count, False)

            # -----------------------------------------------------------------
            # 💡 実際の非同期ダウンロード処理を実行
            # -----------------------------------------------------------------
            _loop.run_until_complete(self.win.info_webfile.download_web_files())

            if not self.is_cancelled:
                self.win.root.after(
                    0,
                    self.win.update_progress,
                    self.total_count,
                    self.total_count,
                    True,
                )

        except asyncio.CancelledError:
            _message = self.win.current_messages.get(
                "msg_info_cancel_progress", "⏳ Cancellation in progress..."
            )
            self.win.root.after(0, self.win.append_log, _message)
        except Exception as e:
            _message = (
                f"{self.win.current_messages.get('msg_error', 'Already Error')}: {e}"
            )
            self.win.root.after(0, self.win.append_log, _message)
        finally:
            try:
                pending_tasks = asyncio.all_tasks(_loop)
                if pending_tasks:
                    _loop.run_until_complete(asyncio.wait(pending_tasks, timeout=2.0))
            except Exception:
                pass
            _loop.close()

            # -----------------------------------------------------------------
            # 💡【要件②】処理完了後にデータモデル（datas_map）とGUIテーブルを最新化する
            # -----------------------------------------------------------------
            self.win.root.after(0, self._on_complete)

    def start_async_download(self) -> None:
        """安全にバックグラウンドで非同期ダウンロードスレッドを起動する"""
        _caller = get_caller_name()
        if self.win.is_running_async:
            _message = self.win.current_messages.get(
                "msg_warn_already_running", "Already running"
            )
            message_warn(func_name=_caller, message=_message, omit=False)
            return

        self.is_cancelled = False
        self.win.is_running_async = True
        if hasattr(self.win, "refresh_exec_button_text"):
            self.win.refresh_exec_button_text()

        # スレッドを即座に起動（判定や通信はスレッド内部で行う）
        _t = threading.Thread(target=self._thread_download_entry, daemon=True)
        _t.start()
