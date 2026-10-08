"""Global variables (shared)"""

# --- Python library ----------------------------------------------------------
from dataclasses import dataclass, fields
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import InfoConfiguration, InfoDistribution, InfoMedia
from common.utils import debug_logger


# ruff: isort: on
# =============================================================================
@dataclass
class Text_fmat:
    """Text data output format"""

    dist = (
        r"{version:<23} {name:<23} {version_id:<23} {code_name:<39} "
        r"{life:<15} {release:<15} {support:<15} {long_term:<15} "
        r"{rhel:<15} {kerne:<27} {note:<27} {wallpaper:<87} "
        r"{create_flag:<11} {sort_flag:<11} "
    )
    mdia = (
        r"{mdia_type:<11} "
        r"{entry_flag:<11} {entry_name:<39} {entry_disp:<39} "
        r"{version:<23} {latest:<23} {release:<15} {support:<15} "
        r"{web_regexp:<143} {web_path:<143} {web_tstamp:<47} {web_size:<15} "
        r"{web_check:<47} {web_status:<15} "
        r"{iso_path:<87} {iso_tstamp:<47} {iso_size:<15} {iso_volume:<43} "
        r"{rmk_path:<87} {rmk_tstamp:<47} {rmk_size:<15} {rmk_volume:<43} "
        r"{ldr_initrd:<87} {ldr_kernel:<87} {cfg_path:<87} {cfg_tstamp:<47} "
        r"{lnk_path:<87} {options:<59} {create_flag:<11} {target_flag:<11} "
    )


# -----------------------------------------------------------------------------
@dataclass
class CommonData:
    conf: InfoConfiguration | None = None
    dist: InfoDistribution | None = None
    mdia: InfoMedia | None = None
    text_fmat: Text_fmat | None = None
    conf_path: Path | None = None
    dist_path: Path | None = None
    mdia_path: Path | None = None
    conf_json: Path | None = None
    dist_json: Path | None = None
    mdia_json: Path | None = None


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
