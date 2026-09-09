"""Json processing"""

# --- Python library ----------------------------------------------------------
import json
from pathlib import Path
from typing import Any

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_error import handle_fatal_error
from .my_fileio import file_read, file_write
from .my_message import get_caller_name


# -----------------------------------------------------------------------------
@debug_logger
def json_load(src_path: Path) -> Any:
    """Load data in json format

    Args:
        src_path (Path): Source path

    Returns:
        Any: data
    """
    caller = get_caller_name()
    try:
        read_data = file_read(src_path)
        return json.loads(read_data)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


# -----------------------------------------------------------------------------
@debug_logger
def json_save(dst_path: Path, src_data: Any) -> None:
    """Save distridata in json format

    Args:
        dst_path (Path): Destination path
        src_data (Any): Source data
    """
    caller = get_caller_name()
    try:
        write_data = json.dumps(src_data, ensure_ascii=False, indent=4)
        file_write(dst_path, write_data, text=True, backup=True)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


# --- eof ---------------------------------------------------------------------
