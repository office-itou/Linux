"""generate custom iso window"""

# --- python library ----------------------------------------------------------
import re
from datetime import datetime
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.shared import (
    ConfigurationData,
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
    def __init__(self, info_comm) -> None:
        # --- processing block ------------------------------------------------
        self.info_comm = info_comm
        self.pxeboot: bool = False
        # --- shared of user file ---------------------------------------------
        self.dirs_conf: str = self.info_comm.conf.find(key="DIRS_CONF").value
        self.dirs_isos: str = self.info_comm.conf.find(key="DIRS_ISOS").value
        self.dirs_imgs: str = self.info_comm.conf.find(key="DIRS_IMGS").value
        self.dirs_rmak: str = self.info_comm.conf.find(key="DIRS_RMAK").value
        self.dirs_xnfs: str = self.info_comm.conf.find(key="DIRS_XNFS").value
        self.path_isos: Path = self.info_comm.conf.get_path(key="DIRS_ISOS")
        self.path_imgs: Path = self.info_comm.conf.get_path(key="DIRS_IMGS")
        self.path_rmak: Path = self.info_comm.conf.get_path(key="DIRS_RMAK")
        self.path_xnfs: Path = self.info_comm.conf.get_path(key="DIRS_XNFS")
        self.path_load: Path = self.info_comm.conf.get_path(key="DIRS_LOAD")
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
        self.ipv4_prfx: str = self.info_comm.conf.find(key="IPV4_PRFX").value
        self.ipv4_cidr: str = self.info_comm.conf.find(key="IPV4_CIDR").value
        self.ipv4_mask: str = self.info_comm.conf.find(key="IPV4_MASK").value
        self.ipv4_gway: str = self.info_comm.conf.find(key="IPV4_GWAY").value
        self.ipv4_nsvr: str = self.info_comm.conf.find(key="IPV4_NSVR").value
        self.ipv4_uadr: str = self.info_comm.conf.find(key="IPV4_UADR").value
        self.nman_name: str = self.info_comm.conf.find(key="NMAN_NAME").value
        self.ntps_addr: str = self.info_comm.conf.find(key="NTPS_ADDR").value
        self.ntps_ipv4: str = self.info_comm.conf.find(key="NTPS_IPV4").value
        # --- function --------------------------------------------------------

    def _get_loader(self, mdia_data: MediaData) -> tuple:
        _load_dire: Path = self.path_load / Path(mdia_data.entry_name)
        _load_fird: Path = Path(mdia_data.ldr_initrd)
        _load_fkrl: Path = Path(mdia_data.ldr_kernel)
        _load_fird = Path("/") / (
            _load_fird.relative_to(_load_dire)
            if _load_fird.is_relative_to(_load_dire)
            else _load_fird
        )
        _load_fkrl = Path("/") / (
            _load_fkrl.relative_to(_load_dire)
            if _load_fkrl.is_relative_to(_load_dire)
            else _load_fkrl
        )
        return (_load_fird, _load_fkrl)

    @debug_logger
    def generate_boot_option(self, mdia_data: MediaData) -> list[ConfigurationData]:
        _boot_options: list[ConfigurationData] = []
        _work = re.sub(r"^([^-]+).+$", r"\1", mdia_data.entry_name)
        for d in self.info_comm.conf.data:
            if d.key == "IPV4_CIDR":
                d.value = (
                    f"{self.ipv4_addr}"
                    if _work == "ubuntu"
                    else f"{self.ipv4_addr}/{self.ipv4_prfx}"
                )
                self.ipv4_cidr = d.value
                break
        _boot_options.append(ConfigurationData(key="DISTRO", value=_work))
        _boot_options.append(ConfigurationData(key="VESA32", value="vesamenu.c32"))
        _boot_options.append(ConfigurationData(key="DTPIMG", value="splash.png"))
        _load_fird, _load_fkrl = self._get_loader(mdia_data=mdia_data)
        _boot_options.append(ConfigurationData(key="PATH_FIRD", value=str(_load_fird)))
        _boot_options.append(ConfigurationData(key="PATH_FKNL", value=str(_load_fkrl)))
        _time: datetime = datetime.fromisoformat(mdia_data.iso_tstamp)
        _work = (
            f"{Path(mdia_data.iso_path).name} "
            f"{_time.strftime('%Y/%m/%d %H:%M:%S %Z (%z)')}"
        )
        _boot_options.append(ConfigurationData(key="TITL_TEXT", value=_work))
        _boot_options.append(ConfigurationData(key="SRVR_TGET", value=self.srvr_http))
        _list_options = []
        match mdia_data.cfg_path:
            case s if re.match(r"^.*/preseed/[^-]*$", s):
                _list_options = generate_boot_option_preseed(self, mdia_data=mdia_data)
            case s if re.match(r"^.*/nocloud/[^-]*$", s):
                _list_options = generate_boot_option_nocloud(self, mdia_data=mdia_data)
            case s if re.match(r"^.*/kickstart/[^-]*$", s):
                _list_options = generate_boot_option_kickstart(
                    self, mdia_data=mdia_data
                )
            case s if re.match(r"^.*/autoyast/[^-]*$", s):
                _list_options = generate_boot_option_autoyast(self, mdia_data=mdia_data)
            case s if re.match(r"^.*/agama/[^-]*$", s):
                _list_options = generate_boot_option_agama(self, mdia_data=mdia_data)
            case _:
                pass
        _boot_options += _list_options
        _work = " ".join(d.value for d in _list_options).strip()
        _work = _work.replace(r"${ethrname}", self.nics_name)
        _work = _work.replace(r"${hostname}", self.nwrk_host)
        _work = _work.replace(r"${ipv4addr}", self.ipv4_addr)
        _work = _work.replace(r"${ipv4mask}", self.ipv4_mask)
        _work = _work.replace(r"${ipv4gway}", self.ipv4_gway)
        _work = _work.replace(r"${ipv4nsvr}", self.ipv4_nsvr)
        _boot_options.append(ConfigurationData(key="BOPT_ALLS", value=_work))
        return _boot_options
