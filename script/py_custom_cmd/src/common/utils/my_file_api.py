"""File I/O processing (For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import os
import re
import shutil
import struct
from datetime import datetime
from pathlib import Path
from typing import Iterator

# --- my library --------------------------------------------------------------
# ruff: isort: of
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    infosystem,
    message_alert,
)


# ruff: isort: on
# =============================================================================
@debug_logger
def file_read(src_path: Path, text: bool = True) -> str | bytes | None:
    """File read (line break codes in text files are standardized to "\n")
    Args:
        src_path (Path): Source path
        text (bool, optional): Read mode. Defaults to True.
    Raises:
        SystemExit: OSError
        SystemExit: Exception
    Returns:
        str| bytes: Result
    """
    _caller = get_caller_name()
    try:
        _src_path: Path = src_path.resolve()
        _mode: str = "r" if text else "rb"
        _encoding: None | str = "utf-8" if text else None
        with open(_src_path, mode=_mode, encoding=_encoding, newline=None) as f_inp:
            return f_inp.read()
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return None


@debug_logger
def file_write(
    dest_path: Path,
    data: str | bytes | None = None,
    text: bool = True,
    backup: bool = False,
) -> None:
    """File write (line break codes in text files are standardized to "\n")
    Args:
        dest_path (Path): Destination path
        data (str | bytes | None, optional): Output data. Defaults to None.
        text (bool, optional): Write mode. Defaults to True.
        backup (bool, optional): Backup mode. Defaults to False.
    Raises:
        SystemExit: OSError
        SystemExit: Exception
    """
    _caller = get_caller_name()
    try:
        _dest_path: Path = dest_path.resolve()
        _mode: str = "w" if text else "wb"
        _encoding: None | str = "utf-8" if text else None
        _newline: None | str = "\n" if text else None
        if data is None:
            data = "" if text else b""
        _dest_path.parent.mkdir(parents=True, exist_ok=True)
        if backup:
            file_backup(_dest_path)
        with open(
            _dest_path, mode=_mode, encoding=_encoding, newline=_newline
        ) as f_out:
            f_out.write(data)
            f_out.flush()
            os.fsync(f_out.fileno())
        if not _dest_path.exists():
            if infosystem.is_gui and infosystem.gui_error_callback:
                infosystem.gui_error_callback(
                    "File Error", f"Failed to write file:\n{_dest_path}"
                )
            else:
                message_alert(_caller, f"failed: {_dest_path}")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def file_copy(src_path: Path, dest_path: Path, backup: bool = False) -> None:
    """File copy
    Args:
        src_path (Path): Source path
        dest_path (Path): Destination path
        backup (bool, optional): Backup. Defaults to False.
    """
    _caller = get_caller_name()
    try:
        _src_path: Path = src_path.resolve()
        _dest_path: Path = dest_path.resolve()
        _dest_path.parent.mkdir(parents=True, exist_ok=True)
        if bool:
            file_backup(_dest_path)
            shutil.copy2(_src_path, _dest_path)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def file_backup(src_path: Path) -> None:
    """File backup
    Args:
        src_path (Path): Source path
    """
    _caller = get_caller_name()
    try:
        _src_path: Path = src_path.resolve()
        if _src_path.exists() and _src_path.is_file():
            # --- backup ------------------------------------------------------
            _timestamp: str = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
            _base_name: str = _src_path.stem
            _ext: str = _src_path.suffix
            _backup_path: Path = _src_path.with_name(f"{_base_name}_{_timestamp}{_ext}")
            shutil.copy2(_src_path, _backup_path)
            # --- history & cleanup -------------------------------------------
            _all_files: Iterator[Path] = _src_path.parent.glob(f"{_base_name}_*{_ext}")
            _pattern: re.Pattern[str] = re.compile(
                rf"^{re.escape(_base_name)}_\d{{14}}_\d{{6}}{re.escape(_ext)}$"
            )
            backups = []
            for f in _all_files:
                if _pattern.match(f.name):
                    backups.append(str(f))
            backups.sort(key=os.path.getmtime)
            # --- cleanup -----------------------------------------------------
            while len(backups) > 3:
                oldest_backup = backups.pop(0)
                os.remove(oldest_backup)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


@debug_logger
def dd(
    src_path: Path,
    dest_path: Path,
    bs: int = 512,
    count: int | None = None,
    skip: int = 0,
    seek: int = 0,
) -> int:
    _caller = get_caller_name()
    copied_blocks = 0
    try:
        with open(src_path, "rb") as f_in, open(dest_path, "r+b") as f_out:
            f_in.seek(skip * bs)
            f_out.seek(seek * bs)
            while True:
                if count is not None and copied_blocks >= count:
                    break
                data: bytes = f_in.read(bs)
                if not data:
                    break
                f_out.write(data)
                copied_blocks += 1
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    finally:
        pass
    return copied_blocks * bs


@debug_logger
def extract_mbr_partition(src_path: Path, dest_path: Path) -> int:
    _result = 0
    with open(src_path, "rb") as f_inp, open(dest_path, "wb") as f_out:
        pt_data: bytes = f_inp.read(446)
        _result: int = f_out.write(pt_data)
    return _result


@debug_logger
def extract_efi_partition(src_path: Path, dest_path: Path) -> int:
    SECTOR_SIZE = 512
    EFI_UUID = b"\x28\x73\x2a\xc1\x1f\xf8\xd2\x11\xba\x4b\x00\xa0\xc9\x3e\xc9\x3b"
    _result = 0
    with open(src_path, "rb") as f_inp, open(dest_path, "wb") as f_out:
        f_inp.seek(446)
        pt_data: bytes = f_inp.read(64)
        # ---------------------------------------------------------------------
        is_gpt = False
        efi_start_lba = None
        efi_sectors = None
        # ---------------------------------------------------------------------
        for i in range(4):
            part: bytes = pt_data[i * 16 : (i + 1) * 16]
            sys_id: int = part[4]
            # -----------------------------------------------------------------
            if sys_id == 0xEE:  # GPT-protective MBR.
                is_gpt = True
            elif sys_id == 0xEF:  # EFI layout in MBR format.
                efi_start_lba: int = struct.unpack("<I", part[8:12])[0]
                efi_sectors: int = struct.unpack("<I", part[12:16])[0]
        # ---------------------------------------------------------------------
        if is_gpt:
            f_inp.seek(SECTOR_SIZE + 72)
            partition_entries_lba: int = struct.unpack("<Q", f_inp.read(8))[0]
            num_parts: int = struct.unpack("<I", f_inp.read(4))[0]
            entry_size: int = struct.unpack("<I", f_inp.read(4))[0]
            # -----------------------------------------------------------------
            f_inp.seek(partition_entries_lba * SECTOR_SIZE)
            # -----------------------------------------------------------------
            for _ in range(num_parts):
                entry: bytes = f_inp.read(entry_size)
                if len(entry) < 32:
                    break
                # -------------------------------------------------------------
                type_uuid: bytes = entry[0:16]
                if type_uuid == EFI_UUID:
                    start_lba: int = struct.unpack("<Q", entry[32:40])[0]
                    end_lba: int = struct.unpack("<Q", entry[40:48])[0]
                    # ---------------------------------------------------------
                    efi_start_lba: int = start_lba
                    efi_sectors: int = (end_lba - start_lba) + 1
                    break
        # ---------------------------------------------------------------------
        if efi_start_lba is not None and efi_sectors is not None:
            start_bytes: int = efi_start_lba * SECTOR_SIZE
            total_bytes: int = efi_sectors * SECTOR_SIZE
            # -----------------------------------------------------------------
            f_inp.seek(start_bytes)
            # -----------------------------------------------------------------
            buffer_size = 4 * 1024 * 1024
            bytes_left: int = total_bytes
            while bytes_left > 0:
                chunk_size: int = min(buffer_size, bytes_left)
                data: bytes = f_inp.read(chunk_size)
                if not data:
                    break
                _result: int = f_out.write(data)
                bytes_left -= len(data)
    return _result


# --- eof ---------------------------------------------------------------------
