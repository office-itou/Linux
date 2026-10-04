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

    def _thread_entry(self) -> None:
        _loop = asyncio.new_event_loop()
        asyncio.set_event_loop(_loop)
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
            self.win.root.after(0, self.win.root.update)

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
            self.win.root.after(0, self._on_complete)

    # -------------------------------------------------------------------------
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
            if getattr(_item, "is_target", False)
            and getattr(_item.mdia_data, "entry_flag", "") == "o"
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

    # -------------------------------------------------------------------------
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
