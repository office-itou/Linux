# --- Python library ----------------------------------------------------------
from dataclasses    					import dataclass, asdict
import json

# --- my library --------------------------------------------------------------
from py_common.my_config      			import infosystem
from py_common.my_colors      			import color
from py_common.my_markdown    			import json2markdown
from py_common.my_common_cfg  			import InfoConfiguration

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
    def __init__(self, path):
        self.data: MediaData = MediaData()
        self.load(path)

    def load(self, path: str):
        with open(path, 'r', encoding='utf-8') as f:
            load_data = json.load(f)
        self.data = [MediaData(**item) for item in load_data]

    def save(self, path: str):
        dict_data = asdict(self.data)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(dict_data, f, ensure_ascii=False, indent=4)

    def from_json(self, str_data: str):
        self.data = [MediaData(**item) for item in str_data]

    def to_json(self) -> str:
        return [asdict(data) for data in self.data]

    def markdown(self, path: str, title: str):
        json2markdown(path, title, self.to_json())

    def conv2data(self, info_conf :InfoConfiguration):
        conv = info_conf.conv2data(self.data)
        self.from_json(json.loads(conv))

    def conv2variable(self, info_conf :InfoConfiguration):
        conv = info_conf.conv2variable(self.data)
        self.from_json(json.loads(conv))

    def dump(self):
        for line in self.data:
            text = f"{str(line):.{infosystem.data.columns}s}"
            eprint(f"{color.yellow}{text}{color.reset}")

# --- eof ---------------------------------------------------------------------
