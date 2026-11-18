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
def setup_hosts(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check parameter -----------------------------------------------------
    if not _data.nics_fqdn:
        message_info(_caller, f"{'skip':<10}:hosts", omit=True)
        return
    try:
        message_info(_caller, f"{'setup':<10}:hosts", omit=True)
        # --- hosts -----------------------------------------------------------
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/hosts"))
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _nics_ipv4: str = (
            _data.ipv4_dumy if _data.nics_ipv4.split(".")[3] == "0" else _data.nics_ipv4
        )
        _ipv4_lhst: str = _data.ipv4_lhst if _data.ipv4_lhst else "127.0.0.1"
        _ipv6_lhst: str = _data.ipv6_lhst if _data.ipv6_lhst else "::1"
        _fmat_parm: str = "{:<16} {}"
        _writ_text: str = cat(rf"""
			{_fmat_parm.format(_ipv4_lhst, r"localhost")}
			{_fmat_parm.format(_nics_ipv4, f"{_data.nics_fqdn} {_data.nics_host}")}
			
			# The following lines are desirable for IPv6 capable hosts
			{_fmat_parm.format(_ipv6_lhst, r"localhost ip6-localhost ip6-loopback")}
			{_fmat_parm.format(r"fe00::0", r"ip6-localnet")}
			{_fmat_parm.format(r"ff00::0", r"ip6-mcastprefix")}
			{_fmat_parm.format(r"ff02::1", r"ip6-allnodes")}
			{_fmat_parm.format(r"ff02::2", r"ip6-allrouters")}
		""")
        fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
