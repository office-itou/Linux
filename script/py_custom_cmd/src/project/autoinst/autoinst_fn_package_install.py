# --- python library ----------------------------------------------------------
import os
import re
import shutil
import subprocess
from pathlib import Path
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    fread,
    get_caller_name,
    handle_fatal_error,
    message_warn,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def get_packages_preseed(seed_path: Path) -> list[str]:
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


@debug_logger
def get_packages_nocloud(seed_path: Path) -> list[str]:
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


@debug_logger
def package_install(info_syst) -> None:
    _caller = get_caller_name()
    # --- check file ----------------------------------------------------------
    _seed_path: Path = info_syst.data.acmd_path / info_syst.data.seed_path.name
    if not _seed_path.exists():
        message_warn(_caller, f"{'skip':<10}:not found:{_seed_path}", omit=True)
        return
    # --- get package list ----------------------------------------------------
    try:
        _pakg_list: list[str] = []
        match _seed_path.name:
            case s if re.search(r"preseed*.cfg|ps*.cfg"):  # (preseed)
                _pakg_list = get_packages_preseed(_seed_path)
            case s if re.search(r"user-data*"):  # (nocloud)
                _pakg_list = get_packages_nocloud(_seed_path)
            case s if re.search(r"kickstart*.cfg|ks*.cfg"):  #  kickstart
                pass
            case s if re.search(r"agama*.json|auto*.json"):  #  agama
                pass
            case s if re.search(r"yast*.xml|auto*.xml", s):  #  autoyast
                pass
        if not _pakg_list:
            message_warn(
                _caller, f"{'skip':<10}:no package list in {_seed_path.name}", omit=True
            )
            return
        # --- missing packages ------------------------------------------------
        if shutil.which("dpkg-query"):
            _envs_list = os.environ.copy()
            _envs_list["_PAKG_LIST"] = _pakg_list
            _shel_comd: str = r"""
                LANG=C dpkg-query --no-pager --show --showformat='${Status}\t${Architecture}\t${binary:Package}\n' "${_PAKG_LIST[@]:-}" 2>&1 | \
                awk '!/^install[ \t]+ok[ \t]+installed[ \t]+/ {gsub(/^.+[ \t]/,""); print}'
            """  # noqa: E501
            if _shel_comd:
                _result: CompletedProcess = subprocess.run(
                    _shel_comd, shell=True, env=_envs_list, executable="/bin/bash"
                )
                if _result.returncode != 0:
                    print(_result.stderr)
                if _result.stdout:
                    _find_list: list[str] = [
                        s for s in str(_result.stdout).splitlines()
                    ]
                    _envs_list["_FIND_LIST"] = _find_list
                    _shel_comd: str = r"""
                        apt-get --quiet              update                        && \
                        apt-get --quiet --assume-yes install "${_FINMD_LIST[@]:-}" && \
                        apt-get --quiet --assume-yes autoremove                    && \
                        apt-get --quiet --assume-yes autoclean                     && \
                        apt-get --quiet --assume-yes clean
                    """
                    if _shel_comd:
                        _result: CompletedProcess = subprocess.run(
                            _shel_comd,
                            shell=True,
                            env=_envs_list,
                            executable="/bin/bash",
                        )
                        if _result.returncode != 0:
                            print(_result.stderr)

    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)
