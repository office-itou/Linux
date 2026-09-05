"""debug processing"""

# --- Python library ----------------------------------------------------------
import inspect
import sys
from collections.abc import Callable

# --- my library --------------------------------------------------------------
from .my_colors import Color
from .my_config import infosystem
from .my_message import message_debug
from .my_string import generate_comment


# -----------------------------------------------------------------------------
def debug_logger(func: Callable):
    """Debug output decorator"""

    # -------------------------------------------------------------------------
    def wrapper(*args, **kwargs):
        # --- get the caller's frame ------------------------------------------
        frame = inspect.currentframe().f_back
        func_name = str(frame.f_code.co_name)
        # file_name = str(Path(frame.f_code.co_filename).stem)
        modu_name = str(frame.f_globals.get("__name__"))
        call_info = f"{modu_name}({func_name})"
        # --- generation of function information and comments -----------------
        args_str = ", ".join(repr(x) for x in args) if args else ""
        kwargs_str = (
            ", ".join(f"{k}={v!r}" for k, v in kwargs.items()) if kwargs else ""
        )
        if args_str and kwargs_str:
            parameter = f"{args_str}, {kwargs_str}"
        else:
            parameter = args_str or kwargs_str or ""
        comment = generate_comment("", "", parameter)
        # --- start log -------------------------------------------------------
        debugout(call_info, "Start", Color.yellow, comment)
        # --- execute the original function processing ------------------------
        result = func(*args, **kwargs)
        # --- completion log --------------------------------------------------
        debugout(call_info, "Complete", Color.yellow, "")
        return result

    return wrapper


# -----------------------------------------------------------------------------
def debugout_scale(size: int):
    """Debug output for scale

    Args:
        size (int): Scale value
    """
    eprint = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)
    # scale_u = "".join(
    #     str(i // 100)[-1] if i % 10 == 0 else " " for i in range(1, size + 1)
    # )
    scale_m = "".join(
        str((i // 10) % 10) if i % 10 == 0 else " " for i in range(1, size + 1)
    )
    scale_l = "".join(str(i % 10) for i in range(1, size + 1))
    # eprint(scale_u)
    eprint(scale_m)
    eprint(scale_l)


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
