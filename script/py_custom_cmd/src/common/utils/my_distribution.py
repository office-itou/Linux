# --- python library ----------------------------------------------------------
import re
from dataclasses import dataclass
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    fread,
    get_caller_name,
    message_info,
)


# --- import module -----------------------------------------------------------
@dataclass
class DistributionData:
    name: str | None = None  # name
    vers: str | None = None  # version
    code: str | None = None  # code


# --- class and function ------------------------------------------------------
def get_distribution(find_list: list[Path]) -> DistributionData:
    _caller = get_caller_name()
    # --- distribution --------------------------------------------------------
    _dist = DistributionData()
    for _path in find_list:
        if _path.exists():
            message_info(_caller, f"{'loading':<10}:{_path}", omit=True)
            _read_text: str = fread(src_path=_path, text=True)
            _os_info = {}
            _kv_rule = re.compile(r"^\s*([A-Z_]+)\s*=\s*(.*)\s*$")
            for _line in _read_text.splitlines():
                _match = _kv_rule.match(_line)
                if _match:
                    _key = _match.group(1)
                    _val = _match.group(2).strip("\"'").strip()
                    _os_info[_key] = _val.lower()
            _dist.name = _os_info.get("ID") or _os_info.get("DISTRIB_ID", "")
            _dist.name = re.sub(r"-.+", "", _dist.name)
            _dist.vers = _os_info.get("VERSION_ID") or _os_info.get(
                "DISTRIB_RELEASE", ""
            )
            _dist.code = _os_info.get("VERSION_CODENAME") or _os_info.get(
                "DISTRIB_CODENAME", ""
            )
            break
    return _dist
