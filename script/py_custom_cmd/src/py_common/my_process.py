# --- Python library ----------------------------------------------------------
import subprocess

from py_common.my_colors import color

# --- my library --------------------------------------------------------------
from py_common.my_debug import debug_logger
from py_common.my_message import get_caller_name, message_alert


# -----------------------------------------------------------------------------
@debug_logger
def run_subprocess(parameter: str):
    try:
        res = subprocess.run(parameter, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        message_alert(
            get_caller_name(),
            f"Subprocess error status {e.returncode}: {e.stderr}{color.reset}",
        )
        raise SystemExit
    except FileNotFoundError as e:
        message_alert(
            get_caller_name(),
            f"Subprocess file not found error: {e.filename}{color.reset}",
        )
        raise SystemExit
    # -------------------------------------------------------------------------
    return str(res.stdout.strip())


# --- eof ---------------------------------------------------------------------
