# --- Python library ----------------------------------------------------------
import json
from dataclasses                        import dataclass, asdict

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_colors                import color
from py_common.my_markdown              import json2markdown

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
    def __init__(self, path):
        self.data: DistributionData = DistributionData()
        self.load(path)

    def load(self, path: str):
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        self.data = [DistributionData(**item) for item in data]

    def save(self, path: str):
        data = asdict(self.data)
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)

    def from_json(self, data: list):
        self.data = [DistributionData(**item) for item in data]

    def to_json(self) -> dict:
        return [asdict(data) for data in self.data]

    def markdown(self, path: str, title: str):
        json2markdown(path, title, self.to_json())

    def dump(self):
        for line in self.data:
            text = f"{str(line):.{infosystem.data.columns}s}"
            eprint(f"{color.yellow}{text}{color.reset}")

# --- eof ---------------------------------------------------------------------
