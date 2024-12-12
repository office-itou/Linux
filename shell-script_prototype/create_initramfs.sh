#!/bin/bash

	case "${1:-}" in
		-dbg) set -x; shift;;
		*) ;;
	esac

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

# --- command parameter section -----------------------------------------------
#	declare -a    COMD_LINE=("${@:-}")

# --- system parameter section ------------------------------------------------
	OS_RELEASE=("$(cat /etc/os-release)")
#	OS_DISTRIBUTION="$(echo "${OS_RELEASE[@]}" |  awk -F '=' '$1=="ID" {gsub(/(^"|"$)/,"",$2); print tolower($2);}')"
#	OS_VERSION_ID="$(echo "${OS_RELEASE[@]}" | awk -F '=' '$1=="VERSION_ID" {gsub(/(^"|"$)/,"",$2); print $2;}')"
	OS_CODENAME="$(echo "${OS_RELEASE[@]}" |  awk -F '=' '$1=="VERSION_CODENAME" {gsub(/(^"|"$)/,"",$2); print tolower($2);}')"
	OS_KERNEL_VERSION="$(uname -r)"
	OS_ARCHITECTURES="${OS_KERNEL_VERSION##*-}"

#	declare -r -a OS_RELEASE
#	declare -r    OS_DISTRIBUTION		# ex.: debian
#	declare -r    OS_VERSION_ID			# ex.: 12
	declare -r    OS_CODENAME			# ex.: bookworm
	declare -r    OS_KERNEL_VERSION		# ex.: 6.1.0-25-amd64
	declare -r    OS_ARCHITECTURES		# ex.: amd64

#	declare -r    PROG_PATH="$0"
	declare -r    DIRS_WORK="${PWD}/workdir"
	declare -r    DIRS_TGET="${PWD}/filesys"
	declare -r    DIRS_KRNG="/home/master/share/keys"
	declare -r    TGET_ARCH="amd64"
	declare -r    TGET_PKGS="package"

# --- data parameter section --------------------------------------------------
	#  0: operation flags (o: execute, others: not execute)
	#  1: version
	#  2: code name
	#  3: kernel
	#  4: life
	#  5: release date
	#  6: end of support
	#  7: long term
	#  8: mirror
	#  9: components
	# 10: linux image file name

	declare -a    OS_VERSION_HISTORY_LIST=(                                                                                                         \
	    "x  debian-1.1      buzz        -                       EOL     1996-06-17  -           -           http://archive.debian.org/debian    "   \
	    "x  debian-1.2      rex         -                       EOL     1996-12-12  -           -           http://archive.debian.org/debian    "   \
	    "x  debian-1.3      bo          -                       EOL     1997-06-05  -           -           http://archive.debian.org/debian    "   \
	    "x  debian-2.0      hamm        -                       EOL     1998-07-24  -           -           http://archive.debian.org/debian    "   \
	    "x  debian-2.1      slink       -                       EOL     1999-03-09  2000-10-30  -           http://archive.debian.org/debian    "   \
	    "x  debian-2.2      potato      -                       EOL     2000-08-15  2003-06-30  -           http://archive.debian.org/debian    "   \
	    "x  debian-3.0      woody       -                       EOL     2002-07-19  2006-06-30  -           http://archive.debian.org/debian    "   \
	    "x  debian-3.1      sarge       -                       EOL     2005-06-06  2008-03-31  -           http://archive.debian.org/debian    "   \
	    "x  debian-4        etch        -                       EOL     2007-04-08  2010-02-15  -           http://archive.debian.org/debian    "   \
	    "x  debian-5        lenny       -                       EOL     2009-02-14  2012-02-06  -           http://archive.debian.org/debian    "   \
	    "x  debian-6        squeeze     -                       EOL     2011-02-06  2014-05-31  2016-02-29  http://archive.debian.org/debian    "   \
	    "x  debian-7        wheezy      -                       EOL     2013-05-04  2016-04-25  2018-05-31  http://archive.debian.org/debian    "   \
	    "x  debian-8        jessie      -                       EOL     2015-04-25  2018-06-17  2020-06-30  http://archive.debian.org/debian    "   \
	    "x  debian-9        stretch     -                       EOL     2017-06-17  2020-07-18  2022-06-30  http://archive.debian.org/debian    "   \
	    "o  debian-10       buster      4.19.0-21-_ARCH_-di     EOL     2019-07-06  2022-09-10  2024-06-30  http://deb.debian.org/debian        "   \
	    "o  debian-11       bullseye    5.10.0-32-_ARCH_-di     LTS     2021-08-14  2024-07-01  2026-06-01  http://deb.debian.org/debian        "   \
	    "o  debian-12       bookworm    6.1.0-27-_ARCH_-di      -       2023-06-10  2026-06-01  2028-06-01  http://deb.debian.org/debian        "   \
	    "o  debian-13       trixie      -                       -       2025-xx-xx  20xx-xx-xx  20xx-xx-xx  http://deb.debian.org/debian        "   \
	    "-  debian-14       forky       -                       -       2027-xx-xx  20xx-xx-xx  20xx-xx-xx  http://deb.debian.org/debian        "   \
	    "o  debian-sid      sid         6.10.9-_ARCH_-di        -       -           -           -           http://deb.debian.org/debian        "   \
	    "x  ubuntu-4.10     warty       -                       EOL     2004-10-20  2006-04-30  -           -                                   "   \
	    "x  ubuntu-5.04     hoary       -                       EOL     2005-04-08  2006-10-31  -           -                                   "   \
	    "x  ubuntu-5.10     breezy      -                       EOL     2005-10-12  2007-04-13  -           -                                   "   \
	    "x  ubuntu-6.06     dapper      -                       EOL     2006-06-01  2009-07-14  2011-06-01  -                                   "   \
	    "x  ubuntu-6.10     edgy        -                       EOL     2006-10-26  2008-04-25  -           -                                   "   \
	    "x  ubuntu-7.04     feisty      -                       EOL     2007-04-19  2008-10-19  -           -                                   "   \
	    "x  ubuntu-7.10     gutsy       -                       EOL     2007-10-18  2009-04-18  -           -                                   "   \
	    "x  ubuntu-8.04     hardy       -                       EOL     2008-04-24  2011-05-12  2013-05-09  -                                   "   \
	    "x  ubuntu-8.10     intrepid    -                       EOL     2008-10-30  2010-04-30  -           -                                   "   \
	    "x  ubuntu-9.04     jaunty      -                       EOL     2009-04-23  2010-10-23  -           -                                   "   \
	    "x  ubuntu-9.10     karmic      -                       EOL     2009-10-29  2011-04-30  -           -                                   "   \
	    "x  ubuntu-10.04    lucid       -                       EOL     2010-04-29  2013-05-09  2015-04-30  -                                   "   \
	    "x  ubuntu-10.10    maverick    -                       EOL     2010-10-10  2012-04-10  -           -                                   "   \
	    "x  ubuntu-11.04    natty       -                       EOL     2011-04-28  2012-10-28  -           -                                   "   \
	    "x  ubuntu-11.10    oneiric     -                       EOL     2011-10-13  2013-05-09  -           -                                   "   \
	    "x  ubuntu-12.04    precise     -                       EOL     2012-04-26  2017-04-28  2019-04-26  -                                   "   \
	    "x  ubuntu-12.10    quantal     -                       EOL     2012-10-18  2014-05-16  -           -                                   "   \
	    "x  ubuntu-13.04    raring      -                       EOL     2013-04-25  2014-01-27  -           -                                   "   \
	    "x  ubuntu-13.10    saucy       -                       EOL     2013-10-17  2014-07-17  -           -                                   "   \
	    "x  ubuntu-14.04    trusty      -                       EOL     2014-04-17  2019-04-25  2024-04-25  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-14.10    utopic      -                       EOL     2014-10-23  2015-07-23  -           -                                   "   \
	    "x  ubuntu-15.04    vivid       -                       EOL     2015-04-23  2016-02-04  -           -                                   "   \
	    "x  ubuntu-15.10    wily        -                       EOL     2015-10-22  2016-07-28  -           -                                   "   \
	    "-  ubuntu-16.04    xenial      -                       LTS     2016-04-21  2021-04-30  2026-04-23  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-16.10    yakkety     -                       EOL     2016-10-13  2017-07-20  -           -                                   "   \
	    "x  ubuntu-17.04    zesty       -                       EOL     2017-04-13  2018-01-13  -           -                                   "   \
	    "x  ubuntu-17.10    artful      -                       EOL     2017-10-19  2018-07-19  -           -                                   "   \
	    "-  ubuntu-18.04    bionic      4.15.0-20-generic-di    LTS     2018-04-26  2023-05-31  2028-04-26  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-18.10    cosmic      -                       EOL     2018-10-18  2019-07-18  -           -                                   "   \
	    "x  ubuntu-19.04    disco       -                       EOL     2019-04-18  2020-01-23  -           -                                   "   \
	    "x  ubuntu-19.10    eoan        -                       EOL     2019-10-17  2020-07-17  -           -                                   "   \
	    "o  ubuntu-20.04    focal       5.4.0-26-generic-di     -       2020-04-23  2025-05-29  2030-04-23  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-20.10    groovy      -                       EOL     2020-10-22  2021-07-22  -           -                                   "   \
	    "x  ubuntu-21.04    hirsute     -                       EOL     2021-04-22  2022-01-20  -           -                                   "   \
	    "x  ubuntu-21.10    impish      -                       EOL     2021-10-14  2022-07-14  -           -                                   "   \
	    "o  ubuntu-22.04    jammy       5.15.0-25-generic-di    -       2022-04-21  2027-06-01  2032-04-21  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-22.10    kinetic     -                       EOL     2022-10-20  2023-07-20  -           -                                   "   \
	    "x  ubuntu-23.04    lunar       -                       EOL     2023-04-20  2024-01-25  -           -                                   "   \
	    "x  ubuntu-23.10    mantic      -                       EOL     2023-10-12  2024-07-11  -           -                                   "   \
	    "o  ubuntu-24.04    noble       6.8.0-31-generic-di     -       2024-04-25  2029-05-31  2034-04-25  http://archive.ubuntu.com/ubuntu    "   \
	    "o  ubuntu-24.10    oracular    6.11.0-8-generic-di     -       2024-10-10  2025-07-xx  -           http://archive.ubuntu.com/ubuntu    "   \
	    "o  ubuntu-25.04    plucky      6.11.0-8-generic-di     -       2025-04-17  2026-01-xx  -           http://archive.ubuntu.com/ubuntu    "   \
	) # 0:  1:              2:          3:                      4:      5:          6:          7:          8:

	declare -r -a _PACKAGE_LIST_DEBIAN_NETINST=( \
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
	)

#	    fontconfig-udeb*.udeb \								# generic font configuration library - minimal runtime
#	    libfreetype6-udeb*.udeb \							# FreeType 2 font engine for the debian-installer

#	    libpango1.0-udeb*.udeb \							# Layout and rendering of internationalized text - minimal runtime
#	    libfontenc1-udeb*.udeb \							# X11 font encoding library
#	    libxfont2-udeb*.udeb \								# X11 font rasterisation library
#	    libxft2-udeb*.udeb \								# FreeType-based font drawing library for X

#	    fonts-sil-scheherazade-udeb*.udeb \					# Scheherazade font for the graphical installer
#	    fonts-ukij-uyghur-udeb*.udeb \						# uyghur font for the graphical installer (UKIJEkran)
#	    fonts-farsiweb-udeb*.udeb \							# Farsiweb TrueType fonts for the graphical installer
#	    fonts-freefont-udeb*.udeb \							# Freefont Sans fonts for the graphical installer

#	    lowmemcheck*.udeb \									# detect low-memory systems and enter lowmem mode

#	    media-retriever*.udeb \								# Fetches modules from removable media

#	    cdrom-checker*.udeb \								# Verify the cd contents
#	    cdrom-detect*.udeb \								# Detect CDROM devices and mount the CD
#	    cdrom-retriever*.udeb \								# Fetch modules from a CDROM
#	    load-cdrom*.udeb \									# Load installer components from CD

#-	    acpi-modules_KERNEL_VERSION_*.udeb \				# ACPI support modules
#n	    ata-modules_KERNEL_VERSION_*.udeb \					# ATA disk modules
#	    btrfs-modules_KERNEL_VERSION_*.udeb \				# BTRFS filesystem support
#n	    cdrom-core-modules_KERNEL_VERSION_*.udeb \			# CDROM support
#-	    crc-modules_KERNEL_VERSION_*.udeb \					# CRC modules
#	    crypto-dm-modules_KERNEL_VERSION_*.udeb \			# devicemapper crypto module
#-	    crypto-modules_KERNEL_VERSION_*.udeb \				# crypto modules
#	    efi-modules_KERNEL_VERSION_*.udeb \					# EFI modules
#	    event-modules_KERNEL_VERSION_*.udeb \				# Event support
#	    ext4-modules_KERNEL_VERSION_*.udeb \				# ext2/ext3/ext4 filesystem support
#	    f2fs-modules_KERNEL_VERSION_*.udeb \				# f2fs filesystem support
#-	    fat-modules_KERNEL_VERSION_*.udeb \					# FAT filesystem support
#-	    fb-modules_KERNEL_VERSION_*.udeb \					# Frame buffer support
#n	    firewire-core-modules_KERNEL_VERSION_*.udeb \		# Core FireWire drivers
#	    fuse-modules_KERNEL_VERSION_*.udeb \				# FUSE modules
#-	    i2c-modules_KERNEL_VERSION_*.udeb \					# i2c support modules
#-	    input-modules_KERNEL_VERSION_*.udeb \				# Input devices support
#n	    isofs-modules_KERNEL_VERSION_*.udeb \				# ISOFS filesystem support
#	    jfs-modules_KERNEL_VERSION_*.udeb \					# JFS filesystem support
#-	    kernel-image_KERNEL_VERSION_*.udeb \				# Linux kernel image and core modules for the Debian installer
#	    loop-modules_KERNEL_VERSION_*.udeb \				# Loopback filesystem support
#	    md-modules_KERNEL_VERSION_*.udeb \					# RAID and LVM support
#-	    mmc-core-modules_KERNEL_VERSION_*.udeb \			# MMC/SD/SDIO core modules
#-	    mmc-modules_KERNEL_VERSION_*.udeb \					# MMC/SD card modules
#	    mouse-modules_KERNEL_VERSION_*.udeb \				# Mouse support
#-	    mtd-core-modules_KERNEL_VERSION_*.udeb \			# MTD core
#	    multipath-modules_KERNEL_VERSION_*.udeb \			# Multipath support
#	    nbd-modules_KERNEL_VERSION_*.udeb \					# Network Block Device modules
#-	    nic-modules_KERNEL_VERSION_*.udeb \					# NIC drivers
#-	    nic-pcmcia-modules_KERNEL_VERSION_*.udeb \			# Common PCMCIA NIC drivers
#-	    nic-shared-modules_KERNEL_VERSION_*.udeb \			# Shared NIC drivers
#-	    nic-usb-modules_KERNEL_VERSION_*.udeb \				# USB NIC drivers
#-	    nic-wireless-modules_KERNEL_VERSION_*.udeb \		# Wireless NIC drivers
#n	    pata-modules_KERNEL_VERSION_*.udeb \				# PATA drivers
#-	    pcmcia-modules_KERNEL_VERSION_*.udeb \				# Common PCMCIA drivers
#n	    pcmcia-storage-modules_KERNEL_VERSION_*.udeb \		# PCMCIA storage drivers
#	    ppp-modules_KERNEL_VERSION_*.udeb \					# PPP drivers
#-	    rfkill-modules_KERNEL_VERSION_*.udeb \				# rfkill modules
#n	    sata-modules_KERNEL_VERSION_*.udeb \				# SATA drivers
#-	    scsi-core-modules_KERNEL_VERSION_*.udeb \			# Core SCSI subsystem
#n	    scsi-modules_KERNEL_VERSION_*.udeb \				# SCSI drivers
#	    scsi-nic-modules_KERNEL_VERSION_*.udeb \			# SCSI drivers for converged NICs
#-	    serial-modules_KERNEL_VERSION_*.udeb \				# Serial drivers
#	    sound-modules_KERNEL_VERSION_*.udeb \				# sound support
#	    speakup-modules_KERNEL_VERSION_*.udeb \				# speakup modules
#	    squashfs-modules_KERNEL_VERSION_*.udeb \			# squashfs modules
#	    udf-modules_KERNEL_VERSION_*.udeb \					# UDF modules
#-	    uinput-modules_KERNEL_VERSION_*.udeb \				# uinput support
#-	    usb-modules_KERNEL_VERSION_*.udeb \					# USB support
#-	    usb-serial-modules_KERNEL_VERSION_*.udeb \			# USB serial drivers
#-	    usb-storage-modules_KERNEL_VERSION_*.udeb \			# USB storage support
#	    xfs-modules_KERNEL_VERSION_*.udeb \					# XFS filesystem support

# -: the registration parameters for this shell.
# n: netinst mini.iso

# --- initial setup -----------------------------------------------------------
function funcInitial_setup() {
	declare       _PROC=""				#  0: operation flags (o: execute, others: not execute)
	declare       _DIST=""				#  1: version
	declare       _SUIT=""				#  2: code name
	declare       _KVER=""				#  3: kernel
	declare       _LIFE=""				#  4: life
	declare       _RDAY=""				#  5: release date
	declare       _EDAY=""				#  6: end of support
	declare       _LDAY=""				#  7: long term
	declare       _MIRR=""				#  8: mirror
	declare       _COMP=""				#  9: components
	declare       _LIMG=""				# 10: linux image file name
	declare       _VERS=""				# version id
	declare -a    _LIST=()
	declare -i    I=0

	for ((I=0; I<"${#OS_VERSION_HISTORY_LIST[@]}"; I++))
	do
		read -r -a _LIST < <(echo "${OS_VERSION_HISTORY_LIST[I]}")
		_PROC="${_LIST[0]}"
		_DIST="${_LIST[1]}"
		_SUIT="${_LIST[2]}"
		_KVER="${_LIST[3]}"
		_LIFE="${_LIST[4]}"
		_RDAY="${_LIST[5]}"
		_EDAY="${_LIST[6]}"
		_LDAY="${_LIST[7]}"
		_MIRR="${_LIST[8]}"
#		if [[ "${_PROC}" != "o" ]]; then
#			continue
#		fi
		case "${_DIST}" in
			debian-*)
				_COMP="main,contrib,non-free,non-free-firmware,main/debian-installer,contrib/debian-installer,non-free/debian-installer,non-free-firmware/debian-installer"
				_LIMG="linux-image-${TGET_ARCH}"
				_VERS="${_DIST##*-}"
				if [[ "${_VERS:-}" =~ ^-?[0-9]+\.?[0-9]*$ ]] && [[ "${_VERS%%.*}" -le 11 ]]; then
					_COMP="main,contrib,non-free,main/debian-installer,contrib/debian-installer,non-free/debian-installer"
				fi
				;;
			ubuntu-*)
				_COMP="main,multiverse,restricted,universe,main/debian-installer,multiverse/debian-installer,restricted/debian-installer,universe/debian-installer"
				_LIMG="linux-image-generic"
				;;
			*       )
				continue
				;;
		esac
		_LIST=( \
			"${_PROC}" \
			"${_DIST}" \
			"${_SUIT}" \
			"${_KVER}" \
			"${_LIFE}" \
			"${_RDAY}" \
			"${_EDAY}" \
			"${_LDAY}" \
			"${_MIRR}" \
			"${_COMP}" \
			"${_LIMG}" \
		)
		OS_VERSION_HISTORY_LIST[I]="${_LIST[*]}"
	done

#	declare -r -a OS_VERSION_HISTORY_LIST
}

# --- create base system ------------------------------------------------------
function funcCreate_base_system() {
	rm -rf "${DIRS_WORK:?}"
	mkdir -p "${DIRS_WORK:?}"
	mmdebstrap \
	    --variant=apt \
	    --mode=sudo \
	    --format=directory \
	    --keyring="${DIRS_KRNG:?}" \
	    --include='fakechroot gnupg bash-completion apt-listchanges apt-transport-https apt-utils' \
	    --components='main contrib non-free non-free-firmware' \
	    --architectures="${TGET_ARCH}" \
	    "${OS_CODENAME:?}" \
	    "${DIRS_WORK:?}"
}

# --- create sources.list.d ---------------------------------------------------
function funcCreate_sources_list_d() {
	declare       _PROC=""				#  0: operation flags (o: execute, others: not execute)
#	declare       _DIST=""				#  1: version
	declare       _SUIT=""				#  2: code name
#	declare       _KVER=""				#  3: kernel
#	declare       _LIFE=""				#  4: life
#	declare       _RDAY=""				#  5: release date
#	declare       _EDAY=""				#  6: end of support
#	declare       _LDAY=""				#  7: long term
	declare       _MIRR=""				#  8: mirror
	declare       _COMP=""				#  9: components
#	declare       _LIMG=""				# 10: linux image file name
#	declare       _VERS=""				# version id
	declare -a    _LIST=()
	declare -i    I=0

	for ((I=0; I<"${#OS_VERSION_HISTORY_LIST[@]}"; I++))
	do
		read -r -a _LIST < <(echo "${OS_VERSION_HISTORY_LIST[I]}")
		_PROC="${_LIST[0]}"
#		_DIST="${_LIST[1]}"
		_SUIT="${_LIST[2]}"
#		_KVER="${_LIST[3]}"
#		_LIFE="${_LIST[4]}"
#		_RDAY="${_LIST[5]}"
#		_EDAY="${_LIST[6]}"
#		_LDAY="${_LIST[7]}"
		_MIRR="${_LIST[8]}"
		_COMP="${_LIST[9]}"
#		_LIMG="${_LIST[10]}"
		if [[ "${_PROC}" != "o" ]]; then
			continue
		fi
		cat <<- _EOT_ > "${DIRS_WORK}/etc/apt/sources.list.d/${_SUIT}.list"
			deb ${_MIRR} ${_SUIT} ${_COMP//,/ }
_EOT_
	done
}

# --- install keyring ---------------------------------------------------------
function funcInstall_keyring() {
	rm -f debian-keyring_*.deb ubuntu-keyring_*.deb
	wget --quiet --timestamping http://deb.debian.org/debian/pool/main/d/debian-keyring/debian-keyring_2024.09.22_all.deb
	wget --quiet --timestamping http://archive.ubuntu.com/ubuntu/pool/main/u/ubuntu-keyring/ubuntu-keyring_2023.11.28.1_all.deb
	dpkg --install --root="${DIRS_WORK}" debian-keyring_*.deb ubuntu-keyring_*.deb > /dev/null
}

# --- apt-get update ----------------------------------------------------------
function funcApt_get_update() {
	declare -r    _FILE_PATH="${DIRS_WORK}/etc/apt/sources.list"
	declare -r -a _COMD=( \
	    "apt-get -q update;" \
	)

	if [[ -e "${_FILE_PATH}" ]]; then
		mv "${_FILE_PATH}" "${_FILE_PATH}.org"
	fi
	chroot "${DIRS_WORK:?}" bash -c "${_COMD[*]}"
}

# --- create initramfs --------------------------------------------------------
function funcCreate_initramfs() {
	declare -r -a _TGET=("$@")
	declare       _PROC=""				#  0: operation flags (o: execute, others: not execute)
	declare       _DIST=""				#  1: version
	declare       _SUIT=""				#  2: code name
#	declare       _KVER=""				#  3: kernel
#	declare       _LIFE=""				#  4: life
#	declare       _RDAY=""				#  5: release date
#	declare       _EDAY=""				#  6: end of support
#	declare       _LDAY=""				#  7: long term
	declare       _MIRR=""				#  8: mirror
	declare       _COMP=""				#  9: components
	declare       _LIMG=""				# 10: linux image file name
	declare       _VERS=""				# version id
	declare -a    _COMD=()
	declare       _LINE=""
	declare -a    _LIST=()
	declare -i    I=0
	declare -a    _PKGS=()				# package name list
	declare       _DPKG=""				# package file directory
	declare       _DTAG=""				# target filesystem directory
	declare       _KRNL=""				# kernel file name
	declare       _IRAM=""				# initramfs file name
	declare       _SORC=""				# source path name
	declare       _DIST=""				# destination path name
	declare       _PATH=""				# path name
	declare       _FILE=""				# file name
	declare -a    _HOOK=()

#	rm -rf "${DIRS_WORK:?}/${TGET_PKGS:?}"
#	rm -rf "${DIRS_TGET:?}"
	for ((I=0; I<"${#OS_VERSION_HISTORY_LIST[@]}"; I++))
	do
		read -r -a _LIST < <(echo "${OS_VERSION_HISTORY_LIST[I]}")
		_PROC="${_LIST[0]}"
		_DIST="${_LIST[1]}"
		_SUIT="${_LIST[2]}"
		_KVER="${_LIST[3]}"
		_LIFE="${_LIST[4]}"
		_RDAY="${_LIST[5]}"
		_EDAY="${_LIST[6]}"
		_LDAY="${_LIST[7]}"
		_MIRR="${_LIST[8]}"
		_COMP="${_LIST[9]}"
		_LIMG="${_LIST[10]}"
		_VERS="${_DIST##*-}"
		if [[ "${_PROC}" != "o" ]]; then
			continue
		fi
		if [[ -n "${_TGET[*]}" ]] && [[ ! "${_TGET[*]}" =~ ${_DIST} ]]; then
			continue
		fi
#		printf "\033[m\033[45m%s\033[m\n" "# --- ${_DIST} --- #"
		# --- get kernel version ----------------------------------------------
#		if [[ "${_DIST}" = "debian-sid" ]] \
#		&& [[ ${_KVER:?} != "-" ]]; then
#			_KVER="${_KVER//_ARCH_/${TGET_ARCH}}"
#			_KVER="${_KVER%-di}"
#		else
			_KRNL="linux_${_DIST:?}"
			if [[ -e "./${_KRNL:?}" ]]; then
				_KVER="$(file -L "${_KRNL}")"
				_KVER="${_KVER#*version }"
				_KVER="${_KVER%% *}"
			else
				_COMD=( \
				    "echo \"\$(apt-cache show \$(apt-cache depends -t '${_SUIT}' '${_LIMG}' | awk '/Depends: linux-image/ {print \$2;}') | awk '/Filename:/ {print \$2;}')\";" \
				)
				_LIMG="$(chroot "${DIRS_WORK:?}" bash -c "${_COMD[*]}")"
				_KVER="${_LIMG##*/linux-image-}"
				_KVER="${_KVER%%_*}"
			fi
#		fi
		printf "\033[m\033[45m%s\033[m\n" "# --- ${_DIST} (${_KVER}) --- #"
		_LIST=( \
			"${_PROC}" \
			"${_DIST}" \
			"${_SUIT}" \
			"${_KVER}" \
			"${_LIFE}" \
			"${_RDAY}" \
			"${_EDAY}" \
			"${_LDAY}" \
			"${_MIRR}" \
			"${_COMP}" \
			"${_LIMG}" \
		)
		OS_VERSION_HISTORY_LIST[I]="${_LIST[*]}"
		# --- set package file version ----------------------------------------
		case "${_DIST}" in
			debian-*) _PKGS=("${_PACKAGE_LIST_DEBIAN_NETINST[@]}");;
			ubuntu-*) _PKGS=("${_PACKAGE_LIST_DEBIAN_NETINST[@]}");;
			*       ) continue;;
		esac
		_PKGS=("${_PKGS[@]//_KERNEL_VERSION_/${_KVER:+"-${_KVER}"}}")
		_PKGS=("${_PKGS[@]//_VERSION_ID_/${_VERS}}")
		_PKGS=("${_PKGS[@]//_ARCH_/${TGET_ARCH}}")
		_PKGS=("${_PKGS[@]//i386/686}")
		case "${_DIST}" in
			debian-10 )
				_PKGS=("${_PKGS[@]//f2fs-modules*/}")
				_PKGS=("${_PKGS[@]//kmod-udeb*/}")
				_PKGS=("${_PKGS[@]//libacl1-udeb*/}")
				_PKGS=("${_PKGS[@]//libcap2-udeb*/}")
				_PKGS=("${_PKGS[@]//libcrypt1-udeb*/}")
				_PKGS=("${_PKGS[@]//libcrypto3-udeb/libcrypto1.1-udeb}")
				_PKGS=("${_PKGS[@]//libexpat1-udeb*/}")
				_PKGS=("${_PKGS[@]//libncursesw6-udeb*/}")
				_PKGS=("${_PKGS[@]//libpci3-udeb*/}")
				_PKGS=("${_PKGS[@]//libreadline8-udeb*/}")
				_PKGS=("${_PKGS[@]//libselinux1-udeb*/}")
				_PKGS=("${_PKGS[@]//libssl3-udeb/libssl1.1-udeb}")
				_PKGS=("${_PKGS[@]//readline-common-udeb*/}")
				_PKGS=("${_PKGS[@]//rfkill-modules*/}")
				_PKGS=("${_PKGS[@]//wireless-regdb-udeb*/}")
				_PKGS=("${_PKGS[@]//libgcc-s1*/}")
				;;
			debian-11 )
				_PKGS=("${_PKGS[@]//libacl1-udeb*/}")
				_PKGS=("${_PKGS[@]//libcrypto3-udeb/libcrypto1.1-udeb}")
				_PKGS=("${_PKGS[@]//libexpat1-udeb*/}")
				_PKGS=("${_PKGS[@]//libncursesw6-udeb*/}")
				_PKGS=("${_PKGS[@]//libreadline8-udeb*/}")
				_PKGS=("${_PKGS[@]//libselinux1-udeb*/}")
				_PKGS=("${_PKGS[@]//libssl3-udeb/libssl1.1-udeb}")
				_PKGS=("${_PKGS[@]//readline-common-udeb*/}")
				;;
			debian-12 )
				;;
			debian-13 )
				_PKGS=("${_PKGS[@]//acpi-modules-*/}")
				_PKGS=("${_PKGS[@]//crc-modules-*/}")
				_PKGS=("${_PKGS[@]//i2c-modules-*/}")
				;;
			debian-sid)
				_PKGS=("${_PKGS[@]//acpi-modules-*/}")
				_PKGS=("${_PKGS[@]//crc-modules-*/}")
				_PKGS=("${_PKGS[@]//i2c-modules-*/}")
				;;
			debian-*  )
				;;
			ubuntu-16.04)
				;;
			ubuntu-18.04)
				;;
			ubuntu-20.04)
				;;
			ubuntu-22.04)
				;;
			ubuntu-24.04)
				;;
			ubuntu-24.10)
				;;
			ubuntu-25.04)
				;;
			*)
				continue
				;;
		esac
		# --- extract-hook ----------------------------------------------------
		_HOOK=("dpkg --unpack --root=\"\$1\" \"\$1\"/var/cache/apt/archives/*.udeb || true;")
		case "${_DIST}" in
			debian-10 ) ;;
			*         ) _HOOK+=("dpkg --force-overwrite --unpack --root=\"\$1\" \"\$1\"/var/cache/apt/archives/kmod-udeb*.udeb || true;");;
		esac
		_HOOK+=("dpkg --force-overwrite --unpack --root=\"\$1\" \"\$1\"/var/cache/apt/archives/wget-udeb*.udeb || true;")
		_HOOK+=("dpkg --force-overwrite --install --root=\"\$1\" \"\$1\"/var/cache/apt/archives/debian-installer*.deb || true;")
		# --- create initramfs ------------------------------------------------
		_DPKG="${DIRS_WORK:?}/${TGET_PKGS:?}/${_DIST:?}"	# outside the chroot directory
		_DTAG="${DIRS_TGET:?}/${_DIST:?}"
		_PKGS=("${_PKGS[@]//\**/}")
		_LINE="${_PKGS[*]:?}"
		_LINE="${_LINE// /,}"
		rm -rf "${_DTAG:?}"
		mkdir -p "${_DTAG:?}"
		# shellcheck disable=SC2016
		mmdebstrap \
		    --variant=extract \
		    --mode=sudo \
		    --format=directory \
		    --keyring="${DIRS_KRNG:?}" \
		    --include="${_LINE:?}" \
		    --components="${_COMP:?}" \
		    --architectures="${TGET_ARCH:-${OS_ARCHITECTURES:?}}" \
		    ${_HOOK:+"--extract-hook=${_HOOK[*]}"} \
		    "${_SUIT:?}" \
		    "${_DTAG:?}" \
		    "${_MIRR:?}"
		# --- usr merge -------------------------------------------------------
		for _DIRS in bin sbin lib lib64
		do
			if [[ ! -e "${_DTAG:?}/${_DIRS}"/. ]] && [[ -e "${_DTAG:?}/usr/${_DIRS}"/. ]]; then
				ln -s "${_DTAG:?}/usr/${_DIRS}" "${_DTAG:?}"/
			fi
		done
#		for _DIRS in bin sbin lib lib64
#		do
#			mkdir -p "${_DTAG}/usr/${_DIRS}.work"
#			# --- file merge --------------------------------------------------
#			cp -ab "${_DTAG}/${_DIRS}"/.     "${_DTAG}/usr/${_DIRS}.work"/
#			cp -ab "${_DTAG}/usr/${_DIRS}"/. "${_DTAG}/usr/${_DIRS}.work"/
#			# --- relink ------------------------------------------------------
#		done
#
#		for _SORC in $(find "${_DTAG:?}"/bin/ -type f)
#		do
#			_FILE="${_SORC##*/}"
#			_PATH="${_SORC#${_DTAG:?}/}"
#			_DIST="${_DTAG:?}/usr/${_PATH}"
#			if [[ -e "${_DIST}" ]]; then
#				# --- same file -----------------------------------------------
#				if cmp --quiet "${_SORC}" "${_DTAG:?}"/usr/"${_SORC#${_DTAG:?}/}"; then
#					echo "copy skip: ${_PATH}"
#					continue
#				fi
#				# --- source is a symbolic link -------------------------------
#				if [[ -h "${_SORC}" ]]; then
#				fi
#			fi
#			cp -a "${_SORC}" "${_DTAG:?}"/usr/bin/
#		done
		# --- partial setup ---------------------------------------------------
		rm -rf "${_DTAG:?}"/etc/apt
		echo "${_SUIT:?}" > "${_DTAG:?}"/etc/default-release
		echo "host" > "${_DTAG:?}"/etc/hostname
		echo "127.0.0.1 localhost host" > "${_DTAG:?}"/etc/hosts
		echo "nameserver 127.0.0.1" > "${_DTAG:?}"/etc/resolv.conf
		# --- create initrd file ----------------------------------------------
		_IRAM="initrd.gz_${_DIST:?}"
		printf "\033[m\033[92m%s\033[m\n" "create ${_IRAM:?}"
		pushd "${_DTAG:?}" > /dev/null
			# shellcheck disable=SC2312
			find . | LC_ALL=C sort | cpio --quiet -R 0:0 --reproducible -o -H newc | gzip -q -k -9 > "../../${_IRAM:?}"
		popd > /dev/null
		ls -lh "./${_IRAM}"
	done

#	declare -r -a OS_VERSION_HISTORY_LIST
	#  0: operation flags (o: execute, others: not execute)
	#  1: version
	#  2: code name
	#  3: kernel
	#  4: life
	#  5: release date
	#  6: end of support
	#  7: long term
	#  8: mirror
	#  9: components
	# 10: linux image file name
	#   0:  1:              2:          3:                  4:      5:          6:          7:          8:                                  9:                                                                                                                                                  10:
	#   o   debian-11       bullseye    5.10.0-32-amd64     LTS     2021-08-14  2024-07-01  2026-06-01  http://deb.debian.org/debian        main,contrib,non-free,main/debian-installer,contrib/debian-installer,non-free/debian-installer                                                      pool/main/l/linux-signed-amd64/linux-image-5.10.0-32-amd64_5.10.223-1_amd64.deb
	#   o   debian-12       bookworm    6.1.0-27-amd64      -       2023-06-10  2026-06-01  2028-06-01  http://deb.debian.org/debian        main,contrib,non-free,non-free-firmware,main/debian-installer,contrib/debian-installer,non-free/debian-installer,non-free-firmware/debian-installer pool/main/l/linux-signed-amd64/linux-image-6.1.0-27-amd64_6.1.115-1_amd64.deb
	#   o   debian-13       trixie      6.11.7-amd64        -       2025-xx-xx  20xx-xx-xx  20xx-xx-xx  http://deb.debian.org/debian        main,contrib,non-free,non-free-firmware,main/debian-installer,contrib/debian-installer,non-free/debian-installer,non-free-firmware/debian-installer pool/main/l/linux-signed-amd64/linux-image-6.11.7-amd64_6.11.7-1_amd64.deb
	#   o   debian-sid      sid         6.11.9-amd64        -       -           -           -           http://deb.debian.org/debian        main,contrib,non-free,non-free-firmware,main/debian-installer,contrib/debian-installer,non-free/debian-installer,non-free-firmware/debian-installer pool/main/l/linux-signed-amd64/linux-image-6.11.9-amd64_6.11.9-1_amd64.deb
	#   o   ubuntu-20.04    focal       5.4.0-26-generic    -       2020-04-23  2025-05-29  2030-04-23  http://archive.ubuntu.com/ubuntu    main,multiverse,restricted,universe,main/debian-installer,multiverse/debian-installer,restricted/debian-installer,universe/debian-installer         pool/main/l/linux-signed/linux-image-5.4.0-26-generic_5.4.0-26.30_amd64.deb
	#   o   ubuntu-22.04    jammy       5.15.0-25-generic   -       2022-04-21  2027-06-01  2032-04-21  http://archive.ubuntu.com/ubuntu    main,multiverse,restricted,universe,main/debian-installer,multiverse/debian-installer,restricted/debian-installer,universe/debian-installer         pool/main/l/linux-signed/linux-image-5.15.0-25-generic_5.15.0-25.25_amd64.deb
	#   o   ubuntu-24.04    noble       6.8.0-31-generic    -       2024-04-25  2029-05-31  2034-04-25  http://archive.ubuntu.com/ubuntu    main,multiverse,restricted,universe,main/debian-installer,multiverse/debian-installer,restricted/debian-installer,universe/debian-installer         pool/main/l/linux-signed/linux-image-6.8.0-31-generic_6.8.0-31.31_amd64.deb
	#   o   ubuntu-24.10    oracular    6.11.0-8-generic    -       2024-10-10  2025-07-xx  -           http://archive.ubuntu.com/ubuntu    main,multiverse,restricted,universe,main/debian-installer,multiverse/debian-installer,restricted/debian-installer,universe/debian-installer         pool/main/l/linux-signed/linux-image-6.11.0-8-generic_6.11.0-8.8_amd64.deb
	#   o   ubuntu-25.04    plucky      6.11.0-8-generic    -       2025-04-17  2026-01-xx  -           http://archive.ubuntu.com/ubuntu    main,multiverse,restricted,universe,main/debian-installer,multiverse/debian-installer,restricted/debian-installer,universe/debian-installer         pool/main/l/linux-signed/linux-image-6.11.0-8-generic_6.11.0-8.8_amd64.deb
}

# --- main --------------------------------------------------------------------
#	declare -r    OLD_IFS="${IFS}"
	declare       _FOCE=""
	declare -a    _TGET=()

	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			-d | --debug ) set -x;;
			-f | --force ) _FOCE="true";;
			debian-*     ) _TGET+=("${1}");;
			ubuntu-*     ) _TGET+=("${1}");;
			* ) ;;
		esac
		shift
	done

	funcInitial_setup
	if [[ -n "${_FOCE:-}" ]] || [[ ! -d "${DIRS_WORK:?}/." ]]; then
		funcCreate_base_system
		funcCreate_sources_list_d
		funcInstall_keyring
		funcApt_get_update
	fi
	funcCreate_initramfs "${_TGET[@]:-}"

# --- exit --------------------------------------------------------------------
	exit 0

# --- eof ---------------------------------------------------------------------
