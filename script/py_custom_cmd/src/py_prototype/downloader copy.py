#!/usr/bin/env python3
# encoding: utf-8

import os
#topdir = os.getcwd()

topdir = "/home/master/linux/script/py_custom_cmd/src"
import sys
sys.path.append(topdir)

import argparse
from pathlib import Path
import re
import inspect

#import aiofiles                         # sudo apt-get install python3-aiofiles
import aiohttp                          # sudo apt-get install python3-aiohttp
from aiohttp import ClientError, ClientTimeout
import asyncio
import tempfile
import shutil
import os

from datetime import datetime, timezone
from tqdm import tqdm

#import json
import time

# sudo apt-get install python3-pandas
#import pandas as pd

from py_common          import config
from py_common.colors   import color
from py_common.debug    import debugout

#from py_common.common_cfg       import Common_cfg
#from py_common.distribution_dat import Distribution_dat
#from py_common.media_dat        import Media_dat

from py_common.infoweb  import Infoweb, get_webinfo
from py_common.infofile import Infofile, get_fileinfo
from py_common.infodata import Infodata, debug_info, get_infodata

# -----------------------------------------------------------------------------
async def async_resume_download(target_url, target_path, mode):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")
    # -------------------------------------------------------------------------
    info = Infoweb()
    path = Path(target_path).resolve()
    overwrite = True
    generatefile = False
    if path.is_dir():
        overwrite = False
        path = Path(path, Path(target_url).name)
        base = path.stem
        count = 1
        print(path)
        print(base)
        newpath = False
        count = 1
        while path.exists():
            path = path.with_stem(f"{base}_{count}")
            count += 1
            print("gen:" + str(path))
    print(path)
    if not path.exists():
        newpath = True
    path.touch()
    generatefile = True
    if newpath == False:
        print(f"\n{color.bg_red}Failed to already same file name exist.({path}){color.reset}\n")
        raise SystemExit
    timeout = ClientTimeout(total=None, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(timeout=timeout, raise_for_status=False) as session:
        for r in range(3):
            file_size = path.stat().st_size if path.exists() and mode == "ab" else 0
            headers = {'Range': f'bytes={file_size}-'} if file_size > 0 else {}
            async with session.get(target_url, allow_redirects=True, headers=headers) as response:
                info.status = response.status if hasattr(response, "status") else "0"
                info.reason = response.reason if hasattr(response, "reason") else ""
                if hasattr(response, "headers") and hasattr(response.headers, "get"):
                    info.size = file_size + int(response.headers.get("Content-Length")) if response.headers.get("Content-Length") else 0
                    info.tmstamp = datetime.strptime(response.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc).isoformat() if response.headers.get("Last-Modified") else ""
                match info.status:
                    case 416:                                                       # Range Not Satisfiable
                        debugout(config.debugout, color.yellow, func_name, "Info", f"status: {info.status}({info.reason})")
                        debugout(config.debugout, color.yellow, func_name, "Complete", "")
                    case x if mode == "ab" and x == 200:                            # Don't support partial content.
                        info = await async_resume_download(target_url, target_path, "wb")
                        debugout(config.debugout, color.yellow, func_name, "Info", f"status: {info.status}({info.reason})")
                        debugout(config.debugout, color.yellow, func_name, "Complete", "")
                    case x if (mode == "ab" and x == 206) or x == 200:              # Partial Content
                        try:
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
                                info.status = response.status if hasattr(response, "status") else "0"
                                info.reason = response.reason if hasattr(response, "reason") else ""
                                if hasattr(response, "headers") and hasattr(response.headers, "get"):
                                    info.size = file_size + int(response.headers.get("Content-Length")) if response.headers.get("Content-Length") else 0
                                    info.tmstamp = datetime.strptime(response.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc).isoformat() if response.headers.get("Last-Modified") else ""
                                    mtime = datetime.fromisoformat(info.tmstamp).timestamp()
                                    atime = datetime.now(tz=timezone.utc).timestamp()
#                                   if overwrite == False and path.exists():
#                                       print(f"\n{color.bg_red}Failed to already same file name exist.({path}){color.reset}\n")
#                                       raise SystemExit
                                    with open(tmp.name, 'rb') as src, open(path, mode) as dst:
                                        shutil.copyfileobj(src, dst)
                                        os.utime(path, (atime, mtime))
                                        if path.stat().st_size != path.stat().st_size:
                                            print(f"\n{color.bg_red}Failed to copy from the temporary file.({path}){color.reset}\n")
                                            raise SystemExit
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
                        except KeyboardInterrupt:
                            if generatefile == True and path.exists() and path.stat().st_size == 0:
                                info.status = ""
                            break
                        else:
                            pass
                        finally:
                            print(info)
                            if generatefile == True and (isinstance(info.status, int) or not 200 <= info.status <= 299) and path.exists() and path.stat().st_size == 0:
                                print(f"remove:{path}")
                                path.unlink()
                            pass
                    case _:
                        pass

    # -------------------------------------------------------------------------
    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    return info

# -----------------------------------------------------------------------------
async def main():
    start = time.perf_counter()
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", "")

    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug', help='Debug mode', action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    args = parser.parse_args()
    config.debug = args.debug
    config.debugout = args.debugout
    if config.debug == True:
        config.debugout = True

    debugout(config.debugout, color.yellow, func_name, "info", "Debug mode on")

    if os.geteuid() != 0:
        print(f"{color.br_yellow}You have standard user privileges. Please run this with sudo.{color.reset}")
        exit(1)
    # -------------------------------------------------------------------------
    mode        = "ab"

    list = [
        {   "url":"https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso",
            "path":"./debian-testing-amd64-DVD-1.iso"},
        {   "url":"https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso",
            "path":"./debian-testing-amd64-DVD-1.iso"},
        {   "url":"https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso",
            "path":"./debian-testing-amd64-netinst.iso"},
        {   "url":"https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso",
            "path":"./debian-testing-amd64-netinst.iso"},
        {   "url":"https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso",
            "path":"./mini-bullseye-amd64.iso"},
        {   "url":"https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso",
            "path":"./mini-bullseye-amd64.iso"}
    ]

#   infoweb = await async_resume_download(target_url, target_path, mode)
#   print(infoweb.status, infoweb.reason, infoweb.size, infoweb.tmstamp, target_path)

    tasks = []
    for line in list:
        tasks.append(async_resume_download(line["url"], "./", "wb"))
    infos = await asyncio.gather(*tasks)
    for info in infos:
        print(info.status, info.reason, info.size, info.tmstamp, info.path)
    # -------------------------------------------------------------------------
    debugout(config.debugout, color.yellow, func_name, "Complete", "")
    end = time.perf_counter()
    elapsed = end - start
    print(f"elapsed time: {elapsed:.4f} 秒")
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    asyncio.run(main())
