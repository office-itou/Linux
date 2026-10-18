"""generate custom iso window"""

# --- python library ----------------------------------------------------------
import re
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.shared import (
    ConfigurationData,
    InfoCommon,
    MediaData,
)
from common.utils import (
    debug_logger,
)

# --- gui window module -------------------------------------------------------
from generate_boot_option_agama import generate_boot_option_agama
from generate_boot_option_autoyast import generate_boot_option_autoyast
from generate_boot_option_kickstart import generate_boot_option_kickstart
from generate_boot_option_nocloud import generate_boot_option_nocloud
from generate_boot_option_preseed import generate_boot_option_preseed


class GenerateBootOption:
    @debug_logger
    def __init__(self) -> None:
        # --- processing block ------------------------------------------------
        self.pxeboot: bool = False
        self.info_comm: InfoCommon = InfoCommon()
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
        # --- tftp / web server network parameter -----------------------------
        self.srvr_addr: str = self.info_comm.conf.find(key="SRVR_ADDR").value
        self.srvr_http: str = (
            f"{self.info_comm.conf.find(key='SRVR_HTTP').value}:{self.srvr_addr}"
        )
        self.srvr_prot: str = (
            f"{self.info_comm.conf.find(key='SRVR_PROT').value}:{self.srvr_addr}"
        )
        # --- network parameter -----------------------------------------------
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
    def generate_boot_option(self, mdia_data: MediaData) -> list[ConfigurationData]:
        _boot_options: list[ConfigurationData] = []
        match mdia_data.cfg_path:
            case s if re.match(r"^.*/preseed/[^-]*$", s):
                _boot_options = generate_boot_option_preseed(self, mdia_data=mdia_data)
            case s if re.match(r"^.*/nocloud/[^-]*$", s):
                _boot_options = generate_boot_option_nocloud(self, mdia_data=mdia_data)
            case s if re.match(r"^.*/kickstart/[^-]*$", s):
                _boot_options = generate_boot_option_kickstart(
                    self, mdia_data=mdia_data
                )
            case s if re.match(r"^.*/autoyast/[^-]*$", s):
                _boot_options = generate_boot_option_autoyast(self, mdia_data=mdia_data)
            case s if re.match(r"^.*/agama/[^-]*$", s):
                _boot_options = generate_boot_option_agama(self, mdia_data=mdia_data)
            case _:
                pass
        return _boot_options
