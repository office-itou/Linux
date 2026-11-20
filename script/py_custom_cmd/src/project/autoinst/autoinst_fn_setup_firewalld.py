# --- python library ----------------------------------------------------------
import os
import shutil
import subprocess
from ipaddress import IPv4Interface, IPv6Interface
from pathlib import Path
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    fcopy,
    file_backup,
    file_origin,
    find_serivce,
    get_caller_name,
    handle_fatal_error,
    is_service_active,
    message_info,
    restart_service,
    run_subprocess,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def setup_firewalld_active(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    # --- check command -------------------------------------------------------
    if not shutil.which("firewall-cmd"):
        message_info(_caller, f"{'skip':<10}:firewalld", omit=True)
        return
    # --- firewalld -----------------------------------------------------------
    _nics_name: str = _data.nics_name
    _fwal_zone: str = _data.fwal_zone
    _interface_ipv4 = IPv4Interface(f"{_data.ipv4_uadr}.0/{_data.ipv4_prfx}")
    _interface_ipv6 = IPv6Interface(f"{_data.ipv6_uadr}:0/{_data.ipv6_prfx}")
    _interface_link = IPv6Interface(f"{_data.link_uadr}:0/10")
    _ipv4_rang = _interface_ipv4.network
    _ipv6_rang = _interface_ipv6.network
    _link_rang = _interface_link.network
    # --- set default zone ----------------------------------------------------
    _shel_comd = rf"firewall-cmd --quiet --permanent --set-default-zone={_fwal_zone}"
    _result: CompletedProcess = subprocess.run(
        _shel_comd, shell=True, executable="/bin/bash"
    )
    if _result.returncode != 0:
        print(_result.stderr)
    # --- change interface ----------------------------------------------------
    if _nics_name:
        _shel_comd = rf'''
            firewall-cmd --quiet --permanent --zone="{_fwal_zone}"
            --change-interface="{_nics_name}"
        '''
        _result: CompletedProcess = subprocess.run(
            _shel_comd, shell=True, executable="/bin/bash"
        )
        if _result.returncode != 0:
            print(_result.stderr)
    # --- set firewall rule ---------------------------------------------------
    for _addr in [
        {"group": "ipv4", "range": _ipv4_rang},
        {"group": "ipv6", "range": _link_rang},
    ]:
        # --- service ---------------------------------------------------------
        for _name in _data.fwal_name:
            _shel_comd = rf'''
                firewall-cmd --quiet --permanent --zone="{_fwal_zone}"
                --add-rich-rule='rule family="{_addr["group"]}"
                source address="{_addr["range"]}"
                service name="{_name}"
                accept'
            '''
            _result: CompletedProcess = subprocess.run(
                _shel_comd, shell=True, executable="/bin/bash"
            )
            if _result.returncode != 0:
                print(_result.stderr)
        # --- port ------------------------------------------------------------
        for _port in _data.fwal_port:
            _shel_comd = rf'''
                firewall-cmd --quiet --permanent --zone="{_fwal_zone}"
                --add-rich-rule='rule family="{_addr["group"]}"
                source address="{_addr["range"]}"
                port protocol="{_port.split("/")[1]}"
                port="{_port.split("/")[0]}"
                accept'
            '''
            _result: CompletedProcess = subprocess.run(
                _shel_comd, shell=True, executable="/bin/bash"
            )
            if _result.returncode != 0:
                print(_result.stderr)
        # --- icmp ------------------------------------------------------------
        _shel_comd = rf'''
            firewall-cmd --quiet --permanent --zone="{_fwal_zone}"
            --add-rich-rule='rule family="{_addr["group"]}"
            source address="{_addr["range"]}"
            protocol value="icmp"
            accept'
        '''
        _result: CompletedProcess = subprocess.run(
            _shel_comd, shell=True, executable="/bin/bash"
        )
        if _result.returncode != 0:
            print(_result.stderr)
    # --- ipv4: tftp ----------------------------------------------------------
    _shel_comd = rf'''
        firewall-cmd --quiet --permanent --zone="{_fwal_zone}"
        --add-rich-rule='rule family="ipv4"
        source address="0.0.0.0"
        service name="tftp"
        accept'
    '''
    _result: CompletedProcess = subprocess.run(
        _shel_comd, shell=True, executable="/bin/bash"
    )
    if _result.returncode != 0:
        print(_result.stderr)
    # --- ipv4: port ----------------------------------------------------------
    _shel_comd = rf'''
        firewall-cmd --quiet --permanent --zone="{_fwal_zone}"
        --add-rich-rule='rule family="ipv4"
        source address="0.0.0.0"
        port protocol="udp" port="67-68"
        accept'
    '''
    _result: CompletedProcess = subprocess.run(
        _shel_comd, shell=True, executable="/bin/bash"
    )
    if _result.returncode != 0:
        print(_result.stderr)
    # --- reload --------------------------------------------------------------
    _result = run_subprocess(["firewall-cmd", "--quiet", "--reload"])
    _shel_comd = r"firewall-cmd --quiet --reload"
    _result: CompletedProcess = subprocess.run(
        _shel_comd, shell=True, executable="/bin/bash"
    )
    if _result.returncode != 0:
        print(_result.stderr)


@debug_logger
def setup_firewalld_inactive(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    # --- check command -------------------------------------------------------
    if not shutil.which("firewall-offline-cmd"):
        message_info(_caller, f"{'skip':<10}:firewalld", omit=True)
        return
    # --- firewalld -----------------------------------------------------------
    _nics_name: str = _data.nics_name
    _fwal_zone: str = _data.fwal_zone
    _interface_ipv4 = IPv4Interface(f"{_data.ipv4_uadr}.0/{_data.ipv4_prfx}")
    _interface_ipv6 = IPv6Interface(f"{_data.ipv6_uadr}:0/{_data.ipv6_prfx}")
    _interface_link = IPv6Interface(f"{_data.link_uadr}:0/10")
    _ipv4_rang = _interface_ipv4.network
    _ipv6_rang = _interface_ipv6.network
    _link_rang = _interface_link.network
    # --- set default zone ----------------------------------------------------
    _shel_comd = rf"firewall-offline-cmd --quiet --set-default-zone={_fwal_zone}"
    _result: CompletedProcess = subprocess.run(
        _shel_comd, shell=True, executable="/bin/bash"
    )
    if _result.returncode != 0:
        print(_result.stderr)
    # --- change interface ----------------------------------------------------
    if _nics_name:
        _shel_comd = rf'''
            firewall-offline-cmd --quiet --zone="{_fwal_zone}"
            --change-interface="{_nics_name}"
        '''
        _result: CompletedProcess = subprocess.run(
            _shel_comd, shell=True, executable="/bin/bash"
        )
        if _result.returncode != 0:
            print(_result.stderr)
    # --- set firewall rule ---------------------------------------------------
    for _addr in [
        {"group": "ipv4", "range": _ipv4_rang},
        {"group": "ipv6", "range": _link_rang},
    ]:
        # --- service ---------------------------------------------------------
        for _name in _data.fwal_name:
            _shel_comd = rf'''
                firewall-offline-cmd --quiet --zone="{_fwal_zone}"
                --add-rich-rule='rule family="{_addr["group"]}"
                source address="{_addr["range"]}"
                service name="{_name}"
                accept'
            '''
            _result: CompletedProcess = subprocess.run(
                _shel_comd, shell=True, executable="/bin/bash"
            )
            if _result.returncode != 0:
                print(_result.stderr)
        # --- port ------------------------------------------------------------
        for _port in _data.fwal_port:
            _shel_comd = rf'''
                firewall-offline-cmd --quiet --zone="{_fwal_zone}"
                --add-rich-rule='rule family="{_addr["group"]}"
                source address="{_addr["range"]}"
                port protocol="{_port.split("/")[1]}"
                port="{_port.split("/")[0]}"
                accept'
            '''
            _result: CompletedProcess = subprocess.run(
                _shel_comd, shell=True, executable="/bin/bash"
            )
            if _result.returncode != 0:
                print(_result.stderr)
        # --- icmp ------------------------------------------------------------
        _shel_comd = rf'''
            firewall-offline-cmd --quiet --zone="{_fwal_zone}"
            --add-rich-rule='rule family="{_addr["group"]}"
            source address="{_addr["range"]}"
            protocol value="icmp"
            accept'
        '''
        _result: CompletedProcess = subprocess.run(
            _shel_comd, shell=True, executable="/bin/bash"
        )
        if _result.returncode != 0:
            print(_result.stderr)
    # --- ipv4: tftp ----------------------------------------------------------
    _shel_comd = rf'''
        firewall-offline-cmd --quiet --zone="{_fwal_zone}"
        --add-rich-rule='rule family="ipv4"
        source address="0.0.0.0"
        service name="tftp"
        accept'
    '''
    _result: CompletedProcess = subprocess.run(
        _shel_comd, shell=True, executable="/bin/bash"
    )
    if _result.returncode != 0:
        print(_result.stderr)
    # --- ipv4: port ----------------------------------------------------------
    _shel_comd = rf'''
        firewall-offline-cmd --quiet --zone="{_fwal_zone}"
        --add-rich-rule='rule family="ipv4"
        source address="0.0.0.0"
        port protocol="udp" port="67-68"
        accept'
    '''
    _result: CompletedProcess = subprocess.run(
        _shel_comd, shell=True, executable="/bin/bash"
    )
    if _result.returncode != 0:
        print(_result.stderr)
    # --- reload --------------------------------------------------------------


@debug_logger
def setup_firewalld(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check service -------------------------------------------------------
    _srvc_name: str = "firewalld.service"
    _srvc_path: Path = find_serivce(tget_path=_tget_path, srvc_name=_srvc_name)
    if not _srvc_path or not _srvc_path.exists():
        message_info(_caller, f"{'skip':<10}:firewalld:{_srvc_name}", omit=True)
        return
    try:
        message_info(_caller, f"{'setup':<10}:firewalld", omit=True)
        file_backup(info_syst=info_syst, orig_path=_srvc_path)
        file_origin(info_syst=info_syst, orig_path=_srvc_path)
        _envs_list = os.environ.copy()
        _envs_list["_SRVC_PATH"] = str(_srvc_path)
        _shel_comd = r"""
            sed -e '/\[Unit\]/,/\[.*\]/                {' \
                -e '/^Before=network-pre.target$/ s/^/#/' \
                -e '/^Wants=network-pre.target$/  s/^/#/' \
                -e '                                   }' \
                -i "${_SRVC_PATH:?}"
        """
        _result: CompletedProcess = subprocess.run(
            _shel_comd, shell=True, env=_envs_list, executable="/bin/bash"
        )
        if _result.returncode != 0:
            print(_result.stderr)
        file_backup(info_syst=info_syst, orig_path=_srvc_path, mode="init")
        # --- firewalld -------------------------------------------------------
        _drop_zone: str = "drop.xml"
        _drop_path: Path = None
        for _find_dirs in ["/lib/firewalld/zones", "/usr/lib/firewalld/zones"]:
            _find_path: Path = addpath(
                base=_tget_path, path=Path(f"{_find_dirs}/{_drop_zone}")
            )
            if _find_path.exists():
                _drop_path: Path = _find_path
                break
        _fwal_zone: str = _data.fwal_zone
        _fwal_path: Path = addpath(
            base=_tget_path, path=Path(f"/etc/firewalld/zones/{_fwal_zone}.xml")
        )
        if _drop_path.exists():
            fcopy(src_path=_drop_path, dest_path=_fwal_path, backup=False)
            file_backup(info_syst=info_syst, orig_path=_fwal_path)
            file_origin(info_syst=info_syst, orig_path=_fwal_path)
        if not _data.tget_chrt and is_service_active(_srvc_name):
            message_info(_caller, f"{'active':<10}:{_srvc_name}", omit=True)
            setup_firewalld_active(info_syst=info_syst)
            # --- service restart ---------------------------------------------
            if not info_syst.data.tget_chrt:
                restart_service(srvc_name=_srvc_name)
        else:
            message_info(_caller, f"{'inactive':<10}:{_srvc_name}", omit=True)
            setup_firewalld_inactive(info_syst=info_syst)
        file_backup(info_syst=info_syst, orig_path=_fwal_path, mode="init")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
