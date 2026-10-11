"""async download"""

# --- Python library ----------------------------------------------------------
import asyncio
import threading
from datetime import datetime

import aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
from common.shared import (
    MediaData,
)
from common.utils import (
    FileData,
    WebData,
    get_caller_name,
    get_contents,
    get_infofile,
    get_infoweb,
    ljust,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
class AsyncDownload:
    def __init__(self, win) -> None:
        self.win = win
        self.is_running = False
        self.is_cancelled = False
        self.semaphore = asyncio.Semaphore(5)
        self.session = None

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
        _message = f"{
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
                self.session = session
                await self.get_downloads()
        finally:
            self.is_running = False
            self.win.on_handler_complete()

    async def get_downloads(self) -> None:
        _caller = get_caller_name()
        semaphore = asyncio.Semaphore(3)
        async with semaphore:
            mdia_data: list[MediaData] = [
                d for d in self.win.info_comm.mdia.data if d.target_flag == "o"
            ]
            total_datas = len(mdia_data)
            current_data = 0
            self.win.update_progress(
                current=current_data, total=total_datas, is_complete=False
            )
            for d in mdia_data:
                if self.is_cancelled:
                    _message = f"{
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
                if d.target_flag != "o":
                    continue
                current_data += 1
                self.win.update_progress(
                    current=current_data, total=total_datas, is_complete=False
                )
                _disp_name = getattr(d, "entry_disp", d.entry_name)
                _mdia_type = getattr(d, "mdia_type", d.mdia_type)
                if not d.web_path:
                    _message = f"{
                        ljust(
                            self.win.current_messages.get(
                                'msg_info_no_target_file', 'No target file'
                            ),
                            20,
                        )
                    }: {_disp_name} ({_mdia_type})..."
                    if self.win.append_log:
                        self.win.append_log(_message)
                    else:
                        message_info(_caller, _message, omit=True)
                    continue
                # -------------------------------------------------------------
                _message = f"[Queue] Fetching: {d.web_regexp}"
                message_info(_caller, _message, omit=True)
                # --- get web datas -----------------------------------
                _web_datas: list[WebData] = await get_infoweb(
                    self.session,
                    d.web_path,
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
                if d.web_tstamp and d.iso_tstamp:
                    dt1 = datetime.fromisoformat(d.web_tstamp)
                    dt2 = datetime.fromisoformat(d.iso_tstamp)
                    if dt1 <= dt2:
                        _message = f"{
                            ljust(
                                self.win.current_messages.get('msg_info_skip', 'Skip'),
                                20,
                            )
                        }: {_disp_name} ({_mdia_type})..."
                        if self.win.append_log:
                            self.win.append_log(_message)
                        else:
                            message_info(_caller, _message, omit=True)
                        continue
                # -------------------------------------------------------------
                _message = f"{
                    ljust(
                        self.win.current_messages.get(
                            'msg_info_downloading', '➔ Downloading'
                        ),
                        20,
                    )
                }: {_disp_name} ({_mdia_type})..."
                if self.win.append_log:
                    self.win.append_log(_message)
                else:
                    message_info(_caller, _message, omit=True)
                # -------------------------------------------------------------
                message_info(_caller, f"[Queue] Fetching: {d.web_path}", omit=True)
                # --- get web datas -------------------------------------------
                w = await get_contents(
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
                        self.win.current_messages.get(
                            'msg_info_complete', '✓ Completed.'
                        ),
                        20,
                    )
                }: {_disp_name} ({_mdia_type})..."
                if self.win.append_log:
                    self.win.append_log(_message)
                else:
                    message_info(_caller, _message, omit=True)
            self.win.update_progress(
                current=current_data, total=total_datas, is_complete=True
            )


# --- eof ---------------------------------------------------------------------
