"""error processing (For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import sys
import traceback


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import infosystem, debug_logger, message_alert


# ruff: isort: on
# =============================================================================
@debug_logger
def handle_fatal_error(caller: str, e: Exception, omit: bool = False) -> None:
    """Fatal error handler (For both CUI/GUI)
    Args:
        caller (str): Function name
        e (Exception): Error information
        omit (bool, optional): Omit. Defaults to False.
    Raises:
        SystemExit: System exit
    """
    # --- Constructing error messages -----------------------------------------
    _summary = traceback.extract_tb(e.__traceback__)[-1]
    message_alert(caller, f"Fatal error: {e}", omit)
    _error_msg = f"Fatal error: {e}\n"
    if isinstance(e, OSError):
        _error_msg += f"line number: {_summary.lineno}"
    else:
        _error_msg += (
            f"file name  : {_summary.filename}\nline number: {_summary.lineno}"
        )
    # --- Processing in GUI mode ----------------------------------------------
    if infosystem.is_gui and infosystem.gui_error_callback:
        infosystem.gui_error_callback(f"Error ({caller})", _error_msg)
        sys.exit(1)  # Safely terminate the GUI thread
    else:
        # --- Conventional CUI processing -------------------------------------
        message_alert(caller, f"Fatal error: {e}", omit)
        if isinstance(e, OSError):
            message_alert(caller, f"line number: {_summary.lineno}", omit)
        else:
            message_alert(caller, f"file name  : {_summary.filename}", omit)
            message_alert(caller, f"line number: {_summary.lineno}", omit)
        raise SystemExit from e


# --- eof ---------------------------------------------------------------------
