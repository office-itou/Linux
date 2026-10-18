# --- python library ----------------------------------------------------------
import asyncio
import shutil

# import subprocess
import tempfile
from asyncio.subprocess import Process
from pathlib import Path
from typing import Any, Mapping

# --- my library --------------------------------------------------------------
# from common.shared.my_distribution_dat import ORDERED_DISTRIBUTIONS
from common.utils import (
    debug_logger,
    extract_efi_partition,
    extract_mbr_partition,
    get_caller_name,
    get_partition_type,
    get_volume_label,
    handle_fatal_error,
    message_end,
    message_info,
    message_start,
)


# =============================================================================
@debug_logger
async def generate_iso_file(
    srcs_path: Path, dest_path: Path, target_path: Path
) -> bool:
    _caller = get_caller_name()
    _status: bool = False
    _temp_objs: object = tempfile.TemporaryDirectory()
    _temp_dirs: Path = Path(_temp_objs.name)
    _temp_path: Path = _temp_dirs / dest_path.name
    _temp_file: str = str(_temp_path)
    _srcs_file: str = str(srcs_path)
    _dest_file: str = str(dest_path)
    _tget_file: str = str(target_path)
    _dest_labl: str = get_volume_label(_srcs_file)
    _isos_ptyp: str = get_partition_type(_srcs_file)
    _hbrd_path: Path = Path()  # hybrid
    _mbrf_path: Path = Path()  # mbr
    _uefi_path: Path = Path()  # uefi
    _bcat_path: Path = Path()  # eltorito-catalog
    _etri_path: Path = Path()  # eltorito-boot
    # -------------------------------------------------------------------------
    # uefi
    #   grub/efi.img
    #   images/efiboot.img
    #   x86_64/efi
    # boot catalog
    #   boot.cat
    #   boot.catalog
    #   isolinux/boot.cat
    # eltorito.img / isolinux.bin
    #   boot/eltorito.img
    #   boot/grub/i386-pc/eltorito.img
    #   boot/x86_64/loader/eltorito.img
    #   boot/x86_64/loader/isolinux.bin
    #   images/eltorito.img
    #   isolinux.bin
    #   isolinux/isolinux.bin
    # -------------------------------------------------------------------------
    _mbrf_path = _temp_dirs / "mbr.img"
    _uefi_path = _temp_dirs / "efi.img"
    match _isos_ptyp:
        case "dos":
            _hbrd_path = _mbrf_path
        case "gpt":
            pass
        case _:
            pass
    for _path in target_path.rglob("*"):
        if not _path.is_file():
            continue
        _file_str = str(_path.name)
        if _file_str == "efi.img" or _file_str == "efiboot.img" or _file_str == "efi":
            _uefi_path = _path
        elif _file_str == "boot.cat" or _file_str == "boot.catalog":
            _bcat_path = _path
        elif _file_str == "eltorito.img" or _file_str == "isolinux.bin":
            _etri_path = _path
    _temp_dirs.mkdir(parents=True, exist_ok=True)
    # --- get mbr image file --------------------------------------------------
    if not _mbrf_path.exists():
        extract_mbr_partition(src_path=srcs_path, dest_path=_mbrf_path)
    # --- get uefi image file -------------------------------------------------
    if not _uefi_path.exists():
        extract_efi_partition(src_path=srcs_path, dest_path=_uefi_path)
    # --- xorriso -------------------------------------------------------------
    _sudo_args: list[str] = ["sudo", "-n"]
    _nice_args: list[str] = ["nice", "-n", "19"]
    _xorriso_args: list[str] = [
        *_sudo_args,
        *_nice_args,
        "xorrisofs",
        "-rock",
        "-joliet",
    ]
    if _dest_labl:
        _xorriso_args += ["-volid", _dest_labl]
    _xorriso_args += ["-iso-level", "3"]
    if _hbrd_path:
        message_info(_caller, "isohybrid-mbr", omit=True)
        _xorriso_args += [
            "-isohybrid-mbr",
            str(_hbrd_path),
            "-isohybrid-gpt-basdat",
            "-isohybrid-apm-hfsplus",
        ]
    else:
        message_info(_caller, "grub2-mbr", omit=True)
        _xorriso_args += [
            "--grub2-mbr",
            str(_mbrf_path),
            "-partition_offset",
            "16-appended_part_as_gpt",
            "-append_partition",
            "2",
            "C12A7328-F81F-11D2-BA4B-00A0C93EC93B",
            str(_uefi_path.relative_to(target_path)),
            "-iso_mbr_part_type",
            "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7",
        ]
    if _bcat_path:
        _xorriso_args += ["-eltorito-catalog", str(_bcat_path.relative_to(target_path))]
    _xorriso_args += ["--boot-catalog-hide"]
    if _etri_path:
        _xorriso_args += [
            "-eltorito-boot",
            str(_etri_path.relative_to(target_path)),
            "-no-emul-boot",
        ]
    _xorriso_args += ["-boot-load-size", "4", "-boot-info-table", "-eltorito-alt-boot"]
    if _hbrd_path:
        _xorriso_args += [
            "-e",
            str(_uefi_path.relative_to(target_path)),
            "-no-emul-boot",
        ]
    else:
        _xorriso_args += [
            "-e",
            "--interval:appended_partition_2:all::",
            "-no-emul-boot",
        ]
    _xorriso_args += ["-output", _temp_file, _tget_file]
    # -------------------------------------------------------------------------
    _kwargs: Mapping[str, Any] = {
        "stdout": asyncio.subprocess.PIPE,
        "stderr": asyncio.subprocess.PIPE,
    }
    try:
        # _xorriso_proc = subprocess.run(
        #    _xorriso_args, check=True, capture_output=True, text=True
        # )

        message_start(_caller, omit=True)
        message_info(_caller, f"target: {_tget_file}", omit=True)
        message_info(_caller, f"tmpout: {_temp_file}", omit=True)
        _xorriso_proc: Process = await asyncio.create_subprocess_exec(
            *_xorriso_args, **_kwargs
        )
        _stdout, _stderr = await _xorriso_proc.communicate()
        _status = _xorriso_proc.returncode == 0
        message_info(_caller, f"output: {dest_path}", omit=True)
        if not _status:
            if _stdout:
                message_info(_caller, f"stdout: {_stdout.decode()}")
            if _stderr:
                message_info(_caller, f"stderr: {_stderr.decode()}")
        if _status and _temp_path.exists():
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(None, shutil.copy2, _temp_path, dest_path)
        message_end(_caller, omit=True)
    except Exception as e:
        handle_fatal_error(_caller, e, raise_exit=False)
        _status = False
    finally:
        if _temp_dirs.exists():
            _temp_objs.cleanup()
    return _status
