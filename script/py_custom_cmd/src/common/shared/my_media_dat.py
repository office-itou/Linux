###############################################################################
#
# 	media.dat I/O
#
# 	developer   : J.Itou
# 	release     : 2026/09/03
#
# 	history     :
# 	   data    version    developer    point
# 	---------- -------- -------------- ----------------------------------------
# 	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
import json
from dataclasses import asdict, dataclass, fields
from typing import Any

# --- my library --------------------------------------------------------------
from ..utils.my_colors import Color
from ..utils.my_config import infosystem
from ..utils.my_debug import debug_logger
from ..utils.my_fileio import get_text2list, put_list2text
from ..utils.my_markdown import list2markdown
from ..utils.my_string import eprint, spc_decode, spc_encode
from .my_common_cfg import InfoConfiguration


# -----------------------------------------------------------------------------
@dataclass
class MediaData:
    type: str = ""
    entry_flag: str = ""
    entry_name: str = ""
    entry_disp: str = ""
    version: str = ""
    latest: str = ""
    release: str = ""
    support: str = ""
    web_regexp: str = ""
    web_path: str = ""
    web_tstamp: str = ""
    web_size: str = ""
    web_check: str = ""
    web_status: str = ""
    iso_path: str = ""
    iso_tstamp: str = ""
    iso_size: str = ""
    iso_volume: str = ""
    rmk_path: str = ""
    rmk_tstamp: str = ""
    rmk_size: str = ""
    rmk_volume: str = ""
    ldr_initrd: str = ""
    ldr_kernel: str = ""
    cfg_path: str = ""
    cfg_tstamp: str = ""
    lnk_path: str = ""
    options: str = ""
    create_flag: str = ""


class InfoMedia:
    def __init__(self, path: str | None = None, info_conf: Any | None = None):
        self._valid_fields = {f.name for f in fields(MediaData)}
        self.data: list[MediaData] = []
        if path and info_conf:
            self.load(path, info_conf)

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            if self.data:
                return getattr(self.data[0], name)
            return ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    def find(self, **kwargs) -> MediaData | None:
        for item in self.data:
            if all(getattr(item, key, None) == value for key, value in kwargs.items()):
                return item
        return None

    @debug_logger
    def load(self, path: str, info_conf: InfoConfiguration) -> None:
        with open(path, "r", encoding="utf-8") as f:
            raw_data = json.load(f)
        decoded_data = spc_decode(raw_data)
        converted_data = info_conf.conv2data(decoded_data)
        self.data = [
            MediaData(**item) if isinstance(item, dict) else item
            for item in converted_data
        ]

    @debug_logger
    def save(self, path: str, info_conf: InfoConfiguration) -> None:
        dict_list = [asdict(item) for item in self.data]
        converted_data = info_conf.conv2variable(dict_list)
        encoded_data = spc_encode(converted_data)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(encoded_data, f, ensure_ascii=False, indent=4)

    def markdown(self, path: str, title: str) -> None:
        dict_list = [asdict(item) for item in self.data]
        list2markdown(path, title, dict_list)

    def dump(self) -> None:
        for line in self.data:
            text = f"{line!s:.{infosystem.columns}s}"
            eprint(f"{Color.yellow}{text}{Color.reset}")

    def conv2data(self, info_conf: InfoConfiguration) -> None:
        converted_data = info_conf.conv2data(self.data)
        if hasattr(self, "_to_mediadata_list"):
            self.data = self._to_mediadata_list(converted_data)
        else:
            self.data = [
                MediaData(**item) if isinstance(item, dict) else item
                for item in converted_data
            ]

    def conv2variable(self, info_conf: InfoConfiguration) -> list[dict[str, Any]]:
        dict_list = [asdict(item) for item in self.data]
        converted_data = info_conf.conv2variable(dict_list)
        if hasattr(self, "_to_mediadata_list"):
            list_data = self._to_mediadata_list(converted_data)
        else:
            list_data = [
                MediaData(**item) if isinstance(item, dict) else item
                for item in converted_data
            ]
        return list_data

    def get_text2list(self, path: str, info_conf: InfoConfiguration) -> None:
        list_data = get_text2list(path)
        decoded_data = spc_decode(list_data)
        converted_data = info_conf.conv2data(decoded_data)
        self.data = [
            MediaData(**item) if isinstance(item, dict) else item
            for item in converted_data
        ]

    def put_list2text(self, path: str, fmat: str, info_conf: InfoConfiguration) -> None:
        put_list2text(
            path, [asdict(item) for item in self.conv2variable(info_conf)], fmat
        )


#        dict_list = [asdict(item) for item in self.data]

# --- eof ---------------------------------------------------------------------
