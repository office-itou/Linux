"""Message processing"""

# --- Python library ----------------------------------------------------------
import inspect
import re
from datetime import datetime, timedelta
from pathlib import Path

# --- my library --------------------------------------------------------------
from .my_colors import Color
from .my_config import infosystem
from .my_string import count_width, eprint, omit_middle

# colsize_func = 30 if infosystem.columns < 80 else 40 if infosystem.columns < 100 else 50
colsize_mode = 8
colsize_func = (
    (infosystem.columns - (colsize_mode + 2)) // 2 if infosystem.columns < 100 else 50
)
colsize_mesg = infosystem.columns - (colsize_func + colsize_mode + 2)


def message_date(func_name: str, mode: str, message_color: str, date_time: str):
    """Message output for datetime

    Args:
        func_name (str): Function name
        mode (str): Message category
        message_color (str): Message color
        date_time (str): Formatted date and time
    """
    _mesg_text = f"--- {date_time} " + "-" * (
        infosystem.columns - (colsize_func + colsize_mode + 5 + 2)
    )
    eprint(
        f"{Color.reset}{message_color}{func_name:<{colsize_func}}|{mode:^{colsize_mode}}|{_mesg_text}{Color.reset}",
        infosystem.columns,
    )


def message_start(func_name: str):
    """Message output for startup

    Args:
        func_name (str): Function name
    """
    _date_time = datetime.now().astimezone().strftime("%Y/%m/%d %H:%M:%S %Z (%z)")
    _prog_text = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    message_date(_prog_text, "Start", Color.green, _date_time)


def message_end(func_name: str):
    """Message output for termination

    Args:
        func_name (str): Function name
    """
    _date_time = datetime.now().astimezone().strftime("%Y/%m/%d %H:%M:%S %Z (%z)")
    _prog_text = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    message_date(_prog_text, "Complete", Color.green, _date_time)


def message_elapsed(func_name: str, elapsed: str):
    """Message output for elapsed time

    Args:
        func_name (str): Function name
        elapsed (str): Elapsed time
    """
    _prog_text = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    _time_text = timedelta(seconds=elapsed)
    eprint(
        f"{Color.reset}{Color.yellow}{_prog_text:<{colsize_func}}|{'Elapsed':^{colsize_mode}}|{_time_text}{Color.reset}",
        infosystem.columns,
    )


def message_debug(func_name: str, mode: str, message_color: str, message: str):
    """Message output for debug

    Args:
        func_name (str): Function name
        mode (str): Message category
        message_color (str): Message color
        message (str): Message
    """
    _prog_text = omit_middle(f"{infosystem.program_name}:{func_name}", colsize_func)
    _mesg_text = omit_middle(
        f"{message}", infosystem.columns - (colsize_func + colsize_mode + 1)
    )
    eprint(
        f"{Color.reset}{message_color}{_prog_text:<{colsize_func}}|{mode:^{colsize_mode}}|{_mesg_text}{Color.reset}",
        infosystem.columns,
    )


def message_info(func_name: str, message: str, omit: bool = False):
    """message output for information

    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    _prog_text = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    _mesg_text = (
        omit_middle(
            f"{message}", infosystem.columns - (colsize_func + colsize_mode + 2)
        )
        if omit == True
        else message
    )
    eprint(
        f"{Color.reset}{Color.br_green}{_prog_text:<{colsize_func}}|{'info':^{colsize_mode}}|{_mesg_text}{Color.reset}"
    )


def message_warn(func_name: str, message: str, omit: bool = False):
    """Message output for warning

    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    _prog_text = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    _mesg_text = (
        omit_middle(
            f"{message}", infosystem.columns - (colsize_func + colsize_mode + 2)
        )
        if omit == True
        else message
    )
    eprint(
        f"{Color.reset}{Color.br_yellow}{_prog_text:<{colsize_func}}|{'info':^{colsize_mode}}|{_mesg_text}{Color.reset}"
    )


def message_alert(func_name: str, message: str, omit: bool = False):
    """Message output for alert

    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    _prog_text = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    _mesg_text = (
        omit_middle(
            f"{message}", infosystem.columns - (colsize_func + colsize_mode + 2)
        )
        if omit == True
        else message
    )
    eprint(
        f"{Color.reset}{Color.br_red}{_prog_text:<{colsize_func}}|{'info':^{colsize_mode}}|{_mesg_text}{Color.reset}"
    )


def get_caller_name(only: bool = True) -> str:
    """Get function name

    Args:
        only (bool, optional): Function only or including filename. Defaults to True.

    Returns:
        str: _description_
    """
    frame = inspect.currentframe().f_back
    func_text = str(frame.f_code.co_name)
    file_text = str(Path(frame.f_code.co_filename).stem)
    call_info = func_text if only == True else f"{file_text}({func_text})"
    return call_info


def generate_comment(modu_name: str, func_name: str, para: str = "") -> str:
    """Omit the intermediate characters.

    Args:
        modu_name (str): Module name
        func_name (str): Function name
        para (str, optional): Parameter. Defaults to "".

    Returns:
        str: Comment message
    """
    from .my_message import colsize_mesg

    _front_part = ""
    _colsize_para = colsize_mesg
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
