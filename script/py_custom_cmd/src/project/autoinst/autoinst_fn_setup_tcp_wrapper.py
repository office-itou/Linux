# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    file_backup,
    file_origin,
    fread,
    fwrite,
    get_caller_name,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
def setup_tcp_wrapper(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- hosts.allow ---------------------------------------------------------
    _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/hosts.allow"))
    file_backup(info_syst=info_syst, orig_path=_conf_path)
    file_origin(info_syst=info_syst, orig_path=_conf_path)
    _read_text: str = fread(src_path=_conf_path, text=True)
    _writ_text: str = (
        f"{_read_text}\nALL: [fe80::]/10\nALL: {_data.nics_uadr}.0/{_data.nics_prfx}"
    )
    fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
    file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    # --- hosts.deny ----------------------------------------------------------
    _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/hosts.deny"))
    file_backup(info_syst=info_syst, orig_path=_conf_path)
    file_origin(info_syst=info_syst, orig_path=_conf_path)
    _read_text: str = fread(src_path=_conf_path, text=True)
    _writ_text: str = f"{_read_text}\nALL: ALL"
    fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
    file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
