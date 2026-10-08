# --- Python library ----------------------------------------------------------
import asyncio
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
    WebData,
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


class InfoWebFile:
    def __init__(self, window_instance: Any) -> None:
        self.win = window_instance
        self.on_progress_callback: Callable[[str], None] | None = None
        self._active_tasks: list[asyncio.Task] = []

    # =========================================================================
    # a block that retrieves file information from the web.
    # =========================================================================
    async def _process_single_media(
        self,
        semaphore: asyncio.Semaphore,
        session: aiohttp.ClientSession,
        mdia_data: MediaData,
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

            if not mdia_data:
                return
            # --- asynchronous communication processing -----------------------
            _caller = get_caller_name()
            _disp_name = getattr(mdia_data, "entry_disp", mdia_data.entry_name)
            _mdia_type = getattr(mdia_data, "mdia_type", mdia_data.mdia_type)
            if self.on_progress_callback:
                _message = ljust(
                    self.win.current_messages.get(
                        "msg_info_communicating", "➔ Communicating"
                    ),
                    20,
                )
                self.on_progress_callback(f"{_message}: {_disp_name} ({_mdia_type})...")
            # -----------------------------------------------------------------
            _local_file_path: Path = Path(mdia_data.iso_path)
            if mdia_data.web_regexp:
                message_info(
                    _caller,
                    f"[Queue] Fetching: {mdia_data.web_regexp}",
                    omit=True,
                )
                info_web = InfoWeb()
                _web_datas: list[WebData] = await info_web.get_info(
                    session,
                    mdia_data.web_regexp,
                    _local_file_path,
                )
                for _web_data in _web_datas:
                    mdia_data.web_path = str(_web_data.request_url)
                    mdia_data.web_tstamp = str(_web_data.time_stamp)
                    mdia_data.web_size = str(_web_data.file_size)
                    mdia_data.web_check = str(_web_data.check_date)
                    mdia_data.web_status = str(_web_data.status)
                    _local_file_path = (
                        Path(_web_data.local_file) if _web_data.local_file else Path()
                    )
                    break
            # --- local file information collection ---------------------------
            _file_exists = False
            if _local_file_path:
                # print(f"_local_file:{_local_file_path}")
                try:
                    _file_exists = await asyncio.to_thread(_local_file_path.exists)
                except (OSError, Exception) as e:
                    if self.on_progress_callback:
                        _message = ljust(
                            self.win.current_messages.get("msg_error", "❌ Error."),
                            20,
                        )
                        self.on_progress_callback(
                            f"{_message}: {_disp_name} ({_local_file_path}): {e}"
                        )
                    _file_exists = False
            if _file_exists:
                info_file = InfoFile()
                _local_file_str = str(_local_file_path)
                try:
                    await asyncio.to_thread(info_file.get_info, _local_file_str)
                except (OSError, Exception) as e:
                    if self.on_progress_callback:
                        _message = ljust(
                            self.win.current_messages.get("msg_error", "❌ Error."),
                            20,
                        )
                        self.on_progress_callback(
                            f"{_message}: {_disp_name} ({_local_file_path}): {e}"
                        )
                    return
                mdia_data.iso_path = str(info_file.data.path)
                mdia_data.iso_tstamp = str(info_file.data.tmstamp)
                mdia_data.iso_size = str(info_file.data.size)
                mdia_data.iso_volume = str(info_file.data.volume)
            else:
                mdia_data.iso_path = str(_local_file_path)
                mdia_data.iso_tstamp = ""
                mdia_data.iso_size = ""
                mdia_data.iso_volume = ""
            # --- log notification upon completion of a single task -----------
            if self.on_progress_callback:
                _message = ljust(
                    self.win.current_messages.get("msg_info_complete", "✓ Completed."),
                    20,
                )
                self.on_progress_callback(f"{_message}: {_disp_name} ({_mdia_type})...")

    # @debug_logger
    async def get_web_file_info(self) -> None:
        """Get web/file information data (Parallelized & Rate-limited)"""
        timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
        semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)
        async with aiohttp.ClientSession(
            timeout=timeout, raise_for_status=False
        ) as session:
            _tasks = []
            for _mdia_data in self.win.info_comm.mdia.data:
                if _mdia_data.target_flag != "o":
                    continue
                # --- generating a task ---------------------------------------
                _tasks.append(
                    self._process_single_media(
                        semaphore=semaphore,
                        session=session,
                        mdia_data=_mdia_data,
                    )
                )
            # -----------------------------------------------------------------
            if _tasks:
                await asyncio.gather(*_tasks)

    # =========================================================================
    # a block that downloads a file.
    # =========================================================================
    async def _download_single_media(
        self,
        semaphore: asyncio.Semaphore,
        session: aiohttp.ClientSession,
        mdia_data: MediaData,
    ) -> None:
        async with semaphore:
            from common.utils import get_contents

            if not mdia_data:
                return
            # --- asynchronous communication processing -----------------------
            _caller = get_caller_name()
            _disp_name = getattr(mdia_data, "entry_disp", mdia_data.entry_name)
            _mdia_type = getattr(mdia_data, "mdia_type", mdia_data.mdia_type)
            if self.on_progress_callback:
                _message = ljust(
                    self.win.current_messages.get(
                        "msg_info_downloading", "➔ Downloading"
                    ),
                    20,
                )
                self.on_progress_callback(f"{_message}: {_disp_name} ({_mdia_type})...")
            # -----------------------------------------------------------------
            _web_data = await get_contents(
                session=session,
                request_url=mdia_data.web_path,
                local_file=mdia_data.iso_path,
                overwrite=True,
                show_progress=False,
            )
            if int(_web_data.status, 0) in (200, 206):
                mdia_data.iso_path = _web_data.local_file
                mdia_data.iso_tstamp = _web_data.time_stamp
                mdia_data.iso_size = _web_data.file_size
                # --- log notification upon completion of a single task -------
                if self.on_progress_callback:
                    _message = ljust(
                        self.win.current_messages.get(
                            "msg_info_complete", "✓ Completed."
                        ),
                        20,
                    )
                    self.on_progress_callback(
                        f"{_message}: {_disp_name} ({_mdia_type})..."
                    )
            else:
                if self.on_progress_callback:
                    _message = ljust(
                        self.win.current_messages.get("msg_error", "❌ Error."),
                        20,
                    )
                    self.on_progress_callback(
                        f"{_message}: {_disp_name} (Status: {_web_data.status})"
                    )

    async def download_web_files(self) -> None:
        timeout = ClientTimeout(total=None, connect=30, sock_read=60)
        semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)

        async with aiohttp.ClientSession(
            timeout=timeout, raise_for_status=False
        ) as session:
            self._active_tasks = []
            for _mdia_data in self.win.async_handler.target_items:
                if not _mdia_data.web_path:
                    continue
                _coro = self._download_single_media(
                    semaphore=semaphore,
                    session=session,
                    mdia_data=_mdia_data,
                )
                _task = asyncio.ensure_future(_coro)
                self._active_tasks.append(_task)
            if self._active_tasks:
                try:
                    await asyncio.gather(*self._active_tasks)
                except asyncio.CancelledError:
                    if self.on_progress_callback:
                        _message = ljust(
                            self.win.current_messages.get(
                                "msg_info_cancel_complete",
                                "🎉 The cancellation process has been completed.",
                            ),
                            20,
                        )
                        self.on_progress_callback(f"{_message}")
                    raise
                finally:
                    self._active_tasks = []
