"""async download"""

# --- Python library ----------------------------------------------------------
import asyncio
import tempfile
import threading
from asyncio.subprocess import Process
from pathlib import Path
from typing import Any, Mapping

import aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
from common.shared import (
    MediaData,
)
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    ljust,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
class AsyncRsync:
    # --- rsync options -------------------------------------------------------
    _rsync_opt: list[str] = [
        "--recursive",
        "--links",
        "--perms",
        "--times",
        "--group",
        "--owner",
        "--devices",
        "--specials",
        "--hard-links",
        "--acls",
        "--xattrs",
        "--human-readable",
        "--delete",
        "--info=stats2",
        "--compress",
    ]
    _kwargs: Mapping[str, Any] = {
        "stdout": asyncio.subprocess.PIPE,
        "stderr": asyncio.subprocess.PIPE,
    }

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
                await self.get_rsyncs()
        finally:
            self.is_running = False
            self.win.on_handler_complete()

    @debug_logger
    async def get_rsyncs_single(self, mdia_data: MediaData) -> bool:
        _caller = get_caller_name()
        _status = False
        _disp_name = getattr(mdia_data, "entry_disp", mdia_data.entry_name)
        _mdia_type = getattr(mdia_data, "mdia_type", mdia_data.mdia_type)
        if not mdia_data.iso_path:
            _message: str = f"{
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
            return _status
        _message: str = f"{
            ljust(
                self.win.current_messages.get(
                    'msg_info_Synchronizing', '➔ Synchronizing'
                ),
                20,
            )
        }: {_disp_name} ({_mdia_type})..."
        if self.win.append_log:
            self.win.append_log(_message)
        else:
            message_info(_caller, _message, omit=True)
        # -------------------------------------------------------------
        message_info(_caller, f"[Queue] Fetching: {mdia_data.iso_path}", omit=True)
        # --- rsync parameters ----------------------------------------
        _temp_obj: tempfile.TemporaryDirectory[str] = tempfile.TemporaryDirectory()
        _src_path = Path(mdia_data.iso_path)
        _dest_path = (
            self.win.info_comm.conf.get_path("DIRS_IMGS") / mdia_data.entry_name
        )
        _mount_path = Path(_temp_obj.name)
        _rsync_src: str = f"{str(_mount_path)}/."
        _rsync_dest: str = f"{str(_dest_path)}/"
        _sudo_args: list[str] = ["sudo", "-n"]
        _nice_args: list[str] = ["nice", "-n", "19"]
        _mount_args = [
            *_sudo_args,
            "mount",
            "-o",
            "loop,ro",
            _src_path,
            _mount_path,
        ]
        _umount_args = [*_sudo_args, "umount", _mount_path]
        _umount_f_args = [*_sudo_args, "umount", "-f", _mount_path]
        _umount_l_args = [*_sudo_args, "umount", "-l", _mount_path]
        _rsync_args: list[str] = [
            *_sudo_args,
            *_nice_args,
            "rsync",
            *self._rsync_opt,
            _rsync_src,
            _rsync_dest,
        ]
        _mounted = False
        try:
            _mount_path.mkdir(parents=True, exist_ok=True)
            _dest_path.mkdir(parents=True, exist_ok=True)
            # --- mount -----------------------------------------------
            _mount_proc: Process = await asyncio.create_subprocess_exec(
                *_mount_args, **self._kwargs
            )
            _, _stderr_mount = await _mount_proc.communicate()
            _mounted: bool = _mount_proc.returncode == 0
            # --- rsync -------------------------------------------
            if _mounted:
                _rsync_proc: Process = await asyncio.create_subprocess_exec(
                    *_rsync_args, **self._kwargs
                )
                _status: bool = _rsync_proc.returncode == 0
                for _args in (_umount_args, _umount_f_args, _umount_l_args):
                    _umount_proc: Process = await asyncio.create_subprocess_exec(
                        *_args, **self._kwargs
                    )
                    await _umount_proc.communicate()
                    if _umount_proc.returncode == 0:
                        _mounted = False
                        _status = True
        except asyncio.CancelledError:
            _message: str = f"{
                ljust(
                    self.win.current_messages.get(
                        'msg_info_cancel_complete',
                        '🎉 The cancellation process has been completed.',
                    ),
                    20,
                )
            }: {_disp_name} ({_mdia_type})..."
            if self.win.append_log:
                self.win.append_log(_message)
            else:
                message_info(_caller, _message, omit=True)
            raise
        except Exception as e:
            handle_fatal_error("RsyncAsyncHandler", e, raise_exit=False)
        if _mounted:
            _status = False
        else:
            _temp_obj.cleanup()
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

    @debug_logger
    async def get_rsyncs(self) -> bool:
        _caller = get_caller_name()
        _status = False
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
                await self.get_rsyncs_single(mdia_data=mdia_data)
            self.win.update_progress(
                current=current_data, total=total_datas, is_complete=True
            )
        return _status


# --- eof ---------------------------------------------------------------------
