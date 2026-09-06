#!/usr/bin/env python3
# encoding: utf-8

import aiohttp                          # sudo apt-get install python3-aiohttp
from aiohttp import ClientError, ClientTimeout
import pathlib
from pathlib import Path
import asyncio
import aiofiles

import inspect
import tempfile
from datetime import datetime, timezone
import shutil
import os
from tqdm import tqdm

from ..py_common.web import webinfo, get_header, get_text, get_info, set_webinfo, get_url2path

async def resume_download(session, url, dest_path):
    wi = webinfo()
    path = pathlib.Path(dest_path)
    downloaded_size = path.stat().st_size if path.exists() else 0
    headers = {"Range": f"bytes={downloaded_size}-"}
    async with session.get(url, headers=headers) as resp:
        wi = await set_webinfo(wi, url, path, resp)
        mode = "ab" if resp.status == 206 else "wb"
        if mode == "wb":
            downloaded_size = 0  # Restart if no range support
        async with aiofiles.open(path, mode) as f, tqdm(
                desc=path.name,
                total=int(resp.headers.get("content-length", 0)),
                unit="iB",
                unit_scale=True,
                unit_divisor=1024,
                leave=True,
                colour='CYAN',
                bar_format='{l_bar}{bar:a}{r_bar}',
                dynamic_ncols=False
            ) as bar:
                async for chunk in resp.content.read_any():
                    size = await f.write(chunk)
                    bar.update(size)
    return wi

# -----------------------------------------------------------------------------
async def download(url, *args):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({url}) START")
    # -------------------------------------------------------------------------
    wi = webinfo()
    path = get_url2path(url, *args)
    # -------------------------------------------------------------------------
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(raise_for_status=False, timeout=timeout) as session:
        async with session.get(url, allow_redirects=True) as response:
            wi = await set_webinfo(wi, url, path, response)
            response.raise_for_status()
            with tempfile.NamedTemporaryFile(delete=True) as tmp, tqdm(
                desc=Path(path).name,
                total=int(response.headers.get("content-length", 0)),
                unit="iB",
                unit_scale=True,
                unit_divisor=1024,
                leave=True,
                colour='CYAN',
                bar_format='{l_bar}{bar:a}{r_bar}',
                dynamic_ncols=False
            ) as bar:
                async for chunk in response.content.iter_chunked(1024**2):
                    size = tmp.write(chunk)
                    bar.update(size)
                    response.raise_for_status()
                mtime = datetime.strptime(wi.get("date"), "%Y/%m/%d %H:%M:%S %Z").replace(tzinfo=timezone.utc).timestamp()
                atime = datetime.now(tz=timezone.utc).timestamp()
                shutil.copy(tmp.name, path)
                os.utime(path, (atime, mtime))
    # -------------------------------------------------------------------------
    print(f"{func_name}({url}) END")
    return wi
