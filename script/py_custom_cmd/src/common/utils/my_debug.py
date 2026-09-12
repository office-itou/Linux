"""debug processing"""

# --- Python library ----------------------------------------------------------
import inspect
import sys
from collections.abc import Callable

# --- my library --------------------------------------------------------------
from .my_colors import Color
from .my_config import infosystem
from .my_message import generate_comment, message_debug


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
        debugout(_call_info, "Start", Color.yellow, _comment)
        # --- execute the original function processing ------------------------
        result = func(*args, **kwargs)
        # --- completion log --------------------------------------------------
        debugout(_call_info, "Complete", Color.yellow, "")
        return result

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
def debugout(function_name: str, mode: str, message_color: str, message: str):
    """Debug output

    Args:
        function_name (str): Function name
        mode (str): Mode ("Start", "Complete", ....)
        message_color (str): Color (`color.br_green`)
        message (str): Message
    """
    if infosystem.debugout == False:
        return
    message_debug(function_name, mode, message_color, message)


# --- eof ---------------------------------------------------------------------
