"""async download"""

# --- Python library ----------------------------------------------------------
import asyncio
import tempfile
from pathlib import Path
from types import SimpleNamespace
from typing import Any, Callable, Mapping

import aiohttp

# --- my library --------------------------------------------------------------
from common.shared import InfoCommon
from common.utils import (
    get_caller_name,
    handle_fatal_error,
    ljust,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
class AsyncRsync:
    info_comm: InfoCommon
    semaphore: SimpleNamespace
    session: aiohttp.ClientSession
    search_url: str
    local_file: str
    exclude_url: str
    current_messages: dict
    # --- rsync options -------------------------------------------------------
    _rsync_opt = [
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

    def __init__(self) -> None:
        self.on_progress_callback: Callable[[str], None] | None = None

    async def get_rsyncs(self) -> bool:
        _caller = get_caller_name()
        _status = False
        semaphore = asyncio.Semaphore(self.semaphore.infowebs)
        async with semaphore:
            for d in self.info_comm.mdia:
                _disp_name = getattr(d, "entry_disp", d.entry_name)
                _mdia_type = getattr(d, "mdia_type", d.mdia_type)
                if not d.iso_path:
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
                            'msg_info_Synchronizing', '➔ Synchronizing'
                        ),
                        20,
                    )
                }: {_disp_name} ({_mdia_type})..."
                if self.on_progress_callback:
                    self.on_progress_callback(_message)
                else:
                    message_info(_caller, _message, omit=True)
                # -------------------------------------------------------------
                message_info(_caller, f"[Queue] Fetching: {d.iso_path}", omit=True)
                # --- rsync parameters ----------------------------------------
                _temp_obj = tempfile.TemporaryDirectory()
                _src_path = Path(d.iso_path)
                _dest_path = self.info_comm.get_path("DIRS_IMGS") / d.entry_name
                _mount_path = Path(_temp_obj.name)
                _rsync_src = f"{str(_mount_path)}/."
                _rsync_dest = f"{str(_dest_path)}/"
                _sudo_args = ["sudo", "-n"]
                _nice_args = ["nice", "-n", "19"]
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
                _rsync_args = [
                    *_sudo_args,
                    *_nice_args,
                    "rsync",
                    *self._rsync_opt,
                    _rsync_src,
                    _rsync_dest,
                ]
                _status = False
                _mounted = False
                try:
                    _mount_path.mkdir(parents=True, exist_ok=True)
                    _dest_path.mkdir(parents=True, exist_ok=True)
                    # --- mount -----------------------------------------------
                    _mount_proc = await asyncio.create_subprocess_exec(
                        *_mount_args, **self._kwargs
                    )
                    _, _stderr_mount = await _mount_proc.communicate()
                    _mounted = _mount_proc.returncode == 0
                    # --- rsync -------------------------------------------
                    if _mounted:
                        _rsync_proc = await asyncio.create_subprocess_exec(
                            *_rsync_args, **self._kwargs
                        )
                        _status = _rsync_proc.returncode == 0
                        for _args in (_umount_args, _umount_f_args, _umount_l_args):
                            _umount_proc = await asyncio.create_subprocess_exec(
                                *_args, **self._kwargs
                            )
                            await _umount_proc.communicate()
                            if _umount_proc.returncode == 0:
                                _mounted = False
                                _status = True
                except asyncio.CancelledError:
                    _message = f"{
                        ljust(
                            self.current_messages.get(
                                'msg_info_cancel_complete',
                                '🎉 The cancellation process has been completed.',
                            ),
                            20,
                        )
                    }: {_disp_name} ({_mdia_type})..."
                    if self.on_progress_callback:
                        self.on_progress_callback(_message)
                    else:
                        message_info(_caller, _message, omit=True)
                    raise
                except Exception as e:
                    handle_fatal_error("RsyncAsyncHandler", e, raise_exit=False)
                if _mounted:
                    _status = False
                else:
                    _temp_obj.cleanup()
                    _message = f"{
                        ljust(
                            self.current_messages.get(
                                'msg_info_complete', '✓ Completed.'
                            ),
                            20,
                        )
                    }: {_disp_name} ({_mdia_type})..."
                    if self.on_progress_callback:
                        self.on_progress_callback(_message)
                    else:
                        message_info(_caller, _message, omit=True)
        return _status


# --- eof ---------------------------------------------------------------------
