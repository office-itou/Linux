#!/usr/bin/env python3
from dataclasses import dataclass, fields
from pathlib import Path

from common.shared import (
    spc_decode,
)
from common.utils import (
    Color,
    eprint,
    generate_comment,
    infosystem,
    json_load,
    message_debug,
)


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


infosystem.initialize(is_gui=False)
src_path = Path("/srv/user/share/conf/_data/distribution.dat.json")
_raw_data: list[dict[str, str]] = json_load(src_path)
_decoded_data = spc_decode(_raw_data)
# for d in _decoded_data:
#    for k,v in d.items():
#        print(k,v)
data: list[DistributionData] = [
    DistributionData(**d) if isinstance(d, dict) else d for d in _decoded_data
]
_data_dicts: list[dict[str, str]] = [
    d.__dict__ if hasattr(d, "__dict__") else getattr(d, f.name)
    for d in data
    for f in fields(d)
]
print(_data_dicts)
