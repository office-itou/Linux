# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def find_command(tget_path: Path, srvc_name: str) -> Path | None:
    _tget_path: Path = Path(tget_path)
    for _find_dir in ["/bin", "/sbin", "/usr/bin", "/usr/sbin"]:
        _find_path: Path = Path(_find_dir) / srvc_name
        _conf_path: Path = addpath(base=_tget_path, path=_find_path)
        if _conf_path.exists():
            return _conf_path
    return None
