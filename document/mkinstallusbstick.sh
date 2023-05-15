#!/bin/bash
# *****************************************************************************
# Unattended installation USB stick for multiple ISO files. (GPT exFAT Ver.)
# -----------------------------------------------------------------------------
#   Debian xx    : -------- (testing)      : debian-testing-amd64-netinst.iso         : 6.1.0-9-amd64
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
#   ./arc : 
#   ./bld : boot loader files
#   ./cfg : setting files (preseed.cfg/cloud-init/initrd/vmlinuz/...)
#   ./deb : deb files
#   ./img : copy files image
#   ./ird : custom initramfs files
#   ./iso : iso files
#   ./lnx : linux-image unpacked files
#   ./mnt : iso file mount point
#   ./opt : 
#   ./pac : optional deb unpacked files
#   ./ram : initramfs files
#   ./tmp : 
#   ./usb : USB stick mount point
#   ./wrk : work directory
#
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
# dpkg -l fdisk coreutils curl dosfstools grub2-common initramfs-tools-core cpio gzip bzip2 lz4 lzma lzop xz-utils zstd
# apt-get install fdisk coreutils curl dosfstools grub2-common initramfs-tools-core cpio gzip bzip2 lz4 lzma lzop xz-utils zstd

# -----------------------------------------------------------------------------
  ROW_SIZE=25
  COL_SIZE=80

# -----------------------------------------------------------------------------
  readonly TXT_RESET='\033[m'           # reset all attributes
  readonly TXT_ULINE='\033[4m'          # set underline
  readonly TXT_ULINERST='\033[24m'      # reset underline
  readonly TXT_REV='\033[7m'            # set reverse display
  readonly TXT_REVRST='\033[27m'        # reset reverse display
  readonly TXT_BLACK='\033[30m'         # text black
  readonly TXT_RED='\033[31m'           # text red
  readonly TXT_GREEN='\033[32m'         # text green
  readonly TXT_YELLOW='\033[33m'        # text yellow
  readonly TXT_BLUE='\033[34m'          # text blue
  readonly TXT_MAGENTA='\033[35m'       # text purple
  readonly TXT_CYAN='\033[36m'          # text light blue
  readonly TXT_WHITE='\033[37m'         # text white
  readonly TXT_BBLACK='\033[40m'        # text reverse black
  readonly TXT_BRED='\033[41m'          # text reverse red
  readonly TXT_BGREEN='\033[42m'        # text reverse green
  readonly TXT_BYELLOW='\033[43m'       # text reverse yellow
  readonly TXT_BBLUE='\033[44m'         # text reverse blue
  readonly TXT_BMAGENTA='\033[45m'      # text reverse purple
  readonly TXT_BCYAN='\033[46m'         # text reverse light blue
  readonly TXT_BWHITE='\033[47m'        # text reverse white

# ### common function #########################################################
# --- text color test ---------------------------------------------------------
funcColorTest () {
  echo -e "${TXT_RESET} : TXT_RESET    : ${TXT_RESET}"
  echo -e "${TXT_ULINE} : TXT_ULINE    : ${TXT_RESET}"
  echo -e "${TXT_ULINERST} : TXT_ULINERST : ${TXT_RESET}"
  echo -e "${TXT_REV} : TXT_REV      : ${TXT_RESET}"
  echo -e "${TXT_REVRST} : TXT_REVRST   : ${TXT_RESET}"
  echo -e "${TXT_BLACK} : TXT_BLACK    : ${TXT_RESET}"
  echo -e "${TXT_RED} : TXT_RED      : ${TXT_RESET}"
  echo -e "${TXT_GREEN} : TXT_GREEN    : ${TXT_RESET}"
  echo -e "${TXT_YELLOW} : TXT_YELLOW   : ${TXT_RESET}"
  echo -e "${TXT_BLUE} : TXT_BLUE     : ${TXT_RESET}"
  echo -e "${TXT_MAGENTA} : TXT_MAGENTA  : ${TXT_RESET}"
  echo -e "${TXT_CYAN} : TXT_CYAN     : ${TXT_RESET}"
  echo -e "${TXT_WHITE} : TXT_WHITE    : ${TXT_RESET}"
  echo -e "${TXT_BBLACK} : TXT_BBLACK   : ${TXT_RESET}"
  echo -e "${TXT_BRED} : TXT_BRED     : ${TXT_RESET}"
  echo -e "${TXT_BGREEN} : TXT_BGREEN   : ${TXT_RESET}"
  echo -e "${TXT_BYELLOW} : TXT_BYELLOW  : ${TXT_RESET}"
  echo -e "${TXT_BBLUE} : TXT_BBLUE    : ${TXT_RESET}"
  echo -e "${TXT_BMAGENTA} : TXT_BMAGENTA : ${TXT_RESET}"
  echo -e "${TXT_BCYAN} : TXT_BCYAN    : ${TXT_RESET}"
  echo -e "${TXT_BWHITE} : TXT_BWHITE   : ${TXT_RESET}"
}

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
  H=($(curl --location --no-progress-bar --head --remote-time --show-error --silent --fail "${U}" 2> /dev/null | sed -n '/HTTP\/.* 200/,/^$/p'))
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

# === download: link ==========================================================
funcDownload_lnk () {
  # ### download: cfg link ####################################################
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}download : cfg link${TXT_RESET}"
  rm -rf ./cfg/
  mkdir -p ./cfg                                          \
           ./cfg/debian                                   \
           ./cfg/ubuntu.desktop                           \
           ./cfg/ubuntu.server                            \
           ./cfg/fedora                                   \
           ./cfg/installer-hd-media/debian.buster/gtk     \
           ./cfg/installer-hd-media/debian.bullseye/gtk   \
           ./cfg/installer-hd-media/debian.bookworm/gtk   \
           ./cfg/installer-hd-media/debian.testing/gtk    \
           ./cfg/installer-hd-media/ubuntu.bionic-updates \
           ./cfg/installer-hd-media/ubuntu.focal-updates
  # === setting file ==========================================================
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/debian/preseed.cfg                                      ./cfg/debian/preseed.cfg
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/debian/sub_late_command.sh                              ./cfg/debian/sub_late_command.sh
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/ubuntu.desktop/preseed.cfg                              ./cfg/ubuntu.desktop/preseed.cfg
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/ubuntu.desktop/sub_late_command.sh                      ./cfg/ubuntu.desktop/sub_late_command.sh
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/ubuntu.desktop/sub_success_command.sh                   ./cfg/ubuntu.desktop/sub_success_command.sh
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/ubuntu.server/user-data                                 ./cfg/ubuntu.server/user-data
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/fedora/ks_fedora.cfg                                    ./cfg/fedora/ks_fedora.cfg
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/fedora/ks_alma.cfg                                      ./cfg/fedora/ks_alma.cfg
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/fedora/ks_rocky.cfg                                     ./cfg/fedora/ks_rocky.cfg
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/fedora/ks_miracle.cfg                                   ./cfg/fedora/ks_miracle.cfg
  # === debian installer ======================================================
  # --- stretch ---------------------------------------------------------------
  # --- buster ----------------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.buster/boot.img.gz            ./cfg/installer-hd-media/debian.buster/boot.img.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.buster/initrd.gz              ./cfg/installer-hd-media/debian.buster/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.buster/vmlinuz                ./cfg/installer-hd-media/debian.buster/vmlinuz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.buster/gtk/initrd.gz          ./cfg/installer-hd-media/debian.buster/gtk/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.buster/gtk/vmlinuz            ./cfg/installer-hd-media/debian.buster/gtk/vmlinuz
  # --- bullseye --------------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bullseye/boot.img.gz          ./cfg/installer-hd-media/debian.bullseye/boot.img.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bullseye/initrd.gz            ./cfg/installer-hd-media/debian.bullseye/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bullseye/vmlinuz              ./cfg/installer-hd-media/debian.bullseye/vmlinuz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bullseye/gtk/initrd.gz        ./cfg/installer-hd-media/debian.bullseye/gtk/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bullseye/gtk/vmlinuz          ./cfg/installer-hd-media/debian.bullseye/gtk/vmlinuz
  # --- bookworm --------------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bookworm/boot.img.gz          ./cfg/installer-hd-media/debian.bookworm/boot.img.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bookworm/initrd.gz            ./cfg/installer-hd-media/debian.bookworm/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bookworm/vmlinuz              ./cfg/installer-hd-media/debian.bookworm/vmlinuz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bookworm/gtk/initrd.gz        ./cfg/installer-hd-media/debian.bookworm/gtk/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.bookworm/gtk/vmlinuz          ./cfg/installer-hd-media/debian.bookworm/gtk/vmlinuz
  # --- testing ---------------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.testing/boot.img.gz           ./cfg/installer-hd-media/debian.testing/boot.img.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.testing/initrd.gz             ./cfg/installer-hd-media/debian.testing/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.testing/vmlinuz               ./cfg/installer-hd-media/debian.testing/vmlinuz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.testing/gtk/initrd.gz         ./cfg/installer-hd-media/debian.testing/gtk/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/debian.testing/gtk/vmlinuz           ./cfg/installer-hd-media/debian.testing/gtk/vmlinuz
  # --- bionic ----------------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/ubuntu.bionic-updates/boot.img.gz    ./cfg/installer-hd-media/ubuntu.bionic-updates/boot.img.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/ubuntu.bionic-updates/initrd.gz      ./cfg/installer-hd-media/ubuntu.bionic-updates/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/ubuntu.bionic-updates/vmlinuz        ./cfg/installer-hd-media/ubuntu.bionic-updates/vmlinuz
  # --- focal -----------------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/ubuntu.focal-updates/boot.img.gz     ./cfg/installer-hd-media/ubuntu.focal-updates/boot.img.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/ubuntu.focal-updates/initrd.gz       ./cfg/installer-hd-media/ubuntu.focal-updates/initrd.gz
  ln -s /mnt/hgfs/workspace/Image/linux/cfg/installer-hd-media/ubuntu.focal-updates/vmlinuz         ./cfg/installer-hd-media/ubuntu.focal-updates/vmlinuz
  # ### download: iso link ####################################################
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}download : iso link${TXT_RESET}"
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
  # --- fedora server ---------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/fedora/Fedora-Server-netinst-x86_64-38-1.6.iso              ./iso/Fedora-Server-netinst-x86_64-38-1.6.iso
  # --- almalinux -------------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/almalinux/AlmaLinux-9-latest-x86_64-boot.iso                ./iso/AlmaLinux-9-latest-x86_64-boot.iso
  # --- rocky -----------------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/Rocky/Rocky-9.1-x86_64-boot.iso                             ./iso/Rocky-9.1-x86_64-boot.iso
  # --- miraclelinux ----------------------------------------------------------
  ln -s /mnt/hgfs/workspace/Image/linux/miraclelinux/MIRACLELINUX-9.0-rtm-minimal-x86_64.iso        ./iso/MIRACLELINUX-9.0-rtm-minimal-x86_64.iso
}

# === download: cfg file ======================================================
funcDownload_cfg () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}download: cfg file${TXT_RESET}"
  # ### download: setting file ################################################
# rm -rf ./cfg/
  mkdir -p ./cfg
  # === setting file ==========================================================
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : setting file${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/debian"                                     "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/debian/preseed.cfg"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/debian"                                     "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/debian/sub_late_command.sh"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                             "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/preseed.cfg"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                             "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/sub_late_command.sh"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.desktop"                             "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.desktop/sub_success_command.sh"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/ubuntu.server"                              "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/ubuntu.server/user-data"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/fedora"                                     "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/fedora/ks_fedora.cfg"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/fedora"                                     "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/fedora/ks_alma.cfg"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/fedora"                                     "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/fedora/ks_rocky.cfg"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/fedora"                                     "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cfg/fedora/ks_miracle.cfg"
}

# === download: debian installer ==============================================
funcDownload_bld () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}download : debian installer${TXT_RESET}"
  # ### download: debian installer ############################################
  # === stretch ===============================================================
# fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : stretch${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/boot.img.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/initrd.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch"          "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/vmlinuz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch/gtk"      "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.stretch/gtk"      "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === buster ================================================================
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : buster${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster"           "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster/gtk"       "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.buster/gtk"       "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === bullseye ==============================================================
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : bullseye${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye"         "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye/gtk"     "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bullseye/gtk"     "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === bookworm ==============================================================
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : bookworm${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm"         "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm/gtk"     "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/gtk/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.bookworm/gtk"     "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/hd-media/gtk/vmlinuz"
  # === testing ===============================================================
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : testing${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing"          "https://d-i.debian.org/daily-images/amd64/daily/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing/gtk"      "https://d-i.debian.org/daily-images/amd64/daily/hd-media/gtk/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/debian.testing/gtk"      "https://d-i.debian.org/daily-images/amd64/daily/hd-media/gtk/vmlinuz"
  # === bionic ================================================================
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : bionic${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/boot.img.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/initrd.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic"           "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.bionic-updates"   "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/hd-media/vmlinuz"
  # === focal =================================================================
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : focal${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/boot.img.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/initrd.gz"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal"            "http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/hd-media/vmlinuz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/boot.img.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/initrd.gz"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./cfg/installer-hd-media/ubuntu.focal-updates"    "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/hd-media/vmlinuz"
}

# === download: iso file ======================================================
funcDownload_iso () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}download : iso file${TXT_RESET}"
  # ### download: iso file ####################################################
# rm -rf ./iso/
  mkdir -p ./iso
  # ::: debian mini.iso :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# fncPrintf "${TXT_BLACK}${TXT_BGREEN}download: debian mini.iso${TXT_RESET}"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-stretch-amd64.iso"                               "https://archive.debian.org/debian/dists/stretch/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-buster-amd64.iso"                                "https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-bullseye-amd64.iso"                              "https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-bookworm-amd64.iso"                              "https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-testing-amd64.iso"                               "https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso"
  # ::: debian netinst ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : debian netinst${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-cd/debian-9.13.0-amd64-netinst.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/10.13.0/amd64/iso-cd/debian-10.13.0-amd64-netinst.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-11.7.0-amd64-netinst.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/bookworm_di_rc2/amd64/iso-cd/debian-bookworm-DI-rc2-amd64-netinst.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso"
  # ::: debian DVD ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : debian DVD${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/9.13.0/amd64/iso-dvd/debian-9.13.0-amd64-DVD-1.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/10.13.0/amd64/iso-dvd/debian-10.13.0-amd64-DVD-1.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-11.7.0-amd64-DVD-1.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/bookworm_di_rc2/amd64/iso-dvd/debian-bookworm-DI-rc2-amd64-DVD-1.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso"
  # ::: debian live DVD :::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : debian Live DVD${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/9.13.0-live/amd64/iso-hybrid/debian-live-9.13.0-amd64-lxde.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/archive/10.13.0-live/amd64/iso-hybrid/debian-live-10.13.0-amd64-lxde.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-11.7.0-amd64-lxde.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/bookworm_di_rc2-live/amd64/iso-hybrid/debian-live-bkworm-DI-rc2-amd64-lxde.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso"
  # ::: ubuntu mini.iso :::::::::::::::::::::::::::::::::::::::::::::::::::::::
# fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : ubuntu mini.iso${TXT_RESET}"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-bionic-amd64.iso"                                "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
# funcCurl -L -# -R -S -f --create-dirs -o "./iso/mini-focal-amd64.iso"                                 "http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso"
  # ::: ubuntu server :::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : ubuntu server${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04.6-server-amd64.iso"
  # ::: ubuntu live server ::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : ubuntu live server${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/bionic/ubuntu-18.04.6-live-server-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/focal/ubuntu-20.04.6-live-server-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/kinetic/ubuntu-22.10-live-server-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/lunar/ubuntu-23.04-live-server-amd64.iso"
  # ::: ubuntu desktop ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : ubuntu desktop${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/bionic/ubuntu-18.04.6-desktop-amd64.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/focal/ubuntu-20.04.6-desktop-amd64.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-desktop-amd64.iso"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/kinetic/ubuntu-22.10-desktop-amd64.iso"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://releases.ubuntu.com/lunar/ubuntu-23.04-desktop-amd64.iso"
  # ::: fedora server :::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : fedora server${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-netinst-x86_64-38-1.6.iso"
  # ::: almalinux :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : almalinux${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso"
  # ::: rocky :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : rocky${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.1-x86_64-boot.iso"
  # ::: miraclelinux ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : miraclelinux${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./iso"                                            "https://repo.dist.miraclelinux.net/miraclelinux/isos/9.0-released/x86_64/MIRACLELINUX-9.0-rtm-minimal-x86_64.iso"
}

# === download: deb file ======================================================
funcDownload_deb () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}download : deb file${TXT_RESET}"
# rm -rf ./opt/
  mkdir -p ./opt
  # ::: linux image :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : linux image${TXT_RESET}"
# funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/debian.testing"                             "https://deb.debian.org/debian/pool/main/l/linux-signed-amd64/linux-image-6.1.0-9-amd64_6.1.27-1_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar.desktop"                       "http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-extra-6.2.0-20-generic_6.2.0-20.20_amd64.deb"
  # ::: exfat :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : exfat${TXT_RESET}"
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
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : libfuse2${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/libfuse2-udeb_2.9.9-3_amd64.udeb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.focal"                               "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse/libfuse2_2.9.9-3_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.jammy"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/libfuse2_2.9.9-5ubuntu3_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.kinetic"                             "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/libfuse2_2.9.9-5ubuntu3_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar"                               "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/libfuse2_2.9.9-6_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.mantic"                              "http://archive.ubuntu.com/ubuntu/pool/universe/f/fuse/libfuse2_2.9.9-6_amd64.deb"
  # ::: fuse3 :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : fuse3${TXT_RESET}"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar.desktop"                       "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/fuse3_3.14.0-3_amd64.deb"
  funcCurl -L -# -O -R -S --create-dirs --output-dir "./opt/ubuntu.lunar.desktop"                       "http://archive.ubuntu.com/ubuntu/pool/main/f/fuse3/libfuse3-3_3.14.0-3_amd64.deb"
  # ::: mount :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : mount${TXT_RESET}"
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
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}download : arc file${TXT_RESET}"
# rm -rf ./arc/
  mkdir -p ./arc
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}download : iso-scan${TXT_RESET}"
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
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}copy module${TXT_RESET}"
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
    fncPrintf "${TXT_BLACK}${TXT_BGREEN}mount   iso: %s${TXT_RESET}\n" "${P}"
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
    for F in $(find ${L} \( -name 'initrd*' -o  -name 'vmlinuz*' \) \( -type f -o -type l \))
    do
      fncPrintf "copy initrd: %-24.24s : %s\n" "${D}" "${F}"
      T="$(dirname ${F#\./mnt/})"
      mkdir -p ./bld/${D}/${T}
      cp -a -u ${F} ./bld/${D}/${T}/
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
      for P in $(find ${T[@]} -regextype posix-basic -regex ".*/${F}" \( -type f -o -type l \) | sed -n '/\(all\|amd64\)/p' | sed -n "/\(${F%\\.*}_\|-udeb_\)/p")
      do
        B="$(basename ${P})"
        fncPrintf "copy module: %-24.24s : %s\n" "${F}" "${B}"
        if [ -n "${P}" ]; then
          cp -a -u ${P} ./deb/${D}/
        fi
      done
      if [ -z "${B}" ]; then
        O=("./opt/${N}.${S}")
        if [ -d "./opt/${D}/." ]; then
          O+=(./opt/${D})
        fi
        for P in $(find ${O[@]} -regextype posix-basic -regex ".*/${F}" \( -type f -o -type l \) | sed -n '/\(all\|amd64\)/p' | sed -n "/\(${F%\\.*}_\|-udeb_\)/p")
        do
          B="$(basename ${P})"
          fncPrintf "copy module: %-24.24s : ${TXT_GREEN}%s${TXT_RESET}\n" "${F}" "${B}"
        done
      fi
      if [ -z "${B}" ]; then
        fncPrintf "copy module: %-24.24s : %s\n" "${F}" "${B}"
      fi
    done
    # *** linux image *********************************************************
    fncPrintf "$(find ${T[@]} -regextype posix-basic -regex '.*/\(linux\|linux-signed\(-amd64\)*\)/linux-\(image\|modules\).*-[0-9]*-\(amd64\|generic\)*_.*' \
                  \( -type f -o -type l \) -printf 'copy   limg: %f\n' -exec cp -a -u '{}' ./deb/${D}/ \;)"
    # *** packages file *******************************************************
    cp -a -u ./mnt/dists ./deb/${D}/
    # --- unmount -------------------------------------------------------------
    umount ./mnt
  done
}

# === unpack linux image ======================================================
funcUnpack_lnximg () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}unpack linux image${TXT_RESET}"
  rm -rf ./pac
  mkdir -p ./pac
  for S in $(ls -1aA ./deb/)
  do
    D=""
    if [ -d ./deb/${S}/.     ]; then D+="./deb/${S}/ ";     fi
    if [ -d ./opt/${S%\.*}/. ]; then D+="./opt/${S%\.*}/ "; fi
    if [ -d ./opt/${S}/.     ]; then D+="./opt/${S}/ ";     fi
    for F in $(find ${D} \( -name 'linux-image-*_amd64.deb' -o -name 'linux-modules-*_amd64.deb' \) \( -type f -o -type l \))
    do
      fncPrintf "unpack limg: %-24.24s : %s\n" "${S}" "$(basename ${F})"
      mkdir -p ./pac/${S}
      dpkg -x ${F} ./pac/${S}
    done
  done
}

# === remake module ===========================================================
funcRemake_module () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}remake module${TXT_RESET}"
  S=$1
  fncPrintf "${TXT_BLACK}${TXT_BGREEN}remk module: ${S}${TXT_RESET}"
  shift
  for D in $@
  do
    fncPrintf "remk module: ${D}"
    B="$(basename ${D})"
#    fncPrintf "remk module: ${B}"
    case "${B}" in
      live   ) I="${S}/live"   ;;
      casper ) I="${S}/casper" ;;
      *      ) I="${S}/install";;
    esac
    # --- unpack: inird -> ./ram/${I}/initrd ----------------------------------
    for W in 'initrd*-*' 'initrd*.*' 'initrd'
    do
      for F in $(find ${D} -name "${W}" \( -type f -o -type l \))
      do
        fncPrintf "unpack file: ${F}"
        mkdir -p ./ram/${I}/initrd
        unmkinitramfs ${F} ./ram/${I}/initrd
        break 2
      done
    done
    # --- copy: vmlinuz -> ./ram/${I}/vmlinuz ---------------------------------
    for W in 'vmlinuz*-*' 'vmlinuz*.*' 'vmlinuz'
    do
      for F in $(find ${D} -name "${W}" \( -type f -o -type l \))
      do
        fncPrintf "copy   file: ${F}"
        mkdir -p ./ram/${I}/vmlinuz
        cp -a -u ${F} ./ram/${I}/vmlinuz
        break 2
      done
    done
    # --- ram -> wrk ----------------------------------------------------------
    if [ -d ./ram/${I}/initrd/main/. ]; then
      D="./ram/${I}/initrd/main"
    else
      D="./ram/${I}/initrd"
    fi
    fncPrintf "copy     fs: ${D}"
    mkdir -p ./wrk/${I}/initrd
    cp -a -u ${D}/. ./wrk/${I}/initrd/
    # --- linux image -> wrk --------------------------------------------------
    if [ -d ./wrk/${I}/initrd/lib/modules/*/kernel/. ]; then
      V=$(find ./wrk/${I}/initrd/lib/modules/*/kernel/ -name 'fs' -type d | sed -e 's~^.*/modules/\(.*\)/kernel/.*$~\1~g')
    else
      V="$(find ./deb/${S}/ -name 'linux-image*' \( -type f -o -type l \) | sed -n -e 's~^.*/linux-image-\(.*\)_.*_.*$~\1~p')"
      if [ -z "${V}" ]; then
        fncPrintf "failed to get kernel version, exiting process."
        exit 1
      fi
      mkdir -p ./wrk/${I}/initrd/lib/modules/${V}/kernel
    fi
#    R=false
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
          cp -a -u --backup ./pac/${S}/lib/modules/${V}/${T} ./wrk/${I}/initrd/lib/modules/${V}/$(dirname ${T})
#          R=true
        fi
      done
    fi
#    if [ R = true ]; then
      touch ./wrk/${I}/initrd/lib/modules/${V}/modules.builtin.modinfo
      depmod -a -b ./wrk/${I}/initrd ${V}
#    fi
    # --- create var/lib/dpkg/status ------------------------------------------
    fncPrintf "create var/lib/dpkg/status"
    if [ ! -f ./wrk/${I}/initrd/var/lib/dpkg/status ]; then
      mkdir -p ./wrk/${I}/initrd/var/lib/dpkg
      touch ./wrk/${I}/initrd/var/lib/dpkg/status
    fi
    # --- Fix out-of-spec version ---------------------------------------------
    fncPrintf "edit   ver.: debian-installer [$(sed -n -e '/^Package: debian-installer$/,/^Package:/ {/Version:/p}' ./wrk/${I}/initrd/var/lib/dpkg/status)]"
    sed -i ./wrk/${I}/initrd/var/lib/dpkg/status                                      \
        -e '/^Package: debian-installer$/,/^Package:/ s/\(Version:\)[[:space:]]*hd-media-\([0-9]*\).*$/\1 \2/'
    fncPrintf "edit   ver.: debian-installer [$(sed -n -e '/^Package: debian-installer$/,/^Package:/ {/Version:/p}' ./wrk/${I}/initrd/var/lib/dpkg/status)]"
    # --- dpkg --update-avail -------------------------------------------------
    fncPrintf "update package data base"
    for P in $(find ./deb/${S}/dists/ -name '*Packages*' \( -type f -o -type l \))
    do
      mkdir -p ./tmp
      cp -a -u ${P} ./tmp/
      if [ -f ./tmp/Packages.gz ]; then
        gzip -d ./tmp/Packages.gz
      fi
      LANG=C dpkg --root=./wrk/${I}/initrd --update-avail ./tmp/Packages 2>&1 | \
        sed -n '/\(Replacing\|Information\)/!p'
      rm -rf ./tmp
    done
    # --- add package ---------------------------------------------------------
    fncPrintf "inst package"
    U=("")
    C=("")
    D=""
    if [ -d ./deb/${S}/.     ]; then D+="./deb/${S}/ ";     fi
    if [ -d ./opt/${S%\.*}/. ]; then D+="./opt/${S%\.*}/ "; fi
    if [ -d ./opt/${S}/.     ]; then D+="./opt/${S}/ ";     fi
    for P in $(find ${D} \
             \( -not -name 'linux-image-*_amd64.deb' -a -not -name 'linux-modules-*_amd64.deb' \
          -a \( -name '*.deb' -o -name '*.udeb' \) \) \( -type f -o -type l \) | sed -n '/\(all\|amd64\)/p' | sort -u)
    do
      F="$(basename ${P})"
      M="${F%%_*}"
      W="${M}\\(-udeb\\)*"
      # --- exclusion check [ *-udev_, *_ ] -----------------------------------
      if [ -z "$(echo ${P} | sed -n "/\/${M}\(-udeb\)*_/p")" ]; then
        continue
      fi
      # --- priority [ *-udev, * ] / registration check -----------------------
      for A in ${C[@]}
      do
        B="$(basename ${A})"
        if [ "${F}"      = "${B}"     ] ||
           [ "${M}"      = "${B%%_*}" ] ||
           [ "${M}-udeb" = "${B%%_*}" ]; then
          continue 2
        fi
      done
      # --- skip registered modules -------------------------------------------
      if [ -n "$(sed -n "/^Package: ${W}$/p" ./wrk/${I}/initrd/var/lib/dpkg/status)" ]; then
        continue
      fi
      # --- overriding busybox symlinks ---------------------------------------
      C+=("${P} ")
      case "${M}" in
        mount*     | \
        libmount1* )
          if [ -f ./wrk/${I}/initrd/bin/mount ]; then
            if [ "$(readlink -q ./wrk/${I}/initrd/bin/mount)" != "busybox" ]; then
              continue
            fi
            fncPrintf "overwr pack: ${F}"
            mkdir -p ./tmp
            dpkg -x ${P} ./tmp
            for T in $(ls ./tmp/)
            do
              cp -a --backup ./tmp/${T}/. ./wrk/${I}/initrd/${T}
            done
            rm -rf ./tmp
            continue
          fi
          ;;
        * )
          ;;
      esac
      fncPrintf "inst   pack: ${F}"
      U+=("${P} ")
    done
    # --- unpack package ------------------------------------------------------
#set +e
    fncPrintf "unpack package"
    LANG=C dpkg --root=./wrk/${I}/initrd --unpack ${U[@]} 2>&1          | \
      sed -n '/\(Selecting\|Reading\|Preparing\|warning:\|missing\)/!p' | \
      sed -e 's/^Unpacking \(.*\)$/unpack pack: \1/g'
#set -e
    # --- config --------------------------------------------------------------
    fncPrintf "config"
    if [ -f  ./wrk/${I}/initrd/var/lib/dpkg/info/iso-scan.postinst ]; then
      sed -i ./wrk/${I}/initrd/var/lib/dpkg/info/iso-scan.postinst    \
          -e 's/^\([[:space:]]*FS\)="\(.*\)".*$/\1="\2 fuse fuse3 exfat ntfs3"/'
    fi
    case "${S}" in
      debian.*        ) ;;
      ubuntu.bionic.* )
        if [ -f  ./wrk/${I}/initrd/var/lib/dpkg/info/iso-scan.postinst ]; then
          OLD_IFS=${IFS}
          INS_ROW=$(
            sed -n -e '/^[[:space:]]*use_this_iso[[:space:]]*([[:space:]]*)/,/^[[:space:]]*}$/ {/[[:space:]]*mount .* \/cdrom/=}' \
              ./wrk/${I}/initrd/var/lib/dpkg/info/iso-scan.postinst
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
          sed -i ./wrk/${I}/initrd/var/lib/dpkg/info/iso-scan.postinst                                                    \
              -e '/^[[:space:]]*use_this_iso[[:space:]]*([[:space:]]*/,/^}$/ s~^\([[:space:]]*mount .* /cdrom .*$\)~#\1~' \
              -e "${INS_ROW:-1}a \\${INS_STR}"
          cat <<- '_EOT_' >> ./wrk/${I}/initrd/var/lib/dpkg/info/iso-scan.templates
			
			Template: iso-scan/copy_iso_to_ram
			Type: boolean
			Default: false
			Description: copy the ISO image to a ramdisk with enough space?
			Description-ja.UTF-8: ISO イメージを十分な容量のある RAM ディスクにコピーしますか?
_EOT_
        fi
        ;;
      ubuntu.*        )
        if [ -d  ./wrk/${I}/initrd/scripts/casper-premount/. ]; then
          OLD_IFS=${IFS}
          IFS= INS_STR=$(
            cat <<- '_EOT_' | sed -e 's/^ //g' | sed -z -e 's/\n/\\n/g'
			/scripts/casper-bottom/99cloud_init "$@"
			[ -e /conf/param.conf ] && . /conf/param.conf
_EOT_
          )
          IFS=${OLD_IFS}
          sed -i ./wrk/${I}/initrd/scripts/casper-bottom/ORDER -e "$ a \\${INS_STR}"
          sed -i ./wrk/${I}/initrd/scripts/casper-bottom/ORDER -e '/^$/d'
          cat <<- '_EOT_' >> ./wrk/${I}/initrd/scripts/casper-bottom/99cloud_init
			#!/bin/sh
			
			PREREQ=""
			
			prereqs()
			{
			  echo "${PREREQ}"
			}
			
			case $1 in
			  # get pre-requisites
			  prereqs)
			    prereqs
			    exit 0
			    ;;
			esac
			
			. /scripts/casper-functions
			. /scripts/casper-helpers
			if [ -f /scripts/lupin-helpers ]; then
			  . /scripts/lupin-helpers
			fi
			
			nocloud_path=
			for x in $(cat /proc/cmdline); do
			  case ${x} in
			    ds=nocloud\;*      | \
			    ds=nocloud-net\;*  )
			    case ${x} in
			      *s=file:*        | \
			      *seedfrom=file:* )
			        nocloud_path=${x#*=file:///}
			        break
			        ;;
			    esac
			    ;;
			  esac
			done
			
			if [ "${nocloud_path}" ]; then
			  if find_path "/${nocloud_path}" /isodevice rw; then
			    echo "mkdir -p /root/${nocloud_path}"
			    mkdir -p /root/${nocloud_path}
			    echo "cp -dR ${FOUNDPATH}/. /root/${nocloud_path}"
			    cp -dR ${FOUNDPATH}/. /root/${nocloud_path}
			  else
			    panic "
			Could not find the nocloud /${nocloud_path}
			"
			  fi
			fi
_EOT_
          chmod +x ./wrk/${I}/initrd/scripts/casper-bottom/99cloud_init
        fi
        if [ -f  ./wrk/${I}/initrd/scripts/casper-helpers ]; then
          OLD_IFS=${IFS}
          INS_ROW=$(
            sed -n -e '/^[[:space:]]*find_files[[:space:]]*([[:space:]]*)/,/^[[:space:]]*}$/ {/[[:space:]]*vfat|ext2)/,/.*;;$/=}' \
              ./wrk/${I}/initrd/scripts/casper-helpers                                                                            \
              | awk 'END {print}'
          )
          IFS= INS_STR=$(
            cat <<- '_EOT_' | sed -e 's/^ //g' | sed -z -e 's/\n/\\n/g'
			                 exfat|ntfs)
			                     :;;
_EOT_
        )
          IFS=${OLD_IFS}
          sed -i ./wrk/${I}/initrd/scripts/casper-helpers                                                                                 \
              -e '/[[:space:]]*is_supported_fs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ s/\(vfat.*\))/\1|exfat)/'                      \
              -e '/[[:space:]]*wait_for_devs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ {/touch/i \\    mkdir -p /dev/.initramfs' -e '}' \
              -e "${INS_ROW:-1}a \\${INS_STR}"
        fi
        if [ -f  ./wrk/${I}/initrd/scripts/lupin-helpers ]; then
          sed -i ./wrk/${I}/initrd/scripts/lupin-helpers                                                                                  \
              -e '/[[:space:]]*is_supported_fs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ s/\(vfat.*\))/\1|exfat)/'                      \
              -e '/[[:space:]]*wait_for_devs[[:space:]]*([[:space:]]*)/,/[[:space:]]*}$/ {/touch/i \\    mkdir -p /dev/.initramfs' -e '}'
        fi
        ;;
      *               ) ;;
    esac
  done
}

# === select module ===========================================================
funcSelect_module () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}select module${TXT_RESET}"
  rm -rf ./ram/
  rm -rf ./wrk/
  mkdir -p ./ram
  mkdir -p ./wrk
  for S in $(ls -1aA ./bld/)
  do
    # --- bld or cfg -> ram ---------------------------------------------------
    D=("")
    case "${S}" in
      debian.*.live        ) D=("./bld/${S}/live"                          \
                                "./cfg/installer-hd-media/${S%\.*}"        );;
      debian.*             ) D=("./cfg/installer-hd-media/${S%\.*}"        );;
      ubuntu.bionic.server ) D=("./cfg/installer-hd-media/${S%\.*}-updates");;
      ubuntu.*             ) D=("./bld/${S}/casper"                        );;
      *                    ) 
        if [ -d ./bld/${S}/install.amd/. ]; then
          D=("./bld/${S}/install.amd")
        else
          D=("./bld/${S}/install")
        fi
      ;;
    esac
    funcRemake_module ${S} ${D[@]}
  done
}

# === make initramfs ==========================================================
funcMake_initramfs () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}make initramfs${TXT_RESET}"
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
    for B in $(ls -1aA ./wrk/${S}/)
    do
#      fncPrintf "make       : ${B}"
      case "${B}" in
        live   ) I="${S}/live"   ;;
        casper ) I="${S}/casper" ;;
        *      ) I="${S}/install";;
      esac
      pushd ./wrk/${I}/initrd > /dev/null
        fncPrintf "make initrd: ./ird/${I}/initrd.img"
        mkdir -p ${O}/ird/${I}
        find . -name '*~' -prune -o -print | cpio -R 0:0 -o -H newc --quie | gzip -c > ${O}/ird/${I}/initrd.img
      popd > /dev/null
      cp -a -u ./ram/${I}/vmlinuz/vmlinuz* ./ird/${I}/vmlinuz.img
    done
  done
  OLD_IFS=${IFS}
  IFS=$'\n'
  for A in $(ls -lhX1 $(find ./ird/ \( -name 'initrd*' -o -name 'vmlinuz*' \) \( -type f -o -type l \)))
  do
    fncPrintf "%s\n" "${A}"
  done
  IFS=${OLD_IFS}
# rm -rf ./wrk/*
}

# ### file copy ###############################################################
# === copy initramfs ==========================================================
funcCopy_initramfs () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}copy initramfs${TXT_RESET}"
  rm -rf ./img/install.amd/ \
         ./img/live/        \
         ./img/casper/
  mkdir -p ./img/install.amd \
           ./img/live        \
           ./img/casper
  for S in $(ls -1aA ./ird/)
  do
    for B in $(ls -1aA ./ird/${S}/)
    do
      fncPrintf "copy initrd: %-7.7s : %s\n" "${B}" "${S}"
      case "${B}" in
        live   )
          mkdir -p ./img/live/${S}
          cp -a -u ./ird/${S}/live/. ./img/live/${S}/
          ;;
        casper )
          mkdir -p ./img/casper/${S}
          cp -a -u ./ird/${S}/casper/. ./img/casper/${S}/
          ;;
        *      )
          mkdir -p ./img/install.amd/${S}
          cp -a -u ./ird/${S}/install/. ./img/install.amd/${S}/
          ;;
      esac
    done
  done
}

# === copy config file ========================================================
funcCopy_cfg_file () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}copy config file${TXT_RESET}"
  rm -rf ./img/preseed   \
         ./img/nocloud   \
         ./img/kickstart
  mkdir -p ./img/preseed/debian \
           ./img/preseed/ubuntu \
           ./img/nocloud/       \
           ./img/kickstart/
  # === copy config file ======================================================
# cp -a -u ./cfg/debian/preseed.cfg                    ./img/preseed/debian/
  cp -a -u ./cfg/debian/sub_late_command.sh            ./img/preseed/debian/
# cp -a -u ./cfg/ubuntu.desktop/preseed.cfg            ./img/preseed/ubuntu/
  cp -a -u ./cfg/ubuntu.desktop/sub_late_command.sh    ./img/preseed/ubuntu/
  cp -a -u ./cfg/ubuntu.desktop/sub_success_command.sh ./img/preseed/ubuntu/
  for D in desktop server
  do
    mkdir -p ./img/nocloud/ubuntu.${D}
    cp -a -u ./cfg/ubuntu.server/user-data ./img/nocloud/ubuntu.${D}
    touch ./img/nocloud/ubuntu.${D}/meta-data
    touch ./img/nocloud/ubuntu.${D}/vendor-data
    touch ./img/nocloud/ubuntu.${D}/network-config
  done
  cp -a -u ./cfg/fedora/ks_fedora.cfg                  ./img/kickstart/
  cp -a -u ./cfg/fedora/ks_alma.cfg                    ./img/kickstart/
  cp -a -u ./cfg/fedora/ks_rocky.cfg                   ./img/kickstart/
  cp -a -u ./cfg/fedora/ks_miracle.cfg                 ./img/kickstart/
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
  # === make preseed.cfg for server ===========================================
  fncPrintf "make preseed.cfg for server"
  for F in debian/preseed.cfg debian/preseed_old.cfg ubuntu/preseed.cfg ubuntu/preseed_old.cfg
  do
    D="$(dirname  ${F})"
    B="$(basename ${F})"
    T="${F/\./_server\.}"
    case "${D}" in
      debian )
        cp -a ./img/preseed/${F} ./img/preseed/${T}
        sed -i ./img/preseed/${T}                                                      \
            -e '/^[[:space:]].*[[:space:]]isc-dhcp-server[[:space:]]*/        s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]minidlna[[:space:]]*/               s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]apache2[[:space:]]*/                s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]task-desktop[[:space:]]*/           s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]task-lxde-desktop[[:space:]]*/      s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]task-laptop[[:space:]]*/            s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]task-japanese[[:space:]]*/          s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]task-japanese-desktop[[:space:]]*/  s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]fonts-noto[[:space:]]*/             s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]ibus-mozc[[:space:]]*/              s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]mozc-utils-gui[[:space:]]*/         s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]libreoffice-l10n-ja[[:space:]]*/    s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]libreoffice-help-ja[[:space:]]*/    s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]firefox-esr-l10n-ja[[:space:]]*/    s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]thunderbird[[:space:]]*/            s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]thunderbird-l10n-ja[[:space:]]*/    s/^ /#/'
        sed -z 's/\\\n#/\n#/g' -i ./img/preseed/${T}
        ;;
      ubuntu )
        cp -a ./img/preseed/${F} ./img/preseed/${T}
        sed -i ./img/preseed/${T}                                                      \
            -e '/^[[:space:]].*[[:space:]]isc-dhcp-server[[:space:]]*/        s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]minidlna[[:space:]]*/               s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]apache2[[:space:]]*/                s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]ubuntu-desktop[[:space:]]*/         s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]ubuntu-gnome-desktop[[:space:]]*/   s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]language-pack-ja[[:space:]]*/       s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]language-pack-gnome-ja[[:space:]]*/ s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]fonts-noto[[:space:]]*/             s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]ibus-mozc[[:space:]]*/              s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]mozc-utils-gui[[:space:]]*/         s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]libreoffice-l10n-ja[[:space:]]*/    s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]libreoffice-help-ja[[:space:]]*/    s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]firefox-locale-ja[[:space:]]*/      s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]thunderbird[[:space:]]*/            s/^ /#/' \
            -e '/^[[:space:]].*[[:space:]]thunderbird-locale-ja[[:space:]]*/  s/^ /#/'
        sed -z 's/\\\n#/\n#/g' -i ./img/preseed/${T}
        ;;
      *      )
        ;;
    esac
  done
  # === make cloud-init file for server =======================================
  fncPrintf "make cloud-init file for server"
  if [ -f ./img/nocloud/ubuntu.server/user-data ]; then
    sed -i ./img/nocloud/ubuntu.server/user-data                         \
        -e 's/^[[:space:]]\([[:space:]]*- isc-dhcp-server\)/#\1/'        \
        -e 's/^[[:space:]]\([[:space:]]*- minidlna\)/#\1/'               \
        -e 's/^[[:space:]]\([[:space:]]*- apache2\)/#\1/'                \
        -e 's/^[[:space:]]\([[:space:]]*- ubuntu-desktop\)/#\1/'         \
        -e 's/^[[:space:]]\([[:space:]]*- ubuntu-gnome-desktop\)/#\1/'   \
        -e 's/^[[:space:]]\([[:space:]]*- language-pack-ja\)/#\1/'       \
        -e 's/^[[:space:]]\([[:space:]]*- language-pack-gnome-ja\)/#\1/' \
        -e 's/^[[:space:]]\([[:space:]]*- fonts-noto\)/#\1/'             \
        -e 's/^[[:space:]]\([[:space:]]*- ibus-mozc\)/#\1/'              \
        -e 's/^[[:space:]]\([[:space:]]*- mozc-utils-gui\)/#\1/'         \
        -e 's/^[[:space:]]\([[:space:]]*- libreoffice-l10n-ja\)/#\1/'    \
        -e 's/^[[:space:]]\([[:space:]]*- libreoffice-help-ja\)/#\1/'    \
        -e 's/^[[:space:]]\([[:space:]]*- firefox-locale-ja\)/#\1/'      \
        -e 's/^[[:space:]]\([[:space:]]*- thunderbird\)/#\1/'            \
        -e 's/^[[:space:]]\([[:space:]]*- thunderbird-locale-ja\)/#\1/'
  fi
}

# === copy iso image ==========================================================
funcCopy_iso_image () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}copy iso image${TXT_RESET}"
#  rm -rf ./img/images
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
    Fedora-Server-netinst-x86_64-38-1.6.iso  \
    AlmaLinux-9-latest-x86_64-boot.iso       \
    Rocky-9.1-x86_64-boot.iso                \
    MIRACLELINUX-9.0-rtm-minimal-x86_64.iso  \
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
    nice -n 10 cp -a -u ./iso/${F} ./img/images/
  done
}

# ### USB Device: partition and format ########################################
funcUSB_Device_check () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}USB Device: partition and format${TXT_RESET}"
  # *** [ USB device: /dev/sdb ] ***
  # === device and mount check ================================================
  fncPrintf "device and mount check"
  if [ -b /dev/sdb ]; then
    lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
  fi
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
  # === device and mount check ================================================
# lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
  mountpoint -q ./usb/ && (umount -q -f ./usb || umount -q -lf ./usb) || true
}

funcUSB_Device_partition_and_format () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}USB Device: partition and format${TXT_RESET}"
  # *** [ USB device: /dev/sdb ] ***
  # === partition =============================================================
  fncPrintf "partition"
  sfdisk --wipe always --wipe-partitions always /dev/sdb <<- _EOT_
	label: gpt
	first-lba: 34
	start=34, size=  2014, type=21686148-6449-6E6F-744E-656564454649, attrs="GUID:62,63"
	start=  , size=256MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
	start=  , size=      , type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
_EOT_
#	start=  , size=  4GiB, type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
  sleep 3
  sync
  # === format ================================================================
  fncPrintf "format"
  mkfs.vfat -F 32              /dev/sdb2
# mkfs.vfat -F 32 -n "CIDATA"  /dev/sdb3
#  mkfs.vfat -F 32 -n "CFGFILE" /dev/sdb3
  mkfs.exfat      -n "ISOFILE" /dev/sdb3
#  mkfs.exfat      -n "ISOFILE" /dev/sdb4
# mkfs.ntfs -Q    -L "ISOFILE" /dev/sdb4
  sleep 3
  sync
  lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
}

# ### USB Device: [ /dev/sdX1, /dev/sdX2 ] Boot and EFI partition #############
funcUSB_Device_Inst_Bootloader () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}USB Device: Boot and EFI partition${TXT_RESET}"
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
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}USB Device: EFI partition${TXT_RESET}"
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

	search.fs_label "ISOFILE" cfgpart hd1,gpt3
	search.fs_label "ISOFILE" isopart hd1,gpt3

	loadfont ${prefix}/fonts/unicode.pf2

	set lang=ja_JP

	set gfxmode=1280x720
	set gfxpayload=keep
	insmod efi_gop
	insmod efi_uga
	insmod video_bochs
	insmod video_cirrus
	insmod gfxterm
	insmod png
	terminal_output gfxterm

	set menu_color_normal=cyan/blue
	set menu_color_highlight=white/blue

	grub_platform

	insmod play
	play 960 440 1 0 4 440 1

	menuentry '[ Unattended installation ]' {
	    true
	}
	menuentry 'Debian testing' {
	    set isofile="/images/debian-testing-amd64-netinst.iso"
	    set isoscan="${isofile} (testing)"
	    set isodist="debian.testing.netinst"
	    set preseed="auto=true file=/hd-media/preseed/debian/preseed.cfg netcfg/disable_autoconfig=true"
	    set locales="locales=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb3] ${isoscan}" ${locales} fsck.mode=skip ${preseed} ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Debian 12:bookworm' {
	    set isofile="/images/debian-bookworm-DI-rc2-amd64-netinst.iso"
	    set isoscan="${isofile} (testing)"
	    set isodist="debian.bookworm.netinst"
	    set preseed="auto=true file=/hd-media/preseed/debian/preseed.cfg netcfg/disable_autoconfig=true"
	    set locales="locales=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb3] ${isoscan}" ${locales} fsck.mode=skip ${preseed} ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Debian 11:bullseye' {
	    set isofile="/images/debian-11.7.0-amd64-netinst.iso"
	    set isoscan="${isofile} (stable - 11.7)"
	    set isodist="debian.bullseye.netinst"
	    set preseed="auto=true file=/hd-media/preseed/debian/preseed.cfg netcfg/disable_autoconfig=true"
	    set locales="locales=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb3] ${isoscan}" ${locales} fsck.mode=skip ${preseed} ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Debian 10:buster' {
	    set isofile="/images/debian-10.13.0-amd64-netinst.iso"
	    set isoscan="${isofile} (oldstable - 10.13)"
	    set isodist="debian.buster.netinst"
	    set preseed="auto=true file=/hd-media/preseed/debian/preseed_old.cfg netcfg/disable_autoconfig=true"
	    set locales="locales=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb3] ${isoscan}" ${locales} fsck.mode=skip ${preseed} ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Ubuntu 23.04:Lunar Lobster' {
	    set isofile="/images/ubuntu-23.04-live-server-amd64.iso"
	    set isoscan="iso-scan/filename=${isofile}"
	    set isodist="ubuntu.lunar.server"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/ubuntu.server/'
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/casper/${isodist}/vmlinuz.img root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip ${nocloud} ip=dhcp ipv6.disable=0 ---
	    initrd  (${cfgpart})/casper/${isodist}/initrd.img
	}
	menuentry 'Ubuntu 22.10:Kinetic Kudu' {
	    set isofile="/images/ubuntu-22.10-live-server-amd64.iso"
	    set isoscan="iso-scan/filename=${isofile}"
	    set isodist="ubuntu.kinetic.server"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/ubuntu.server/'
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/casper/${isodist}/vmlinuz.img root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip ${nocloud} ip=dhcp ipv6.disable=0 ---
	    initrd  (${cfgpart})/casper/${isodist}/initrd.img
	}
	menuentry 'Ubuntu 22.04:Jammy Jellyfish' {
	    set isofile="/images/ubuntu-22.04.2-live-server-amd64.iso"
	    set isoscan="iso-scan/filename=${isofile}"
	    set isodist="ubuntu.jammy.server"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/ubuntu.server/'
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/casper/${isodist}/vmlinuz.img root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip ${nocloud} ip=dhcp ipv6.disable=0 ---
	    initrd  (${cfgpart})/casper/${isodist}/initrd.img
	}
	menuentry 'Ubuntu 20.04:Focal Fossa' {
	    set isofile="/images/ubuntu-20.04.6-live-server-amd64.iso"
	    set isoscan="iso-scan/filename=${isofile}"
	    set isodist="ubuntu.focal.server"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/ubuntu.server/'
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/casper/${isodist}/vmlinuz.img root=${cfgpart} ${isoscan} ${locales} fsck.mode=skip ${nocloud} ip=dhcp ipv6.disable=0 ---
	    initrd  (${cfgpart})/casper/${isodist}/initrd.img
	}
	menuentry 'Ubuntu 18.04:Bionic Beaver' {
	    set isofile="/images/ubuntu-18.04.6-server-amd64.iso"
	    set isoscan="${isofile} (bionic - 18.04)"
	    set isodist="ubuntu.bionic.server"
	    set preseed="auto=true file=/hd-media/preseed/ubuntu/preseed_old.cfg netcfg/disable_autoconfig=true"
	    set locales="locales=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb3] ${isoscan}" ${locales} fsck.mode=skip ${preseed} ---
	    initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	}
	menuentry 'Fedora 38' {
	    set isofile="/images/Fedora-Server-netinst-x86_64-38-1.6.iso"
	    set hdlabel="Fedora-S-dvd-x86_64-38"
	    set ksstart="inst.ks=hd:/dev/sdb3:/kickstart/ks_fedora.cfg"
	    set isoscan="iso-scan/filename=${isofile}"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    loopback loop ($isopart)$isofile
	    linux  (loop)/images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${hdlabel} quiet ${isoscan} ${ksstart}
	    initrd (loop)/images/pxeboot/initrd.img
	    loopback --delete loop
	}
	menuentry 'AlmaLinux 9' {
	    set isofile="/images/AlmaLinux-9-latest-x86_64-boot.iso"
	    set hdlabel="AlmaLinux-9-2-x86_64-dvd"
	    set ksstart="inst.ks=hd:/dev/sdb3:/kickstart/ks_alma.cfg"
	    set isoscan="iso-scan/filename=${isofile}"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    loopback loop ($isopart)$isofile
	    linux  (loop)/images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${hdlabel} quiet ${isoscan} ${ksstart}
	    initrd (loop)/images/pxeboot/initrd.img
	    loopback --delete loop
	}
	menuentry 'Rocky 9' {
	    set isofile="/images/Rocky-9.1-x86_64-boot.iso"
	    set hdlabel="Rocky-9-1-x86_64-dvd"
	    set ksstart="inst.ks=hd:/dev/sdb3:/kickstart/ks_rocky.cfg"
	    set isoscan="iso-scan/filename=${isofile}"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    loopback loop ($isopart)$isofile
	    linux  (loop)/images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${hdlabel} quiet ${isoscan} ${ksstart}
	    initrd (loop)/images/pxeboot/initrd.img
	    loopback --delete loop
	}
	menuentry 'MIRACLELINUX 9' {
	    set isofile="/images/MIRACLELINUX-9.0-rtm-minimal-x86_64.iso"
	    set hdlabel="MIRACLE-LINUX-9-0-x86_64"
	    set ksstart="inst.ks=hd:/dev/sdb3:/kickstart/ks_miracle.cfg"
	    set isoscan="iso-scan/filename=${isofile}"
	    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	    if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	    echo "Loading ${isofile} ..."
	    loopback loop ($isopart)$isofile
	    linux  (loop)/images/pxeboot/vmlinuz inst.stage2=hd:LABEL=${hdlabel} quiet ${isoscan} ${ksstart}
	    initrd (loop)/images/pxeboot/initrd.img
	    loopback --delete loop
	}
	submenu '[ Live media ... ]' {
	    search.fs_label "ISOFILE" cfgpart hd1,gpt3
	    search.fs_label "ISOFILE" isopart hd1,gpt3
	    set menu_color_normal=cyan/blue
	    set menu_color_highlight=white/blue
	    set gfxpayload=keep
	    menuentry '[ Live system ]' {
	        true
	    }
	    menuentry 'Debian 12:bookworm' {
	        set isofile="/images/debian-live-bkworm-DI-rc2-amd64-lxde.iso"
	        set isoscan="${isofile} (bookworm - 12)"
	        set isodist="debian.bookworm.live"
	        set preseed="auto=true file=/hd-media/preseed/debian/preseed.cfg netcfg/disable_autoconfig=true"
	        set locales="locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	        echo "Loading ${isofile} ..."
	        linux   (${cfgpart})/live/${isodist}/vmlinuz.img root=${cfgpart} boot=live components quiet splash findiso=${isofile} ${locales} fsck.mode=skip
	        initrd  (${cfgpart})/live/${isodist}/initrd.img
	    }
	    menuentry 'Ubuntu 23.04:Lunar Lobster' {
	        set isofile="/images/ubuntu-23.04-desktop-amd64.iso"
	        set isoscan="iso-scan/filename=${isofile}"
	        set isodist="ubuntu.lunar.desktop"
	        set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	        set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/ubuntu.desktop/'
	        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	        echo "Loading ${isofile} ..."
	        linux   (${cfgpart})/casper/${isodist}/vmlinuz.img layerfs-path=minimal.standard.live.squashfs --- quiet splash ${isoscan} ${locales} fsck.mode=skip
	        initrd  (${cfgpart})/casper/${isodist}/initrd.img
	    }
	    menuentry '[ Unattended installation ]' {
	        true
	    }
	    menuentry 'Debian 12:bookworm' {
	        set isofile="/images/debian-live-bkworm-DI-rc2-amd64-lxde.iso"
	        set isoscan="${isofile} (bookworm - 12)"
	        set isodist="debian.bookworm.live"
	        set preseed="auto=true file=/hd-media/preseed/debian/preseed.cfg netcfg/disable_autoconfig=true"
	        set locales="locales=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	        echo "Loading ${isofile} ..."
	        linux   (${cfgpart})/install.amd/${isodist}/vmlinuz.img root=${cfgpart} iso-scan/ask_which_iso="[sdb3] ${isoscan}" ${locales} fsck.mode=skip ${preseed} ---
	        initrd  (${cfgpart})/install.amd/${isodist}/initrd.img
	    }
	    menuentry 'Ubuntu 23.04:Lunar Lobster' {
	        set isofile="/images/ubuntu-23.04-desktop-amd64.iso"
	        set isoscan="iso-scan/filename=${isofile}"
	        set isodist="ubuntu.lunar.desktop"
	        set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	        set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/ubuntu.desktop/'
	        if [ "${grub_platform}" = "efi" ]; then rmmod tpm; fi
	        echo "Loading ${isofile} ..."
	        linux   (${cfgpart})/casper/${isodist}/vmlinuz.img layerfs-path=minimal.standard.live.squashfs --- quiet splash ${isoscan} ${locales} fsck.mode=skip ${nocloud} ip=dhcp ipv6.disable=0 ---
	        initrd  (${cfgpart})/casper/${isodist}/initrd.img
	    }
	}
	menuentry '[ System command ]' {
	    true
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
  fncPrintf "unmount"
  umount ./usb/
}

# ### USB Device: [ /dev/sdX3 ] Data partition ################################
funcUSB_Device_Inst_File_partition () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}USB Device: Data partition [initramfs]${TXT_RESET}"
  # *** [ USB device: /dev/sdb3 ] ***
  # === mount /dev/sdX3 =======================================================
  fncPrintf "mount /dev/sdX3"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb3 ./usb/
  # === copy boot loader and setting files ====================================
  fncPrintf "copy boot loader and setting files"
  mkdir -p ./usb/install.amd \
           ./usb/live        \
           ./usb/casper
  nice -n 10 cp --preserve=timestamps -L -u -r ./img/install.amd/. ./usb/install.amd/
  nice -n 10 cp --preserve=timestamps -L -u -r ./img/live/.        ./usb/live/
  nice -n 10 cp --preserve=timestamps -L -u -r ./img/casper/.      ./usb/casper/
# cp --preserve=timestamps -L -u    ./cfg/ubuntu.server/user-data  ./usb/
# touch ./usb/meta-data
# touch ./usb/vendor-data
# touch ./usb/network-config
  # === unmount ===============================================================
  fncPrintf "unmount"
  umount ./usb/
}

# ### USB Device: [ /dev/sdX4 ] Data partition ################################
funcUSB_Device_Data_File_partition () {
  fncPrintf "${TXT_BLACK}${TXT_BYELLOW}USB Device: Data partition [iso file]${TXT_RESET}"
  # *** [ USB device: /dev/sdb3 ] ***
  # === mount /dev/sdX4 =======================================================
  fncPrintf "mount /dev/sdX4"
  rm -rf ./usb/
  mkdir -p ./usb
  mount /dev/sdb3 ./usb/
  # === copy iso files ========================================================
  fncPrintf "copy iso files"
  mkdir -p ./usb/images/
  for F in $(ls ./img/images)
  do
    fncPrintf "copy   file: ${F}"
    nice -n 10 cp --preserve=timestamps -L -u ./img/images/${F} ./usb/images/
  done
  cp --preserve=timestamps -L -u -r ./img/preseed/   ./usb/
  cp --preserve=timestamps -L -u -r ./img/nocloud/   ./usb/
  cp --preserve=timestamps -L -u -r ./img/kickstart/ ./usb/
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
  # --- test ------------------------------------------------------------------
#  funcColorTest
  # --- main ------------------------------------------------------------------
  fncPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"
  funcDownload "lnk"
  funcDownload "cfg"
  funcDownload "bld"
  funcDownload "iso"
  funcDownload "deb"
  funcDownload "arc"
  funcCopy_module
  funcUnpack_lnximg
  funcSelect_module
  funcMake_initramfs
  funcCopy_initramfs
  funcCopy_cfg_file
  funcCopy_iso_image
  funcUSB_Device_check
  funcUSB_Device_partition_and_format
  funcUSB_Device_Inst_Bootloader
  funcUSB_Device_Inst_GRUB
  funcUSB_Device_Inst_File_partition
  funcUSB_Device_Data_File_partition
  if [ -b /dev/sdb ]; then
    lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
  fi
  fncPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing end${TXT_RESET}"
}

# === main ====================================================================
main
# =============================================================================
# https://deb.debian.org/debian/pool/main/n/ntfs-3g/ntfs-3g_2022.10.3-1+b1_amd64.deb
# https://deb.debian.org/debian/pool/main/f/fuse3/fuse3_3.14.0-3_amd64.deb
# https://deb.debian.org/debian/pool/main/f/fuse/fuse_2.9.9-6+b1_amd64.deb
# ### eof #####################################################################
