"""main window build buttons"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from collections.abc import Callable
from tkinter import ttk


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import build_buttons


# --- main --------------------------------------------------------------------
class MainWindowButtons:
    root: tk.Tk
    current_messages: dict[str, str]
    main_bottom_button_widgets: list[ttk.Button]
    ui_def: dict

    def _generate_bottom_buttons(self, cmd_map: dict[str, Callable]) -> None:
        if (
            not hasattr(self, "main_bottom_button_widgets")
            or self.main_bottom_button_widgets is None
        ):
            self.main_bottom_button_widgets = []
        else:
            self.main_bottom_button_widgets.clear()
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
        for _child in _button_container.winfo_children():
            if isinstance(_child, ttk.Button):
                if _button_idx < len(_buttons_in_json):
                    _cmd_name = _buttons_in_json[_button_idx].get("command_name", "")
                    setattr(_child, "cmd_name", _cmd_name)  # noqa: B010
                    if "event_update" in _cmd_name or "event_exec" in _cmd_name:
                        self.main_bottom_button_widgets.append(_child)
                _button_idx += 1

    # -------------------------------------------------------------------------
    def refresh_exec_button_text(self) -> None:
        """Toggle the button display for connection status."""
        if not hasattr(self, "main_bottom_button_widgets"):
            return

        _is_running = getattr(self, "is_running_async", False)
        for _btn in self.main_bottom_button_widgets:
            if not _btn.winfo_exists():
                continue
            if _is_running:
                _cancel_text = self.current_messages.get("btn_cancel", "❌ Cancel")
                _btn.configure(text=_cancel_text)
            else:
                _cmd_name = getattr(_btn, "cmd_name", "")
                if "event_update" in _cmd_name:
                    _exec_text = self.current_messages.get("btn_update", "Update")
                else:
                    _exec_text = self.current_messages.get("btn_exec", "Run")
                _btn.configure(text=_exec_text)
