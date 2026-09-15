#!/usr/bin/env python3
import re
from dataclasses import dataclass
from pathlib import Path

try:
    from packaging.version import InvalidVersion
    from packaging.version import parse as parse_version
except ImportError:
    from distutils.version import LooseVersion as parse_version

    class InvalidVersion(Exception):
        pass


# 表示色定義
class Color:
    cyan = "\033[36m"
    blue = "\033[34m"
    yellow = "\033[33m"
    magenta = "\033[35m"
    green = "\033[32m"
    red = "\033[31m"
    reset = "\033[0m"


@dataclass
class _SortData:
    url: str = ""
    distribution: str = ""
    filename: str = ""
    version: str = ""
    flavor: str = ""


def version_newer(target_urls: list[str]) -> list[_SortData]:
    _DISTRIBUTION_LIST = [
        "debian",
        "ubuntu",
        "fedora",
        "centos",
        "almalinux",
        "rockylinux",
        "miraclelinux",
        "opensuse",
    ]
    _FLAVOR_LIST = [
        "live-server",
        "desktop",
        "server",
        "netinst",
        "dvd",
        "mini.iso",
        "boot",
        "gnome",
        "xfce",
        "kde",
        "lxde",
        "lxqt",
        "mate",
        "cinnamon",
        "standard",
        "lomiri",
        "minimal",
        "rtm",
        "media",
        "offline",
        "online",
    ]
    _DEVELOPMENT_VERSION = [
        "oldoldstable",
        "oldstable",
        "stable",
        "testing",
        "testing-daily",
        "testing-weekly",
        "testing-monthly",
        "sid",
        "unstable",
        "experimental",
        "latest",
        "tumbleweed",
    ]

    _CODE_LIST = [
        {"distribution": "Debian", "version": "1.1", "codename": "Buzz"},
        {"distribution": "Debian", "version": "1.2", "codename": "Rex"},
        {"distribution": "Debian", "version": "1.3", "codename": "Bo"},
        {"distribution": "Debian", "version": "2.0", "codename": "Hamm"},
        {"distribution": "Debian", "version": "2.1", "codename": "Slink"},
        {"distribution": "Debian", "version": "2.2", "codename": "Potato"},
        {"distribution": "Debian", "version": "3.0", "codename": "Woody"},
        {"distribution": "Debian", "version": "3.1", "codename": "Sarge"},
        {"distribution": "Debian", "version": "4.0", "codename": "Etch"},
        {"distribution": "Debian", "version": "5.0", "codename": "Lenny"},
        {"distribution": "Debian", "version": "6.0", "codename": "Squeeze"},
        {"distribution": "Debian", "version": "7.0", "codename": "Wheezy"},
        {"distribution": "Debian", "version": "8.0", "codename": "Jessie"},
        {"distribution": "Debian", "version": "9.0", "codename": "Stretch"},
        {"distribution": "Debian", "version": "10.0", "codename": "Buster"},
        {"distribution": "Debian", "version": "11.0", "codename": "Bullseye"},
        {"distribution": "Debian", "version": "12.0", "codename": "Bookworm"},
        {"distribution": "Debian", "version": "13.0", "codename": "Trixie"},
        {"distribution": "Debian", "version": "14.0", "codename": "Forky"},
        {"distribution": "Debian", "version": "15.0", "codename": "Duke"},
        {"distribution": "Debian", "version": "testing", "codename": "Testing"},
        {
            "distribution": "Debian",
            "version": "testing-daily",
            "codename": "Daily build(testing)",
        },
        {"distribution": "Debian", "version": "sid", "codename": "SID"},
        {"distribution": "Ubuntu", "version": "4.10", "codename": "Warty Warthog"},
        {"distribution": "Ubuntu", "version": "5.04", "codename": "Hoary Hedgehog"},
        {"distribution": "Ubuntu", "version": "5.10", "codename": "Breezy Badger"},
        {"distribution": "Ubuntu", "version": "6.06", "codename": "Dapper Drake"},
        {"distribution": "Ubuntu", "version": "6.10", "codename": "Edgy Eft"},
        {"distribution": "Ubuntu", "version": "7.04", "codename": "Feisty Fawn"},
        {"distribution": "Ubuntu", "version": "7.10", "codename": "Gutsy Gibbon"},
        {"distribution": "Ubuntu", "version": "8.04", "codename": "Hardy Heron"},
        {"distribution": "Ubuntu", "version": "8.10", "codename": "Intrepid Ibex"},
        {"distribution": "Ubuntu", "version": "9.04", "codename": "Jaunty Jackalope"},
        {"distribution": "Ubuntu", "version": "9.10", "codename": "Karmic Koala"},
        {"distribution": "Ubuntu", "version": "10.04", "codename": "Lucid Lynx"},
        {"distribution": "Ubuntu", "version": "10.10", "codename": "Maverick Meerkat"},
        {"distribution": "Ubuntu", "version": "11.04", "codename": "Natty Narwhal"},
        {"distribution": "Ubuntu", "version": "11.10", "codename": "Oneiric Ocelot"},
        {"distribution": "Ubuntu", "version": "12.04", "codename": "Precise Pangolin"},
        {"distribution": "Ubuntu", "version": "12.10", "codename": "Quantal Quetzal"},
        {"distribution": "Ubuntu", "version": "13.04", "codename": "Raring Ringtail"},
        {"distribution": "Ubuntu", "version": "13.10", "codename": "Saucy Salamander"},
        {"distribution": "Ubuntu", "version": "14.04", "codename": "Trusty Tahr"},
        {"distribution": "Ubuntu", "version": "14.10", "codename": "Utopic Unicorn"},
        {"distribution": "Ubuntu", "version": "15.04", "codename": "Vivid Vervet"},
        {"distribution": "Ubuntu", "version": "15.10", "codename": "Wily Werewolf"},
        {"distribution": "Ubuntu", "version": "16.04", "codename": "Xenial Xerus"},
        {"distribution": "Ubuntu", "version": "16.10", "codename": "Yakkety Yak"},
        {"distribution": "Ubuntu", "version": "17.04", "codename": "Zesty Zapus"},
        {"distribution": "Ubuntu", "version": "17.10", "codename": "Artful Aardvark"},
        {"distribution": "Ubuntu", "version": "18.04", "codename": "Bionic Beaver"},
        {"distribution": "Ubuntu", "version": "18.10", "codename": "Cosmic Cuttlefish"},
        {"distribution": "Ubuntu", "version": "19.04", "codename": "Disco Dingo"},
        {"distribution": "Ubuntu", "version": "19.10", "codename": "Eoan Ermine"},
        {"distribution": "Ubuntu", "version": "20.04", "codename": "Focal Fossa"},
        {"distribution": "Ubuntu", "version": "20.10", "codename": "Groovy Gorilla"},
        {"distribution": "Ubuntu", "version": "21.04", "codename": "Hirsute Hippo"},
        {"distribution": "Ubuntu", "version": "21.10", "codename": "Impish Indri"},
        {"distribution": "Ubuntu", "version": "22.04", "codename": "Jammy Jellyfish"},
        {"distribution": "Ubuntu", "version": "22.10", "codename": "Kinetic Kudu"},
        {"distribution": "Ubuntu", "version": "23.04", "codename": "Lunar Lobster"},
        {"distribution": "Ubuntu", "version": "23.10", "codename": "Mantic Minotaur"},
        {"distribution": "Ubuntu", "version": "24.04", "codename": "Noble Numbat"},
        {"distribution": "Ubuntu", "version": "24.10", "codename": "Oracular Oriole"},
        {"distribution": "Ubuntu", "version": "25.04", "codename": "Plucky Puffin"},
        {"distribution": "Ubuntu", "version": "25.10", "codename": "Questing Quokka"},
        {"distribution": "Ubuntu", "version": "26.04", "codename": "Resolute Raccoon"},
        {"distribution": "Ubuntu", "version": "26.10", "codename": "Stonking Stingray"},
    ]

    @dataclass
    class _CodeName:
        distribution: str = ""
        version: str = ""
        codename: str = ""
        codename_id: str = ""

    _code_name: list[_CodeName] = []
    for d in _CODE_LIST:
        _code_name.append(
            _CodeName(
                distribution=d["distribution"],
                version=d["version"],
                codename=d["codename"],
                codename_id=d["codename"].split()[0].lower(),
            )
        )

    def _get_distribution(url_lower: str) -> str:
        for s in _DISTRIBUTION_LIST:
            if s in url_lower or (s == "rockylinux" and "rocky" in url_lower):
                return "rockylinux" if s == "rocky" else s
        return "_generic_os"

    def _get_flavor(filename_lower: str) -> str:
        for s in _FLAVOR_LIST:
            if s in filename_lower:
                return s
        return "_generic"

    def _get_development(filename_lower: str, url_lower: str) -> str:
        for s in _DEVELOPMENT_VERSION:
            if s in filename_lower or s in url_lower:
                return s
        return "_generic"

    def _get_version(
        url_lower: str, filename_lower: str, version_pattern: re.Pattern
    ) -> str:
        for d in _code_name:
            if (
                filename_lower == "mini.iso"
                and (
                    f"/{d.codename_id}/" in url_lower
                    or f"/{d.codename_id}-updates/" in url_lower
                )
            ) or d.codename_id in filename_lower:
                match = version_pattern.search(filename_lower)
                if match:
                    return match.group(2)
                return d.version
        match = version_pattern.search(filename_lower)
        if match:
            return match.group(2)
        return _get_development(filename_lower, url_lower)

    def _final_sort_key(item: _SortData):
        file_name_lower = item.filename.lower()
        url_lower = item.url.lower()
        dist_weight = 999
        for i, s in enumerate(_DISTRIBUTION_LIST):
            if s in item.distribution:
                dist_weight = 1000 - i
                break
        is_live = 1 if "live" in file_name_lower else 2
        if "mini.iso" in file_name_lower:
            is_live = 0
        is_dev = False
        for s in _DEVELOPMENT_VERSION:
            if s in file_name_lower or s in url_lower:
                is_dev = True
                break

        def _format_version(version_str: str) -> str:
            number_pattern = re.compile(r"(\d+)(.*)")
            if not number_pattern:
                return version_str
            formatted_parts = []
            for n in version_str.split("."):
                match = number_pattern.match(n)
                if match:
                    num_part = int(match.group(1))
                    alpha_part = match.group(2)
                    formatted_parts.append(f"{num_part:03}{alpha_part}")
                else:
                    formatted_parts.append(n)
            major_ver = formatted_parts[0]
            if formatted_parts[1:]:
                minor_ver = ".".join(formatted_parts[1:])
                if not formatted_parts[2:]:
                    minor_ver += ".000"
            else:
                minor_ver = "000.000"
            result_ver = f"{major_ver}.{minor_ver}"
            return result_ver

        clean_v = re.sub(r"(\d+)h(\d+)", r"\1.\2", item.version)
        num_match = re.search(r"(\d+(?:\.\d+)*)", clean_v)
        flavor_weight = "".join(chr(255 - ord(c)) for c in item.flavor)
        if num_match:
            try:
                v_str = _format_version(num_match.group(1))
                v_obj = parse_version(v_str)
                return (
                    dist_weight,
                    2,
                    v_obj,
                    is_live,
                    flavor_weight,
                    item.filename,
                )
            except (InvalidVersion, TypeError, ValueError):
                pass
        if is_dev:
            return (
                dist_weight,
                3,
                parse_version("999.999.999"),
                is_live,
                flavor_weight,
                item.filename,
            )
        return (
            dist_weight,
            0,
            parse_version("0.0.0"),
            is_live,
            flavor_weight,
            item.filename,
        )

    # -------------------------------------------------------------------------
    # _pattern_str = r"^([a-zA-Z0-9_-]+?)-([0-9.]+|\d+-\d+|testing|sid|stream|latest|leap|tumbleweed)"
    _pattern_str = rf"^([a-zA-Z0-9_-]+?)-([0-9.]+|{'|'.join(_DEVELOPMENT_VERSION)})"
    _version_pattern = re.compile(_pattern_str)
    _resolved_urls = list(set(target_urls))
    _target_datas: list[_SortData] = []
    for _url in _resolved_urls:
        _url_lower = _url.lower()
        _filename = Path(_url).name
        _filename_lower = _filename.lower()
        dist = _get_distribution(_url_lower)
        flav = _get_flavor(_filename_lower)
        ver = _get_version(_url_lower, _filename_lower, _version_pattern)
        _target_datas.append(
            _SortData(
                url=_url,
                distribution=dist,
                filename=_filename,
                version=ver,
                flavor=flav,
            )
        )
    _sorted_datas = sorted(_target_datas, key=_final_sort_key, reverse=True)
    _result_datas: list[_SortData] = []
    _seen_groups = set()
    major_pattern = re.compile(r"(\d+)")
    for data in _sorted_datas:
        major_match = major_pattern.search(data.version)
        if major_match and not any(
            kw in data.version for kw in _DEVELOPMENT_VERSION + ["stream", "leap"]
        ):
            gen_group = major_match.group(1)
        else:
            gen_group = data.version

        group_key = f"{data.distribution}-{gen_group}-{data.flavor}"

        if group_key not in _seen_groups:
            _seen_groups.add(group_key)
            _result_datas.append(data)
    return sorted(_result_datas, key=_final_sort_key, reverse=True)


target_urls = [
    "https://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso",
    "https://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso",
    "https://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/installer-amd64/current/images/netboot/mini.iso",
    "https://archive.ubuntu.com/ubuntu/dists/xenial-updates/main/installer-amd64/current/images/netboot/mini.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-11.11.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-11.11.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-11.11.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-11.11.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-11.11.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-11.11.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-11.11.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-11.11.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-12.15.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-12.15.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-12.15.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-12.15.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-12.15.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-12.15.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-12.15.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-12.15.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-12.15.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.7.0-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.7.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.7.0-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-13.7.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-13.7.0-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-kde.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lomiri.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lomiri.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lomiri.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxqt.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-mate.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-xfce.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-xfce.iso",
    "https://cdimage.ubuntu.com/ubuntu-server/stonking/daily-live/current/stonking-live-server-amd64.iso",
    "https://cdimage.ubuntu.com/ubuntu-server/stonking/daily-live/current/stonking-live-server-amd64.iso",
    "https://cdimage.ubuntu.com/ubuntu/stonking/daily-live/current/stonking-desktop-amd64.iso",
    "https://cdimage.ubuntu.com/ubuntu/stonking/daily-live/current/stonking-desktop-amd64.iso",
    "https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-dvd-x86_64-43-1.6.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-netinst-x86_64-43-1.6.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-dvd-x86_64-44-1.7.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-netinst-x86_64-44-1.7.iso",
    "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso",
    "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Media.iso",
    "https://download.opensuse.org/distribution/leap/16.0/offline/Leap-16.0-offline-installer-x86_64.install.iso",
    "https://download.opensuse.org/distribution/leap/16.0/offline/Leap-16.0-online-installer-x86_64.install.iso",
    "https://download.opensuse.org/distribution/leap/16.1/offline/Leap-16.1-offline-installer-x86_64.install.iso",
    "https://download.opensuse.org/distribution/leap/16.1/offline/Leap-16.1-online-installer-x86_64.install.iso",
    "https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso",
    "https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso",
    "https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8-latest-x86_64-boot.iso",
    "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-boot.iso",
    "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-dvd.iso",
    "https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10-latest-x86_64-boot.iso",
    "https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10-latest-x86_64-dvd.iso",
    "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso",
    "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso",
    "https://mirror.stream.centos.org/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso",
    "https://mirror.stream.centos.org/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso",
    "https://releases.ubuntu.com/14.04/ubuntu-14.04.6-desktop-amd64.iso",
    "https://releases.ubuntu.com/14.04/ubuntu-14.04.6-desktop-amd64.iso",
    "https://releases.ubuntu.com/14.04/ubuntu-14.04.6-server-amd64.iso",
    "https://releases.ubuntu.com/14.04/ubuntu-14.04.6-server-amd64.iso",
    "https://releases.ubuntu.com/16.04/ubuntu-16.04.7-desktop-amd64.iso",
    "https://releases.ubuntu.com/16.04/ubuntu-16.04.7-desktop-amd64.iso",
    "https://releases.ubuntu.com/16.04/ubuntu-16.04.7-server-amd64.iso",
    "https://releases.ubuntu.com/16.04/ubuntu-16.04.7-server-amd64.iso",
    "https://releases.ubuntu.com/18.04/ubuntu-18.04.6-desktop-amd64.iso",
    "https://releases.ubuntu.com/18.04/ubuntu-18.04.6-desktop-amd64.iso",
    "https://releases.ubuntu.com/18.04/ubuntu-18.04.6-live-server-amd64.iso",
    "https://releases.ubuntu.com/18.04/ubuntu-18.04.6-live-server-amd64.iso",
    "https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso",
    "https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso",
    "https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso",
    "https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso",
    "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso",
    "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso",
    "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso",
    "https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso",
    "https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso",
    "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso",
    "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso",
    "https://releases.ubuntu.com/24.04/ubuntu-24.04.4-live-server-amd64.iso",
    "https://releases.ubuntu.com/24.04/ubuntu-24.04.5-live-server-amd64.iso",
    "https://releases.ubuntu.com/24.04/ubuntu-24.04.5-live-server-amd64.iso",
    "https://releases.ubuntu.com/25.10/ubuntu-25.10-desktop-amd64.iso",
    "https://releases.ubuntu.com/25.10/ubuntu-25.10-desktop-amd64.iso",
    "https://releases.ubuntu.com/25.10/ubuntu-25.10-live-server-amd64.iso",
    "https://releases.ubuntu.com/25.10/ubuntu-25.10-live-server-amd64.iso",
    "https://releases.ubuntu.com/26.04/ubuntu-26.04-desktop-amd64.iso",
    "https://releases.ubuntu.com/26.04/ubuntu-26.04-live-server-amd64.iso",
    "https://releases.ubuntu.com/26.04/ubuntu-26.04.1-desktop-amd64.iso",
    "https://releases.ubuntu.com/26.04/ubuntu-26.04.1-desktop-amd64.iso",
    "https://releases.ubuntu.com/26.04/ubuntu-26.04.1-live-server-amd64.iso",
    "https://releases.ubuntu.com/26.04/ubuntu-26.04.1-live-server-amd64.iso",
    "https://repo.almalinux.org/almalinux/8/isos/x86_64/AlmaLinux-8-latest-x86_64-boot.iso",
    "https://repo.almalinux.org/almalinux/8/isos/x86_64/AlmaLinux-8-latest-x86_64-dvd.iso",
    "https://repo.almalinux.org/almalinux/8/live/x86_64/AlmaLinux-8-latest-x86_64-Live-GNOME.iso",
    "https://repo.almalinux.org/almalinux/8/live/x86_64/AlmaLinux-8-latest-x86_64-Live-KDE.iso",
    "https://repo.almalinux.org/almalinux/8/live/x86_64/AlmaLinux-8-latest-x86_64-Live-MATE.iso",
    "https://repo.almalinux.org/almalinux/8/live/x86_64/AlmaLinux-8-latest-x86_64-Live-XFCE.iso",
    "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso",
    "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso",
    "https://repo.almalinux.org/almalinux/9/live/x86_64/AlmaLinux-9-latest-x86_64-Live-GNOME.iso",
    "https://repo.almalinux.org/almalinux/9/live/x86_64/AlmaLinux-9-latest-x86_64-Live-KDE.iso",
    "https://repo.almalinux.org/almalinux/9/live/x86_64/AlmaLinux-9-latest-x86_64-Live-MATE.iso",
    "https://repo.almalinux.org/almalinux/9/live/x86_64/AlmaLinux-9-latest-x86_64-Live-XFCE.iso",
    "https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10-latest-x86_64-boot.iso",
    "https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10-latest-x86_64-dvd.iso",
    "https://repo.almalinux.org/almalinux/10/live/x86_64/AlmaLinux-10-latest-x86_64-Live-GNOME.iso",
    "https://repo.almalinux.org/almalinux/10/live/x86_64/AlmaLinux-10-latest-x86_64-Live-KDE.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/8.4-released/x86_64/MIRACLELINUX-8.4-rtm-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/8.6-released/x86_64/MIRACLELINUX-8.6-rtm-minimal-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/8.6-released/x86_64/MIRACLELINUX-8.6-rtm-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/8.8-released/x86_64/MIRACLELINUX-8.8-rtm-minimal-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/8.8-released/x86_64/MIRACLELINUX-8.8-rtm-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/8.10-released/x86_64/MIRACLELINUX-8.10-rtm-minimal-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/8.10-released/x86_64/MIRACLELINUX-8.10-rtm-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.0-released/x86_64/MIRACLELINUX-9.0-rtm-minimal-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.0-released/x86_64/MIRACLELINUX-9.0-rtm-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.2-released/x86_64/MIRACLELINUX-9.2-rtm-minimal-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.2-released/x86_64/MIRACLELINUX-9.2-rtm-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.4-released/x86_64/MIRACLELINUX-9.4-rtm-minimal-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.4-released/x86_64/MIRACLELINUX-9.4-rtm-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.6-released/x86_64/MIRACLELINUX-9.6-rtm-minimal-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.6-released/x86_64/MIRACLELINUX-9.6-rtm-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.8-released/x86_64/MIRACLELINUX-9.8-rtm-x86_64.iso",
    "https://www.memtest.org/download/v8.10/mt86plus_8.10_x86_64.grub.iso.zip",
]
sorted_urls = []
sorted_urls = version_newer(target_urls)
for d in sorted_urls:
    print(f"{d.filename:<50},{d.version:<10},{d.url}")
