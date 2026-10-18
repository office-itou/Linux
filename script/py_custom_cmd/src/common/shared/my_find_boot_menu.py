# --- Python library ----------------------------------------------------------
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# =============================================================================
def find_grub_cfg(search_dir: Path) -> Path:
    for _dir in [
        "/",
        "/boot/grub",
        "/boot/grub2",
        "/efi/boot",
        "/efi/BOOT",
        "/EFI/boot",
        "/EFI/BOOT",
    ]:
        for _path in (search_dir / _dir.lstrip("/")).glob("grub.cfg"):
            if _path.exists():
                return _path
    return Path()


def find_isolinux_cfg(search_dir: Path) -> Path:
    for _dir in [
        "/",
        "/isolinux",
        "/syslinux",
    ]:
        for _path in (search_dir / _dir.lstrip("/")).glob("isolinux.cfg"):
            if _path.exists():
                return _path
    return Path()
