###############################################################################
#
#	global variables
#
#	developer   : J.Itou
#	release     : 2026/09/03
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
from typing                             import Any, Callable
from dataclasses                        import dataclass, asdict
from pathlib                            import Path
import __main__
import shutil

# --- my library --------------------------------------------------------------
#from py_common.my_config                import infosystem
#from py_common.my_debug                 import debug_logger

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
