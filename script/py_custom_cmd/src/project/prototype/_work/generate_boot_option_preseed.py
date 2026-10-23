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
def generate_boot_option_preseed(
    parameter, mdia_data: MediaData
) -> list[ConfigurationData]:
    _boot_options: list[ConfigurationData] = []
    # --- 0: server -----------------------------------------------------------
    #_boot_options.append(
    #    ConfigurationData(key="SRVR_TGET", value=parameter.srvr_http),
    #)
    # --- 1: autoinst ---------------------------------------------------------
    _work: str = ""
    if mdia_data.mdia_type == "live":
        _work += "boot=live"
    if mdia_data.cfg_path:
        _path_conf: str = re.sub(r"^.*(/[^/]+/[^/]+)$", r"\1", mdia_data.cfg_path)
        if not (
            not parameter.pxeboot and re.match(r"^.*-mini-.*$", mdia_data.entry_name)
        ):
            _work += "auto=true "
            if re.match(r"^ubuntu-(desktop|legacy)-.*$", mdia_data.entry_name):
                _work += "automatic-ubiquity noprompt "
            if parameter.pxeboot:
                _work += f"preseed/file=/url={parameter.srvr_http}/{_path_conf}"
            else:
                _work += f"preseed/file=/cdrom{_path_conf}"
    _boot_options.append(ConfigurationData(key="OPTN_AUTO", value=_work))
    # --- 2: language ---------------------------------------------------------
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
    # --- 3: network ----------------------------------------------------------
    _work: str = ""
    if not mdia_data.cfg_path:
        _work += "dhcp"
    else:
        if mdia_data.mdia_type == "live":
            _work += "dhcp"
        if re.match(r"^ubuntu-.*$", mdia_data.entry_name):
            _work += "netcfg/target_network_config=NetworkManager"
        _work += "netcfg/disable_autoconfig=true "
        _work += r"netcfg/choose_interface=${ethrname} "
        _work += r"netcfg/get_hostname=${hostname} "
        _work += r"netcfg/get_ipaddress=${ipv4addr} "
        _work += r"netcfg/get_netmask=${ipv4mask} "
        _work += r"netcfg/get_gateway=${ipv4gway} "
        _work += r"netcfg/get_nameservers=${ipv4nsvr}"
    _boot_options.append(ConfigurationData(key="OPTN_NWRK", value=_work))
    # --- 4: otheropt ---------------------------------------------------------
    _work: str = ""
    if mdia_data.options:
        _work += mdia_data.options.replace(r"%20", " ")
    _boot_options.append(ConfigurationData(key="OPTN_OTHR", value=_work))
    return _boot_options
