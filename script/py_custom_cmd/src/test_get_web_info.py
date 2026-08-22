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

import asyncio

from py_common.colors import color
from py_common.web import Info, get_fileinfo, get_webinfo

# -----------------------------------------------------------------------------
async def sub_get_info(urls):
    info = Info()
#   info.web  = await get_webinfo(target_regexp)
#   info.file = get_fileinfo(target_path)

    tasks = [get_webinfo(url) for url in urls]
    result = await asyncio.gather(*tasks)
    for info.web in result:
        if True:
            print(f"{color.yellow}# --------------------------------------------------------------------------- #{color.reset}")
            print(f"info.web.regexp  : [{info.web.regexp}]")
            print(f"info.web.path    : [{info.web.path}]")
            print(f"info.web.tmstamp : [{info.web.tmstamp}]")
            print(f"info.web.size    : [{info.web.size}]")
            print(f"info.web.check   : [{info.web.check}]")
            print(f"info.web.status  : [{info.web.status}]")
            print(f"info.web.reason  : [{info.web.reason}]")
            print(f"info.web.contents: [{info.web.contents}]") if info.web.status == 200 else print(f"info.web.contents: []")
            print(f"{color.yellow}# --------------------------------------------------------------------------- #{color.reset}")
        if False:
            print(f"info.file.path   : [{info.file.path}]")
            print(f"info.file.tmstamp: [{info.file.tmstamp}]")
            print(f"info.file.size   : [{info.file.size}]")
            print(f"info.file.volume : [{info.file.volume}]")

# -----------------------------------------------------------------------------
async def main():
    await sub_get_info(urls)

if __name__ == "__main__":
    asyncio.run(main())
