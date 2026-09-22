"""debug processing (For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import inspect
import sys

from collections.abc import Callable

# --- my library --------------------------------------------------------------
from my_colors import Color
from my_config import infosystem
from my_message import generate_comment, message_debug


# -----------------------------------------------------------------------------
def debug_logger(func: Callable):
    """Debug output decorator"""

    # -------------------------------------------------------------------------
    def _wrapper(*args, **kwargs):
        # --- get the caller's frame ------------------------------------------
        _frame = inspect.currentframe().f_back
        _func_name = str(_frame.f_code.co_name)
        # _file_name = str(Path(_frame.f_code.co_filename).stem)
        _modu_name = str(_frame.f_globals.get("__name__"))
        _call_info = f"{_modu_name}({_func_name})"
        # --- generation of function information and comments -----------------
        _args_str = ", ".join(repr(x) for x in args) if args else ""
        _kwargs_str = (
            ", ".join(f"{k}={v!r}" for k, v in kwargs.items()) if kwargs else ""
        )
        if _args_str and _kwargs_str:
            _parameter = f"{_args_str}, {_kwargs_str}"
        else:
            _parameter = _args_str or _kwargs_str or ""
        _comment = generate_comment("", "", _parameter)
        # --- start log -------------------------------------------------------
        debugout(Color.yellow, _call_info, "Start", _comment, omit=True)
        # --- execute the original function processing ------------------------
        result = func(*args, **kwargs)
        # --- completion log --------------------------------------------------
        debugout(Color.yellow, _call_info, "Complete", "", omit=True)
        return result

    return _wrapper


# -----------------------------------------------------------------------------
def debug_chk_cui(func: Callable):
    """A decorator that forces termination if a CUI-only function is called from a GUI environment."""

    def _wrapper(*args, **kwargs):
        # --- Defensive processing when invoked from a GUI environment --------
        if infosystem.is_gui:
            _frame = inspect.currentframe().f_back
            _func_name = str(_frame.f_code.co_name)
            _modu_name = str(_frame.f_globals.get("__name__"))
            _call_info = f"{_modu_name}({_func_name})"
            # -----------------------------------------------------------------
            if infosystem.gui_error_callback:
                infosystem.gui_error_callback(
                    "System Error",
                    f"A CUI-only function was called from the GUI:\n{func.__name__}\n\nCaller:\n{_call_info}",
                )
            else:
                # --- Fallback mechanism in the event that a callback is not registered. ---
                print(
                    f"🚨 [Error] CUI function '{func.__name__}' called from GUI by {_call_info}",
                    file=sys.stderr,
                )
            raise SystemExit(1)  # Safely exit the application
        # --- In a CUI environment, the original function is executed as-is, and the result is returned. ---
        return func(*args, **kwargs)

    return _wrapper


# -----------------------------------------------------------------------------
def debugout_scale(size: int):
    """Debug output for scale
    Args:
        size (int): Scale value
    """
    _eprint = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)
    # _scale_u = "".join(
    #     str(i // 100)[-1] if i % 10 == 0 else " " for i in range(1, size + 1)
    # )
    _scale_m = "".join(
        str((i // 10) % 10) if i % 10 == 0 else " " for i in range(1, size + 1)
    )
    _scale_l = "".join(str(i % 10) for i in range(1, size + 1))
    # _eprint(scale_u)
    _eprint(_scale_m)
    _eprint(_scale_l)


# -----------------------------------------------------------------------------
def debugout(color: str, func_name: str, mode: str, message: str, omit: bool = False):
    """Debug output
    Args:
        color (str): Message color
        func_name (str): Function name
        mode (str): Message category
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    if infosystem.debugout:
        message_debug(color, func_name, mode, message, omit=omit)


# --- eof ---------------------------------------------------------------------
