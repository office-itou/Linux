# --- python library ----------------------------------------------------------
import ipaddress
import re
import subprocess
from ipaddress import IPv4Interface, IPv6Interface
from pathlib import Path
from typing import Any

from natsort import natsorted


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    addpath,
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    message_alert,
    message_info,
    message_warn,
)

# ruff: isort: on
# --- import module -----------------------------------------------------------
# from autoinst_fn_syspara import InfoSystem


# --- class and function ------------------------------------------------------
@debug_logger
def conv_ipv4_reverse(addr: str) -> str:
    if not addr:
        return None
    _caller = get_caller_name()
    try:
        _ipv4_objs = ipaddress.ip_address(addr)
        return _ipv4_objs.reverse_pointer
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def conv_ipv6_reverse(addr: str) -> str:
    if not addr:
        return None
    _caller = get_caller_name()
    try:
        _ipv6_objs = ipaddress.IPv6Address(addr)
        return _ipv6_objs.reverse_pointer
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def conv_ipv6_full(addr: str) -> str:
    if not addr:
        return None
    _caller = get_caller_name()
    try:
        _ipv6_objs = ipaddress.IPv6Address(addr)
        return _ipv6_objs.exploded
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def conv_ipv6_omit(addr: str) -> str:
    if not addr:
        return None
    _caller = get_caller_name()
    try:
        _ipv6_objs = ipaddress.IPv6Address(addr)
        return _ipv6_objs.compressed
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def network_param(info_syst):
    @debug_logger
    def _run_cmd(cmd: list[str]) -> str:
        try:
            return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL)
        except (subprocess.CalledProcessError, FileNotFoundError):
            return ""

    _caller = get_caller_name()
    try:
        message_info(_caller, f"{'initialize':<10}:network parameter", omit=True)
        _out = info_syst.data
        # --- hostname --------------------------------------------------------
        _hostnamectl_out = _run_cmd(["hostnamectl", "hostname"])
        if _hostnamectl_out:
            _host_list: str = _hostnamectl_out.strip("\n").split(".")
            _out.nics_host = _host_list[0]
            _out.nics_wgrp = ".".join(_host_list[1:])
            _out.nics_fqdn = f"{_out.nics_host}.{_out.nics_wgrp}"
        # --- nic name --------------------------------------------------------
        _tget_path: Path = getattr(_out, "tget_path", None)
        _sdev_path: Path = addpath(base=_tget_path, path=Path("/sys/devices"))
        message_info(_caller, f"{'sdev path':<10}:{_sdev_path}", omit=True)
        if not _sdev_path.exists():
            message_warn(_caller, f"not exist: [{_sdev_path}]", omit=True)
        else:
            _out.nics_name = getattr(info_syst.data, "nics_name", "ens160")
            _nics_list: list[Path] = [
                p
                for p in _sdev_path.rglob(f"**/net/{_out.nics_name}")
                if "/virtual/" not in p.parts and not Path(p / "brport").exists()
            ]
            if not _nics_list:
                _sdev_path: Path = addpath(
                    base=_tget_path, path=Path("/sys/devices/virtual/net")
                )
                _nics_list: list[Path] = [
                    p for p in _sdev_path.glob("*") if "lo" != p.parts
                ]
            if not _nics_list:
                message_alert(
                    _caller, f"{'nic name':<10}:{_out.nics_name} not found", omit=True
                )
            else:
                _nics_sort = natsorted(_nics_list, key=str)
                _nics_path = _nics_sort[0] if _nics_sort else ""
                _nics_find = _nics_path.name if _nics_path else ""
                if _out.nics_name == _nics_find:
                    message_info(
                        _caller, f"{'nic name':<10}:{_out.nics_name}", omit=True
                    )
                else:
                    _out.nics_name = _nics_find
                    message_warn(
                        _caller,
                        f"{'nic name':<10}:{_out.nics_name} (changed)",
                        omit=True,
                    )
                _stat_path = Path(_nics_path) / "operstate"
                _out.nics_stat = "False"
                if _stat_path.exists():
                    _out.nics_stat = str(
                        _stat_path.read_text().strip("\n").lower() == "up"
                    )
                # --- gateway -------------------------------------------------
                message_info(_caller, "ip route show", omit=True)
                _ip_route_out = _run_cmd(["ip", "route", "show", "dev", _out.nics_name])
                message_info(_caller, "parse gateway", omit=True)
                _gway_match = re.search(r"default\s+via\s+([0-9.]+)", _ip_route_out)
                _out.nics_gway = _gway_match.group(1) if _gway_match else ""
                # --- nameserver ----------------------------------------------
                message_info(_caller, "resolvectl status", omit=True)
                _resolve_out = _run_cmd(["resolvectl", "status", _out.nics_name])
                if not _resolve_out:
                    message_info(_caller, "systemd-resolve --status", omit=True)
                    _resolve_out = _run_cmd(
                        ["systemd-resolve", "--status", _out.nics_name]
                    )
                message_info(_caller, "parse name server", omit=True)
                _nics_nsvr = ""
                _rslv_match = re.search(
                    r"DNS\s+Servers:\s+([0-9a-fA-F:\s.]+)\n", _resolve_out
                )
                if _rslv_match:
                    _nsvr_find: list[Any] = re.findall(
                        r"([^\s]+)", _rslv_match.group(1)
                    )
                    _out.nics_nsvr = _nsvr_find if _nsvr_find else ""
                # --- get ip address ------------------------------------------
                message_info(_caller, "ip address show", omit=True)
                _ip_addr_out = _run_cmd(
                    ["ip", "address", "show", "dev", _out.nics_name]
                )
                message_info(_caller, "ip route show", omit=True)
                # --- parse an mac address ------------------------------------
                _mac_match = re.search(r"link/ether\s+([0-9a-fA-F:]+)", _ip_addr_out)
                _out.nics_madr = (
                    _mac_match.group(1).lower() if _mac_match else "00:00:00:00:00:00"
                )
                # --- parse an ipv4 address -----------------------------------
                message_info(_caller, "parse ipv4 address", omit=True)
                _out.nics_auto = ""  # ipv4 dhcp      (ex. empty or dhcp)
                _out.nics_ipv4 = ""  # ipv4 address    (ex. 192.168.1.1)
                _out.nics_prfx = ""  # IPv4 prefix len (ex. 24)
                _out.nics_mask = ""  # ipv4 netmask    (ex. 255.255.255.0)
                _out.nics_cidr = ""  # ipv4 cidr       (ex. 24)
                _out.nics_uadr = ""  # ipv4 addr up    (ex. 192.168.1)
                _out.nics_ladr = ""  # ipv4 addr low   (ex. 1)
                _out.nics_radr = ""  # ipv4 reverse    (ex. 1.1.168.192.in-addr.arpa)
                _ipv4_match = re.search(r"inet\s+([0-9.]+)/(\d+)\s+.+", _ip_addr_out)
                if _ipv4_match:
                    _out.nics_auto = str("dynamic" in _ipv4_match.group(0))
                    _out.nics_ipv4 = _ipv4_match.group(1)
                    _out.nics_prfx = _ipv4_match.group(2)
                    _interface = IPv4Interface(f"0.0.0.0/{_out.ipv4_prfx}")
                    _out.nics_mask = str(_interface.netmask)
                    _out.nics_cidr = f"{_out.nics_ipv4}/{_out.nics_prfx}"
                    _out.nics_uadr = ".".join(_out.nics_ipv4.split(".")[:3])
                    _out.nics_ladr = ".".join(_out.nics_ipv4.split(".")[3:])
                    _out.nics_radr = conv_ipv4_reverse(_out.nics_ipv4)
                # --- parse an ipv6 address -----------------------------------
                message_info(_caller, "parse ipv6 address", omit=True)
                _out.ipv6_auto = ""  # ipv6 dhcp      (ex. empty or dhcp)
                _out.ipv6_addr = ""  # ipv6 address    (ex. ::1)
                _out.ipv6_prfx = ""  # IPv6 prefix len (ex. 64)
                _out.ipv6_mask = ""  # ipv4 netmask    (ex.)
                _out.ipv6_cidr = ""  # IPv6 cidr       (ex. ::1/64)
                _out.ipv6_fadr = ""  # ipv6 full addr  (ex. 0000:0000:....:0001)
                _out.ipv6_uadr = ""  # ipv6 addr up    (ex. 0000:0000:0000:0000)
                _out.ipv6_ladr = ""  # ipv6 addr low   (ex. 0000:0000:0000:0001)
                _out.ipv6_radr = ""  # ipv6 reverse    (ex. ...)
                _ipv6_global_rule = r"inet6\s+([0-9a-fA-F:]+/\d+)\s+scope\s+global\s.+"
                _ipv6_global_list: list[Any] = re.findall(
                    _ipv6_global_rule, _ip_addr_out
                )
                _ipv6_match = re.search(_ipv6_global_rule, _ip_addr_out)
                if _ipv6_match:
                    _ipv6_match_1st = re.search(
                        r"([0-9a-fA-F:]+)/(\d+)",
                        _ipv6_global_list[0] if _ipv6_global_list else "",
                    )
                    _out.ipv6_auto = str("dynamic" in _ipv6_match_1st.group(0))
                    _out.ipv6_addr = _ipv6_match_1st.group(1)
                    _out.ipv6_prfx = _ipv6_match_1st.group(2)
                    _interface = IPv6Interface(f"{_out.ipv6_addr}/{_out.ipv6_prfx}")
                    _out.ipv6_mask = _interface.network.netmask
                    _out.ipv6_cidr = f"{_out.ipv6_addr}/{_out.ipv6_prfx}"
                    _out.ipv6_fadr = conv_ipv6_full(_out.ipv6_addr)
                    _out.ipv6_uadr = _out.ipv6_fadr[:19]
                    _out.ipv6_ladr = _out.ipv6_fadr[20:]
                    _out.ipv6_radr = conv_ipv6_reverse(_out.ipv6_addr)

                # --- parse an link local address -----------------------------
                message_info(_caller, "parse link address", omit=True)
                _out.link_auto = ""  # link dhcp      (ex. empty or dhcp)
                _out.link_addr = ""  # link address    (ex. c::1)
                _out.link_prfx = ""  # IPv6 prefix len (ex. 64)
                _out.link_mask = ""  # ipv4 netmask    (ex.)
                _out.link_cidr = ""  # IPv6 cidr       (ex. link::1/64)
                _out.link_fadr = ""  # link full addr  (ex. fe80:0000:....:0001)
                _out.link_uadr = ""  # link addr up    (ex. fe80:0000:0000:0000)
                _out.link_ladr = ""  # link addr low   (ex. 0000:0000:0000:0001)
                _out.link_radr = ""  # link reverse    (ex. ...)
                _ipv6_link_rule = r"inet6\s+([0-9a-fA-F:]+/\d+)\s+scope\s+link\s.+"
                _ipv6_link_list: list[Any] = re.findall(_ipv6_link_rule, _ip_addr_out)
                _link_match = re.search(_ipv6_link_rule, _ip_addr_out)
                if _link_match:
                    _link_match_1st = re.search(
                        r"([0-9a-fA-F:]+)/(\d+)",
                        _ipv6_link_list[0] if _ipv6_link_list else "",
                    )
                    _out.link_auto = str("dynamic" in _link_match_1st.group(0))
                    _out.link_addr = _link_match_1st.group(1)
                    _out.link_prfx = _link_match_1st.group(2)
                    _interface = IPv6Interface(f"{_out.link_addr}/{_out.link_prfx}")
                    _out.link_mask = _interface.network.netmask
                    _out.link_cidr = f"{_out.link_addr}/{_out.link_prfx}"
                    _out.link_fadr = conv_ipv6_full(_out.link_addr)
                    _out.link_uadr = _out.link_fadr[:19]
                    _out.link_ladr = _out.link_fadr[20:]
                    _out.link_radr = conv_ipv6_reverse(_out.link_addr)
        # ---------------------------------------------------------------------
        message_info(_caller, f"{'complete':<10}:network parameter", omit=True)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return info_syst
