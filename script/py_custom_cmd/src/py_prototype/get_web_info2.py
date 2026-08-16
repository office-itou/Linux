#!/usr/bin/env python3
# encoding: utf-8

import inspect
import asyncio
import requests
from functools import partial
import datetime
import re
import sys
import time

urls = [
    "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/duke/main/installer-amd64/current/images/netboot/mini.iso",
    "https://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/netboot/mini.iso",
    "https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso",
    "https://cdimage.debian.org/cdimage/archive/11.[0-9.]*/amd64/iso-cd/debian-11.[0-9.]*-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/12.[0-9.]*/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.[0-9.]*-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-cd/debian-testing-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/11.[0-9.]*/amd64/iso-dvd/debian-11.[0-9.]*-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/12.[0-9.]*/amd64/iso-dvd/debian-12.[0-9.]*-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-13.[0-9.]*-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso",
    "https://cdimage.debian.org/cdimage/archive/11.[0-9.]*-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/11.[0-9.]*-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/11.[0-9.]*-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/11.[0-9.]*-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/archive/12.[0-9.]*-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/archive/12.[0-9.]*-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/archive/12.[0-9.]*-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/archive/12.[0-9.]*-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.[0-9.]*-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.[0-9.]*-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.[0-9.]*-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-13.[0-9.]*-amd64-standard.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-cinnamon.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-gnome.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso",
    "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-standard.iso",
    "https://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso",
    "https://releases.ubuntu.com/20.04/ubuntu-20.04[0-9.]*-live-server-amd64.iso",
    "https://releases.ubuntu.com/22.04/ubuntu-22.04[0-9.]*-live-server-amd64.iso",
    "https://releases.ubuntu.com/24.04/ubuntu-24.04[0-9.]*-live-server-amd64.iso",
    "https://releases.ubuntu.com/24.10/ubuntu-24.10[0-9.]*-live-server-amd64.iso",
    "https://releases.ubuntu.com/25.04/ubuntu-25.04[0-9.]*-live-server-amd64.iso",
    "https://releases.ubuntu.com/25.10/ubuntu-25.10[0-9.]*-live-server-amd64.iso",
    "https://releases.ubuntu.com/26.04/ubuntu-26.04[0-9.]*-live-server-amd64.iso",
    "https://cdimage.ubuntu.com/ubuntu-server/stonking/daily-live/current/stonking-live-server-amd64.iso",
    "https://releases.ubuntu.com/20.04/ubuntu-20.04[0-9.]*-desktop-amd64.iso",
    "https://releases.ubuntu.com/22.04/ubuntu-22.04[0-9.]*-desktop-amd64.iso",
    "https://releases.ubuntu.com/24.04/ubuntu-24.04[0-9.]*-desktop-amd64.iso",
    "https://releases.ubuntu.com/24.10/ubuntu-24.10[0-9.]*-desktop-amd64.iso",
    "https://releases.ubuntu.com/25.04/ubuntu-25.04[0-9.]*-desktop-amd64.iso",
    "https://releases.ubuntu.com/25.10/ubuntu-25.10[0-9.]*-desktop-amd64.iso",
    "https://releases.ubuntu.com/26.04/ubuntu-26.04[0-9.]*-desktop-amd64.iso",
    "https://cdimage.ubuntu.com/ubuntu/stonking/daily-live/current/stonking-desktop-amd64.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-netinst-x86_64-40-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-netinst-x86_64-42-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-netinst-x86_64-43-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-netinst-x86_64-44-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-dvd-x86_64-40-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Server/x86_64/iso/Fedora-Server-dvd-x86_64-42-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-dvd-x86_64-43-[0-9.]*.iso",
    "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-dvd-x86_64-44-[0-9.]*.iso",
    "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso",
    "https://mirror.stream.centos.org/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso",
    "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso",
    "https://mirror.stream.centos.org/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso",
    "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso",
    "https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10-latest-x86_64-boot.iso",
    "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso",
    "https://repo.almalinux.org/almalinux/10/isos/x86_64/AlmaLinux-10-latest-x86_64-dvd.iso",
    "https://repo.almalinux.org/almalinux/10/live/x86_64/AlmaLinux-10-latest-x86_64-Live-GNOME.iso",
    "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-boot.iso",
    "https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10-latest-x86_64-boot.iso",
    "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-dvd.iso",
    "https://download.rockylinux.org/pub/rocky/10/isos/x86_64/Rocky-10-latest-x86_64-dvd.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.6-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-minimal-x86_64.iso",
    "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.6-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso",
    "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Media.iso",
    "https://download.opensuse.org/distribution/leap/16.0/offline/Leap-16.0-online-installer-x86_64.install.iso",
    "https://download.opensuse.org/distribution/leap/16.1/offline/Leap-16.1-online-installer-x86_64.install.iso",
    "https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso",
    "https://download.opensuse.org/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso",
    "https://download.opensuse.org/distribution/leap/16.0/offline/Leap-16.0-offline-installer-x86_64.install.iso",
    "https://download.opensuse.org/distribution/leap/16.1/offline/Leap-16.1-offline-installer-x86_64.install.iso",
    "https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso",
    "https://www.memtest.org/download/v8.00/mt86plus_8.00_x86_64.grub.iso.zip",
    "https://www.memtest.org/download/v8.10/mt86plus_8.10_x86_64.grub.iso.zip"
]

def url_strip(text):
    text = re.sub(r"^\"", "", text)
    text = re.sub(r"\"$", "", text)
    text = re.sub(r"^/", "", text)
    text = re.sub(r"/$", "", text)
    return(text)

def version_key(v):
    v = re.sub(r"^[^0-9]*([0-9.]+).*$", r"\1", v)
    return [int(x) for x in v.split(".")]

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Connection": "close",
}

async def getsize(url):
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}({url}) START")
    while True:
        match = re.search(r"[^/ \t]*\[[^/ \t]+\][^/ \t]*", url)
        if not match:
            break
        # === get directory and file name =====================================
        match_dirs = url_strip(url[0:match.start()])
        match_ptrn = url_strip(match.group())
        match_rear = url_strip(url[match.end():])
        url = match_dirs + "/"
        # --- request ---------------------------------------------------------
        loop = asyncio.get_event_loop()
        func = partial(requests.get, url, allow_redirects=True, headers=headers, timeout=(10.0, 30.0))
        response = await loop.run_in_executor(None, func)
        stat_code = int(response.status_code)
        stat_mesg = response.reason
        # --- error detection -------------------------------------------------
        if stat_code < 200 or stat_code > 299:
            file_date = "-"
            file_size = 0
            print(f"{func_name}({url}) ERROR")
            return f"{url},\"{file_date}\",{file_size},{stat_code},\"{stat_mesg}\""
        # --- pattern matching ------------------------------------------------
        result = re.findall(r'<a href="' + match_ptrn + r'/*"[^>]*>', response.text)
        list = []
        for text in result:
            match = re.search(match_ptrn, text)
            text = url_strip(match.group())
            list.append(text)
        list.sort(key=version_key, reverse=True)
        url = url + list[0]
        if match_rear:
            url = url + "/" + match_rear
    # === get file information ================================================
    # --- request -------------------------------------------------------------
    loop = asyncio.get_event_loop()
    func = partial(requests.head, url, allow_redirects=True, headers=headers, timeout=(10.0, 30.0))
    response = await loop.run_in_executor(None, func)
    stat_code = int(response.status_code)
    stat_mesg = response.reason
        # --- error detection -------------------------------------------------
    if stat_code < 200 or stat_code > 299:
        file_date = "-"
        file_size = 0
    else:
        file_size = int(response.headers.get("Content-Length"))
        file_date = datetime.datetime.strptime(response.headers.get("Last-Modified"), "%a, %d %b %Y %H:%M:%S GMT")
    print(f"{func_name}({url}) END")
    return f"{url},\"{file_date}\",{file_size},{stat_code},\"{stat_mesg}\""

async def main():
    func_name = inspect.currentframe().f_code.co_name
    print(f"{func_name}() START")
    tasks = [asyncio.create_task(getsize(url)) for url in urls]
    results = await asyncio.gather(*tasks)
    print("result: ", results)
    print(f"{func_name}() END")

if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())
