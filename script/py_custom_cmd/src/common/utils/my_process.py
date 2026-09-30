"""Subprocess wrapper"""

# --- Python library ----------------------------------------------------------
import subprocess


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
)


# ruff: isort: on
# =============================================================================
@debug_logger
def run_subprocess(*args, **kwargs) -> str:
    """Subprocess wrapper
    Raises:
        SystemExit: subprocess.CalledProcessError
        SystemExit: FileNotFoundError
    Returns:
        str: stdout
    """
    _caller = get_caller_name()
    kwargs["check"] = True
    kwargs["capture_output"] = True
    kwargs["text"] = True
    try:
        _res = subprocess.run(*args, **kwargs)  # noqa: PLW1510
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    # -------------------------------------------------------------------------
    return str(_res.stdout.strip())


# --- eof ---------------------------------------------------------------------
