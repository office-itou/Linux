# --- python library ----------------------------------------------------------
import shutil
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    file_backup,
    get_caller_name,
    message_alert,
    message_info,
    run_subprocess,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def setup_hostname(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check command -------------------------------------------------------
    if not shutil.which("hostnamectl"):
        return
    # --- hostname ------------------------------------------------------------
    if _data.nics_fqdn:
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/hostname"))
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        _comd_list: list[str] = ["hostnamectl", "hostname", _data.nics_fqdn]
        _result = run_subprocess(_comd_list)
        if _result.returncode == 0:
            message_info(_caller, f"{'success':<10}:{' '.join(_comd_list)}", omit=True)
        else:
            message_info(_caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True)
        _comd_list: list[str] = ["hostnamectl", "status"]
        _result = run_subprocess(_comd_list)
        if _result.returncode == 0:
            message_info(_caller, f"{'info':<10}:{_result.stdout}", omit=True)
        else:
            message_alert(_caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
