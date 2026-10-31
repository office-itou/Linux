# --- python library ----------------------------------------------------------
import os
import re
from dataclasses import dataclass, field, fields
from datetime import datetime
from ipaddress import IPv4Interface
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    cmdline,
    debug_logger,
    fread,
    get_caller_name,
    infosystem,
    is_chroot,
    is_container,
    is_vm_type,
    message_info,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_common_cfg import InfoConfiguration
from autoinst_fn_info_network import conv_ipv4_reverse


# --- class and function ------------------------------------------------------
@dataclass
class SystemData:
    prog_path: Path = field(
        default_factory=lambda: infosystem.program_path
    )  # program name
    prog_name: str = field(
        default_factory=lambda: infosystem.program_name
    )  # program name
    # --- debug ---------------------------------------------------------------
    dbgs_flag: bool | None = None  # debug flag
    dout_flag: bool | None = None  # debug out flag
    # --- distribution --------------------------------------------------------
    dist_name: str | None = None  # distribution name (ex. debian)
    dist_vers: str | None = None  # version           (ex. testing)
    dist_code: str | None = None  # code name         (ex. testing)
    # --- target machine ------------------------------------------------------
    tget_virt: str | None = None  # virtualization (ex. vmware)
    tget_chrt: str | None = None  # is chgroot     (empty: none, else: chroot)
    tget_cntr: str | None = None  # is container   (empty: none, else: container)
    # --- parameter -----------------------------------------------------------
    parm_root: str | None = None  # environmental variables: root
    parm_secu: str | None = None  # "                      : security
    parm_armo: str | None = None  # "                      : apparmor
    parm_slnx: str | None = None  # "                      : selinux
    # --- directory / file ----------------------------------------------------
    tget_dirs: list[Path] = field(
        default_factory=lambda: [Path("/target"), Path("/mnt/sysimage"), Path("/mnt")]
    )
    tget_path: Path | None = None  # target dir     (ex. /target)
    tget_urls: str | None = None  # target dir     (ex. /target)
    isou_path: Path | None = None  # iso file name
    isou_urls: str | None = None  # iso file name
    # --- samba ---------------------------------------------------------------
    nlin_dirs: list[Path] = field(
        default_factory=lambda: [Path("/usr/sbin/nologin"), Path("/sbin/nologin")]
    )
    nlin_path: Path | None = None
    samb_user: str = "sambauser"  # force user
    samb_grup: str = "sambashare"  # force group
    samb_gadm: str = "sambaadmin"  # admin group
    samb_nssw: list[str] = field(
        default_factory=lambda: [
            "wins",
            "mdns_minimal",
            "mdns4_minimal",
            "[NOTFOUND=return]",
            "resolve",
            "[!UNAVAIL=return]",
            "dns",
            "mdns6",
            "mdns4",
        ]
    )  # nsswitch.conf
    # --- firewalld -----------------------------------------------------------
    fwal_zone: str = "home_use"  # firewalld default zone
    fwal_name: list[str] = field(
        default_factory=lambda: [
            "dhcp",
            "dhcpv6",
            "dhcpv6-client",
            "dns",
            "http",
            "https",
            "mdns",
            "nbd",
            "nfs",
            "proxy-dhcp",
            "samba",
            "samba-client",
            "ssh",
            "tftp",
        ]
    )  # firewalld service name
    fwal_port: list[str] = field(
        default_factory=lambda: ["0-65535/tcp", "0-65535/udp"]
    )  # firewalld port
    # --- preseed -------------------------------------------------------------
    seed_path: Path | None = None  # preseed file name
    seed_urls: str | None = None  # preseed file name
    # --- network: nic (retrieved value) --------------------------------------
    nics_name: str | None = None  # nic if name     (ex. ens160)
    nics_madr: str | None = None  # "   if mac      (ex. 00:00:00:00:00:00)
    nics_gway: str | None = None  # "   gateway     (ex. 192.168.1.254)
    nics_nsvr: str | None = None  # "   nameserver  (ex. 192.168.1.254)
    # --- network: nic (retrieved value) --------------------------------------
    nics_fqdn: str | None = None  # hostname fqdn   (ex. sv-server.workgroup)
    nics_host: str | None = None  # hostname        (ex. sv-server)
    nics_wgrp: str | None = None  # domain          (ex. workgroup)
    nics_stat: str | None = None  # nic if status   (empty: stop, else: active)
    nics_auto: str | None = None  # ipv4 dhcp       (ex. empty or dhcp)
    nics_ipv4: str | None = None  # ipv4 address    (ex. 192.168.1.1)
    nics_prfx: str | None = None  # IPv4 prefix len (ex. 24)
    nics_mask: str | None = None  # ipv4 netmask    (ex. 255.255.255.0)
    nics_cidr: str | None = None  # ipv4 cidr       (ex. 24)
    nics_uadr: str | None = None  # ipv4 addr up    (ex. 192.168.1)
    nics_ladr: str | None = None  # ipv4 addr low   (ex. 1)
    nics_radr: str | None = None  # ipv4 reverse    (ex. 1.1.168.192.in-addr.arpa)
    # --- network parameter ---------------------------------------------------
    nwrk_fqdn: str | None = None  # hostname fqdn   (ex. sv-server.workgroup)
    nwrk_host: str | None = None  # hostname        (ex. sv-server)
    nwrk_wgrp: str | None = None  # domain          (ex. workgroup)
    ipv4_auto: str | None = None  # IPv4 dhcp       (ex. empty or dhcp)
    ipv4_addr: str | None = None  # IPv4 address    (ex. 192.168.1.1)
    ipv4_prfx: str | None = None  # IPv4 prefix len (ex. 24)
    ipv4_cidr: str | None = None  # IPv4 cidr       (ex. 192.168.1.1/24)
    ipv4_mask: str | None = None  # IPv4 subnetmask (ex. 255.255.255.0)
    ipv4_gway: str | None = None  # IPv4 gateway    (ex. 192.168.1.254)
    ipv4_nsvr: str | None = None  # IPv4 nameserver (ex. 192.168.1.254)
    ipv4_uadr: str | None = None  # IPv4 addr up    (ex. 192.168.1)
    ipv4_ladr: str | None = None  # ipv4 addr low   (ex. 1)
    ipv4_radr: str | None = None  # ipv4 reverse    (ex. 1.168.192)
    nman_name: str | None = None  # network manager (ex. nm_config, ifupdown, loopback)
    ntps_addr: str | None = None  # ntp server      (ex. ntp.nict.jp)
    ntps_ipv4: str | None = None  # ntp ipv4 addr   (ex. 61.205.120.130)
    # --- network: ipv6 -------------------------------------------------------
    ipv6_auto: str | None = None  # ipv6 dhcp      (ex. empty or dhcp)
    ipv6_addr: str | None = None  # ipv6 address    (ex. ::1)
    ipv6_prfx: str | None = None  # IPv6 prefix len (ex. 64)
    ipv6_mask: str | None = None  # ipv4 netmask    (ex.)
    ipv6_cidr: str | None = None  # IPv6 cidr       (ex. ::1/64)
    ipv6_fadr: str | None = None  # ipv6 full addr  (ex. 0000:0000:....:0001)
    ipv6_uadr: str | None = None  # ipv6 addr up    (ex. 0000:0000:0000:0000)
    ipv6_ladr: str | None = None  # ipv6 addr low   (ex. 0000:0000:0000:0001)
    ipv6_radr: str | None = None  # ipv6 reverse    (ex. ...)
    # --- network: link local -------------------------------------------------
    link_auto: str | None = None  # ipv4 dhcp      (ex. empty or dhcp)
    link_addr: str | None = None  # link address    (ex. fe80::1)
    link_prfx: str | None = None  # IPv6 prefix len (ex. 64)
    link_mask: str | None = None  # link netmask    (ex.)
    link_cidr: str | None = None  # link cidr       (ex. fe80::/64)
    link_fadr: str | None = None  # link full addr  (ex. fe80:0000:....:0001)
    link_uadr: str | None = None  # link addr up    (ex. fe80:0000:0000:0000)
    link_ladr: str | None = None  # link addr low   (ex. 0000:0000:0000:0001)
    link_radr: str | None = None  # link reverse    (ex. ...)
    # --- localhost -----------------------------------------------------------
    ipv6_lhst: str = "::1"  # ipv6 local host address
    ipv4_lhst: str = "127.0.0.1"  # ipv4 local host address
    ipv4_dumy: str = "127.0.1.1"  # ipv4 dummy address
    # --- ntp server ----------------------------------------------------------
    ntps_fbak: list[str] = field(
        default_factory=lambda: [
            "ntp1.jst.mfeed.ad.jp",
            "ntp2.jst.mfeed.ad.jp",
            "ntp3.jst.mfeed.ad.jp",
        ]
    )
    # --- shared directory parameter ------------------------------------------
    tops_path: Path | None = None  # top of shared directory
    expo_path: Path | None = None  # exports
    hgfs_path: Path | None = None  # vmware shared
    html_path: Path | None = None  # html contents#
    samb_path: Path | None = None  # samba shared
    tftp_path: Path | None = None  # tftp contents
    user_path: Path | None = None  # user file
    pvat_path: Path | None = None  # private contents directory
    shar_path: Path | None = None  # shared contents directory
    conf_path: Path | None = None  # configuration file
    data_path: Path | None = None  # data file
    keys_path: Path | None = None  # keyring file
    mkos_path: Path | None = None  # mkosi configuration files
    tmpl_path: Path | None = None  # templates for various configuration files
    shel_path: Path | None = None  # shell script file
    imgs_path: Path | None = None  # iso file extraction destination
    isos_path: Path | None = None  # iso file
    load_path: Path | None = None  # load module
    rmak_path: Path | None = None  # remake file
    cach_path: Path | None = None  # cache file
    ctnr_path: Path | None = None  # container file
    chrt_path: Path | None = None  # container file (chroot)
    xnbd_path: Path | None = None  # exports (network block device)
    xnfs_path: Path | None = None  # exports (network file system)
    xsmb_path: Path | None = None  # exports (samba)
    # --- working directory parameter -----------------------------------------
    time_stmp: str | None = None  # time stamp
    vadm_dirs: Path = field(
        default_factory=lambda: Path("/var/admin")
    )  # top of admin working directory
    vadm_path: Path | None = None  # top of admin working directory
    acmd_path: Path | None = None  # auto-command working directory
    inst_path: Path | None = None  # auto-install working directory
    back_path: Path | None = None  # top of backup directory
    orig_path: Path | None = None  # original file directory
    init_path: Path | None = None  # initial file directory
    samp_path: Path | None = None  # sample file directory
    logs_path: Path | None = None  # log file directory


class InfoSystem:
    @debug_logger
    def __init__(self, info_conf: InfoConfiguration) -> None:
        _caller = get_caller_name()
        message_info(_caller, f"{'initialize':<10}:system data", omit=True)
        # ---------------------------------------------------------------------
        self._valid_fields: set[str] = {f.name for f in fields(SystemData)}
        self.data: SystemData = SystemData()
        self.conf = info_conf
        _inp = self.conf
        _out = self.data
        # --- target directory ------------------------------------------------
        # /target      : debian
        # /mnt/sysimage: rhel(fedora,centos,...)
        # /mnt         :
        _out.tget_path = None
        for _tget_path in _out.tget_dirs:
            if _tget_path.exists() and os.path.ismount(_tget_path):
                _out.tget_path = _tget_path
                break
        if _out.tget_path:
            message_info(
                _caller, f"{'inst mode':<10}:target ({_out.tget_path})", omit=True
            )
        else:
            message_info(_caller, f"{'inst mode':<10}:not target", omit=True)
        # --- distribution ----------------------------------------------------
        for _path in ["/etc/os-release", "/etc/lsb-release"]:
            _tget_path: Path = addpath(base=_out.tget_path, path=Path(_path))
            if _tget_path.exists():
                message_info(_caller, f"{'loading':<10}:{_tget_path}", omit=True)
                _read_text: str = fread(src_path=_tget_path, text=True)
                _os_info = {}
                _kv_rule = re.compile(r"^\s*([A-Z_]+)\s*=\s*(.*)\s*$")
                for _line in _read_text.splitlines():
                    _match = _kv_rule.match(_line)
                    if _match:
                        _key = _match.group(1)
                        _val = _match.group(2).strip("\"'").strip()
                        _os_info[_key] = _val.lower()
                _out.dist_name = _os_info.get("ID") or _os_info.get("DISTRIB_ID", "")
                _out.dist_name = re.sub(r"-.+", "", _out.dist_name)
                _out.dist_vers = _os_info.get("VERSION_ID") or _os_info.get(
                    "DISTRIB_RELEASE", ""
                )
                _out.dist_code = _os_info.get("VERSION_CODENAME") or _os_info.get(
                    "DISTRIB_CODENAME", ""
                )
                # -------------------------------------------------------------
                break

        # --- target machine --------------------------------------------------
        _out.tget_virt = is_vm_type()  # virtualization (ex. vmware)
        _out.tget_chrt = is_chroot()  # is chgroot     (empty: none, else: chroot)
        _out.tget_cntr = is_container()  # is container   (empty: none, else: container)
        if os.path.ismount("/usr/bin/ischroot"):
            _out.tget_cntr = True
        # --- network parameter -----------------------------------------------
        _out.nwrk_host = _inp.find(key="NWRK_HOST")  # hostname
        _out.nwrk_wgrp = _inp.find(key="NWRK_WGRP")  # domain
        _out.nics_name = _inp.find(key="NICS_NAME")  # network device name
        _out.nics_madr = _inp.find(key="NICS_MADR")  # "              mac
        _out.ipv4_auto = _inp.find(key="IPV4_AUTO")  # IPv4 dhcp
        _out.ipv4_addr = _inp.find(key="IPV4_ADDR")  # IPv4 address
        _out.ipv4_prfx = _inp.find(key="IPV4_PRFX")  # IPv4 prefix length
        _out.ipv4_cidr = _inp.find(key="IPV4_CIDR")  # IPv4 cidr
        _out.ipv4_mask = _inp.find(key="IPV4_MASK")  # IPv4 subnetmask
        _out.ipv4_gway = _inp.find(key="IPV4_GWAY")  # IPv4 gateway
        _out.ipv4_nsvr = _inp.find(key="IPV4_NSVR")  # IPv4 nameserver
        _out.ipv4_uadr = _inp.find(key="IPV4_UADR")  # IPv4 address up
        _out.nman_name = _inp.find(key="NMAN_NAME")  # network manager name
        _out.ntps_addr = _inp.find(key="NTPS_ADDR")  # ntp server address
        _out.ntps_ipv4 = _inp.find(key="NTPS_IPV4")  # ntp server ipv4 addr
        # _out.ipv4_auto = True if _out.ipv4_addr else False  #
        # --- shared directory parameter --------------------------------------
        _out.tops_path = _inp.path(key="DIRS_TOPS")  # top of shared directory
        _out.expo_path = _inp.path(key="DIRS_EXPO")  # exports
        _out.hgfs_path = _inp.path(key="DIRS_HGFS")  # vmware shared
        _out.html_path = _inp.path(key="DIRS_HTML")  # html contents#
        _out.samb_path = _inp.path(key="DIRS_SAMB")  # samba shared
        _out.tftp_path = _inp.path(key="DIRS_TFTP")  # tftp contents
        _out.user_path = _inp.path(key="DIRS_USER")  # user file
        _out.pvat_path = _inp.path(key="DIRS_PVAT")  # private contents directory
        _out.shar_path = _inp.path(key="DIRS_SHAR")  # shared contents directory
        _out.conf_path = _inp.path(key="DIRS_CONF")  # configuration file
        _out.data_path = _inp.path(key="DIRS_DATA")  # data file
        _out.keys_path = _inp.path(key="DIRS_KEYS")  # keyring file
        _out.mkos_path = _inp.path(key="DIRS_MKOS")  # mkosi configuration files
        _out.tmpl_path = _inp.path(key="DIRS_TMPL")  # templates for various conf files
        _out.shel_path = _inp.path(key="DIRS_SHEL")  # shell script file
        _out.imgs_path = _inp.path(key="DIRS_IMGS")  # iso file extraction destination
        _out.isos_path = _inp.path(key="DIRS_ISOS")  # iso file
        _out.load_path = _inp.path(key="DIRS_LOAD")  # load module
        _out.rmak_path = _inp.path(key="DIRS_RMAK")  # remake file
        _out.cach_path = _inp.path(key="DIRS_CACH")  # cache file
        _out.ctnr_path = _inp.path(key="DIRS_CTNR")  # container file
        _out.chrt_path = _inp.path(key="DIRS_CHRT")  # container file (chroot)
        _out.xnbd_path = _inp.path(key="DIRS_XNBD")  # exports (network block device)
        _out.xnfs_path = _inp.path(key="DIRS_XNFS")  # exports (network file system)
        _out.xsmb_path = _inp.path(key="DIRS_XSMB")  # exports (samba)
        # --- working directory parameter -------------------------------------
        _timestamp: str = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
        _out.time_stmp = _timestamp  # time stamp
        _out.vadm_path = _inp.path(key="DIRS_VADM")  # top of admin working directory
        _out.acmd_path = _out.vadm_path / "autoinst"  # auto-command working directory
        # _out.acmd_path = _out.vadm_path / _out.prog_name
        _out.inst_path = _out.acmd_path  # auto-install working directory
        _out.back_path = _out.inst_path.with_suffix(
            f"{_out.inst_path.suffix}.{_timestamp}"
        )  # top of backup directory
        _out.orig_path = _out.back_path / "orig"  # original file directory
        _out.init_path = _out.back_path / "init"  # initial file directory
        _out.samp_path = _out.back_path / "samp"  # sample file directory
        _out.logs_path = _out.back_path / "logs"  # log file directory
        # --- samba ---------------------------------------------------------------
        for _dir in _out.nlin_dirs:
            _tget_path: Path = addpath(base=_out.tget_path, path=Path(_dir))
            if _tget_path.exists():
                _out.nlin_path = _tget_path
                break
        # --- complete system data --------------------------------------------
        message_info(_caller, f"{'complete':<10}:system data", omit=True)
        # --- command line ----------------------------------------------------
        message_info(_caller, f"{'loading':<10}:command line", omit=True)
        _params: dict[str, str | bool] = cmdline()
        for _key, _value in _params.items():
            _val_str = str(_value) if _value else None
            match _key:
                # --- debug ---------------------------------------------------
                case "debug" | "dbg":
                    _out.dbgs_flag = True
                    _out.dout_flag = True
                case "debug_out" | "dbg_out":
                    _out.dout_flag = True
                # --- parameter -----------------------------------------------
                case "root":
                    _out.parm_root = _val_str
                case "security":
                    _out.parm_secu = _val_str
                case "apparmor":
                    _out.parm_armo = _val_str
                case "selinux":
                    _out.parm_slnx = _val_str
                # --- directory / file ----------------------------------------
                case "target":
                    _out.tget_urls = _val_str
                case "iso-url":
                    _out.isou_urls = _val_str
                # --- preseed -------------------------------------------------
                # preseed.cfg
                case "preseed/url" | "url" | "preseed/file" | "file":
                    _out.seed_urls = _val_str
                # nocloud
                case "ds":
                    _out.seed_urls = f"{_val_str}/user-data"
                # kickstart
                case "inst.ks":
                    _out.seed_urls = _val_str
                # autoyast
                case "autoyast":
                    _out.seed_urls = _val_str
                # agama
                case "inst.auto":
                    _out.seed_urls = _val_str
                # --- network parameter -----------------------------------------------
                # hostname
                case "netcfg/get_hostname" | "hostname":
                    _out.nwrk_host = _val_str
                # domain
                case "netcfg/get_domain" | "domain":
                    _out.nwrk_wgrp = _val_str
                # network device name
                case "netcfg/choose_interface" | "interface":
                    _out.nics_name = _val_str
                # IPv4 address (emp=dhcp)
                case "netcfg/target_network_config":
                    _out.ipv4_auto = True
                case "netcfg/disable_dhcp" | "netcfg/disable_autoconfig":
                    _out.ipv4_auto = bool(_val_str.lower() != "true")
                case "netcfg/get_ipaddress":
                    _out.ipv4_auto = False
                    _out.ipv4_addr = _val_str
                # IPv4 subnetmask
                case "netcfg/get_netmask":
                    _out.ipv4_mask = _val_str
                # IPv4 gateway
                case "netcfg/get_gateway":
                    _out.ipv4_gway = _val_str
                # IPv4 nameserver
                case "netcfg/get_nameservers" | "nameserver":
                    _out.ipv4_nsvr = _val_str
                case "ip" | "ip4" | "ipv4":
                    _list = str(_val_str + ":" * 8).split(":")
                    match _list[1].lower():
                        case "dhcp" | "dhcp4":
                            _out.ipv4_auto = True
                            _out.ipv4_addr = ""
                            _out.ipv4_gway = ""
                            _out.ipv4_mask = ""
                            _out.nwrk_host = ""
                            _out.nwrk_wgrp = ""
                            _out.ipv4_nsvr = ""
                        case _:
                            _out.ipv4_auto = False
                            _out.ipv4_addr = _list[1] if _list[1] else None
                            _out.ipv4_gway = _list[3] if _list[3] else None
                            _out.ipv4_mask = _list[4] if _list[4] else None
                            _out.nwrk_host = _list[5] if _list[5] else None
                            _out.nwrk_wgrp = _list[6] if _list[6] else None
                            _out.ipv4_nsvr = _list[8] if _list[8] else None
                case "ifcfg":
                    _list = str(_val_str + "=" * 1).split("=")
                    _out.nics_name = _list[1]
                    _list = str(_list[2] + "," * 4).split(",")
                    match _list[1].lower():
                        case "dhcp" | "dhcp4":
                            _out.ipv4_auto = True
                            _out.ipv4_addr = ""
                            _out.ipv4_gway = ""
                            _out.ipv4_nsvr = ""
                            _out.nwrk_wgrp = ""
                        case "dhcp6":
                            _out.ipv4_auto = ""
                            _out.ipv4_addr = ""
                            _out.ipv4_gway = ""
                            _out.ipv4_nsvr = ""
                            _out.nwrk_wgrp = ""
                        case _:
                            _val_str = re.sub(r"[^=]+=[^=]+=", "", _val_str)
                            _list = str(_val_str + "," * 4).split(",")
                            _out.ipv4_auto = False
                            _out.ipv4_addr = _list[1] if _list[1] else None
                            _out.ipv4_gway = _list[2] if _list[2] else None
                            _out.ipv4_nsvr = _list[3] if _list[3] else None
                            _out.nwrk_wgrp = _list[4] if _list[4] else None
        _out.tget_path = (
            None
            if not _out.tget_urls or "://" in _out.tget_urls
            else Path(_out.tget_urls)
        )
        _out.isou_path = (
            None
            if not _out.isou_urls or "://" in _out.isou_urls
            else Path(_out.isou_urls)
        )
        _out.seed_path = (
            None
            if not _out.seed_urls or "://" in _out.seed_urls
            else Path(_out.seed_urls)
        )
        if "/" in _out.ipv4_addr:
            _out.ipv4_cidr = _out.ipv4_addr
            _out.ipv4_addr = _out.ipv4_cidr.split("/")[0]
            _out.ipv4_prfx = _out.ipv4_cidr.split("/")[1]
        if not _out.ipv4_prfx and _out.ipv4_mask:
            _interface = IPv4Interface(f"0.0.0.0/{_out.ipv4_mask}")
            _out.ipv4_prfx = str(_interface.network.prefixlen)
        if _out.ipv4_prfx and not _out.ipv4_mask:
            _interface = IPv4Interface(f"0.0.0.0/{_out.ipv4_prfx}")
            _out.nics_mask = str(_interface.netmask)
        if not _out.ipv4_cidr:
            _out.ipv4_cidr = f"{_out.ipv4_addr}/{_out.ipv4_prfx}"
        if _out.ipv4_addr:
            _out.ipv4_uadr = ".".join(_out.ipv4_addr.split(".")[:3])
            _out.ipv4_ladr = ".".join(_out.ipv4_addr.split(".")[3:])
            _out.ipv4_radr = conv_ipv4_reverse(_out.ipv4_addr)
        if _out.dist_name:
            _out.nwrk_host = _out.nwrk_host.replace(":_DISTRO_:", _out.dist_name)
        _out.nwrk_fqdn = f"{_out.nwrk_host}.{_out.nwrk_wgrp}"
        message_info(_caller, f"{'complete':<10}:command line", omit=True)

    @debug_logger
    def debug(self, debugout: bool = False) -> None:
        if debugout:
            _caller = get_caller_name()
            message_info(_caller, f"{'*** start':<10}:SystemData ***", omit=True)
            for _key, _value in self.data.__dict__.items():
                message_info(_caller, f"{_key}={_value or ''}", omit=True)
            message_info(_caller, f"{'*** end':<10}:SystemData ***", omit=True)

    @debug_logger
    def print_info(self, debugout: bool = False) -> None:
        if debugout:
            _caller = get_caller_name()
            message_info(_caller, f"{'*** start':<10}:Command line ***", omit=True)
            for _key, _value in self.data.__dict__.items():
                match _key:
                    case (
                        "dbgs_flag"
                        | "dout_flag"
                        | "dist_name"
                        | "dist_vers"
                        | "dist_code"
                        | "tget_virt"
                        | "tget_chrt"
                        | "tget_cntr"
                        | "parm_root"
                        | "parm_secu"
                        | "tget_urls"
                        | "isou_urls"
                        | "seed_urls"
                        | "nwrk_fqdn"
                        | "nwrk_host"
                        | "nwrk_wgrp"
                        | "nics_name"
                        | "nics_madr"
                        | "nics_gway"
                        | "nics_nsvr"
                        | "nics_fqdn"
                        | "nics_host"
                        | "nics_wgrp"
                        | "nics_stat"
                        | "nics_auto"
                        | "nics_cidr"
                        | "ipv4_auto"
                        | "ipv4_addr"
                        | "ipv4_mask"
                        | "ipv4_gway"
                        | "ipv4_nsvr"
                    ):
                        message_info(_caller, f"{_key}={_value or ''}", omit=True)
            message_info(_caller, f"{'*** end':<10}:Command line ***", omit=True)
