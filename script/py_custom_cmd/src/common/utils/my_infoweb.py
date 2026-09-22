"""Retrieves file information from the web."""

# --- Python library ----------------------------------------------------------
import asyncio
import fnmatch
import posixpath
import re


# import traceback
# from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import aiohttp  # sudo apt-get install python3-aiohttp

from bs4 import BeautifulSoup

# --- my library --------------------------------------------------------------
# from my_colors import Color
from my_debug import debug_logger
from my_message import get_caller_name, message_alert, message_warn
from my_web_api import WebData, get_contents, get_header
from natsort import natsort_keygen


# -----------------------------------------------------------------------------
class InfoWeb:
    """Web information class"""

    @debug_logger
    def __init__(self) -> None:
        self.data: list[WebData] = []

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            return getattr(self.data[0], name) if self.data else ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    @debug_logger
    def get_data(self) -> list[WebData]:
        return self.data

    @debug_logger
    async def get_header(
        self, session: aiohttp.ClientSession, request_url: str
    ) -> WebData:
        return await get_header(session, request_url)

    @debug_logger
    async def get_text(
        self, session: aiohttp.ClientSession, request_url: str
    ) -> WebData:
        return await get_contents(session, request_url)

    @debug_logger
    async def get_info(
        self,
        session: aiohttp.ClientSession,
        request_urls: str,
        local_file: str,
        exclude_urls: str = "",
    ) -> list[WebData]:
        self.data = await get_infoweb(session, request_urls, local_file, exclude_urls)
        return self.data


def _compile_exclude_regex(exclude_url: str) -> re.Pattern | None:
    """Compiling exclusion patterns"""
    if not exclude_url:
        return None
    # -------------------------------------------------------------------------
    _translated_patterns = []
    for s in exclude_url.split(","):
        s = s.strip()
        if not s:
            continue
        # ---- patterns with wildcards ----------------------------------------
        _range_match_with_wildcard = re.match(r"^(\d+)-(\d+)\.(.*)$", s)
        # ---- pattern with only numeric ranges ---------------------------
        _range_match_pure_num = re.match(r"^(\d+)-(\d+)$", s)
        # ---------------------------------------------------------------------
        if _range_match_with_wildcard:
            _start = int(_range_match_with_wildcard.group(1))
            _end = int(_range_match_with_wildcard.group(2))
            _remain = _range_match_with_wildcard.group(3)
            for _num in range(_start, _end + 1):
                _regex_str = fnmatch.translate(f"{_num}.{_remain}")
                _translated_patterns.append(f"(?:{_regex_str})")
            continue
        elif _range_match_pure_num:
            _start = int(_range_match_pure_num.group(1))
            _end = int(_range_match_pure_num.group(2))
            for _num in range(_start, _end + 1):
                _regex_str = f"^{_num}$"
                _translated_patterns.append(f"(?:{_regex_str})")
            continue
        # ---- hybrid processing ----------------------------------------------
        if any(_char in s for _char in "()|?+"):
            _regex_str = s
        else:
            _regex_str = fnmatch.translate(s)
        # ---------------------------------------------------------------------
        _translated_patterns.append(f"(?:{_regex_str})")
    # -------------------------------------------------------------------------
    return re.compile("|".join(_translated_patterns)) if _translated_patterns else None


async def _expand_regexp_urls(
    info_web: InfoWeb,
    session: aiohttp.ClientSession,
    search_url: str,
    exclude_url: re.Pattern | None,
    latest: bool = True,
) -> list[str]:
    """Hierarchical expansion of URL regular expressions"""
    _caller = get_caller_name()
    _regex_pattern = re.compile(r"(\[[^\]]+\]|\([^)]+\))[+*?]?")
    _current_urls = [search_url]
    # -------------------------------------------------------------------------
    while True:
        _next_urls = []
        _has_any_regex = False
        # ---------------------------------------------------------------------
        for _url in _current_urls:
            # print(f"{Color.blue}request_url:{_url}{Color.reset}")
            # -----------------------------------------------------------------
            _match_regex = _regex_pattern.search(_url)
            if not _match_regex:
                _next_urls.append(_url)
                continue
            # -----------------------------------------------------------------
            _has_any_regex = True
            _match_start = _match_regex.start()
            _match_end = _match_regex.end()
            # -----------------------------------------------------------------
            _last_slash_idx = _url[:_match_start].rfind("/")
            _match_before = _url[:_last_slash_idx] if _last_slash_idx > 0 else ""
            # -----------------------------------------------------------------
            _first_slash_idx = _url[_match_end:].find("/")
            if _first_slash_idx >= 0:
                _absolute_after_idx = _match_end + _first_slash_idx
                _match_after = _url[_absolute_after_idx:]
                _match_inside = _url[_last_slash_idx + 1 : _absolute_after_idx].strip(
                    "/"
                )
            else:
                _match_after = ""
                _match_inside = _url[_last_slash_idx + 1 :].strip("/")
            # -----------------------------------------------------------------
            _match_before = _match_before.rstrip("/")
            _match_after = _match_after.lstrip("/")
            # --- Retrieving HTML text and retrying ---------------------------
            # print(f"{Color.br_cyan}_match_before:{_match_before}{Color.reset}")
            for r in range(5):
                _web_data = await info_web.get_text(session, _match_before)
                if _web_data.status in (200, 206, 404):
                    break
                message_warn(_caller, f"retry({r}): [{_match_before}]")
                await asyncio.sleep(3)
            if _web_data.status != 200:
                message_warn(_caller, f"{_web_data.request_url}({_web_data.status})")
                continue
            # print(f"{Color.br_yellow}{_web_data.request_url}({_web_data.status}){Color.reset}")
            # -----------------------------------------------------------------
            _web_data.search_url = search_url
            _web_data.exclude_url = exclude_url
            # -----------------------------------------------------------------
            _name_pattern = re.compile(rf"^{_match_inside}$")
            _soup = BeautifulSoup(_web_data.text, "html.parser")
            # -----------------------------------------------------------------
            for a in _soup.find_all("a", href=True):
                _href = a["href"]
                # -------------------------------------------------------------
                if not _href or _href.startswith(("/", "../")):
                    continue
                # -------------------------------------------------------------
                _href_clean = _href.lstrip("./").strip("/")
                # -------------------------------------------------------------
                if exclude_url and exclude_url.search(_href_clean):
                    continue
                # -------------------------------------------------------------
                if _name_pattern.match(_href_clean):
                    _joined_url = _match_before + "/" + _href_clean
                    if _match_after or _href.endswith("/"):
                        _joined_url += "/"
                    if _match_after:
                        _joined_url += _match_after
                    _next_urls.append(_joined_url)
        # ---------------------------------------------------------------------
        # print(f"{Color.br_blue}{_next_urls}{Color.reset}")
        if latest and _next_urls:
            _next_urls.sort(key=natsort_keygen(), reverse=True)
            _next_urls = [_next_urls[0]]
        _current_urls = _next_urls
        # print(f"{Color.br_blue}{_next_urls}{Color.reset}")
        if not _has_any_regex:
            break
    # -------------------------------------------------------------------------
    return _current_urls


@debug_logger
async def get_infoweb(
    session: aiohttp.ClientSession,
    search_url: str,
    local_file: str,
    exclude_url: str = "",
) -> list[WebData]:
    """get_infoweb main control function"""
    _caller = get_caller_name()
    _info_web = InfoWeb()
    _web_datas: list[WebData] = []
    _search_pattern = re.compile(
        r"^https?://.+/(debian|ubuntu)?/dists/([^/]+)?/main/installer-([^/]+)?/current/"
        r"|"
        r"^https?://d-i\.debian.org/daily-images/([^/]+)?/daily/"
        r"|"
        r"^https?://[^/]+/cdimage/(daily-builds)/(daily)/([^/]+)?/([^/]+)?/iso-cd/"
        r"|"
        r"^https?://[^/]+/cdimage/(weekly-builds)/([^/]+)?/iso-cd/"
    )
    # --- creating an exclusion pattern ---------------------------------------
    _exclude_url = _compile_exclude_regex(exclude_url)
    # --- expanding multi-level URLs ------------------------------------------
    _resolved_urls = await _expand_regexp_urls(
        _info_web, session, search_url, _exclude_url
    )
    # --- check the header of the confirmed real URL and generate WebData -----
    for _request_url in list(set(_resolved_urls)):
        # print(f"{Color.magenta}{_request_url}{Color.reset}")
        for r in range(5):
            _web_data = await _info_web.get_header(session, _request_url)
            if _web_data.status in (200, 206, 404):
                break
            message_warn(_caller, f"retry({r}): [{_request_url}]")
            await asyncio.sleep(3)
        # ---------------------------------------------------------------------
        if _web_data.status != 200:
            message_alert(_caller, f"status({_web_data.status}): [{_request_url}]")
            continue
        # print(f"{Color.br_yellow}{_web_data.request_url}({_web_data.status}){Color.reset}")
        # ---------------------------------------------------------------------
        _web_data.search_url = search_url
        _web_data.exclude_url = exclude_url
        # ---------------------------------------------------------------------
        _path = urlparse(str(_web_data.request_url)).path
        _dirname, _basename = posixpath.split(_path)
        _file_name_path = Path(_basename) if _basename else None
        _local_file_path = Path(local_file) if local_file else None
        _match = _search_pattern.search(str(_web_data.request_url))
        _generated_filename = str(_file_name_path)
        if _match:
            if _match.group(2):
                _code = _match.group(2)
                _arch = _match.group(3)
                _generated_filename = f"mini-{_code}-{_arch}.iso"
            elif _match.group(4):
                _arch = _match.group(4)
                _generated_filename = f"mini-testing-daily-{_arch}.iso"
            elif _match.group(5):
                _edtn = f"{_match.group(5)}-{_match.group(7)}"
                _arch = _match.group(8)
                _generated_filename = str(_file_name_path).replace(
                    _arch, f"{_edtn}-{_arch}", 1
                )
            elif _match.group(9):
                _edtn = _match.group(9)
                _arch = _match.group(10)
                _generated_filename = str(_file_name_path).replace(
                    _arch, f"{_edtn}-{_arch}", 1
                )
            # print(f"_generated_filename:{_generated_filename}")
        # print(f"{Color.br_blue}{_generated_filename}{Color.reset}")
        if _generated_filename:
            _web_data.local_file = (
                str(_local_file_path.with_name(_generated_filename))
                if _local_file_path
                else ""
            )
        # ---------------------------------------------------------------------
        _web_datas.append(_web_data)
    # --- 2 step sort (newest url per regexp) ---------------------------------
    _web_datas.sort(key=lambda x: x.request_url, reverse=True)
    _web_datas.sort(key=lambda x: x.search_url)
    # -------------------------------------------------------------------------
    return _web_datas


# --- eof ---------------------------------------------------------------------
