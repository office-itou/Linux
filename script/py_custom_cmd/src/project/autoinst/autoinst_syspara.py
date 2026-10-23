# --- python library ----------------------------------------------------------
import re
from dataclasses import dataclass, fields
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.shared import InfoCommon
from common.utils import (
    cmdline,
    debug_logger,
    get_caller_name,
    infosystem,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@dataclass
class SystemData:
    # --- debug ---------------------------------------------------------------
    dbgs_flag: bool | None = None  # debug flag
    dout_flag: bool | None = None  # debug out flag
    # --- target machine ------------------------------------------------------
    tget_virt: bool | None = None  # virtualization (ex. vmware)
    tget_chrt: bool | None = None  # is chgroot     (empty: none, else: chroot)
    tget_cntr: bool | None = None  # is container   (empty: none, else: container)
    # --- parameter -----------------------------------------------------------
    parm_root: str | None = None  # environmental variables: root
    parm_secu: str | None = None  # "                      : security
    parm_armo: str | None = None  # "                      : apparmor
    parm_slnx: str | None = None  # "                      : selinux
    # --- directory / file ----------------------------------------------------
    tget_dirs: list[Path] = [Path("/target"), Path("/mnt/sysimage"), Path("/mnt")]
    tget_path: Path | None = None  # target dir     (ex. /target)
    isos_path: Path | None = None  # iso file name
    # --- samba ---------------------------------------------------------------
    nlin_dirs: list[Path] = [Path("/usr/sbin/nologin"), Path("/sbin/nologin")]
    nlin_path: Path | None = None
    # --- preseed -------------------------------------------------------------
    seed_path: Path | None = None  # preseed file name
    # --- network: nic (retrieved value) --------------------------------------
    nics_fqdn: str | None = None  # hostname fqdn   (ex. sv-server.workgroup)
    nics_host: str | None = None  # hostname        (ex. sv-server)
    nics_wgrp: str | None = None  # domain          (ex. workgroup)
    nics_stat: bool | None = None  # nic if status  (empty: stop, else: active)
    nics_auto: bool | None = None  # ipv4 dhcp      (ex. empty or dhcp)
    nics_ipv4: str | None = None  # ipv4 address    (ex. 192.168.1.1)
    nics_mask: str | None = None  # ipv4 netmask    (ex. 255.255.255.0)
    nics_cidr: str | None = None  # ipv4 cidr       (ex. 24)
    # --- network parameter ---------------------------------------------------
    nwrk_host: str | None = None  # hostname fqdn   (ex. sv-server.workgroup)
    nwrk_wgrp: str | None = None  # domain          (ex. workgroup)
    nics_name: str | None = None  # nic if name     (ex. ens160)
    nics_madr: str | None = None  # "   if mac      (ex. 00:00:00:00:00:00)
    ipv4_auto: bool | None = None  # IPv4 dhcp      (ex. empty or dhcp)
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
    ipv6_auto: bool | None = None  # ipv6 dhcp      (ex. empty or dhcp)
    ipv6_addr: str | None = None  # ipv6 address    (ex. ::1)
    ipv6_prfx: str | None = None  # IPv6 prefix len (ex. 64)
    ipv6_cidr: str | None = None  # IPv6 cidr       (ex. ::1/24)
    ipv6_fadr: str | None = None  # ipv6 full addr  (ex. 0000:0000:....:0001)
    ipv6_uadr: str | None = None  # ipv6 addr up    (ex. 0000:0000:0000:0000)
    ipv6_ladr: str | None = None  # ipv6 addr low   (ex. 0000:0000:0000:0001)
    ipv6_radr: str | None = None  # ipv6 reverse    (ex. ...)
    # --- network: link local -------------------------------------------------
    link_auto: bool | None = None  # ipv4 dhcp      (ex. empty or dhcp)
    link_addr: str | None = None  # link address    (ex. fe80::1)
    link_prfx: str | None = None  # IPv6 prefix len (ex. 64)
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
    ntps_fbak: str = "ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp"
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


class InfoSystem:
    @debug_logger
    def __init__(self, info_comm: InfoCommon) -> None:
        self._valid_fields: set[str] = {f.name for f in fields(SystemData)}
        self.data: SystemData = SystemData()
        self.info_comm = info_comm
        inp = self.info_comm.conf
        out = self.data
        # --- network parameter -----------------------------------------------
        out.nwrk_host = inp.find("NWRK_HOST")  # hostname
        out.nwrk_wgrp = inp.find("NWRK_WGRP")  # domain
        out.nics_name = inp.find("NICS_NAME")  # network device name
        out.nics_madr = inp.find("NICS_MADR")  # "              mac
        out.ipv4_auto = inp.find("IPV4_AUTO")  # IPv4 dhcp
        out.ipv4_addr = inp.find("IPV4_ADDR")  # IPv4 address
        out.ipv4_prfx = inp.find("IPV4_PRFX")  # IPv4 prefix length
        out.ipv4_cidr = inp.find("IPV4_CIDR")  # IPv4 cidr
        out.ipv4_mask = inp.find("IPV4_MASK")  # IPv4 subnetmask
        out.ipv4_gway = inp.find("IPV4_GWAY")  # IPv4 gateway
        out.ipv4_nsvr = inp.find("IPV4_NSVR")  # IPv4 nameserver
        out.ipv4_uadr = inp.find("IPV4_UADR")  # IPv4 address up
        out.nman_name = inp.find("NMAN_NAME")  # network manager name
        out.ntps_addr = inp.find("NTPS_ADDR")  # ntp server address
        out.ntps_ipv4 = inp.find("NTPS_IPV4")  # ntp server ipv4 addr
        out.ipv4_auto = True if out.ipv4_addr else False  #
        # --- shared directory parameter --------------------------------------
        out.tops_path = inp.find("DIRS_TOPS")  # top of shared directory
        out.expo_path = inp.find("DIRS_EXPO")  # exports
        out.hgfs_path = inp.find("DIRS_HGFS")  # vmware shared
        out.html_path = inp.find("DIRS_HTML")  # html contents#
        out.samb_path = inp.find("DIRS_SAMB")  # samba shared
        out.tftp_path = inp.find("DIRS_TFTP")  # tftp contents
        out.user_path = inp.find("DIRS_USER")  # user file
        out.pvat_path = inp.find("DIRS_PVAT")  # private contents directory
        out.shar_path = inp.find("DIRS_SHAR")  # shared contents directory
        out.conf_path = inp.find("DIRS_CONF")  # configuration file
        out.data_path = inp.find("DIRS_DATA")  # data file
        out.keys_path = inp.find("DIRS_KEYS")  # keyring file
        out.mkos_path = inp.find("DIRS_MKOS")  # mkosi configuration files
        out.tmpl_path = inp.find("DIRS_TMPL")  # templates for various conf files
        out.shel_path = inp.find("DIRS_SHEL")  # shell script file
        out.imgs_path = inp.find("DIRS_IMGS")  # iso file extraction destination
        out.isos_path = inp.find("DIRS_ISOS")  # iso file
        out.load_path = inp.find("DIRS_LOAD")  # load module
        out.rmak_path = inp.find("DIRS_RMAK")  # remake file
        out.cach_path = inp.find("DIRS_CACH")  # cache file
        out.ctnr_path = inp.find("DIRS_CTNR")  # container file
        out.chrt_path = inp.find("DIRS_CHRT")  # container file (chroot)
        out.xnbd_path = inp.find("DIRS_XNBD")  # exports (network block device)
        out.xnfs_path = inp.find("DIRS_XNFS")  # exports (network file system)
        out.xsmb_path = inp.find("DIRS_XSMB")  # exports (samba)
        # --- working directory parameter -------------------------------------
        # top of working directory
        # _DIRS_ACMD="${_DIRS_VADM:?}/${_PROG_NAME%%_*}"
        # _DIRS_INST="${_DIRS_ACMD:?}.$(date ${__time_start:+-d "@${__time_start}"} +"%Y%m%d%H%M%S")"
        # readonly _DIRS_ACMD							# auto-command working directory
        # readonly _DIRS_INST							# auto-install working directory
        # readonly _DIRS_BACK="${_DIRS_INST}"			# top of backup directory
        # readonly _DIRS_ORIG="${_DIRS_BACK}/orig"	# original file directory
        # readonly _DIRS_INIT="${_DIRS_BACK}/init"	# initial file directory
        # readonly _DIRS_SAMP="${_DIRS_BACK}/samp"	# sample file directory
        # readonly _DIRS_LOGS="${_DIRS_BACK}/logs"	# log file directory
        # --- command line ----------------------------------------------------
        _params: dict[str, str | bool] = cmdline()
        for _key, _value in _params.items():
            _val_str = str(_value) if _value else None
            match _key:
                # --- debug ---------------------------------------------------
                case "debug" | "dbg":
                    out.dbgs_flag = True
                    out.dout_flag = True
                case "debugout" | "dbgout":
                    out.dout_flag = True
                # --- parameter -----------------------------------------------
                case "root":
                    out.parm_root = _val_str
                case "security":
                    out.parm_secu = _val_str
                case "apparmor":
                    out.parm_armo = _val_str
                case "selinux":
                    out.parm_slnx = _val_str
                # --- directory / file ----------------------------------------
                case "target":
                    out.tget_path = Path(_val_str) if _val_str else None
                case "iso-url":
                    out.isos_path = Path(_val_str) if _val_str else None
                # --- preseed -------------------------------------------------
                # preseed.cfg
                case "preseed/url" | "url" | "preseed/file" | "file":
                    out.seed_path = Path(_val_str) if _val_str else None
                    out.seed_path = Path(_val_str) if _val_str else None
                # nocloud
                case "ds":
                    out.seed_path = Path(_val_str) / "user-data" if _val_str else None
                # kickstart
                case "inst.ks":
                    out.seed_path = Path(_val_str) if _val_str else None
                # autoyast
                case "autoyast":
                    out.seed_path = Path(_val_str) if _val_str else None
                # agama
                case "inst.auto":
                    out.seed_path = Path(_val_str) if _val_str else None
                # --- network parameter -----------------------------------------------
                # hostname
                case "netcfg/get_hostname" | "hostname":
                    out.nwrk_host = _val_str
                # domain
                case "netcfg/get_domain" | "domain":
                    out.nwrk_wgrp = _val_str
                # network device name
                case "netcfg/choose_interface" | "interface":
                    out.nics_name = _val_str
                # IPv4 address (emp=dhcp)
                case "netcfg/target_network_config":
                    out.ipv4_auto = True
                case "netcfg/disable_dhcp" | "netcfg/disable_autoconfig":
                    out.ipv4_auto = bool(_val_str.lower() != "true")
                case "netcfg/get_ipaddress":
                    out.ipv4_auto = False
                    out.ipv4_addr = _val_str
                # IPv4 subnetmask
                case "netcfg/get_netmask":
                    out.ipv4_mask = _val_str
                # IPv4 gateway
                case "netcfg/get_gateway":
                    out.ipv4_gway = _val_str
                # IPv4 nameserver
                case "netcfg/get_nameservers" | "nameserver":
                    out.ipv4_nsvr = _val_str
                case "ip" | "ip4" | "ipv4":
                    _list = str(_val_str + ":" * 8).split(":")
                    match _list[1].lower():
                        case "dhcp" | "dhcp4":
                            out.ipv4_auto = True
                            out.ipv4_addr = ""
                            out.ipv4_gway = ""
                            out.ipv4_mask = ""
                            out.nwrk_host = ""
                            out.nwrk_wgrp = ""
                            out.ipv4_nsvr = ""
                        case _:
                            out.ipv4_auto = False
                            out.ipv4_addr = _list[1] if _list[1] else None
                            out.ipv4_gway = _list[3] if _list[3] else None
                            out.ipv4_mask = _list[4] if _list[4] else None
                            out.nwrk_host = _list[5] if _list[5] else None
                            out.nwrk_wgrp = _list[6] if _list[6] else None
                            out.ipv4_nsvr = _list[8] if _list[8] else None
                case "ifcfg":
                    _list = str(_val_str + "=" * 1).split("=")
                    out.nics_name = _list[1]
                    _list = str(_list[2] + "," * 4).split(",")
                    match _list[1].lower():
                        case "dhcp" | "dhcp4":
                            out.ipv4_auto = True
                            out.ipv4_addr = ""
                            out.ipv4_gway = ""
                            out.ipv4_nsvr = ""
                            out.nwrk_wgrp = ""
                        case "dhcp6":
                            out.ipv4_auto = ""
                            out.ipv4_addr = ""
                            out.ipv4_gway = ""
                            out.ipv4_nsvr = ""
                            out.nwrk_wgrp = ""
                        case _:
                            _val_str = re.sub(r"[^=]+=[^=]+=", "", _val_str)
                            _list = str(_val_str + "," * 4).split(",")
                            out.ipv4_auto = False
                            out.ipv4_addr = _list[1] if _list[1] else None
                            out.ipv4_gway = _list[2] if _list[2] else None
                            out.ipv4_nsvr = _list[3] if _list[3] else None
                            out.nwrk_wgrp = _list[4] if _list[4] else None
        self.debug()

    @debug_logger
    def debug(self) -> None:
        if self.data.dout_flag or getattr(infosystem, "debugout", False):
            _caller = get_caller_name()
            message_info(_caller, "*** start: SystemData ***", omit=True)
            for _clas_data in self.data:
                message_info(
                    _caller, f"{_clas_data.key}={_clas_data.value or ''}", omit=True
                )
            message_info(_caller, "*** end  : SystemData ***", omit=True)
