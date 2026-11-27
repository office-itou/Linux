#!/usr/bin/env python3

# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import InfoNetworkIF


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
def func():
    info_nics = InfoNetworkIF("br0")
    for _key, _val in info_nics.data.__dict__.items():
        print(f"nics.{_key}={_val}")
    for _key, _val in info_nics.data.ipv4.__dict__.items():
        print(f"ipv4.{_key}={_val}")
    for _key, _val in info_nics.data.ipv6.__dict__.items():
        print(f"ipv6.{_key}={_val}")
    for _key, _val in info_nics.data.link.__dict__.items():
        print(f"link.{_key}={_val}")


_base_path: Path = Path("/sys/devices")


def ffff():
    for _nwrk_devs in ["eth0", "ens160", "enp3s0", "lo", "br0"]:
        for _data_path in _base_path.rglob(f"**/net/{_nwrk_devs}"):
            if _data_path and _data_path.exists() and _data_path.is_dir():
                print(_data_path)


def aaaa():
    for _nwrk_devs in ["eth0", "ens160", "enp3s0", "lo", "br0"]:
        _data_path = next((p for p in _base_path.rglob(f"**/net/{_nwrk_devs}")), None)
        if _data_path and _data_path.exists() and _data_path.is_dir():
            print(_data_path)


_base_path: Path = Path("/sys/devices")
for _find_path in _base_path.rglob("**/net/*"):
    _file_path = _find_path / "operstate"
    _nics_stat = _file_path.read_text().strip().lower()
    if _nics_stat != "up":
        continue
    _uper_path = next(_find_path.glob("upper_*"), None)
    if _uper_path:
        continue
    print(_find_path)
    break
