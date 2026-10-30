# --- python library ----------------------------------------------------------
import os
import shutil
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    delpath,
    get_caller_name,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def file_backup(info_syst, orig_path: Path, mode: str=None) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check ---------------------------------------------------------------
    if not orig_path.exists():
        message_info(_caller, f"{'caution':<10}:not exist:{orig_path}", omit=True)
        orig_path.parent.mkdir(parents=True, exist_ok=True)
        _real_path = orig_path.resolve()
        if not _real_path.exists():
            _real_path.parent.mkdir(parents=True, exist_ok=True)
        orig_path.write_text("", encoding="utf-8")
    # --- backup --------------------------------------------------------------
    match mode:
        case "samp":
            _dirs_path: Path = _data.samp_path
        case "init":
            _dirs_path: Path = _data.init_path
        case _:
            _dirs_path: Path = _data.orig_path
    _dirs_path: Path = addpath(base=_tget_path, path=_dirs_path)
    _back_path: Path = _dirs_path / delpath(base=_tget_path, path=orig_path)
    _back_path.parent.mkdir(parents=True, exist_ok=True)
    os.chmod(path=_dirs_path, mode=0o600)
    if _back_path.exists() or _back_path.is_symlink():
        _move_path = _back_path.with_suffix(f"{_back_path.suffix}.{_data.time_stmp}")
        shutil.move(src=_back_path, dst=_move_path)
    message_info(_caller, f"{'backup':<10}:not exist:{orig_path}", omit=True)
    shutil.copy2(orig_path, _back_path)

@debug_logger
def file_origin(info_syst, orig_path: Path) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    _back_path:Path=_data.orig_path / delpath(base=_tget_path, path=orig_path)
    orig_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(_back_path, orig_path)
    _back_stat = _back_path.stat()
    os.utime(orig_path, times=(_back_stat.st_atime, _back_stat.st_mtime))
