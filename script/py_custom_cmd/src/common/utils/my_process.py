"""Subprocess wrapper"""

# --- Python library ----------------------------------------------------------
import subprocess

# --- my library --------------------------------------------------------------
from .my_colors import Color
from .my_debug import debug_logger
from .my_message import get_caller_name, message_alert


# -----------------------------------------------------------------------------
@debug_logger
def run_subprocess(*args, **kwargs) -> str:
    """Subprocess wrapper

    Raises:
        SystemExit: subprocess.CalledProcessError
        SystemExit: FileNotFoundError

    Returns:
        str: stdout
    """
    kwargs["check"] = True
    kwargs["capture_output"] = True
    kwargs["text"] = True
    try:
        res = subprocess.run(*args, **kwargs)  # noqa: PLW1510
    except subprocess.CalledProcessError as e:
        message_alert(
            get_caller_name(),
            f"Subprocess error status {e.returncode}: {e.stderr}{Color.reset}",
        )
        raise SystemExit
    except FileNotFoundError as e:
        message_alert(
            get_caller_name(),
            f"Subprocess file not found error: {e.filename}{Color.reset}",
        )
        raise SystemExit
    # -------------------------------------------------------------------------
    return str(res.stdout.strip())


# --- eof ---------------------------------------------------------------------
