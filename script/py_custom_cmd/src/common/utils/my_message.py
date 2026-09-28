"""Message processing"""

# --- Python library ----------------------------------------------------------
import inspect
import re
from datetime import datetime, timedelta

# --- my library --------------------------------------------------------------
from common.utils import Color, count_width, eprint, infosystem, omit_middle


colsize_mode = 8


def message_out(
    color: str, func_name: str, mode: str, message: str, omit: bool = False
) -> None:
    """_summary_
    Args:
        color (str): Message color
        func_name (str): Function name
        mode (str): Message category
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    _program_name = infosystem.program_name
    _columns = infosystem.columns
    _colsize = (_columns - (colsize_mode + 2)) // 2 if _columns < 100 else 50
    _prog_text = omit_middle(f"{_program_name}({func_name})", _colsize)
    _mesg_text = (
        message
        if not omit
        else omit_middle(f"{message}", _columns - (_colsize + colsize_mode + 2))
    )
    eprint(
        f"{Color.reset}{color}{_prog_text:<{_colsize}}|{mode:^{colsize_mode}}|{_mesg_text}{Color.reset}",
        _columns,
        wrap=not omit,
    )


def message_start(func_name: str, omit: bool = False):
    """Message output for startup
    Args:
        func_name (str): Function name
        omit (bool, optional): Omit. Defaults to False.
    """
    _date_time = datetime.now().astimezone().strftime("%Y/%m/%d %H:%M:%S %Z (%z)")
    message_out(Color.br_green, func_name, "Start", _date_time, omit=omit)


def message_end(func_name: str, omit: bool = False):
    """Message output for termination
    Args:
        func_name (str): Function name
        omit (bool, optional): Omit. Defaults to False.
    """
    _date_time = datetime.now().astimezone().strftime("%Y/%m/%d %H:%M:%S %Z (%z)")
    message_out(Color.br_green, func_name, "Complete", _date_time, omit=omit)


def message_elapsed(func_name: str, elapsed: float, omit: bool = False):
    """Message output for elapsed time
    Args:
        func_name (str): Function name
        elapsed (float): Elapsed time
        omit (bool, optional): Omit. Defaults to False.
    """
    _time_text:str = str(timedelta(seconds=elapsed))
    message_out(Color.br_yellow, func_name, "Elapsed", _time_text, omit=omit)


def message_debug(
    color: str, func_name: str, mode: str, message: str, omit: bool = False
):
    """Message output for debug
    Args:
        color (str): Message color
        func_name (str): Function name
        mode (str): Message category
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    message_out(color, func_name, mode, message, omit=omit)


def message_info(func_name: str, message: str, omit: bool = False):
    """message output for information
    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    message_out(Color.green, func_name, "info", message, omit=omit)


def message_warn(func_name: str, message: str, omit: bool = False):
    """Message output for warning
    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    message_out(Color.yellow, func_name, "Warning", message, omit=omit)


def message_alert(func_name: str, message: str, omit: bool = False):
    """Message output for alert
    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    message_out(Color.red, func_name, "alert", message, omit=omit)


def get_caller_name(only: bool = True) -> str:
    """Get function name
    Args:
        only (bool, optional): Function only or including filename. Defaults to True.
    Returns:
        str: _description_
    """
    _frame = inspect.currentframe()
    if _frame is not None and _frame.f_back is not None:
        _func_name = str(_frame.f_back.f_code.co_name)
        _modu_name = str(_frame.f_back.f_globals.get("__name__"))
        _call_info = f"{_modu_name}({_func_name})"
    else:
        _func_name = "unknown"
        _modu_name = "unknown"
        _call_info = "unknown"
    return _call_info


def generate_comment(modu_name: str, func_name: str, para: str = "") -> str:
    """Omit the intermediate characters.
    Args:
        modu_name (str): Module name
        func_name (str): Function name
        para (str, optional): Parameter. Defaults to "".
    Returns:
        str: Comment message
    """
    _front_part = ""
    _colsize = (
        (infosystem.columns - (colsize_mode + 2)) // 2
        if infosystem.columns < 100
        else 50
    )
    _colsize_para = infosystem.columns - (_colsize + colsize_mode + 2)
    if modu_name:
        _text_modu = re.sub(r"^[^.]+.", "", modu_name)
        _colsize_modu = min(count_width(_text_modu), 20)
        _colsize_call = min(count_width(func_name), 20)
        _colsize_para -= _colsize_modu + _colsize_call + 2
        _text_modu = omit_middle(_text_modu, _colsize_modu)
        _text_func = omit_middle(func_name, _colsize_call)
        _front_part = f"{_text_modu}({_text_func}):"
    _text_para = ""
    if para:
        _text_para = omit_middle(f"{para}", _colsize_para)
    return f"{_front_part}{_text_para}"


# --- eof ---------------------------------------------------------------------
