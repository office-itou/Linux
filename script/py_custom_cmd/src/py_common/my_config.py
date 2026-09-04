###############################################################################
#
# 	global variables
#
# 	developer   : J.Itou
# 	release     : 2026/09/03
#
# 	history     :
# 	   data    version    developer    point
# 	---------- -------- -------------- ----------------------------------------
# 	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
import shutil
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import __main__

# --- my library --------------------------------------------------------------


@dataclass
class SystemData:
    # --- global: args ------------------------------------------------------------
    args: str = ""
    # --- global: debug -----------------------------------------------------------
    debug: bool = False
    debugout: bool = False
    # --- global: system ----------------------------------------------------------
    program_name: str | None = None
    columns: int = 0
    rows: int = 0


class InfoSystem:
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
        )

    @property
    def program_name(self) -> str | None:
        return self.data.program_name

    @property
    def columns(self) -> int:
        return self.data.columns

    @property
    def rows(self) -> int:
        return self.data.rows

    @property
    def debug(self) -> bool:
        return self.data.debug

    @debug.setter
    def debug(self, value: bool):
        self.data.debug = value

    @property
    def debugout(self) -> bool:
        return self.data.debugout

    @debugout.setter
    def debugout(self, value: bool):
        self.data.debugout = value

    def to_dict(self) -> dict[str, Any]:
        return asdict(self.data)


infosystem = InfoSystem()

# --- eof ---------------------------------------------------------------------
