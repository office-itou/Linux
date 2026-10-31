# --- python library ----------------------------------------------------------
import os
import shutil
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    file_backup,
    file_origin,
    fread,
    fwrite,
    get_caller_name,
    message_alert,
    message_info,
    run_subprocess,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def setup_netplan(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check command -------------------------------------------------------
    if not shutil.which("netplan"):
        return
    # --- configures ----------------------------------------------------------
    if shutil.which("nmcli"):
        # --- with network manager --------------------------------------------
        _npln_path: Path = addpath(base=_tget_path, path=Path("/etc/netplan"))
        for _conf_path in _npln_path.glob("*.yaml"):
            file_backup(info_syst=info_syst, orig_path=_conf_path)
            message_info(_caller, f"{'remove':<10}:{_conf_path}", omit=True)
            _conf_path.unlink()
        # --- 99-network-config-all.yaml --------------------------------------
        _conf_path: Path = addpath(
            base=_tget_path, path=Path("/etc/netplan/99-network-manager-all.yaml")
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _read_text: str = fread(src_path=_conf_path, text=True)
        _writ_text: str = (
            f"{_read_text}\nnetwork:\n  version: 2\n  renderer: NetworkManager\n"
        )
        fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        os.chmod(path=_conf_path, mode=0o600)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- 99-disable-network-config.cfg -----------------------------------
        _conf_path: Path = addpath(
            base=_tget_path,
            path=Path("/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"),
        )
        if _conf_path.exists():
            file_backup(info_syst=info_syst, orig_path=_conf_path)
            file_origin(info_syst=info_syst, orig_path=_conf_path)
        _writ_text: str = "network: {config: disabled}"
        fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    else:
        _conf_path: Path = addpath(
            base=_tget_path,
            path=Path(f"/etc/netplan/99-network-config-{_data.nics_name}.yaml"),
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _writ_text: str = (
            "network:\n"
            "	version: 2\n"
            "	renderer: networkd\n"
            "	ethernets:\n"
            f"	{_data.nics_name}:\n"
        )
        if _data.ipv4_auto:
            _writ_text += "dhcp4: true\ndhcp6: true\nipv6-privacy: true\n"
        else:
            _writ_text += (
                "addresses:\n"
                f"- {_data.nics_cidr}\n"
                "routes:\n"
                "- to: default\n"
                f"via: {_data.nics_gway}\n"
                "nameservers:\n"
                "search:\n"
                f"- {_data.nics_wgrp}\n"
                "addresses:\n"
                f"- {_data.nics_nsvr}\n"
                "dhcp4: false\n"
                "dhcp6: true\n"
                "ipv6-privacy: true\n"
            )
        fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        os.chmod(path=_conf_path, mode=0o600)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    # --- netplan -------------------------------------------------------------
    _comd_list: list[str] = ["netplan", "status"]
    _result = run_subprocess(_comd_list)
    if _result.returncode == 0:
        _comd_list: list[str] = ["netplan", "apply"]
        _result = run_subprocess(_comd_list)
        if _result.returncode == 0:
            message_info(_caller, f"{'success':<10}:{' '.join(_comd_list)}", omit=True)
        else:
            message_alert(_caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True)
    else:
        message_alert(_caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True)


# --- eof ---------------------------------------------------------------------
