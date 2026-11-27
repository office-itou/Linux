# --- python library ----------------------------------------------------------
import ipaddress
import json
import os
import re
import shutil
from dataclasses import dataclass, field, fields
from ipaddress import IPv4Interface, IPv6Interface
from pathlib import Path
from subprocess import CompletedProcess
from typing import Any

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    message_alert,
    message_info,
    message_warn,
    run_subprocess,
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
    ipv4: IpAddressData = field(default_factory=IpAddressData)
    ipv6: IpAddressData = field(default_factory=IpAddressData)
    link: IpAddressData = field(default_factory=IpAddressData)


class InfoNetworkIF:
    @debug_logger
    def __init__(self, nic_name: str) -> None:
        self._valid_fields: set[str] = {f.name for f in fields(NetworkIFData)}
        self.data = NetworkIFData()
        _caller = get_caller_name()
        if not nic_name:
            message_alert(
                _caller, f"{'alert':<10}:no nic name ({nic_name}) ", omit=True
            )
            return None
        message_info(_caller, f"{'info':<10}:nic name:{nic_name}", omit=True)
        self.data.name = nic_name
        self.get_nic_information()
        self.get_status()
        self.get_hostname()
        self.get_gateway()
        self.get_nameserver()
        self.get_ip_address()

    # --- nic information -----------------------------------------------------
    def get_nic_information(self) -> None:
        _caller = get_caller_name()
        message_info(
            _caller, f"{'info':<10}:{self.data.name}:nic information", omit=True
        )
        # _base_path: Path = Path("/sys/devices")
        # self.data.path = next(_base_path.rglob(f"**/net/{self.data.name}"), None)
        self.data.path = Path(f"/sys/class/net/{self.data.name}").resolve()
        if self.data.path and not self.data.path.exists():
            message_warn(_caller, f"{'not found':<10}:{self.data.path}", omit=True)

    # --- status --------------------------------------------------------------
    def get_status(self) -> None:
        _caller = get_caller_name()
        message_info(_caller, f"{'info':<10}:{self.data.name}:status", omit=True)
        self.data.stat = "down"
        if self.data.path:
            _path: Path = self.data.path / "operstate"
            if _path and not _path.exists():
                message_warn(_caller, f"{'not found':<10}:{_path}", omit=True)
            else:
                self.data.stat = (
                    _path.read_text().strip("\n").lower() if _path.exists() else None
                )

    # --- hostname ------------------------------------------------------------
    def get_hostname(self) -> None:
        _caller = get_caller_name()
        message_info(_caller, f"{'info':<10}:{self.data.name}:hostname", omit=True)
        _shel_comd: str = ""
        _host_name: str = ""
        if shutil.which("hostnamectl"):
            _shel_comd: str = r"hostnamectl hostname"
        elif shutil.which("hostname"):
            _shel_comd: str = r"hostname -f"
        if _shel_comd:
            _result: CompletedProcess = run_subprocess(_shel_comd)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
            elif _result.stdout:
                _host_name: str = _result.stdout
        if not _host_name:
            _conf_path: Path = Path("/etc/hostname")
            if _conf_path.exists():
                _host_name: str = _conf_path.read_text()
        if _host_name:
            _host_list: list[str] = _host_name.strip("\n").split(".")
            self.data.host = _host_list[0]
            self.data.wgrp = ".".join(_host_list[1:])
            self.data.fqdn = (
                f"{self.data.host}.{self.data.wgrp}"
                if self.data.wgrp
                else self.data.host
            )

    # --- gateway -------------------------------------------------------------
    def get_gateway(self) -> None:
        _caller = get_caller_name()
        message_info(_caller, f"{'info':<10}:{self.data.name}:gateway", omit=True)
        _envs_list: dict[str, str] = os.environ.copy()
        _envs_list["_NICS_NAME"] = str(self.data.name)
        _shel_comd: str = r'/sbin/ip -j route show dev "${_NICS_NAME:?}"'
        _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
        if _result.returncode != 0 and _result.stderr:
            _shel_comd: str = r'/sbin/ip route show dev "${_NICS_NAME:?}"'
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
            elif _result.stdout:
                _match = re.search(r"default\s+via\s+([0-9.]+)", _result.stdout)
                self.data.gway = _match.group(1) if _match else ""
        elif _result.stdout:
            _retn_list: list[dict] = json.loads(_result.stdout)
            for _retn_line in _retn_list:
                if "gateway" in _retn_line:
                    self.data.gway = _retn_line.get("gateway", None)
                    break

    # --- nameserver ----------------------------------------------------------
    def get_nameserver(self) -> None:
        _caller = get_caller_name()
        message_info(_caller, f"{'info':<10}:{self.data.name}:nameserver", omit=True)
        _shel_comd: str = ""
        if shutil.which("resolvectl"):
            _shel_comd: str = r'resolvectl status "${_NICS_NAME:?}"'
        elif shutil.which("systemd-resolve"):
            _shel_comd: str = r'systemd-resolve --status "${_NICS_NAME:?}"'
        if _shel_comd:
            _envs_list: dict[str, str] = os.environ.copy()
            _envs_list["_NICS_NAME"] = str(self.data.name)
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
            elif _result.stdout:
                _match = re.search(
                    r"DNS\s+Servers:\s+([0-9a-fA-F:\s.]+)\n", _result.stdout
                )
                if _match:
                    _find: list[Any] = re.findall(r"([^\s]+)", _match.group(1))
                    self.data.nsvr = ",".join(_find) if _find else ""

    # --- get ip address ------------------------------------------------------
    def get_ip_address(self) -> None:
        _caller = get_caller_name()
        message_info(
            _caller, f"{'info':<10}:{self.data.name}:get ip address", omit=True
        )

        def _get_ip_address_plain(self, env: dict[str, str]) -> None:
            message_info(
                _caller, f"{'info':<10}:{self.data.name}:get ip address", omit=True
            )
            env["_NICS_NAME"] = str(self.data.name)
            _shel_comd: str = r'/sbin/ip address show dev "${_NICS_NAME:?}"'
            _result: CompletedProcess = run_subprocess(_shel_comd, env=env)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
            elif _result.stdout:
                # --- parse an mac address ------------------------------------
                message_info(
                    _caller,
                    f"{'info':<10}:{self.data.name}:parse an mac address",
                    omit=True,
                )
                _match = re.search(r"link/ether\s+([0-9a-fA-F:]+)", _result.stdout)
                self.data.madr = (
                    _match.group(1).lower() if _match else "00:00:00:00:00:00"
                )
                # --- parse an ipv4 address -----------------------------------
                message_info(
                    _caller,
                    f"{'info':<10}:{self.data.name}:parse an ipv4 address",
                    omit=True,
                )
                _match = re.search(r"inet\s+([0-9.]+)/(\d+)\s+.+", _result.stdout)
                if _match:
                    self.data.ipv4.auto = "dhcp" if "dynamic" in _match.group(0) else ""
                    self.data.ipv4.addr = _match.group(1)
                    self.data.ipv4.prfx = _match.group(2)
                    self.data.ipv4.cidr = f"{self.data.ipv4.addr}/{self.data.ipv4.prfx}"
                    self.data.ipv4.mask = ipv4_mask(cidr=self.data.ipv4.cidr)
                    self.data.ipv4.uadr = ipv4_upper(addr=self.data.ipv4.addr)
                    self.data.ipv4.ladr = ipv4_lower(addr=self.data.ipv4.addr)
                    self.data.ipv4.radr = ipv4_reverse(addr=self.data.ipv4.addr)
                # --- parse an ipv6 address -----------------------------------
                message_info(
                    _caller,
                    f"{'info':<10}:{self.data.name}:parse an ipv6 address",
                    omit=True,
                )
                _match = re.search(
                    r"inet6\s+([0-9a-fA-F:]+)/(\d+)\s+scope\s+global\s.+",
                    _result.stdout,
                )
                if _match:
                    self.data.ipv6.auto = (
                        "True" if "dynamic" in _match.group(0) else "False"
                    )
                    self.data.ipv6.addr = _match.group(1)
                    self.data.ipv6.prfx = _match.group(2)
                    self.data.ipv6.cidr = f"{self.data.ipv6.addr}/{self.data.ipv6.prfx}"
                    self.data.ipv6.mask = ipv6_mask(cidr=self.data.ipv6.cidr)
                    self.data.ipv6.fadr = ipv6_full(addr=self.data.ipv6.addr)
                    self.data.ipv6.uadr = ipv6_upper(addr=self.data.ipv6.addr)
                    self.data.ipv6.ladr = ipv6_lower(addr=self.data.ipv6.addr)
                    self.data.ipv6.radr = ipv6_reverse(addr=self.data.ipv6.addr)
                # --- parse an link local address -----------------------------
                message_info(
                    _caller,
                    f"{'info':<10}:{self.data.name}:parse an link address",
                    omit=True,
                )
                _match = re.search(
                    r"inet6\s+([0-9a-fA-F:]+)/(\d+)\s+scope\s+link\s.+", _result.stdout
                )
                if _match:
                    self.data.link.auto = "dhco" if "dynamic" in _match.group(0) else ""
                    self.data.link.addr = _match.group(1)
                    self.data.link.prfx = _match.group(2)
                    self.data.link.cidr = f"{self.data.link.addr}/{self.data.link.prfx}"
                    self.data.link.mask = ipv6_mask(cidr=self.data.link.cidr)
                    self.data.link.fadr = ipv6_full(addr=self.data.link.addr)
                    self.data.link.uadr = ipv6_upper(addr=self.data.link.addr)
                    self.data.link.ladr = ipv6_lower(addr=self.data.link.addr)
                    self.data.link.radr = ipv6_reverse(addr=self.data.link.addr)

        def _get_ip_address_json(self, env: dict[str, str], data: str) -> None:
            message_info(
                _caller,
                f"{'info':<10}:{self.data.name}:get ip address(json)",
                omit=True,
            )
            _retn_list: list[dict] = json.loads(data)
            for _retn_line in _retn_list:
                # --- parse an mac address ------------------------------------
                if "address" in _retn_line:
                    self.data.madr = _retn_line.get("address", "00:00:00:00:00:00")
                # --- parse an ip address -------------------------------------
                if "addr_info" in _retn_line:
                    _addr_infos: list[dict] = _retn_line.get("addr_info", [])
                    for _addr_info in _addr_infos:
                        _inet_fmly: list[str] = _addr_info.get("family", None)
                        _scpe_type: list[str] = _addr_info.get("scope", None)
                        match _inet_fmly:
                            case "inet":  # parse an ipv4 address
                                _get_ip_address_json_ipv4(self, data=_addr_info)
                            case "inet6":  # parse an ipv6 address
                                match _scpe_type:
                                    case "global":  # parse an ipv6 address(global)
                                        if _addr_info.get("temporary", False):
                                            _get_ip_address_json_ipv6(
                                                self, data=_addr_info
                                            )
                                    case "link":  # parse an ipv6 address(link local)
                                        _get_ip_address_json_link(self, data=_addr_info)
                    break

        def _get_ip_address_json_ipv4(self, data: dict) -> None:
            self.data.ipv4.auto = "dhcp" if data.get("dynamic", False) else ""
            self.data.ipv4.addr = data.get("local", "0.0.0.0")
            self.data.ipv4.prfx = data.get("prefixlen", "24")
            self.data.ipv4.cidr = f"{self.data.ipv4.addr}/{self.data.ipv4.prfx}"
            self.data.ipv4.mask = ipv4_mask(cidr=self.data.ipv4.cidr)
            self.data.ipv4.uadr = ipv4_upper(addr=self.data.ipv4.addr)
            self.data.ipv4.ladr = ipv4_lower(addr=self.data.ipv4.addr)
            self.data.ipv4.radr = ipv4_reverse(addr=self.data.ipv4.addr)

        def _get_ip_address_json_ipv6(self, data: str) -> None:
            self.data.ipv6.auto = str("dhcp" if data.get("dynamic", False) else "")
            self.data.ipv6.addr = data.get("local", "::0")
            self.data.ipv6.prfx = data.get("prefixlen", "64")
            self.data.ipv6.cidr = f"{self.data.ipv6.addr}/{self.data.ipv6.prfx}"
            self.data.ipv6.mask = ipv6_mask(cidr=self.data.ipv6.cidr)
            self.data.ipv6.fadr = ipv6_full(addr=self.data.ipv6.addr)
            self.data.ipv6.uadr = ipv6_upper(addr=self.data.ipv6.addr)
            self.data.ipv6.ladr = ipv6_lower(addr=self.data.ipv6.addr)
            self.data.ipv6.radr = ipv6_reverse(addr=self.data.ipv6.addr)

        def _get_ip_address_json_link(self, data: str) -> None:
            self.data.link.auto = str("dhcp" if data.get("dynamic", False) else "")
            self.data.link.addr = data.get("local", "::0")
            self.data.link.prfx = data.get("prefixlen", "64")
            self.data.link.cidr = f"{self.data.link.addr}/{self.data.link.prfx}"
            self.data.link.mask = ipv6_mask(cidr=self.data.link.cidr)
            self.data.link.fadr = ipv6_full(addr=self.data.link.addr)
            self.data.link.uadr = ipv6_upper(addr=self.data.link.addr)
            self.data.link.ladr = ipv6_lower(addr=self.data.link.addr)
            self.data.link.radr = ipv6_reverse(addr=self.data.link.addr)

        _envs_list: dict[str, str] = os.environ.copy()
        _envs_list["_NICS_NAME"] = str(self.data.name)
        _shel_comd: str = r'/sbin/ip -j address show dev "${_NICS_NAME:?}"'
        _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
        if _result.returncode != 0 and _result.stderr:
            _get_ip_address_plain(self, env=_envs_list)
        elif _result.stdout:
            _get_ip_address_json(self, env=_envs_list, data=str(_result.stdout))


@debug_logger
#def find_nic(base_path: Path = Path("/sys/devices")) -> str | None:
#    for _find_path in base_path.rglob("**/net/*"):
def find_nic(base_path: Path = Path("/sys/class/net")) -> str | None:
    for _find_path in base_path.glob("*"):
        _real_path = _find_path.resolve()
        _file_path = _real_path / "operstate"
        _nics_stat = _file_path.read_text().strip().lower()
        if _nics_stat != "up":
            continue
        _uper_path = next(_real_path.glob("upper_*"), None)
        if _uper_path:
            continue
        _envs_list: dict[str, str] = os.environ.copy()
        _envs_list["_NICS_NAME"] = str(_real_path.name)
        _shel_comd: str = r'/sbin/ip -oneline address show dev "${_NICS_NAME:?}"'
        _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
        if _result.returncode != 0 and _result.stderr:
            print(_result.stderr)
        elif _result.stdout:
            return _real_path.name
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
