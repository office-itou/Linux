#!/usr/bin/env python3
# encoding: utf-8

## -----------------------------------------------------------------------------
import inspect

import aiohttp                          # sudo apt-get install python3-aiohttp
from aiohttp import ClientError, ClientTimeout
import asyncio

#import functools
#from functools import partial
#from time import sleep

from urllib.parse import urlparse
#from pathlib import Path
from datetime import datetime, timezone

#import sys
#import requests

from bs4 import BeautifulSoup
from natsort import natsort_keygen
import re

#import tempfile
#import shutil
#import os

from tqdm import tqdm

from . import config
from .colors import color
from .debug  import debugout

# -----------------------------------------------------------------------------
import dataclasses
@dataclasses.dataclass
class Infoweb:
    regexp:   str = ""
    url:      str = ""
    tmstamp:  str = ""
    size:     int = 0
    check:    str = ""
    status:   int = 0
    reason:   str = ""
    contents: str = ""
    output:   str = ""

# -----------------------------------------------------------------------------
def url_strip(text):
    text = re.sub(r"^\"", "", text)
    text = re.sub(r"\"$", "", text)
    text = re.sub(r"^/", "", text)
    text = re.sub(r"/$", "", text)
    return(text)

# -----------------------------------------------------------------------------
async def get_response(target_url, response):
    info = Infoweb()
    info.url = target_url
    info.status = response.status if hasattr(response, "status") else "0"
    info.reason = response.reason if hasattr(response, "reason") else ""
    if info.status == 200:
        info.size = int(response.headers.get("Content-Length")) if response.headers.get("Content-Length") else 0
        info.tmstamp = datetime.strptime(response.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc).isoformat() if response.headers.get("Last-Modified") else ""
        info.contents = await response.text() if hasattr(response, 'text') else ""
    return info

# -----------------------------------------------------------------------------
async def get_header(session, target_url):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", f"({target_url})")
    # -------------------------------------------------------------------------
    for r in range(3):
        try:
            async with session.head(target_url, allow_redirects=True) as response:
                info = await get_response(target_url, response)
                response.raise_for_status()
                break
        except aiohttp.ClientConnectorError as e:
            print(f"{color.bg_red}Connection failed: {e}{color.reset}")
            print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except aiohttp.ClientResponseError as e:
            print(f"{color.bg_red}HTTP error status {e.status}: {e.message}{color.reset}")
            print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except aiohttp.ClientError as e:
            print(f"{color.bg_red}Aiohttp general error: {e}{color.reset}")
            print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except asyncio.TimeoutError:
            print(f"{color.bg_red}The request timed out.{color.reset}")
            print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except Exception as e:
            print(f"{color.bg_red}Exception error: {e}{color.reset}")
            raise SystemExit
        else:
            pass
        finally:
            pass
    # -------------------------------------------------------------------------
    debugout(config.debugout, color.yellow, func_name, "Complete", f"({target_url})")
    return info if info else None

# -----------------------------------------------------------------------------
async def get_text(session, target_url):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", f"({target_url})")
    # -------------------------------------------------------------------------
    for r in range(3):
        try:
            async with session.get(target_url, allow_redirects=True) as response:
                info = await get_response(target_url, response)
                response.raise_for_status()
                break
        except aiohttp.ClientConnectorError as e:
            print(f"{color.bg_red}Connection failed: {e}{color.reset}")
            print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except aiohttp.ClientResponseError as e:
            print(f"{color.bg_red}HTTP error status {e.status}: {e.message}{color.reset}")
            print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except aiohttp.ClientError as e:
            print(f"{color.bg_red}Aiohttp general error: {e}{color.reset}")
            print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except asyncio.TimeoutError:
            print(f"{color.bg_red}The request timed out.{color.reset}")
            print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
            await asyncio.sleep(1)
        except Exception as e:
            print(f"{color.bg_red}Exception error: {e}{color.reset}")
            raise SystemExit
        else:
            pass
        finally:
            pass
    # -------------------------------------------------------------------------
    debugout(config.debugout, color.yellow, func_name, "Complete", f"({target_url})")
    return info if info else None

async def get_webinfo(session, target_regexp, target_path):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", f"({target_regexp})")
    # -------------------------------------------------------------------------
    target_url = target_regexp
    match_dirs = ""
    match_ptrn = ""
    match_rear = ""
    while True:
        match = re.search(r"[^/ \t]*\[[^/ \t]+\][^/ \t]*", target_url)
        if not match:
            match = re.search(target_regexp, target_url)
            if not match:
                print(f"{color.bg_red}File not found on the web.{color.reset}")
                print(f"{color.br_yellow}regexp: [{target_regexp}]{color.reset}")
                print(f"{color.br_yellow}result: [{target_url}]{color.reset}")
                raise SystemExit
            break
        match_dirs = url_strip(target_url[0:match.start()])
        match_ptrn = url_strip(match.group())
        match_rear = url_strip(target_url[match.end():])
        if match_rear:
            match_ptrn = match_ptrn + "/"
        target_url = match_dirs
        info = await get_text(session, target_url)
        if info.status != 200:
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"# --------------------------------------------------------------------------- #")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"target_regexp:[{target_regexp}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"target_url   :[{target_url}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.regexp   :[{info.regexp}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.url      :[{info.url}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.tmstamp  :[{info.tmstamp}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.size     :[{info.size}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.check    :[{info.check}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.status   :[{info.status}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.reason   :[{info.reason}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.contents :[{info.contents}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"web.output   :[{info.output}]")
            debugout(config.debugout, color.yellow, func_name, "Debugout", f"# --------------------------------------------------------------------------- #")
            return info
        list = []
        soup = BeautifulSoup(info.contents, "html.parser")
        for a in soup.find_all('a'):
            href = a.get('href')
            if not href:
                continue
            match = re.match(f"{match_ptrn}", href)
            if not match:
                continue
            list.append(match.group())
        if not list:
            continue
        list.sort(key=natsort_keygen(), reverse=True)
        target_url = target_url + "/" + list[0]
        if match_rear:
            target_url = target_url + match_rear
    # -------------------------------------------------------------------------
    info = await get_header(session, target_url)
    info.regexp = target_regexp
    info.output = target_path
    # -------------------------------------------------------------------------
    debugout(config.debugout, color.yellow, func_name, "Complete", f"({target_url})")
    return info
