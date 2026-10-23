#!/usr/bin/env python3
# --- python library ----------------------------------------------------------
# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import (
    proc_comp,
    proc_init,
)
from common.utils import (
    debug_logger,
    get_caller_name,
    infosystem,
)

# ruff: isort: on
# --- import module -----------------------------------------------------------
from autoinst_syspara import InfoSystem

from autoinst_common_cfg import InfoConfiguration
from autoinst_initialize import initialize


# --- class and function ------------------------------------------------------
# --- initialize --------------------------------------------------------------
# --- main --------------------------------------------------------------------
@debug_logger
def main() -> None:
    """Main"""
    _caller = get_caller_name()
    _info_conf: InfoConfiguration
    _info_syst: InfoSystem
    _info_syst, _info_conf = initialize()


if __name__ == "__main__":
    # --- initialization ------------------------------------------------------
    _caller = get_caller_name()
    proc_init(
        description="autoinst late command", list_args=[], caller=_caller, is_gui=False
    )
    # --- processing block ----------------------------------------------------
    if infosystem.args:
        main()
    # --- complete ------------------------------------------------------------
    proc_comp(caller=_caller)
# --- eof ---------------------------------------------------------------------
