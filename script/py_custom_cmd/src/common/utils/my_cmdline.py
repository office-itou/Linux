# --- Python library ----------------------------------------------------------
from io import TextIOWrapper

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
)


# =============================================================================
@debug_logger
def cmdline() -> dict[str, str | bool]:
    with open("/proc/cmdline", "r") as f:
        f: TextIOWrapper
        _content: str = f.read().strip()
    _cmdline_dict: dict[str, str | bool] = {}
    for _item in _content.split():
        if "=" in _item:
            _key, _value = _item.split("=", 1)
            _cmdline_dict[_key] = _value
        else:
            _cmdline_dict[_item] = True
    return _cmdline_dict
