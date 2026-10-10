"""async download"""

# --- Python library ----------------------------------------------------------
import asyncio
from types import SimpleNamespace
from typing import Callable

import aiohttp

# --- my library --------------------------------------------------------------
from common.shared import InfoCommon
from common.utils import (
    FileData,
    get_caller_name,
    get_contents,
    get_infofile,
    ljust,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
class AsyncDownload:
    info_comm: InfoCommon
    semaphore: SimpleNamespace
    session: aiohttp.ClientSession
    search_url: str
    local_file: str
    exclude_url: str
    current_messages: dict

    def __init__(self) -> None:
        self.on_progress_callback: Callable[[str], None] | None = None

    async def get_downloads(self) -> None:
        _caller = get_caller_name()
        semaphore = asyncio.Semaphore(self.semaphore.infowebs)
        async with semaphore:
            for d in self.info_comm.mdia:
                _disp_name = getattr(d, "entry_disp", d.entry_name)
                _mdia_type = getattr(d, "mdia_type", d.mdia_type)
                if not d.web_path:
                    _message = f"{
                        ljust(
                            self.current_messages.get(
                                'msg_info_no_target_file', 'No target file'
                            ),
                            20,
                        )
                    }: {_disp_name} ({_mdia_type})..."
                    if self.on_progress_callback:
                        self.on_progress_callback(_message)
                    else:
                        message_info(_caller, _message, omit=True)
                    continue
                _message = f"{
                    ljust(
                        self.current_messages.get(
                            'msg_info_downloading', '➔ Downloading'
                        ),
                        20,
                    )
                }: {_disp_name} ({_mdia_type})..."
                if self.on_progress_callback:
                    self.on_progress_callback(_message)
                else:
                    message_info(_caller, _message, omit=True)
                # -------------------------------------------------------------
                message_info(_caller, f"[Queue] Fetching: {d.web_path}", omit=True)
                # --- get web datas -------------------------------------------
                w = await asyncio.to_thread(
                    get_contents,
                    self.session,
                    d.web_path,
                    d.iso_path,
                    True,
                    False,
                )
                # --- store web data ------------------------------------------
                if int(w.status, 0) in (200, 206):
                    d.iso_path = w.local_file
                    # --- store file data -------------------------------------
                    _file_data: FileData = await asyncio.to_thread(
                        get_infofile, d.iso_path
                    )
                    d.iso_tstamp = _file_data.tmstamp
                    d.iso_size = _file_data.size
                    d.iso_volume = _file_data.volume
                # -------------------------------------------------------------
                _message = f"{
                    ljust(
                        self.current_messages.get('msg_info_complete', '✓ Completed.'),
                        20,
                    )
                }: {_disp_name} ({_mdia_type})..."
                if self.on_progress_callback:
                    self.on_progress_callback(_message)
                else:
                    message_info(_caller, _message, omit=True)


# --- eof ---------------------------------------------------------------------
