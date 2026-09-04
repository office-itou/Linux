# --- Python library ----------------------------------------------------------
import asyncio
import re
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# from tqdm import tqdm
# from urllib.parse import urlparse
import aiohttp  # sudo apt-get install python3-aiohttp
from bs4 import BeautifulSoup
from natsort import natsort_keygen
from py_common.my_colors import color

# --- my library --------------------------------------------------------------
from py_common.my_config import infosystem
from py_common.my_debug import debug_logger, debugout
from py_common.my_message import get_caller_name, message_alert, message_warn


# -----------------------------------------------------------------------------
@dataclass
class WebData:
    regexp: str = ""
    url: str = ""
    tmstamp: str = ""
    size: int = 0
    check: str = ""
    status: int = 0
    reason: str = ""
    mime: str = ""
    contents: str = ""
    output: str = ""


class InfoWeb:
    def __init__(self, data: WebData | None = None):
        self.data: WebData = data if data is not None else WebData()

    def get_data(self) -> WebData:
        return self.data

    async def get_info(
        self, session: aiohttp.ClientSession, target_regexp: str, target_path: str
    ) -> WebData:
        self.data = await get_info(session, target_regexp, target_path)
        return self.data

    async def get_response(
        self, session: aiohttp.ClientSession, target_url: str
    ) -> WebData:
        self.data = await get_response(session.get, target_url)
        return self.data

    async def get_header(
        self, session: aiohttp.ClientSession, target_url: str
    ) -> WebData:
        self.data = await get_header(session, target_url)
        return self.data

    async def get_text(
        self, session: aiohttp.ClientSession, target_url: str
    ) -> WebData:
        self.data = await get_text(session, target_url)
        return self.data

    def url_strip(self, data: str) -> str:
        return url_strip(data)


BASE_HEADERS = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Accept-Language": "ja,en;q=0.9,en-GB;q=0.8,en-US;q=0.7,ja-JP;q=0.6",
    "Cache-Control": "max-age=0",
    "Connection": "keep-alive",
    "Content-Security-Policy": "upgrade-insecure-requests",
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36 Edg/152.0.0.0",
}


# -----------------------------------------------------------------------------
# descript: url stripping
#   input : data                  : input
#   output:                       : unused
#   return: text                  : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
def url_strip(data: str) -> str:
    text = re.sub(r"[\n|\r\n]$", "", data)  # remove lf or crlf
    text = re.sub(r"^\"", "", text)  # remove the first double quotation mark
    text = re.sub(r"\"$", "", text)  # remove the last double quotation mark
    text = re.sub(r"^/", "", text)  # remove the first '/'
    text = re.sub(r"/$", "", text)  # remove the last '/'
    return text


# -----------------------------------------------------------------------------
# descript: get response
#   input : session               : input
#   input : target_url            : input
#   output:                       : unused
#   return: WebData               : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
async def get_response(request_func: Callable, target_url: str) -> WebData:
    host_match = re.sub(r"http[s]*://([^/]+)/.*$", r"\1", target_url)
    req_url = target_url
    req_headers = BASE_HEADERS.copy()
    req_headers["Host"] = host_match if host_match else req_headers["Host"]
    req_headers = ""
    info = WebData()
    for r in range(3):
        try:
            async with request_func(
                req_url, headers=req_headers, allow_redirects=True, timeout=60
            ) as response:
                info.url = response.url if hasattr(response, "url") else ""
                info.status = response.status if hasattr(response, "status") else 0
                info.reason = response.reason if hasattr(response, "reason") else ""
                content_length = response.headers.get("Content-Length")
                info.size = (
                    int(content_length)
                    if content_length and content_length.isdigit()
                    else 0
                )
                last_mod = response.headers.get("Last-Modified")
                if last_mod:
                    try:
                        info.tmstamp = (
                            datetime.strptime(last_mod, "%a, %d %b %Y %H:%M:%S %Z")
                            .replace(tzinfo=timezone.utc)
                            .isoformat()
                        )
                    except ValueError:
                        info.tmstamp = last_mod
                info.mime = response.headers.get("content-type", "")
                info.contents = (
                    await response.text() if hasattr(response, "text") else ""
                )
                response.raise_for_status()
                break
        except (
            aiohttp.ClientConnectorError,
            aiohttp.ClientResponseError,
            aiohttp.ClientError,
            asyncio.TimeoutError,
        ) as e:
            message_alert(get_caller_name(), f"HTTP/Connection error: {e}")
            message_warn(get_caller_name(), f"retry({r}): {target_url}")
            await asyncio.sleep(1)
        except Exception as e:
            message_alert(get_caller_name(), f"Fatal error: {e}")
            raise SystemExit
    return info


# -----------------------------------------------------------------------------
# descript: get header
#   input : session               : input
#   input : target_url            : input
#   output:                       : unused
#   return: WebData               : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
async def get_header(session: aiohttp.ClientSession, target_url: str) -> WebData:
    return await get_response(session.head, target_url)


# -----------------------------------------------------------------------------
# descript: get text
#   input : session               : input
#   input : target_url            : input
#   output:                       : unused
#   return: WebData               : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
async def get_text(session: aiohttp.ClientSession, target_url: str) -> WebData:
    return await get_response(session.get, target_url)


# -----------------------------------------------------------------------------
# descript: get web information data
#   input : session               : input
#   input : target_regexp         : input
#   input : target_path           : input
#   output:                       : unused
#   return: WebData               : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
async def get_info(session: Any, target_regexp: str, target_path: str) -> WebData:
    data = WebData()
    target_url = target_regexp
    match_dirs = ""
    match_ptrn = ""
    match_rear = ""
    status = True
    while True:
        match = re.search(r"[^/ \t]*\[[^/ \t]+\][^/ \t]*", target_url)
        if not match:
            break
        match_dirs = url_strip(target_url[0 : match.start()])
        match_ptrn = url_strip(match.group())
        match_rear = url_strip(target_url[match.end() :])
        if match_rear:
            match_ptrn = match_ptrn + "/"
        target_url = match_dirs
        data = await get_text(session, target_url)
        if data.status != 200:
            status = False
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                "# " + "-" * infosystem.columns + " #",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"target_regexp:[{target_regexp}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"target_url   :[{target_url}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.regexp   :[{data.regexp}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.url      :[{data.url}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.tmstamp  :[{data.tmstamp}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.size     :[{data.size}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.check    :[{data.check}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.status   :[{data.status}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.reason   :[{data.reason}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.mime     :[{data.mime}]",
            )
            if data.mime and "text" in data.mime:
                debugout(
                    get_caller_name(only=False),
                    "Debugout",
                    color.yellow,
                    f"web.contents :[{data.contents}]",
                )
            else:
                debugout(
                    get_caller_name(only=False),
                    "Debugout",
                    color.yellow,
                    f"web.contents :error: mime({data.mime})",
                )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                f"web.output   :[{data.output}]",
            )
            debugout(
                get_caller_name(only=False),
                "Debugout",
                color.yellow,
                "# " + "-" * infosystem.columns + " #",
            )
            break
        match_url = []
        soup = BeautifulSoup(data.contents, "html.parser")
        for a in soup.find_all("a"):
            href = a.get("href")
            if not href:
                continue
            match_href = re.match(f"{match_ptrn}", href)
            if not match_href:
                continue
            match_url.append(match_href.group())
        if not match_url:
            status = False
            message_warn(
                get_caller_name(), f"No matching links found for pattern: {match_ptrn}"
            )
            break
        match_url.sort(key=natsort_keygen(), reverse=True)
        target_url = target_url + "/" + match_url[0]
        if match_rear:
            target_url = target_url + match_rear
    if status:
        for i in range(5):
            data = await get_header(session, target_url)
            if data.status in (200, 404):
                break
            message_warn(get_caller_name(), f"retry({i})")
            await asyncio.sleep(3)
    data.regexp = target_regexp if target_regexp else "-"
    data.url = target_url if target_url else "-"
    filename = re.sub(r"^.+/", "", target_url)
    match filename:
        case "mini.iso":
            if re.match(r"^http(|s)://.+/(debian|ubuntu)/dists/.+$", target_url):
                arch = re.sub(r"/current/.+$", "", target_url)
                arch = re.sub(r"^.+/.+-", "", arch)
                code = re.sub(r"/main/.+$", "", target_url)
                code = re.sub(r"^.+/", "", code)
                code = re.sub(r"-.+$", "", code)
                filename = f"mini-{code}-{arch}.iso"
            elif re.match(r"^http(|s)://d-i.debian.org/daily-images/.+$", target_url):
                arch = re.sub(r"/daily/.+$", "", target_url)
                arch = re.sub(r"^.+/", "", arch)
                filename = f"mini-testing-daily-{arch}.iso"
        case s if re.match(r"debian-testing-.+-netinst\.iso", s):
            edtn = re.sub(r"^.+/cdimage/", "", target_url)
            edtn = re.sub(r"-.+", "", edtn)
            arch = re.sub(r"/iso-cd/.+$", "", target_url)
            arch = re.sub(r"^.+/", "", arch)
            bild = re.sub(r"/" + arch + r"/.+$", "", target_url)
            bild = re.sub(r"^.+/", "", bild)
            if bild:
                edtn = f"{edtn}-{bild}"
            filename = re.sub(arch, f"{edtn}-{arch}", filename)
    data.output = str(
        Path(target_path).with_name(filename) if target_path and filename else "-"
    )
    return data


# --- eof ---------------------------------------------------------------------
