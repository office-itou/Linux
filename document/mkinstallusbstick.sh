#!/bin/bash
# *****************************************************************************
# Unattended installation USB stick for multiple ISO files. (GPT NTFS Ver.)
# -----------------------------------------------------------------------------
#   Debian 12    : testing      (bookworm) : debian-testing-amd64-netinst.iso        : 6.1.0-7-amd64
#   Debian 11    : stable       (bullseye) : debian-11.6.0-amd64-netinst.iso         : 5.10.0-20-amd64
#   Debian 10    : oldstable    (buster)   : debian-10.13.0-amd64-netinst.iso        : 4.19.0-21-amd64
#   Debian  9    : oldoldstable (stretch)  : debian-9.13.0-amd64-netinst.iso         : 4.9.0-13-amd64
#   Ubuntu 23.04 : Lunar Lobster           : ubuntu-23.04-live-server-amd64.iso      : 6.2.0-18-generic
#   Ubuntu 22.10 : Kinetic Kudu            : ubuntu-22.10-live-server-amd64.iso      : 5.19.0-21-generic
#   Ubuntu 22.04 : Jammy Jellyfish         : ubuntu-22.04.2-live-server-amd64.iso    : 5.15.0-60-generic
#   Ubuntu 20.04 : Focal Fossa             : ubuntu-20.04.6-live-server-amd64.iso    : 5.4.0-42-generic
#   Ubuntu 18.04 : Bionic Beaver           : ubuntu-18.04.6-server-amd64.iso         : 4.15.0-156-generic
# *****************************************************************************
#   ./bld : boot loader files
#   ./cfg : setting files (preseed.cfg/cloud-init/initrd/vmlinuz/...)
#   ./deb : deb files
#   ./img : copy files image
#   ./ird : custom initramfs files
#   ./iso : iso files
#   ./lnx : linux-image unpacked files
#   ./mnt : iso file mount point
#   ./pac : optional deb unpacked files
#   ./ram : initramfs files
#   ./usb : USB stick mount point
#   ./wrk : work directory
# https://packages.debian.org/index
# ### initial setting #########################################################
#set -x
#set -e
#set -u
trap 'exit 1' 1 2 3 15
# -----------------------------------------------------------------------------
dpkg -l fdisk curl dosfstools grub2-common initramfs-tools-core cpio gzip bzip2 lz4 lzma lzop xz-utils zstd
#sudo apt-get install fdisk curl dosfstools grub2-common initramfs-tools-core cpio gzip bzip2 lz4 lzma lzop xz-utils zstd
# ### download ################################################################
funcDownload () {
  # ### download: setting file ################################################
  sudo rm -rf ./cfg/
  mkdir -p ./cfg
  # === setting file ==========================================================
  echo "setting file"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/debian"                              "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/debian/preseed.cfg"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/debian"                              "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/debian/sub_late_command.sh"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                      "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/preseed.cfg"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                      "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/sub_late_command.sh"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                      "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/sub_success_command.sh"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.server"                       "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.server/user-data"
  # === oldoldstable ==========================================================
# echo "oldoldstable"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldoldstable"     "http://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/boot.img.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldoldstable"     "http://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/initrd.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldoldstable"     "http://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/vmlinuz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldoldstable/gtk" "http://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldoldstable/gtk" "http://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === oldstable =============================================================
  echo "oldstable"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldstable"        "http://deb.debian.org/debian/dists/oldstable/main/installer-amd64/current/images/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldstable"        "http://deb.debian.org/debian/dists/oldstable/main/installer-amd64/current/images/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldstable"        "http://deb.debian.org/debian/dists/oldstable/main/installer-amd64/current/images/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldstable/gtk"    "http://deb.debian.org/debian/dists/oldstable/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/oldstable/gtk"    "http://deb.debian.org/debian/dists/oldstable/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === stable ================================================================
  echo "stable"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stable"           "http://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stable"           "http://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stable"           "http://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stable/gtk"       "http://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stable/gtk"       "http://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === testing ===============================================================
  echo "testing"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "http://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "http://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "http://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing/gtk"      "http://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing/gtk"      "http://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/boot.img.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/initrd.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/vmlinuz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing/gtk"      "https://d-i.debian.org/daily-images/amd64/daily/hd-media/gtk/initrd.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing/gtk"      "https://d-i.debian.org/daily-images/amd64/daily/hd-media/gtk/vmlinuz"
  # === bionic ================================================================
  echo "bionic"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/boot.img.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/initrd.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/vmlinuz"
  # === focal =================================================================
  echo "focal"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/boot.img.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/initrd.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/vmlinuz"
  # ### download: iso file ####################################################
  sudo rm -rf ./iso/
  mkdir -p ./iso
  # ---------------------------------------------------------------------------
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-10.13.0-amd64-DVD-1.iso          ./iso/debian-10.13.0-amd64-DVD-1.iso
  ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-10.13.0-amd64-netinst.iso        ./iso/debian-10.13.0-amd64-netinst.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-11.6.0-amd64-DVD-1.iso           ./iso/debian-11.6.0-amd64-DVD-1.iso
  ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-11.6.0-amd64-netinst.iso         ./iso/debian-11.6.0-amd64-netinst.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-9.13.0-amd64-DVD-1.iso           ./iso/debian-9.13.0-amd64-DVD-1.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-9.13.0-amd64-netinst.iso         ./iso/debian-9.13.0-amd64-netinst.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-10.13.0-amd64-lxde.iso      ./iso/debian-live-10.13.0-amd64-lxde.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-11.6.0-amd64-lxde.iso       ./iso/debian-live-11.6.0-amd64-lxde.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-9.13.0-amd64-lxde.iso       ./iso/debian-live-9.13.0-amd64-lxde.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-testing-amd64-lxde.iso      ./iso/debian-live-testing-amd64-lxde.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-testing-amd64-DVD-1.iso          ./iso/debian-testing-amd64-DVD-1.iso
  ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-testing-amd64-netinst.iso        ./iso/debian-testing-amd64-netinst.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-oldoldstable-amd64.iso             ./iso/mini-stretch-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-oldstable-amd64.iso                ./iso/mini-buster-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-stable-amd64.iso                   ./iso/mini-bullseye-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-testing-amd64.iso                  ./iso/mini-bookworm-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/lunar-desktop-amd64.iso                 ./iso/lunar-desktop-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/lunar-desktop-legacy-amd64.iso          ./iso/lunar-desktop-legacy-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/lunar-live-server-amd64.iso             ./iso/lunar-live-server-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/mini-bionic-amd64.iso                   ./iso/mini-bionic-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/mini-focal-amd64.iso                    ./iso/mini-focal-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-18.04.6-desktop-amd64.iso        ./iso/ubuntu-18.04.6-desktop-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-18.04.6-server-amd64.iso         ./iso/ubuntu-18.04.6-server-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-18.04.6-live-server-amd64.iso    ./iso/ubuntu-18.04.6-live-server-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-20.04.6-desktop-amd64.iso        ./iso/ubuntu-20.04.6-desktop-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-20.04.6-live-server-amd64.iso    ./iso/ubuntu-20.04.6-live-server-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.04.2-desktop-amd64.iso        ./iso/ubuntu-22.04.2-desktop-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.04.2-live-server-amd64.iso    ./iso/ubuntu-22.04.2-live-server-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.10-desktop-amd64.iso          ./iso/ubuntu-22.10-desktop-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.10-live-server-amd64.iso      ./iso/ubuntu-22.10-live-server-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.04-desktop-amd64.iso          ./iso/ubuntu-23.04-desktop-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.04-live-server-amd64.iso      ./iso/ubuntu-23.04-live-server-amd64.iso
  # ::: debian mini.iso :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "debian mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-stretch-amd64.iso"                        "http://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-buster-amd64.iso"                         "http://deb.debian.org/debian/dists/oldstable/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-bullseye-amd64.iso"                       "http://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-bookworm-amd64.iso"                       "https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso"
  # ::: debian netinst ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "debian netinst"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-9.13.0-amd64-netinst.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-10.13.0-amd64-netinst.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-11.6.0-amd64-netinst.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso"
  # ::: debian DVD ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "debian DVD"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-9.13.0-amd64-DVD-1.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-10.13.0-amd64-DVD-1.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-11.6.0-amd64-DVD-1.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso"
  # ::: debian live DVD :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "debian live DVD"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "http://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-9.13.0-amd64-lxde.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "http://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-10.13.0-amd64-lxde.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-11.6.0-amd64-lxde.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso"
  # ::: ubuntu mini.iso :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "ubuntu mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-bionic-amd64.iso"                         "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-focal-amd64.iso"                          "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso"
  # ::: ubuntu server :::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "ubuntu server"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "http://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04.6-server-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/bionic/ubuntu-18.04.6-live-server-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/focal/ubuntu-20.04.6-live-server-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/kinetic/ubuntu-22.10-live-server-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/lunar/ubuntu-23.04-live-server-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "http://cdimage.ubuntu.com/ubuntu-server/daily-live/current/lunar-live-server-amd64.iso"
  # ::: ubuntu desktop ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "ubuntu desktop"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/bionic/ubuntu-18.04.6-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/focal/ubuntu-20.04.6-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/ubuntu-22.10-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/lunar/ubuntu-23.04-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "http://cdimage.ubuntu.com/daily-legacy/current/lunar-desktop-legacy-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "http://cdimage.ubuntu.com/ubuntu/daily-live/current/lunar-desktop-amd64.iso"
}
# === download: deb file ======================================================
funcDownload_deb () {
  sudo rm -rf ./opt/
  mkdir -p ./opt
  # ::: exfat :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo "exfat"
  # --- stretch ---------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/stretch"                             "http://ftp.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.2.5-2_amd64.deb"
  # --- buster ----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/buster"                              "http://ftp.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0-1_amd64.deb"
  # --- bullseye --------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/bullseye"                            "http://ftp.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0-2_amd64.deb"
  # --- bookworm --------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/bookworm"                            "http://ftp.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0+git20220115-2_amd64.deb"
  # --- bionic ----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/bionic"                              "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.2.8-1_amd64.deb"
  # --- focal -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.3.0-1_amd64.deb"
  # --- jammy -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/jammy"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.3.0+git20220115-2_amd64.deb"
  # --- kinetic ---------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/kinetic"                             "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.3.0+git20220115-2_amd64.deb"
  # --- lunar -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/lunar"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.4.0-1_amd64.deb"
  # ::: fuse ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo "fuse"
  # --- buster ----------------------------------------------------------------
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/buster"                              "http://ftp.debian.org/debian/pool/main/f/fuse/fuse_2.9.9-1+deb10u1_amd64.deb"
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/buster"                              "http://ftp.debian.org/debian/pool/main/f/fuse/libfuse2_2.9.9-1+deb10u1_amd64.deb"
  # --- focal -----------------------------------------------------------------
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/fuse_2.9.9-3_amd64.deb"
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/libfuse2_2.9.9-3_amd64.deb"
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/fuse-udeb_2.9.9-3_amd64.udeb"
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/libfuse2-udeb_2.9.9-3_amd64.udeb"
  # --- jammy -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/jammy"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/fuse_2.9.9-5ubuntu3_amd64.deb"
  # --- kinetic ---------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/kinetic"                             "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/fuse_2.9.9-5ubuntu3_amd64.deb"
  # --- lunar -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/lunar"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/fuse_2.9.9-6_amd64.deb"
  echo "fuse3"
  # ::: fuse3 :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  # --- focal -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse3/fuse3_3.9.0-2_amd64.deb"
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse3/libfuse3-3_3.9.0-2_amd64.deb"
  # --- jammy -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/jammy"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/fuse3_3.10.5-1build1_amd64.deb"
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/jammy"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/libfuse3-3_3.10.5-1build1_amd64.deb"
  # --- kinetic ---------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/kinetic"                             "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/fuse3_3.11.0-1_amd64.deb"
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/kinetic"                             "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/libfuse3-3_3.11.0-1_amd64.deb"
  # --- lunar -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/lunar"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/fuse3_3.14.0-3_amd64.deb"
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/lunar"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/libfuse3-3_3.14.0-3_amd64.deb"
  # ::: mount :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo "mount"
  # --- bionic ----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/bionic"                              "http://archive.ubuntu.com/ubuntu/pool/main/u/util-linux/mount_2.31.1-0.4ubuntu3.7_amd64.deb"
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/bionic"                              "http://archive.ubuntu.com/ubuntu/pool/main/u/util-linux/libmount1_2.31.1-0.4ubuntu3.7_amd64.deb"
}
# === download ================================================================
funcDownload
funcDownload_deb
# ### make initramfs and deb file #############################################
# === copy initrd and vmlinuz =================================================
# apt-cache depends package
# apt-cache rdepends package
# -----------------------------------------------------------------------------
echo "copy initrd and vmlinuz"
sudo bash -c 'mountpoint -q ./mnt/ && (umount -q -f ./mnt || umount -q -lf ./mnt)'
sudo bash -c 'mountpoint -q ./usb/sdb/ && (umount -q -f ./usb/sdb || umount -q -lf ./usb/sdb)'
sudo rm -rf ./mnt/
sudo rm -rf ./bld/
sudo rm -rf ./deb/
mkdir -p ./mnt
mkdir -p ./bld
mkdir -p ./deb
sudo bash -c 'for P in $(find ./iso/ \( -name 'debian-*-amd64-netinst.iso' \
                                     -o -name 'ubuntu-2*-live-server-amd64.iso' \
                                     -o -name 'ubuntu-1*[!live]-server-amd64.iso' \) \( -type f -o -type l \))
do
  mount -r -o loop ${P} ./mnt
  N=$(awk -F '\''\ '\'' '\''{split($1,A,"-"); print tolower(A[1]);}'\'' ./mnt/.disk/info)
  S=$(awk -F '\''\"'\'' '\''{split($2,A," "); print tolower(A[1]);}'\'' ./mnt/.disk/info)
  printf "copy initrd and vmlinuz: %-6.6s : %-8.8s : %s\n" ${N} ${S} ${P}
  mkdir -p ./bld/${S}
  mkdir -p ./lnx/${S}
  mkdir -p ./deb/${S}
  if [ -d ./mnt/casper/. ]; then
    cp -a ./mnt/casper/initrd* ./mnt/casper/vmlinuz   ./bld/${S}/
  elif [ -d ./mnt/install.amd/. ]; then
    cp -a ./mnt/install.amd/.                         ./bld/${S}/
  else
    cp -a ./mnt/install/initrd* ./mnt/install/vmlinuz ./bld/${S}/
  fi
  # *** modules ***************************************************************
#   libc6-udeb_* \
#   libc6_* \
  M=( \
    libc-l10n_* \
    libgcrypt20-udeb_* \
    libgcrypt20_* \
    libgnutls30_* \
    libmount1-udeb_* \
    libmount1_* \
    libntfs-3g* \
    libpcre3_* \
    libselinux1-udeb_* \
    libselinux1_* \
    libsmartcols1-udeb_* \
    libsmartcols1_* \
    libtinfo5_* \
    libzstd1-udeb_* \
    mount_* \
    ntfs-3g-udeb_* \
    ntfs-3g_* \
    util-linux_* \
  )
  case ${S} in
    stretch  ) M+=(fuse-udeb_* libfuse2-udeb_* );;
    buster   ) M+=(fuse-udeb_* libfuse2-udeb_* );;
    bullseye ) M+=(fuse-udeb_* libfuse2-udeb_* fuse3-udeb_* libfuse3-3-udeb_* );;
    bookworm ) M+=(fuse-udeb_* libfuse2-udeb_* fuse3-udeb_* libfuse3-3-udeb_* );;
    bionic   ) M+=(fuse-udeb_* libfuse2_* );;
    focal    ) ;;
    jammy    ) ;;
    kinetic  ) ;;
    lunar    ) ;;
    *        ) ;;
  esac
  # *** copy module ***********************************************************
  for F in ${M[@]}
  do
    printf '\''  %-20.20s : %s\n'\'' '\"'${F}'\"' '\"'$(find ./mnt/pool/main/ -name ''${F}'' -type f -printf '%f' -exec cp -a -u '\'{}\'' ./deb/${S}/ \;)'\"'
  done
  # *** linux image * *********************************************************
  find ./mnt/pool/ -regextype posix-basic -regex '\''.*/\(linux\|linux-signed\(-amd64\)*\)/linux-\(image\|modules\).*-[0-9]*-\(amd64\|generic\)*_.*'\'' \
     -type f -printf '\''  linux image file     : %f\n'\'' -exec cp -a '\'{}\'' ./deb/${S}/ \;
  umount ./mnt
done'
# === unpack deb file =========================================================
echo "unpack deb file"
sudo rm -rf ./pac/
sudo rm -rf ./lnx/
mkdir -p ./pac
mkdir -p ./lnx
sudo bash -c 'for S in $(ls ./deb/)
do
  find ./deb/${S}/ \(      -name 'linux-image-*_amd64.deb' -o      -name 'linux-modules-*_amd64.deb' \) \( -type f -o -type l \) -printf "unpack %p\n" -exec mkdir -p ./pac/${S} \; -exec dpkg -x '\'{}\'' ./lnx/${S} \;
  find ./deb/${S}/ \( -not -name 'linux-image-*_amd64.deb' -a -not -name 'linux-modules-*_amd64.deb' \) \( -type f -o -type l \) -printf "unpack %p\n" -exec mkdir -p ./pac/${S} \; -exec dpkg -x '\'{}\'' ./pac/${S} \;
done'
sudo bash -c 'for S in $(ls ./opt/)
do
  find ./opt/${S}/ \(      -name 'linux-image-*_amd64.deb' -o      -name 'linux-modules-*_amd64.deb' \) \( -type f -o -type l \) -printf "unpack %p\n" -exec mkdir -p ./pac/${S} \; -exec dpkg -x '\'{}\'' ./lnx/${S} \;
  find ./opt/${S}/ \( -not -name 'linux-image-*_amd64.deb' -a -not -name 'linux-modules-*_amd64.deb' \) \( -type f -o -type l \) -printf "unpack %p\n" -exec mkdir -p ./pac/${S} \; -exec dpkg -x '\'{}\'' ./pac/${S} \;
done'
# === unpack initramfs ========================================================
echo "unpack initramfs"
sudo rm -rf ./ram/
mkdir -p ./ram
sudo bash -c 'for S in $(ls ./bld/)
do
  case ${S} in
    bookworm ) D="./cfg/installer-hd-media/testing"       ;;
    bullseye ) D="./cfg/installer-hd-media/stable"        ;;
    buster   ) D="./cfg/installer-hd-media/oldstable"     ;;
    stretch  ) D="./cfg/installer-hd-media/oldoldstable"  ;;
    bionic   ) D="./cfg/installer-hd-media/bionic-updates";;
    *        ) D="./bld/${S}";;
  esac
  find ${D}/ -maxdepth 1 -name 'initrd*' \( -type f -o -type l \) -printf "unpack %p\n" -exec mkdir -p ./ram/${S} \; -exec unmkinitramfs '\'{}\'' ./ram/${S} \;
done'
# === copy and make kernel module =============================================
echo "copy and make kernel module"
sudo rm -rf ./wrk/
sudo rm -rf ./ird/
mkdir -p ./wrk
mkdir -p ./ird
sudo bash -c 'for S in $(ls ./ram/)
do
  if [ -d ./ram/${S}/main/. ]; then
    D="./ram/${S}/main"
  else
    D="./ram/${S}"
  fi
  printf "copy initramfs : %-8.8s : %s\n" ${S} ${D}
  mkdir -p ./wrk/${S}
  cp -a ${D}/. ./wrk/${S}/
  if [ -d ./pac/${S}/. ]; then
    for O in $(ls ./pac/${S}/)
    do
      cp -a --backup ./pac/${S}/${O}/. ./wrk/${S}/${O}/
    done
  fi
  V=$(find ./wrk/${S}/lib/modules/*/kernel/ -name '\''fs'\'' -type d | sed -e '\''s~^.*/modules/\(.*\)/kernel/.*$~\1~g'\'')
  if [ -d ./lnx/${S}/. ]; then
#   cp -a --backup ./lnx/${S}/lib/modules/${V}/kernel/drivers/firmware ./wrk/${S}/lib/modules/${V}/kernel/drivers
    for T in fat exfat ntfs ntfs3 fuse fuse3
    do
      if [ -d ./lnx/${S}/lib/modules/${V}/kernel/fs/${T}/. ]; then
        cp -a --backup ./lnx/${S}/lib/modules/${V}/kernel/fs/${T} ./wrk/${S}/lib/modules/${V}/kernel/fs
      fi
    done
  fi
  if [ -d ./wrk/${S}/lib/modules/${V}/. ]; then
    touch ./wrk/${S}/lib/modules/${V}/modules.builtin.modinfo
    depmod -a -b wrk/${S} ${V}
  fi
  if [ -f  ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst ]; then
    sed -i ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst    \
        -e '\''s/^\([[:space:]]*FS\)="\(.*\)".*$/\1="\2 fuse"/'\''
  fi
  case ${S} in
    bookworm ) ;;
    bullseye ) ;;
    buster   ) ;;
    stretch  ) ;;
    bionic   )
      if [ -f  ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst ]; then
        OLD_IFS=${IFS}
        INS_ROW=$(
          sed -n -e '\''/^[[:space:]]*use_this_iso () {/,/^[[:space:]]*}/ {/[[:space:]]*mount -t iso9660 -o loop,ro,exec $iso_to_try \/cdrom/=}'\'' \
            ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst
        )
        IFS= INS_STR=$(
          cat <<- '\''_EOT_'\'' | sed -e '\''s/^ //g'\'' | sed -z -e '\''s/\n/\\n/g'\''
			 	#
			 	local ram=$(grep ^MemAvailable: /proc/meminfo | { read label size unit; echo ${size:-0}; })
			 	local iso_size=$(ls -sk /hd-media/$iso_to_try | { read size filename; echo ${size:-0}; })
			 	#
			 	cd /
			 	if [ $(( $iso_size + 100000 )) -lt $ram ]; then
			 		# We have enough RAM to be able to copy the ISO to RAM,
			 		# let'\''s offer it to the user
			 		db_input low iso-scan/copy_iso_to_ram || true
			 		db_go
			 		db_get iso-scan/copy_iso_to_ram
			 		RET="true"
			 	else
			 		log "Skipping debconf question iso-scan/copy_iso_to_ram:" \
			 		    "not enough memory available ($ram kB) to copy" \
			 		    "/hd-media/$iso_to_try ($iso_size kB) into RAM and still" \
			 		    "have 100 MB free."
			 		RET="false"
			 	fi
			 
			 	if [ "$RET" = false ]; then
			 		# Direct mount
			 		log "Mounting /hd-media/$iso_to_try on /cdrom"
			 		mount -t iso9660 -o loop,ro,exec /hd-media/$iso_to_try /cdrom 2>/dev/null
			 	else
			 		# We copy the ISO to RAM before mounting it
			 		log "Copying /hd-media/$iso_to_try to /installer.iso"
			 		cp /hd-media/$iso_to_try /installer.iso
			 		log "Mounting /installer.iso on /cdrom"
			 		mount -t iso9660 -o loop,ro,exec /installer.iso /cdrom 2>/dev/null
			 		# So that we can free the original device
			#		log "Unmounting /hd-media"
			#		cd /
			#		umount /hd-media
			#		mount | sort
			#		log "USB media freed"
			 	fi
_EOT_
        )
        IFS=${OLD_IFS}
        sed -i ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst                                                                    \
            -e '\''/^use_this_iso () {/,/^}/ s~^\([[:space:]]*mount -t iso9660 -o loop,ro,exec $iso_to_try /cdrom .*$\)~#\1~'\'' \
            -e '\"'${INS_ROW:-1}a \\${INS_STR}'\"'
        cat <<- '\''_EOT_'\'' >> ./wrk/${S}/var/lib/dpkg/info/iso-scan.templates
			
			Template: iso-scan/copy_iso_to_ram
			Type: boolean
			Default: false
			Description: Copy the ISO image into RAM before mounting it?
			 There is enough available memory to be able to copy the ISO image into
			 RAM.
			 .
			 Choosing this option allows reusing the disk hosting the ISO image. If you
			 don'\''t do it, the disk will be actively used to access the ISO image and
			 it can'\''t be partitioned by the installer.
			 .
			 Note however that if you overwrite the disk containing the ISO image, you
			 should not reboot before the end of the installation as you will not be
			 able to restart the installer since the ISO image will be gone from the
			 hard disk and memory.
			Description-ja.UTF-8: マウントする前に、ISO イメージを RAM にコピーしますか?
			 ISO イメージを RAM にコピーするのに十分なメモリがあります。
			 .
			 「はい」を選ぶと、ISO イメージを提供したディスクを再利用できます。「いいえ」を選ぶと、ディスクは ISO イメージにアクセスするのに随時使われるので、インストーラでそのディスクをパーティショニングすることはできません。
			 .
			 ただし、ISO イメージを含むディスクを上書きすると、ISO イメージはディスクからもメモリからも消失するため、インストーラを再度開始できなくなるので、このインストールを完了するまで再起動してはならないことに注意してください。
_EOT_
      fi
      ;;
    focal    ) ;;
    jammy    ) ;;
    kinetic  ) ;;
    lunar    ) ;;
    *        ) ;;
  esac
done'
  # COMPRESS: [ gzip | bzip2 | lz4 | lzma | lzop | xz | zstd ]
  # COMPRESSLEVEL: ...
  # Valid values are:
  # 1 -  9 for gzip|bzip2|lzma|lzop
  # 0 -  9 for  lz4|xz
  # 0 - 19 for zstd
sudo bash -c 'for S in $(ls ./ram/)
do
  O=$(pwd)
  pushd ./wrk/${S} > /dev/null
    printf "make initramfs : %-8.8s : %s\n" ${S} ${O}/ird/initrd-${S}.img
    find . | cpio -R 0:0 -o -H newc --quie | gzip -c > ${O}/ird/initrd-${S}.img
  popd > /dev/null
done'
ls -lh ./ird/
#sudo rm -rf ./wrk/*
# === copy initramfs ==========================================================
echo "copy initramfs"
sudo rm -rf ./img/
mkdir -p ./img
sudo bash -c 'for F in $(ls ./ird/)
do
  echo "copy ${F}"
  S=$(echo ${F} | sed -e "s/^.*-\(.*\)\..*$/\1/g")
  case ${S} in
    stretch  | \
    buster   | \
    bullseye | \
    bookworm )
      mkdir -p ./img/install.amd/debian/${S}
      cp -a -L -u ./bld/${S}/. ./img/install.amd/debian/${S}/
      cp -a -L -u ./ird/${F}   ./img/install.amd/debian/${S}/initrd.img
      ;;
    bionic   | \
    focal    | \
    jammy    | \
    kinetic  | \
    lunar    )
      mkdir -p ./img/install.amd/ubuntu/${S}
      cp -a -L -u ./bld/${S}/. ./img/install.amd/ubuntu/${S}/
      cp -a -L -u ./ird/${F}   ./img/install.amd/ubuntu/${S}/initrd.img
      ;;
    *        )
      ;;
  esac
done'
# ### make copy image #########################################################
# === make directory ==========================================================
echo "make directory"
sudo mkdir -p ./img/images         \
              ./img/preseed/debian \
              ./img/preseed/ubuntu \
              ./img/nocloud
# === copy config file ========================================================
#sudo cp -a -L -u ./cfg/debian/preseed.cfg                    ./img/preseed/debian/
sudo cp -a -L -u ./cfg/debian/sub_late_command.sh            ./img/preseed/debian/
#sudo cp -a -L -u ./cfg/ubuntu.desktop/preseed.cfg            ./img/preseed/ubuntu/
sudo cp -a -L -u ./cfg/ubuntu.desktop/sub_late_command.sh    ./img/preseed/ubuntu/
sudo cp -a -L -u ./cfg/ubuntu.desktop/sub_success_command.sh ./img/preseed/ubuntu/
#sudo cp -a -L -u ./cfg/ubuntu.server/user-data               ./img/nocloud/
#sudo touch ./img/nocloud/meta-data
#sudo touch ./img/nocloud/vendor-data
#sudo touch ./img/nocloud/network-config
# === change config file ======================================================
echo "change config file"
sed -e 's~ /cdrom/preseed/~ /hd-media/preseed/debian/~g' ./cfg/debian/preseed.cfg         | sudo tee ./img/preseed/debian/preseed.cfg > /dev/null
sed -e 's~ /cdrom/preseed/~ /hd-media/preseed/ubuntu/~g' ./cfg/ubuntu.desktop/preseed.cfg | sudo tee ./img/preseed/ubuntu/preseed.cfg > /dev/null
#sed -e 's/bind9-utils/bind9utils/'                                                        \
#    -e 's/bind9-dnsutils/dnsutils/'                                                       \
#    -e 's~\(^[ \t]*d-i[ \t]*mirror/http/hostname\).*$~\1 string archive.debian.org~'      \
#    -e 's~\(^[ \t]*d-i[ \t]*mirror/http/mirror select\).*$~\1 select archive.debian.org~' \
#    -e 's~\(^[ \t]*d-i[ \t]*apt-setup/services-select\).*$~\1 multiselect updates~'       \
#    -e 's~\(^[ \t]*d-i[ \t]*apt-setup/security_host\).*$~\1 string archive.debian.org~'   \
#           ./img/preseed/debian/preseed.cfg                                               \
#| sudo tee ./img/preseed/debian/preseed_oldold.cfg > /dev/null
sed -e 's/bind9-utils/bind9utils/'                          \
    -e 's/bind9-dnsutils/dnsutils/'                         \
           ./img/preseed/debian/preseed.cfg                 \
| sudo tee ./img/preseed/debian/preseed_old.cfg > /dev/null
sed -e 's/bind9-utils/bind9utils/'                          \
    -e 's/bind9-dnsutils/dnsutils/'                         \
    -e '/d-i partman\/unmount_active/ s/^#/ /g'             \
    -e '/d-i partman\/early_command/,/exit 0/ s/^#/ /g'     \
           ./img/preseed/ubuntu/preseed.cfg                 \
| sudo tee ./img/preseed/ubuntu/preseed_old.cfg > /dev/null
# === copy iso file ===========================================================
echo "copy iso file"
for F in \
  debian-testing-amd64-netinst.iso        \
  debian-11.6.0-amd64-netinst.iso         \
  debian-10.13.0-amd64-netinst.iso        \
  ubuntu-23.04-live-server-amd64.iso      \
  ubuntu-22.10-live-server-amd64.iso      \
  ubuntu-22.04.2-live-server-amd64.iso    \
  ubuntu-20.04.6-live-server-amd64.iso    \
  ubuntu-18.04.6-server-amd64.iso
# debian-9.13.0-amd64-netinst.iso         \
# ubuntu-18.04.6-live-server-amd64.iso    \
# ubuntu-23.04-desktop-amd64.iso          \
# ubuntu-22.10-desktop-amd64.iso          \
# ubuntu-22.04.2-desktop-amd64.iso        \
# ubuntu-20.04.6-desktop-amd64.iso        \
# ubuntu-18.04.6-desktop-amd64.iso
do
  echo "copy ${F}"
  sudo cp -a -L -u ./iso/${F} ./img/images/
done
# ### USB Device: partition and format ########################################
# *** [ USB device: /dev/sdb ] ***
# === device and mount check ==================================================
echo "device and mount check"
while :
do
  lsblk -f /dev/sdb
  if [ $? -eq 0 ]; then
    break
  fi
  echo "device not found"
  lsblk -f /dev/sd[a-z]
  echo "enter Ctrl+C"
  read DUMMY
done
sudo bash -c 'mountpoint -q ./usb/sdb/ && (umount -q -f ./usb/sdb || umount -q -lf ./usb/sdb)'
sudo bash -c 'umount -q /dev/sdb1 || umount -q -lf /dev/sdb1'
sudo bash -c 'umount -q /dev/sdb2 || umount -q -lf /dev/sdb2'
sudo bash -c 'umount -q /dev/sdb3 || umount -q -lf /dev/sdb3'
sudo bash -c 'umount -q /dev/sdb4 || umount -q -lf /dev/sdb4'
# === partition ===============================================================
echo "partition"
sudo sfdisk --wipe always --wipe-partitions always /dev/sdb << _EOT_
label: gpt
first-lba: 34
start=34, size=  2014, type=21686148-6449-6E6F-744E-656564454649, attrs="GUID:62,63"
start=  , size=256MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
start=  , size=  4GiB, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
start=  , size=      , type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
_EOT_
# === format ==================================================================
echo "format"
sudo mkfs.vfat -F 32              /dev/sdb2
sudo mkfs.vfat -F 32 -n "CIDATA"  /dev/sdb3
#sudo mkfs.exfat      -n "ISOFILE" /dev/sdb4
sudo mkfs.ntfs -Q    -L "ISOFILE" /dev/sdb4
sleep 1
sudo sync
lsblk -f /dev/sdb
# ### USB Device: [ /dev/sdX1, /dev/sdX2 ] Boot and EFI partition #############
# *** [ USB device: /dev/sdb1, /dev/sdb2 ] ***
# === mount /dev/sdX2 =========================================================
echo "mount /dev/sdX2"
sudo rm -rf ./usb/sdb/sdb/
mkdir -p ./usb/sdb
sudo mount /dev/sdb2 ./usb/sdb/
# === install boot loader =====================================================
echo "install boot loader"
sudo grub-install --target=i386-pc    --recheck   --boot-directory=./usb/sdb/boot /dev/sdb
sudo grub-install --target=x86_64-efi --removable --boot-directory=./usb/sdb/boot --efi-directory=./usb/sdb
# === make .disk directory ====================================================
echo "make .disk directory"
sudo mkdir -p ./usb/sdb/.disk
sudo touch ./usb/sdb/.disk/info
# === grub.cfg ================================================================
echo "grub.cfg"
cat << '_EOT_' | sudo tee ./usb/sdb/boot/grub/grub.cfg > /dev/null
set default=0
set timeout=-1

search.fs_label "CIDATA"  cfgpart hd1,gpt3
search.fs_label "ISOFILE" isopart hd1,gpt4

loadfont ${prefix}/fonts/unicode.pf2

set lang=ja_JP

set gfxmode=1280x720
insmod all_video
insmod gfxterm
terminal_output gfxterm

set menu_color_normal=cyan/blue
set menu_color_highlight=white/blue

grub_platform

insmod play
play 960 440 1 0 4 440 1

menuentry 'Unattended installation (Debian 12:testing [bookworm])' {
    set gfxpayload=keep
    set isofile="/images/debian-testing-amd64-netinst.iso"
    set isoscan="${isofile} (testing)"
    set isodist="debian/bookworm"
    set preseed="/hd-media/preseed/debian/preseed.cfg"
    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
#   initrd  (${cfgpart})/install.amd/${isodist}/initrd.gz
}
menuentry 'Unattended installation (Debian 11:stable [bullseye])' {
    set gfxpayload=keep
    set isofile="/images/debian-11.6.0-amd64-netinst.iso"
    set isoscan="${isofile} (stable - 11.6)"
    set isodist="debian/bullseye"
    set preseed="/hd-media/preseed/debian/preseed.cfg"
    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
#   initrd  (${cfgpart})/install.amd/${isodist}/initrd.gz
}
menuentry 'Unattended installation (Debian 10:oldstable [buster])' {
    set gfxpayload=keep
    set isofile="/images/debian-10.13.0-amd64-netinst.iso"
    set isoscan="${isofile} (oldstable - 10.13)"
    set isodist="debian/buster"
    set preseed="/hd-media/preseed/debian/preseed_old.cfg"
    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
#   initrd  (${cfgpart})/install.amd/${isodist}/initrd.gz
}
#menuentry 'Unattended installation (Debian 9:oldoldstable [stretch])' {
#    set gfxpayload=keep
#    set isofile="/images/debian-9.13.0-amd64-netinst.iso"
#    set isoscan="${isofile} (oldstable - 9.13)"
#    set isodist="debian/stretch"
#    set preseed="/hd-media/preseed/debian/preseed_oldold.cfg"
#    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
#    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
#    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
#    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
##   initrd  (${cfgpart})/install.amd/${isodist}/initrd.gz
#}
menuentry 'Unattended installation (Ubuntu 23.04:Lunar Lobster)' {
    set gfxpayload=keep
    set isofile="/images/ubuntu-23.04-live-server-amd64.iso"
    set isoscan="iso-scan/filename=${isofile}"
    set isodist="ubuntu/lunar"
    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=1 ---
    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
#   loopback loop (${isopart})${isofile}
#   linux   (loop)/casper/vmlinuz root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=1 ---
#   initrd  (loop)/casper/initrd
#   loopback --delete loop
}
menuentry 'Unattended installation (Ubuntu 22.10:Kinetic Kudu)' {
    set gfxpayload=keep
    set isofile="/images/ubuntu-22.10-live-server-amd64.iso"
    set isoscan="iso-scan/filename=${isofile}"
    set isodist="ubuntu/kinetic"
    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=1 ---
    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
#   loopback loop (${isopart})${isofile}
#   linux   (loop)/casper/vmlinuz root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=1 ---
#   initrd  (loop)/casper/initrd
#   loopback --delete loop
}
menuentry 'Unattended installation (Ubuntu 22.04:Jammy Jellyfish)' {
    set gfxpayload=keep
    set isofile="/images/ubuntu-22.04.2-live-server-amd64.iso"
    set isoscan="iso-scan/filename=${isofile}"
    set isodist="ubuntu/jammy"
    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=1 ---
    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
#   loopback loop (${isopart})${isofile}
#   linux   (loop)/casper/vmlinuz root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=1 ---
#   initrd  (loop)/casper/initrd
#   loopback --delete loop
}
menuentry 'Unattended installation (Ubuntu 20.04:Focal Fossa)' {
    set gfxpayload=keep
    set isofile="/images/ubuntu-20.04.6-live-server-amd64.iso"
    set isoscan="iso-scan/filename=${isofile}"
    set isodist="ubuntu/focal"
    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=1 ---
    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
#   loopback loop (${isopart})${isofile}
#   linux   (loop)/casper/vmlinuz root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=1 ---
#   initrd  (loop)/casper/initrd
#   loopback --delete loop
}
menuentry 'Unattended installation (Ubuntu 18.04:Bionic Beaver)' {
    set gfxpayload=keep
    set isofile="/images/ubuntu-18.04.6-server-amd64.iso"
    set isoscan="${isofile} (bionic - 18.04)"
    set isodist="ubuntu/bionic"
    set preseed="/hd-media/preseed/ubuntu/preseed_old.cfg"
    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
#   initrd  (${cfgpart})/install.amd/${isodist}/initrd.gz
}

menuentry "System shutdown" {
    echo "System shutting down..."
    halt
}
menuentry "System restart" {
    echo "System rebooting..."
    reboot
}
_EOT_
# === unmount =================================================================
echo "unmount"
sudo umount ./usb/sdb/
# ### USB Device: [ /dev/sdX3 ] Data partition ################################
# *** [ USB device: /dev/sdb3 ] ***
# === mount /dev/sdX3 =========================================================
echo "mount /dev/sdX3"
sudo mount /dev/sdb3 ./usb/sdb/
# === copy boot loader and setting files ======================================
echo "copy boot loader and setting files"
sudo cp --preserve=timestamps -u -r ./img/install.amd/ ./usb/sdb/
sudo cp --preserve=timestamps -u    ./cfg/ubuntu.server/user-data ./usb/sdb/
sudo touch ./usb/sdb/meta-data
sudo touch ./usb/sdb/vendor-data
sudo touch ./usb/sdb/network-config
# === unmount =================================================================
echo "unmount"
sudo umount ./usb/sdb/
# ### USB Device: [ /dev/sdX4 ] Data partition ################################
# *** [ USB device: /dev/sdb4 ] ***
# === mount /dev/sdX4 =========================================================
echo "mount /dev/sdX4"
sudo mount /dev/sdb4 ./usb/sdb/
# === copy iso files ==========================================================
echo "copy iso files"
sudo cp --preserve=timestamps -u -r ./img/images/  ./usb/sdb/
sudo cp --preserve=timestamps -u -r ./img/nocloud/ ./usb/sdb/
sudo cp --preserve=timestamps -u -r ./img/preseed/ ./usb/sdb/
# === unmount =================================================================
sudo umount ./usb/sdb
echo "unmount"
lsblk -f /dev/sdb
# =============================================================================
echo "complete"
# =============================================================================
# http://ftp.debian.org/debian/pool/main/n/ntfs-3g/ntfs-3g_2022.10.3-1+b1_amd64.deb
# http://ftp.debian.org/debian/pool/main/f/fuse3/fuse3_3.14.0-3_amd64.deb
# http://ftp.debian.org/debian/pool/main/f/fuse/fuse_2.9.9-6+b1_amd64.deb
# ### eof #####################################################################
