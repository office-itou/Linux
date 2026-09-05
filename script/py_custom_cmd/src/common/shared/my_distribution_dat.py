###############################################################################
#
# 	distribution.dat I/O
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
from ..utils.my_fileio import get_text2list, put_list2text
from ..utils.my_markdown import list2markdown
from ..utils.my_string import eprint, spc_decode, spc_encode


# -----------------------------------------------------------------------------
@dataclass
class DistributionData:
    version: str = ""
    name: str = ""
    version_id: str = ""
    code_name: str = ""
    life: str = ""
    release: str = ""
    support: str = ""
    long_term: str = ""
    rhel: str = ""
    kerne: str = ""
    note: str = ""
    wallpaper: str = ""
    create_flag: str = ""
    sort_flag: str = ""


class InfoDistribution:
    def __init__(self, path: str | None = None):
        self._valid_fields = {f.name for f in fields(DistributionData)}
        self.data: list[DistributionData] = []
        if path:
            self.load(path)

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            if self.data:
                return getattr(self.data[0], name)
            return ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    def find(self, **kwargs) -> DistributionData | None:
        for item in self.data:
            if all(getattr(item, key, None) == value for key, value in kwargs.items()):
                return item
        return None

    def load(self, path: str) -> None:
        with open(path, "r", encoding="utf-8") as f:
            raw_data = json.load(f)
        decoded_data = spc_decode(raw_data)
        self.data = [
            DistributionData(**item) if isinstance(item, dict) else item
            for item in decoded_data
        ]

    def save(self, path: str):
        dict_list = [asdict(item) for item in self.data]
        encoded_data = spc_encode(dict_list)
        with open(path, "w", encoding="utf-8") as f:
            json.dump(encoded_data, f, ensure_ascii=False, indent=4)

    def markdown(self, path: str, title: str) -> None:
        dict_list = [asdict(item) for item in self.data]
        list2markdown(path, title, dict_list)

    def dump(self) -> None:
        for line in self.data:
            text = f"{line!s:.{infosystem.columns}s}"
            eprint(f"{Color.yellow}{text}{Color.reset}")

    def get_text2list(self, path: str) -> None:
        list_data = get_text2list(path)
        decoded_data = spc_decode(list_data)
        self.data = [
            DistributionData(**item) if isinstance(item, dict) else item
            for item in decoded_data
        ]

    def put_list2text(self, path: str, fmat: str) -> None:
        put_list2text(path, [asdict(item) for item in self.data], fmat)


# --- eof ---------------------------------------------------------------------
