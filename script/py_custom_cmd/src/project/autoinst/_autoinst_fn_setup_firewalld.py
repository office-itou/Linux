# --- python library ----------------------------------------------------------
import os
import re
import shutil
from ipaddress import IPv4Interface, IPv6Interface
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    file_backup,
    file_origin,
    find_serivce,
    fread,
    fwrite,
    get_caller_name,
    is_service_active,
    message_alert,
    message_info,
    run_subprocess,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def setup_firewalld(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check command -------------------------------------------------------
    if not shutil.which("firewall-cmd"):
        return
    # --- check service -------------------------------------------------------
    _srvc_name: str = "firewalld.service"
    _srvc_path: Path = find_serivce(tget_path=_tget_path, srvc_name=_srvc_name)
    if not _srvc_path or not _srvc_path.exists():
        return
    file_backup(info_syst=info_syst, orig_path=_srvc_path)
    file_origin(info_syst=info_syst, orig_path=_srvc_path)
    _st_pattern = re.compile(r"^\[Unit\]$")
    _en_pattern = re.compile(r"^\[.*\]$")
    _it_pattern = re.compile(r"^(Before|Wants)=network-pre.target$")
    _in_packages_section: bool = False
    _pack_list: list[str] = []
    _read_text: str = fread(src_path=_srvc_path, text=True)
    for _line in _read_text.splitlines():
        _line_str = _line.strip()
        if _st_pattern.match(_line_str):
            _in_packages_section = True
        elif _in_packages_section:
            if _en_pattern.match(_line_str):
                _in_packages_section = False
            if _it_pattern.split(_line_str):
                _line_str = f"#{_line_str}"
        _pack_list.append(_line_str)
    _writ_text = "\n".join(_pack_list)
    fwrite(dest_path=_srvc_path, data=_writ_text, text=True, backup=False)
    file_backup(info_syst=info_syst, orig_path=_srvc_path, mode="init")
    # --- firewalld -----------------------------------------------------------
    _drop_zone: str = "drop.xml"
    _drop_path: Path = None
    for _find_dirs in ["/lib/firewalld/zones", "/usr/lib/firewalld/zones"]:
        _find_path: Path = addpath(
            base=_tget_path, path=Path(f"{_find_dirs}/{_drop_zone}")
        )
        if _find_path.exists():
            _drop_path: Path = _find_path
            break
    _nics_name: str = _data.nics_name
    _fwal_zone: str = _data.fwal_zone
    _fwal_path: Path = addpath(
        base=_tget_path, path=Path(f"/etc/firewalld/zones/{_fwal_zone}.xml")
    )
    file_backup(info_syst=info_syst, orig_path=_srvc_path)
    file_origin(info_syst=info_syst, orig_path=_srvc_path)
    _interface_ipv4 = IPv4Interface(f"{_data.ipv4_uadr}.0/{_data.ipv4_prfx}")
    _interface_ipv6 = IPv6Interface(f"{_data.ipv6_uadr}:0/{_data.ipv6_prfx}")
    _interface_link = IPv6Interface(f"{_data.link_uadr}:0/10")
    _ipv4_rang=_interface_ipv4.network
    _ipv6_rang=_interface_ipv6.network
    _link_rang=_interface_link.network
    if not _data.tget_chrt and is_service_active(_srvc_name):
        message_info(_caller, f"{'active':<10}:{_srvc_name}", omit=True)
        _comd_list:list[str] = ["firewall-cmd", "--quiet", "--permanent", f"--set-default-zone={_fwal_zone}"]
        _result = run_subprocess(_comd_list)
        if _nics_name:
            _comd_list:list[str] = ["firewall-cmd", "--quiet", "--permanent", f"--zone={_fwal_zone}", f"--change-interface={_nics_name}"]
            _result = run_subprocess(_comd_list)



        if _result.returncode == 0:
            message_info(
                _caller, f"{'success':<10}:{' '.join(_comd_list)}", omit=True
            )
        else:
            message_alert(
                _caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True
            )

	if [ -z "${_TGET_CHRT:-}" ] && systemctl --quiet is-active "${__SRVC}"; then
		fnMsgout "${_PROG_NAME:-}" "active" "${__SRVC}"
		firewall-cmd --quiet --permanent --set-default-zone="${_FWAL_ZONE}" || true
		[ -n "${_NICS_NAME##-}" ] && { firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --change-interface="${_NICS_NAME}" || true; }
		for __NAME in ${_FWAL_NAME}
		do
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" service name="'"${__NAME}"'" accept' || true
#			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" service name="'"${__NAME}"'" accept' || true
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" service name="'"${__NAME}"'" accept' || true
		done
		for __PORT in ${_FWAL_PORT}
		do
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
#			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
			firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
		done
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" protocol value="icmp"      accept'
#		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" protocol value="ipv6-icmp" accept'
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" protocol value="ipv6-icmp" accept'
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		firewall-cmd --quiet --permanent --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
		firewall-cmd --quiet --reload
		if [ -n "${_DBGS_FLAG:-}" ]; then
			[ -n "${_NICS_NAME##-}" ] && firewall-cmd --get-zone-of-interface="${_NICS_NAME}"
			firewall-cmd --list-all --zone="${_FWAL_ZONE}"
		fi
	else
		fnMsgout "${_PROG_NAME:-}" "inactive" "${__SRVC}"
		firewall-offline-cmd --quiet --set-default-zone="${_FWAL_ZONE}" || true
		[ -n "${_NICS_NAME##-}" ] && { firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --change-interface="${_NICS_NAME}" || true; }
		for __NAME in ${_FWAL_NAME}
		do
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" service name="'"${__NAME}"'" accept' || true
#			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" service name="'"${__NAME}"'" accept' || true
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" service name="'"${__NAME}"'" accept' || true
		done
		for __PORT in ${_FWAL_PORT}
		do
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
#			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
			firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" port protocol="'"${__PORT##*/}"'" port="'"${__PORT%/*}"'" accept' || true
		done
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${__IPV4}"'" protocol value="icmp"      accept'
#		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__IPV6}"'" protocol value="ipv6-icmp" accept'
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${__LINK}"'" protocol value="ipv6-icmp" accept'
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		firewall-offline-cmd --quiet --zone="${_FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
#		firewall-offline-cmd --quiet --reload
		if [ -n "${_DBGS_FLAG:-}" ]; then
			[ -n "${_NICS_NAME##-}" ] && firewall-offline-cmd --get-zone-of-interface="${_NICS_NAME}"
			firewall-offline-cmd --list-all --zone="${_FWAL_ZONE}"
		fi
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
