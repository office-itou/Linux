"""Global variables (utils) (For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import os
import shutil
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import __main__


# ruff: isort: off
# --- my library --------------------------------------------------------------
# ruff: isort: on
# -----------------------------------------------------------------------------
@dataclass
class SystemData:
    """System data class (For both CUI/GUI)"""

    # --- global: args --------------------------------------------------------
    args: str | None = None
    # --- global: debug -------------------------------------------------------
    debug: bool = False
    debugout: bool = False
    # --- global: system ------------------------------------------------------
    program_name: str | None = None
    columns: int = 0
    rows: int = 0
    # --- global: user --------------------------------------------------------
    exec_user: str | None = None
    home_dir: str | None = None
    # --- Extended property for GUI support -----------------------------------
    is_gui: bool = False
    # --- Slot for registering a function to display a dialog on the GUI side -
    #     (arguments: title, message)
    gui_info_callback: Any = None
    gui_error_callback: Any = None
    log_window_active: bool = False
    # --- Coordinate management for cascade layout ----------------------------
    #     (initial position: X=50, Y=50)
    next_win_x: int = 50
    next_win_y: int = 50
    # --- laguage -------------------------------------------------------------
    lang: str = "en"


# -----------------------------------------------------------------------------
class InfoSystem:
    """System information class"""

    def __init__(self) -> None:
        self.data: SystemData | None = None

    def initialize(self, is_gui: bool = False) -> None:
        terminal_size = shutil.get_terminal_size()
        program_name = (
            Path(__main__.__file__).stem
            if hasattr(__main__, "__file__")
            else "interactive"
        )
        exec_user = os.getenv("SUDO_USER", os.getenv("USER"))
        home_dir = os.getenv("SUDO_HOME")
        from my_language import detect_language

        lang = detect_language() or "en"
        if is_gui:
            from tkinter import messagebox

            gui_error_callback = messagebox.showerror
            gui_info_callback = messagebox.showinfo
            log_window_active = True
            columns = 120
            rows = 40
            debugout = True
        else:
            gui_error_callback = None
            gui_info_callback = None
            log_window_active = False
            columns = terminal_size.columns
            rows = terminal_size.lines
            debugout = False
        self.data = SystemData(
            lang=lang,
            is_gui=is_gui,
            debugout=debugout,
            program_name=program_name,
            columns=columns,
            rows=rows,
            exec_user=exec_user,
            home_dir=home_dir or os.getenv("HOME") or f"/home/{exec_user}",
            gui_error_callback=gui_error_callback,
            gui_info_callback=gui_info_callback,
            log_window_active=log_window_active,
        )

    def __getattr__(self, name: str) -> Any:
        if self.data is None:
            raise RuntimeError(
                "InfoSystem has not been initialized yet. Call initialize() first."
            )
        return getattr(self.data, name)

    def __setattr__(self, name: str, value: Any) -> None:
        if (
            name != "data"
            and "data" in self.__dict__
            and self.data is not None
            and hasattr(self.data, name)
        ):
            setattr(self.data, name, value)
        else:
            super().__setattr__(name, value)

    def to_dict(self) -> dict[str, Any]:
        if self.data is None:
            return {}
        return asdict(self.data)


infosystem = InfoSystem()
# --- eof ---------------------------------------------------------------------
