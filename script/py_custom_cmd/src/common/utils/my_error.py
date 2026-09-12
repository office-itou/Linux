"""error processing"""

# --- Python library ----------------------------------------------------------
import traceback

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_message import message_alert


@debug_logger
def handle_fatal_error(caller: str, e: Exception) -> None:
    """Fatal error handler

    Args:
        caller (str): Function name
        e (Exception): Error information

    Raises:
        SystemExit: System exit
    """
    _summary = traceback.extract_tb(e.__traceback__)[-1]
    message_alert(caller, f"Fatal error: {e}")
    if isinstance(e, OSError):
        message_alert(caller, f"line number: {_summary.lineno}")
    else:
        message_alert(caller, f"file name  : {_summary.filename}")
        message_alert(caller, f"line number: {_summary.lineno}")
    raise SystemExit from e


# --- eof ---------------------------------------------------------------------
