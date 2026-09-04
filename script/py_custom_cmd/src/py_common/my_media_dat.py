###############################################################################
#
#	media.dat I/O
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
from py_common.my_common_cfg            import InfoConfiguration

# -----------------------------------------------------------------------------
@dataclass
class MediaData:
    type:           str = ''
    entry_flag:     str = ''
    entry_name:     str = ''
    entry_disp:     str = ''
    version:        str = ''
    latest:         str = ''
    release:        str = ''
    support:        str = ''
    web_regexp:     str = ''
    web_path:       str = ''
    web_tstamp:     str = ''
    web_size:       str = ''
    web_check:      str = ''
    web_status:     str = ''
    iso_path:       str = ''
    iso_tstamp:     str = ''
    iso_size:       str = ''
    iso_volume:     str = ''
    rmk_path:       str = ''
    rmk_tstamp:     str = ''
    rmk_size:       str = ''
    rmk_volume:     str = ''
    ldr_initrd:     str = ''
    ldr_kernel:     str = ''
    cfg_path:       str = ''
    cfg_tstamp:     str = ''
    lnk_path:       str = ''
    options:        str = ''
    create_flag:    str = ''

class InfoMedia:
    def __init__(self, path: str = None, info_conf: Any = None):
        self.data: list[MediaData] = []
        self._valid_fields = {f.name for f in fields(MediaData)}
        if path and info_conf:
            self.load(path, info_conf)

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            if self.data:
                return getattr(self.data[0], name)
            return ''
        raise AttributeError(f"'{self.__class__.__name__}' object has no attribute '{name}'")

    def find(self, **kwargs) -> Optional[MediaData]:
        for item in self.data:
            match = True
            for key, value in kwargs.items():
                if getattr(item, key, None) != value:
                    match = False
                    break
            if match:
                return item

    @debug_logger
    def load(self, path: str, info_conf: InfoConfiguration) -> None:
        with open(path, 'r', encoding='utf-8') as f:
            raw_data = json.load(f)
        decoded_data = spc_decode(raw_data)
        converted_data = info_conf.conv2data(decoded_data)
        self.data = converted_data

    @debug_logger
    def save(self, path: str, info_conf: InfoConfiguration) -> None:
        converted_data = info_conf.conv2variable(self.data)
        encoded_data = spc_encode(converted_data)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(encoded_data, f, ensure_ascii=False, indent=4)

    def markdown(self, path: str, title: str) -> None:
        list2markdown(path, title, self.data)

    def dump(self) -> None:
        for line in self.data:
            text = f"{str(line):.{infosystem.columns}s}"
            eprint(f"{color.yellow}{text}{color.reset}")

    def conv2data(self, info_conf: InfoConfiguration) -> None:
        converted_data = info_conf.conv2data(self.data)
        self.data = self._to_mediadata_list(converted_data)

    def conv2variable(self, info_conf: InfoConfiguration) -> list[dict[str, Any]]:
        return info_conf.conv2variable(self.data)

#        dict_list = [asdict(item) for item in self.data]

# --- eof ---------------------------------------------------------------------
