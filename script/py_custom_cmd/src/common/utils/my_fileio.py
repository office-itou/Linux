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
def file_read(path_src: Path, text: bool = True) -> str | bytes:
    """File read (line break codes in text files are standardized to "\n")

    Args:
        path_src (Path): Source path
        text (bool, optional): Read mode. Defaults to True.

    Raises:
        SystemExit: OSError
        SystemExit: Exception

    Returns:
        str| bytes: Result
    """
    caller = get_caller_name()
    try:
        path_src = path_src.resolve()
        mode = "r" if text else "rb"
        encoding = "utf-8" if text else None
        with open(path_src, mode=mode, encoding=encoding, newline=None) as f:
            return f.read()
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


@debug_logger
def file_write(
    path_dest: Path,
    data: str | bytes | None = None,
    text: bool = True,
    backup: bool = False,
) -> None:
    """File write (line break codes in text files are standardized to "\n")

    Args:
        path_dest (Path): Destination path
        data (str | bytes | None, optional): Output data. Defaults to None.
        text (bool, optional): Write mode. Defaults to True.
        backup (bool, optional): Backup mode. Defaults to False.

    Raises:
        SystemExit: OSError
        SystemExit: Exception
    """
    caller = get_caller_name()
    try:
        path_dest = path_dest.resolve()
        mode = "w" if text else "wb"
        encoding = "utf-8" if text else None
        newline = "\n" if text else None
        if data is None:
            data = "" if text else b""
        path_dest.parent.mkdir(parents=True, exist_ok=True)
        if backup:
            file_backup(path_dest)
        with open(path_dest, mode=mode, encoding=encoding, newline=newline) as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        if not path_dest.exists():
            message_alert(get_caller_name(), f"failed: {path_dest}")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


@debug_logger
def file_copy(path_src: Path, path_dest: Path, backup: bool = False) -> None:
    """File copy

    Args:
        path_src (Path): Source path
        path_dest (Path): Destination path
        backup (bool, optional): Backup. Defaults to False.
    """
    caller = get_caller_name()
    try:
        path_dest = path_dest.resolve()
        path_dest.parent.mkdir(parents=True, exist_ok=True)
        if bool == True:
            file_backup(path_dest)
            shutil.copy2(path_src, path_dest)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


@debug_logger
def file_backup(path_src: Path) -> None:
    """File backup

    Args:
        src_path (Path): Source path
    """
    caller = get_caller_name()
    try:
        path_src = path_src.resolve()
        if path_src.exists() and path_src.is_file():
            # --- backup ------------------------------------------------------
            timestamp = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
            base_name = path_src.stem
            ext = path_src.suffix
            backup_path = path_src.with_name(f"{base_name}_{timestamp}{ext}")
            shutil.copy2(path_src, backup_path)
            # --- history & cleanup -------------------------------------------
            all_files = path_src.parent.glob(f"{base_name}_*{ext}")
            pattern = re.compile(
                rf"^{re.escape(base_name)}_\d{{14}}_\d{{6}}{re.escape(ext)}$"
            )
            backups = []
            for f in all_files:
                if pattern.match(f.name):
                    backups.append(str(f))
            backups.sort(key=os.path.getmtime)
            # --- cleanup -----------------------------------------------------
            while len(backups) > 3:
                oldest_backup = backups.pop(0)
                os.remove(oldest_backup)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


# --- eof ---------------------------------------------------------------------
