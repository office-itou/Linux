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
def generate_boot_option_kickstart(
    parameter, mdia_data: MediaData
) -> list[ConfigurationData]:
    _boot_options: list[ConfigurationData] = []
    # --- 0: server -------------------------------------------------------
    _boot_options.append(ConfigurationData(key="SRVR_TGET", value=parameter.srvr_http))
    # --- 1: autoinst -----------------------------------------------------
    _work: str = ""
    if mdia_data.cfg_path:
        _path_conf: str = re.sub(r"^.*\(/[^/]+/[^/]+\)$", mdia_data.cfg_path, r"\1")
        if parameter.pxeboot:
            _work += f"inst.ks={parameter.srvr_http}{_path_conf}"
        else:
            _work += f"inst.ks=hd:sr0:{_path_conf}"
    _boot_options.append(ConfigurationData(key="OPTN_AUTO", value=_work))
    # --- 2: language -----------------------------------------------------
    _work: str = ""
    _work += (
        "locale=ja_JP.UTF-8 timezone=Asia/Tokyo "
        "keyboard-configuration/layoutcode=jp "
        "keyboard-configuration/modelcode=jp106 "
        "language=ja_JP"
    )
    _boot_options.append(ConfigurationData(key="OPTN_LANG", value=_work))
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
    _boot_options.append(ConfigurationData(key="OPTN_NWRK", value=_work))
    # --- 4: otheropt -----------------------------------------------------
    _work: str = ""
    if not mdia_data.cfg_path:
        _work += (
            rf"root=live:${{srvrhttp}}/${parameter.path_imgs}/{mdia_data.entry_name}/LiveOS/squashfs.img"
            "rd.live.image rd.live.overlay.overlayfs=1"
        )
    else:
        _path_xnfs = parameter.path_xnfs / parameter.path_imgs / mdia_data.entry_name
        if parameter.pxeboot:
            _work += rf"inst.repo=nfs:${{srvraddr}}:{_path_xnfs}"
        else:
            _work += rf"inst.stage2=hd:LABEL={mdia_data.iso_volume}"
    if mdia_data.options:
        _work += mdia_data.options.replace(r"%20", " ")
    _boot_options.append(ConfigurationData(key="OPTN_OTHR", value=_work))
    return _boot_options
