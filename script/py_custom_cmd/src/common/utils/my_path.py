# --- Python library ----------------------------------------------------------
import stat
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import debug_logger, run_subprocess


# =============================================================================
#      :     Read     :    Write     :     Exec     :
# User : stat.S_IRUSR : stat.S_IWUSR : stat.S_IXUSR :
# Group: stat.S_IRGRP : stat.S_IWGRP : stat.S_IXGRP :
# Other: stat.S_IROTH : stat.S_IWOTH : stat.S_IXOTH :
#
# path = Path("example.txt")
#
# path.chmod(0o644)
#
# current_mode = path.stat().st_mode
#
# remove_mask = stat.S_IWGRP | stat.S_IWOTH
# new_mode = current_mode & ~remove_mask
#
# path.chmod(current_mode | stat.S_IXUSR)


@debug_logger
def parse_ugo_to_stat(ugo_str: str, current_mode: int = 0o000) -> int:
    _perm_map = {
        "u": {"r": stat.S_IRUSR, "w": stat.S_IWUSR, "x": stat.S_IXUSR},
        "g": {"r": stat.S_IRGRP, "w": stat.S_IWGRP, "x": stat.S_IXGRP},
        "o": {"r": stat.S_IROTH, "w": stat.S_IWOTH, "x": stat.S_IXOTH},
    }
    _result_mode = current_mode
    for _clause in ugo_str.split(","):
        _clause = _clause.strip()
        if not _clause:
            continue
        _operator = None
        for _op in ("=", "+", "-"):
            if _op in _clause:
                _operator = _op
                break
        if not _operator:
            raise ValueError(f"Invalid format: {_clause}")
        _who, _perms = _clause.split(_operator)
        _targets = list(_who) if _who else ["u", "g", "o"]
        if "a" in _targets:
            _targets = ["u", "g", "o"]
        _mask = 0
        for t in _targets:
            if t not in _perm_map:
                continue
            for p in _perms:
                if p in _perm_map[t]:
                    _mask |= _perm_map[t][p]
        if _operator == "=":
            _clear_mask = 0
            for t in _targets:
                _clear_mask |= _perm_map[t]["r"] | _perm_map[t]["w"] | _perm_map[t]["x"]
            _result_mode = (_result_mode & ~_clear_mask) | _mask
        elif _operator == "+":
            _result_mode |= _mask
        elif _operator == "-":
            _result_mode &= ~(_mask & 0o7777)
    return _result_mode


@debug_logger
def chmod(path: Path, mode: str, follow_symlinks: bool = True) -> None:

    run_subprocess(["setfacl", "-b", str(path)], check=True, capture_output=True)
    _current_mode: int = path.stat().st_mode
    _mode: int = parse_ugo_to_stat(ugo_str=mode, current_mode=_current_mode)
    print(f"{str(path)}:{mode}:{oct(_mode)}")
    path.chmod(mode=_mode, follow_symlinks=follow_symlinks)
