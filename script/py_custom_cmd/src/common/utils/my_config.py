"""Global variables (utils)"""

# --- Python library ----------------------------------------------------------
import os
import shutil
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import __main__

# --- my library --------------------------------------------------------------


# -----------------------------------------------------------------------------
@dataclass
class SystemData:
    """System data class"""

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


# -----------------------------------------------------------------------------
class InfoSystem:
    """System information class"""

    def __init__(self):
        terminal_size = shutil.get_terminal_size()
        program_name = (
            Path(__main__.__file__).stem
            if hasattr(__main__, "__file__")
            else "interactive"
        )
        self.data = SystemData(
            program_name=program_name,
            columns=terminal_size.columns,
            rows=terminal_size.lines,
            exec_user=os.getenv("SUDO_USER", os.getenv("USER")),
            home_dir=os.getenv("SUDO_HOME")
            or os.getenv("HOME")
            or f"/home/{self.data.exec_user}",
        )

    def __getattr__(self, name: str) -> Any:
        return getattr(self.data, name)

    def __setattr__(self, name: str, value: Any) -> None:
        if name != "data" and hasattr(self, "data") and hasattr(self.data, name):
            setattr(self.data, name, value)
        else:
            super().__setattr__(name, value)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self.data)


# -----------------------------------------------------------------------------
infosystem = InfoSystem()
# --- eof ---------------------------------------------------------------------
