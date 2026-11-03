# --- python library ----------------------------------------------------------
import ipaddress
import re
from dataclasses import dataclass, fields
from ipaddress import IPv4Interface, IPv6Interface
from pathlib import Path
from typing import Any

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    message_alert,
    message_info,
    message_warn,
    run_subprocess_stdout,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@dataclass
class IpAddressData:
    auto: str | None = None  # dhcp
    addr: str | None = None  # address
    prfx: str | None = None  # prefix len
    cidr: str | None = None  # cidr
    mask: str | None = None  # netmask
    fadr: str | None = None  # full addr
    uadr: str | None = None  # addr up
    ladr: str | None = None  # addr low
    radr: str | None = None  # reverse


@dataclass
class NetworkIFData:
    path: Path | None = None  # path (/sys/devices/**/net/{name})
    name: str | None = None  # nic if name
    madr: str | None = None  # "   if mac
    gway: str | None = None  # "   gateway
    nsvr: str | None = None  # "   nameserver
    fqdn: str | None = None  # hostname fqdn
    host: str | None = None  # hostname
    wgrp: str | None = None  # domain
    stat: str | None = None  # nic if status
    ipv4 = IpAddressData()
    ipv6 = IpAddressData()
    link = IpAddressData()


class InfoNetworkIF:
    @debug_logger
    def __init__(self, nic_name: str) -> None:
        _caller = get_caller_name()
        if not nic_name:
            message_alert(
                _caller, f"{'alert':<10}:no nic name ({nic_name}) ", omit=True
            )
            return None
        message_info(_caller, f"{'info':<10}:nic name:{nic_name} ", omit=True)
        self._valid_fields: set[str] = {f.name for f in fields(NetworkIFData)}
        self.data = NetworkIFData()
        # --- nic information -------------------------------------------------
        message_info(_caller, f"{'info':<10}:nic information", omit=True)
        self.data.name = nic_name
        _base_path: Path = Path("/sys/devices")
        self.data.path = next(_base_path.rglob(f"**/net/{self.data.name}"), None)
        if self.data.path and not self.data.path.exists():
            message_warn(_caller, f"{'not found':<10}:{self.data.path}", omit=True)
        # --- status ----------------------------------------------------------
        message_info(_caller, f"{'info':<10}:status", omit=True)
        self.data.stat = "down"
        if self.data.path:
            _path: Path = self.data.path / "operstate"
            if _path and not _path.exists():
                message_warn(_caller, f"{'not found':<10}:{_path}", omit=True)
            else:
                self.data.stat = (
                    _path.read_text().strip("\n").lower() if _path.exists() else None
                )
        # --- hostname --------------------------------------------------------
        message_info(_caller, f"{'info':<10}:hostname", omit=True)
        _comd_list: list[str] = ["hostnamectl", "hostname"]
        _result = run_subprocess_stdout(_comd_list)
        if not _result:
            message_warn(_caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True)
        else:
            _host_list: list[str] = _result.strip("\n").split(".")
            self.data.host = _host_list[0]
            self.data.wgrp = ".".join(_host_list[1:])
            self.data.fqdn = f"{self.data.host}.{self.data.wgrp}"
        # --- gateway ---------------------------------------------------------
        message_info(_caller, f"{'info':<10}:gateway", omit=True)
        _comd_list: list[str] = ["ip", "route", "show", "dev", self.data.name]
        _result = run_subprocess_stdout(_comd_list)
        if not _result:
            message_warn(_caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True)
        else:
            _match = re.search(r"default\s+via\s+([0-9.]+)", _result)
            self.data.gway = _match.group(1) if _match else ""
        # --- nameserver ------------------------------------------------------
        message_info(_caller, f"{'info':<10}:nameserver", omit=True)
        _comd_list: list[str] = ["resolvectl", "status", self.data.name]
        _result = run_subprocess_stdout(_comd_list)
        if not _result:
            _comd_list: list[str] = ["systemd-resolve", "--status", self.data.name]
            _result = run_subprocess_stdout(_comd_list)
        if not _result:
            message_warn(_caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True)
        else:
            _match = re.search(r"DNS\s+Servers:\s+([0-9a-fA-F:\s.]+)\n", _result)
            if _match:
                _find: list[Any] = re.findall(r"([^\s]+)", _match.group(1))
                self.data.nsvr = _find if _find else ""
        # --- get ip address --------------------------------------------------
        message_info(_caller, f"{'info':<10}:get ip address", omit=True)
        _comd_list: list[str] = ["ip", "address", "show", "dev", self.data.name]
        _result = run_subprocess_stdout(_comd_list)
        if not _result:
            message_warn(_caller, f"{'failed':<10}:{' '.join(_comd_list)}", omit=True)
        else:
            message_info(_caller, f"{'info':<10}:parse an mac address", omit=True)
            # --- parse an mac address ----------------------------------------
            _match = re.search(r"link/ether\s+([0-9a-fA-F:]+)", _result)
            self.data.madr = _match.group(1).lower() if _match else "00:00:00:00:00:00"
            # --- parse an ipv4 address ---------------------------------------
            message_info(_caller, f"{'info':<10}:parse an ipv4 address", omit=True)
            _match = re.search(r"inet\s+([0-9.]+)/(\d+)\s+.+", _result)
            if _match:
                self.data.ipv4.auto = str("dynamic" in _match.group(0))
                self.data.ipv4.ipv4 = _match.group(1)
                self.data.ipv4.prfx = _match.group(2)
                self.data.ipv4.cidr = f"{self.data.ipv4.ipv4}/{self.data.ipv4.prfx}"
                self.data.ipv4.mask = ipv4_mask(cidr=self.data.ipv4.cidr)
                self.data.ipv4.uadr = ipv4_upper(addr=self.data.ipv4.ipv4)
                self.data.ipv4.ladr = ipv4_lower(addr=self.data.ipv4.ipv4)
                self.data.ipv4.radr = ipv4_reverse(addr=self.data.ipv4.ipv4)
            # --- parse an ipv6 address ---------------------------------------
            message_info(_caller, f"{'info':<10}:parse an ipv6 address", omit=True)
            _match = re.search(
                r"inet6\s+([0-9a-fA-F:]+)/(\d+)\s+scope\s+global\s.+", _result
            )
            if _match:
                self.data.ipv6.auto = str("dynamic" in _match.group(0))
                self.data.ipv6.addr = _match.group(1)
                self.data.ipv6.prfx = _match.group(2)
                self.data.ipv6.cidr = f"{self.data.ipv6.addr}/{self.data.ipv6.prfx}"
                self.data.ipv6.mask = ipv6_mask(cidr=self.data.ipv6.cidr)
                self.data.ipv6.fadr = ipv6_full(addr=self.data.ipv6.addr)
                self.data.ipv6.uadr = ipv6_upper(addr=self.data.ipv6.addr)
                self.data.ipv6.ladr = ipv6_lower(addr=self.data.ipv6.addr)
                self.data.ipv6.radr = ipv6_reverse(addr=self.data.ipv6.addr)
            # --- parse an link local address ---------------------------------------
            message_info(_caller, f"{'info':<10}:parse an link address", omit=True)
            _match = re.search(
                r"inet6\s+([0-9a-fA-F:]+)/(\d+)\s+scope\s+link\s.+", _result
            )
            if _match:
                self.data.link.auto = str("dynamic" in _match.group(0))
                self.data.link.addr = _match.group(1)
                self.data.link.prfx = _match.group(2)
                self.data.link.cidr = f"{self.data.link.addr}/{self.data.link.prfx}"
                self.data.link.mask = ipv6_mask(cidr=self.data.link.cidr)
                self.data.link.fadr = ipv6_full(addr=self.data.link.addr)
                self.data.link.uadr = ipv6_upper(addr=self.data.link.addr)
                self.data.link.ladr = ipv6_lower(addr=self.data.link.addr)
                self.data.link.radr = ipv6_reverse(addr=self.data.link.addr)


@debug_logger
def find_nic(base_path: Path = Path("/sys/devices")) -> str | None:
    for _find_path in base_path.rglob("**/net/*"):
        _file_path = _find_path / "operstate"
        _nics_stat = _file_path.read_text().strip().lower()
        if _nics_stat != "up":
            continue
        _uper_path = next(_find_path.glob("upper_*"), None)
        if _uper_path:
            continue
        return _find_path.name
    return None


@debug_logger
def ipv4_addr(cidr: str) -> str:
    if not cidr:
        return None
    _caller = get_caller_name()
    try:
        _interface = IPv4Interface(cidr)
        return str(_interface.ip)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def ipv4_mask(cidr: str) -> str:
    if not cidr:
        return None
    _caller = get_caller_name()
    try:
        _interface = IPv4Interface(cidr)
        return str(_interface.netmask)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def ipv4_prfx(cidr: str) -> str:
    if not cidr:
        return None
    _caller = get_caller_name()
    try:
        _interface = IPv4Interface(cidr)
        return str(_interface.network.prefixlen)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def ipv4_reverse(addr: str) -> str:
    if not addr:
        return None
    _caller = get_caller_name()
    try:
        _ipv4_objs = ipaddress.ip_address(addr)
        return _ipv4_objs.reverse_pointer
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def ipv4_upper(addr: str) -> str:
    if not addr:
        return None
    return ".".join(addr.split(".")[:3])


@debug_logger
def ipv4_lower(addr: str) -> str:
    if not addr:
        return None
    return ".".join(addr.split(".")[3:])


@debug_logger
def ipv6_mask(cidr) -> str:
    if not cidr:
        return None
    _caller = get_caller_name()
    try:
        _interface = IPv6Interface(cidr)
        return str(_interface.netmask)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def ipv6_reverse(addr: str) -> str:
    if not addr:
        return None
    _caller = get_caller_name()
    try:
        _ipv6_objs = ipaddress.IPv6Address(addr)
        return _ipv6_objs.reverse_pointer
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def ipv6_upper(addr: str, omit: bool = True) -> str:
    if not addr:
        return None
    return ipv6_full(addr)[:19]


@debug_logger
def ipv6_lower(addr: str, omit: bool = True) -> str:
    if not addr:
        return None
    return ipv6_full(addr)[20:]


@debug_logger
def ipv6_full(addr: str) -> str:
    if not addr:
        return None
    _caller = get_caller_name()
    try:
        _ipv6_objs = ipaddress.IPv6Address(addr)
        return _ipv6_objs.exploded
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def ipv6_omit(addr: str) -> str:
    if not addr:
        return None
    _caller = get_caller_name()
    try:
        _ipv6_objs = ipaddress.IPv6Address(addr)
        return _ipv6_objs.compressed
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
