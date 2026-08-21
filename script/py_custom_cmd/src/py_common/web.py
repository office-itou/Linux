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
import re
from urllib.parse import urlparse
from pathlib import Path
from datetime import datetime, timezone
#import sys
#import requests
from bs4 import BeautifulSoup
from natsort import natsort_keygen
import tempfile
import shutil
import os
from tqdm import tqdm

from py_common.color import Color_code
color = Color_code()

# -----------------------------------------------------------------------------
class webinfo:
    def __init__(self):
        self.data = dict()
    def get(self, key):
        return self.data.get(key, "")
    def set(self, key, value):
        self.data[key] = value

# -----------------------------------------------------------------------------
def url_strip(text):
    text = re.sub(r"^\"", "", text)
    text = re.sub(r"\"$", "", text)
    text = re.sub(r"^/", "", text)
    text = re.sub(r"/$", "", text)
    return(text)

def get_url2path(url, *args):
    parse = urlparse(url)
    dirname  = str(Path.cwd())
    filename = Path(parse.path).name
    if 'args[0]' in locals():
        dirname = str(args[0])
    if 'args[1]' in locals():
        filename = str(args[1])
    path = Path(dirname, filename)
    return path

async def set_webinfo(wi, url, path, response):
    wi.set("url"     , url)
    wi.set("urldir"  , re.sub(r"/[^/]+$", "", url))
    wi.set("path"    , path)
    wi.set("currdir" , str(Path.cwd()))
    wi.set("dirname" , str(Path(path).parent))
    wi.set("filename", Path(path).name)
    wi.set("status"  , response.status)
    wi.set("message" , response.reason)
    if response.headers.get("Content-Length"):
        wi.set("size"    , int(response.headers.get("Content-Length")))
    if response.headers.get("Last-Modified"):
        wi.set("date"    , datetime.strftime(datetime.strptime(response.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc), "%Y/%m/%d %H:%M:%S %Z"))
    if hasattr(response, 'text'):
        wi.set("text"    , await response.text())
    return wi

# -----------------------------------------------------------------------------
async def get_header(url, *args):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({url}) START")
    # -------------------------------------------------------------------------
    wi = webinfo()
    path = get_url2path(url, *args)
    # -------------------------------------------------------------------------
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    for r in range(3):
        try:
            async with aiohttp.ClientSession(raise_for_status=False, timeout=timeout) as session:
                async with session.head(url, allow_redirects=True) as response:
                    wi = await set_webinfo(wi, url, path, response)
                    response.raise_for_status() 
                    break
        except:
            print(f"{color.code['yellow']}retry({r}): {url}{color.code['reset']}")
            await asyncio.sleep(1)
        else:
            pass
        finally:
            pass
    # -------------------------------------------------------------------------
    print(f"{func_name}({url}) END")
    return wi

# -----------------------------------------------------------------------------
async def get_text(url, *args):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({url}) START")
    # -------------------------------------------------------------------------
    wi = webinfo()
    path = get_url2path(url, *args)
    # -------------------------------------------------------------------------
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    for r in range(3):
        try:
            async with aiohttp.ClientSession(raise_for_status=False, timeout=timeout) as session:
                async with session.get(url, allow_redirects=True) as response:
                    wi = await set_webinfo(wi, url, path, response)
                    response.raise_for_status() 
                    break
        except:
            print(f"{color.code['yellow']}retry({r}): {url}{color.code['reset']}")
            await asyncio.sleep(1)
        else:
            pass
        finally:
            pass
    # -------------------------------------------------------------------------
    print(f"{func_name}({url}) END")
    return wi

# -----------------------------------------------------------------------------
async def get_info(url):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({url}) START")
    # -------------------------------------------------------------------------
    while True:
        match = re.search(r"[^/ \t]*\[[^/ \t]+\][^/ \t]*", url)
        if not match:
            break
        match_dirs = url_strip(url[0:match.start()])
        match_ptrn = url_strip(match.group())
        match_rear = url_strip(url[match.end():])
        if match_rear:
            match_ptrn = match_ptrn + "/"
        url = match_dirs
        wi = await get_text(url)
        if wi.get("status") != 200:
            return wi
        list = []
        soup = BeautifulSoup(wi.get("text"), "html.parser")
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
        url = url + "/" + list[0]
        if match_rear:
            url = url + match_rear
    # -------------------------------------------------------------------------
    print(f"{func_name}({url}) END")
    return await get_header(url)

async def download(url, *args):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({url}) START")
    wi = webinfo()
    wi.set("url", url)
    wi.set("dirname", Path(url).parent)
    wi.set("filename", Path(url).name)
    path = Path(Path.cwd(), Path(url).name)
    if args:
        path = Path(args[0], Path(url).name)
    wi.set("path", path)
    print(f"url: {url}")
    print(f"path: {path}")
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    for r in range(3):
        try:
            async with aiohttp.ClientSession(raise_for_status=False, timeout=timeout) as session:
                async with session.get(url, allow_redirects=True) as response:
                    print(f"status: {response.status}")
                    print(f"reason: {response.reason}")
                    wi.set("status", response.status)
                    wi.set("message", response.reason)
                    response.raise_for_status() 
                    if response.status == 200:
                        async with tempfile.NamedTemporaryFile(delete=True) as tmp, tqdm(
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
                            async for chunk in response.iter_content(chunk_size=(1024**2)):
                                size = await tmp.write(chunk)
                                await bar.update(size)
                            print(f"status: {response.status}")
                            print(f"reason: {response.reason}")
                            wi.set("status", response.status)
                            wi.set("message", response.reason)
                            response.raise_for_status() 
                            if response.status == 200:
                                if response.headers.get("Content-Length"):
                                    wi.set("size", int(response.headers.get("Content-Length")))
                                if response.headers.get("Last-Modified"):
                                    wi.set("date", datetime.strptime(response.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc))
                                nowdt = datetime.now(tz=timezone.utc)
                                atime = nowdt.timestamp()
                                mtime = wi.get("date").timestamp()
                                shutil.copy(tmp.name, path)
                                os.utime(path, (atime, mtime))
                                break
        except:
            print(f"{color.code['yellow']}{url}: retry({r}){color.code['reset']}")
            await asyncio.sleep(1)
        else:
            pass
        finally:
            pass
    print(f"{func_name}({url}) END")
    return wi
