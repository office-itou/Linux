"""main window build buttons"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import build_buttons


# --- main --------------------------------------------------------------------
class MainWindowBuildButtons:
    root: tk.Tk
    ui_def: dict
    current_messages: dict[str, str]
    exec_buttons_list: list[ttk.Button]

    def _generate_bottom_buttons(self, cmd_map: dict[str, Callable]) -> None:
        if not hasattr(self, "exec_buttons_list") or self.exec_buttons_list is None:
            self.exec_buttons_list = []
        else:
            self.exec_buttons_list.clear()
        # ---------------------------------------------------------------------
        _bottom_frame = ttk.Frame(self.root, padding=10)
        _bottom_frame.pack(fill="x", side="bottom")
        # ---------------------------------------------------------------------
        _layout_info = self.ui_def.get("button_layout", {})
        _side_input = _layout_info.get("side", "right")
        _padx = _layout_info.get("padx", 0)
        _pady = _layout_info.get("pady", 0)
        _button_container = ttk.Frame(_bottom_frame)
        # ---------------------------------------------------------------------
        if _side_input == "left":
            _button_container.pack(side="left", padx=_padx, pady=_pady)
        elif _side_input == "center":
            _button_container.pack(side="top", anchor="center", padx=_padx, pady=_pady)
        else:
            _button_container.pack(side="right", padx=_padx, pady=_pady)
        # ---------------------------------------------------------------------
        build_buttons(
            parent=_button_container,
            button_data=self.ui_def["buttons"],
            messages=self.current_messages,
            commands=cmd_map,
        )
        _buttons_in_json = self.ui_def.get("buttons", [])
        _button_idx = 0
        # ---------------------------------------------------------------------
        for child in _button_container.winfo_children():
            if isinstance(child, ttk.Button):
                if _button_idx < len(_buttons_in_json):
                    cmd_name = _buttons_in_json[_button_idx].get("command_name", "")
                    setattr(child, "cmd_name", cmd_name)
                    if "event_update" in cmd_name or "event_exec" in cmd_name:
                        self.exec_buttons_list.append(child)
                _button_idx += 1
    # -------------------------------------------------------------------------
    def refresh_exec_button_text(self) -> None:
        """Toggle the button display for connection status."""
        if not hasattr(self, "exec_buttons_list"):
            return

        _is_running = getattr(self, "is_running_async", False)
        for btn in self.exec_buttons_list:
            if not btn.winfo_exists():
                continue
            if _is_running:
                cancel_text = self.current_messages.get("btn_cancel", "❌ Cancel")
                btn.configure(text=cancel_text)
            else:
                _cmd_name = getattr(btn, "cmd_name", "")
                if "event_update" in _cmd_name:
                    exec_text = self.current_messages.get("btn_update", "Update")
                else:
                    exec_text = self.current_messages.get("btn_exec", "Run")
                btn.configure(text=exec_text)
