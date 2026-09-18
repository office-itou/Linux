"""Global variables (shared)"""

# --- Python library ----------------------------------------------------------
from dataclasses import dataclass, fields
from pathlib import Path

# --- my library --------------------------------------------------------------
from ..shared.my_common_cfg import InfoConfiguration
from ..shared.my_distribution_dat import InfoDistribution
from ..shared.my_media_dat import InfoMedia
from ..utils.my_debug import debug_logger


# =============================================================================
@dataclass
class Text_fmat:
    """Text data output format"""

    dist = r"{version:<23} {name:<23} {version_id:<23} {code_name:<39} {life:<15} {release:<15} {support:<15} {long_term:<15} {rhel:<15} {kerne:<27} {note:<27} {wallpaper:<87} {create_flag:<11} {sort_flag:<11} "
    mdia = r"{type:<11} {entry_flag:<11} {entry_name:<39} {entry_disp:<39} {version:<23} {latest:<23} {release:<15} {support:<15} {web_regexp:<143} {web_path:<143} {web_tstamp:<47} {web_size:<15} {web_check:<47} {web_status:<15} {iso_path:<87} {iso_tstamp:<47} {iso_size:<15} {iso_volume:<43} {rmk_path:<87} {rmk_tstamp:<47} {rmk_size:<15} {rmk_volume:<43} {ldr_initrd:<87} {ldr_kernel:<87} {cfg_path:<87} {cfg_tstamp:<47} {lnk_path:<87} {options:<59} {create_flag:<11} "


# -----------------------------------------------------------------------------
@dataclass
class CommonData:
    conf: InfoConfiguration = None
    dist: InfoDistribution = None
    mdia: InfoMedia = None
    text_fmat: Text_fmat = None
    conf_path: Path = None
    dist_path: Path = None
    mdia_path: Path = None
    conf_json: Path = None
    dist_json: Path = None
    mdia_json: Path = None


class InfoCommon:
    """InfoCommon interface class"""

    @debug_logger
    def __init__(self) -> None:
        """Method for initializing the data class."""
        self._valid_fields: set[str] = {f.name for f in fields(CommonData)}
        # ---------------------------------------------------------------------
        self.conf = InfoConfiguration()
        self.conf_path = Path(self.conf.get_path(key="PATH_CONF"))
        self.dist_path = Path(self.conf.get_path(key="PATH_DIST"))
        self.mdia_path = Path(self.conf.get_path(key="PATH_MDIA"))
        self.conf_json = self.conf_path.with_suffix(self.conf_path.suffix + ".json")
        self.dist_json = self.dist_path.with_suffix(self.dist_path.suffix + ".json")
        self.mdia_json = self.mdia_path.with_suffix(self.mdia_path.suffix + ".json")
        self.dist = InfoDistribution(self.dist_json)
        self.mdia = InfoMedia(self.mdia_json, self.conf)
        self.text_fmat = Text_fmat()


# --- eof ---------------------------------------------------------------------
