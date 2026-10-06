"""main window build status"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from tkinter import ttk


# --- my library --------------------------------------------------------------
# ruff: isort: off
# --- main --------------------------------------------------------------------
class MainWindowStatus:
    root: tk.Tk
    current_messages: dict[str, str]
    ui_def: dict
    _main_frame: ttk.Frame

    def _generate_status_monitor(self) -> None:
        if (
            hasattr(self, "main_status_widgets")
            and self.main_status_widgets.winfo_exists()
        ):
            return
        # --- generate a container frame for displaying status. ---------------
        _parent_frame: ttk.Frame = self._main_frame
        _status_frame = ttk.Frame(_parent_frame, padding=(0, 10, 0, 0))
        _status_frame.grid(row=3, column=0, columnspan=2, sticky="ew")
        _status_frame.columnconfigure(0, weight=1)  # resize the log monitor.
        _status_frame.columnconfigure(1, weight=0)  # the progress bar has a fixed
        # --- 5-line log monitor (Text + Scrollbar) ---------------------------
        _log_container = ttk.Frame(_status_frame)
        _log_container.grid(row=0, column=0, sticky="nsew", padx=(0, 10))
        _log_container.columnconfigure(0, weight=1)
        # --- Specify a height of approximately five lines (height=5). --------
        self.main_status_widgets = tk.Text(
            _log_container,
            height=5,
            wrap="char",
            state="disabled",
            font=("", 9),
            background="#f8fafc",
            foreground="#334155",
        )
        self.main_status_widgets.grid(row=0, column=0, sticky="ew")
        # ---------------------------------------------------------------------
        _log_scroll = ttk.Scrollbar(
            _log_container, orient=tk.VERTICAL, command=self.main_status_widgets.yview
        )
        self.main_status_widgets.configure(yscrollcommand=_log_scroll.set)
        _log_scroll.grid(row=0, column=1, sticky="ns")
        # --- container for the processed count bar and label -----------------
        _bar_container = ttk.Frame(_status_frame)
        _bar_container.grid(row=0, column=1, sticky="ns")
        # ---------------------------------------------------------------------
        _messages = (
            f"{self.current_messages.get('msg_info_standby', 'Standby')}"
            f"(0/0 {self.current_messages.get('msg_info_target_items', 'items')})"
        )
        self.progress_label = ttk.Label(_bar_container, text=_messages, font=("", 9))
        self.progress_label.pack(anchor="w", pady=(0, 2))
        # ---------------------------------------------------------------------
        self.progress_bar = ttk.Progressbar(
            _bar_container, orient=tk.HORIZONTAL, length=220, mode="determinate"
        )
        self.progress_bar.pack(anchor="w")
        # ---------------------------------------------------------------------
        _messages = self.current_messages.get(
            "msg_info_startup", "The application has started.\nIt is ready."
        )
        self.append_log(_messages)
        # ---------------------------------------------------------------------

    def append_log(self, text: str) -> None:
        """Add a line to the log monitor and automatically scroll to the bottom."""
        if (
            not hasattr(self, "main_status_widgets")
            or not self.main_status_widgets.winfo_exists()
        ):
            return
        # --- Safely dispatch to the main thread when called from a sub-thread. ---
        import threading

        if threading.current_thread() != threading.main_thread():
            self.root.after(0, self.append_log, text)
            return
        # ---------------------------------------------------------------------
        self.main_status_widgets.configure(state="normal")
        self.main_status_widgets.insert(tk.END, f"{text}\n")
        self.main_status_widgets.configure(state="disabled")
        self.main_status_widgets.see(tk.END)  # Scroll to the latest log

    def update_progress(
        self, current: int, total: int, is_complete: bool = False
    ) -> None:
        """Update the progress bar and progress text."""
        if not hasattr(self, "progress_bar") or not self.progress_bar.winfo_exists():
            return
        # ---------------------------------------------------------------------
        import threading

        if threading.current_thread() != threading.main_thread():
            self.root.after(0, self.update_progress, current, total, is_complete)
            return
        # ---------------------------------------------------------------------
        _message = ""
        if total > 0:
            _percent = (current / total) * 100
            self.progress_bar["value"] = _percent
            if is_complete or current >= total:
                _key = "msg_info_complete"
                _default = "✓ Completed."
            else:
                _key = "msg_info_processing"
                _default = "Processing..."
            _message = f"{self.current_messages.get(_key, _default)}"
        else:
            current = 0
            total = 0
            self.progress_bar["value"] = 0
        _message += (
            f" ({current} / {total} "
            f"{self.current_messages.get('msg_info_target_items', 'items')})"
        )
        self.progress_label.configure(text=_message)
