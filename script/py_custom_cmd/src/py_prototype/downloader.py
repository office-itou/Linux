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

from py_common.my_config   import debug_flag, debugout_flag
from py_common.my_colors   import color
from py_common.my_debug    import debugout

#from py_common.my_common_cfg       import Common_cfg
#from py_common.my_distribution_dat import Distribution_dat
#from py_common.my_media_dat        import Media_dat

from py_common.my_infoweb  import Infoweb, get_webinfo
from py_common.my_infofile import Infofile, get_fileinfo
from py_common.my_infodata import Infodata, debug_info, get_infodata

async def get_response(response, target_url, target_path, info, file_size):
#   info.regexp   = ""
    info.url      = target_url
    info.tmstamp  = datetime.strptime(response.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z').replace(tzinfo=timezone.utc).isoformat() if response.headers.get("Last-Modified") else ""
    info.size     = file_size + int(response.headers.get("Content-Length"), 0) if response.headers.get("Content-Length") else 0
    info.status   = response.status if hasattr(response, "status") else "0"
    info.reason   = response.reason if hasattr(response, "reason") else ""
    content_type = response.headers.get("Content-Type", "")
    if "text" in content_type or "json" in content_type:
        info.contents = await response.text() if hasattr(response, 'text') else ""
        print(f"info.contents: [{info.contents}]")
    info.output   = target_path
    return info

# -----------------------------------------------------------------------------
async def async_resume_download(target_url, target_path, mode, keep=False):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", f"{target_url}")
#   debugout(debugout_flag, color.yellow, func_name, "Info", f"url   : {target_url}")
#   debugout(debugout_flag, color.yellow, func_name, "Info", f"path  : {target_path}")
    # -------------------------------------------------------------------------
    user_break = False
    info = Infoweb()
    path = Path(target_path).resolve() if not Path(target_path).is_dir() else Path(target_path, Path(target_url).name).resolve()
    if not path.parent.exists(): path.parent.mkdir()
    # -------------------------------------------------------------------------
    if mode != "ab" and Path(target_path).is_dir():
        base = path.stem
        count = 1
        while path.exists():
            path = path.with_stem(f"{base}_{count}")
            count += 1
        debugout(debugout_flag, color.yellow, func_name, "Info", f"new filename: {path}")
    if not path.exists(): path.touch()
    # -------------------------------------------------------------------------
    timeout = ClientTimeout(total=None, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(timeout=timeout, raise_for_status=False) as session:
        for r in range(3):
            file_size = path.stat().st_size if path.exists() and mode == "ab" else 0
            headers = {'Range': f'bytes={file_size}-'} if file_size > 0 else {}
            async with session.get(target_url, allow_redirects=True, headers=headers) as response:
                info = await get_response(response, target_url, path, info, file_size)
                match info.status:
                    case 416:                                                       # Range Not Satisfiable
                        debugout(debugout_flag, color.yellow, func_name, "Info", f"status: {info.status}({info.reason})")
#                       debugout(debugout_flag, color.yellow, func_name, "Info", f"url   : {target_url}")
#                       debugout(debugout_flag, color.yellow, func_name, "Info", f"path  : {path}")
#                       debugout(debugout_flag, color.yellow, func_name, "Complete", "")
                        break
                    case x if mode == "ab" and x == 200:                            # Don't support partial content.
                        info = await async_resume_download(target_url, path, "wb")
                        debugout(debugout_flag, color.yellow, func_name, "Info", f"status: {info.status}({info.reason})")
#                       debugout(debugout_flag, color.yellow, func_name, "Info", f"url   : {target_url}")
#                       debugout(debugout_flag, color.yellow, func_name, "Info", f"path  : {path}")
#                       debugout(debugout_flag, color.yellow, func_name, "Complete", "")
                        break
                    case x if (mode == "ab" and x == 206) or x == 200:              # Partial Content
                        try:
                            with open(path, mode) as f, tqdm(
                                desc=Path(info.output).name,
                                total=info.size,
                                unit="iB",
                                unit_scale=True,
                                unit_divisor=1024,
                                leave=True,
                                colour='CYAN',
                                bar_format='{l_bar}{bar:a}{r_bar}',
                                dynamic_ncols=False
                            ) as bar:
                                async for chunk in response.content.iter_chunked(1024**2):
                                    size = f.write(chunk)
                                    bar.update(size)
                                response.raise_for_status()
                                info = await get_response(response, target_url, path, info, file_size)
                                mtime = datetime.fromisoformat(info.tmstamp).timestamp()
                                atime = datetime.now(tz=timezone.utc).timestamp()
                                os.utime(path, (atime, mtime))
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
                            user_break = True
                            break
                        else:
                            pass
                        finally:
                            print(info)
                            if keep == False and user_break == True and path.exists():
                                print(f"remove:{path}")
                                path.unlink()
                            pass
                    case _:
                        pass
    debugout(debugout_flag, color.yellow, func_name, "Info", f"status: {info.status}({info.reason})")
    debugout(debugout_flag, color.yellow, func_name, "Info", f"url   : {info.url}")
    debugout(debugout_flag, color.yellow, func_name, "Info", f"path  : {info.output}")
    debugout(debugout_flag, color.yellow, func_name, "Complete", "")

    # -------------------------------------------------------------------------
    debugout(debugout_flag, color.yellow, func_name, "Complete", f"{target_url}")
#   debugout(debugout_flag, color.yellow, func_name, "Info", f"url   : {target_url}")
#   debugout(debugout_flag, color.yellow, func_name, "Info", f"path  : {path}")
    return info

# -----------------------------------------------------------------------------
async def main():
    start = time.perf_counter()
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", "")

    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument('--debug', help='Debug mode', action='store_true')
    parser.add_argument('--debugout', help='Debug mode for display only', action='store_true')
    args = parser.parse_args()
    debug_flag = args.debug
    debugout_flag = args.debugout
    if debug_flag == True:
        debugout_flag = True

    debugout(debugout_flag, color.yellow, func_name, "info", "Debug mode on")

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
        tasks.append(async_resume_download(line["url"], "./", "ab"))
    infos = await asyncio.gather(*tasks)
    for info in infos:
        print(info.status, info.reason, info.size, info.tmstamp, info.output)
    # -------------------------------------------------------------------------
    debugout(debugout_flag, color.yellow, func_name, "Complete", "")
    end = time.perf_counter()
    elapsed = end - start
    print(f"elapsed time: {elapsed:.4f} 秒")
# -----------------------------------------------------------------------------

if __name__ == "__main__":
    asyncio.run(main())
