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
class ConfData:
    info: InfoConfiguration = None
    path: Path = None
    json: Path = None


@dataclass
class DistData:
    info: InfoDistribution = None
    path: Path = None
    json: Path = None


@dataclass
class MdiaData:
    info: InfoMedia = None
    path: Path = None
    json: Path = None


# -----------------------------------------------------------------------------
@dataclass
class CommonData:
    conf: ConfData = None
    dist: DistData = None
    mdia: MdiaData = None
    text_fmat: Text_fmat = None


class InfoCommon:
    """InfoCommon interface class"""

    @debug_logger
    def __init__(self) -> None:
        """Method for initializing the data class."""
        self._valid_fields: set[str] = {f.name for f in fields(CommonData)}
        # ---------------------------------------------------------------------
        _info_configuration = InfoConfiguration()
        _conf_path = _info_configuration.get_path(key="PATH_CONF")
        _dist_path = _info_configuration.get_path(key="PATH_DIST")
        _mdia_path = _info_configuration.get_path(key="PATH_MDIA")
        # ---------------------------------------------------------------------
        self.conf = ConfData(
            info=_info_configuration,
            path=_conf_path,
            json=_conf_path.with_suffix(_conf_path.suffix + ".json"),
        )
        self.dist = DistData(
            info=InfoDistribution(_dist_path.with_suffix(_dist_path.suffix + ".json")),
            path=_dist_path,
            json=_dist_path.with_suffix(_dist_path.suffix + ".json"),
        )
        self.mdia = MdiaData(
            info=InfoMedia(
                _mdia_path.with_suffix(_mdia_path.suffix + ".json"), self.conf.info
            ),
            path=_mdia_path,
            json=_mdia_path.with_suffix(_mdia_path.suffix + ".json"),
        )
        # ---------------------------------------------------------------------
        self.text_fmat = Text_fmat()
        # ---------------------------------------------------------------------
        self.data = CommonData(
            conf=self.conf, dist=self.dist, mdia=self.mdia, text_fmat=self.text_fmat
        )


# --- eof ---------------------------------------------------------------------
