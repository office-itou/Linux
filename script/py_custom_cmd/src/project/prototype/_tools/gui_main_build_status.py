"""main window build status"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from tkinter import ttk


# --- main --------------------------------------------------------------------
class MainWindowBuildStatus:
    root: tk.Tk
    ui_def: dict
    current_messages: dict[str, str]
    log_text_widget: tk.Text
    progress_bar: ttk.Progressbar
    progress_label: ttk.Label

    def _generate_status_monitor(self, parent_frame: tk.Widget) -> None:
        if hasattr(self, "log_text_widget") and self.log_text_widget.winfo_exists():
            return
        # --- generate a container frame for displaying status. ---------------
        _status_frame = ttk.Frame(parent_frame, padding=(0, 10, 0, 0))
        _status_frame.grid(row=3, column=0, columnspan=2, sticky="ew")
        _status_frame.columnconfigure(0, weight=1)  # resize the log monitor.
        _status_frame.columnconfigure(1, weight=0)  # the progress bar has a fixed
        # --- 5-line log monitor (Text + Scrollbar) ---------------------------
        _log_container = ttk.Frame(_status_frame)
        _log_container.grid(row=0, column=0, sticky="nsew", padx=(0, 10))
        _log_container.columnconfigure(0, weight=1)
        # --- Specify a height of approximately five lines (height=5). --------
        self.log_text_widget = tk.Text(
            _log_container,
            height=5,
            wrap="char",
            state="disabled",
            font=("", 9),
            background="#f8fafc",
            foreground="#334155",
        )
        self.log_text_widget.grid(row=0, column=0, sticky="ew")
        # ---------------------------------------------------------------------
        _log_scroll = ttk.Scrollbar(
            _log_container, orient=tk.VERTICAL, command=self.log_text_widget.yview
        )
        self.log_text_widget.configure(yscrollcommand=_log_scroll.set)
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
            not hasattr(self, "log_text_widget")
            or not self.log_text_widget.winfo_exists()
        ):
            return
        # --- Safely dispatch to the main thread when called from a sub-thread. ---
        import threading

        if threading.current_thread() != threading.main_thread():
            self.root.after(0, self.append_log, text)
            return
        # ---------------------------------------------------------------------
        self.log_text_widget.configure(state="normal")
        self.log_text_widget.insert(tk.END, f"{text}\n")
        self.log_text_widget.configure(state="disabled")
        self.log_text_widget.see(tk.END)  # Scroll to the latest log

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
            percent = (current / total) * 100
            self.progress_bar["value"] = percent
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
