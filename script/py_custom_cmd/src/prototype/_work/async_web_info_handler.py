"""async web info"""

# --- Python library ----------------------------------------------------------
import asyncio
from types import SimpleNamespace
from typing import Callable

import aiohttp

# --- my library --------------------------------------------------------------
from common.shared import InfoCommon
from common.utils import (
    FileData,
    WebData,
    get_caller_name,
    get_infofile,
    get_infoweb,
    ljust,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
class AsyncWebInfo:
    info_comm: InfoCommon
    semaphore: SimpleNamespace
    session: aiohttp.ClientSession
    search_url: str
    local_file: str
    exclude_url: str
    current_messages: dict

    def __init__(self) -> None:
        self.on_progress_callback: Callable[[str], None] | None = None

    async def get_infowebs(self) -> None:
        _caller = get_caller_name()
        async with self.semaphore.infowebs:
            for d in self.info_comm.mdia:
                _disp_name = getattr(d, "entry_disp", d.entry_name)
                _mdia_type = getattr(d, "mdia_type", d.mdia_type)
                _message = f"{
                    ljust(
                        self.current_messages.get(
                            'msg_info_communicating', '➔ Communicating'
                        ),
                        20,
                    )
                }: {_disp_name} ({_mdia_type})..."
                if self.on_progress_callback:
                    self.on_progress_callback(_message)
                else:
                    message_info(_caller, _message, omit=True)
                # -------------------------------------------------------------
                if d.web_regexp:
                    _message = f"[Queue] Fetching: {d.web_regexp}"
                    if self.on_progress_callback:
                        self.on_progress_callback(_message)
                    else:
                        message_info(_caller, _message, omit=True)
                    # --- get web datas -----------------------------------
                    _web_datas: list[WebData] = await asyncio.to_thread(
                        get_infoweb,
                        self.session,
                        d.web_regexp,
                        d.iso_path,
                        None,
                    )
                    # --- store web data --------------------------------------
                    for w in _web_datas:
                        d.web_regexp = w.search_url
                        d.web_path = w.request_url
                        d.web_tstamp = w.time_stamp
                        d.web_size = w.file_size
                        d.web_check = w.check_date
                        d.web_status = w.status
                        d.iso_path = w.local_file
                # --- store file data -----------------------------------------
                _file_data: FileData = await asyncio.to_thread(get_infofile, d.iso_path)
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
