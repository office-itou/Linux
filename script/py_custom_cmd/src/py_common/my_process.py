# --- Python library ----------------------------------------------------------
from typing                             import Any, Callable
from pathlib                            import Path
import inspect
import subprocess

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_debug                 import debug_logger
from py_common.my_colors                import color
from py_common.my_string                import omit_middle, generate_comment
from py_common.my_debug                 import debugout

# -----------------------------------------------------------------------------
@debug_logger
def run_subprocess(parameter: str):
    try:
        res = subprocess.run(parameter, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        message_alert(get_caller_name(), f"Subprocess error status {e.returncode}: {e.stderr}{color.reset}")
        raise SystemExit
    except FileNotFoundError as e:
        message_alert(get_caller_name(), f"Subprocess file not found error: {e.filename}{color.reset}")
        raise SystemExit
    # -------------------------------------------------------------------------
    return str(res.stdout.strip())

# --- eof ---------------------------------------------------------------------
