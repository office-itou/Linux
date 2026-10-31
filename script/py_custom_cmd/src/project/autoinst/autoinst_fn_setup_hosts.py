# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    file_backup,
    fwrite,
    get_caller_name,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
@debug_logger
def setup_hosts(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- hosts ---------------------------------------------------------------
    if _data.nics_fqdn:
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/hosts"))
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        _nics_ipv4: str = (
            _data.ipv4_dumy if _data.nics_ipv4.split(".")[3] == "0" else _data.nics_ipv4
        )
        _ipv4_lhst: str = _data.ipv4_lhst if _data.ipv4_lhst else "127.0.0.1"
        _ipv6_lhst: str = _data.ipv6_lhst if _data.ipv6_lhst else "::1"
        _fmat_parm: str = "{:<16} {}\n"
        _fmat_list = [
            _fmat_parm.format(_ipv4_lhst, "localhost"),
            _fmat_parm.format(_nics_ipv4, f"{_data.nics_fqdn} {_data.nics_host}"),
            "\n",
            "# The following lines are desirable for IPv6 capable hosts\n",
            _fmat_parm.format(_ipv6_lhst, "localhost ip6-localhost ip6-loopback"),
            _fmat_parm.format("fe00::0", "ip6-localnet"),
            _fmat_parm.format("ff00::0", "ip6-mcastprefix"),
            _fmat_parm.format("ff02::1", "ip6-allnodes"),
            _fmat_parm.format("ff02::2", "ip6-allrouters"),
        ]
        _writ_text = "\n".join(s for s in _fmat_list)
        fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
