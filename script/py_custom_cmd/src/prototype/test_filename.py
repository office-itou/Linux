#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import os
import re
import sys
from pathlib import Path

# --- my library --------------------------------------------------------------
execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))
from common.utils.my_colors import Color


def function(target: str):
    # --- output file information ---------------------------------------------
    # https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso
    RE_DEB_UBU = re.compile(
        r"^https?://.+/(debian|ubuntu)/dists/[^/]+/main/installer-([^/]+)/current/"
    )
    # https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso
    RE_DAILY = re.compile(r"^https?://d-i\.debian.org/daily-images/([^/]+)/daily/")
    # https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso
    # https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso
    # https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso
    RE_NETINST = re.compile(
        r"^https?://[^/]+/cdimage/([^/]+)/(?:daily/)?(.+/)?([^/]+)/iso-cd/"
    )
    filename = re.sub(r"^.+/", "", target_url)
    match filename:
        case "mini.iso":
            if m := RE_DEB_UBU.match(target_url):
                code = target_url.split("/dists/")[1].split("/")[0]
                arch = m.group(2)
                filename = f"mini-{code}-{arch}.iso"
            elif m := RE_DAILY.match(target_url):
                arch = m.group(1)
                filename = f"mini-testing-daily-{arch}.iso"
        case s if m := re.match(r"debian-testing-.+-netinst\.iso", s):
            if m := RE_NETINST.match(target_url):
                print(f"{Color.br_yellow}{m.groups()}{Color.reset}")
                edtn = m.group(1)
                bild = m.group(2)
                arch = m.group(3)
                if bild:
                    edtn = f"{edtn}-{bild.strip('/').replace('/', '-')}"
                filename = filename.replace(arch, f"{edtn}-{arch}", 1)
    return filename


for target_url, target_path in [
    # mini.iso
    [
        "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso",
        ":_DIRS_ISOS_:/linux/debian/mini-_bullseye-amd64.iso",
    ],
    [
        "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso",
        ":_DIRS_ISOS_:/linux/debian/mini-_bookworm-amd64.iso",
    ],
    [
        "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
        ":_DIRS_ISOS_:/linux/debian/mini-_trixie-amd64.iso",
    ],
    [
        "https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso",
        ":_DIRS_ISOS_:/linux/debian/mini-_forky-amd64.iso",
    ],
    [
        "https://deb.debian.org/debian/dists/duke/main/installer-amd64/current/images/netboot/mini.iso",
        ":_DIRS_ISOS_:/linux/debian/mini-_duke-amd64.iso",
    ],
    [
        "https://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/netboot/mini.iso",
        ":_DIRS_ISOS_:/linux/debian/mini-_testing-amd64.iso",
    ],
    [
        "https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso",
        ":_DIRS_ISOS_:/linux/debian/mini-_testing-daily-amd64.iso",
    ],
    [
        "https://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso",
        ":_DIRS_ISOS_:/linux/ubuntu/mini-_focal-amd64.iso",
    ],
    # netinst
    [
        "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso",
        ":_DIRS_ISOS_:/linux/debian/debian-testing-_weekly-weekly-builds-amd64-netinst.iso",
    ],
    [
        "https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso",
        ":_DIRS_ISOS_:/linux/debian/debian-testing-_daily-current-amd64-netinst.iso",
    ],
    [
        "https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso",
        ":_DIRS_ISOS_:/linux/debian/debian-testing-_daily-builds-arch-latest-amd64-netinst.iso",
    ],
]:
    filename = function(target_url)
    print(
        str(Path(target_path).with_name(filename) if target_path and filename else "")
    )
