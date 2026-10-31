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
    find_serivce,
    fwrite,
    get_caller_name,
    is_service_active,
    message_alert,
    message_info,
    restart_user_service,
    run_subprocess,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def setup_netman(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check service -------------------------------------------------------
    _srvc_name: str = "NetworkManager.service"
    _srvc_path: Path = find_serivce(tget_path=_tget_path, srvc_name=_srvc_name)
    if not _srvc_path or not _srvc_path.exists():
        return
    _result = run_subprocess(["nmcli", "--version"])
    _comd_vers = str(_result.stdout.splitlines()) if _result.returncode == 0 else ""
    message_info(_caller, f"{'info':<10}:nmcli version:{_comd_vers}", omit=True)
    # --- configures ----------------------------------------------------------
    _nman_path: Path = addpath(base=_tget_path, path=Path("/etc/NetworkManager"))
    if not _data.nic_name:
        for _conf_name in ("zz-all-en", "zz-all-eth"):
            _conf_path: Path = Path(
                f"{_nman_path}/system-connections/{_conf_name}.nmconnection"
            )
            file_backup(info_syst=info_syst, orig_path=_conf_path)
            file_origin(info_syst=info_syst, orig_path=_conf_path)
            _fwal_parm: list[str] = (
                ["connection.zone", _data.fwal_zone] if _data.fwal_zone else []
            )
            _comd_list: list[str] = [
                "nmcli",
                "--offline",
                "connection add",
                "type",
                "ethernet",
                "match.interface-name",
                f"{_conf_name.replace('zz-all-', '')}*",
                "connection.id",
                _conf_name,
                "connection.autoconnect",
                "true",
                "connection.autoconnect-priority",
                "999",
                *_fwal_parm,
                "ethernet.wake-on-lan",
                "0",
                "ipv4.method",
                "auto",
                "ipv6.method",
                "auto",
                "ipv6.addr-gen-mode",
                "default",
            ]
            _result = run_subprocess(_comd_list)
            if _result.returncode == 0:
                fwrite(
                    dest_path=_conf_path,
                    data=_result.stdout,
                    text=True,
                    backup=False,
                )
                shutil.chown(path=_conf_path, user="root", group="root")
                os.chmod(_conf_path, 0o600)
                file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    else:
        _runs_path: Path = addpath(base=_tget_path, path=Path("/run/NetworkManager"))
        _conf_sufx: str = ""
        for _dirs_path in [_nman_path, _runs_path]:
            _scon_path: Path = _dirs_path / "system-connections"
            if _scon_path.glob("*.nmconnection"):
                _conf_sufx: str = "nmconnection"
                break
        _conf_name: str = (
            f"{_data.nics_name}.nmconnection" if _conf_sufx else "Wired connection 1"
        )
        _conf_path: Path = _nman_path / _conf_name
        _parm_list: list[str] = ["type ethernet"]
        if _conf_name:
            _parm_list.append("connection.id", _conf_name)
        if _data.nics_name:
            _parm_list.append("connection.interface-name", _data.nics_name)
        _parm_list.append("connection.autoconnect", "true")
        if _data.fwal_zone:
            _parm_list.append("connection.zone", _data.fwal_zone)
        _parm_list.append("ethernet.wake-on-lan", "0")
        if _data.nics_madr:
            _parm_list.append("ethernet.mac-address", _data.nics_madr)
        if _data.ipv4_auto:
            _parm_list.append(
                "ipv4.method",
                "auto",
                "ipv6.method",
                "auto",
                "ipv6.addr-gen-mode",
                "default",
            )
        else:
            _parm_list.append("ipv4.method", "manual")
            if _data.nics_cidr:
                _parm_list.append("ipv4.address", _data.nics_cidr)
            if _data.nics_gway:
                _parm_list.append("ipv4.gateway", _data.nics_gway)
            if _data.nics_gway:
                _parm_list.append("ipv4.dns", _data.nics_nsvr)
            _parm_list.append("ipv6.method", "auto")
            _parm_list.append("ipv6.addr-gen-mode", "default")
        # --- uuid ------------------------------------------------------------
        _conf_uuid: str = ""
        if not _data.tget_chrt:
            if is_service_active(_srvc_name):
                _result = run_subprocess(
                    [
                        "nmcli",
                        "--terse",
                        "--fields",
                        "DEVICE,UUID,NAME",
                        "connection",
                        "show",
                    ]
                )
                _uuid_list: list[str] = list(
                    _result.stdout.splitlines() if _result.returncode == 0 else ""
                )
                _conf_uuid: str = str(s for s in _uuid_list if _data.nics_name in s)
        # --- output ----------------------------------------------------------
        if _conf_uuid:
            _result = run_subprocess(
                ["nmcli", "connection", "modify", "uuid", _conf_uuid, *_parm_list]
            )
            if _result.returncode != 0:
                message_alert(
                    _caller,
                    f"{'failed':<10}:nmcli connection modify uuid {_conf_uuid} {' '.join(_parm_list)}",  # noqa: E501
                    omit=True,
                )
            _writ_text: str = str(
                _result.stdout.splitlines() if _result.returncode == 0 else ""
            )
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
            shutil.chown(path=_conf_path, user="root", group="root")
            os.chmod(_conf_path, 0o600)
        else:
            _result = run_subprocess(
                ["nmcli", "--offline", "connection", "add", *_parm_list]
            )
            if _result.returncode != 0:
                message_alert(
                    _caller,
                    f"{'failed':<10}:nmcli --offline connection add {' '.join(_parm_list)}",  # noqa: E501
                    omit=True,
                )
            _writ_text: str = str(
                _result.stdout.splitlines() if _result.returncode == 0 else ""
            )
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    # --- dns.conf ------------------------------------------------------------
    _conf_path: Path = Path(f"{_nman_path}/conf.d/dns.conf")
    file_backup(info_syst=info_syst, orig_path=_conf_path)
    file_origin(info_syst=info_syst, orig_path=_conf_path)
    if shutil.which("resolvectl"):
        _writ_text: str = "[main]\ndns=systemd-resolved\n"
    elif shutil.which("dnsmasq"):
        _writ_text: str = "[main]\ndns=dnsmasq\n"
    fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
    file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    # --- mdns.conf -----------------------------------------------------------
    _conf_path: Path = Path(f"{_nman_path}/conf.d/mdns.conf")
    file_backup(info_syst=info_syst, orig_path=_conf_path)
    file_origin(info_syst=info_syst, orig_path=_conf_path)
    if shutil.which("resolvectl"):
        _writ_text: str = "[connection]\nconnection.mdns=2\n"
        fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    # --- service restart -----------------------------------------------------
    if not info_syst.data.tget_chrt:
        _svex_name: str = "systemd-networkd.service"
        _result = run_subprocess(["systemctl", "--quiet", "is-enabled", _svex_name])
        if _result.returncode == 0:
            message_info(_caller, f"{'mask':<10}:{_svex_name}", omit=True)
            _result = run_subprocess(["systemctl", "--quiet", "mask", _svex_name])
            _result = run_subprocess(
                ["systemctl", "--quiet", "mask", f"{Path(_svex_name).stem}.socket"]
            )
        if restart_user_service(srvc_name=_srvc_name):
            _comd_list: list[str] = ["nmcli", "connection", "reload"]
            _result = run_subprocess(_comd_list)
            if _result.returncode == 0:
                message_info(
                    _caller, f"{'success':<10}:{' '.join(_comd_list)}", omit=True
                )
            else:
                message_alert(
                    _caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True
                )
