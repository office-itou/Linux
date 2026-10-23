"""async web info"""

# --- Python library ----------------------------------------------------------
import asyncio
import threading
from typing import Any

import aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
from common.shared import (
    MediaData,
)
from common.utils import (
    FileData,
    WebData,
    debug_logger,
    get_caller_name,
    get_infofile,
    get_infoweb,
    ljust,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
class AsyncWebInfo:
    def __init__(self, win) -> None:
        self.win: Any = win
        self.is_running = False
        self.is_cancelled = False
        self.semaphore = asyncio.Semaphore(5)
        self.session = aiohttp.ClientSession()

    def start_process(self) -> None:
        if self.is_running:
            return
        self.is_running = True
        self.is_cancelled = False
        threading.Thread(
            target=lambda: asyncio.run(self._run_loop()), daemon=True
        ).start()

    def cancel_process(self) -> None:
        if not self.is_running:
            return
        self.is_cancelled = True
        _caller = get_caller_name()
        _message: str = f"{
            ljust(
                self.win.current_messages.get(
                    'msg_info_cancel_accepted',
                    '⏳ Cancellation request accepted. Stopping...',
                ),
                20,
            )
        }"
        if self.win.append_log:
            self.win.append_log(_message)
        else:
            message_info(_caller, _message, omit=True)

    async def _run_loop(self) -> None:
        try:
            timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
            async with aiohttp.ClientSession(
                timeout=timeout, raise_for_status=False
            ) as session:
                self.session: aiohttp.ClientSession = session
                await self.get_infowebs()
        finally:
            self.is_running = False
            self.win.on_handler_complete()

    @debug_logger
    async def get_infowebs_single(self, mdia_data: MediaData) -> bool:
        _caller = get_caller_name()
        _status = False
        _disp_name = getattr(mdia_data, "entry_disp", mdia_data.entry_name)
        _mdia_type = getattr(mdia_data, "mdia_type", mdia_data.mdia_type)
        _message: str = f"{
            ljust(
                self.win.current_messages.get(
                    'msg_info_communicating', '➔ Communicating'
                ),
                20,
            )
        }: {_disp_name} ({_mdia_type})..."
        if self.win.append_log:
            self.win.append_log(_message)
        else:
            message_info(_caller, _message, omit=True)
        # -------------------------------------------------------------
        if mdia_data.web_regexp:
            _message: str = f"[Queue] Fetching: {mdia_data.web_regexp}"
            message_info(_caller, _message, omit=True)
            # --- get web datas -----------------------------------
            _web_datas: list[WebData] = await get_infoweb(
                self.session,
                mdia_data.web_regexp,
                mdia_data.iso_path,
                None,
            )
            if _web_datas:
                _status = True
            # --- store web data --------------------------------------
            for w in _web_datas:
                mdia_data.web_regexp = w.search_url
                mdia_data.web_path = w.request_url
                mdia_data.web_tstamp = w.time_stamp
                mdia_data.web_size = w.file_size
                mdia_data.web_check = w.check_date
                mdia_data.web_status = w.status
                mdia_data.iso_path = w.local_file
        # --- store file data -----------------------------------------
        _file_data: FileData = await asyncio.to_thread(get_infofile, mdia_data.iso_path)
        mdia_data.iso_tstamp = _file_data.tmstamp
        mdia_data.iso_size = _file_data.size
        mdia_data.iso_volume = _file_data.volume
        # -------------------------------------------------------------
        _message: str = f"{
            ljust(
                self.win.current_messages.get('msg_info_complete', '✓ Completed.'),
                20,
            )
        }: {_disp_name} ({_mdia_type})..."
        if self.win.append_log:
            self.win.append_log(_message)
        else:
            message_info(_caller, _message, omit=True)
        return _status

    async def get_infowebs(self) -> None:
        _caller = get_caller_name()
        async with self.semaphore:
            mdia_datas: list[MediaData] = [
                d for d in self.win.info_comm.mdia.data if d.target_flag == "o"
            ]
            total_datas: int = len(mdia_datas)
            current_data = 0
            self.win.update_progress(
                current=current_data, total=total_datas, is_complete=False
            )
            for mdia_data in mdia_datas:
                if self.is_cancelled:
                    _message: str = f"{
                        ljust(
                            self.win.current_messages.get(
                                'msg_info_cancel_accepted',
                                '⏳ The cancellation request has been accepted.',
                            ),
                            20,
                        )
                    }"
                    if self.win.append_log:
                        self.win.append_log(_message)
                    else:
                        message_info(_caller, _message, omit=True)
                    break
                if mdia_data.target_flag != "o":
                    continue
                current_data += 1
                self.win.update_progress(
                    current=current_data, total=total_datas, is_complete=False
                )
                await self.get_infowebs_single(mdia_data=mdia_data)
            self.win.update_progress(
                current=current_data, total=total_datas, is_complete=True
            )


# --- eof ---------------------------------------------------------------------
