# --- Python library ----------------------------------------------------------
import os

# --- my library --------------------------------------------------------------
from common.utils import (
    Argument,
    TimeElapsed,
    get_caller_name,
    infosystem,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    print_peak_memory,
)


# ruff: isort: on
def proc_init(
    description: str, list_args: list[dict[str]] = [], caller: str = get_caller_name()
) -> None:
    # --- initialization --------------------------------------------------
    Argument(description=description, list_args=list_args)
    _gui = (
        bool(os.getenv("DISPLAY"))
        if not getattr(infosystem.args, "force_cui", True)
        else False
    )
    infosystem.initialize(is_gui=_gui)
    infosystem.elapsed = TimeElapsed()
    message_start(caller)
    if infosystem.debugout:
        _message = "--- system info ---"
        message_info(caller, _message, omit=True)
        for _message in (
            f"{'GUI mode':<9}={getattr(infosystem, 'is_gui', '')}",
            f"{'Debug':<9}={getattr(infosystem, 'debug', '')}",
            f"{'Debugout':<9}={getattr(infosystem, 'debugout', '')}",
            f"{'exec user':<9}={getattr(infosystem.data, 'exec_user', '')}",
            f"{'home dir':<9}={getattr(infosystem.data, 'home_dir', '')}",
        ):
            message_info(caller, _message, omit=True)
        _message = "--- command args ---"
        message_info(caller, _message, omit=True)
        for _args in infosystem.args.__dict__:
            _message = f"{_args:<9}={getattr(infosystem.args, _args, '')}"
            message_info(caller, _message, omit=True)


def proc_comp(caller: str = get_caller_name()) -> None:
    # --- complete --------------------------------------------------------
    message_end(caller)
    message_elapsed(caller, infosystem.elapsed.elapsed(), omit=True)
    print_peak_memory(caller)


# --- eof ---------------------------------------------------------------------
