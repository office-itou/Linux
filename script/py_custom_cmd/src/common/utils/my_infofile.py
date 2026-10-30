"""Retrieves file information from the local system.(For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import mimetypes  # ⭕ magic の代わりに標準の mimetypes をインポート
import re
import shutil
from dataclasses import dataclass, fields
from datetime import datetime, timezone
from pathlib import Path
from typing import Callable

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    run_subprocess_stdout,
)


# -----------------------------------------------------------------------------
@dataclass
class FileData:
    """File data class"""

    path: str = ""
    tmstamp: str = ""
    size: int = 0
    volume: str = ""
    uuid: str = ""


class InfoFile:
    """File information class"""

    def __init__(self) -> None:
        self._valid_fields: set[str] = {f.name for f in fields(FileData)}
        self.data = FileData()  # 初期値を明示
        self.uuid: str = ""
        self.volume: str = ""

    def get_data(self) -> FileData:
        return self.data

    def get_info(self, target_path: str) -> FileData:
        self.data: FileData = get_infofile(target_path)
        return self.data

    def get_volume_uuid(self, device: str) -> str:
        self.uuid: str | None = get_volume_uuid(device)
        return self.uuid

    def get_volume_label(self, device: str) -> str:
        self.volume: str | None = get_volume_label(device)
        return self.volume

    def get_partition_type(self, device: str) -> str:
        self.pttype: Callable[..., str] = get_partition_type
        return self.pttype


@debug_logger
def get_volume_uuid(device: str) -> str | None:
    """Get volume uuid"""
    _caller = get_caller_name()

    @debug_logger
    def _file_access(device: str) -> str | None:
        with open(device, "rb") as f:
            f.seek(0x8000 + 813)
            dt_bytes: bytes = f.read(16)
            dt_str: str = dt_bytes.decode("ascii", errors="ignore")
            if dt_str.isdigit() and len(dt_str) == 16:
                return (
                    f"{dt_str[0:4]}-{dt_str[4:6]}-{dt_str[6:8]}"
                    f"-{dt_str[8:10]}-{dt_str[10:12]}-{dt_str[12:14]}"
                    f"-{dt_str[14:16]}"
                )
        return None

    try:
        if shutil.which("blkid"):
            parameter: list[str] = ["blkid", "-s", "UUID", "-o", "value", device]
            return run_subprocess_stdout(parameter)
        if shutil.which("file"):
            parameter: list[str] = ["file", "-b", device]
            result = run_subprocess_stdout(parameter)
            match: re.Match[str] | None = re.search(
                r"UUID[=\s]'?([A-Za-z0-9:-]+)'?", result
            )
            if match:
                return match.group(1).strip()
        if shutil.which("isoinfo"):
            parameter: list[str] = ["isoinfo", "-d", "-i", device]
            result = run_subprocess_stdout(parameter)
            for line in result.splitlines():
                if "Volume creation time:" in line:
                    dt_part = line.split(":", 1)[1].strip()
                    uuid_like: str = re.sub(r"\s+", "-", dt_part)
                    if uuid_like:
                        return uuid_like
        return _file_access(device)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return None


@debug_logger
def get_volume_label(device: str) -> str | None:
    """Get volume label"""
    _caller = get_caller_name()
    try:
        if shutil.which("blkid"):
            parameter: list[str] = ["blkid", "-s", "LABEL", "-o", "value", device]
            return run_subprocess_stdout(parameter)
        if shutil.which("file"):
            parameter: list[str] = ["file", "-b", device]
            result = run_subprocess_stdout(parameter)
            match: re.Match[str] | None = re.search(r"'(.*?)'", result)
            if match:
                return match.group(1).strip()
        if shutil.which("isoinfo"):
            parameter: list[str] = ["isoinfo", "-d", "-i", device]
            result = run_subprocess_stdout(parameter)
            for line in result.stdout.splitlines():
                if "Volume id:" in line:
                    return line.split(":", 1)[1].strip()
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return None


@debug_logger
def get_infofile(target_path: str) -> FileData:
    """Get file information data
    Args:
        target_path (str): Target path
    Returns:
        FileData: File information
    """
    _data = FileData()
    _path = Path(target_path)
    _data.path = str(_path.resolve())
    if _path.exists():
        # 1. 🌟 標準の mimetypes を使って拡張子からMIMEタイプを安全に取得
        _kind, _ = mimetypes.guess_type(_data.path)
        # ISOファイル用の代表的なMIMEタイプ候補リスト
        iso_mimes: set[str] = {
            "application/x-iso9660-image",
            "application/octet-stream",
            "application/vnd.efi.iso",
            "application/x-cd-image",
        }
        # 2. 🌟 拡張子が .iso であるか、またはMIMEタイプが候補に含まれるかチェック
        is_iso_file: bool = (_path.suffix.lower() == ".iso") or (_kind in iso_mimes)
        if is_iso_file:
            # 3. 🌟 blkid を用いてボリュームラベルの取得を試みる
            label: str | None = get_volume_label(_data.path)
            if label:
                _data.volume = label
        # タイムスタンプとファイルサイズの設定
        _data.tmstamp = datetime.fromtimestamp(
            _path.stat().st_mtime, tz=timezone.utc
        ).isoformat()
        _data.size = _path.stat().st_size
    return _data


@debug_logger
def get_partition_type(target_path: str) -> str:
    try:
        with open(target_path, "rb") as f:
            # --- check the primary volume descriptor signature ---------------
            f.seek(32769)
            iso_sig: bytes = f.read(5)
            is_iso9660: bool = iso_sig == b"CD001"
            # --- check the mbr -----------------------------------------------
            f.seek(510)
            mbr_sig: bytes = f.read(2)
            has_mbr: bool = mbr_sig == b"\x55\xaa"
            if not has_mbr:
                return "unknown"
            # --- analysis of the partition table within the mbr  -------------
            f.seek(446)
            pt_data: bytes = f.read(64)

            has_valid_partition = False
            is_gpt_protective = False
            for i in range(4):
                part: bytes = pt_data[i * 16 : (i + 1) * 16]
                sys_id: int = part[4]
                if sys_id != 0x00:
                    has_valid_partition = True
                if sys_id == 0xEE:
                    # 0xEE は GPT保護MBR (Protective MBR) の識別子
                    is_gpt_protective = True
            # --- decision logic ----------------------------------------------
            if is_gpt_protective:
                return "gpt"
            elif is_iso9660 or has_valid_partition:
                return "dos"
    except Exception:
        return "unknown"
    return "unknown"


# --- eof ---------------------------------------------------------------------
