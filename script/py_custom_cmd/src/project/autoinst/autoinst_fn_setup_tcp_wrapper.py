# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    cat,
    debug_logger,
    fwrite,
    get_caller_name,
    handle_fatal_error,
    message_info,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_file_backup import file_backup, file_origin


# --- class and function ------------------------------------------------------
@debug_logger
def setup_tcp_wrapper(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check parameter -----------------------------------------------------
    if not _data.nwrk_fqdn:
        message_info(_caller, f"{'skip':<10}:tcp wrapper", omit=True)
        return
    try:
        message_info(_caller, f"{'setup':<10}:tcp wrapper", omit=True)
        # --- hosts.allow -----------------------------------------------------
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/hosts.allow"))
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _writ_text: str = cat(rf"""
			ALL: [fe80::]/10
			ALL: {_data.ipv4_uadr}.0/{_data.ipv4_prfx}
		""")
        fwrite(
            dest_path=_conf_path,
            data=_writ_text,
            text=True,
            backup=False,
            append=True,
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- hosts.deny ------------------------------------------------------
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/hosts.deny"))
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _writ_text: str = cat(r"""
			ALL: ALL
		""")
        fwrite(
            dest_path=_conf_path,
            data=_writ_text,
            text=True,
            backup=False,
            append=True,
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
