#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import asyncio
import fnmatch
import os
import re
import sys
import time
from dataclasses import dataclass, fields
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import aiohttp  # sudo apt-get install python3-aiohttp
from aiohttp import ClientTimeout
from bs4 import BeautifulSoup

# from packaging.version import InvalidVersion
# from packaging.version import parse as parse_version

# from tqdm import tqdm
# from urllib.parse import urlparse


# --- my library --------------------------------------------------------------
execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))
from common.shared.my_convert import get_text2list, put_list2text
from common.utils.my_colors import Color
from common.utils.my_debug import debug_logger
from common.utils.my_infoweb import (
    WebData,
    get_header,
    get_text,
)
from common.utils.my_message import get_caller_name, message_warn


@dataclass
class SearchData:
    enabled: str = ""
    media_type: str = ""
    architecture: str = ""
    search_url: str = ""
    exclude_url: str = ""
    target_url: str = ""
    time_stamp: str = ""
    file_size: str = ""
    check_date: str = ""
    status: str = ""
    reason: str = ""
    mime: str = ""
    contents: str = ""


class InfoSearch:
    @debug_logger
    def __init__(self, src_path: Path) -> None:
        self._valid_fields = {f.name for f in fields(SearchData)}
        self.data: list[SearchData] = []
        self.load(src_path)

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            return getattr(self.data[0], name) if self.data else ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    @debug_logger
    def load(self, src_path: Path) -> None:
        _raw_data = get_text2list(src_path)
        if _raw_data and isinstance(_raw_data[0], dict):
            self.data = [SearchData(**d) for d in _raw_data]
        else:
            self.data = [SearchData(*d) for d in _raw_data]


def _compile_exclude_regex(exclude_url: str) -> re.Pattern | None:
    """Compiling exclusion patterns"""
    if not exclude_url:
        return None
    # -------------------------------------------------------------------------
    translated_patterns = []
    for s in exclude_url.split(","):
        s = s.strip()
        if not s:
            continue
        # ---- patterns with wildcards ----------------------------------------
        range_match_with_wildcard = re.match(r"^(\d+)-(\d+)\.(.*)$", s)
        # ---- pattern with only numeric ranges ---------------------------
        range_match_pure_num = re.match(r"^(\d+)-(\d+)$", s)
        # ---------------------------------------------------------------------
        if range_match_with_wildcard:
            start = int(range_match_with_wildcard.group(1))
            end = int(range_match_with_wildcard.group(2))
            remain = range_match_with_wildcard.group(3)
            for num in range(start, end + 1):
                regex_str = fnmatch.translate(f"{num}.{remain}")
                translated_patterns.append(f"(?:{regex_str})")
            continue
        elif range_match_pure_num:
            start = int(range_match_pure_num.group(1))
            end = int(range_match_pure_num.group(2))
            for num in range(start, end + 1):
                regex_str = f"^{num}$"
                translated_patterns.append(f"(?:{regex_str})")
            continue
        # ---- hybrid processing ----------------------------------------------
        if any(char in s for char in "()|?+"):
            regex_str = s
        else:
            regex_str = fnmatch.translate(s)
        # ---------------------------------------------------------------------
        translated_patterns.append(f"(?:{regex_str})")
    # -------------------------------------------------------------------------
    return re.compile("|".join(translated_patterns)) if translated_patterns else None


async def _expand_regexp_urls(
    session: aiohttp.ClientSession, target_regexp: str, exclude_regex: re.Pattern | None
) -> list[str]:
    """Hierarchical expansion of URL regular expressions"""
    regex_pattern = re.compile(r"(\[[^\]]+\]|\([^)]+\))[+*?]?")
    current_urls = [target_regexp]
    # -------------------------------------------------------------------------
    while True:
        next_urls = []
        has_any_regex = False
        # ---------------------------------------------------------------------
        for url in current_urls:
            print(f"{Color.blue}target_url:{url}{Color.reset}")
            # -----------------------------------------------------------------
            match_regex = regex_pattern.search(url)
            if not match_regex:
                next_urls.append(url)
                continue
            # -----------------------------------------------------------------
            has_any_regex = True
            match_start = match_regex.start()
            match_end = match_regex.end()
            # -----------------------------------------------------------------
            last_slash_idx = url[:match_start].rfind("/")
            match_before = url[:last_slash_idx] if last_slash_idx > 0 else ""
            # -----------------------------------------------------------------
            first_slash_idx = url[match_end:].find("/")
            if first_slash_idx >= 0:
                absolute_after_idx = match_end + first_slash_idx
                match_after = url[absolute_after_idx:]
                match_inside = url[last_slash_idx + 1 : absolute_after_idx].strip("/")
            else:
                match_after = ""
                match_inside = url[last_slash_idx + 1 :].strip("/")
            # -----------------------------------------------------------------
            match_before = match_before.rstrip("/")
            match_after = match_after.lstrip("/")
            # --- Retrieving HTML text and retrying ---------------------------
            for r in range(5):
                web_data = await get_text(session, match_before)
                if web_data.status in (200, 404):
                    break
                message_warn(get_caller_name(), f"retry({r}): [{match_before}]")
                await asyncio.sleep(3)
            if web_data.status != 200:
                continue
            # -----------------------------------------------------------------
            name_pattern = re.compile(rf"^{match_inside}$")
            soup = BeautifulSoup(web_data.contents, "html.parser")
            # -----------------------------------------------------------------
            for a in soup.find_all("a", href=True):
                href = a["href"]
                # -------------------------------------------------------------
                if not href or href.startswith(("/", "../")):
                    continue
                # -------------------------------------------------------------
                href_clean = href.lstrip("./").strip("/")
                # -------------------------------------------------------------
                if exclude_regex and exclude_regex.search(href_clean):
                    continue
                # -------------------------------------------------------------
                if name_pattern.match(href_clean):
                    joined_url = match_before + "/" + href_clean
                    if match_after or href.endswith("/"):
                        joined_url += "/"
                    if match_after:
                        joined_url += match_after
                    next_urls.append(joined_url)
        # ---------------------------------------------------------------------
        current_urls = next_urls
        if not has_any_regex:
            break
    # -------------------------------------------------------------------------
    return current_urls


async def get_infoweb(
    session: aiohttp.ClientSession, target_regexp: str, exclude_url: str
) -> list[WebData]:
    """get_infoweb main control function"""
    infowebs: list[WebData] = []
    # --- creating an exclusion pattern ---------------------------------------
    exclude_regex = _compile_exclude_regex(exclude_url)
    # --- expanding multi-level URLs ------------------------------------------
    resolved_urls = await _expand_regexp_urls(session, target_regexp, exclude_regex)
    # --- check the header of the confirmed real URL and generate WebData -----
    for target_url in resolved_urls:
        print(f"{Color.magenta}{target_url}{Color.reset}")
        for r in range(5):
            data = await get_header(session, target_url)
            if data.status in (200, 404):
                break
            message_warn(get_caller_name(), f"retry({r}): [{target_url}]")
            await asyncio.sleep(3)
        # ---------------------------------------------------------------------
        if data.status != 200:
            print(f"{Color.red}Failed: {target_url}{Color.reset}")
            continue
        # ---------------------------------------------------------------------
        data.regexp = target_regexp if target_regexp else ""
        data.url = target_url if target_url else ""
        data.check = datetime.now(timezone.utc).isoformat(timespec="microseconds")
        infowebs.append(data)
    # --- 2 step sort (newest url per regexp) ---------------------------------
    infowebs.sort(key=lambda x: x.url, reverse=True)
    infowebs.sort(key=lambda x: x.regexp)
    # -------------------------------------------------------------------------
    return infowebs


@debug_logger
async def main():
    start = time.perf_counter()
    text_fmat = r"{enabled:<7} {media_type:<19} {architecture:<19} {search_url:<159} {exclude_url:<59} {target_url:<159} {time_stamp:<39} {file_size:<19} {check_date:<39} {status:<19} {reason:<39} {mime:<39} {contents:<127} "
    infowebs: list[WebData] = []
    result_dicts = []
    src_path = Path("./prototype/url_search.txt").resolve()
    dest_path = Path(f"{src_path}.output")
    info_srch = InfoSearch(src_path)
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(
        timeout=timeout, raise_for_status=False
    ) as session:
        for item in info_srch.data:
            if item.enabled != "o":
                result_dict = {
                    "enabled": item.enabled,
                    "media_type": item.media_type,
                    "architecture": item.architecture,
                    "search_url": item.search_url,
                    "exclude_url": item.exclude_url,
                    "target_url": item.target_url,
                    "time_stamp": item.time_stamp,
                    "file_size": item.file_size,
                    "check_date": item.check_date,
                    "status": item.status,
                    "reason": item.reason,
                    "mime": item.mime,
                    "contents": item.contents if item.contents else "-",
                }
                result_dicts.append(result_dict)
            else:
                search_url = re.sub(":_ARCH_:", item.architecture, item.search_url)
                print(f"{Color.green}{search_url}{Color.reset}")
                infowebs = await get_infoweb(
                    session, search_url, item.exclude_url.strip("-")
                )
                if not infowebs:
                    result_dict = {
                        "enabled": item.enabled,
                        "media_type": item.media_type,
                        "architecture": item.architecture,
                        "search_url": item.search_url,
                        "exclude_url": item.exclude_url,
                        "target_url": item.target_url,
                        "time_stamp": item.time_stamp,
                        "file_size": item.file_size,
                        "check_date": item.check_date,
                        "status": item.status,
                        "reason": item.reason,
                        "mime": item.mime,
                        "contents": item.contents if item.contents else "-",
                    }
                    result_dicts.append(result_dict)
                else:
                    for infoweb in infowebs:
                        target_url = infoweb.url.strip("-")
                        if target_url:
                            result_dict = {
                                "enabled": item.enabled,
                                "media_type": item.media_type,
                                "architecture": item.architecture,
                                "search_url": item.search_url,
                                "exclude_url": item.exclude_url,
                                "target_url": infoweb.url,
                                "time_stamp": infoweb.tmstamp,
                                "file_size": infoweb.size,
                                "check_date": infoweb.check,
                                "status": infoweb.status,
                                "reason": infoweb.reason,
                                "mime": infoweb.mime,
                                "contents": infoweb.contents
                                if infoweb.contents
                                else "-",
                            }
                        else:
                            result_dict = {
                                "enabled": item.enabled,
                                "media_type": item.media_type,
                                "architecture": item.architecture,
                                "search_url": item.search_url,
                                "exclude_url": item.exclude_url,
                                "target_url": item.target_url,
                                "time_stamp": item.time_stamp,
                                "file_size": item.file_size,
                                "check_date": item.check_date,
                                "status": item.status,
                                "reason": item.reason,
                                "mime": item.mime,
                                "contents": item.contents if item.contents else "-",
                            }
                        result_dicts.append(result_dict)
    put_list2text(dest_path, result_dicts, text_fmat)
    end = time.perf_counter()
    elapsed = end - start
    print(f"{Color.reset}{Color.yellow}Elapsed:{elapsed}{Color.reset}")


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
