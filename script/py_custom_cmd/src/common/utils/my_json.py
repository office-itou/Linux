"""Json processing"""

# --- Python library ----------------------------------------------------------
import json
from pathlib import Path
from typing import Any


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    handle_fatal_error,
    file_read,
    file_write,
    get_caller_name,
    message_alert,
)


# ruff: isort: on
# =============================================================================
@debug_logger
def json_load(src_path: Path) -> Any:
    """Load data in json format
    Args:
        src_path (Path): Source path
    Returns:
        Any: data
    """
    _caller = get_caller_name()
    try:
        _read_data: str = str(file_read(src_path))
        return json.loads(_read_data)
    except (OSError, Exception) as e:  # noqa: BLE001
        message_alert(_caller, f"target file: {src_path}")
        handle_fatal_error(_caller, e)


# -----------------------------------------------------------------------------
@debug_logger
def json_save(dest_path: Path, src_data: Any) -> None:
    """Save distridata in json format
    Args:
        dest_path (Path): Destination path
        src_data (Any): Source data
    """
    _caller = get_caller_name()
    try:
        _write_data = json.dumps(src_data, ensure_ascii=False, indent=4)
        file_write(dest_path, _write_data, text=True, backup=True)
    except (OSError, Exception) as e:  # noqa: BLE001
        message_alert(_caller, f"target file: {dest_path}")
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
