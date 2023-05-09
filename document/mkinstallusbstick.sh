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
  dpkg -l fdisk coreutils curl dosfstools grub2-common initramfs-tools-core cpio gzip bzip2 lz4 lzma lzop xz-utils zstd
# apt-get install fdisk coreutils curl dosfstools grub2-common initramfs-tools-core cpio gzip bzip2 lz4 lzma lzop xz-utils zstd

# -----------------------------------------------------------------------------
ROW_SIZE=25
COL_SIZE=80

# ### common function #########################################################
# --- is integer --------------------------------------------------------------
fncIsInt () {
  set +e
  expr ${1:-""} + 1 > /dev/null 2>&1
  if [ $? -ge 2 ]; then echo 1; else echo 0; fi
  set -e
}

# --- string output -----------------------------------------------------------
fncString () {
  local OLD_IFS=${IFS}
  IFS=$'\n'
  if [ "$2" = " " ]; then
    echo $1      | awk '{s=sprintf("%"$1"."$1"s"," "); print s;}'
  else
    echo $1 "$2" | awk '{s=sprintf("%"$1"."$1"s"," "); gsub(" ",$2,s); print s;}'
  fi
  IFS=${OLD_IFS}
}

# --- print with screen control -----------------------------------------------
fncPrintf () {
  local RET_STR=""
  local INP_STR=""
  local OUT_STR=""
  local MAX_COLS=$((COL_SIZE-1))
  local OLD_IFS=${IFS}
  INP_STR="$@"
  IFS=$'\n'
  OUT_STR="$(printf $@)"
  RET_STR="$(echo -n "${OUT_STR}" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null)"
  if [ $? -ne 0 ]; then
    MAX_COLS=$((COL_SIZE-2))
    RET_STR="$(echo -n "${OUT_STR}" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null)"
  fi
  echo "${RET_STR}"
  IFS=${OLD_IFS}
}

# --- download ----------------------------------------------------------------
funcCurl ()
{
  P="$@"
  U=$(echo ${P} | sed -n -e 's~^.* \(\(http\|https\)://.*\)$~\1~p')
  O=$(echo ${P} | sed -n -e 's~^.* --output-dir *\(.*\) .*$~\1~p' | sed -e 's~/$~~')
  OLD_IFS=${IFS}
  IFS=
  set +e
  H=($(curl --location --no-progress-bar --head --remote-time --show-error --silent --fail "${U}" 2> /dev/null))
  R=$?
  set -e
  if [ ${R} -eq 18 -o ${R} -eq 22 -o ${R} -eq 28  ]; then
    E=$(echo ${H[@]} | sed -n '/^HTTP/p' | sed -z 's/\n\|\r\|\l//g')
    fncPrintf "${E}: ${U}"
    return ${R}
  fi
  S=$(echo ${H[@],,} | sed -n -e '/^content-length:/ s/^.*: //p' | sed -z 's/\n\|\r\|\l//g')
  T=$(TZ=UTC date -d "$(echo ${H[@],,} | sed -n -e '/^last-modified:/ s/^.*: //p')" "+%Y%m%d%H%M%S")
  IFS=${OLD_IFS}
  F="${O:-.}/$(basename ${U})"
  if [ -f ${F} ]; then
    I=$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "${F}")
    D=$(echo ${I} | awk '{print $6;}')
    L=$(echo ${I} | awk '{print $5;}')
    if [ ${T:-0} -eq ${D:-0} ] && [ ${S:-0} -eq ${L:-0} ]; then
      fncPrintf "same file: ${F}"
      return 0
    fi
  fi
  fncPrintf "get  file: ${F}"
  curl ${P}
  return $?
}

# === download: cfg file ======================================================
funcDownload_cfg () {
  # ### download: setting file ################################################
# rm -rf ./cfg/
  mkdir -p ./cfg
  # === setting file ==========================================================
  fncPrintf "setting file"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/debian"                                     "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/debian/preseed.cfg"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/debian"                                     "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/debian/sub_late_command.sh"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                             "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/preseed.cfg"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                             "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/sub_late_command.sh"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                             "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/sub_success_command.sh"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.server"                              "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.server/user-data"
}

# === download: debian installer ==============================================
funcDownload_bld () {
  # ### download: debian installer ############################################
  # === stretch ===============================================================
# fncPrintf "stretch"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/boot.img.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/initrd.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/vmlinuz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch/gtk"      "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch/gtk"      "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === buster ================================================================
  fncPrintf "buster"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster/gtk"       "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster/gtk"       "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === bullseye ==============================================================
  fncPrintf "bullseye"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye/gtk"     "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye/gtk"     "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === bookworm ==============================================================
  fncPrintf "bookworm"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm/gtk"     "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm/gtk"     "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === testing ===============================================================
  fncPrintf "testing"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing/gtk"      "https://d-i.debian.org/daily-images/amd64/daily/hd-media/gtk/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing/gtk"      "https://d-i.debian.org/daily-images/amd64/daily/hd-media/gtk/vmlinuz"
  # === bionic ================================================================
  fncPrintf "bionic"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/boot.img.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/initrd.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/vmlinuz"
  # === focal =================================================================
  fncPrintf "focal"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/boot.img.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/initrd.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/vmlinuz"
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
  mkdir -p ./iso
  # ::: debian mini.iso :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# fncPrintf "debian mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-stretch-amd64.iso"                               "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-buster-amd64.iso"                                "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-bullseye-amd64.iso"                              "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-bookworm-amd64.iso"                              "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-testing-amd64.iso"                               "https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso"
  # ::: debian netinst ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "debian netinst"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-cd/debian-9.13.0-amd64-netinst.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/10.13.0/amd64/iso-cd/debian-10.13.0-amd64-netinst.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-11.7.0-amd64-netinst.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/bookworm_di_rc2/amd64/iso-cd/debian-bookworm-DI-rc2-amd64-netinst.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso"
  # ::: debian DVD ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# fncPrintf "debian DVD"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-dvd/debian-9.13.0-amd64-DVD-1.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/10.13.0/amd64/iso-dvd/debian-10.13.0-amd64-DVD-1.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-11.7.0-amd64-DVD-1.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/bookworm_di_rc2/amd64/iso-dvd/debian-bookworm-DI-rc2-amd64-DVD-1.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso"
  # ::: debian live DVD :::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "debian live DVD"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/9.13.0-live/amd64/iso-hybrid/debian-live-9.13.0-amd64-lxde.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/10.13.0-live/amd64/iso-hybrid/debian-live-10.13.0-amd64-lxde.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-11.7.0-amd64-lxde.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/bookworm_di_rc2-live/amd64/iso-hybrid/debian-live-bkworm-DI-rc2-amd64-lxde.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso"
  # ::: ubuntu mini.iso :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# fncPrintf "ubuntu mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-bionic-amd64.iso"                                "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-focal-amd64.iso"                                 "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso"
  # ::: ubuntu server :::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "ubuntu server"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04.6-server-amd64.iso"
  # ::: ubuntu live server ::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "ubuntu live server"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/bionic/ubuntu-18.04.6-live-server-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/focal/ubuntu-20.04.6-live-server-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/kinetic/ubuntu-22.10-live-server-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/lunar/ubuntu-23.04-live-server-amd64.iso"
  # ::: ubuntu desktop ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# fncPrintf "ubuntu desktop"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/bionic/ubuntu-18.04.6-desktop-amd64.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/focal/ubuntu-20.04.6-desktop-amd64.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-desktop-amd64.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/kinetic/ubuntu-22.10-desktop-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/lunar/ubuntu-23.04-desktop-amd64.iso"
}

# === download: deb file ======================================================
funcDownload_deb () {
# rm -rf ./opt/
  mkdir -p ./opt
  # ::: linux image :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "linux image"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.testing"                             "https://deb.debian.org/debian/pool/main/l/linux-signed-amd64/linux-image-6.1.0-8-amd64_6.1.25-1_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar.desktop"                       "http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-extra-6.2.0-20-generic_6.2.0-20.20_amd64.deb"
  # ::: exfat :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "exfat"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.stretch"                             "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.2.5-2_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.buster"                              "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0-1_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.bullseye"                            "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0-2_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.bookworm"                            "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0+git20220115-2_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.testing"                             "https://deb.debian.org/debian/pool/main/f/fuse-exfat/exfat-fuse_1.3.0+git20220115-2_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.bionic"                              "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.2.8-1_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.focal"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.3.0-1_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.jammy"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.3.0+git20220115-2_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.kinetic"                             "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.3.0+git20220115-2_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.4.0-1_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.mantic"                              "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse-exfat/exfat-fuse_1.4.0-1_amd64.deb"
  # ::: libfuse2 ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "libfuse2"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/libfuse2-udeb_2.9.9-3_amd64.udeb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/libfuse2_2.9.9-3_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.jammy"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/libfuse2_2.9.9-5ubuntu3_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.kinetic"                             "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/libfuse2_2.9.9-5ubuntu3_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/libfuse2_2.9.9-6_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.mantic"                              "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/libfuse2_2.9.9-6_amd64.deb"
  # ::: fuse3 :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "fuse3"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar.desktop"                       "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/fuse3_3.14.0-3_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar.desktop"                       "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/libfuse3-3_3.14.0-3_amd64.deb"
  # ::: mount :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "mount"
  # --- debian.bookworm.live --------------------------------------------------
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.bookworm.live"                       "https://deb.debian.org/debian/pool/main/u/util-linux/mount_2.38.1-5+b1_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.bookworm.live"                       "https://deb.debian.org/debian/pool/main/u/util-linux/libmount1-udeb_2.38.1-5+b1_amd64.udeb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.bookworm.live"                       "https://deb.debian.org/debian/pool/main/u/util-linux/libmount1_2.38.1-5+b1_amd64.deb"
  # --- ubuntu.bionic ---------------------------------------------------------
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.bionic"                              "http://archive.ubuntu.com/ubuntu/pool/main/u/util-linux/mount_2.31.1-0.4ubuntu3.7_amd64.deb"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.bionic"                              "http://archive.ubuntu.com/ubuntu/pool/main/u/util-linux/libmount1_2.31.1-0.4ubuntu3.7_amd64.deb"
  # ::: cruft-ng ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# fncPrintf "cruft-ng"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar"                               "http://archive.ubuntu.com/ubuntu/pool/universe/c/cruft-ng/cruft-ng_0.9.54_amd64.deb"
}

# === download: arc file ======================================================
funcDownload_arc () {
# rm -rf ./arc/
  mkdir -p ./arc
  fncPrintf "iso-scan"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./arc/debian.buster"                              "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.75.tar.xz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./arc/debian.bullseye"                            "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.85.tar.xz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./arc/debian.bookworm"                            "https://deb.debian.org/debian/pool/main/i/iso-scan/iso-scan_1.88.tar.xz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./arc/ubuntu.bionic"                              "http://archive.ubuntu.com/ubuntu/pool/main/i/iso-scan/iso-scan_1.55ubuntu5.tar.xz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./arc/ubuntu.focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/i/iso-scan/iso-scan_1.55ubuntu9.tar.xz"
}

# === download ================================================================
funcDownload () {
  case "$1" in
    cfg ) funcDownload_cfg;;
    bld ) funcDownload_bld;;
    lnk ) funcDownload_lnk;;
    iso ) funcDownload_iso;;
    deb ) funcDownload_deb;;
    arc ) funcDownload_arc;;
  esac
  for D in cfg iso opt arc
  do
    if [ -d ./${D}/. ]; then
      find ./${D}/ -type d -exec chmod +rx '{}' \;
    fi
  done
}

# ### make initramfs and deb file #############################################
# === copy module =============================================================
# apt-cache depends package
# apt-cache rdepends package
# -----------------------------------------------------------------------------
funcCopy_module () {
  fncPrintf "copy module"
  mountpoint -q ./mnt/ && (umount -q -f ./mnt || umount -q -lf ./mnt) || true
  mountpoint -q ./usb/ && (umount -q -f ./usb || umount -q -lf ./usb) || true
  rm -rf ./mnt/
  rm -rf ./bld/
  rm -rf ./deb/
  rm -rf ./tmp
  mkdir -p ./mnt
  mkdir -p ./bld
  mkdir -p ./deb
  mkdir -p ./tmp
  # *** modules ***************************************************************
  U=(                              \
    libaio1-udeb\\\(-udeb\\\)*_.*  \
    libblkid1\\\(-udeb\\\)*_.*     \
    libc-l10n\\\(-udeb\\\)*_.*     \
    libgcrypt20\\\(-udeb\\\)*_.*   \
    libgnutls30\\\(-udeb\\\)*_.*   \
    libmount1\\\(-udeb\\\)*_.*     \
#   libntfs-3g\\\(-udeb\\\)*_.*    \
    libpcre3\\\(-udeb\\\)*_.*      \
    libselinux1\\\(-udeb\\\)*_.*   \
    libsmartcols1\\\(-udeb\\\)*_.* \
    libtinfo5\\\(-udeb\\\)*_.*     \
    libzstd1\\\(-udeb\\\)*_.*      \
#   lvm2\\\(-udeb\\\)*_.*          \
    mount\\\(-udeb\\\)*_.*         \
#   ntfs-3g\\\(-udeb\\\)*_.*       \
#   util-linux\\\(-udeb\\\)*_.*    \
  )
  for P in $(find ./iso/ \( -name 'debian-*-amd64-netinst.iso'           \
                         -o -name 'ubuntu-2*-live-server-amd64.iso'      \
                         -o -name 'ubuntu-1*[!live]-server-amd64.iso'    \
                         -o -name 'debian-live-*-amd64-lxde.iso'         \
                         -o -name 'ubuntu-*-desktop-amd64.iso'        \) \
                      \( -type f -o -type l \))
  do
    # --- mount ---------------------------------------------------------------
    mount -r -o loop ${P} ./mnt
    # --- make directory ------------------------------------------------------
    R=$(cat ./mnt/.disk/info | sed -z 's/-n//g')
    N=$(echo ${R,,} | awk -F ' ' '{split($1,A,"-"); print A[1];}')
    S=$(echo ${R,,} | awk -F '"' '{split($2,A," "); print A[1];}')
    I=$(echo ${R,,} | sed -n -e 's/^.*\(live\|dvd\|netinst\|netboot\|server\).*$/\1/p')
    case "${N}" in
      debian ) V=$(echo ${R,,} | awk -F ' ' '{print $3;}');;
      ubuntu ) V=$(echo ${R,,} | awk -F ' ' '{print $2;}');;
      *      ) V=""                                       ;;
    esac
    case "${V}" in
      testing ) S="${V}";;
      *       )         ;;
    esac
    D="${N}.${S}.${I:-desktop}"
    fncPrintf "copy initrd: %-24.24s : %s\n" "${D}" "${P}"
    mkdir -p ./bld/${D}
    mkdir -p ./lnx/${D}
    mkdir -p ./deb/${D}
    # *** copy initrd and vmlinuz *********************************************
    L=""
    if [ -d ./mnt/install/.     ]; then L+="./mnt/install/ ";     fi
    if [ -d ./mnt/install.amd/. ]; then L+="./mnt/install.amd/ "; fi
    if [ -d ./mnt/live/.        ]; then L+="./mnt/live/" ;        fi
    if [ -d ./mnt/casper/.      ]; then L+="./mnt/casper/" ;      fi
    for F in $(find ${L} \( -name 'initrd*' -o  -name 'vmlinuz*' \) -type f)
    do
      fncPrintf "copy initrd: %-24.24s : %s\n" "${D}" "${F}"
      T="$(dirname ${F#\./mnt/})"
      mkdir -p ./bld/${D}/${T}
      cp -a ${F} ./bld/${D}/${T}/
    done
    # *** copy deb file *******************************************************
    T=($(find ./mnt/ -maxdepth 1 -name 'pool*' -type d))
    M=(${U[@]})
    case "${S%\.*}" in
      stretch  ) M+=(fuse\\\(-udeb\\\)*_.* libfuse2\\\(-udeb\\\)*_.* ntfs-3g\\\(-udeb\\\)*_.* );;
      buster   ) M+=(fuse\\\(-udeb\\\)*_.* libfuse2\\\(-udeb\\\)*_.* ntfs-3g\\\(-udeb\\\)*_.* );;
      bullseye ) M+=(fuse\\\(-udeb\\\)*_.* libfuse2\\\(-udeb\\\)*_.* ntfs-3g\\\(-udeb\\\)*_.* );;
      bookworm ) M+=(fuse\\\(-udeb\\\)*_.* libfuse2\\\(-udeb\\\)*_.* ntfs-3g\\\(-udeb\\\)*_.* );;
      testing  ) M+=(fuse\\\(-udeb\\\)*_.* libfuse2\\\(-udeb\\\)*_.* ntfs-3g\\\(-udeb\\\)*_.* );;
      bionic   ) M+=(fuse\\\(-udeb\\\)*_.* libfuse2\\\(-udeb\\\)*_.* );;
      focal    ) M+=(fuse\\\(-udeb\\\)*_.* libfuse2\\\(-udeb\\\)*_.* ntfs-3g\\\(-udeb\\\)*_.* );;
      jammy    ) M+=(fuse\\\(-udeb\\\)*_.* libfuse2\\\(-udeb\\\)*_.* ntfs-3g\\\(-udeb\\\)*_.* );;
      kinetic  ) M+=(fuse3\\\(-udeb\\\)*_.* );;
      lunar    ) M+=(fuse3\\\(-udeb\\\)*_.* );;
      *        ) ;;
    esac
    # *** copy module *********************************************************
    for F in ${M[@]}
    do
      B=""
      for P in $(find ${T[@]} -regextype posix-basic -regex ".*/${F}" -type f | sed -n '/\(all\|amd64\)/p' | sed -n "/\(${F%\\.*}_\|-udeb_\)/p")
      do
        B="$(basename ${P})"
        fncPrintf "copy module: %-24.24s : %s\n" "${F}" "${B}"
        if [ -n "${P}" ]; then
          cp -a -u ${P} ./deb/${D}/
        fi
      done
      if [ -z "${B}" ]; then
        fncPrintf "copy module: %-24.24s : %s\n" "${F}" "${B}"
      fi
    done
    # *** linux image *********************************************************
    fncPrintf "$(find ${T[@]} -regextype posix-basic -regex '.*/\(linux\|linux-signed\(-amd64\)*\)/linux-\(image\|modules\).*-[0-9]*-\(amd64\|generic\)*_.*' \
                  -type f -printf 'copy   limg: %f\n' -exec cp -a '{}' ./deb/${D}/ \;)"
    # *** packages file *******************************************************
    cp -a ./mnt/dists ./deb/${D}/
    # --- unmount -------------------------------------------------------------
    umount ./mnt
  done
}

# === unpack linux image ======================================================
funcUnpack_lnximg () {
  fncPrintf "unpack linux image"
  rm -rf ./pac
  mkdir -p ./pac
  for S in $(ls -1aA ./deb/)
  do
    D=""
    if [ -d ./deb/${S}/.     ]; then D+="./deb/${S}/ ";     fi
    if [ -d ./opt/${S%\.*}/. ]; then D+="./opt/${S%\.*}/ "; fi
    if [ -d ./opt/${S}/.     ]; then D+="./opt/${S}/ ";     fi
    for F in $(find ${D} \( -name 'linux-image-*_amd64.deb' -o -name 'linux-modules-*_amd64.deb' \) -type f)
    do
      fncPrintf "unpack limg: %-24.24s : %s\n" "${S}" "$(basename ${F})"
      mkdir -p ./pac/${S}
      dpkg -x ${F} ./pac/${S}
    done
  done
}

# === unpack module ===========================================================
funcUnpack_module () {
  fncPrintf "unpack module"
  rm -rf ./ram/
  rm -rf ./wrk/
  mkdir -p ./ram
  mkdir -p ./wrk
  for S in $(ls -1aA ./bld/)
  do
    # --- bld or cfg -> ram ---------------------------------------------------
    case "${S}" in
      debian.*.live        ) D="./bld/${S}/live"                          ;;
      debian.*             ) D="./cfg/installer-hd-media/${S%\.*}"        ;;
      ubuntu.bionic.server ) D="./cfg/installer-hd-media/${S%\.*}-updates";;
      ubuntu.*             ) D="./bld/${S}/casper"                        ;;
      *                    ) 
        if [ -d ./bld/${S}/install.amd/. ]; then
          D="./bld/${S}/install.amd"
        else
          D="./bld/${S}/install"
        fi
      ;;
    esac
    # --- unpack: inird -> ./ram/${S}/initrd ----------------------------------
    for W in 'initrd*-*' 'initrd*.*' 'initrd'
    do
      for F in $(find ${D} -name "${W}" -type f)
      do
        fncPrintf "unpack file: ${F}"
        mkdir -p ./ram/${S}/initrd
        unmkinitramfs ${F} ./ram/${S}/initrd
        break 2
      done
    done
    # --- copy: vmlinuz -> ./ram/${S}/vmlinuz ---------------------------------
    for W in 'vmlinuz*-*' 'vmlinuz*.*' 'vmlinuz'
    do
      for F in $(find ${D} -name "${W}" -type f)
      do
        fncPrintf "copy   file: ${F}"
        mkdir -p ./ram/${S}/vmlinuz
        cp -a ${F} ./ram/${S}/vmlinuz
        break 2
      done
    done
    # --- ram -> wrk ----------------------------------------------------------
    if [ -d ./ram/${S}/initrd/main/. ]; then
      D="./ram/${S}/initrd/main"
    else
      D="./ram/${S}/initrd"
    fi
    fncPrintf "copy     fs: ${D}"
    mkdir -p ./wrk/${S}/initrd
    cp -a ${D}/. ./wrk/${S}/initrd/
    # --- remove module -------------------------------------------------------
    case "${S}" in
      debian.*.live        )
        fncPrintf "remove module"
        M=( \
          usr/lib/finish-install.d/15cdrom-detect     \
          var/lib/dpkg/info/cdrom-checker.postinst    \
          var/lib/dpkg/info/cdrom-checker.templates   \
          var/lib/dpkg/info/cdrom-detect.postinst     \
          var/lib/dpkg/info/cdrom-detect.templates    \
          var/lib/dpkg/info/load-cdrom.postinst       \
          var/lib/dpkg/info/load-cdrom.templates      \
        )
        for T in ${M[@]}
        do
          if [ -f ./wrk/${S}/initrd/${T} ]; then
            fncPrintf "remove pack: ${T}"
            mv ./wrk/${S}/initrd/${T} ./wrk/${S}/initrd/${T}~
          fi
        done
        if [ -f ./wrk/${S}/initrd/var/lib/dpkg/status ]; then
          sed -i ./wrk/${S}/initrd/var/lib/dpkg/status   \
              -e '/Package: cdrom-checker/,/^$/d' \
              -e '/Package: cdrom-detect/,/^$/d'  \
              -e '/Package: load-cdrom/,/^$/d'
        fi
        ;;
      *                    )
        ;;
    esac
    # --- linux image -> wrk --------------------------------------------------
    if [ -d ./wrk/${S}/initrd/lib/modules/*/kernel/. ]; then
      V=$(find ./wrk/${S}/initrd/lib/modules/*/kernel/ -name 'fs' -type d | sed -e 's~^.*/modules/\(.*\)/kernel/.*$~\1~g')
    else
      V="$(find ./deb/${S}/ -name 'linux-image*' -type f | sed -n -e 's~^.*/linux-image-\(.*\)_.*_.*$~\1~p')"
      if [ -z "${V}" ]; then
        fncPrintf "failed to get kernel version, exiting process."
        exit 1
      fi
      mkdir -p ./wrk/${S}/initrd/lib/modules/${V}/kernel
    fi
    if [ -d ./pac/${S}/. ]; then
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
        if [ -d ./pac/${S}/lib/modules/${V}/${T}/. ]; then
          fncPrintf "copy module: ${T}"
          cp -a --backup ./pac/${S}/lib/modules/${V}/${T} ./wrk/${S}/initrd/lib/modules/${V}/$(dirname ${T})
        fi
      done
    fi
    # --- deb or opt -> wrk ---------------------------------------------------
    D=""
    if [ -d ./deb/${S}/.     ]; then D+="./deb/${S}/ ";     fi
    if [ -d ./opt/${S%\.*}/. ]; then D+="./opt/${S%\.*}/ "; fi
    if [ -d ./opt/${S}/.     ]; then D+="./opt/${S}/ ";     fi
    # --- dpkg --update-avail -------------------------------------------------
    fncPrintf "update package data base"
    if [ ! -f ./wrk/${S}/initrd/var/lib/dpkg/status ]; then
      mkdir -p ./wrk/${S}/initrd/var/lib/dpkg
      touch ./wrk/${S}/initrd/var/lib/dpkg/status
    fi
    for P in $(find ./deb/${S}/dists/ -name '*Packages*' -type f)
    do
      mkdir -p ./tmp
      cp -a ${P} ./tmp/
      if [ -f ./tmp/Packages.gz ]; then
        gzip -d ./tmp/Packages.gz
      fi
      LANG=C dpkg --root=./wrk/${S}/initrd --update-avail ./tmp/Packages 2>&1 | \
        grep -v 'parsing file' | grep -v 'missing '\''Architecture'\'' field' | grep -v 'missing '\''Maintainer'\'' field' | \
        grep -v 'field value' | grep -v 'warning: files list' | \
        grep -v 'Reading database' | grep -v 'Preparing' | \
        grep -v 'Updating' | grep -v 'Information'
      rm -rf ./tmp
    done
    # --- add package ---------------------------------------------------------
    fncPrintf "inst package"
    U=("")
    C=("")
    for P in $(find ${D} \
         \( -not -name 'linux-image-*_amd64.deb' -a -not -name 'linux-modules-*_amd64.deb' \
      -a \( -name '*.deb' -o -name '*.udeb' \) \) -type f | sed -n '/\(all\|amd64\)/p' | sort -u)
    do
      F="$(basename ${P})"
      M="${F%%_*}"
      W="${M}\\(-udeb\\)*"
      for A in ${U[@]}
      do
        B="$(basename ${A})"
        if [ "${F}"      = "${B}"     ] ||
           [ "${M}"      = "${B%%_*}" ] ||
           [ "${M}-udeb" = "${B%%_*}" ]; then
          continue 2
        fi
      done
      if [ -f ./ram/${S}/initrd/var/lib/dpkg/status ] && \
         [ -n "$(sed -n "/^Package: ${W}.*$/p" ./ram/${S}/initrd/var/lib/dpkg/status)" ]; then
        C+=("${P} ")
        continue
      fi
      T=$(echo ${P} | sed -n "/\/${M}\(-udeb\)*_/p")
      if [ -n "${T}" ]; then
        fncPrintf "inst   pack: ${F}"
        U+=("${T} ")
        C+=("${T} ")
      fi
    done
    # --- copy package --------------------------------------------------------
    fncPrintf "copy package"
    for P in ${C[@]}
    do
      F="$(basename ${P})"
      M="${F%%_*}"
      case "${M}" in
        mount*     | \
        libmount1* )
          if [ -f ./wrk/${S}/initrd/bin/mount ]; then
            if [ "$(readlink -q ./wrk/${S}/initrd/bin/mount)" != "busybox" ]; then
              Z=(${U[@]/${P}})
              U=(${Z[@]})
            else
              fncPrintf "copy   pack: ${F}"
              mkdir -p ./tmp
              dpkg -x ${P} ./tmp
              for T in $(ls ./tmp/)
              do
                cp -a --backup ./tmp/${T}/. ./wrk/${S}/initrd/${T}
              done
              rm -rf ./tmp
            fi
          fi
          ;;
        * )
          ;;
      esac
    done
    # --- unpack package ------------------------------------------------------
    fncPrintf "unpack package"
#set +e
    sed -i ./wrk/${S}/initrd/var/lib/dpkg/status                                             \
        -e '/^Package: debian-installer$/,/^Package:/ s/\(Version:\) \(.*\)/\1 1:\2/'
    LANG=C dpkg --root=./wrk/${S}/initrd --unpack ${U[@]} 2>&1 | \
      grep -v 'parsing file' | grep -v 'missing '\''Architecture'\'' field' | grep -v 'missing '\''Maintainer'\'' field' | \
      grep -v 'field value' | grep -v 'warning: files list' | \
      grep -v 'Reading database' | grep -v 'Preparing' | \
      grep -v 'Selecting'
#set -e
    # --- unpack arc file -----------------------------------------------------
    case "${S}" in
      debian.*.live        )
        fncPrintf "unpack arc file"
        if [ ! -d ./wrk/${S}/initrd/var/lib/dpkg/info/. ]; then
          mkdir -p ./wrk/${S}/initrd/var/lib/dpkg/info
        fi
        for F in $(find ./arc/${S%\.*}/ -type f)
        do
          fncPrintf "unpack  arc: ${F}"
          mkdir -p ./tmp
          tar -C ./tmp/ -xf ${F}
          # --- iso-scan and load-iso -----------------------------------------
          if [ -z "$(sed -n '/^Package: iso-scan$/p' ./wrk/${S}/initrd/var/lib/dpkg/status)" ]; then
            fncPrintf "$(find ./tmp/ \( -name 'iso-scan.*' -o -name 'load-iso.*' \) -type f -printf 'copy   file: %p\n' -exec cp -a --backup '{}' ./wrk/${S}/initrd/var/lib/dpkg/info/ \;)"
            V="$(echo ${F} | sed -e 's/^.*_\(.*\)\.tar.*$/\1/')"
            cat <<- '_EOT_' | sed -e "s/_VER_/${V}/g" | tee -a ./wrk/${S}/initrd/var/lib/dpkg/status > /dev/null
				
				Package: iso-scan
				Status: install ok unpacked
				Version: _VER_
				Depends: cdebconf-udeb, hw-detect, loop-modules, di-utils
				Description: Scan hard drives for an installer ISO image
_EOT_
          fi
          if [ -z "$(sed -n '/^Package: load-iso$/p' ./wrk/${S}/initrd/var/lib/dpkg/status)" ]; then
            cat <<- '_EOT_' | sed -e "s/_VER_/${V}/g" | tee -a ./wrk/${S}/initrd/var/lib/dpkg/status > /dev/null
				
				Package: load-iso
				Status: install ok unpacked
				Version: _VER_
				Depends: cdebconf-udeb, iso-scan, cdrom-retriever, anna
				Description: Load installer components from an installer ISO
_EOT_
          fi
          rm -rf ./tmp/
        done
        ;;
      *                    )
        ;;
    esac
    # --- config --------------------------------------------------------------
    fncPrintf "config"
    V=$(find ./wrk/${S}/initrd/lib/modules/*/kernel/ -name 'fs' -type d | sed -e 's~^.*/modules/\(.*\)/kernel/.*$~\1~g')
    if [ -d ./wrk/${S}/initrd/lib/modules/${V}/. ]; then
      touch ./wrk/${S}/initrd/lib/modules/${V}/modules.builtin.modinfo
      depmod -a -b ./wrk/${S}/initrd ${V}
    fi
    if [ -f  ./wrk/${S}/initrd/var/lib/dpkg/info/iso-scan.postinst ]; then
      sed -i ./wrk/${S}/initrd/var/lib/dpkg/info/iso-scan.postinst    \
          -e 's/^\([[:space:]]*FS\)="\(.*\)".*$/\1="\2 fuse fuse3 exfat ntfs3"/'
    fi
    case "${S%\.*}" in
      debian.*        ) ;;
      ubuntu.bionic   )
        if [ -f  ./wrk/${S}/initrd/var/lib/dpkg/info/iso-scan.postinst ]; then
          OLD_IFS=${IFS}
          INS_ROW=$(
            sed -n -e '/^[[:space:]]*use_this_iso[[:space:]]*([[:space:]]*)/,/^[[:space:]]*}$/ {/[[:space:]]*mount .* \/cdrom/=}' \
              ./wrk/${S}/initrd/var/lib/dpkg/info/iso-scan.postinst
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
          sed -i ./wrk/${S}/initrd/var/lib/dpkg/info/iso-scan.postinst                                                    \
              -e '/^[[:space:]]*use_this_iso[[:space:]]*([[:space:]]*/,/^}$/ s~^\([[:space:]]*mount .* /cdrom .*$\)~#\1~' \
              -e "${INS_ROW:-1}a \\${INS_STR}"
          cat <<- '_EOT_' >> ./wrk/${S}/initrd/var/lib/dpkg/info/iso-scan.templates
			
			Template: iso-scan/copy_iso_to_ram
			Type: boolean
			Default: false
			Description: copy the ISO image to a ramdisk with enough space?
			Description-ja.UTF-8: ISO イメージを十分な容量のある RAM ディスクにコピーしますか?
_EOT_
        fi
        ;;
      ubuntu.focal    | \
      ubuntu.jammy    | \
      ubuntu.kinetic  | \
      ubuntu.lunar    )
#       mkdir -p ./wrk/${S}/initrd/dev/.initramfs
        if [ -f  ./wrk/${S}/initrd/scripts/casper-helpers ]; then
          OLD_IFS=${IFS}
          INS_ROW=$(
            sed -n -e '/^[[:space:]]*find_files[[:space:]]*([[:space:]]*)/,/^[[:space:]]*}$/ {/[[:space:]]*vfat|ext2)/,/.*;;$/=}' \
              ./wrk/${S}/initrd/scripts/casper-helpers                                                                            \
              | awk 'END {print}'
          )
          IFS= INS_STR=$(
            cat <<- '_EOT_' | sed -e 's/^ //g' | sed -z -e 's/\n/\\n/g'
			                 exfat|ntfs)
			                     :;;
_EOT_
        )
          IFS=${OLD_IFS}
          sed -i ./wrk/${S}/initrd/scripts/casper-helpers                                                                                  \
              -e '/[[:space:]]*is_supported_fs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ s/\(vfat.*\))/\1|exfat)/'                      \
              -e '/[[:space:]]*wait_for_devs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ {/touch/i \\    mkdir -p /dev/.initramfs' -e '}' \
              -e "${INS_ROW:-1}a \\${INS_STR}"
        fi
        if [ -f  ./wrk/${S}/initrd/scripts/lupin-helpers ]; then
          sed -i ./wrk/${S}/initrd/scripts/lupin-helpers                                                                                  \
              -e '/[[:space:]]*is_supported_fs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ s/\(vfat.*\))/\1|exfat)/'                      \
              -e '/[[:space:]]*wait_for_devs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ {/touch/i \\    mkdir -p /dev/.initramfs' -e '}'
        fi
        ;;
      *               ) ;;
    esac
    if [ -f ./wrk/${S}/initrd/etc/lsb-release ]; then
      sed -i ./wrk/${S}/initrd/etc/lsb-release                      \
          -e 's/^\(X_INSTALLATION_MEDIUM\)=.*$/\1=hd-media/'
    fi
  done
}

# === make initramfs ==========================================================
funcMake_initramfs () {
  fncPrintf "make initramfs"
  rm -rf ./ird/
  mkdir -p ./ird
  # COMPRESS: [ gzip | bzip2 | lz4 | lzma | lzop | xz | zstd ]
  # COMPRESSLEVEL: ...
  # Valid values are:
  # 1 -  9 for gzip|bzip2|lzma|lzop
  # 0 -  9 for  lz4|xz
  # 0 - 19 for zstd
  for S in $(ls -1aA ./wrk/)
  do
    O=$(pwd)
    pushd ./wrk/${S}/initrd > /dev/null
      fncPrintf "make       : ./ird/${S}/initrd.img"
      mkdir -p ${O}/ird/${S}
      find . -name '*~' -prune -o -print | cpio -R 0:0 -o -H newc --quie | gzip -c > ${O}/ird/${S}/initrd.img
    popd > /dev/null
    cp -a ./ram/${S}/vmlinuz/vmlinuz* ./ird/${S}/vmlinuz.img
  done
  OLD_IFS=${IFS}
  IFS=$'\n'
  for A in $(ls -lhX1 $(find ./ird/ \( -name 'initrd*' -o -name 'vmlinuz*' \) -type f))
  do
    fncPrintf "%s\n" "${A}"
  done
  IFS=${OLD_IFS}
# rm -rf ./wrk/*
}

# ### file copy ###############################################################
# === copy initramfs ==========================================================
funcCopy_initramfs () {
  fncPrintf "copy initramfs"
  rm -rf ./img/install.amd/
  mkdir -p ./img/install.amd
  cp -a ./ird/. ./img/install.amd
}

# === copy config file ========================================================
funcCopy_cfg_file () {
  fncPrintf "make directory"
  rm -rf ./img/preseed/debian \
         ./img/preseed/ubuntu \
         ./img/nocloud
  mkdir -p ./img/preseed/debian \
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
  fncPrintf "change config file"
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
}

# === copy iso image ==========================================================
funcCopy_iso_image () {
  fncPrintf "make directory"
  rm -rf ./img/images
  mkdir -p ./img/images
  # === copy iso file =========================================================
  fncPrintf "copy iso file"
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
    fncPrintf "copy   file: ${F}"
    cp -a -L -u ./iso/${F} ./img/images/
  done
}

# ### USB Device: partition and format ########################################
funcUSB_Device_partition_and_format () {
  # *** [ USB device: /dev/sdb ] ***
  # === device and mount check ================================================
  fncPrintf "device and mount check"
  lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
  while :
  do
    if [ -b /dev/sdb ]; then
      break
    fi
    fncPrintf "device not found"
    lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sd[a-z]
    fncPrintf "enter Ctrl+C"
    read DUMMY
  done
  while :
  do
    fncPrintf "erase /dev/sdb? (YES or Ctrl-C)"
    read DUMMY
    if [ "${DUMMY}" = "YES" ]; then
      break
    fi
  done
# lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
  mountpoint -q ./usb/ && (umount -q -f ./usb || umount -q -lf ./usb) || true
  # === partition =============================================================
  fncPrintf "partition"
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
  fncPrintf "format"
  mkfs.vfat -F 32              /dev/sdb2
  mkfs.vfat -F 32 -n "CIDATA"  /dev/sdb3
  mkfs.exfat      -n "ISOFILE" /dev/sdb4
# mkfs.ntfs -Q    -L "ISOFILE" /dev/sdb4
  sleep 3
  sync
  lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
}

# ### USB Device: [ /dev/sdX1, /dev/sdX2 ] Boot and EFI partition #############
funcUSB_Device_Inst_Bootloader () {
  # *** [ USB device: /dev/sdb1, /dev/sdb2 ] ***
  # === mount /dev/sdX2 =======================================================
  fncPrintf "mount /dev/sdX2"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb2 ./usb/
  # === install boot loader ===================================================
  fncPrintf "install boot loader"
  grub-install --target=i386-pc    --recheck   --boot-directory=./usb/boot /dev/sdb
  grub-install --target=x86_64-efi --removable --boot-directory=./usb/boot --efi-directory=./usb
  # === make .disk directory ==================================================
  fncPrintf "make .disk directory"
  mkdir -p ./usb/.disk
  touch ./usb/.disk/info
  # === unmount ===============================================================
  fncPrintf "unmount"
  umount ./usb/
}

# ### USB Device: [ /dev/sdX2 ] EFI partition #################################
funcUSB_Device_Inst_GRUB () {
  # *** [ USB device: /dev/sdb2 ] ***
  # === mount /dev/sdX3 =======================================================
  fncPrintf "mount /dev/sdX2"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb2 ./usb/
  # === grub.cfg ==============================================================
  fncPrintf "make grub.cfg"
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
	    set isodist="debian.testing.netinst"
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
	    set isodist="debian.bookworm.netinst"
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
	    set isodist="debian.bullseye.netinst"
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
	    set isodist="debian.buster.netinst"
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
	    set isodist="ubuntu.lunar.server"
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
	    set isodist="ubuntu.kinetic.server"
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
	    set isodist="ubuntu.jammy.server"
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
	    set isodist="ubuntu.focal.server"
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
	    set isodist="ubuntu.bionic.server"
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
	    menuentry 'Live system (Debian 12:testing [bookworm])' {
	        set gfxpayload=keep
	        set isofile="/images/debian-live-bkworm-DI-rc2-amd64-lxde.iso"
	        set isoscan="${isofile} (bookworm - 12)"
	        set isodist="debian.bookworm.live"
	        set preseed="/hd-media/preseed/debian/preseed.cfg"
	        set locales="locale=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	        echo "Loading ${isofile} ..."
	        linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} boot=live components quiet splash findiso=${isofile} ${locales} fsck.mode=skip
	        initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	    }
	    menuentry 'Unattended installation (Debian 12:testing [bookworm])' {
	        set gfxpayload=keep
	        set isofile="/images/debian-live-bkworm-DI-rc2-amd64-lxde.iso"
	        set isoscan="${isofile} (bookworm - 12)"
	        set isodist="debian.bookworm.live"
	        set preseed="/hd-media/preseed/debian/preseed.cfg"
	        set locales="locale=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	        echo "Loading ${isofile} ..."
	        linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb4] ${isoscan}" ${locales} fsck.mode=skip auto=true file=${preseed} netcfg/disable_autoconfig=true ---
	        initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	    }
	    menuentry 'Live system (Ubuntu 23.04:Lunar Lobster)' {
	        set gfxpayload=keep
	        set isofile="/images/ubuntu-23.04-desktop-amd64.iso"
	        set isoscan="iso-scan/filename=${isofile}"
	        set isodist="ubuntu.lunar.desktop"
	        set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	        echo "Loading ${isofile} ..."
	        linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img layerfs-path=minimal.standard.live.squashfs --- quiet splash ${isoscan} ${locales} fsck.mode=skip
	        initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	    }
	    menuentry 'Unattended installation (Ubuntu 23.04:Lunar Lobster)' {
	        set gfxpayload=keep
	        set isofile="/images/ubuntu-23.04-desktop-amd64.iso"
	        set isoscan="iso-scan/filename=${isofile}"
	        set isodist="ubuntu.lunar.desktop"
	        set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	        echo "Loading ${isofile} ..."
	        linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img layerfs-path=minimal.standard.live.squashfs --- quiet splash ${isoscan} ${locales} fsck.mode=skip autoinstall ip=dhcp ipv6.disable=0
	        initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	    }
	}
	menuentry "System shutdown" {
	    echo "System shutting down ..."
	    halt
	}
	menuentry "System restart" {
	    echo "System rebooting ..."
	    reboot
	}
	if [ "$grub_platform" = "efi" ]; then
	    menuentry 'Boot from next volume' {
	        exit 1
	    }
	    menuentry 'UEFI Firmware Settings' {
	        fwsetup
	    }
	fi
_EOT_
  # === unmount ===============================================================
  fncPrintf "unmount"
  umount ./usb/
}

# ### USB Device: [ /dev/sdX3 ] Data partition ################################
funcUSB_Device_Inst_File_partition () {
  # *** [ USB device: /dev/sdb3 ] ***
  # === mount /dev/sdX3 =======================================================
  fncPrintf "mount /dev/sdX3"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb3 ./usb/
  # === copy boot loader and setting files ====================================
  fncPrintf "copy boot loader and setting files"
  cp --preserve=timestamps -u -r ./img/install.amd/ ./usb/
  cp --preserve=timestamps -u    ./cfg/ubuntu.server/user-data ./usb/
  touch ./usb/meta-data
  touch ./usb/vendor-data
  touch ./usb/network-config
  # === unmount ===============================================================
  fncPrintf "unmount"
  umount ./usb/
}

# ### USB Device: [ /dev/sdX4 ] Data partition ################################
funcUSB_Device_Data_File_partition () {
  # *** [ USB device: /dev/sdb4 ] ***
  # === mount /dev/sdX4 =======================================================
  fncPrintf "mount /dev/sdX4"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb4 ./usb/
  # === copy iso files ========================================================
  fncPrintf "copy iso files"
  cp --preserve=timestamps -u -r ./img/images/  ./usb/
  cp --preserve=timestamps -u -r ./img/nocloud/ ./usb/
  cp --preserve=timestamps -u -r ./img/preseed/ ./usb/
  # === unmount ===============================================================
  fncPrintf "unmount"
  umount ./usb
}

# ### main ####################################################################
main () {
  if [ "$(whoami)" != "root" ]; then
    fncPrintf "execute as root user."
    exit 1
  fi
  # --- initialization --------------------------------------------------------
  if [ "$(command -v tput 2> /dev/null)" != "" ]; then
    ROW_SIZE=$(tput lines)
    COL_SIZE=$(tput cols)
  fi
  if [ ${COL_SIZE} -lt 80 ]; then
    COL_SIZE=80
  fi
  if [ ${COL_SIZE} -gt 100 ]; then
    COL_SIZE=100
  fi
  # --- main ------------------------------------------------------------------
  fncPrintf "$(date +"%Y/%m/%d %H:%M:%S") processing start"
  funcDownload "cfg"
  funcDownload "bld"
  funcDownload "lnk"
  funcDownload "iso"
  funcDownload "deb"
  funcDownload "arc"
  funcCopy_module
  funcUnpack_lnximg
  funcUnpack_module
  funcMake_initramfs
  funcCopy_initramfs
  funcCopy_cfg_file
  funcCopy_iso_image
  funcUSB_Device_partition_and_format
  funcUSB_Device_Inst_Bootloader
  funcUSB_Device_Inst_GRUB
  funcUSB_Device_Inst_File_partition
  funcUSB_Device_Data_File_partition
  lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
  fncPrintf "complete"
  fncPrintf "$(date +"%Y/%m/%d %H:%M:%S") processing end"
}

# === main ====================================================================
main
# =============================================================================
# https://deb.debian.org/debian/pool/main/n/ntfs-3g/ntfs-3g_2022.10.3-1+b1_amd64.deb
# https://deb.debian.org/debian/pool/main/f/fuse3/fuse3_3.14.0-3_amd64.deb
# https://deb.debian.org/debian/pool/main/f/fuse/fuse_2.9.9-6+b1_amd64.deb
# ### eof #####################################################################
