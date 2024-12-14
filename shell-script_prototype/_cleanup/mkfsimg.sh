#!/bin/bash

set -e
set -u

rm -rf "fsimg"
mkdir -p "fsimg"
# shellcheck disable=SC2016
mmdebstrap \
    --variant=extract \
    --mode=sudo \
    --format=directory \
    --keyring=/home/master/share/keys \
    --include=" \
    debian-installer*.deb \
    acpi-modules_KERNEL_VERSION_*.udeb \
    anna*.udeb \
    archdetect*.udeb \
    bogl-bterm-udeb*.udeb \
    brltty-udeb*.udeb \
    busybox-udeb*.udeb \
    ca-certificates-udeb*.udeb \
    cdebconf-newt-terminal*.udeb \
    cdebconf-newt-udeb*.udeb \
    cdebconf-priority*.udeb \
    cdebconf-text-udeb*.udeb \
    cdebconf-udeb*.udeb \
    choose-mirror*.udeb \
    choose-mirror-bin*.udeb \
    console-setup-pc-ekmap*.udeb \
    console-setup-udeb*.udeb \
    crc-modules_KERNEL_VERSION_*.udeb \
    crypto-modules_KERNEL_VERSION_*.udeb \
    debian-archive-keyring-udeb*.udeb \
    di-utils*.udeb \
    di-utils-reboot*.udeb \
    di-utils-shell*.udeb \
    di-utils-terminfo*.udeb \
    download-installer*.udeb \
    env-preseed*.udeb \
    ethdetect*.udeb \
    fat-modules_KERNEL_VERSION_*.udeb \
    fb-modules_KERNEL_VERSION_*.udeb \
    file-preseed*.udeb \
    gpgv-udeb*.udeb \
    haveged-udeb*.udeb \
    hw-detect*.udeb \
    i2c-modules_KERNEL_VERSION_*.udeb \
    initrd-preseed*.udeb \
    input-modules_KERNEL_VERSION_*.udeb \
    installation-locale*.udeb \
    kbd-udeb*.udeb \
    kernel-image_KERNEL_VERSION_*.udeb \
    kmod-udeb*.udeb \
    libacl1-udeb*.udeb \
    libasound2-udeb*.udeb \
    libblkid1-udeb*.udeb \
    libc6-udeb*.udeb \
    libcap2-udeb*.udeb \
    libcrypt1-udeb*.udeb \
    libcrypto3-udeb*.udeb \
    libdebconfclient0-udeb*.udeb \
    libdebian-installer4-udeb*.udeb \
    libexpat1-udeb*.udeb \
    libfribidi0-udeb*.udeb \
    libgcrypt20-udeb*.udeb \
    libgpg-error0-udeb*.udeb \
    libiw30-udeb*.udeb \
    libkmod2-udeb*.udeb \
    libncursesw6-udeb*.udeb \
    libnewt0.52-udeb*.udeb \
    libnl-3-200-udeb*.udeb \
    libnl-genl-3-200-udeb*.udeb \
    libpci3-udeb*.udeb \
    libpcre2-8-0-udeb*.udeb \
    libreadline8-udeb*.udeb \
    libselinux1-udeb*.udeb \
    libslang2-udeb*.udeb \
    libssl3-udeb*.udeb \
    libtextwrap1-udeb*.udeb \
    libtinfo6-udeb*.udeb \
    libudev1-udeb*.udeb \
    libuuid1-udeb*.udeb \
    localechooser*.udeb \
    lowmemcheck*.udeb \
    main-menu*.udeb \
    media-retriever*.udeb \
    mmc-core-modules_KERNEL_VERSION_*.udeb \
    mmc-modules_KERNEL_VERSION_*.udeb \
    mountmedia*.udeb \
    mtd-core-modules_KERNEL_VERSION_*.udeb \
    nano-udeb*.udeb \
    ndisc6-udeb*.udeb \
    net-retriever*.udeb \
    netcfg*.udeb \
    network-preseed*.udeb \
    nic-modules_KERNEL_VERSION_*.udeb \
    nic-pcmcia-modules_KERNEL_VERSION_*.udeb \
    nic-shared-modules_KERNEL_VERSION_*.udeb \
    nic-usb-modules_KERNEL_VERSION_*.udeb \
    nic-wireless-modules_KERNEL_VERSION_*.udeb \
    pciutils-udeb*.udeb \
    pcmcia-modules_KERNEL_VERSION_*.udeb \
    pcmciautils-udeb*.udeb \
    preseed-common*.udeb \
    rdnssd-udeb*.udeb \
    readline-common-udeb*.udeb \
    rescue-check*.udeb \
    rfkill-modules_KERNEL_VERSION_*.udeb \
    rootskel*.udeb \
    save-logs*.udeb \
    screen-udeb*.udeb \
    scsi-core-modules_KERNEL_VERSION_*.udeb \
    serial-modules_KERNEL_VERSION_*.udeb \
    udev-udeb*.udeb \
    udpkg*.udeb \
    uinput-modules_KERNEL_VERSION_*.udeb \
    usb-modules_KERNEL_VERSION_*.udeb \
    usb-serial-modules_KERNEL_VERSION_*.udeb \
    usb-storage-modules_KERNEL_VERSION_*.udeb \
    util-linux-udeb*.udeb \
    wget-udeb*.udeb \
    wide-dhcpv6-client-udeb*.udeb \
    wireless-regdb-udeb*.udeb \
    wpasupplicant-udeb*.udeb \
    zlib1g-udeb*.udeb \
    libatomic1*.deb \
    libgcc-s1*.deb \
    user-mode-linux*.deb \
    bterm-unifont*.deb \
    fuse3-udeb*.udeb \
    nfs-common*.deb \
    smbclient*.deb \
    ntfs-3g-udeb*.udeb \
    exfat-fuse*.deb \
    apt-setup-udeb*.udeb \
    apt-mirror*.deb \
    openssh-server-udeb*.udeb \
    openssh-client-udeb*.udeb \
    vim-common*.deb \
    vim-tiny*.deb \
    " \
    --components="main,contrib,non-free,non-free-firmware,main/debian-installer,contrib/debian-installer,non-free/debian-installer,non-free-firmware/debian-installer" \
    --architectures="amd64" \
    --extract-hook='mkdir -p "$1"/etc/console-setup' \
    --extract-hook='cp -a "$1"/lib/x86_64-linux-gnu/libgcc_s.so.1 "$1"/lib' \
    --extract-hook='cp -a "$1"/usr/lib/uml/modules/*/modules.* "$1"/lib/modules/*/' \
    --extract-hook='dpkg --unpack --root="$1" "$1"/var/cache/apt/archives/*.udeb || true' \
    --extract-hook='dpkg --force-overwrite --unpack --root="$1" "$1"/var/cache/apt/archives/kmod-udeb*.udeb || true' \
    --extract-hook='dpkg --force-overwrite --unpack --root="$1" "$1"/var/cache/apt/archives/wget-udeb*.udeb || true' \
    --extract-hook='dpkg --force-overwrite --install --root="$1" "$1"/var/cache/apt/archives/debian-installer*.deb || true' \
    bookworm \
    "fsimg"

# linux-image-6.1.0-27-amd64
# apt-cdrom-setup

rm -rf "fsimg"/etc/apt
echo "bookworm" > "fsimg"/etc/default-release
echo "host" > "fsimg"/etc/hostname
echo "127.0.0.1 localhost host" > "fsimg"/etc/hosts
echo "nameserver 127.0.0.1" > "fsimg"/etc/resolv.conf

pushd "fsimg" > /dev/null
	# shellcheck disable=SC2312
	find . | LC_ALL=C sort | cpio --quiet -R 0:0 --reproducible -o -H newc | gzip -q -k -9 > "../initrd.gz"
popd > /dev/null
ls -lh "./initrd.gz"

