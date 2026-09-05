"""Json processing"""

# --- Python library ----------------------------------------------------------
import json
from pathlib import Path
from typing import Any

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_fileio import file_backup


# -----------------------------------------------------------------------------
@debug_logger
def json_load(src_path: str) -> Any:
    """Load data in json format

    Args:
        src_path (str): Source path

    Returns:
        Any: data
    """
    with open(src_path, "r", encoding="utf-8") as f:
        return json.load(f)


# -----------------------------------------------------------------------------
@debug_logger
def save_json(dst_path: str, src_data: Any) -> None:
    """Save distridata in json format

    Args:
        dst_path (str): Destination path
        src_data (Any): Source data
    """
    Path(dst_path).parent.mkdir(parents=True, exist_ok=True)
    file_backup(dst_path)
    with open(dst_path, "w", encoding="utf-8") as f:
        json.dump(src_data, f, ensure_ascii=False, indent=4)


# --- eof ---------------------------------------------------------------------
