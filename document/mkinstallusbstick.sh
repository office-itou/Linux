#!/bin/bash
# *****************************************************************************
# Unattended installation USB stick for multiple ISO files. (GPT exFAT Ver.)
# -----------------------------------------------------------------------------
#   Debian xx    : -------- (testing)      : debian-testing-amd64-netinst.iso         : 6.1.0-7-amd64
#   Debian 12    : bookworm (testing)      : debian-bookworm-DI-rc2-amd64-netinst.iso : 6.1.0-7-amd64
#   Debian 11    : bullseye (stable)       : debian-11.7.0-amd64-netinst.iso          : 5.10.0-22-amd64
#   Debian 10    : buster   (oldstable)    : debian-10.13.0-amd64-netinst.iso         : 4.19.0-21-amd64
#   Debian  9    : stretch  (oldoldstable) : debian-9.13.0-amd64-netinst.iso          : 4.9.0-13-amd64
#   Ubuntu 23.04 : Lunar Lobster           : ubuntu-23.04-live-server-amd64.iso       : 6.2.0-18-generic
#   Ubuntu 22.10 : Kinetic Kudu            : ubuntu-22.10-live-server-amd64.iso       : 5.19.0-21-generic
#   Ubuntu 22.04 : Jammy Jellyfish         : ubuntu-22.04.2-live-server-amd64.iso     : 5.15.0-60-generic
#   Ubuntu 20.04 : Focal Fossa             : ubuntu-20.04.6-live-server-amd64.iso     : 5.4.0-42-generic
#   Ubuntu 18.04 : Bionic Beaver           : ubuntu-18.04.6-server-amd64.iso          : 4.15.0-156-generic
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
# -----------------------------------------------------------------------------
# set -n
# set -x
  set -o ignoreeof
  set +m
  set -e
  set -u

  trap 'exit 1' 1 2 3 15
# -----------------------------------------------------------------------------
  dpkg -l fdisk curl dosfstools grub2-common initramfs-tools-core cpio gzip bzip2 lz4 lzma lzop xz-utils zstd
# apt-get install fdisk curl dosfstools grub2-common initramfs-tools-core cpio gzip bzip2 lz4 lzma lzop xz-utils zstd

# ### download ################################################################
# === download: cfg file ======================================================
funcDownload_cfg () {
  # ### download: setting file ################################################
  rm -rf ./cfg/
  mkdir -p ./cfg
  # === setting file ==========================================================
  echo "setting file"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/debian"                              "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/debian/preseed.cfg"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/debian"                              "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/debian/sub_late_command.sh"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                      "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/preseed.cfg"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                      "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/sub_late_command.sh"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                      "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/sub_success_command.sh"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.server"                       "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.server/user-data"
  # === stretch ===============================================================
# echo "stretch"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/boot.img.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/initrd.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/vmlinuz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stretch/gtk"      "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
# curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/stretch/gtk"      "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === buster ================================================================
  echo "buster"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/buster/gtk"       "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/buster/gtk"       "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === bullseye ==============================================================
  echo "bullseye"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bullseye/gtk"     "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bullseye/gtk"     "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === bookworm ==============================================================
  echo "bookworm"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bookworm/gtk"     "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/bookworm/gtk"     "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === testing ===============================================================
  echo "testing"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/boot.img.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/vmlinuz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing/gtk"      "https://d-i.debian.org/daily-images/amd64/daily/hd-media/gtk/initrd.gz"
  curl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/testing/gtk"      "https://d-i.debian.org/daily-images/amd64/daily/hd-media/gtk/vmlinuz"
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
}

# === download: iso link ======================================================
funcDownload_lnk () {
  # ### download: iso link ####################################################
  rm -rf ./iso/
  mkdir -p ./iso
  # --- mini.iso --------------------------------------------------------------
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-stretch-amd64.iso                               ./iso/mini-stretch-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-buster-amd64.iso                                ./iso/mini-buster-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-bullseye-amd64.iso                              ./iso/mini-bullseye-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-bookworm-amd64.iso                              ./iso/mini-bookworm-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/mini-testing-amd64.iso                               ./iso/mini-testing-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/mini-bionic-amd64.iso                                ./iso/mini-bionic-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/mini-focal-amd64.iso                                 ./iso/mini-focal-amd64.iso
  # --- debian netinst --------------------------------------------------------
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-9.13.0-amd64-netinst.iso                      ./iso/debian-9.13.0-amd64-netinst.iso
  ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-10.13.0-amd64-netinst.iso                     ./iso/debian-10.13.0-amd64-netinst.iso
  ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-11.7.0-amd64-netinst.iso                      ./iso/debian-11.7.0-amd64-netinst.iso
  ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-bookworm-DI-rc2-amd64-netinst.iso             ./iso/debian-bookworm-DI-rc2-amd64-netinst.iso
  ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-testing-amd64-netinst.iso                     ./iso/debian-testing-amd64-netinst.iso
  # --- debian DVD ------------------------------------------------------------
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-9.13.0-amd64-DVD-1.iso                        ./iso/debian-9.13.0-amd64-DVD-1.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-10.13.0-amd64-DVD-1.iso                       ./iso/debian-10.13.0-amd64-DVD-1.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-11.7.0-amd64-DVD-1.iso                        ./iso/debian-11.7.0-amd64-DVD-1.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-bookworm-DI-rc2-amd64-DVD-1.iso               ./iso/debian-bookworm-DI-rc2-amd64-DVD-1.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-testing-amd64-DVD-1.iso                       ./iso/debian-testing-amd64-DVD-1.iso
  # --- debian live -----------------------------------------------------------
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-9.13.0-amd64-lxde.iso                    ./iso/debian-live-9.13.0-amd64-lxde.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-10.13.0-amd64-lxde.iso                   ./iso/debian-live-10.13.0-amd64-lxde.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-11.7.0-amd64-lxde.iso                    ./iso/debian-live-11.7.0-amd64-lxde.iso
  ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-bkworm-DI-rc2-amd64-lxde.iso             ./iso/debian-live-bkworm-DI-rc2-amd64-lxde.iso
# ln -s /mnt/hgfs/workspace/Image/linux/debian/debian-live-testing-amd64-lxde.iso                   ./iso/debian-live-testing-amd64-lxde.iso
  # --- ubuntu desktop --------------------------------------------------------
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-18.04.6-desktop-amd64.iso                     ./iso/ubuntu-18.04.6-desktop-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-20.04.6-desktop-amd64.iso                     ./iso/ubuntu-20.04.6-desktop-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.04.2-desktop-amd64.iso                     ./iso/ubuntu-22.04.2-desktop-amd64.iso
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.10-desktop-amd64.iso                       ./iso/ubuntu-22.10-desktop-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.04-desktop-amd64.iso                       ./iso/ubuntu-23.04-desktop-amd64.iso
  # --- ubuntu server ---------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-18.04.6-server-amd64.iso                      ./iso/ubuntu-18.04.6-server-amd64.iso
  # --- ubuntu live server ----------------------------------------------------
# ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-18.04.6-live-server-amd64.iso                 ./iso/ubuntu-18.04.6-live-server-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-20.04.6-live-server-amd64.iso                 ./iso/ubuntu-20.04.6-live-server-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.04.2-live-server-amd64.iso                 ./iso/ubuntu-22.04.2-live-server-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.10-live-server-amd64.iso                   ./iso/ubuntu-22.10-live-server-amd64.iso
  ln -s /mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.04-live-server-amd64.iso                   ./iso/ubuntu-23.04-live-server-amd64.iso
}

# === download: iso file ======================================================
funcDownload_iso () {
  # ### download: iso file ####################################################
# rm -rf ./iso/
# mkdir -p ./iso
  # ::: debian mini.iso :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "debian mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-stretch-amd64.iso"                        "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-buster-amd64.iso"                         "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-bullseye-amd64.iso"                       "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-bookworm-amd64.iso"                       "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-testing-amd64.iso"                        "https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso"
  # ::: debian netinst ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo "debian netinst"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-cd/debian-9.13.0-amd64-netinst.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/10.13.0/amd64/iso-cd/debian-10.13.0-amd64-netinst.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-11.7.0-amd64-netinst.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/bookworm_di_rc2/amd64/iso-cd/debian-bookworm-DI-rc2-amd64-netinst.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso"
  # ::: debian DVD ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "debian DVD"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-dvd/debian-9.13.0-amd64-DVD-1.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/10.13.0/amd64/iso-dvd/debian-10.13.0-amd64-DVD-1.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-11.7.0-amd64-DVD-1.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/bookworm_di_rc2/amd64/iso-dvd/debian-bookworm-DI-rc2-amd64-DVD-1.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso"
  # ::: debian live DVD :::::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo "debian live DVD"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/9.13.0-live/amd64/iso-hybrid/debian-live-9.13.0-amd64-lxde.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/archive/10.13.0-live/amd64/iso-hybrid/debian-live-10.13.0-amd64-lxde.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-11.7.0-amd64-lxde.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/bookworm_di_rc2-live/amd64/iso-hybrid/debian-live-bkworm-DI-rc2-amd64-lxde.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso"
  # ::: ubuntu mini.iso :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "ubuntu mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-bionic-amd64.iso"                         "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
# curl -L -# -R -S -f --create-dirs -o "./iso/mini-focal-amd64.iso"                          "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso"
  # ::: ubuntu server :::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo "ubuntu server"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04.6-server-amd64.iso"
  # ::: ubuntu live server ::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo "ubuntu live server"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/bionic/ubuntu-18.04.6-live-server-amd64.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/focal/ubuntu-20.04.6-live-server-amd64.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/kinetic/ubuntu-22.10-live-server-amd64.iso"
  curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/lunar/ubuntu-23.04-live-server-amd64.iso"
  # ::: ubuntu desktop ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "ubuntu desktop"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/bionic/ubuntu-18.04.6-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/focal/ubuntu-20.04.6-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/kinetic/ubuntu-22.10-desktop-amd64.iso"
# curl -L -# -O -R -S --create-dirs --output-dir "./iso"                                     "https://releases.ubuntu.com/lunar/ubuntu-23.04-desktop-amd64.iso"
}

# === download: deb file ======================================================
funcDownload_deb () {
  rm -rf ./opt/
  mkdir -p ./opt
  # ::: exfat :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  echo "exfat"
  # --- stretch ---------------------------------------------------------------
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/stretch"                             "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.2.5-2_amd64.deb"
  # --- buster ----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/buster"                              "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0-1_amd64.deb"
  # --- bullseye --------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/bullseye"                            "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0-2_amd64.deb"
  # --- bookworm --------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./opt/bookworm"                            "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0+git20220115-2_amd64.deb"
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
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/buster"                              "https://deb.debian.org/debian/pool/main/f/fuse/fuse_2.9.9-1+deb10u1_amd64.deb"
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/buster"                              "https://deb.debian.org/debian/pool/main/f/fuse/libfuse2_2.9.9-1+deb10u1_amd64.deb"
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
  # ::: iso-scan ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# echo "iso-scan"
  # --- stretch ---------------------------------------------------------------
  # --- buster ----------------------------------------------------------------
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/buster"                              "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.75_all.udeb"
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/buster"                              "https://deb.debian.org/debian/pool/main/i/iso-scan/load-iso_1.75_all.udeb"
  # --- bullseye --------------------------------------------------------------
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/bullseye"                            "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.85_all.udeb"
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/bullseye"                            "https://deb.debian.org/debian/pool/main/i/iso-scan/load-iso_1.85_all.udeb"
  # --- bookworm --------------------------------------------------------------
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/bookworm"                            "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.88_all.udeb"
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/bookworm"                            "https://deb.debian.org/debian/pool/main/i/iso-scan/load-iso_1.88_all.udeb"
  # --- bionic ----------------------------------------------------------------
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/bionic"                              "http://archive.ubuntu.com/ubuntu/pool/main/i/iso-scan/iso-scan_1.55ubuntu5_all.udeb"
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/bionic"                              "http://archive.ubuntu.com/ubuntu/pool/main/i/iso-scan/load-iso_1.55ubuntu5_all.udeb"
  # --- focal -----------------------------------------------------------------
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/i/iso-scan/iso-scan_1.55ubuntu9_all.udeb"
# curl -L -# -O -R -S --create-dirs --output-dir "./opt/focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/i/iso-scan/load-iso_1.55ubuntu9_all.udeb"
  # --- jammy -----------------------------------------------------------------
  # --- kinetic ---------------------------------------------------------------
  # --- lunar -----------------------------------------------------------------
}

# === download: arc file ======================================================
funcDownload_arc () {
  rm -rf ./arc/
  mkdir -p ./arc
  echo "iso-scan"
  # --- stretch ---------------------------------------------------------------
  # --- buster ----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./arc/buster"                              "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.75.tar.xz"
  # --- bullseye --------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./arc/bullseye"                            "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.85.tar.xz"
  # --- bookworm --------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./arc/bookworm"                            "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.88.tar.xz"
  # --- bionic ----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./arc/bionic"                              "http://archive.ubuntu.com/ubuntu/pool/main/i/iso-scan/iso-scan_1.55ubuntu5.tar.xz"
  # --- focal -----------------------------------------------------------------
  curl -L -# -O -R -S --create-dirs --output-dir "./arc/focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/i/iso-scan/iso-scan_1.55ubuntu9.tar.xz"
  # --- jammy -----------------------------------------------------------------
  # --- kinetic ---------------------------------------------------------------
  # --- lunar -----------------------------------------------------------------
}

# === download ================================================================
funcDownload () {
  case "$1" in
    cfg ) funcDownload_cfg;;
    lnk ) funcDownload_lnk;;
    iso ) funcDownload_iso;;
    deb ) funcDownload_deb;;
    arc ) funcDownload_arc;;
  esac
  for D in cfg iso opt arc
  do
    if [ -d ./${D}/. ]; then
      find ./${D}/ -type d -exec chmod +rx {} \;
    fi
  done
}

# ### make initramfs and deb file #############################################
# === copy initrd and vmlinuz =================================================
# apt-cache depends package
# apt-cache rdepends package
# -----------------------------------------------------------------------------
funcCopy_initrd_and_vmlinuz () {
  echo "copy initrd and vmlinuz"
  mountpoint -q ./mnt/ && (umount -q -f ./mnt || umount -q -lf ./mnt) || true
  mountpoint -q ./usb/ && (umount -q -f ./usb || umount -q -lf ./usb) || true
  rm -rf ./mnt/
  rm -rf ./bld/
  rm -rf ./deb/
  mkdir -p ./mnt
  mkdir -p ./bld
  mkdir -p ./deb
  for P in $(find ./iso/ \( -name 'debian-*-amd64-netinst.iso'        \
                         -o -name 'ubuntu-2*-live-server-amd64.iso'   \
                         -o -name 'ubuntu-1*[!live]-server-amd64.iso' \) \
                      \( -type f -o -type l \))
  do
    mount -r -o loop ${P} ./mnt
    N=$(awk -F ' ' '{split($1,A,"-"); print tolower(A[1]);}' ./mnt/.disk/info)
    S=$(awk -F '"' '{split($2,A," "); print tolower(A[1]);}' ./mnt/.disk/info)
    case "${N}" in
      debian ) V=$(awk -F ' ' '{print tolower($3);}' ./mnt/.disk/info);;
      ubuntu ) V=$(awk -F ' ' '{print tolower($2);}' ./mnt/.disk/info);;
      *      ) V=""                                                               ;;
    esac
    case "${V}" in
      testing ) S="${V}";;
      *       )         ;;
    esac
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
    # *** modules *************************************************************
    M=(                    \
      libc-l10n_*          \
      libgcrypt20-udeb_*   \
      libgcrypt20_*        \
      libgnutls30_*        \
      libmount1-udeb_*     \
      libmount1_*          \
      libntfs-3g*          \
      libpcre3_*           \
      libselinux1-udeb_*   \
      libselinux1_*        \
      libsmartcols1-udeb_* \
      libsmartcols1_*      \
      libtinfo5_*          \
      libzstd1-udeb_*      \
      mount_*              \
      ntfs-3g-udeb_*       \
      ntfs-3g_*            \
      util-linux_*         \
      libaio1-udeb_*       \
      lvm2-udeb_*          \
    )
    case ${S} in
      stretch  ) M+=(fuse-udeb_* libfuse2-udeb_* );;
      buster   ) M+=(fuse-udeb_* libfuse2-udeb_* );;
      bullseye ) M+=(fuse-udeb_* libfuse2-udeb_* fuse3-udeb_* libfuse3-3-udeb_* );;
      bookworm ) M+=(fuse-udeb_* libfuse2-udeb_* fuse3-udeb_* libfuse3-3-udeb_* );;
      testing  ) M+=(fuse-udeb_* libfuse2-udeb_* fuse3-udeb_* libfuse3-3-udeb_* );;
      bionic   ) M+=(fuse-udeb_* libfuse2_* );;
      focal    ) ;;
      jammy    ) ;;
      kinetic  ) ;;
      lunar    ) ;;
      *        ) ;;
    esac
    # *** copy module *********************************************************
    for F in ${M[@]}
    do
      printf '  %-20.20s : %s\n' "${F}" "$(find ./mnt/pool/main/ -name "${F}" -type f -printf '%f' -exec cp -a -u '{}' ./deb/${S}/ \;)"
    done
    # *** linux image * *******************************************************
    find ./mnt/pool/ -regextype posix-basic -regex '.*/\(linux\|linux-signed\(-amd64\)*\)/linux-\(image\|modules\).*-[0-9]*-\(amd64\|generic\)*_.*' \
       -type f -printf '  linux image file     : %f\n' -exec cp -a '{}' ./deb/${S}/ \;
    umount ./mnt
  done
}

# === unpack deb file =========================================================
funcUnpack_deb_file () {
  echo "unpack deb file"
  rm -rf ./pac/
  rm -rf ./lnx/
  mkdir -p ./pac
  mkdir -p ./lnx
  for S in $(ls -1aA ./deb/)
  do
    find ./deb/${S}/ \(      -name 'linux-image-*_amd64.deb' -o      -name 'linux-modules-*_amd64.deb' \) -type f -printf "unpack %p\n" -exec mkdir -p ./pac/${S} \; -exec dpkg -x '{}' ./lnx/${S} \;
    find ./deb/${S}/ \( -not -name 'linux-image-*_amd64.deb' -a -not -name 'linux-modules-*_amd64.deb' \) -type f -printf "unpack %p\n" -exec mkdir -p ./pac/${S} \; -exec dpkg -x '{}' ./pac/${S} \;
  done
  for S in $(ls -1aA ./opt/)
  do
    find ./opt/${S}/ \(      -name 'linux-image-*_amd64.deb' -o      -name 'linux-modules-*_amd64.deb' \) -type f -printf "unpack %p\n" -exec mkdir -p ./pac/${S} \; -exec dpkg -x '{}' ./lnx/${S} \;
    find ./opt/${S}/ \( -not -name 'linux-image-*_amd64.deb' -a -not -name 'linux-modules-*_amd64.deb' \) -type f -printf "unpack %p\n" -exec mkdir -p ./pac/${S} \; -exec dpkg -x '{}' ./pac/${S} \;
  done
}

# === unpack arc file =========================================================
funcUnpack_arc_file () {
  echo "unpack arc file"
  rm -rf ./tmp/
  mkdir -p ./tmp
  for S in $(ls -1aA ./arc/)
  do
    mkdir -p ./tmp/${S}
    find ./arc/${S}/ -type f -printf "unpack %p\n" -exec tar -C ./tmp/${S}/ -xf {} \;
    # --- iso-scan and load-iso -----------------------------------------------
#    find ./tmp/${S}/ \( -name 'iso-scan.*' -o -name 'load-iso.*' \) -type f -printf "copy %p\n" -exec mkdir -p ./pac/${S}/var/lib/dpkg/info \; -exec cp -a --backup '{}' ./pac/${S}/var/lib/dpkg/info/ \;
  done
  rm -rf ./tmp/
}

# === unpack initramfs ========================================================
funcUnpack_initramfs () {
  echo "unpack initramfs"
  rm -rf ./ram/
  mkdir -p ./ram
  for S in $(ls -1aA ./bld/)
  do
    case ${S} in
      testing  ) D="./cfg/installer-hd-media/${S}"        ;;
      bookworm ) D="./cfg/installer-hd-media/${S}"        ;;
      bullseye ) D="./cfg/installer-hd-media/${S}"        ;;
      buster   ) D="./cfg/installer-hd-media/${S}"        ;;
      stretch  ) D="./cfg/installer-hd-media/${S}"        ;;
      bionic   ) D="./cfg/installer-hd-media/${S}-updates";;
      *        ) D="./bld/${S}";;
    esac
    find ${D}/ -maxdepth 1 -name 'initrd*' -type f -printf "unpack %p\n" -exec mkdir -p ./ram/${S} \; -exec unmkinitramfs '{}' ./ram/${S} \;
  done
}

# === copy and make kernel module =============================================
funcCopy_and_make_kernel_module () {
  echo "copy and make kernel module"
  rm -rf ./wrk/
  mkdir -p ./wrk
  for S in $(ls -1aA ./ram/)
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
      for O in $(ls -1aA ./pac/${S}/)
      do
        cp -a --backup ./pac/${S}/${O}/. ./wrk/${S}/${O}/
      done
    fi
    V=$(find ./wrk/${S}/lib/modules/*/kernel/ -name 'fs' -type d | sed -e 's~^.*/modules/\(.*\)/kernel/.*$~\1~g')
    if [ -d ./lnx/${S}/. ]; then
      M=( \
        kernel/crypto        \
        kernel/drivers/block \
        kernel/drivers/md    \
        kernel/fs/exfat      \
        kernel/fs/ext4       \
        kernel/fs/fat        \
        kernel/fs/fuse       \
        kernel/fs/fuse3      \
        kernel/fs/jbd2       \
        kernel/fs/ntfs       \
        kernel/fs/ntfs3      \
        kernel/lib           \
      )
      for T in ${M[@]}
      do
        if [ -d ./lnx/${S}/lib/modules/${V}/${T}/. ]; then
          cp -a --backup ./lnx/${S}/lib/modules/${V}/${T} ./wrk/${S}/lib/modules/${V}/$(dirname ${T})
        fi
      done
    fi
    if [ -d ./wrk/${S}/lib/modules/${V}/. ]; then
      touch ./wrk/${S}/lib/modules/${V}/modules.builtin.modinfo
      depmod -a -b wrk/${S} ${V}
    fi
    if [ -f  ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst ]; then
      sed -i ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst    \
          -e 's/^\([[:space:]]*FS\)="\(.*\)".*$/\1="\2 fuse fuse3 exfat ntfs3"/'
    fi
#    if [ -d ./wrk/${S}/var/lib/dpkg/info/. ]; then
#      for P in $(find ./wrk/${S}/var/lib/dpkg/info/ \( -name 'cdrom-checker.*' -o -name 'cdrom-detect.*' -o -name 'load-cdrom.*' \) -type f)
#      do
#        echo "rename ${P}"
#        mv ${P} ${P}~
#      done
#    fi
    case ${S} in
      testing  ) ;;
      bookworm ) ;;
      bullseye ) ;;
      buster   ) ;;
      stretch  ) ;;
      bionic   )
        if [ -f  ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst ]; then
          OLD_IFS=${IFS}
          INS_ROW=$(
            sed -n -e '/^[[:space:]]*use_this_iso[[:space:]]*([[:space:]]*)/,/^[[:space:]]*}$/ {/[[:space:]]*mount .* \/cdrom/=}' \
              ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst
          )
          IFS= INS_STR=$(
            cat <<- '_EOT_' | sed -e 's/^ //g' | sed -z -e 's/\n/\\n/g'
			 	#
			 	local ram=$(grep ^MemAvailable: /proc/meminfo | { read label size unit; echo ${size:-0}; })
			 	local iso_size=$(ls -sk /hd-media/$iso_to_try | { read size filename; echo ${size:-0}; })
			 	#
			 	cd /
			 	if [ $(( $iso_size + 100000 )) -lt $ram ]; then
			 		# We have enough RAM to be able to copy the ISO to RAM,
			 		# let's offer it to the user
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
          sed -i ./wrk/${S}/var/lib/dpkg/info/iso-scan.postinst                                                           \
              -e '/^[[:space:]]*use_this_iso[[:space:]]*([[:space:]]*/,/^}$/ s~^\([[:space:]]*mount .* /cdrom .*$\)~#\1~' \
              -e "${INS_ROW:-1}a \\${INS_STR}"
          cat <<- '_EOT_' >> ./wrk/${S}/var/lib/dpkg/info/iso-scan.templates
			
			Template: iso-scan/copy_iso_to_ram
			Type: boolean
			Default: false
			Description: Copy the ISO image to a ramdisk with enough space?
			Description-ja.UTF-8: ISO イメージを十分な容量のある RAM ディスクにコピーしますか?
_EOT_
        fi
        ;;
      focal    | \
      jammy    | \
      kinetic  | \
      lunar    )
#       mkdir -p ./wrk/${S}/dev/.initramfs
        if [ -f  ./wrk/${S}/scripts/casper-helpers ]; then
          OLD_IFS=${IFS}
          INS_ROW=$(
            sed -n -e '/^[[:space:]]*find_files[[:space:]]*([[:space:]]*)/,/^[[:space:]]*}$/ {/[[:space:]]*vfat|ext2)/,/.*;;$/=}' \
              ./wrk/${S}/scripts/casper-helpers                                                                                   \
              | awk 'END {print}'
          )
          IFS= INS_STR=$(
            cat <<- '_EOT_' | sed -e 's/^ //g' | sed -z -e 's/\n/\\n/g'
			                 exfat|ntfs)
			                     :;;
_EOT_
        )
          IFS=${OLD_IFS}
          sed -i ./wrk/${S}/scripts/casper-helpers                                                                                        \
              -e '/[[:space:]]*is_supported_fs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ s/\(vfat.*\))/\1|exfat)/'                      \
              -e '/[[:space:]]*wait_for_devs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ {/touch/i \\    mkdir -p /dev/.initramfs' -e '}' \
              -e "${INS_ROW:-1}a \\${INS_STR}"
        fi
        if [ -f  ./wrk/${S}/scripts/lupin-helpers ]; then
          sed -i ./wrk/${S}/scripts/lupin-helpers                                                                                         \
              -e '/[[:space:]]*is_supported_fs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ s/\(vfat.*\))/\1|exfat)/'                      \
              -e '/[[:space:]]*wait_for_devs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ {/touch/i \\    mkdir -p /dev/.initramfs' -e '}'
        fi
        ;;
      *        ) ;;
    esac
    if [ -f ./wrk/${S}/etc/lsb-release ]; then
      sed -i ./wrk/${S}/etc/lsb-release                      \
          -e 's/^\(X_INSTALLATION_MEDIUM\)=.*$/\1=hd-media/'
    fi
  done
}

# === make initramfs ==========================================================
funcMake_initramfs () {
  echo "make initramfs"
  rm -rf ./ird/
  mkdir -p ./ird
  # COMPRESS: [ gzip | bzip2 | lz4 | lzma | lzop | xz | zstd ]
  # COMPRESSLEVEL: ...
  # Valid values are:
  # 1 -  9 for gzip|bzip2|lzma|lzop
  # 0 -  9 for  lz4|xz
  # 0 - 19 for zstd
  for S in $(ls -1aA ./ram/)
  do
    O=$(pwd)
    pushd ./wrk/${S} > /dev/null
      printf "make initramfs : %-8.8s : %s\n" ${S} ${O}/ird/initrd-${S}.img
      find . -name '*~' -prune -o -print | cpio -R 0:0 -o -H newc --quie | gzip -c > ${O}/ird/initrd-${S}.img
    popd > /dev/null
  done
  ls -lh ./ird/
# rm -rf ./wrk/*
}

# === copy initramfs ==========================================================
funcCopy_initramfs () {
  echo "copy initramfs"
  rm -rf ./img/
  mkdir -p ./img
  for F in $(ls -1aA ./ird/)
  do
    echo "copy ${F}"
    S=$(echo ${F} | sed -e "s/^.*-\(.*\)\..*$/\1/g")
    case ${S} in
      testing  ) D="./cfg/installer-hd-media/${S}"        ;;
      bookworm ) D="./cfg/installer-hd-media/${S}"        ;;
      bullseye ) D="./cfg/installer-hd-media/${S}"        ;;
      buster   ) D="./cfg/installer-hd-media/${S}"        ;;
      stretch  ) D="./cfg/installer-hd-media/${S}"        ;;
      bionic   ) D="./cfg/installer-hd-media/${S}-updates";;
      *        ) D="./bld/${S}";;
    esac
    case ${S} in
      stretch  | \
      buster   | \
      bullseye | \
      bookworm | \
      testing  )
        mkdir -p ./img/install.amd/debian/${S}
        cp -a -L -u ./bld/${S}/.  ./img/install.amd/debian/${S}/
        cp -a -L -u ./ird/${F}    ./img/install.amd/debian/${S}/initrd.img
        cp -a -L -u ${D}/vmlinuz* ./img/install.amd/debian/${S}/vmlinuz.img
        ;;
      bionic   | \
      focal    | \
      jammy    | \
      kinetic  | \
      lunar    )
        mkdir -p ./img/install.amd/ubuntu/${S}
        cp -a -L -u ./bld/${S}/.  ./img/install.amd/ubuntu/${S}/
        cp -a -L -u ./ird/${F}    ./img/install.amd/ubuntu/${S}/initrd.img
        cp -a -L -u ${D}/vmlinuz* ./img/install.amd/ubuntu/${S}/vmlinuz.img
        ;;
      *        )
        ;;
    esac
  done
}

# ### make copy image #########################################################
funcMake_copy_image () {
  # === make directory ========================================================
  echo "make directory"
  mkdir -p ./img/images         \
           ./img/preseed/debian \
           ./img/preseed/ubuntu \
           ./img/nocloud
  # === copy config file ======================================================
# cp -a -L -u ./cfg/debian/preseed.cfg                    ./img/preseed/debian/
  cp -a -L -u ./cfg/debian/sub_late_command.sh            ./img/preseed/debian/
# cp -a -L -u ./cfg/ubuntu.desktop/preseed.cfg            ./img/preseed/ubuntu/
  cp -a -L -u ./cfg/ubuntu.desktop/sub_late_command.sh    ./img/preseed/ubuntu/
  cp -a -L -u ./cfg/ubuntu.desktop/sub_success_command.sh ./img/preseed/ubuntu/
# cp -a -L -u ./cfg/ubuntu.server/user-data               ./img/nocloud/
# touch ./img/nocloud/meta-data
# touch ./img/nocloud/vendor-data
# touch ./img/nocloud/network-config
  # === change config file ====================================================
  echo "change config file"
  sed -e 's~ /cdrom/preseed/~ /hd-media/preseed/debian/~g' ./cfg/debian/preseed.cfg         | tee ./img/preseed/debian/preseed.cfg > /dev/null
  sed -e 's~ /cdrom/preseed/~ /hd-media/preseed/ubuntu/~g' ./cfg/ubuntu.desktop/preseed.cfg | tee ./img/preseed/ubuntu/preseed.cfg > /dev/null
# sed -e 's/bind9-utils/bind9utils/'                                                                    \
#     -e 's/bind9-dnsutils/dnsutils/'                                                                   \
#     -e 's~\(^[[:space:]]*d-i[[:space:]]*mirror/http/hostname\).*$~\1 string archive.debian.org~'      \
#     -e 's~\(^[[:space:]]*d-i[[:space:]]*mirror/http/mirror select\).*$~\1 select archive.debian.org~' \
#     -e 's~\(^[[:space:]]*d-i[[:space:]]*apt-setup/services-select\).*$~\1 multiselect updates~'       \
#     -e 's~\(^[[:space:]]*d-i[[:space:]]*apt-setup/security_host\).*$~\1 string archive.debian.org~'   \
#            ./img/preseed/debian/preseed.cfg                                                           \
# | tee ./img/preseed/debian/preseed_oldold.cfg > /dev/null
  sed -e 's/bind9-utils/bind9utils/'                          \
      -e 's/bind9-dnsutils/dnsutils/'                         \
             ./img/preseed/debian/preseed.cfg                 \
  | tee ./img/preseed/debian/preseed_old.cfg > /dev/null
  sed -e 's/bind9-utils/bind9utils/'                          \
      -e 's/bind9-dnsutils/dnsutils/'                         \
      -e '/d-i partman\/unmount_active/ s/^#/ /g'             \
      -e '/d-i partman\/early_command/,/exit 0/ s/^#/ /g'     \
             ./img/preseed/ubuntu/preseed.cfg                 \
  | tee ./img/preseed/ubuntu/preseed_old.cfg > /dev/null
# === copy iso file ===========================================================
  echo "copy iso file"
  M=( \
    debian-testing-amd64-netinst.iso         \
    debian-bookworm-DI-rc2-amd64-netinst.iso \
    debian-11.7.0-amd64-netinst.iso          \
    debian-10.13.0-amd64-netinst.iso         \
    ubuntu-23.04-live-server-amd64.iso       \
    ubuntu-22.10-live-server-amd64.iso       \
    ubuntu-22.04.2-live-server-amd64.iso     \
    ubuntu-20.04.6-live-server-amd64.iso     \
    ubuntu-18.04.6-server-amd64.iso          \
    debian-live-bkworm-DI-rc2-amd64-lxde.iso \
    ubuntu-23.04-desktop-amd64.iso           \
#   debian-9.13.0-amd64-netinst.iso          \
#   ubuntu-18.04.6-live-server-amd64.iso     \
#   ubuntu-23.04-desktop-amd64.iso           \
#   ubuntu-22.10-desktop-amd64.iso           \
#   ubuntu-22.04.2-desktop-amd64.iso         \
#   ubuntu-20.04.6-desktop-amd64.iso         \
#   ubuntu-18.04.6-desktop-amd64.iso         \
  )
  for F in ${M[@]}
  do
    echo "copy ${F}"
    cp -a -L -u ./iso/${F} ./img/images/
  done
}

# ### USB Device: partition and format ########################################
funcUSB_Device_partition_and_format () {
  # *** [ USB device: /dev/sdb ] ***
  # === device and mount check ================================================
  echo "device and mount check"
  lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
  while :
  do
    if [ -b /dev/sdb ]; then
      break
    fi
    echo "device not found"
    lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sd[a-z]
    echo "enter Ctrl+C"
    read DUMMY
  done
  while :
  do
    echo "erase /dev/sdb? (YES or Ctrl-C)"
    read DUMMY
    if [ "${DUMMY}" = "YES" ]; then
      break
    fi
  done
  lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
  mountpoint -q ./usb/ && (umount -q -f ./usb || umount -q -lf ./usb) || true
  # === partition =============================================================
  echo "partition"
  sfdisk --wipe always --wipe-partitions always /dev/sdb <<- _EOT_
	label: gpt
	first-lba: 34
	start=34, size=  2014, type=21686148-6449-6E6F-744E-656564454649, attrs="GUID:62,63"
	start=  , size=256MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
	start=  , size=  4GiB, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
	start=  , size=      , type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
_EOT_
  sleep 3
  sync
  # === format ================================================================
  echo "format"
  mkfs.vfat -F 32              /dev/sdb2
  mkfs.vfat -F 32 -n "CIDATA"  /dev/sdb3
  mkfs.exfat      -n "ISOFILE" /dev/sdb4
# mkfs.ntfs -Q    -L "ISOFILE" /dev/sdb4
  sleep 3
  sync
  lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
}

# ### USB Device: [ /dev/sdX1, /dev/sdX2 ] Boot and EFI partition #############
funcUSB_Device_Boot_and_EFI_partition () {
  # *** [ USB device: /dev/sdb1, /dev/sdb2 ] ***
  # === mount /dev/sdX2 =======================================================
  echo "mount /dev/sdX2"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb2 ./usb/
  # === install boot loader ===================================================
  echo "install boot loader"
  grub-install --target=i386-pc    --recheck   --boot-directory=./usb/boot /dev/sdb
  grub-install --target=x86_64-efi --removable --boot-directory=./usb/boot --efi-directory=./usb
  # === make .disk directory ==================================================
  echo "make .disk directory"
  mkdir -p ./usb/.disk
  touch ./usb/.disk/info
  # === grub.cfg ==============================================================
  echo "grub.cfg"
  cat <<- '_EOT_' | tee ./usb/boot/grub/grub.cfg > /dev/null
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

	menuentry 'Unattended installation (Debian testing)' {
	    set gfxpayload=keep
	    set isofile="/images/debian-testing-amd64-netinst.iso"
	    set isoscan="${isofile} (testing)"
	    set isodist="debian/bookworm"
	    set preseed="/hd-media/preseed/debian/preseed.cfg"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Unattended installation (Debian 12:bookworm)' {
	    set gfxpayload=keep
	    set isofile="/images/debian-bookworm-DI-rc2-amd64-netinst.iso"
	    set isoscan="${isofile} (testing)"
	    set isodist="debian/bookworm"
	    set preseed="/hd-media/preseed/debian/preseed.cfg"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Unattended installation (Debian 11:bullseye)' {
	    set gfxpayload=keep
	    set isofile="/images/debian-11.7.0-amd64-netinst.iso"
	    set isoscan="${isofile} (stable - 11.7)"
	    set isodist="debian/bullseye"
	    set preseed="/hd-media/preseed/debian/preseed.cfg"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Unattended installation (Debian 10:buster)' {
	    set gfxpayload=keep
	    set isofile="/images/debian-10.13.0-amd64-netinst.iso"
	    set isoscan="${isofile} (oldstable - 10.13)"
	    set isodist="debian/buster"
	    set preseed="/hd-media/preseed/debian/preseed_old.cfg"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Unattended installation (Ubuntu 23.04:Lunar Lobster)' {
	    set gfxpayload=keep
	    set isofile="/images/ubuntu-23.04-live-server-amd64.iso"
	    set isoscan="iso-scan/filename=${isofile}"
	    set isodist="ubuntu/lunar"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=0 ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Unattended installation (Ubuntu 22.10:Kinetic Kudu)' {
	    set gfxpayload=keep
	    set isofile="/images/ubuntu-22.10-live-server-amd64.iso"
	    set isoscan="iso-scan/filename=${isofile}"
	    set isodist="ubuntu/kinetic"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=0 ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Unattended installation (Ubuntu 22.04:Jammy Jellyfish)' {
	    set gfxpayload=keep
	    set isofile="/images/ubuntu-22.04.2-live-server-amd64.iso"
	    set isoscan="iso-scan/filename=${isofile}"
	    set isodist="ubuntu/jammy"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=0 ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Unattended installation (Ubuntu 20.04:Focal Fossa)' {
	    set gfxpayload=keep
	    set isofile="/images/ubuntu-20.04.6-live-server-amd64.iso"
	    set isoscan="iso-scan/filename=${isofile}"
	    set isodist="ubuntu/focal"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=0 ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Unattended installation (Ubuntu 18.04:Bionic Beaver)' {
	    set gfxpayload=keep
	    set isofile="/images/ubuntu-18.04.6-server-amd64.iso"
	    set isoscan="${isofile} (bionic - 18.04)"
	    set isodist="ubuntu/bionic"
	    set preseed="/hd-media/preseed/ubuntu/preseed_old.cfg"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	submenu 'Live media ...' {
	    search.fs_label "CIDATA"  cfgpart hd1,gpt3
	    search.fs_label "ISOFILE" isopart hd1,gpt4
	    set menu_color_normal=cyan/blue
	    set menu_color_highlight=white/blue
	#    menuentry 'Live system (Debian 12:testing [bookworm])' {
	#        set gfxpayload=keep
	#        set isofile="/images/debian-live-bkworm-DI-rc2-amd64-lxde.iso"
	#        set isoscan="${isofile} (testing)"
	#        set isodist="debian/bookworm"
	#        set preseed="/hd-media/preseed/debian/preseed.cfg"
	#        set locales="locale=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	#        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	#        echo "Loading ${isofile} ..."
	#        linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img boot=live components quiet splash findiso=${isofile} ${locales} fsck.mode=skip
	#        initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	#    }
	#    menuentry 'Live system (Ubuntu 23.04:Lunar Lobster)' {
	#        set gfxpayload=keep
	#        set isofile="/images/ubuntu-23.04-desktop-amd64.iso"
	#        set isoscan="iso-scan/filename=${isofile}"
	#        set isodist="ubuntu/lunar"
	#        set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	#        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	#        echo "Loading ${isofile} ..."
	#        linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img layerfs-path=minimal.standard.live.squashfs --- quiet splash ${isoscan} ${locales} fsck.mode=skip
	#        initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	#    }
	}
	menuentry "System shutdown" {
	    echo "System shutting down ..."
	    halt
	}
	menuentry "System restart" {
	    echo "System rebooting ..."
	    reboot
	}
_EOT_
  # === unmount ===============================================================
  echo "unmount"
  umount ./usb/
}

# ### USB Device: [ /dev/sdX3 ] Data partition ################################
funcUSB_Device_Inst_File_partition () {
  # *** [ USB device: /dev/sdb3 ] ***
  # === mount /dev/sdX3 =======================================================
  echo "mount /dev/sdX3"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb3 ./usb/
  # === copy boot loader and setting files ====================================
  echo "copy boot loader and setting files"
  cp --preserve=timestamps -u -r ./img/install.amd/ ./usb/
  cp --preserve=timestamps -u    ./cfg/ubuntu.server/user-data ./usb/
  touch ./usb/meta-data
  touch ./usb/vendor-data
  touch ./usb/network-config
  # === unmount ===============================================================
  echo "unmount"
  umount ./usb/
}

# ### USB Device: [ /dev/sdX4 ] Data partition ################################
funcUSB_Device_Data_File_partition () {
  # *** [ USB device: /dev/sdb4 ] ***
  # === mount /dev/sdX4 =======================================================
  echo "mount /dev/sdX4"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb4 ./usb/
  # === copy iso files ========================================================
  echo "copy iso files"
  cp --preserve=timestamps -u -r ./img/images/  ./usb/
  cp --preserve=timestamps -u -r ./img/nocloud/ ./usb/
  cp --preserve=timestamps -u -r ./img/preseed/ ./usb/
  # === unmount ===============================================================
  umount ./usb
  echo "unmount"
  lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
}

# ### main ####################################################################
main () {
  if [ "$(whoami)" != "root" ]; then
    echo "execute as root user."
    exit 1
  fi
  echo "$(date +"%Y/%m/%d %H:%M:%S") processing start"
  funcDownload "cfg"
  funcDownload "lnk"
  funcDownload "iso"
  funcDownload "deb"
  funcDownload "arc"
  funcCopy_initrd_and_vmlinuz
  funcUnpack_deb_file
  funcUnpack_arc_file
  funcUnpack_initramfs
  funcCopy_and_make_kernel_module
  funcMake_initramfs
  funcCopy_initramfs
  funcMake_copy_image
  funcUSB_Device_partition_and_format
  funcUSB_Device_Boot_and_EFI_partition
  funcUSB_Device_Inst_File_partition
  funcUSB_Device_Data_File_partition
  echo "complete"
  echo "$(date +"%Y/%m/%d %H:%M:%S") processing end"
}

# === main ====================================================================
main
# =============================================================================
# https://deb.debian.org/debian/pool/main/n/ntfs-3g/ntfs-3g_2022.10.3-1+b1_amd64.deb
# https://deb.debian.org/debian/pool/main/f/fuse3/fuse3_3.14.0-3_amd64.deb
# https://deb.debian.org/debian/pool/main/f/fuse/fuse_2.9.9-6+b1_amd64.deb
# ### eof #####################################################################
