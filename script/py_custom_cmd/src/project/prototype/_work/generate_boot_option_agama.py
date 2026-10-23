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
def generate_boot_option_agama(
    parameter, mdia_data: MediaData
) -> list[ConfigurationData]:
    _boot_options: list[ConfigurationData] = []
    # --- 0: server -------------------------------------------------------
    #_boot_options.append(
    #    ConfigurationData(key="SRVR_TGET", value=parameter.srvr_http),
    #)
    # --- 1: autoinst -----------------------------------------------------
    _work: str = ""
    if mdia_data.cfg_path:
        _path_conf: str = re.sub(r"^.*(/[^/]+/[^/]+)$", r"\1", mdia_data.cfg_path)
        _work += "live.password=install inst.auto="
        if parameter.pxeboot:
            _work += rf"${{srvrhttp}}/{_path_conf.replace('_dvd', '_web')}"
        else:
            _work += rf"dvd:{_path_conf}?devices=sr0"
    _boot_options.append(ConfigurationData(key="OPTN_AUTO", value=_work))
    # --- 2: language -----------------------------------------------------
    _work: str = ""
    _work += "language=ja_JP"
    _boot_options.append(ConfigurationData(key="OPTN_LANG", value=_work))
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
            rf"{parameter.nwrk_wgrp}"
        )
    _boot_options.append(ConfigurationData(key="OPTN_NWRK", value=_work))
    # --- 4: otheropt -----------------------------------------------------
    _work: str = ""
    if not mdia_data.cfg_path:
        if parameter.pxeboot:
            _path_isos: str = re.sub(r"^.*(/[^/]+/[^/]+)$", r"\1", mdia_data.iso_path)
            _work += rf"root=live:${{srvrhttp}}/{_path_isos}"
    if mdia_data.options:
        _work += mdia_data.options.replace(r"%20", " ")
    _boot_options.append(ConfigurationData(key="OPTN_OTHR", value=_work))
    return _boot_options
