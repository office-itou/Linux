# --- Python library ----------------------------------------------------------
import asyncio
from dataclasses import dataclass, fields
from pathlib import Path
from typing import Any, Callable

import aiohttp  # sudo apt-get install python3-aiohttp
from aiohttp import ClientTimeout


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import (
    MediaData,
)
from common.utils import (
    debug_logger,
    get_caller_name,
    ljust,
    message_info,
)


# --- maximum number of simultaneous semaphore accesses -----------------------
MAX_CONCURRENT_REQUESTS = 5
# --- list of default name mappings for each distribution ---------------------
BASE_DIR_MAP = {
    "debian": "BASE_DEBI",
    "ubuntu": "BASE_UBUN",
    "fedora": "BASE_FEDO",
    "centos": "BASE_CENT",
    "almalinux": "BASE_ALMA",
    "rockylinux": "BASE_ROCK",
    "miraclelinux": "BASE_MIRA",
    "opensuse": "BASE_SUSE",
    "memtest86plus": "BASE_TEST",
    "windows-10": "BASE_WI10",
    "windows-11": "BASE_WI11",
    "winpe": "BASE_WINP",
    "ati": "BASE_ATIW",
    "aomei": "BASE_AOME",
}


@dataclass
class WebFileData:
    mdia_data: MediaData | None = None
    is_target: bool = False
    local_file: Path | None = None


class InfoWebFile:
    current_messages: dict[str, str]

    def __init__(self, window_instance: Any) -> None:
        self.win = window_instance
        self.on_progress_callback: Callable[[str], None] | None = None
        self._valid_fields = {f.name for f in fields(WebFileData)}
        self.data: list[WebFileData] = [
            WebFileData(
                mdia_data=_mdia_data,
                is_target=False,
                local_file=self._local_file(
                    tget_mdia=_mdia_data, local_file_path=_mdia_data.iso_path
                ),
            )
            for _mdia_data in self.win.info_comm.mdia.data
        ]

    def __getattr__(self, name: str) -> Any:
        if name.startswith("__"):
            return super().__getattribute__(name)
        if name in self._valid_fields:
            return getattr(self.data[0], name) if self.data else ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    def _local_file(self, tget_mdia: MediaData, local_file_path: Path) -> Path:
        if local_file_path:
            _local_file_path = Path(local_file_path)
        else:
            _local_file_path = Path()
            for _name, _key in BASE_DIR_MAP.items():
                if _name in tget_mdia.entry_name:
                    _local_file_path = (
                        self.win.info_comm.conf.get_path(_key)
                        / f"{tget_mdia.entry_name}.iso"
                    )
                    break
        return _local_file_path

    async def _process_single_media(
        self,
        semaphore: asyncio.Semaphore,
        session: aiohttp.ClientSession,
        tget_webfile: WebFileData,
    ) -> None:
        """Asynchronous task for processing a single piece of media data
        (with rate limiting via semaphore)
        Args:
            semaphore (asyncio.Semaphore): _description_
            session (aiohttp.ClientSession): _description_
            tget_mdia (MediaData): _description_
        """
        async with semaphore:
            from common.utils import InfoFile, InfoWeb

            if not tget_webfile or not tget_webfile.mdia_data:
                return
            # --- asynchronous communication processing ---------------------------
            _caller = get_caller_name()
            _disp_name = getattr(
                tget_webfile.mdia_data, "entry_disp", tget_webfile.mdia_data.entry_name
            )
            if self.on_progress_callback:
                _message = ljust(
                    self.win.current_messages.get(
                        "msg_info_communicating", "➔ Communicating"
                    ),
                    20,
                )
                self.on_progress_callback(f"{_message}: {_disp_name} ...")
            if tget_webfile.mdia_data.web_regexp:
                message_info(
                    _caller,
                    f"[Queue] Fetching: {tget_webfile.mdia_data.web_regexp}",
                    omit=True,
                )
                info_web = InfoWeb()
                _local_path_str = str(tget_webfile.local_file)
                _web_datas = await info_web.get_info(
                    session,
                    tget_webfile.mdia_data.web_regexp,
                    _local_path_str,
                )
                for _web_data in _web_datas:
                    tget_webfile.mdia_data.web_path = str(_web_data.request_url)
                    tget_webfile.mdia_data.web_tstamp = str(_web_data.time_stamp)
                    tget_webfile.mdia_data.web_size = str(_web_data.file_size)
                    tget_webfile.mdia_data.web_check = str(_web_data.check_date)
                    tget_webfile.mdia_data.web_status = str(_web_data.status)
                    tget_webfile.local_file = (
                        Path(_web_data.local_file) if _web_data.local_file else None
                    )
            # --- local file information collection -------------------------------
            file_exists = False
            if tget_webfile.local_file:
                file_exists = await asyncio.to_thread(tget_webfile.local_file.exists)
            if file_exists:
                info_file = InfoFile()
                await asyncio.to_thread(
                    info_file.get_info, str(tget_webfile.local_file)
                )
                tget_webfile.mdia_data.iso_path = str(info_file.data.path)
                tget_webfile.mdia_data.iso_tstamp = str(info_file.data.tmstamp)
                tget_webfile.mdia_data.iso_size = str(info_file.data.size)
                tget_webfile.mdia_data.iso_volume = str(info_file.data.volume)
            else:
                tget_webfile.mdia_data.iso_path = (
                    str(tget_webfile.local_file) if tget_webfile.local_file else ""
                )
                tget_webfile.mdia_data.iso_tstamp = ""
                tget_webfile.mdia_data.iso_size = ""
                tget_webfile.mdia_data.iso_volume = ""
            # --- log notification upon completion of a single task ---------------
            if self.on_progress_callback:
                _message = ljust(
                    self.win.current_messages.get("msg_info_complete", "✓ Completed."),
                    20,
                )
                self.on_progress_callback(f"{_message}: {_disp_name}")

    @debug_logger
    async def get_web_file_info(self) -> None:
        """Get web/file information data (Parallelized & Rate-limited)"""
        timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
        semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)
        async with aiohttp.ClientSession(
            timeout=timeout, raise_for_status=False
        ) as session:
            _tasks = []
            for _tget_webfile in self.data:
                if not _tget_webfile.is_target:
                    continue
                # --- generating a task -------------------------------------------
                _tasks.append(
                    self._process_single_media(
                        semaphore=semaphore,
                        session=session,
                        tget_webfile=_tget_webfile,
                    )
                )
            # ---------------------------------------------------------------------
            if _tasks:
                await asyncio.gather(*_tasks)
