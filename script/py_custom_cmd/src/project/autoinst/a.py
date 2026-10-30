#!/usr/bin/env python3
# --- python library ----------------------------------------------------------
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import url2pathname


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    download,
    fcopy,
    fread,
    infosystem,
)

# ruff: isort: on
# --- import module -----------------------------------------------------------
from autoinst_fn_initialize import initialize


# --- class and function ------------------------------------------------------
@debug_logger
def url2path(url: str) -> Path:
    _parsed_url = urlparse(url)
    _native_path = url2pathname(_parsed_url.path)
    print(f"_parsed_url:{_parsed_url}")
    print(f"_native_path:{_native_path}")
    if _parsed_url.netloc:
        _native_path = Path(f"{_parsed_url.netloc}{_native_path}")
    return _native_path.resolve()


_tget_list: list[Path] = [
    "http://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "fttp://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "cdrom:/BaseOS/",
    "hd:/mnt/cdrom/BaseOS/",
    "nfs:master@sv-server:/mnt/cdrom/BaseOS/",
    "",
    "cdrom",
    "hmc",
    "",
    "fttps://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "tftps://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "tftp://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "hd:sr0:",
    "dvd:",
    "cd:device:",
    "label:",
    "usb:",
    "smb:",
    "file:///mnt/cdrom/BaseOS/",
    "/mnt/cdrom/BaseOS/",
]
_tget_list: list[str] = [
    "http://sv-server/conf/script/autoinst_cmd_early.sh",
    "http://sv-server/conf/script/autoinst_cmd_late.sh",
    "http://sv-server/conf/script/autoinst_cmd_part.sh",
    "http://sv-server/conf/script/autoinst_cmd_run.sh",
    "file=/preseed/ps_debian_server.cfg",
    "preseed/file=/preseed/ps_debian_desktop.cfg",
    "url=http://sv-server/conf/preseed/ps_debian_server.cfg",
    "preseed/url=http://sv-server/conf/preseed/ps_debian_desktop.cfg",
    "ds=nocloud;s=/cdrom/nocloud/ubuntu_server/user-data",
    "ds=nocloud;s=http://sv-server/conf/nocloud/ubuntu_desktop/user-data",
    "inst.repo=http://sv-server/conf/kickstart/ks_almalinux-10_net.cfg",
    "autoyast=http://sv-server/conf/autoyast/autoinst_tumbleweed_net.xml",
    "inst.auto=http://sv-server/conf/agama/autoinst_leap-16.0.json",
]
_shel_list: list[str] = [
    "/srv/user/share/conf/script/autoinst_cmd_early.sh",
    "/srv/user/share/conf/script/autoinst_cmd_late.sh",
    "/srv/user/share/conf/script/autoinst_cmd_part.sh",
    "/srv/user/share/conf/script/autoinst_cmd_run.sh",
]
_tget_list: list[str] = [
    *_shel_list,
    "file=/srv/user/share/conf/preseed/ps_debian_server.cfg",
    "preseed/file=/srv/user/share/conf/preseed/ps_debian_desktop.cfg",
    "ds=nocloud;s=/srv/user/share/conf/nocloud/ubuntu_server/user-data",
]
_aaa = [
    "inst.repo=cdrom",
    "inst.repo=cdrom:device",
    "inst.repo=hd:device:/path",
    "inst.repo=hmc",
    "inst.repo=https://host/path",
    "inst.repo=ftp://username:password@host/path",
    "inst.repo=nfs:[options:]server:/path",
    "inst.auto=https://sv-server/conf/agama/autoinst_leap-16.0.json",
    "inst.auto=ftp://sv-server/conf/agama/autoinst_leap-16.0.json",
    "inst.auto=ftps://sv-server/conf/agama/autoinst_leap-16.0.json",
    "inst.auto=smb://sv-server/conf/agama/autoinst_leap-16.0.json",
    "inst.auto=smbs://sv-server/conf/agama/autoinst_leap-16.0.json",
    "inst.auto=file:",
    "inst.auto=device://sda1/profile.json",
    "inst.auto=device://sda1/profiles/sles.json",
    "inst.auto=device:///cciss/c1d0p5/sles.json",
    "inst.auto=usb:///profile/sles.json",
    "inst.auto=label://OEMDRV/sles.json",
    "inst.auto=cd",
    "inst.auto=dvd:/autoinst.xml?devices=sr1",
    "inst.auto=hd:/sles.jsonnet?devices=/dev/sr0",
    "inst.auto=repo://",
]

_info_syst = initialize()
_prog_name: str = infosystem.program_name
_timestamp: str = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
_vadm_path: Path = _info_syst.conf.path("DIRS_VADM") / _prog_name
_vwrk_path: Path = _vadm_path.with_suffix(f"{_vadm_path.suffix}.{_timestamp}")


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
    _srcs_path = Path(_tget_pars.path)
    _dest_path = _vadm_path / Path(_tget_pars.path).name
    match _tget_pars.scheme:
        case "http" | "https":
            print(f"download:{_tget_urls}")
            download(tget_urls=_tget_urls, dest_path=_dest_path)
        case "ftp":
            print(f"download:{_tget_urls}")
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
            # subprocess.check_output(_comd_list, text=True, stderr=subprocess.DEVNULL)
            pass
        case s if "cdrom" == s or "hd:sr" in _tget_pars.path:
            _tget_path = (
                Path(_tget_pars.path)
                if ":" not in _tget_pars.path
                else ":".join(_tget_pars.path.split(":")[1:])
            )
            _srcs_path = Path("/mnt/install/repo") / _tget_path
            print(f"copy:{_srcs_path}")
            fcopy(src_path=_srcs_path, dest_path=_dest_path, backup=False)
        case "hd" | "dvd" | "cd":
            _tget_path = (
                Path(_tget_pars.path)
                if ":" not in _tget_pars.path
                else ":".join(_tget_pars.path.split(":")[1:])
            )
            _chek_path: Path = Path("/run/initramfs/live")
            if _chek_path.exists() and _chek_path.is_dir():
                print(f"info:{_chek_path}")
                _srcs_path = _chek_path / _tget_path
                print(f"copy:{_srcs_path}")
                fcopy(src_path=_srcs_path, dest_path=_dest_path, backup=False)
                continue
            _chek_path: Path = Path("/var/log/YaST2/y2start.log")
            if _chek_path.exists() and _chek_path.is_file():
                print(f"info:{_chek_path}")
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
                    print(f"copy:{_srcs_path}")
                    fcopy(src_path=_srcs_path, dest_path=_dest_path, backup=False)
                    _comd_list = ["umount", str(_mntp_path)]
                    subprocess.check_output(
                        _comd_list, text=True, stderr=subprocess.DEVNULL
                    )
        case "nfs":
            print(f"copy:{_srcs_path}")
            pass
        case _:
            match _tget_pars.path:
                case "cdrom":
                    _tget_path = (
                        Path(_tget_pars.path)
                        if ":" not in _tget_pars.path
                        else ":".join(_tget_pars.path.split(":")[1:])
                    )
                    _srcs_path = Path("/mnt/install/repo") / _tget_path
                    print(f"copy:{_srcs_path}")
                    fcopy(src_path=_srcs_path, dest_path=_dest_path, backup=False)
                case "hmc":
                    print(f"copy:{_srcs_path}")
                    pass
                case _:
                    print(f"copy:{_srcs_path}")
                    fcopy(src_path=_srcs_path, dest_path=_dest_path, backup=False)
    if _dest_path.exists():
        if "/script/" in str(_tget_urls):
            os.chmod(_dest_path, 0o755)
        else:
            os.chmod(_dest_path, 0o644)
