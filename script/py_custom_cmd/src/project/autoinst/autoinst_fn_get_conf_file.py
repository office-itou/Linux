#!/usr/bin/env python3
# --- python library ----------------------------------------------------------
import os
import re
import subprocess
from pathlib import Path
from urllib.parse import urlparse


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    download,
    fcopy,
    fread,
    get_caller_name,
    message_info,
)


# ruff: isort: on
# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def get_conf_file(info_syst) -> None:
    _caller = get_caller_name()
    _tget_list: list[Path] = [
        info_syst.info_conf.get_path("PATH_ERLY"),
        info_syst.info_conf.get_path("PATH_LATE"),
        info_syst.info_conf.get_path("PATH_PART"),
        info_syst.info_conf.get_path("PATH_RUNS"),
        info_syst.data.seed_path,
    ]
    _dest_path = info_syst.data.tget_path / info_syst.info_conf.get_path("DIRS_INST")
    for _tget_line in _tget_list:
        _tget_urls = (
            (
                _tget_line.split("=")[2]
                if "nocloud" in _tget_line
                else _tget_line.split("=")[1]
            )
            if "=" in _tget_line
            else _tget_line
        )
        _tget_pars = urlparse(_tget_urls)
        _srcs_path: Path = Path(_tget_pars.path)
        _dest_path: Path = info_syst.data.acmd_path / Path(_tget_pars.path).name
        match _tget_pars.scheme:
            case "http" | "https":
                message_info(_caller, f"{'download':<10}:{_tget_urls}", omit=True)
                download(tget_urls=_tget_urls, dest_path=_dest_path)
            case "ftp":
                message_info(_caller, f"{'download':<10}:{_tget_urls}", omit=True)
                # _tget_urls = "ftp://://example.com"
                # _user_name = ""
                # _pass_word = ""
                # _ftp_cmd: list[str] = [
                #    "wget",
                #    f"--ftp-user={_user_name}",
                #    f"--ftp-password={_pass_word}",
                #    _tget_urls,
                # ]
                # dest_path.parent.mkdir(parents=True, exist_ok=True)
                # subprocess.check_output(_comd_list, text=True,
                #   stderr=subprocess.DEVNULL)
            case s if "cdrom" == s or "hd:sr" in _tget_pars.path:
                _tget_path = (
                    Path(_tget_pars.path)
                    if ":" not in _tget_pars.path
                    else ":".join(_tget_pars.path.split(":")[1:])
                )
                _srcs_path = Path("/mnt/install/repo") / _tget_path
                message_info(_caller, f"{'copy':<10}:{_srcs_path}", omit=True)
                fcopy(src_path=_srcs_path, dest_path=_dest_path, backup=False)
            case "hd" | "dvd" | "cd":
                _tget_path = (
                    Path(_tget_pars.path)
                    if ":" not in _tget_pars.path
                    else ":".join(_tget_pars.path.split(":")[1:])
                )
                _chek_path: Path = Path("/run/initramfs/live")
                if _chek_path.exists() and _chek_path.is_dir():
                    message_info(_caller, f"{'info':<10}:{_chek_path}", omit=True)
                    _srcs_path = _chek_path / _tget_path
                    message_info(_caller, f"{'copy':<10}:{_srcs_path}", omit=True)
                    fcopy(src_path=_srcs_path, dest_path=_dest_path, backup=False)
                    continue
                _chek_path: Path = Path("/var/log/YaST2/y2start.log")
                if _chek_path.exists() and _chek_path.is_file():
                    message_info(_caller, f"{'info':<10}:{_chek_path}", omit=True)
                    _read_text: str = fread(src_path=_chek_path, text=True)
                    _os_info = {}
                    _kv_rule = re.compile(r"^\s*([A-Z_]+)\s*=\s*(.*)\s*$")
                    for _line in _read_text.splitlines():
                        _match = _kv_rule.match(_line)
                        if _match:
                            _key = _match.group(1)
                            _val = _match.group(2).strip("\"'").strip()
                            _os_info[_key] = _val.lower()
                    _seed_path: Path = _os_info.get("AutoYaST", None)
                    _yast_path: Path = _os_info.get("autoyast", None)
                    _devs_path = f"/dev/${str(_seed_path / _yast_path)}"
                    if _seed_path and _yast_path and _devs_path.exists():
                        _mntp_path: Path = Path("/media")
                        _mntp_path.parent.mkdir(parents=True, exist_ok=True)
                        _comd_list = ["mount", "-r", str(_devs_path), str(_mntp_path)]
                        subprocess.check_output(
                            _comd_list, text=True, stderr=subprocess.DEVNULL
                        )
                        _srcs_path = _mntp_path / _tget_path
                        message_info(_caller, f"{'copy':<10}:{_srcs_path}", omit=True)
                        fcopy(
                            src_path=_srcs_path, dest_path=_dest_path, backup=False
                        )
                        _comd_list = ["umount", str(_mntp_path)]
                        subprocess.check_output(
                            _comd_list, text=True, stderr=subprocess.DEVNULL
                        )
            case "nfs":
                message_info(_caller, f"{'copy':<10}:{_srcs_path}", omit=True)
            case _:
                match _tget_pars.path:
                    case "cdrom":
                        _tget_path = (
                            Path(_tget_pars.path)
                            if ":" not in _tget_pars.path
                            else ":".join(_tget_pars.path.split(":")[1:])
                        )
                        _srcs_path = Path("/mnt/install/repo") / _tget_path
                        message_info(_caller, f"{'copy':<10}:{_srcs_path}", omit=True)
                        fcopy(
                            src_path=_srcs_path, dest_path=_dest_path, backup=False
                        )
                    case "hmc":
                        message_info(_caller, f"{'copy':<10}:{_srcs_path}", omit=True)
                    case _:
                        message_info(_caller, f"{'copy':<10}:{_srcs_path}", omit=True)
                        fcopy(
                            src_path=_srcs_path, dest_path=_dest_path, backup=False
                        )
        if _dest_path.exists():
            if "/script/" in str(_tget_urls):
                os.chmod(_dest_path, 0o755)
            else:
                os.chmod(_dest_path, 0o644)
