"""Web API"""

# --- Python library ----------------------------------------------------------
import asyncio
import os
import shutil
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

import aiofiles  # sudo apt-get install python3-aiofiles
import aiohttp  # sudo apt-get install python3-aiohttp
from rich.progress import (
    BarColumn,
    DownloadColumn,
    Progress,
    TextColumn,
    TimeRemainingColumn,
    TransferSpeedColumn,
)

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_error import handle_fatal_error
from .my_message import get_caller_name, message_alert, message_info, message_warn


@dataclass
class WebData:
    """Web data class"""

    search_url: str = ""
    exclude_url: str = ""
    request_url: str = ""
    response_url: str = ""
    local_file: str = ""
    time_stamp: str = ""
    file_size: str = ""
    check_date: str = ""
    status: str = ""
    reason: str = ""
    mime: str = ""
    text: str = ""
    content: bytes = b""


def generate_wget_filename(base_name: str) -> Path:
    base_name_path = Path(base_name)
    if not base_name_path.exists():
        return base_name_path
    _counter = 1
    while True:
        _new_path = base_name_path.with_name(base_name_path.name + str(_counter))
        if not _new_path.exists():
            return _new_path
        _counter += 1


async def get_response(
    request_func: Callable,
    request_url: str,
    local_file: str = "",
    overwrite: bool = False,
) -> dict:
    """Get response

    Args:
        request_func (Callable): Request function
        request_url (str): Request URL
        local_file_path (str, optional): Local file name. Defaults to "".
        overwrite (bool, optional): Overwrite. Defaults to False.

    Returns:
        dict: Result
    """
    _caller = get_caller_name()
    _check_date = datetime.now(timezone.utc).isoformat(timespec="microseconds")
    _chunk_size = 10 * 1024
    _max_retries = 3
    if local_file:
        _local_file_path = Path(local_file).resolve()
        _final_file_path = (
            _local_file_path if overwrite else generate_wget_filename(_local_file_path)
        )
        _tmp_file_path = f"{_final_file_path}.tmp" if _final_file_path else ""
    else:
        _final_file_path = ""
        _tmp_file_path = ""
    _web_data = WebData(
        request_url=request_url,
        local_file=str(_final_file_path),
        check_date=_check_date,
    )

    # -------------------------------------------------------------------------
    _timeout = aiohttp.ClientTimeout(total=None, connect=30, sock_read=30)
    for _attempt in range(1, _max_retries + 1):
        try:
            _downloaded_bytes = 0
            _headers = {}
            if _tmp_file_path:
                if Path(_tmp_file_path).exists():
                    _downloaded_bytes = os.path.getsize(_tmp_file_path)
                # -------------------------------------------------------------
                if _downloaded_bytes > 0:
                    _headers["Range"] = f"bytes={_downloaded_bytes}-"
                    message_warn(
                        _caller, f"Retry({_attempt}): resume({_downloaded_bytes})"
                    )
            # -----------------------------------------------------------------
            async with request_func(
                request_url, allow_redirects=True, timeout=_timeout, headers=_headers
            ) as _response:
                _web_data.status = _response.status
                _web_data.reason = _response.reason
                _web_data.check_date = datetime.now(timezone.utc).isoformat()
                if _response.status not in (200, 206):
                    message_alert(_caller, f"server returned error: {_response.status}")
                    break
                # -------------------------------------------------------------
                _web_data.response_url = str(_response.url)
                _last_mod = _response.headers.get("Last-Modified", "")
                _last_mod_isoformat = (
                    (
                        datetime.strptime(_last_mod, "%a, %d %b %Y %H:%M:%S %Z")
                        .replace(tzinfo=timezone.utc)
                        .isoformat()
                    )
                    if _last_mod
                    else ""
                )
                _web_data.time_stamp = _last_mod_isoformat
                _content_length = _response.headers.get("Content-Length", 0)
                _total_size = (
                    int(_content_length) + _downloaded_bytes
                    if _content_length
                    else None
                )
                _web_data.file_size = str(_total_size)
                _web_data.mime = _response.headers.get("content-type", "")
                if "text" in _web_data.mime or "json" in _web_data.mime:
                    _web_data.text = await _response.text(encoding="utf-8")
                else:
                    _web_data.text = ""
                # -------------------------------------------------------------
                if _tmp_file_path:
                    message_info(_caller, f"download: {_final_file_path}")
                    with Progress(
                        TextColumn("[bold blue]{task.description}"),
                        BarColumn(),
                        "[progress.percentage]{task.percentage:>3.0f}%",
                        DownloadColumn(),
                        TransferSpeedColumn(),
                        TimeRemainingColumn(),
                    ) as _progress:
                        _task_id = _progress.add_task(
                            description=os.path.basename(_final_file_path),
                            total=_total_size,
                            completed=_downloaded_bytes,
                        )
                        _local_file_path.parent.mkdir(parents=True, exist_ok=True)
                        async with aiofiles.open(_tmp_file_path, mode="ab") as f:
                            while True:
                                _chunk = await _response.content.read(_chunk_size)
                                if not _chunk:
                                    break
                                await f.write(_chunk)
                                _progress.update(_task_id, advance=len(_chunk))
                    # ---------------------------------------------------------
                    if Path(_tmp_file_path).exists():
                        shutil.move(_tmp_file_path, _final_file_path)
                        if _last_mod:
                            _mtime = datetime.fromisoformat(
                                _web_data.time_stamp
                            ).timestamp()
                            _atime = datetime.now(tz=timezone.utc).timestamp()
                            os.utime(_final_file_path, (_atime, _mtime))
                # -------------------------------------------------------------
                _web_data.status = _response.status
                _web_data.reason = _response.reason
                _web_data.check_date = datetime.now(timezone.utc).isoformat()
            return _web_data
        except (aiohttp.ClientError, asyncio.TimeoutError) as e:
            message_alert(_caller, f"HTTP/Connection error: {e}")
            if _attempt < _max_retries:
                await asyncio.sleep(3)
        except (OSError, Exception) as e:  # noqa: BLE001
            handle_fatal_error(_caller, e)
            break
    return _web_data


@debug_logger
async def get_header(session: aiohttp.ClientSession, request_url: str) -> dict:
    """Get header

    Args:
        session (aiohttp.ClientSession): Session object
        request_url (str): Request URL

    Returns:
        dict: Result
    """
    return await get_response(session.head, request_url)


@debug_logger
async def get_contents(
    session: aiohttp.ClientSession,
    request_url: str,
    local_file: str = "",
    overwrite: bool = False,
) -> dict:
    """Get contents

    Args:
        session (aiohttp.ClientSession): Session object
        request_url (str): Request URL
        local_file_path (str, optional): Local file name. Defaults to "".
        overwrite (bool, optional): Overwrite. Defaults to False.

    Returns:
        dict: Result
    """
    return await get_response(session.get, request_url, local_file, overwrite)
