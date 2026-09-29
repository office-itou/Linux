#!/usr/bin/env python3
"""Generate markdown"""

# --- Python library ----------------------------------------------------------
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    get_caller_name,
    message_info,
)
from common.shared import (
    InfoCommon,
)


# ruff: isort: on
# =============================================================================
@debug_logger
def generate_markdown(dest_dir_path: Path, info_comm: InfoCommon) -> None:
    _caller = get_caller_name()
    message_info(_caller, f"Generate markdown ({dest_dir_path})", omit=True)
    info_comm.conf.markdown(
        dest_dir_path / "Readme_Configuration.md",
        f"Configuration data({info_comm.conf_path.name})",
    )
    info_comm.dist.markdown(
        dest_dir_path / "Readme_Distribution.md",
        f"Distribution data({info_comm.dist_path.name})",
    )
    info_comm.mdia.markdown(
        dest_dir_path / "Readme_Media.md",
        f"Media data({info_comm.mdia_path.name})",
    )
