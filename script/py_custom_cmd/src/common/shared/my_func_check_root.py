#!/usr/bin/env python3
"""Check root"""

# --- Python library ----------------------------------------------------------
import os


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    Color,
    debug_logger,
    infosystem,
)


# ruff: isort: on
# =============================================================================
@debug_logger
def check_root(bypass: bool = False) -> bool:
    if bypass or os.geteuid() == 0:
        return True
    print(
        f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n"
        f"{Color.br_yellow} You have standard user privileges. "
        f"{Color.underline}Please run this with sudo -E.{Color.reset}"
    )
    return False
