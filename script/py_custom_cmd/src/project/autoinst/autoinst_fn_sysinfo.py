# --- python library ----------------------------------------------------------
import os
import re
from dataclasses import fields
from datetime import datetime
from pathlib import Path

# --- import module -----------------------------------------------------------
from autoinst_def_sysinfo import SystemData

# --- my library --------------------------------------------------------------
from common.shared import (
    InfoConfiguration,
)
from common.utils import (
    InfoNetworkIF,
    addpath,
    cmdline,
    debug_logger,
    find_nic,
    get_caller_name,
    get_distribution,
    ipv4_addr,
    ipv4_lower,
    ipv4_mask,
    ipv4_prfx,
    ipv4_reverse,
    ipv4_upper,
    is_chroot,
    is_container,
    is_vm_type,
    message_info,
)


# --- class and function ------------------------------------------------------
class InfoSystem:
    @debug_logger
    def __init__(self, info_conf: InfoConfiguration) -> None:
        _caller = get_caller_name()
        # ---------------------------------------------------------------------
        message_info(_caller, f"{'initialize':<10}:system data", omit=True)
        self._valid_fields: set[str] = {f.name for f in fields(SystemData)}
        self.data: SystemData = SystemData()
        self.conf = info_conf
        message_info(_caller, f"{'complete':<10}:system data", omit=True)
        # ---------------------------------------------------------------------
        message_info(_caller, f"{'configure':<10}:user data", omit=True)
        self._get_target_dir()
        self._get_target_dist()
        self._get_target_machine()
        self._get_target_ntwk_info()
        self._get_target_share_dir()
        self._get_target_nologin()
        self._get_command_line()
        self._get_target_nics_info()
        message_info(_caller, f"{'complete':<10}:user data", omit=True)

    @debug_logger
    def _get_target_dir(self) -> None:
        _caller = get_caller_name()
        # --- target directory ------------------------------------------------
        # /target      : debian
        # /mnt/sysimage: rhel(fedora,centos,...)
        # /mnt         :
        self.data.tget_path = None
        for _tget_path in self.data.tget_dirs:
            _root_path = _tget_path / "root"
            if _root_path.exists():
                self.data.tget_path = _tget_path
                break

    def _get_target_dist(self) -> None:
        _caller = get_caller_name()
        # --- distribution ----------------------------------------------------
        _find_list: list[Path] = [
            addpath(base=self.data.tget_path, path=Path("/etc/os-release")),
            addpath(base=self.data.tget_path, path=Path("/etc/lsb-release")),
        ]
        _info_dist = get_distribution(find_list=_find_list)
        self.data.dist_name = _info_dist.name
        self.data.dist_vers = _info_dist.vers
        self.data.dist_code = _info_dist.code

    def _get_target_machine(self) -> None:
        _caller = get_caller_name()
        # --- target machine --------------------------------------------------
        self.data.tget_virt = is_vm_type()  # virtualization
        self.data.tget_chrt = is_chroot()  # is chgroot
        self.data.tget_cntr = is_container()  # is container
        if os.path.ismount("/usr/bin/ischroot"):
            self.data.tget_cntr = True

    def _get_target_nics_info(self) -> None:
        _caller = get_caller_name()
        # --- network: nic configuration settings -----------------------------
        _nwrk_devs = self.data.nwrk_devs
        info_ntwk = InfoNetworkIF(nic_name=_nwrk_devs)
        self.data.nics_path = info_ntwk.data.path  # path
        self.data.nics_name = info_ntwk.data.name  # nic if name
        self.data.nics_madr = info_ntwk.data.madr  # "   if mac
        self.data.nics_gway = info_ntwk.data.gway  # "   gateway
        self.data.nics_nsvr = info_ntwk.data.nsvr  # "   nameserver
        self.data.nics_fqdn = info_ntwk.data.fqdn  # hostname fqdn
        self.data.nics_host = info_ntwk.data.host  # hostname
        self.data.nics_wgrp = info_ntwk.data.wgrp  # domain
        self.data.nics_stat = info_ntwk.data.stat  # nic if status
        self.data.nics_ipv4 = info_ntwk.data.ipv4  # ipv4 address information
        self.data.nics_ipv6 = info_ntwk.data.ipv6  # ipv6 address information
        self.data.nics_link = info_ntwk.data.link  # link address information

    def _get_target_ntwk_info(self) -> None:
        _caller = get_caller_name()
        # --- network parameter: input value  ---------------------------------
        self.data.nwrk_host = self.conf.find(key="NWRK_HOST")  # hostname
        self.data.nwrk_wgrp = self.conf.find(key="NWRK_WGRP")  # domain
        if "." in self.data.nwrk_host:
            _host_list: list[str] = self.data.nwrk_host.strip("\n").split(".")
            self.data.nwrk_host = _host_list[0]
            self.data.nwrk_wgrp = ".".join(_host_list[1:])
        self.data.nwrk_fqdn = (
            f"{self.data.nwrk_host}.{self.data.nwrk_wgrp}"  # hostname fqdn
        )
        self.data.nman_name = self.conf.find(key="NMAN_NAME")  # network manager
        self.data.ntps_addr = self.conf.find(key="NTPS_ADDR")  # ntp server
        self.data.ntps_ipv4 = self.conf.find(key="NTPS_IPV4")  # ntp ipv4 addr
        # --- network parameter: ipv4 -----------------------------------------
        self.data.ipv4_auto = self.conf.find(key="IPV4_AUTO")  # dhcp
        self.data.ipv4_addr = self.conf.find(key="IPV4_ADDR")  # address
        self.data.ipv4_prfx = self.conf.find(key="IPV4_PRFX")  # prefix len
        self.data.ipv4_cidr = self.conf.find(key="IPV4_CIDR")  # cidr
        self.data.ipv4_mask = self.conf.find(key="IPV4_MASK")  # netmask
        if not self.data.ipv4_addr:
            if self.data.ipv4_cidr:
                self.data.ipv4_addr = ipv4_addr(cidr=self.data.ipv4_cidr)
            else:
                self.data.ipv4_auto = "True"
        if not self.data.ipv4_prfx:
            if self.data.ipv4_cidr:
                self.data.ipv4_prfx = ipv4_prfx(cidr=self.data.ipv4_cidr)
            elif self.data.ipv4_mask:
                self.data.ipv4_prfx = ipv4_prfx(cidr=f"0.0.0.0/{self.data.ipv4_mask}")
            else:
                self.data.ipv4_prfx = "24"
        if not self.data.ipv4_mask:
            if self.data.ipv4_cidr:
                self.data.ipv4_mask = ipv4_mask(cidr=self.data.ipv4_cidr)
            elif self.data.ipv4_prfx:
                self.data.ipv4_mask = ipv4_prfx(cidr=f"0.0.0.0/{self.data.ipv4_prfx}")
            else:
                self.data.ipv4_mask = "255.255.255.0"
        if self.data.ipv4_addr and self.data.ipv4_prfx:
            self.data.ipv4_cidr = f"{self.data.ipv4_addr}/{self.data.ipv4_prfx}"
        self.data.ipv4_fadr = self.data.ipv4_cidr  # full addr
        if self.data.ipv4_addr:
            self.data.ipv4_uadr = ipv4_upper(addr=self.data.ipv4_addr)  # addr up
            self.data.ipv4_ladr = ipv4_lower(addr=self.data.ipv4_addr)  # addr low
            self.data.ipv4_radr = ipv4_reverse(addr=self.data.ipv4_addr)  # reverse
        self.data.ipv4_gway = self.conf.find(key="IPV4_GWAY")  # gateway
        self.data.ipv4_nsvr = self.conf.find(key="IPV4_NSVR")  # nameserver
        # --- network parameter: ipv6 -----------------------------------------
        self.data.ipv6_auto = None  # dhcp
        self.data.ipv6_addr = None  # address
        self.data.ipv6_prfx = None  # prefix len
        self.data.ipv6_cidr = None  # cidr
        self.data.ipv6_mask = None  # netmask
        self.data.ipv6_fadr = None  # full addr
        self.data.ipv6_uadr = None  # addr up
        self.data.ipv6_ladr = None  # addr low
        self.data.ipv6_radr = None  # reverse
        # --- network parameter: link -----------------------------------------
        self.data.link_auto = None  # dhcp
        self.data.link_addr = None  # address
        self.data.link_prfx = None  # prefix len
        self.data.link_cidr = None  # cidr
        self.data.link_mask = None  # netmask
        self.data.link_fadr = None  # full addr
        self.data.link_uadr = None  # addr up
        self.data.link_ladr = None  # addr low
        self.data.link_radr = None  # reverse

    def _get_target_share_dir(self) -> None:
        _caller = get_caller_name()
        # --- shared directory parameter --------------------------------------
        self.data.tops_path = self.conf.path(key="DIRS_TOPS")  # top of shared directory
        self.data.expo_path = self.conf.path(key="DIRS_EXPO")  # exports
        self.data.hgfs_path = self.conf.path(key="DIRS_HGFS")  # vmware shared
        self.data.html_path = self.conf.path(key="DIRS_HTML")  # html contents#
        self.data.samb_path = self.conf.path(key="DIRS_SAMB")  # samba shared
        self.data.tftp_path = self.conf.path(key="DIRS_TFTP")  # tftp contents
        self.data.user_path = self.conf.path(key="DIRS_USER")  # user file
        self.data.pvat_path = self.conf.path(key="DIRS_PVAT")  # private contents
        self.data.shar_path = self.conf.path(key="DIRS_SHAR")  # shared contents
        self.data.conf_path = self.conf.path(key="DIRS_CONF")  # configuration file
        self.data.data_path = self.conf.path(key="DIRS_DATA")  # data file
        self.data.keys_path = self.conf.path(key="DIRS_KEYS")  # keyring file
        self.data.mkos_path = self.conf.path(key="DIRS_MKOS")  # mkosi configuration
        self.data.tmpl_path = self.conf.path(key="DIRS_TMPL")  # templates for various
        self.data.shel_path = self.conf.path(key="DIRS_SHEL")  # shell script file
        self.data.imgs_path = self.conf.path(key="DIRS_IMGS")  # iso file extraction
        self.data.isos_path = self.conf.path(key="DIRS_ISOS")  # iso file
        self.data.load_path = self.conf.path(key="DIRS_LOAD")  # load module
        self.data.rmak_path = self.conf.path(key="DIRS_RMAK")  # remake file
        self.data.cach_path = self.conf.path(key="DIRS_CACH")  # cache file
        self.data.ctnr_path = self.conf.path(key="DIRS_CTNR")  # container file
        self.data.chrt_path = self.conf.path(key="DIRS_CHRT")  # container file (chroot)
        self.data.xnbd_path = self.conf.path(key="DIRS_XNBD")  # exports (network block)
        self.data.xnfs_path = self.conf.path(key="DIRS_XNFS")  # exports (network file)
        self.data.xsmb_path = self.conf.path(key="DIRS_XSMB")  # exports (samba)
        # --- working directory parameter -------------------------------------
        _timestamp: str = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
        self.data.time_stmp = _timestamp  # time stamp
        self.data.vadm_path = self.conf.path(key="DIRS_VADM")  # top of admin work
        self.data.acmd_path = self.data.vadm_path / "autoinst"  # auto-command work
        self.data.inst_path = self.data.acmd_path  # auto-install working directory
        self.data.back_path = self.data.inst_path.with_suffix(
            f"{self.data.inst_path.suffix}.{_timestamp}"
        )  # top of backup directory
        self.data.orig_path = self.data.back_path / "orig"  # original file directory
        self.data.init_path = self.data.back_path / "init"  # initial file directory
        self.data.samp_path = self.data.back_path / "samp"  # sample file directory
        self.data.logs_path = self.data.back_path / "logs"  # log file directory

    def _get_target_nologin(self) -> None:
        _caller = get_caller_name()
        # --- nologin ---------------------------------------------------------
        for _dir in self.data.nlin_dirs:
            _tget_path: Path = addpath(base=self.data.tget_path, path=Path(_dir))
            if _tget_path.exists():
                self.data.nlin_path = _tget_path
                break

    def _get_command_line(self) -> None:
        _caller = get_caller_name()
        # --- command line ----------------------------------------------------
        _params: dict[str, str | bool] = cmdline()
        for _key, _value in _params.items():
            _val_str = str(_value) if _value else None
            match _key:
                # --- debug ---------------------------------------------------
                case "debug" | "dbg":
                    self.data.dbgs_flag = True
                    self.data.dout_flag = True
                case "debugdata" | "dbgdata":
                    self.data.dout_flag = True
                # --- parameter -----------------------------------------------
                case "root":
                    self.data.parm_root = _val_str
                case "security":
                    self.data.parm_secu = _val_str
                case "apparmor":
                    self.data.parm_armo = _val_str
                case "selinux":
                    self.data.parm_slnx = _val_str
                # --- directory / file ----------------------------------------
                case "target":
                    self.data.tget_urls = _val_str
                case "iso-url":
                    self.data.isou_urls = _val_str
                # --- preseed -------------------------------------------------
                # preseed.cfg
                case "preseed/url" | "url" | "preseed/file" | "file":
                    self.data.seed_urls = _val_str
                # nocloud
                case "ds":
                    self.data.seed_urls = f"{_val_str}/user-data"
                # kickstart
                case "inst.ks":
                    self.data.seed_urls = _val_str
                # autoyast
                case "autoyast":
                    self.data.seed_urls = _val_str
                # agama
                case "inst.auto":
                    self.data.seed_urls = _val_str
                # --- network parameter ---------------------------------------
                # hostname
                case "netcfg/get_hostname" | "hostname":
                    self.data.nwrk_host = _val_str
                # domain
                case "netcfg/get_domain" | "domain":
                    self.data.nwrk_wgrp = _val_str
                # network device name
                case "netcfg/choose_interface" | "interface":
                    self.data.nwrk_devs = _val_str
                # IPv4 address (emp=dhcp)
                case "netcfg/target_network_config":
                    self.data.ipv4_auto = True
                case "netcfg/disable_dhcp" | "netcfg/disable_autoconfig":
                    self.data.ipv4_auto = bool(_val_str.lower() != "true")
                case "netcfg/get_ipaddress":
                    self.data.ipv4_auto = False
                    self.data.ipv4_addr = _val_str
                # IPv4 subnetmask
                case "netcfg/get_netmask":
                    self.data.ipv4_mask = _val_str
                # IPv4 gateway
                case "netcfg/get_gateway":
                    self.data.ipv4_gway = _val_str
                # IPv4 nameserver
                case "netcfg/get_nameservers" | "nameserver":
                    self.data.ipv4_nsvr = _val_str
                case "ip" | "ip4" | "ipv4":
                    _list = str(_val_str + ":" * 8).split(":")
                    match _list[1].lower():
                        case "dhcp" | "dhcp4":
                            self.data.ipv4_auto = True
                            self.data.ipv4_addr = ""
                            self.data.ipv4_gway = ""
                            self.data.ipv4_mask = ""
                            self.data.nwrk_host = ""
                            self.data.nwrk_wgrp = ""
                            self.data.ipv4_nsvr = ""
                        case _:
                            self.data.ipv4_auto = False
                            self.data.ipv4_addr = _list[1] if _list[1] else None
                            self.data.ipv4_gway = _list[3] if _list[3] else None
                            self.data.ipv4_mask = _list[4] if _list[4] else None
                            self.data.nwrk_host = _list[5] if _list[5] else None
                            self.data.nwrk_wgrp = _list[6] if _list[6] else None
                            self.data.ipv4_nsvr = _list[8] if _list[8] else None
                case "ifcfg":
                    _list = str(_val_str + "=" * 1).split("=")
                    self.data.nwrk_devs = _list[1]
                    _list = str(_list[2] + "," * 4).split(",")
                    match _list[1].lower():
                        case "dhcp" | "dhcp4":
                            self.data.ipv4_auto = True
                            self.data.ipv4_addr = ""
                            self.data.ipv4_gway = ""
                            self.data.ipv4_nsvr = ""
                            self.data.nwrk_wgrp = ""
                        case "dhcp6":
                            self.data.ipv4_auto = ""
                            self.data.ipv4_addr = ""
                            self.data.ipv4_gway = ""
                            self.data.ipv4_nsvr = ""
                            self.data.nwrk_wgrp = ""
                        case _:
                            _val_str = re.sub(r"[^=]+=[^=]+=", "", _val_str)
                            _list = str(_val_str + "," * 4).split(",")
                            self.data.ipv4_auto = False
                            self.data.ipv4_addr = _list[1] if _list[1] else None
                            self.data.ipv4_gway = _list[2] if _list[2] else None
                            self.data.ipv4_nsvr = _list[3] if _list[3] else None
                            self.data.nwrk_wgrp = _list[4] if _list[4] else None
        self.data.tget_path = (
            self.data.tget_path
            if not self.data.tget_urls or "://" in self.data.tget_urls
            else Path(self.data.tget_urls)
        )
        self.data.isou_path = (
            None
            if not self.data.isou_urls or "://" in self.data.isou_urls
            else Path(self.data.isou_urls)
        )
        self.data.seed_path = (
            None
            if not self.data.seed_urls or "://" in self.data.seed_urls
            else Path(self.data.seed_urls)
        )
        # --- network ---------------------------------------------------------
        if not self.data.nwrk_devs:
            _base_path: Path = addpath(
                base=self.data.tget_path, path=Path("/sys/devices")
            )
            self.data.nwrk_devs = find_nic(base_path=_base_path)
        if "/" in str(self.data.ipv4_addr):
            self.data.ipv4_cidr = self.data.ipv4_addr
            self.data.ipv4_addr = ipv4_addr(cidr=self.data.ipv4_cidr)
            self.data.ipv4_prfx = ipv4_prfx(cidr=self.data.ipv4_cidr)
            self.data.ipv4_mask = ipv4_mask(cidr=self.data.ipv4_cidr)
        if not self.data.ipv4_addr:
            if self.data.ipv4_cidr:
                self.data.ipv4_addr = ipv4_addr(cidr=self.data.ipv4_cidr)
            else:
                self.data.ipv4_auto = "True"
        if not self.data.ipv4_prfx:
            if self.data.ipv4_cidr:
                self.data.ipv4_prfx = ipv4_prfx(cidr=self.data.ipv4_cidr)
            elif self.data.ipv4_mask:
                self.data.ipv4_prfx = ipv4_prfx(cidr=f"0.0.0.0/{self.data.ipv4_mask}")
            else:
                self.data.ipv4_prfx = "24"
        if not self.data.ipv4_mask:
            if self.data.ipv4_cidr:
                self.data.ipv4_mask = ipv4_mask(cidr=self.data.ipv4_cidr)
            elif self.data.ipv4_prfx:
                self.data.ipv4_mask = ipv4_prfx(cidr=f"0.0.0.0/{self.data.ipv4_prfx}")
            else:
                self.data.ipv4_mask = "255.255.255.0"
        if self.data.ipv4_addr and self.data.ipv4_prfx:
            self.data.ipv4_cidr = f"{self.data.ipv4_addr}/{self.data.ipv4_prfx}"
        self.data.ipv4_fadr = self.data.ipv4_cidr  # full addr
        if self.data.ipv4_addr:
            self.data.ipv4_uadr = ipv4_upper(addr=self.data.ipv4_addr)  # addr up
            self.data.ipv4_ladr = ipv4_lower(addr=self.data.ipv4_addr)  # addr low
            self.data.ipv4_radr = ipv4_reverse(addr=self.data.ipv4_addr)  # reverse
        # --- hostname --------------------------------------------------------
        if self.data.dist_name:
            self.data.nwrk_host = self.data.nwrk_host.replace(
                ":_DISTRO_:", self.data.dist_name
            )
        self.data.nwrk_fqdn = f"{self.data.nwrk_host}.{self.data.nwrk_wgrp}"

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
                        "prog_path"
                        | "prog_name"
                        | "dbgs_flag"
                        | "dout_flag"
                        | "dist_name"
                        | "dist_vers"
                        | "dist_code"
                        | "tget_virt"
                        | "tget_chrt"
                        | "tget_cntr"
                        | "parm_root"
                        | "parm_secu"
                        | "parm_armo"
                        | "parm_slnx"
                        | "tget_dirs"
                        | "tget_path"
                        | "tget_urls"
                        | "isou_path"
                        | "isou_urls"
                        | "nlin_dirs"
                        | "nlin_path"
                        | "samb_user"
                        | "samb_grup"
                        | "samb_gadm"
                        | "samb_nssw"
                        | "fwal_zone"
                        | "fwal_name"
                        | "fwal_port"
                        | "seed_path"
                        | "seed_urls"
                        | "nics_path"
                        | "nics_name"
                        | "nics_madr"
                        | "nics_gway"
                        | "nics_nsvr"
                        | "nics_fqdn"
                        | "nics_host"
                        | "nics_wgrp"
                        | "nics_stat"
                        | "nics_ipv4"
                        | "nics_ipv6"
                        | "nics_link"
                        | "ipv6_lhst"
                        | "ipv4_lhst"
                        | "ipv4_dumy"
                        | "ntps_fbak"
                        | "nwrk_devs"
                        | "nwrk_fqdn"
                        | "nwrk_host"
                        | "nwrk_wgrp"
                        | "nman_name"
                        | "ntps_addr"
                        | "ntps_ipv4"
                        | "ipv4_auto"
                        | "ipv4_addr"
                        | "ipv4_prfx"
                        | "ipv4_cidr"
                        | "ipv4_mask"
                        | "ipv4_fadr"
                        | "ipv4_uadr"
                        | "ipv4_ladr"
                        | "ipv4_radr"
                        | "ipv4_gway"
                        | "ipv4_nsvr"
                    ):
                        message_info(_caller, f"{_key}={_value or ''}", omit=True)
            message_info(_caller, f"{'*** end':<10}:Command line ***", omit=True)
