#!/usr/bin/env python3
"""generate custom iso window"""

# --- python library ----------------------------------------------------------
import copy
import re

# import threading
from pathlib import Path
from typing import Any

# import aiohttp
# from aiohttp import ClientTimeout
# --- my library --------------------------------------------------------------
from common.shared import (
    InfoCommon,
    MediaData,
)

# from common.shared.my_distribution_dat import ORDERED_DISTRIBUTIONS
from common.utils import (
    debug_logger,
    fread,
    fwrite,
    find_grub_cfg,
    find_isolinux_cfg,
)


# =============================================================================
class GenerateBootMenu:
    @debug_logger
    def __init__(self, win) -> None:
        self.win: Any = win
        # --- processing block ------------------------------------------------
        self.pxeboot: bool = False
        self.info_comm: InfoCommon = win.info_comm
        # --- shared of user file ---------------------------------------------
        self.dirs_conf: str = self.info_comm.conf.find(key="DIRS_CONF").value
        self.dirs_isos: str = self.info_comm.conf.find(key="DIRS_ISOS").value
        self.dirs_imgs: str = self.info_comm.conf.find(key="DIRS_IMGS").value
        self.dirs_rmak: str = self.info_comm.conf.find(key="DIRS_RMAK").value
        self.dirs_xnfs: str = self.info_comm.conf.find(key="DIRS_XNFS").value
        self.path_isos: Path = self.info_comm.conf.get_path(key="DIRS_ISOS").name
        self.path_imgs: Path = self.info_comm.conf.get_path(key="DIRS_IMGS").name
        self.path_rmak: Path = self.info_comm.conf.get_path(key="DIRS_RMAK").name
        self.path_xnfs: Path = self.info_comm.conf.get_path(key="DIRS_XNFS").name
        # --- tftp / web server network self -----------------------------
        self.srvr_addr: str = self.info_comm.conf.find(key="SRVR_ADDR").value
        self.srvr_http: str = (
            f"{self.info_comm.conf.find(key='SRVR_HTTP').value}:{self.srvr_addr}"
        )
        self.srvr_prot: str = (
            f"{self.info_comm.conf.find(key='SRVR_PROT').value}:{self.srvr_addr}"
        )
        # --- network self -----------------------------------------------
        self.nwrk_host: str = self.info_comm.conf.find(key="NWRK_HOST").value
        self.nwrk_wgrp: str = self.info_comm.conf.find(key="NWRK_WGRP").value
        self.nics_name: str = self.info_comm.conf.find(key="NICS_NAME").value
        self.nics_madr: str = self.info_comm.conf.find(key="NICS_MADR").value
        self.ipv4_addr: str = self.info_comm.conf.find(key="IPV4_ADDR").value
        self.ipv4_cidr: str = self.info_comm.conf.find(key="IPV4_CIDR").value
        self.ipv4_mask: str = self.info_comm.conf.find(key="IPV4_MASK").value
        self.ipv4_gway: str = self.info_comm.conf.find(key="IPV4_GWAY").value
        self.ipv4_nsvr: str = self.info_comm.conf.find(key="IPV4_NSVR").value
        self.ipv4_uadr: str = self.info_comm.conf.find(key="IPV4_UADR").value
        self.nman_name: str = self.info_comm.conf.find(key="NMAN_NAME").value
        self.ntps_addr: str = self.info_comm.conf.find(key="NTPS_ADDR").value
        self.ntps_ipv4: str = self.info_comm.conf.find(key="NTPS_IPV4").value
        # --- function --------------------------------------------------------

    @debug_logger
    def generate_boot_option_preseed(
        self, mdia_data: MediaData
    ) -> list[dict[str, str]]:
        _boot_options: list[dict[str, str]] = []
        # --- 0: server -------------------------------------------------------
        _boot_options.append({"SRVR_PROT": self.srvr_http})
        # --- 1: autoinst -----------------------------------------------------
        _work: str = ""
        if mdia_data.mdia_type == "live":
            _work += "boot=live"
        if mdia_data.cfg_path:
            _path_conf: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.cfg_path, r"\1")
            if not (
                not self.pxeboot and re.match(r"^.*-mini-.*$", mdia_data.entry_name)
            ):
                _work += "auto=true "
                if re.match(r"^ubuntu-(desktop|legacy)-.*$", mdia_data.entry_name):
                    _work += "automatic-ubiquity noprompt "
                if self.pxeboot:
                    _work += f"preseed/file=/url={self.srvr_http}/{_path_conf}"
                else:
                    _work += f"preseed/file=/cdrom{_path_conf}"
        _boot_options.append({"OPTN_AUTO": _work})
        # --- 2: language -----------------------------------------------------
        _work: str = ""
        if mdia_data.mdia_type == "live":
            _work += (
                "utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo "
                "key-model=pc105 key-layouts=jp key-variants=OADG109A"
            )
        else:
            match mdia_data.entry_name:
                case s if re.match(r"^live-(debian|ubuntu)-.*$", s):
                    _work += (
                        "utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo "
                        "keyboard-layouts=jp,us "
                        "keyboard-model=pc105 keyboard-variants=,"
                    )
                case s if re.match(r"^debian-live-.*$", s):
                    _work += (
                        "utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo "
                        "key-model=pc105 key-layouts=jp key-variants=OADG109A"
                    )
                case s if re.match(r"^ubuntu-(desktop|legacy).*$", s):
                    _work += (
                        "debian-installer/locale=ja_JP.UTF-8 "
                        "keyboard-configuration/layoutcode=jp "
                        "keyboard-configuration/modelcode=jp106"
                    )
                case _:
                    _work = (
                        "language=ja country=JP timezone=Asia/Tokyo "
                        "keyboard-configuration/xkb-keymap=jp "
                        "keyboard-configuration/variant=Japanese"
                    )
        _boot_options.append({"OPTN_LANG": _work})
        # --- 3: network ------------------------------------------------------
        _work: str = ""
        if not mdia_data.cfg_path:
            _work += "dhcp"
        else:
            if mdia_data.mdia_type == "live":
                _work += "dhcp"
            if re.match(r"^ubuntu-.*$", mdia_data.entry_name):
                _work += "netcfg/target_network_config=NetworkManager"
            _work += "netcfg/disable_autoconfig=true"
            _work += r"netcfg/choose_interface=${ethrname}"
            _work += r"netcfg/get_hostname=${hostname}"
            _work += r"netcfg/get_ipaddress=${ipv4addr}"
            _work += r"netcfg/get_netmask=${ipv4mask}"
            _work += r"netcfg/get_gateway=${ipv4gway}"
            _work += r"netcfg/get_nameservers=${ipv4nsvr}"
        _boot_options.append({"OPTN_NWRK": _work})
        # --- 4: otheropt -----------------------------------------------------
        _work: str = ""
        if mdia_data.options:
            _work += mdia_data.options.replace(r"%20", " ")
        _boot_options.append({"OPTN_OTHR": _work})
        return _boot_options

    @debug_logger
    def generate_boot_option_nocloud(
        self, mdia_data: MediaData
    ) -> list[dict[str, str]]:
        _boot_options: list[dict[str, str]] = []
        # --- 0: server -------------------------------------------------------
        _boot_options.append({"SRVR_PROT": self.srvr_http})
        # --- 1: autoinst -----------------------------------------------------
        _work: str = ""
        if mdia_data.mdia_type == "live":
            _work += "boot=casper"
        if mdia_data.cfg_path:
            _path_conf: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.cfg_path, r"\1")
            _work += (
                "automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null "
            )
            if self.pxeboot:
                _work += f"ds=nocloud;s=/{self.srvr_http}{_path_conf}"
            else:
                _work += f"ds=nocloud;s=/cdrom{_path_conf}"
        _boot_options.append({"OPTN_AUTO": _work})
        # --- 2: language -----------------------------------------------------
        _work: str = ""
        if mdia_data.mdia_type == "live":
            _work += (
                "utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo "
                "key-model=pc105 key-layouts=jp key-variants=OADG109A"
            )
        else:
            match mdia_data.entry_name:
                case s if re.match(r"^live-(debian|ubuntu)-.*$", s):
                    _work += (
                        "utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo "
                        "keyboard-layouts=jp,us "
                        "keyboard-model=pc105 keyboard-variants=,"
                    )
                case s if re.match(r"^debian-live-.*$", s):
                    _work += (
                        "utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo "
                        "key-model=pc105 key-layouts=jp key-variants=OADG109A"
                    )
                case s if re.match(r"^ubuntu-(desktop|legacy).*$", s):
                    _work += (
                        "debian-installer/locale=ja_JP.UTF-8 "
                        "keyboard-configuration/layoutcode=jp "
                        "keyboard-configuration/modelcode=jp106"
                    )
                case _:
                    _work = (
                        "language=ja country=JP timezone=Asia/Tokyo "
                        "keyboard-configuration/xkb-keymap=jp "
                        "keyboard-configuration/variant=Japanese"
                    )
        _boot_options.append({"OPTN_LANG": _work})
        # --- 3: network ------------------------------------------------------
        _work: str = ""
        if not mdia_data.cfg_path:
            _work += "dhcp"
        else:
            if mdia_data.mdia_type == "live":
                _work += "dhcp"
            if re.match(r"^ubuntu-live-18\.04$", mdia_data.entry_name):
                _work += (
                    r"ip=${ethrname},${ipv4addr},${ipv4mask},${ipv4gway} "
                    r"hostname=${hostname}"
                )
            else:
                _work += (
                    r"ip=${ipv4addr}:${rootserv}:${ipv4gway}:${ipv4mask}:"
                    r"${hostname}:${ethrname}:${_IPV4_ADDR:+static}:${ipv4nsvr}"
                )
                if self.ipv4_addr:
                    _work += "static"
                _work += r":${ipv4nsvr}"
        _boot_options.append({"OPTN_NWRK": _work})
        # --- 4: otheropt -----------------------------------------------------
        _work: str = ""
        _work += "root=/dev/ram0"
        _path_initrd: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.ldr_initrd, r"\1")
        _path_kernel: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.ldr_kernel, r"\1")
        _path_isos: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.iso_path, r"\1")
        _path_rmak: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.rmak_path, r"\1")
        if self.pxeboot:
            match mdia_data.entry_name:
                case s if re.match(r"^(debian|ubuntu)-mini-.*$", s):
                    _work += (
                        rf"initrd=${{srvrhttp}}/{_path_initrd} "
                        rf"iso-url=${{srvrhttp}}/{_path_isos}"
                    )
                case s if re.match(
                    r"^ubuntu-((desktop|live)-(18|20|22)\.*)|(server|legacy)-.*$", s
                ):
                    _work += rf"boot=casper url=${{srvrhttp}}/{_path_isos}"
                case s if re.match(r"^ubuntu-.*$", s):
                    _work += rf"boot=casper iso-url=${{srvrhttp}}/{_path_isos}"
                case s if re.match(r"^live-.*$", s):
                    _work += rf"fetch=${{srvrhttp}}/{_path_rmak}"
                case _:
                    _work += rf"fetch=${{srvrhttp}}/{_path_isos}"
        if mdia_data.options:
            _work += mdia_data.options.replace(r"%20", " ")
        _boot_options.append({"OPTN_OTHR": _work})
        return _boot_options

    @debug_logger
    def generate_boot_option_kickstart(
        self, mdia_data: MediaData
    ) -> list[dict[str, str]]:
        _boot_options: list[dict[str, str]] = []
        # --- 0: server -------------------------------------------------------
        _boot_options.append({"SRVR_PROT": self.srvr_http})
        # --- 1: autoinst -----------------------------------------------------
        _work: str = ""
        if mdia_data.cfg_path:
            _path_conf: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.cfg_path, r"\1")
            if self.pxeboot:
                _work += f"inst.ks={self.srvr_http}{_path_conf}"
            else:
                _work += f"inst.ks=hd:sr0:{_path_conf}"
        _boot_options.append({"OPTN_AUTO": _work})
        # --- 2: language -----------------------------------------------------
        _work: str = ""
        _work += (
            "locale=ja_JP.UTF-8 timezone=Asia/Tokyo "
            "keyboard-configuration/layoutcode=jp "
            "keyboard-configuration/modelcode=jp106 "
            "language=ja_JP"
        )
        _boot_options.append({"OPTN_LANG": _work})
        # --- 3: network ------------------------------------------------------
        _work: str = ""
        if not mdia_data.cfg_path:
            _work += "dhcp"
        else:
            if mdia_data.mdia_type == "live":
                _work += "dhcp"
            _work += (
                r"ip=${ipv4addr}::${ipv4gway}:${ipv4mask}:${hostname}:"
                r"${ethrname}:none,auto6 nameserver=${ipv4nsvr}"
            )
        _boot_options.append({"OPTN_NWRK": _work})
        # --- 4: otheropt -----------------------------------------------------
        _work: str = ""
        if not mdia_data.cfg_path:
            _work += (
                rf"root=live:${{srvrhttp}}/${self.path_imgs}/{mdia_data.entry_name}/LiveOS/squashfs.img"
                "rd.live.image rd.live.overlay.overlayfs=1"
            )
        else:
            _path_xnfs = self.path_xnfs / self.path_imgs / mdia_data.entry_name
            if self.pxeboot:
                _work += rf"inst.repo=nfs:${{srvraddr}}:{_path_xnfs}"
            else:
                _work += rf"inst.stage2=hd:LABEL={mdia_data.iso_volume}"
        if mdia_data.options:
            _work += mdia_data.options.replace(r"%20", " ")
        _boot_options.append({"OPTN_OTHR": _work})
        return _boot_options

    @debug_logger
    def generate_boot_option_autoyast(
        self, mdia_data: MediaData
    ) -> list[dict[str, str]]:
        _boot_options: list[dict[str, str]] = []
        # --- 0: server -------------------------------------------------------
        _boot_options.append({"SRVR_PROT": self.srvr_http})
        # --- 1: autoinst -----------------------------------------------------
        _work: str = ""
        if mdia_data.cfg_path:
            _path_conf: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.cfg_path, r"\1")
            if self.pxeboot:
                _work += (
                    f"autoyast={self.srvr_http}{_path_conf.replace('_dvd', '_web')}"
                )
            else:
                _work += f"autoyast=cd:{_path_conf}"
        _boot_options.append({"OPTN_AUTO": _work})
        # --- 2: language -----------------------------------------------------
        _work: str = ""
        _work += "language=ja_JP"
        _boot_options.append({"OPTN_LANG": _work})
        # --- 3: network ------------------------------------------------------
        _work: str = ""
        if not mdia_data.cfg_path:
            _work += "dhcp"
        else:
            if mdia_data.mdia_type == "live":
                _work += "dhcp"
            _work += (
                r"netsetup=dhcp hostname=${{hostname}} "
                r"ifcfg=${{ethrname}}=${{ipv4addr}},${{ipv4gway}},${{ipv4nsvr}},"
                rf"{self.nwrk_wgrp}"
            )
        _boot_options.append({"OPTN_NWRK": _work})
        # --- 4: otheropt -----------------------------------------------------
        _work: str = ""
        if self.pxeboot:
            match mdia_data.entry_name:
                case s if re.match(r"^opensuse-leap-netinst-[0-9.]+$", s):
                    _vers: str = re.sub(
                        r"^.*-\([0-9.]+\)$", mdia_data.entry_name, r"\1"
                    )
                    _work += rf"install=https://download.opensuse.org/distribution/leap/{_vers}/repo/oss/"
                case s if re.match(r"^opensuse-tumbleweed-netinst$", s):
                    _work += (
                        "install=https://download.opensuse.org/tumbleweed/repo/oss/"
                    )
                case _:
                    _path_xnfs = self.path_xnfs / self.path_imgs / mdia_data.entry_name
                    _work += rf"install=nfs://${{srvraddr}}{_path_xnfs}"
        if mdia_data.options:
            _work += mdia_data.options.replace(r"%20", " ")
        _boot_options.append({"OPTN_OTHR": _work})
        return _boot_options

    @debug_logger
    def generate_boot_option_agama(self, mdia_data: MediaData) -> list[dict[str, str]]:
        _boot_options: list[dict[str, str]] = []
        # --- 0: server -------------------------------------------------------
        _boot_options.append({"SRVR_PROT": self.srvr_http})
        # --- 1: autoinst -----------------------------------------------------
        _work: str = ""
        if mdia_data.cfg_path:
            _path_conf: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.cfg_path, r"\1")
            _work += "live.password=install inst.auto="
            if self.pxeboot:
                _work += rf"${{srvrhttp}}/{_path_conf.replace('_dvd', '_web')}"
            else:
                _work += rf"dvd:{_path_conf}?devices=sr0"
        _boot_options.append({"OPTN_AUTO": _work})
        # --- 2: language -----------------------------------------------------
        _work: str = ""
        _work += "language=ja_JP"
        _boot_options.append({"OPTN_LANG": _work})
        # --- 3: network ------------------------------------------------------
        _work: str = ""
        if not mdia_data.cfg_path:
            _work += "dhcp"
        else:
            if mdia_data.mdia_type == "live":
                _work += "dhcp"
            _work += (
                r"netsetup=dhcp hostname=${{hostname}} "
                r"ifcfg=${{ethrname}}=${{ipv4addr}},${{ipv4gway}},${{ipv4nsvr}},"
                rf"{self.nwrk_wgrp}"
            )
        _boot_options.append({"OPTN_NWRK": _work})
        # --- 4: otheropt -----------------------------------------------------
        _work: str = ""
        if not mdia_data.cfg_path:
            if self.pxeboot:
                _path_isos: str = re.sub(
                    r"^.*\(/[^/]+/[^/]+\)$", mdia_data.iso_path, r"\1"
                )
                _work += rf"root=live:${{srvrhttp}}/{_path_isos}"
        if mdia_data.options:
            _work += mdia_data.options.replace(r"%20", " ")
        _boot_options.append({"OPTN_OTHR": _work})
        return _boot_options

    def generate_boot_menu_grub(
        self, conf_path: Path, option: list[dict[str, str]]
    ) -> None:
        if not conf_path:
            return
        _conf_dir: Path = conf_path.parent
        _autoinst_cfg_path = _conf_dir / self.info_comm.conf.get_path(key="AUTO_INST")
        _theme_cfg_path: Path = _conf_dir / "theme.cfg"
        _autoinst_cfg_template_path = self.info_comm.conf.get_path(key="PATH_GAUT")
        _theme_cfg_template_path = self.info_comm.conf.get_path(key="PATH_GTHM")
        _list_parm: list[dict[str, str]] = copy.deepcopy(
            self.info_comm.conf.data
        ) + copy.deepcopy(option)
        # --- grub theme.cfg --------------------------------------------------
        _read_data = fread(_theme_cfg_template_path)
        _var_pattern: re.Pattern[str] = re.compile(r":_([A-Z0-9_]+)_:")
        _conv_dist: str = _var_pattern.sub(
            lambda m: str(self.info_comm.conf.find(key=m.group(1)).value), _read_data
        )
        write_data: str = "\n".join(_conv_dist) + "\n"
        fwrite(_theme_cfg_path, write_data, text=True, backup=True)
        # --- grub autoinst.cfg -----------------------------------------------
        _read_data = fread(_autoinst_cfg_template_path)
        _var_pattern: re.Pattern[str] = re.compile(r":_([A-Z0-9_]+)_:")
        _conv_dist: str = _var_pattern.sub(
            lambda m: str(self.info_comm.conf.find(key=m.group(1)).value), _read_data
        )
        write_data: str = "\n".join(_conv_dist) + "\n"
        fwrite(_autoinst_cfg_path, write_data, text=True, backup=True)

    def generate_boot_menu_ilnx(
        self, conf_path: Path, option: list[dict[str, str]]
    ) -> None:
        if not conf_path:
            return
        _conf_dir: Path = conf_path.parent
        _autoinst_cfg_path = _conf_dir / self.info_comm.conf.get_path(key="AUTO_INST")
        _theme_cfg_path: Path = _conf_dir / "theme.cfg"
        _autoinst_cfg_template_path = self.info_comm.conf.get_path(key="PATH_IAUT")
        _theme_cfg_template_path = self.info_comm.conf.get_path(key="PATH_ITHM")

    def generate_boot_menu(self, imgs_path: Path, mdia_data: MediaData) -> None:
        _option: list[dict[str, str]] = []
        match mdia_data.cfg_path:
            case s if re.match(r"^.*/preseed/[^-]*$", s):
                _option = self.generate_boot_option_preseed(mdia_data=mdia_data)
            case s if re.match(r"^.*/nocloud/[^-]*$", s):
                _option = self.generate_boot_option_nocloud(mdia_data=mdia_data)
            case s if re.match(r"^.*/kickstart/[^-]*$", s):
                _option = self.generate_boot_option_kickstart(mdia_data=mdia_data)
            case s if re.match(r"^.*/autoyast/[^-]*$", s):
                _option = self.generate_boot_option_autoyast(mdia_data=mdia_data)
            case s if re.match(r"^.*/agama/[^-]*$", s):
                _option = self.generate_boot_option_agama(mdia_data=mdia_data)
            case _:
                pass
        _grub_cfg_path = find_grub_cfg(imgs_path)
        _ilnx_cfg_path = find_isolinux_cfg(imgs_path)
        self.generate_boot_menu_grub(conf_path=_grub_cfg_path, option=_option)
        self.generate_boot_menu_ilnx(conf_path=_ilnx_cfg_path, option=_option)


# --- eof ---------------------------------------------------------------------
