"""generate boot option preseed"""

# --- python library ----------------------------------------------------------
import re

# --- my library --------------------------------------------------------------
from common.shared import (
    ConfigurationData,
    MediaData,
)
from common.utils import (
    debug_logger,
)


# ruff: isort: on
# --- gui window module -------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
@debug_logger
def generate_boot_option_nocloud(
    parameter, mdia_data: MediaData
) -> list[ConfigurationData]:
    _boot_options: list[ConfigurationData] = []
    # --- 0: server -------------------------------------------------------
    #_boot_options.append(
    #    ConfigurationData(key="SRVR_TGET", value=parameter.srvr_http),
    #)
    # --- 1: autoinst -----------------------------------------------------
    _work: str = ""
    if mdia_data.mdia_type == "live":
        _work += "boot=casper"
    if mdia_data.cfg_path:
        _path_conf: str = re.sub(r"^.*(/[^/]+/[^/]+)$", r"\1", mdia_data.cfg_path)
        _work += "automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null "
        if parameter.pxeboot:
            _work += f"ds=nocloud;s=/{parameter.srvr_http}{_path_conf}"
        else:
            _work += f"ds=nocloud;s=/cdrom{_path_conf}"
    _boot_options.append(ConfigurationData(key="OPTN_AUTO", value=_work))
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
    _boot_options.append(ConfigurationData(key="OPTN_LANG", value=_work))
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
                r"${hostname}:${ethrname}:"
            )
            if parameter.ipv4_addr:
                _work += "static"
            _work += r":${ipv4nsvr}"
    _boot_options.append(ConfigurationData(key="OPTN_NWRK", value=_work))
    # --- 4: otheropt -----------------------------------------------------
    _work: str = ""
    _work += "root=/dev/ram0"
    _path_initrd: str = re.sub(r"^.*(/[^/]+/[^/]+)$", r"\1", mdia_data.ldr_initrd)
    _path_kernel: str = re.sub(r"^.*(/[^/]+/[^/]+)$", r"\1", mdia_data.ldr_kernel)
    _path_isos: str = re.sub(r"^.*(/[^/]+/[^/]+)$", r"\1", mdia_data.iso_path)
    _path_rmak: str = re.sub(r"^.*(/[^/]+/[^/]+)$", r"\1", mdia_data.rmk_path)
    if parameter.pxeboot:
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
    _boot_options.append(ConfigurationData(key="OPTN_OTHR", value=_work))
    return _boot_options
