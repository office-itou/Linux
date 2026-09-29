#!/usr/bin/env python3
"""Check root"""

# --- Python library ----------------------------------------------------------

# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    Argument,
    debug_logger,
    infosystem,
)


# ruff: isort: on
# =============================================================================
@debug_logger
def initarg(description: str, list_args: list = []) -> None:
    """Initialize argument"""
    arg_manager = Argument(f"{description}\n")
    if list_args:
        for line_arg in list_args:
            arg_name = line_arg.pop("arg")
            if isinstance(arg_name, tuple):
                arg_manager.add(*arg_name, **line_arg)
            else:
                arg_manager.add(arg_name, **line_arg)
    infosystem.args = arg_manager.parse()
