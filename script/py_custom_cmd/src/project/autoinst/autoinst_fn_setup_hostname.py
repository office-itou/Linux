# --- python library ----------------------------------------------------------
import shutil
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    fwrite,
    get_caller_name,
    handle_fatal_error,
    message_alert,
    message_info,
    run_subprocess,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_file_backup import file_backup, file_origin


# --- class and function ------------------------------------------------------
@debug_logger
def setup_hostname(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check parameter -----------------------------------------------------
    if not _data.nics_fqdn:
        message_info(_caller, f"{'skip':<10}:hostname", omit=True)
        return
    try:
        message_info(_caller, f"{'setup':<10}:hostname", omit=True)
        # --- hostname --------------------------------------------------------
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/hostname"))
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        if shutil.which("hostnamectl"):
            _comd_list: list[str] = ["hostnamectl", "hostname", _data.nics_fqdn]
            _result = run_subprocess(_comd_list)
            if _result.returncode == 0:
                message_info(
                    _caller, f"{'success':<10}:{' '.join(_comd_list)}", omit=True
                )
            else:
                message_info(
                    _caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True
                )
            _comd_list: list[str] = ["hostnamectl", "status"]
            _result = run_subprocess(_comd_list)
            if _result.returncode == 0:
                message_info(_caller, f"{'info':<10}:{_result.stdout}", omit=True)
            else:
                message_alert(
                    _caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True
                )
        elif shutil.which("hostname"):
            _comd_list: list[str] = ["hostname", _data.nics_fqdn]
            _result = run_subprocess(_comd_list)
            if _result.returncode == 0:
                message_info(
                    _caller, f"{'success':<10}:{' '.join(_comd_list)}", omit=True
                )
            else:
                message_info(
                    _caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True
                )
            _comd_list: list[str] = ["hostname"]
            _result = run_subprocess(_comd_list)
            if _result.returncode == 0:
                message_info(_caller, f"{'info':<10}:{_result.stdout}", omit=True)
            else:
                message_alert(
                    _caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True
                )
        elif _conf_path.exists():
            fwrite(dest_path=_conf_path, data=_data.nics_fqdn, text=True, backup=False)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
