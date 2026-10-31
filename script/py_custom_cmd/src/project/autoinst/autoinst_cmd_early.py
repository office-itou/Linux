#!/usr/bin/env python3
# --- python library ----------------------------------------------------------
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import (
    proc_comp,
    proc_init,
)
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    infosystem,
)

# ruff: isort: on
# --- import module -----------------------------------------------------------
from autoinst_fn_get_conf_file import get_conf_file
from autoinst_fn_info_network import network_param
from autoinst_fn_initialize import initialize
from autoinst_fn_setup_wireplumber import setup_wireplumber


# --- class and function ------------------------------------------------------
# --- initialize --------------------------------------------------------------
# --- main --------------------------------------------------------------------
@debug_logger
def main() -> None:
    """Main"""
    _caller = get_caller_name()
    _info_syst = initialize()
    _info_syst = network_param(info_syst=_info_syst)
    _info_syst.debug(debugout=bool(_info_syst.data.dout_flag or infosystem.debugout))
    _info_syst.print_info(
        debugout=not bool(_info_syst.data.dout_flag or infosystem.debugout)
    )
    setup_wireplumber(info_syst=_info_syst)
    get_conf_file(info_syst=_info_syst)
    # --- success -------------------------------------------------------------
    _stat_name: str = f"{_info_syst.data.prog_name}.success"
    _stat_path: Path = _info_syst.data.acmd_path / _stat_name
    if _stat_path.exists() and _stat_path.is_dir():
        _stat_path.rmdir()
    _stat_path.mkdir(parents=True, exist_ok=True)


if __name__ == "__main__":
    # --- initialization ------------------------------------------------------
    _caller = get_caller_name()
    try:
        proc_init(
            description="autoinst late command",
            list_args=[],
            caller=_caller,
            is_gui=False,
        )
        # --- processing block ------------------------------------------------
        if infosystem.args:
            main()
        # --- complete --------------------------------------------------------
        proc_comp(caller=_caller)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
# --- eof ---------------------------------------------------------------------
