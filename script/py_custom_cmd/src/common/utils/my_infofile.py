"""Retrieves file information from the local system."""

# --- Python library ----------------------------------------------------------
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import magic  # sudo apt-get install python3-magic

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_process import run_subprocess


# -----------------------------------------------------------------------------
@dataclass
class FileData:
    """File data class"""

    path: str = ""
    tmstamp: str = ""
    size: int = 0
    volume: str = ""


class InfoFile:
    """File information class"""

    def __init__(self, data: FileData = None):
        self.data: FileData = data if data is not None else FileData()

    def get_data(self) -> FileData:
        return self.data

    def get_info(self, target_path: str) -> FileData:
        self.data = get_info(target_path)
        return self.data

    def get_volume_uuid(device: str) -> str:
        return get_volume_uuid(device)

    def get_volume_label(device: str) -> str:
        return get_volume_label(device)


@debug_logger
def get_volume_uuid(device: str) -> str:
    """Get volume uuid

    Args:
        device (str): Device name

    Returns:
        str: UUID
    """
    parameter = ["blkid", "-s", "UUID", "-o", "value", device]
    return run_subprocess(parameter)


@debug_logger
def get_volume_label(device: str) -> str:
    """Get volume label

    Args:
        device (str): Device name

    Returns:
        str: Volume label
    """
    parameter = ["blkid", "-s", "LABEL", "-o", "value", device]
    return run_subprocess(parameter)


# -----------------------------------------------------------------------------
# descript: get web information data
#   input : target_path           : input
#   output:                       : unused
#   return: InfoFile              : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
def get_info(target_path: str) -> FileData:
    """Get file information data

    Args:
        target_path (str): Target path

    Returns:
        FileData: File information
    """
    data = FileData()
    path = Path(target_path)
    data.path = str(path.resolve())
    if path.exists():
        kind = magic.from_file(data.path, mime=True)
        if kind and kind == "application/x-iso9660-image":
            data.volume = get_volume_label(data.path)
        data.tmstamp = datetime.fromtimestamp(
            path.stat().st_mtime, tz=timezone.utc
        ).isoformat()
        data.size = path.stat().st_size
    #   else:
    #       message_alert(get_caller_name(), f"File not exist: {target_path}")
    # --- return --------------------------------------------------------------
    return data


# --- eof ---------------------------------------------------------------------
