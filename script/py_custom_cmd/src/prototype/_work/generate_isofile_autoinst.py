# --- python library ----------------------------------------------------------
import asyncio
import itertools
import re
import shutil
import tempfile
from asyncio.subprocess import Process
from pathlib import Path
from typing import Any, Mapping

import aiohttp

# --- my library --------------------------------------------------------------
from common.shared import (
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
    message_end,
    message_info,
    message_start,
)

# --- import module -----------------------------------------------------------
from .generate_boot_option import GenerateBootOption


# --- class and function ------------------------------------------------------
class GenerateIsoFile:
    _srcs_path: Path  # source file path
    _dest_path: Path  # destination file path
    _temp_objs: tempfile.TemporaryDirectory
    _temp_dirs: Path  # temporary directory path
    _temp_path: Path  # temporary file path
    _temp_file: str  # temporary file name
    _mntp_dovl: Path  # overlay directory path
    _mntp_dupr: Path  # upperdir directory path
    _mntp_dlow: Path  # lowerdir directory path
    _mntp_dwkd: Path  # workdir directory path
    _mntp_dmrg: Path  # merged directory path
    _tget_path: Path  # target directory path
    _imgs_path: Path  # image directory path
    _srcs_file: str  # source file name
    _dest_file: str  # destination file name
    _tget_file: str  # target directory name
    _dest_labl: str  # destination file volume label
    _isos_ptyp: str  # iso file partition type
    _hbrd_path: Path  # hybrid mbr file path
    _mbrf_path: Path  # mbr file path
    _uefi_path: Path  # efi file path
    _bcat_path: Path  # boot catalog file path
    _etri_path: Path  # eltorito boot file path
    _grub_path: Path  # grub.cfg fiel path
    _ilnx_path: Path  # ilinux.cfg file path
    # -------------------------------------------------------------------------
    _sudo_args: list[str] = ["sudo", "-n"]
    _nice_args: list[str] = ["nice", "-n", "19"]
    _kwargs: Mapping[str, Any] = {
        "stdout": asyncio.subprocess.PIPE,
        "stderr": asyncio.subprocess.PIPE,
    }

    # --- init ----------------------------------------------------------------
    def __init__(self, win) -> None:
        self.win: Any = win
        self.is_running = False
        self.is_cancelled = False
        self.semaphore = asyncio.Semaphore(5)
        self.session = aiohttp.ClientSession()
        self.boot_option: GenerateBootOption = GenerateBootOption()

    # --- mount ---------------------------------------------------------------
    @debug_logger
    async def mount(self) -> bool:
        _status: bool = False
        _status: bool = await self._mount_bind()
        if _status:
            _status: bool = await self._mount_overlay()
        self.mounted = _status
        return _status

    # --- mount: bind ---------------------------------------------------------
    @debug_logger
    async def _mount_bind(self) -> bool:
        _status: bool = False
        _command: list[str] = [
            *self._sudo_args,
            "mount",
            "-r",
            "--bind",
            str(self._imgs_path),
            str(self._mntp_dlow),
        ]
        _status: bool = await async_subprocess(*_command, **self._kwargs)
        return _status

    # --- mount: overlay ------------------------------------------------------
    @debug_logger
    async def _mount_overlay(self) -> bool:
        _status: bool = False
        _command: list[str] = [
            *self._sudo_args,
            "mount",
            "-t",
            "overlay",
            "overlay",
            "-o",
            f"lowerdir={str(self._mntp_dlow)},"
            f"upperdir={str(self._mntp_dupr)},"
            f"workdir={str(self._mntp_dwkd)}",
            str(self._mntp_dmrg),
        ]
        _status: bool = await async_subprocess(*_command, **self._kwargs)
        return _status

    # --- boot menu -----------------------------------------------------------
    @debug_logger
    async def boot_menu(self) -> bool:
        _caller = get_caller_name()
        _status: bool = False
        self._boot_options: list[dict[str, str]] = (
            self.boot_option.generate_boot_option(mdia_data=self.mdia_data)
        )
        _status_grub = False
        if self._grub_path:
            _status_grub = await self.boot_menu_grub()
        _status_ilnx = False
        if self._ilnx_path:
            _status_ilnx = await self.boot_menu_isolinux()
        _status = _status_grub and _status_ilnx
        return _status

    # --- boot menu: grub -----------------------------------------------------
    @debug_logger
    async def boot_menu_grub(self) -> bool:
        _caller = get_caller_name()
        _status: bool = False
        _auto_path: Path = self._grub_path.parent / self.win.info_comm.conf.get_path(
            key="AUTO_INST"
        )
        _thme_path: Path = self._grub_path.parent / self.win.info_comm.conf.get_path(
            key="AUTO_THME"
        )
        _gaut_path: Path = self.win.info_comm.conf.get_path(key="PATH_GAUT")
        _gthm_path: Path = self.win.info_comm.conf.get_path(key="PATH_GTHM")
        # ---------------------------------------------------------------------
        _status_auto: bool = False
        _read_data = file_read(_gaut_path)
        _var_pattern: re.Pattern[str] = re.compile(r":_([A-Z0-9_]+)_:")
        _conv_dist: str = _var_pattern.sub(
            lambda m: str(self.win.info_comm.conf.find(key=m.group(1)).value),
            _read_data,
        )
        file_write(_auto_path, _conv_dist)
        _status_auto: bool = True
        # ---------------------------------------------------------------------
        _status_thme: bool = False
        _read_data = file_read(_gthm_path)
        _var_pattern: re.Pattern[str] = re.compile(r":_([A-Z0-9_]+)_:")
        _conv_dist: str = _var_pattern.sub(
            lambda m: str(self.win.info_comm.conf.find(key=m.group(1)).value),
            _read_data,
        )
        file_write(_thme_path, _conv_dist)
        _status_thme: bool = True
        # ---------------------------------------------------------------------
        _status = _status_auto and _status_thme
        return _status

    # --- boot menu: isolinux -------------------------------------------------
    @debug_logger
    async def boot_menu_isolinux(self) -> bool:
        _caller = get_caller_name()
        _status: bool = False
        _auto_path: Path = self._ilnx_path.parent / self.win.info_comm.conf.get_path(
            key="AUTO_INST"
        )
        _thme_path: Path = self._ilnx_path.parent / self.win.info_comm.conf.get_path(
            key="AUTO_THME"
        )
        _iaut_path: Path = self.win.info_comm.conf.get_path(key="PATH_IAUT")
        _ithm_path: Path = self.win.info_comm.conf.get_path(key="PATH_ITHM")
        # ---------------------------------------------------------------------
        _status_auto: bool = False
        _read_data = file_read(_iaut_path)
        _var_pattern: re.Pattern[str] = re.compile(r":_([A-Z0-9_]+)_:")
        _conv_dist: str = _var_pattern.sub(
            lambda m: str(self.win.info_comm.conf.find(key=m.group(1)).value),
            _read_data,
        )
        file_write(_auto_path, _conv_dist)
        _status_auto: bool = True
        # ---------------------------------------------------------------------
        _status_thme: bool = False
        _read_data = file_read(_ithm_path)
        _var_pattern: re.Pattern[str] = re.compile(r":_([A-Z0-9_]+)_:")
        _conv_dist: str = _var_pattern.sub(
            lambda m: str(self.win.info_comm.conf.find(key=m.group(1)).value),
            _read_data,
        )
        file_write(_thme_path, _conv_dist)
        _status_thme: bool = True
        # ---------------------------------------------------------------------
        _status = _status_auto and _status_thme
        return _status

    # --- xorriso -------------------------------------------------------------
    @debug_logger
    async def xorriso(self) -> bool:
        _caller = get_caller_name()
        _status: bool = False
        _xorriso_args: list[str] = [*self._sudo_args, *self._nice_args]
        _xorriso_args += [
            "xorrisofs",
            "-rock",
            "-joliet",
        ]
        # ---------------------------------------------------------------------
        if self._dest_labl:
            _xorriso_args += ["-volid", self._dest_labl]
        # ---------------------------------------------------------------------
        _xorriso_args += ["-iso-level", "3"]
        # ---------------------------------------------------------------------
        if self._hbrd_path:
            message_info(_caller, "isohybrid-mbr", omit=True)
            _xorriso_args += [
                "-isohybrid-mbr",
                str(self._hbrd_path),
                "-isohybrid-gpt-basdat",
                "-isohybrid-apm-hfsplus",
            ]
        else:
            message_info(_caller, "grub2-mbr", omit=True)
            _xorriso_args += [
                "--grub2-mbr",
                str(self._mbrf_path),
                "-partition_offset",
                "16-appended_part_as_gpt",
                "-append_partition",
                "2",
                "C12A7328-F81F-11D2-BA4B-00A0C93EC93B",
                str(self._uefi_path.relative_to(self._tget_path)),
                "-iso_mbr_part_type",
                "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7",
            ]
        # ---------------------------------------------------------------------
        if self._bcat_path:
            _xorriso_args += [
                "-eltorito-catalog",
                str(self._bcat_path.relative_to(self._tget_path)),
            ]
        # ---------------------------------------------------------------------
        _xorriso_args += ["--boot-catalog-hide"]
        # ---------------------------------------------------------------------
        if self._etri_path:
            _xorriso_args += [
                "-eltorito-boot",
                str(self._etri_path.relative_to(self._tget_path)),
                "-no-emul-boot",
            ]
        # ---------------------------------------------------------------------
        _xorriso_args += [
            "-boot-load-size",
            "4",
            "-boot-info-table",
            "-eltorito-alt-boot",
        ]
        # ---------------------------------------------------------------------
        if self._hbrd_path:
            _xorriso_args += [
                "-e",
                str(self._uefi_path.relative_to(self._tget_path)),
                "-no-emul-boot",
            ]
        else:
            _xorriso_args += [
                "-e",
                "--interval:appended_partition_2:all::",
                "-no-emul-boot",
            ]
        # ---------------------------------------------------------------------
        _xorriso_args += ["-output", self._temp_file, self._tget_file]
        # ---------------------------------------------------------------------
        try:
            message_start(_caller, omit=True)
            message_info(_caller, f"target: {self._tget_file}", omit=True)
            message_info(_caller, f"tmpout: {self._temp_file}", omit=True)
            _xorriso_proc: Process = await asyncio.create_subprocess_exec(
                *_xorriso_args, **self._kwargs
            )
            _stdout, _stderr = await _xorriso_proc.communicate()
            _status = _xorriso_proc.returncode == 0
            message_info(_caller, f"output: {self._dest_path}", omit=True)
            if not _status:
                if _stdout:
                    message_info(_caller, f"stdout: {_stdout.decode()}")
                if _stderr:
                    message_info(_caller, f"stderr: {_stderr.decode()}")
            if _status and self._temp_path.exists():
                loop = asyncio.get_running_loop()
                await loop.run_in_executor(
                    None, shutil.copy2, self._temp_path, self._dest_path
                )
            message_end(_caller, omit=True)
        except Exception as e:
            handle_fatal_error(_caller, e, raise_exit=False)
            _status = False
        return _status

    # --- umount --------------------------------------------------------------
    @debug_logger
    async def umount(self) -> bool:
        _status: bool = False
        if self.mounted:
            _status: bool = await self._umount_overlay()
            if _status:
                _status: bool = await self._umount_bind()
            self.mounted = not _status
        return _status

    # --- umount: overlay -----------------------------------------------------
    @debug_logger
    async def _umount_overlay(self) -> bool:
        _status: bool = False
        _command: list[str] = [*self._sudo_args, "umount", str(self._mntp_dmrg)]
        _status: bool = async_subprocess(*_command, **self._kwargs)
        if not _status:
            _command: list[str] = [
                *self._sudo_args,
                "umount",
                "-f",
                str(self._mntp_dmrg),
            ]
            _status: bool = async_subprocess(*_command, **self._kwargs)
            if not _status:
                _command: list[str] = [
                    *self._sudo_args,
                    "umount",
                    "-l",
                    str(self._mntp_dmrg),
                ]
                _status: bool = async_subprocess(*_command, **self._kwargs)
        return _status

    # --- umount: bind --------------------------------------------------------
    @debug_logger
    async def _umount_bind(self) -> bool:
        _status: bool = False
        _command: list[str] = [*self._sudo_args, "umount", str(self._mntp_dlow)]
        _status: bool = async_subprocess(*_command, **self._kwargs)
        if not _status:
            _command: list[str] = [
                *self._sudo_args,
                "umount",
                "-f",
                str(self._mntp_dlow),
            ]
            _status: bool = async_subprocess(*_command, **self._kwargs)
            if not _status:
                _command: list[str] = [
                    *self._sudo_args,
                    "umount",
                    "-l",
                    str(self._mntp_dlow),
                ]
                _status: bool = async_subprocess(*_command, **self._kwargs)
        return _status

    # --- xorriso single task -------------------------------------------------
    @debug_logger
    async def generate_xorrisos_single(self, mdia_data: MediaData) -> bool:
        _caller = get_caller_name()
        _status: bool = False
        # ---------------------------------------------------------------------
        self.mdia_data: MediaData = mdia_data
        # ---------------------------------------------------------------------
        self._srcs_path: Path = Path(mdia_data.iso_path)
        self._dest_path: Path = Path(mdia_data.rmk_path)
        self._temp_objs: tempfile.TemporaryDirectory = tempfile.TemporaryDirectory()
        self._temp_dirs: Path = Path(self._temp_objs.name)
        self._temp_path: Path = self._temp_dirs / self._dest_path.name
        self._temp_file: str = str(self._temp_path)
        self._mntp_dovl: Path = self._temp_path / "overlay"
        self._mntp_dupr: Path = self._mntp_dovl / "upper"
        self._mntp_dlow: Path = self._mntp_dovl / "lower"
        self._mntp_dwkd: Path = self._mntp_dovl / "work"
        self._mntp_dmrg: Path = self._mntp_dovl / "merged"
        self._tget_path: Path = self._mntp_dmrg
        self._imgs_path: Path = (
            self.win.info_comm.conf.get_path("DIRS_IMGS") / mdia_data.entry_name
        )
        self._srcs_file: str = str(self._srcs_path)
        self._dest_file: str = str(self._dest_path)
        self._tget_file: str = str(self._tget_path)
        self._dest_labl: str = get_volume_label(self._srcs_file)
        self._isos_ptyp: str = get_partition_type(self._srcs_file)
        self._hbrd_path: Path = Path()  # hybrid mbr file path
        self._mbrf_path: Path = Path()  # mbr file path
        self._uefi_path: Path = Path()  # efi file path
        self._bcat_path: Path = Path()  # boot catalog file path
        self._etri_path: Path = Path()  # eltorito boot file path
        self._grub_path: Path = Path()  # grub.cfg fiel path
        self._ilnx_path: Path = Path()  # ilinux.cfg file path
        # ---------------------------------------------------------------------
        self._mbrf_path = self._temp_dirs / "mbr.img"
        self._uefi_path = self._temp_dirs / "efi.img"
        match self._isos_ptyp:
            case "dos":
                self._hbrd_path = self._mbrf_path
            case "gpt":
                pass
            case _:
                pass
        _tget_dirs = [
            self._tget_path / "images",
            self._tget_path / "isolinux",
            self._tget_path / "efi/boot",
            self._tget_path / "efi",
            self._tget_path / "EFI/Linux",
            self._tget_path / "EFI/debian",
            self._tget_path / "EFI/BOOT/grub",
            self._tget_path / "EFI/BOOT",
            self._tget_path / "EFI",
            self._tget_path / "boot/x86_64/loader",
            self._tget_path / "boot/grub/i386-efi",
            self._tget_path / "boot/grub/x86_64-efi",
            self._tget_path / "boot/grub",
            self._tget_path / "boot/grub2",
            self._tget_path / "boot",
            self._tget_path,
        ]
        combined_search = itertools.chain(*(d.glob("*") for d in _tget_dirs))
        for _path in combined_search:
            if not _path.is_file():
                continue
            _find = True
            match _path.name:
                case "grub.cfg":
                    self._grub_path = _path
                case "isolinux.cfg":
                    self._ilnx_path = _path
                case "efi.img" | "efiboot.img" | "efi":
                    self._uefi_path = _path
                case "boot.cat" | "boot.catalog":
                    self._bcat_path = _path
                case "eltorito.img" | "isolinux.bin":
                    self._etri_path = _path
                case _:
                    pass
        # ---------------------------------------------------------------------
        self._temp_dirs.mkdir(parents=True, exist_ok=True)
        self._mntp_dovl.mkdir(parents=True, exist_ok=True)
        self._mntp_dupr.mkdir(parents=True, exist_ok=True)
        self._mntp_dlow.mkdir(parents=True, exist_ok=True)
        self._mntp_dwkd.mkdir(parents=True, exist_ok=True)
        self._mntp_dmrg.mkdir(parents=True, exist_ok=True)
        # --- get mbr image file ----------------------------------------------
        if not self._mbrf_path.exists():
            extract_mbr_partition(src_path=self._srcs_path, dest_path=self._mbrf_path)
        # --- get uefi image file ---------------------------------------------
        if not self._uefi_path.exists():
            extract_efi_partition(src_path=self._srcs_path, dest_path=self._uefi_path)
        # ---------------------------------------------------------------------
        semaphore = asyncio.Semaphore(3)
        async with semaphore:
            _status: bool = await self.mount()
            if not _status:
                return _status
            await self.boot_menu()
            await self.xorriso()
            await self.umount()
        self._temp_objs.cleanup()
        del self.mdia_data
        return _status

    # --- xorriso multi task --------------------------------------------------
    @debug_logger
    async def put_xorrisos(self, mdia_datas: list[MediaData]) -> bool:
        _caller = get_caller_name()
        _status: bool = False
        return _status
