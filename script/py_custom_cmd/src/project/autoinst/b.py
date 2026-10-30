#!/usr/bin/env python3
# --- python library ----------------------------------------------------------
import re
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    fread,
    run_subprocess,
)

# ruff: isort: on
# --- import module -----------------------------------------------------------


# --- class and function ------------------------------------------------------
_seed_path = Path("/srv/user/share/conf/preseed/ps_debian_server.cfg")
_yaml_path = Path("/srv/user/share/conf/nocloud/ubuntu_server/user-data")
_kick_path = Path("/srv/user/share/conf/kickstart/ks_almalinux-10_dvd.cfg")
_yast_path = Path("/srv/user/share/conf/autoyast/autoinst_tumbleweed_dvd.xml")
_agma_path = Path("/srv/user/share/conf/agama/autoinst_leap-16.0.json")


# --- preseed -----------------------------------------------------------------
def get_packages_preseed(seed_path: Path) -> list[str] | None:
    _st_pattern = re.compile(r"^\s*d-i\s+pkgsel/include\s+string\s*\\?$")
    _en_pattern = re.compile(r"^\s*d-i\s+")
    _in_packages_section: bool = False
    _pack_list: list[str] = []
    _read_text: str = fread(src_path=seed_path, text=True)
    for _line in _read_text.splitlines():
        _line_str = _line.strip()
        if _st_pattern.match(_line_str):
            _in_packages_section = True
            continue
        if _in_packages_section:
            if not _line_str:
                continue
            if _line_str.startswith("#"):
                continue
            if _en_pattern.match(_line_str) or not _line_str.endswith("\\"):
                if not _en_pattern.match(_line_str):
                    _cleaned = _line_str.replace("\\", "").strip()
                    if _cleaned:
                        _pack_list.extend(_cleaned.split())
                _in_packages_section = False
                break
            _cleaned = _line_str.replace("\\", "").strip()
            if _cleaned:
                _pack_list.extend(_cleaned.split())
    return _pack_list


# --- nocloud -----------------------------------------------------------------
def get_packages_nocloud(seed_path: Path) -> list[str] | None:
    _st_pattern = re.compile(r"^\s*packages:\s*$")
    _en_pattern = re.compile(r"^\s{2}[^-#\s][^:]*:\s*$")
    _in_packages_section: bool = False
    _pack_list: list[str] = []
    _read_text: str = fread(src_path=seed_path, text=True)
    for _line in _read_text.splitlines():
        _line_str = _line.rstrip()
        if _st_pattern.match(_line_str):
            _in_packages_section = True
            continue
        if _in_packages_section:
            _stripped = _line_str.strip()
            if not _stripped:
                continue
            if _stripped.startswith("#"):
                continue
            if _en_pattern.match(_line_str):
                _in_packages_section = False
                break
            if _stripped.startswith("-"):
                _cleaned = re.sub(r"^-\s*", "", _stripped)
                _cleaned = re.sub(r"\s*#.*$", "", _cleaned)
                if _cleaned:
                    _pack_list.append(_cleaned)
    return _pack_list


_pakg_list: list[str] = []
_pakg_list += get_packages_preseed(_seed_path)
_pakg_list += get_packages_nocloud(_yaml_path)

_comd_list: list[str] = [
    "dpkg-query",
    "--no-pager",
    "--show",
    r"--showformat='${Status}\t${Architecture}\t${binary:Package}\n'",
    *_pakg_list,
]
# print(*_comd_list)
_result = run_subprocess(_comd_list, check=False)
_inst_pakg: list[str] = []
_miss_pakg: list[str] = []
_inst_pattern = re.compile(r"^install\s+ok\s+installed\s+[^\s]+\s+([^\s]+)")
for _line in _result.stdout.splitlines():
    _line = _line.strip("'\r\n")
    _match = _inst_pattern.match(_line)
    if _match:
        _inst_pakg.append(_match.group(1))
for _line in _pakg_list:
    if _line not in _inst_pakg:
        _miss_pakg.append(_line)
#print("*" * 80)
#print(_pakg_list)
print("*" * 80)
print(_inst_pakg)
print("*" * 80)
print(_miss_pakg)
print("*" * 80)
