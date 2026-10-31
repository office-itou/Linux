# --- python library ----------------------------------------------------------
import shutil
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    get_caller_name,
    infosystem,
    message_info,
)

# ruff: isort: on
# --- import module -----------------------------------------------------------
from autoinst_fn_common_cfg import InfoConfiguration
from autoinst_fn_info_syspara import InfoSystem


# --- class and function ------------------------------------------------------
# --- initialize --------------------------------------------------------------
@debug_logger
def initialize() -> InfoSystem:
    """Initialize"""
    _caller = get_caller_name()
    # --- copy resolv.conf ----------------------------------------------------
    _stub_path = Path("/run/systemd/resolve/stub-resolv.conf")
    _rslv_path = Path("/etc/resolv.conf")
    if not _stub_path.exists() and not _rslv_path.is_symlink():
        message_info(_caller, f"copy {_stub_path}", omit=True)
        _stub_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(_rslv_path, _stub_path)
    # --- common.cfg ----------------------------------------------------------
    _conf_path: Path = Path(infosystem.program_path.parent) / "common.cfg"
    _info_conf: InfoConfiguration = InfoConfiguration(conf_path=_conf_path)
    # --- command line --------------------------------------------------------
    _info_syst: InfoSystem = InfoSystem(info_conf=_info_conf)
    # _info_syst.print_info(debugout=True)
    # --- debug ---------------------------------------------------------------
    # _info_syst.debug(debugout=bool(_info_syst.data.dout_flag or infosystem.debugout))
    # _info_conf.debug(debugout=bool(_info_syst.data.dbgs_flag or infosystem.debug))
    # --- return --------------------------------------------------------------
    return _info_syst
