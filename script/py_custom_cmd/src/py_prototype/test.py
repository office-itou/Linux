#!/usr/bin/env python3
# encoding: utf-8

topdir = "/home/master/linux/script/py_custom_cmd/src"
#import os
import sys
sys.path.append(topdir) # (os.getcwd())

import pathlib
from pathlib import Path
from urllib.parse import urlparse
from datetime import datetime, timezone
import re
import sys
import pycdlib                          # sudo apt-get install python3-pycdlib

import inspect
import aiohttp                          # sudo apt-get install python3-aiohttp
from aiohttp import ClientError, ClientTimeout
import asyncio

from bs4 import BeautifulSoup
from natsort import natsort_keygen

from py_common.colors import color

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
                print(f"Connection failed: {e}")
                print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
                await asyncio.sleep(1)
            except aiohttp.ClientResponseError as e:
                print(f"HTTP error status {e.status}: {e.message}")
                print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
                await asyncio.sleep(1)
            except aiohttp.ClientError as e:
                print(f"Aiohttp general error: {e}")
                print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
                await asyncio.sleep(1)
            except asyncio.TimeoutError:
                print("The request timed out.")
                print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
                await asyncio.sleep(1)
            except Exception as e:
                print(f"Exception error: {e}")
                raise
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
                print(f"Connection failed: {e}")
                print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
                await asyncio.sleep(1)
            except aiohttp.ClientResponseError as e:
                print(f"HTTP error status {e.status}: {e.message}")
                print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
                await asyncio.sleep(1)
            except aiohttp.ClientError as e:
                print(f"Aiohttp general error: {e}")
                print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
                await asyncio.sleep(1)
            except asyncio.TimeoutError:
                print("The request timed out.")
                print(f"{color.yellow}retry({r}): {target_url}{color.reset}")
                await asyncio.sleep(1)
            except Exception as e:
                print(f"Exception error: {e}")
                raise
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

def get_fileinfo(target_path):
    infofile = Info.file()
    path = Path(target_path)
    infofile.path = path.resolve()
    if path.exists():
        iso = pycdlib.PyCdlib()
        iso.open(infofile.path)
        infofile.volume = iso.pvd.volume_identifier.decode('utf-8').strip()
        iso.close()
        infofile.tmstamp = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat()
        infofile.size   = path.stat().st_size
    return infofile

async def main():
    target_regexp = "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.[0-9.]*-amd64-netinst.iso"
    target_path = "/srv/user/share/isos/linux/debian/debian-13.6.0-amd64-netinst.iso"
#    target_regexp = "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso"
#    target_path   = "/srv/user/share/isos/linux/debian/mini-trixie-amd64.iso"

    info = Info()
    info.web  = await get_webinfo(target_regexp)
    info.file = get_fileinfo(target_path)

    print(f"web.regexp  : [{info.web.regexp}]")
    print(f"web.path    : [{info.web.path}]")
    print(f"web.tmstamp : [{info.web.tmstamp}]")
    print(f"web.size    : [{info.web.size}]")
    print(f"web.check   : [{info.web.check}]")
    print(f"web.status  : [{info.web.status}]")
    print(f"web.reason  : [{info.web.reason}]")
    print(f"web.contents: [{info.web.contents}]")
    print(f"file.path   : [{info.file.path}]")
    print(f"file.tmstamp: [{info.file.tmstamp}]")
    print(f"file.size   : [{info.file.size}]")
    print(f"file.volume : [{info.file.volume}]")

    sys.exit(0)


if __name__ == "__main__":
    asyncio.run(main())
