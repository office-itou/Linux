"""Retrieves file information from the local system.(For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import mimetypes  # ⭕ magic の代わりに標準の mimetypes をインポート
from dataclasses import dataclass, fields
from datetime import datetime, timezone
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import debug_logger, run_subprocess


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

    def __init__(self):
        self._valid_fields = {f.name for f in fields(FileData)}
        self.data = FileData()  # 初期値を明示
        self.uuid = ""
        self.volume = ""

    def get_data(self) -> FileData:
        return self.data

    def get_info(self, target_path: str) -> FileData:
        self.data = get_info(target_path)
        return self.data

    def get_volume_uuid(self, device: str) -> str:
        self.uuid = get_volume_uuid(device)
        return self.uuid

    def get_volume_label(self, device: str) -> str:
        self.volume = get_volume_label(device)
        return self.volume


@debug_logger
def get_volume_uuid(device: str) -> str:
    """Get volume uuid"""
    parameter = ["blkid", "-s", "UUID", "-o", "value", device]
    return run_subprocess(parameter)


@debug_logger
def get_volume_label(device: str) -> str:
    """Get volume label"""
    parameter = ["blkid", "-s", "LABEL", "-o", "value", device]
    return run_subprocess(parameter)


@debug_logger
def get_info(target_path: str) -> FileData:
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
        iso_mimes = {
            "application/x-iso9660-image",
            "application/octet-stream",
            "application/vnd.efi.iso",
            "application/x-cd-image",
        }

        # 2. 🌟 拡張子が .iso であるか、またはMIMEタイプが候補に含まれるかチェック
        is_iso_file = (_path.suffix.lower() == ".iso") or (_kind in iso_mimes)

        if is_iso_file:
            # 3. 🌟 blkid を用いてボリュームラベルの取得を試みる
            label = get_volume_label(_data.path)
            if label:
                _data.volume = label

        # タイムスタンプとファイルサイズの設定
        _data.tmstamp = datetime.fromtimestamp(
            _path.stat().st_mtime, tz=timezone.utc
        ).isoformat()
        _data.size = _path.stat().st_size

    return _data


# --- eof ---------------------------------------------------------------------
