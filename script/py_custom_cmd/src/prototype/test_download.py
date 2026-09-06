#!/usr/bin/env python3
# encoding: utf-8

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

urls = [
    "https://cdimage.debian.org/cdimage/archive/11.[0-9.]*/amd64/iso-cd/debian-11.[0-9.]*-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/archive/12.[0-9.]*/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-13.[0-9.]*-amd64-netinst.iso",
    "https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso"
]

import asyncio

from py_common.web import get_header, get_text, get_info, download

async def sub_get_info(urls):
    list = []
    tasks = [get_info(url) for url in urls]
    wis = await asyncio.gather(*tasks)
    for wi in wis:
        if False:
            print(f"url     : [{wi.get('url')}]")
            print(f"urldir  : [{wi.get('urldir')}]")
            print(f"status  : [{wi.get('status')}]")
            print(f"message : [{wi.get('message')}]")
            print(f"path    : [{wi.get('path')}]")
            print(f"dirname : [{wi.get('dirname')}]")
            print(f"filename: [{wi.get('filename')}]")
            print(f"size    : [{wi.get('size')}]")
            print(f"date    : [{wi.get('date')}]")
        list.append(wi.get('url'))
    return list

async def sub_get_header(urls):
    tasks = [get_header(url) for url in urls]
    wis = await asyncio.gather(*tasks)
    for wi in wis:
        if False:
            print(f"url     : [{wi.get('url')}]")
            print(f"urldir  : [{wi.get('urldir')}]")
            print(f"status  : [{wi.get('status')}]")
            print(f"message : [{wi.get('message')}]")
            print(f"path    : [{wi.get('path')}]")
            print(f"dirname : [{wi.get('dirname')}]")
            print(f"filename: [{wi.get('filename')}]")
            print(f"size    : [{wi.get('size')}]")
            print(f"date    : [{wi.get('date')}]")
            print(f"text    : [{wi.get('text'):80}]")

async def sub_get_text(urls):
    tasks = [get_text(url) for url in urls]
    wis = await asyncio.gather(*tasks)
    for wi in wis:
        if True:
            print(f"url     : [{wi.get('url')}]")
            print(f"urldir  : [{wi.get('urldir')}]")
            print(f"status  : [{wi.get('status')}]")
            print(f"message : [{wi.get('message')}]")
            print(f"path    : [{wi.get('path')}]")
            print(f"dirname : [{wi.get('dirname')}]")
            print(f"filename: [{wi.get('filename')}]")
            print(f"size    : [{wi.get('size')}]")
            print(f"date    : [{wi.get('date')}]")
            print(f"text    : [{wi.get('text'):80}]")

async def sub_download(urls):
    sem = asyncio.Semaphore(2)
    list = []
    tasks = [download(url) for url in urls]
    wis = await asyncio.gather(*tasks)
    for wi in wis:
        if True:
            print(f"url     : [{wi.get('url')}]")
            print(f"urldir  : [{wi.get('urldir')}]")
            print(f"status  : [{wi.get('status')}]")
            print(f"message : [{wi.get('message')}]")
            print(f"path    : [{wi.get('path')}]")
            print(f"dirname : [{wi.get('dirname')}]")
            print(f"filename: [{wi.get('filename')}]")
            print(f"size    : [{wi.get('size')}]")
            print(f"date    : [{wi.get('date')}]")
        list.append(wi.get('url'))
    return list

# -----------------------------------------------------------------------------
async def main():
    list = await sub_get_info(urls)
    await sub_download(list)

if __name__ == "__main__":
    asyncio.run(main())
