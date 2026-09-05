"""Message processing"""

# --- Python library ----------------------------------------------------------
import inspect
from datetime import datetime, timedelta
from pathlib import Path

# --- my library --------------------------------------------------------------
from .my_colors import Color
from .my_config import infosystem
from .my_string import eprint, omit_middle

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
    message = f"--- {date_time} " + "-" * (
        infosystem.columns - (colsize_func + colsize_mode + 5 + 2)
    )
    eprint(
        f"{Color.reset}{message_color}{func_name:<{colsize_func}}|{mode:^{colsize_mode}}|{message}{Color.reset}",
        infosystem.columns,
    )


def message_start(func_name: str):
    """Message output for startup

    Args:
        func_name (str): Function name
    """
    date_time = datetime.now().astimezone().strftime("%Y/%m/%d %H:%M:%S %Z (%z)")
    text_prog = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    message_date(text_prog, "Start", Color.green, date_time)


def message_end(func_name: str):
    """Message output for termination

    Args:
        func_name (str): Function name
    """
    date_time = datetime.now().astimezone().strftime("%Y/%m/%d %H:%M:%S %Z (%z)")
    text_prog = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    message_date(text_prog, "Complete", Color.green, date_time)


def message_elapsed(func_name: str, elapsed: str):
    """Message output for elapsed time

    Args:
        func_name (str): Function name
        elapsed (str): Elapsed time
    """
    text_prog = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    text_time = timedelta(seconds=elapsed)
    eprint(
        f"{Color.reset}{Color.yellow}{text_prog:<{colsize_func}}|{'Elapsed':^{colsize_mode}}|{text_time}{Color.reset}",
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
    text_prog = omit_middle(f"{infosystem.program_name}:{func_name}", colsize_func)
    text_mesg = omit_middle(
        f"{message}", infosystem.columns - (colsize_func + colsize_mode + 1)
    )
    eprint(
        f"{Color.reset}{message_color}{text_prog:<{colsize_func}}|{mode:^{colsize_mode}}|{text_mesg}{Color.reset}",
        infosystem.columns,
    )


def message_info(func_name: str, message: str, omit: bool = False):
    """message output for information

    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    text_prog = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    text_mesg = (
        omit_middle(
            f"{message}", infosystem.columns - (colsize_func + colsize_mode + 2)
        )
        if omit == True
        else message
    )
    eprint(
        f"{Color.reset}{Color.br_green}{text_prog:<{colsize_func}}|{'info':^{colsize_mode}}|{text_mesg}{Color.reset}"
    )


def message_warn(func_name: str, message: str, omit: bool = False):
    """Message output for warning

    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    text_prog = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    text_mesg = (
        omit_middle(
            f"{message}", infosystem.columns - (colsize_func + colsize_mode + 2)
        )
        if omit == True
        else message
    )
    eprint(
        f"{Color.reset}{Color.br_yellow}{text_prog:<{colsize_func}}|{'info':^{colsize_mode}}|{text_mesg}{Color.reset}"
    )


def message_alert(func_name: str, message: str, omit: bool = False):
    """Message output for alert

    Args:
        func_name (str): Function name
        message (str): Message
        omit (bool, optional): Omit. Defaults to False.
    """
    text_prog = omit_middle(f"{infosystem.program_name}({func_name})", colsize_func)
    text_mesg = (
        omit_middle(
            f"{message}", infosystem.columns - (colsize_func + colsize_mode + 2)
        )
        if omit == True
        else message
    )
    eprint(
        f"{Color.reset}{Color.br_red}{text_prog:<{colsize_func}}|{'info':^{colsize_mode}}|{text_mesg}{Color.reset}"
    )


def get_caller_name(only: bool = True) -> str:
    """Get function name

    Args:
        only (bool, optional): Function only or including filename. Defaults to True.

    Returns:
        str: _description_
    """
    frame = inspect.currentframe().f_back
    func_name = str(frame.f_code.co_name)
    file_name = str(Path(frame.f_code.co_filename).stem)
    # modu_name = str(frame.f_globals.get("__name__"))
    call_info = func_name if only == True else f"{file_name}({func_name})"
    return call_info


# --- eof ---------------------------------------------------------------------
