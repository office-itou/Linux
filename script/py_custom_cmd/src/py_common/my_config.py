# --- Python library ----------------------------------------------------------
from dataclasses                        import dataclass, asdict
from pathlib                            import Path
import __main__
import shutil

# --- my library --------------------------------------------------------------
@dataclass
class SystemData:
    # --- global: args ------------------------------------------------------------
    args:           str = ''
    # --- global: debug -----------------------------------------------------------
    debug:          bool = False
    debugout:       bool = False
    # --- global: system ----------------------------------------------------------
    program_name:   str = ''
    columns:        int = 0
    rows:           int = 0
    stdscr:         any = ''

class InfoSystem:
    def __init__(self):
        self.data: SystemData = SystemData()
        if hasattr(__main__, "__file__"):
            self.data.program_name = Path(__main__.__file__).stem
        self.data.columns = shutil.get_terminal_size().columns
        self.data.rows    = shutil.get_terminal_size().lines

infosystem = InfoSystem()

# --- eof ---------------------------------------------------------------------
