# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
)


# --- import module -----------------------------------------------------------


# --- class and function ------------------------------------------------------
@debug_logger
def setup_blacklist(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
