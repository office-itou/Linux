#!/usr/bin/env python3
# encoding: utf-8

## -----------------------------------------------------------------------------
import inspect

import aiohttp                          # sudo apt-get install python3-aiohttp
from aiohttp import ClientError, ClientTimeout
import asyncio

#import functools
#from functools import partial
#import time

from urllib.parse import urlparse
from pathlib import Path
from datetime import datetime, timezone

#import sys
#import requests

from bs4 import BeautifulSoup
from natsort import natsort_keygen
import re

#import tempfile
#import shutil
#import os
import pycdlib                          # sudo apt-get install python3-pycdlib

from tqdm import tqdm

from .colors import color

# -----------------------------------------------------------------------------
import dataclasses
@dataclasses.dataclass
class Info:
    class web:
        regexp:   str = ""
        path:     str = ""
        tmstamp:  str = ""
        size:     int = 0
        check:    str = ""
        status:   int = 0
        reason:   str = ""
        contents: str = ""
    class file:
        path:     str = ""
        tmstamp:  str = ""
        size:     int = 0
        volume:   str = ""

# -----------------------------------------------------------------------------
def url_strip(text):
    text = re.sub(r"^\"", "", text)
    text = re.sub(r"\"$", "", text)
    text = re.sub(r"^/", "", text)
    text = re.sub(r"/$", "", text)
    return(text)
# -----------------------------------------------------------------------------

async def get_header(target_url):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{color.white}{func_name}({target_url}) START{color.reset}")
    # -------------------------------------------------------------------------
    infoweb = Info.web()
    infoweb.path = target_url
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(timeout=timeout, raise_for_status=False) as session:
        for r in range(3):
            try:
                async with session.head(target_url, allow_redirects=True) as resp:
                    infoweb.status = resp.status if hasattr(resp, "status") else "0"
                    infoweb.reason = resp.reason if hasattr(resp, "reason") else ""
                    infoweb.size = int(resp.headers.get("Content-Length")) if resp.headers.get("Content-Length") else 0
                    infoweb.tmstamp = datetime.strptime(resp.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc).isoformat() if resp.headers.get("Last-Modified") else ""
                    infoweb.contents = await resp.text() if hasattr(resp, 'text') else ""
                    resp.raise_for_status()
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
    print(f"{color.white}{func_name}({target_url}) END{color.reset}")
    return infoweb

async def get_text(target_url):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{color.white}{func_name}({target_url}) START{color.reset}")
    # -------------------------------------------------------------------------
    infoweb = Info.web()
    infoweb.path = target_url
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(timeout=timeout, raise_for_status=False) as session:
        for r in range(3):
            try:
                async with session.get(target_url, allow_redirects=True) as resp:
                    infoweb.status = resp.status if hasattr(resp, "status") else "0"
                    infoweb.reason = resp.reason if hasattr(resp, "reason") else ""
                    infoweb.size = int(resp.headers.get("Content-Length")) if resp.headers.get("Content-Length") else 0
                    infoweb.tmstamp = datetime.strptime(resp.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc).isoformat() if resp.headers.get("Last-Modified") else ""
                    infoweb.contents = await resp.text() if hasattr(resp, 'text') else ""
                    resp.raise_for_status()
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
    print(f"{color.white}{func_name}({target_url}) END{color.reset}")
    return infoweb

async def get_webinfo(target_regexp):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{color.white}{func_name}({target_regexp}) START{color.reset}")
    # -------------------------------------------------------------------------
    target_url = target_regexp
    while True:
        match = re.search(r"[^/ \t]*\[[^/ \t]+\][^/ \t]*", target_url)
        if not match:
            break
        match_dirs = url_strip(target_url[0:match.start()])
        match_ptrn = url_strip(match.group())
        match_rear = url_strip(target_url[match.end():])
        if match_rear:
            match_ptrn = match_ptrn + "/"
        target_url = match_dirs
        infoweb = await get_text(target_url)
        if infoweb.status != 200:
            return infoweb
        list = []
        soup = BeautifulSoup(infoweb.contents, "html.parser")
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
    infoweb = await get_header(target_url)
    infoweb.regexp = target_regexp
    # -------------------------------------------------------------------------
    print(f"{color.white}{func_name}({target_url}) END{color.reset}")
    return infoweb

# -----------------------------------------------------------------------------
import subprocess

def get_volume_uuid(device):
    res = subprocess.run(['blkid', '-s', 'UUID', '-o', 'value', device], capture_output=True, text=True)
    return str(res.stdout.strip())

def get_volume_label(device):
    res = subprocess.run(['blkid', '-s', 'LABEL', '-o', 'value', device], capture_output=True, text=True)
    return str(res.stdout.strip())

# -----------------------------------------------------------------------------
def get_fileinfo(target_path):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{color.white}{func_name}({target_path}) START{color.reset}")
    # -------------------------------------------------------------------------
    infofile = Info.file()
    path = Path(target_path)
    infofile.path = path.resolve()
    if path.exists():
#       iso = pycdlib.PyCdlib()
#       iso.open(infofile.path)
#       infofile.volume  = iso.pvd.volume_identifier.decode('utf-8').strip()
#       iso.close()
        infofile.volume  = get_volume_label(infofile.path)
        infofile.tmstamp = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat()
        infofile.size    = path.stat().st_size
    else:
        print(f"{color.yellow}not exist: {target_path}{color.reset}")
    # -------------------------------------------------------------------------
    print(f"{color.white}{func_name}({target_path}) END{color.reset}")
    return infofile
