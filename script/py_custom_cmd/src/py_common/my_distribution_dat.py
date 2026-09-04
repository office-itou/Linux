###############################################################################
#
#	distribution.dat I/O
#
#	developer   : J.Itou
#	release     : 2026/09/03
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
from typing                             import Any, Optional
from dataclasses                        import dataclass, asdict, fields
import json

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_debug                 import debug_logger
from py_common.my_colors                import color
from py_common.my_string                import eprint, spc_decode, spc_encode
from py_common.my_markdown              import list2markdown

# -----------------------------------------------------------------------------
@dataclass
class DistributionData:
    version:        str = ''
    name:           str = ''
    version_id:     str = ''
    code_name:      str = ''
    life:           str = ''
    release:        str = ''
    support:        str = ''
    long_term:      str = ''
    rhel:           str = ''
    kerne:          str = ''
    note:           str = ''
    wallpaper:      str = ''
    create_flag:    str = ''
    sort_flag:      str = ''

class InfoDistribution:
    def __init__(self, path: str = None):
        self.data: list[DistributionData] = []
        self._valid_fields = {f.name for f in fields(DistributionData)}
        if path:
            self.load(path)

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            if self.data:
                return getattr(self.data[0], name)
            return ''
        raise AttributeError(f"'{self.__class__.__name__}' object has no attribute '{name}'")

    def find(self, **kwargs) -> Optional[DistributionData]:
        for item in self.data:
            match = True
            for key, value in kwargs.items():
                if getattr(item, key, None) != value:
                    match = False
                    break
            if match:
                return item

    def load(self, path: str) -> None:
        with open(path, 'r', encoding='utf-8') as f:
            raw_data = json.load(f)
        decoded_data = spc_decode(raw_data)
        self.data = decoded_data

    def save(self, path: str):
        encoded_data = spc_encode(self.data)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(encoded_data, f, ensure_ascii=False, indent=4)

    def markdown(self, path: str, title: str) -> None:
        dict_list = [asdict(item) for item in self.data]
        list2markdown(path, title, dict_list)

    def dump(self) -> None:
        for line in self.data:
            text = f"{str(line):.{infosystem.columns}s}"
            eprint(f"{color.yellow}{text}{color.reset}")

# --- eof ---------------------------------------------------------------------
