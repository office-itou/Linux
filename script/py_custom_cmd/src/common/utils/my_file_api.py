"""File I/O processing"""

# --- Python library ----------------------------------------------------------
import os
import re
import shutil
from datetime import datetime
from pathlib import Path

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_error import handle_fatal_error
from .my_message import get_caller_name, message_alert


@debug_logger
def file_read(src_path: Path, text: bool = True) -> str | bytes:
    """File read (line break codes in text files are standardized to "\n")

    Args:
        src_path (Path): Source path
        text (bool, optional): Read mode. Defaults to True.

    Raises:
        SystemExit: OSError
        SystemExit: Exception

    Returns:
        str| bytes: Result
    """
    _caller = get_caller_name()
    try:
        _src_path = src_path.resolve()
        _mode = "r" if text else "rb"
        _encoding = "utf-8" if text else None
        with open(src_path, mode=_mode, encoding=_encoding, newline=None) as f:
            return f.read()
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def file_write(
    dest_path: Path,
    data: str | bytes | None = None,
    text: bool = True,
    backup: bool = False,
) -> None:
    """File write (line break codes in text files are standardized to "\n")

    Args:
        dest_path (Path): Destination path
        data (str | bytes | None, optional): Output data. Defaults to None.
        text (bool, optional): Write mode. Defaults to True.
        backup (bool, optional): Backup mode. Defaults to False.

    Raises:
        SystemExit: OSError
        SystemExit: Exception
    """
    _caller = get_caller_name()
    try:
        _dest_path = dest_path.resolve()
        _mode = "w" if text else "wb"
        _encoding = "utf-8" if text else None
        _newline = "\n" if text else None
        if data is None:
            data = "" if text else b""
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        if backup:
            file_backup(dest_path)
        with open(dest_path, mode=_mode, encoding=_encoding, newline=_newline) as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        if not dest_path.exists():
            message_alert(get_caller_name(), f"failed: {dest_path}")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def file_copy(src_path: Path, dest_path: Path, backup: bool = False) -> None:
    """File copy

    Args:
        src_path (Path): Source path
        dest_path (Path): Destination path
        backup (bool, optional): Backup. Defaults to False.
    """
    _caller = get_caller_name()
    try:
        dest_path = dest_path.resolve()
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        if bool == True:
            file_backup(dest_path)
            shutil.copy2(src_path, dest_path)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def file_backup(src_path: Path) -> None:
    """File backup

    Args:
        src_path (Path): Source path
    """
    _caller = get_caller_name()
    try:
        src_path = src_path.resolve()
        if src_path.exists() and src_path.is_file():
            # --- backup ------------------------------------------------------
            _timestamp = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
            _base_name = src_path.stem
            _ext = src_path.suffix
            _backup_path = src_path.with_name(f"{_base_name}_{_timestamp}{_ext}")
            shutil.copy2(src_path, _backup_path)
            # --- history & cleanup -------------------------------------------
            _all_files = src_path.parent.glob(f"{_base_name}_*{_ext}")
            _pattern = re.compile(
                rf"^{re.escape(_base_name)}_\d{{14}}_\d{{6}}{re.escape(_ext)}$"
            )
            backups = []
            for f in _all_files:
                if _pattern.match(f.name):
                    backups.append(str(f))
            backups.sort(key=os.path.getmtime)
            # --- cleanup -----------------------------------------------------
            while len(backups) > 3:
                oldest_backup = backups.pop(0)
                os.remove(oldest_backup)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
