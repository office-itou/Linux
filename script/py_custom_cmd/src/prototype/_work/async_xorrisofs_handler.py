# --- python library ----------------------------------------------------------
import asyncio
import itertools
import re
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

# --- my library --------------------------------------------------------------
from common.shared import (
    ConfigurationData,
    InfoCommon,
    MediaData,
)
from common.utils import (
    async_subprocess,
    debug_logger,
    extract_efi_partition,
    extract_mbr_partition,
    file_read,
    file_write,
    get_caller_name,
    get_partition_type,
    get_volume_label,
    handle_fatal_error,
    infosystem,
    message_end,
    message_info,
    message_start,
)

# --- import module -----------------------------------------------------------
from generate_boot_option import GenerateBootOption


# --- class and function ------------------------------------------------------
sudo_args = ["sudo", "-n"]
nice_args = ["nice", "-n", "19"]
kwargs: Mapping[str, Any] = {
    "stdout": asyncio.subprocess.PIPE,
    "stderr": asyncio.subprocess.PIPE,
}


@dataclass
class MkisoData:
    # --- data class ----------------------------------------------------------
    mdia_data: MediaData | None = None  # media.dat data class
    # --- input/output interface ----------------------------------------------
    tget_path: Path | None = None  # target directory path
    srce_path: Path | None = None  # source file path
    dest_path: Path | None = None  # destination file path
    # --- temporary -----------------------------------------------------------
    temp_obje: tempfile.TemporaryDirectory | None = None
    temp_dire: Path | None = None  # temporary directory path
    temp_path: Path | None = None  # temporary file path
    # --- overlay -------------------------------------------------------------
    mntp_dovl: Path | None = None  # overlay directory path
    mntp_dupr: Path | None = None  # upperdir directory path
    mntp_dlow: Path | None = None  # lowerdir directory path
    mntp_dwkd: Path | None = None  # workdir directory path
    mntp_dmrg: Path | None = None  # merged directory path
    # --- boot menu -----------------------------------------------------------
    grub_path: Path | None = None  # grub.cfg fiel path
    ilnx_path: Path | None = None  # isolinux.cfg file path
    auto_path: Path | None = None  # autoinstall configuration file
    thme_path: Path | None = None  # autoinstall configuration file
    gaut_path: Path | None = None  # grub autoinstall menu file
    gthm_path: Path | None = None  # "    theme file
    iaut_path: Path | None = None  # isolinux autoinstall menu file
    ithm_path: Path | None = None  # "    theme file
    boot_optn: list[ConfigurationData] | None = None  # boot options
    # --- iso image -----------------------------------------------------------
    mbrf_path: Path | None = None  # mbr file path
    uefi_path: Path | None = None  # efi file path
    hbrd_path: Path | None = None  # hybrid mbr file path
    bcat_path: Path | None = None  # boot catalog file path
    etri_path: Path | None = None  # eltorito boot file path
    isos_ptyp: str | None = None  # iso image partition type
    dest_labl: str | None = None  # volume label


@debug_logger
def init_mkiso(
    info_comm: InfoCommon,
    mdia_data: MediaData,
) -> MkisoData:
    _mkiso = MkisoData()
    if (
        not mdia_data
        or not mdia_data.entry_name
        or not mdia_data.iso_path
        or not mdia_data.rmk_path
    ):
        return _mkiso
    # --- data class ----------------------------------------------------------
    _boot_option = GenerateBootOption()
    _mkiso.mdia_data = mdia_data
    # --- input/output interface ----------------------------------------------
    _mkiso.tget_path = info_comm.conf.get_path(key="DIRS_IMGS") / mdia_data.entry_name
    _mkiso.srce_path = Path(mdia_data.iso_path)
    _mkiso.dest_path = Path(mdia_data.rmk_path)
    # --- temporary -----------------------------------------------------------
    _mkiso.temp_obje = tempfile.TemporaryDirectory(ignore_cleanup_errors=True)
    _mkiso.temp_dire = Path(_mkiso.temp_obje.name)
    _mkiso.temp_path = _mkiso.temp_dire / f"{_mkiso.dest_path.name}.tmp"
    # --- overlay -------------------------------------------------------------
    _mkiso.mntp_dovl = Path(f"{str(_mkiso.temp_path)}.overlay")
    _mkiso.mntp_dupr = _mkiso.mntp_dovl / "upper"
    _mkiso.mntp_dlow = _mkiso.mntp_dovl / "lower"
    _mkiso.mntp_dwkd = _mkiso.mntp_dovl / "work"
    _mkiso.mntp_dmrg = _mkiso.mntp_dovl / "merged"
    # --- boot menu -----------------------------------------------------------
    _boot_option = GenerateBootOption()
    _mkiso.boot_optn = _boot_option.generate_boot_option(mdia_data=_mkiso.mdia_data)
    _mkiso.auto_path = info_comm.conf.get_path(key="AUTO_INST")
    _mkiso.thme_path = info_comm.conf.get_path(key="AUTO_THME")
    _mkiso.gaut_path = info_comm.conf.get_path(key="PATH_GAUT")
    _mkiso.gthm_path = info_comm.conf.get_path(key="PATH_GTHM")
    _mkiso.iaut_path = info_comm.conf.get_path(key="PATH_IAUT")
    _mkiso.ithm_path = info_comm.conf.get_path(key="PATH_ITHM")
    # --- return --------------------------------------------------------------
    return _mkiso


@debug_logger
async def async_mount(mkiso: MkisoData) -> bool:
    if mkiso is None:
        return False

    # --- mount: iso image ----------------------------------------------------
    @debug_logger
    async def _mount_iso(file: Path, mntdir: Path) -> bool:
        _command: list[str] = [
            *sudo_args,
            "mount",
            "--read-only",
            "--options",
            "loop",
            str(file),
            str(mntdir),
        ]
        _status: bool = await async_subprocess(*_command, **kwargs)
        return _status

    # --- mount: bind ---------------------------------------------------------
    @debug_logger
    async def _mount_bind(olddir: Path, newdir: Path) -> bool:
        _command: list[str] = [
            *sudo_args,
            "mount",
            "--read-only",
            "--bind",
            str(olddir),
            str(newdir),
        ]
        _status: bool = await async_subprocess(*_command, **kwargs)
        return _status

    # --- mount: overlay ------------------------------------------------------
    @debug_logger
    async def _mount_overlay(
        lowerdir: Path, upperdir: Path, workdir: Path, merged: Path
    ) -> bool:
        _command: list[str] = [
            *sudo_args,
            "mount",
            "--types",
            "overlay",
            "overlay",
            "--options",
            f"lowerdir={str(lowerdir)},upperdir={str(upperdir)},workdir={str(workdir)},redirect_dir=off,index=off,metacopy=off",
            str(merged),
        ]
        _status: bool = await async_subprocess(*_command, **kwargs)
        return _status

    # --- mount ---------------------------------------------------------------
    assert mkiso.tget_path is not None
    assert mkiso.srce_path is not None
    assert mkiso.mntp_dlow is not None
    assert mkiso.mntp_dupr is not None
    assert mkiso.mntp_dwkd is not None
    assert mkiso.mntp_dmrg is not None
    #_status: bool = await _mount_bind(olddir=mkiso.tget_path, newdir=mkiso.mntp_dlow)
    _status: bool = await _mount_iso(file=mkiso.srce_path, mntdir=mkiso.mntp_dlow)
    if _status:
        _status: bool = await _mount_overlay(
            lowerdir=mkiso.mntp_dlow,
            upperdir=mkiso.mntp_dupr,
            workdir=mkiso.mntp_dwkd,
            merged=mkiso.mntp_dmrg,
        )
    return _status


@debug_logger
async def async_umount(mkiso: MkisoData) -> bool:
    if mkiso is None:
        return False

    # --- uomunt sub ----------------------------------------------------------
    @debug_logger
    async def _umount(directory: Path) -> bool:
        _command: list[str] = [*sudo_args, "umount", str(directory)]
        _status: bool = await async_subprocess(*_command, **kwargs)
        if _status:
            return _status
        # --- force -----------------------------------------------------------
        _command: list[str] = [*sudo_args, "umount", "--force", str(directory)]
        _status: bool = await async_subprocess(*_command, **kwargs)
        if _status:
            return _status
        # --- lazy ------------------------------------------------------------
        _command: list[str] = [*sudo_args, "umount", "--lazy", str(directory)]
        _status: bool = await async_subprocess(*_command, **kwargs)
        return _status

    # --- umount --------------------------------------------------------------
    assert mkiso.mntp_dmrg is not None
    assert mkiso.mntp_dlow is not None
    _status_overlay: bool = await _umount(directory=mkiso.mntp_dmrg)
    _status_bind: bool = await _umount(directory=mkiso.mntp_dlow)
    return bool(_status_overlay and _status_bind)


@debug_logger
async def async_boot_menu(info_comm: InfoCommon, mkiso: MkisoData) -> bool:
    # --- boot menu: grub -----------------------------------------------------
    @debug_logger
    async def _boot_menu(
        var_pattern: re.Pattern[str],
        find_list: list[ConfigurationData],
        tmpl_path: Path,
        outp_path: Path,
    ) -> bool:
        def _find(class_data, **kwargs) -> ConfigurationData:
            MISSING = object()
            try:
                return next(
                    _class_data.value
                    for _class_data in class_data
                    if all(
                        getattr(_class_data, _key, MISSING) == _value
                        for _key, _value in kwargs.items()
                    )
                )
            except (OSError, Exception) as e:  # noqa: BLE001
                print(e)

        _read_data = file_read(tmpl_path)
        _conv_data: str = var_pattern.sub(
            lambda m: str(_find(class_data=find_list, key=m.group(1))),
            _read_data,
        )
        file_write(outp_path, _conv_data)
        return True

    # --- boot menu -----------------------------------------------------------
    _var_pattern: re.Pattern[str] = re.compile(r":_([A-Z0-9_]+)_:")
    assert mkiso.grub_path is not None
    assert mkiso.ilnx_path is not None
    assert mkiso.auto_path is not None
    assert mkiso.thme_path is not None
    assert mkiso.gaut_path is not None
    assert mkiso.gthm_path is not None
    assert mkiso.iaut_path is not None
    assert mkiso.ithm_path is not None
    _status_gaut = await _boot_menu(
        var_pattern=_var_pattern,
        find_list=info_comm.conf.data + mkiso.boot_optn,
        tmpl_path=mkiso.gaut_path,
        outp_path=mkiso.grub_path.with_name(mkiso.auto_path.name),
    )
    _status_gthm = await _boot_menu(
        var_pattern=_var_pattern,
        find_list=info_comm.conf.data + mkiso.boot_optn,
        tmpl_path=mkiso.gthm_path,
        outp_path=mkiso.grub_path.with_name(mkiso.thme_path.name),
    )
    _status_iaut = await _boot_menu(
        var_pattern=_var_pattern,
        find_list=info_comm.conf.data + mkiso.boot_optn,
        tmpl_path=mkiso.iaut_path,
        outp_path=mkiso.ilnx_path.with_name(mkiso.auto_path.name),
    )
    _status_ithm = await _boot_menu(
        var_pattern=_var_pattern,
        find_list=info_comm.conf.data + mkiso.boot_optn,
        tmpl_path=mkiso.ithm_path,
        outp_path=mkiso.ilnx_path.with_name(mkiso.thme_path.name),
    )
    return bool(_status_gaut and _status_gthm and _status_iaut and _status_ithm)


@debug_logger
async def async_xorrisofs(mkiso: MkisoData) -> bool:
    _caller = get_caller_name()
    _status: bool = False
    assert mkiso.dest_path is not None
    assert mkiso.temp_path is not None
    assert mkiso.mntp_dmrg is not None
    assert mkiso.uefi_path is not None
    _xorriso_args: list[str] = [
        *sudo_args,
        *nice_args,
        "xorrisofs",
        "-rock",
        "-joliet",
    ]
    # --- volid ---------------------------------------------------------------
    if mkiso.dest_labl:
        _xorriso_args += ["-volid", mkiso.dest_labl]
    # --- iso-level -----------------------------------------------------------
    _xorriso_args += ["-iso-level", "3"]
    # -------------------------------------------------------------------------
    if mkiso.hbrd_path:
        message_info(_caller, "isohybrid-mbr", omit=True)
        _xorriso_args += [
            "-isohybrid-mbr",
            str(mkiso.hbrd_path),
            "-isohybrid-gpt-basdat",
            "-isohybrid-apm-hfsplus",
        ]
    else:
        message_info(_caller, "grub2-mbr", omit=True)
        _xorriso_args += [
            "--grub2-mbr",
            str(mkiso.mbrf_path),
            "-partition_offset",
            "16-appended_part_as_gpt",
            "-append_partition",
            "2",
            "C12A7328-F81F-11D2-BA4B-00A0C93EC93B",
            str(
                mkiso.uefi_path.relative_to(mkiso.mntp_dmrg)
                if mkiso.uefi_path.is_relative_to(mkiso.mntp_dmrg)
                else mkiso.uefi_path
            ),
            "-iso_mbr_part_type",
            "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7",
        ]
    # --- eltorito-catalog ----------------------------------------------------
    if mkiso.bcat_path:
        _xorriso_args += [
            "-eltorito-catalog",
            str(
                mkiso.bcat_path.relative_to(mkiso.mntp_dmrg)
                if mkiso.bcat_path.is_relative_to(mkiso.mntp_dmrg)
                else mkiso.bcat_path
            ),
        ]
    # --- boot-catalog-hide ---------------------------------------------------
    _xorriso_args += ["--boot-catalog-hide"]
    # --- eltorito-boot -------------------------------------------------------
    if mkiso.etri_path:
        _xorriso_args += [
            "-eltorito-boot",
            str(
                mkiso.etri_path.relative_to(mkiso.mntp_dmrg)
                if mkiso.etri_path.is_relative_to(mkiso.mntp_dmrg)
                else mkiso.etri_path
            ),
            "-no-emul-boot",
        ]
    # --- boot-load-size ------------------------------------------------------
    _xorriso_args += [
        "-boot-load-size",
        "4",
        "-boot-info-table",
        "-eltorito-alt-boot",
    ]
    # --- hybrid --------------------------------------------------------------
    if mkiso.hbrd_path:
        _xorriso_args += [
            "-e",
            str(
                mkiso.uefi_path.relative_to(mkiso.mntp_dmrg)
                if mkiso.uefi_path.is_relative_to(mkiso.mntp_dmrg)
                else mkiso.uefi_path
            ),
            "-no-emul-boot",
        ]
    else:
        _xorriso_args += [
            "-e",
            "--interval:appended_partition_2:all::",
            "-no-emul-boot",
        ]
    # --- output ----------------------------------------------------------
    _xorriso_args += ["-output", mkiso.temp_path, mkiso.mntp_dmrg]
    # ---------------------------------------------------------------------
    try:
        message_start(_caller, omit=True)
        message_info(_caller, f"target: {str(mkiso.mntp_dmrg)}", omit=True)
        message_info(_caller, f"tmpout: {str(mkiso.temp_path)}", omit=True)
        _status = await async_subprocess(*_xorriso_args, **kwargs)
        if _status and mkiso.temp_path.exists():
            loop = asyncio.get_running_loop()
            await loop.run_in_executor(
                None, shutil.copy2, mkiso.temp_path, mkiso.dest_path
            )
        message_end(_caller, omit=True)
    except Exception as e:
        handle_fatal_error(_caller, e, raise_exit=False)
        _status = False
    return _status


async def process_xorrisofs(
    semaphore: asyncio.Semaphore, info_comm: InfoCommon, mdia_data: MediaData
) -> bool:
    _caller = get_caller_name()
    _status = False
    async with semaphore:
        _mkiso = init_mkiso(info_comm=info_comm, mdia_data=mdia_data)
        # --- make directory --------------------------------------------------
        assert _mkiso.temp_obje is not None
        assert _mkiso.temp_dire is not None
        try:
            assert _mkiso.mntp_dovl is not None
            assert _mkiso.mntp_dupr is not None
            assert _mkiso.mntp_dlow is not None
            assert _mkiso.mntp_dwkd is not None
            assert _mkiso.mntp_dmrg is not None
            _mkiso.temp_dire.mkdir(parents=True, exist_ok=True)
            _mkiso.mntp_dovl.mkdir(parents=True, exist_ok=True)
            _mkiso.mntp_dupr.mkdir(parents=True, exist_ok=True)
            _mkiso.mntp_dlow.mkdir(parents=True, exist_ok=True)
            _mkiso.mntp_dwkd.mkdir(parents=True, exist_ok=True)
            _mkiso.mntp_dmrg.mkdir(parents=True, exist_ok=True)
            # --- setfacl -----------------------------------------------------
            if True:
                _command: list[str] = [
                *sudo_args,
                    "setfacl",
                    "-R",
                    "-m",
                    f"u:{infosystem.exec_user}:rwX",
                    str(_mkiso.temp_dire),
                ]
                print(_command)
                _status: bool = await async_subprocess(*_command, **kwargs)
                _command: list[str] = [
                    *sudo_args,
                    "setfacl",
                    "-R",
                "-d",
                    "-m",
                    f"u:{infosystem.exec_user}:rwX",
                    str(_mkiso.temp_dire),
                ]
                print(_command)
                _status: bool = await async_subprocess(*_command, **kwargs)
            # --- mount -------------------------------------------------------
            _mounted = await async_mount(mkiso=_mkiso)
            # --- iso image ---------------------------------------------------
            _mkiso.mbrf_path = _mkiso.temp_dire / "mbr.img"
            _mkiso.uefi_path = _mkiso.temp_dire / "efi.img"
            _mkiso.isos_ptyp = get_partition_type(_mkiso.srce_path)
            _mkiso.dest_labl = get_volume_label(_mkiso.srce_path)
            match _mkiso.isos_ptyp:
                case "dos":
                    _mkiso.hbrd_path = _mkiso.mbrf_path
                case "gpt":
                    pass
                case _:
                    pass
            _tget_dirs = [
                _mkiso.mntp_dmrg / "images",
                _mkiso.mntp_dmrg / "isolinux",
                _mkiso.mntp_dmrg / "efi/boot",
                _mkiso.mntp_dmrg / "efi",
                _mkiso.mntp_dmrg / "EFI/Linux",
                _mkiso.mntp_dmrg / "EFI/debian",
                _mkiso.mntp_dmrg / "EFI/BOOT/grub",
                _mkiso.mntp_dmrg / "EFI/BOOT",
                _mkiso.mntp_dmrg / "EFI",
                _mkiso.mntp_dmrg / "boot/x86_64/loader",
                _mkiso.mntp_dmrg / "boot/grub/i386-efi",
                _mkiso.mntp_dmrg / "boot/grub/x86_64-efi",
                _mkiso.mntp_dmrg / "boot/grub",
                _mkiso.mntp_dmrg / "boot/grub2",
                _mkiso.mntp_dmrg / "boot",
                _mkiso.mntp_dmrg,
            ]
            combined_search = itertools.chain(*(d.glob("*") for d in _tget_dirs))
            for _path in combined_search:
                if not _path.is_file():
                    continue
                _find = True
                match _path.name:
                    case "grub.cfg":
                        _mkiso.grub_path = _path
                    case "isolinux.cfg":
                        _mkiso.ilnx_path = _path
                    case "efi.img" | "efiboot.img" | "efi":
                        _mkiso.uefi_path = _path
                    case "boot.cat" | "boot.catalog":
                        _mkiso.bcat_path = _path
                    case "eltorito.img" | "isolinux.bin":
                        _mkiso.etri_path = _path
                    case _:
                        pass
            # --- get mbr image file ------------------------------------------
            if not _mkiso.mbrf_path.exists():
                extract_mbr_partition(
                    src_path=_mkiso.srce_path, dest_path=_mkiso.mbrf_path
                )
            # --- get uefi image file -----------------------------------------
            if not _mkiso.uefi_path.exists():
                extract_efi_partition(
                    src_path=_mkiso.srce_path, dest_path=_mkiso.uefi_path
                )
            # --- boot menu ---------------------------------------------------
            _statsu = await async_boot_menu(info_comm=info_comm, mkiso=_mkiso)
            # --- xorrisofs ---------------------------------------------------
            _status = await async_xorrisofs(mkiso=_mkiso)
        finally:
            # --- umount ------------------------------------------------------
            _mounted = await async_umount(mkiso=_mkiso)
            if _mkiso.temp_dire.exists():
                message_info(_caller, "temporary cleanup", omit=True)
                _rm_args: list[str] = [
                    *sudo_args,
                    *nice_args,
                    "rm",
                    "-rf",
                    str(_mkiso.temp_dire),
                ]
                _status = await async_subprocess(*_rm_args, **kwargs)
                _mkiso.temp_obje.cleanup()
    return _status
