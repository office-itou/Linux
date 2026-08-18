#!/usr/bin/env python3
# encoding: utf-8

from pathlib import Path
import tempfile
import requests
import shutil
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
import os
from tqdm import tqdm

url = "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso"
url = "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.6.0-amd64-netinst.iso"
dirname = Path.cwd()
filename = Path(url).name
dst = Path(dirname, filename)

print("url:" + url)
print("dst:" + dst.name)

terminal_size = shutil.get_terminal_size()

response = requests.get(url, stream=True)
total_size = int(response.headers.get("content-length", 0))

l_bar='{l_bar}'
r_bar='{r_bar}'
bar='{bar:a}'
bar_format = f"{l_bar}{bar}{r_bar}"
print(bar_format)
chunk_size=1024**2

with tempfile.NamedTemporaryFile(delete=True) as tmp, tqdm(
    desc=filename,
    total=total_size,
    unit="iB",
    unit_scale=True,
    unit_divisor=1024,
    leave=False,
    colour='CYAN',
    bar_format=bar_format,
    ncols=terminal_size.columns,
    dynamic_ncols=False
) as bar:
    for chunk in response.iter_content(chunk_size=chunk_size):
        size = tmp.write(chunk)
        bar.update(size)
    print(f"\nstatus_code: {response.status_code} ({response.reason})")
    if response.status_code == 200:
        fsize = int(response.headers.get("Content-Length"))
        ltime = datetime.strptime(response.headers.get("Last-Modified"), '%a, %d %b %Y %H:%M:%S %Z')
        ltime = ltime.replace(tzinfo=timezone.utc)
        nowdt = datetime.now()
        print(f"Ltime: {response.headers.get("Last-Modified")}")
        print(f"fsize: {fsize}")
        print(f"ltime: {ltime}")
        print(f"nowdt: {nowdt}")
        atime = nowdt.timestamp()
        mtime = ltime.timestamp()
        shutil.copy(tmp.name, dst)
        os.utime(dst.name, (atime, mtime))
