# --- python library ----------------------------------------------------------
import re
import shutil

# import yaml
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    fread,
    get_caller_name,
    message_info,
    message_warn,
    run_subprocess,
    run_subprocess_stdout,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def get_packages_preseed(seed_path: Path) -> None:
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
    return " ".join(_pack_list)


@debug_logger
def get_packages_nocloud(seed_path: Path) -> None:
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
    return " ".join(_pack_list)


@debug_logger
def package_update(info_syst) -> None:
    _caller = get_caller_name()
    # --- check file ----------------------------------------------------------
    _repo_path: Path = info_syst.data.acmd_path / info_syst.data.seed_path.name
    if not _repo_path.exists():
        message_warn(_caller, f"{'skip':<10}:not found:{_repo_path}", omit=True)
        return
    # --- get package list ----------------------------------------------------
    _pakg_list = ""
    match _repo_path.name:
        case s if re.search(r"yast*.xml|auto*.xml", s):  #  autoyast
            pass
        case s if re.search(r"agama*.json|auto*.json"):  #  agama
            pass
        case s if re.search(r"kickstart*.cfg|ks*.cfg"):  #  kickstart
            pass
        case s if re.search(r"user-data*"):  # (nocloud)
            _pakg_list = get_packages_nocloud(_repo_path)
        case s if re.search(r"preseed*.cfg|ps*.cfg"):  # (preseed)
            _pakg_list = get_packages_preseed(_repo_path)
    if not _pakg_list:
        message_warn(
            _caller, f"{'skip':<10}:no package list in {_repo_path.name}", omit=True
        )
        return
    # --- missing packages ----------------------------------------------------
    if shutil.which("apt-get"):
        # --- get missing packages --------------------------------------------
        _comd_list: list[str] = [
            "dpkg-query",
            "--no-pager",
            "--show",
            r"--showformat='${Status}\t${Architecture}\t${binary:Package}\n'",
            *_pakg_list,
        ]
        _result: str = run_subprocess(_comd_list)
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
        # --- install missing packages ----------------------------------------
        message_info(_caller, f"{'info':<10}:installed packages list", omit=True)
        for _line in _inst_pakg:
            message_info(_caller, f"{'info':<10}:{_line}", omit=True)
        message_info(_caller, f"{'info':<10}:missing packages list", omit=True)
        for _line in _miss_pakg:
            message_info(_caller, f"{'info':<10}:{_line}", omit=True)
        if not _miss_pakg:
            message_info(_caller, f"{'skip':<10}:no missing packages", omit=True)
            return
        message_info(_caller, f"{'info':<10}:missing packages install", omit=True)
        # --- check network ---------------------------------------------------
        if not info_syst.data.nics_stat:
            message_warn(_caller, f"{'skip':<10}:network is down", omit=True)
            return
        _result = run_subprocess_stdout(["apt-get", "--quiet", "update"])
        _result = run_subprocess_stdout(
            ["apt-get", "--quiet", "--assumeyes", "install", *_miss_pakg]
        )
        _result = run_subprocess_stdout(
            ["apt-get", "--quiet", "--assumeyes", "autoremove"]
        )
        _result = run_subprocess_stdout(
            ["apt-get", "--quiet", "--assumeyes", "autoclean"]
        )
        _result = run_subprocess_stdout(["apt-get", "--quiet", "--assumeyes", "clean"])
