#!/bin/bash

	case "${1:-}" in
		-dbg) set -x; shift;;
		*) ;;
	esac

	set -e
	set -u

	_OS_RELEASE=("$(cat /etc/os-release)")
	_OS_DISTRIBUTION="$(echo "${_OS_RELEASE[@]}" |  awk -F '=' '$1=="ID" {gsub(/(^"|"$)/,"",$2); print tolower($2);}')"
	_OS_VERSION_ID="$(echo "${_OS_RELEASE[@]}" | awk -F '=' '$1=="VERSION_ID" {gsub(/(^"|"$)/,"",$2); print $2;}')"
	_OS_CODENAME="$(echo "${_OS_RELEASE[@]}" |  awk -F '=' '$1=="VERSION_CODENAME" {gsub(/(^"|"$)/,"",$2); print tolower($2);}')"
	_OS_KERNEL_VERSION="$(uname -r)"
	_OS_ARCHITECTURES="${_OS_KERNEL_VERSION##*-}"

	declare -r -a _OS_RELEASE
	declare -r    _OS_DISTRIBUTION		# ex.: debian
	declare -r    _OS_VERSION_ID		# ex.: 12
	declare -r    _OS_CODENAME			# ex.: bookworm
	declare -r    _OS_KERNEL_VERSION	# ex.: 6.1.0-25-amd64
	declare -r    _OS_ARCHITECTURES		# ex.: amd64

	# 0: operation flags (o: execute, others: not execute)
	# 1: version
	# 2: code name
	# 3: kernel
	# 4: life
	# 5: release date
	# 6: end of support
	# 7: long term
	# 8: mirror

	declare -r -a _OS_VERSION_HISTORY_LIST=(                                                                                                        \
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
	    "o  debian-10       buster      4.19.0-21-_ARCH_-di     EOL     2019-07-06  2022-09-10  2024-06-30  http://archive.debian.org/debian    "   \
	    "o  debian-11       bullseye    5.10.0-32-_ARCH_-di     LTS     2021-08-14  2024-07-01  2026-06-01  http://deb.debian.org/debian        "   \
	    "o  debian-12       bookworm    6.1.0-27-_ARCH_-di      -       2023-06-10  2026-06-01  2028-06-01  http://deb.debian.org/debian        "   \
	    "o  debian-13       trixie      -                       -       2025-xx-xx  20xx-xx-xx  20xx-xx-xx  http://deb.debian.org/debian        "   \
	    "-  debian-14       forky       -                       -       2027-xx-xx  20xx-xx-xx  20xx-xx-xx  http://deb.debian.org/debian        "   \
	    "o  debian-sid      sid         6.10.11-_ARCH_-di       -       -           -           -           http://deb.debian.org/debian        "   \
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
	    "x  ubuntu-16.04    xenial      -                       LTS     2016-04-21  2021-04-30  2026-04-23  http://archive.ubuntu.com/ubuntu    "   \
	    "x  ubuntu-16.10    yakkety     -                       EOL     2016-10-13  2017-07-20  -           -                                   "   \
	    "x  ubuntu-17.04    zesty       -                       EOL     2017-04-13  2018-01-13  -           -                                   "   \
	    "x  ubuntu-17.10    artful      -                       EOL     2017-10-19  2018-07-19  -           -                                   "   \
	    "o  ubuntu-18.04    bionic      4.15.0-20-generic-di    LTS     2018-04-26  2023-05-31  2028-04-26  http://archive.ubuntu.com/ubuntu    "   \
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

	declare       _TARGET_VERSION="${_OS_DISTRIBUTION:?}-${_OS_VERSION_ID:?}"
	declare       _TARGET_SUITE="${_OS_CODENAME:?}"
	declare       _TARGET_DIRECTORY=""
	declare       _TARGET_MIRROR=""
	declare       _TARGET_KERNEL="${_OS_KERNEL_VERSION:?}"
	declare       _ARCHITECTURES="${_OS_ARCHITECTURES:?}"

	declare -r -a _VARIANT_LIST=(extract custom essential apt required minbase buildd important debootstrap - standard)
	declare       _VARIANT="${_VARIANT_LIST[0]}"

	declare -r -a _MODE_LIST=(auto sudo root unshare fakeroot fakechroot chrootless)
	declare       _MODE="${_MODE_LIST[1]}"

	declare -r -a _FORMAT_LIST=(auto directory tar squashfs ext2 null)
	declare       _FORMAT="${_FORMAT_LIST[1]}"

	declare       _APTOPT=""

	declare       _KEYRING="/home/master/share/keys"

	declare       _DPKGOPT=""

	declare -r -a _INCLUDE_LIST=( \
	    acpi-modules_KERNEL_VERSION_ \
	    anna \
	    archdetect \
	    ata-modules_KERNEL_VERSION_ \
	    bogl-bterm-udeb \
	    brltty-udeb \
	    busybox-udeb \
	    ca-certificates-udeb \
	    cdebconf-newt-terminal \
	    cdebconf-newt-udeb \
	    cdebconf-priority \
	    cdebconf-text-udeb \
	    cdebconf-udeb \
	    cdrom-checker \
	    cdrom-core-modules_KERNEL_VERSION_ \
	    cdrom-detect \
	    cdrom-retriever \
	    choose-mirror \
	    choose-mirror-bin \
	    console-setup-pc-ekmap \
	    console-setup-udeb \
	    crc-modules_KERNEL_VERSION_ \
	    crypto-modules_KERNEL_VERSION_ \
	    debian-archive-keyring-udeb \
	    debian-installer \
	    di-utils \
	    di-utils-reboot \
	    di-utils-shell \
	    di-utils-terminfo \
	    download-installer \
	    env-preseed \
	    ethdetect \
	    ext4-modules_KERNEL_VERSION_ \
	    fat-modules_KERNEL_VERSION_ \
	    fb-modules_KERNEL_VERSION_ \
	    file-preseed \
	    firewire-core-modules_KERNEL_VERSION_ \
	    gpgv-udeb \
	    haveged-udeb \
	    hw-detect \
	    i2c-modules_KERNEL_VERSION_ \
	    initrd-preseed \
	    input-modules_KERNEL_VERSION_ \
	    installation-locale \
	    iso-scan \
	    isofs-modules_KERNEL_VERSION_ \
	    kbd-udeb \
	    kernel-image_KERNEL_VERSION_ \
	    kmod-udeb \
	    libacl1-udeb \
	    libaio1-udeb \
	    libasound2-udeb \
	    libblkid1-udeb \
	    libc6-udeb \
	    libcap2-udeb \
	    libcrypt1-udeb \
	    libcrypto3-udeb \
	    libdebconfclient0-udeb \
	    libdebian-installer4-udeb \
	    libexpat1-udeb \
	    libfribidi0-udeb \
	    libgcrypt20-udeb \
	    libgpg-error0-udeb \
	    libiw30-udeb \
	    libkmod2-udeb \
	    libncursesw6-udeb \
	    libnewt0.52-udeb \
	    libnl-3-200-udeb \
	    libnl-genl-3-200-udeb \
	    libpci3-udeb \
	    libpcre2-8-0-udeb \
	    libreadline8-udeb \
	    libselinux1-udeb \
	    libslang2-udeb \
	    libssl3-udeb \
	    libtextwrap1-udeb \
	    libtinfo6-udeb \
	    libudev1-udeb \
	    libuuid1-udeb \
	    load-cdrom \
	    load-iso \
	    localechooser \
	    loop-modules_KERNEL_VERSION_ \
	    lowmemcheck \
	    lvm2-udeb \
	    main-menu \
	    md-modules_KERNEL_VERSION_ \
	    media-retriever \
	    mmc-core-modules_KERNEL_VERSION_ \
	    mmc-modules_KERNEL_VERSION_ \
	    mountmedia \
	    mtd-core-modules_KERNEL_VERSION_ \
	    nano-udeb \
	    ndisc6-udeb \
	    net-retriever \
	    netcfg \
	    network-preseed \
	    nic-modules_KERNEL_VERSION_ \
	    nic-pcmcia-modules_KERNEL_VERSION_ \
	    nic-shared-modules_KERNEL_VERSION_ \
	    nic-usb-modules_KERNEL_VERSION_ \
	    nic-wireless-modules_KERNEL_VERSION_ \
	    pata-modules_KERNEL_VERSION_ \
	    pciutils-udeb \
	    pcmcia-modules_KERNEL_VERSION_ \
	    pcmcia-storage-modules_KERNEL_VERSION_ \
	    pcmciautils-udeb \
	    preseed-common \
	    rdnssd-udeb \
	    readline-common-udeb \
	    rescue-check \
	    rfkill-modules_KERNEL_VERSION_ \
	    rootskel \
	    sata-modules_KERNEL_VERSION_ \
	    save-logs \
	    screen-udeb \
	    scsi-core-modules_KERNEL_VERSION_ \
	    scsi-modules_KERNEL_VERSION_ \
	    serial-modules_KERNEL_VERSION_ \
	    udev-udeb \
	    udpkg \
	    uinput-modules_KERNEL_VERSION_ \
	    usb-modules_KERNEL_VERSION_ \
	    usb-serial-modules_KERNEL_VERSION_ \
	    usb-storage-modules_KERNEL_VERSION_ \
	    util-linux-udeb \
	    wget-udeb \
	    wide-dhcpv6-client-udeb \
	    wireless-regdb-udeb \
	    wpasupplicant-udeb \
	    zlib1g-udeb \
	    vim-common \
	    vim-tiny \
	    libatomic1 \
	)
#	    linux-image-_ARCH_ \
#	    user-mode-linux \
#	    bash \
#	    dpkg \
#	    diffutils \
#	    libc-bin \
#	    tar \
#	    sensible-utils \
#	    debian-installer-launcher \
#	    debian-installer-_VERSION_ID_-netboot-_ARCH_ \
#	    di-utils-exit-installer \
#	    di-utils-mapdevfs \
#	    libgcc-s1 \
#	    vim-common \
#	    vim-tiny \
#	)

	declare       _INCLUDE=""
	_INCLUDE="$(printf "%s," "${_INCLUDE_LIST[@]}")"
	_INCLUDE="${_INCLUDE%%,}"

	declare -r -a _COMPONENTS_LIST=(main contrib non-free non-free-firmware main/debian-installer contrib/debian-installer non-free/debian-installer non-free-firmware/debian-installer)
	declare       _COMPONENTS=""
	_COMPONENTS="$(printf "%s," "${_COMPONENTS_LIST[@]}")"
	_COMPONENTS="${_COMPONENTS%%,}"

#	_ARCHITECTURES="amd64"

	_SIMULATE=""

	_SETUP_HOOK=""
	_EXTRACT_HOOK=""
	_ESSENTIAL_HOOK=""
	_CUSTOMIZE_HOOK=""
	_HOOK_DIRECTORY=""

	_SKIP=""

	_QUIET=""
	_VERBOSE=""
	_DEBUG=""
	_LOGFILE=""

	declare       _LINE=""
	declare -a    _LIST=()

	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			--dbgout) set -x;;
			debian-*          | \
			ubuntu-*          )
				_TARGET_VERSION=""
				for _LINE in "${_OS_VERSION_HISTORY_LIST[@]}"
				do
					read -r -a _LIST < <(echo "${_LINE}")
					if [[ "${_LIST[0]}" != "o" ]]; then
						continue
					fi
					if [[ "${_LIST[1]}" != "${1}" ]]; then
						continue
					fi
					_TARGET_VERSION="${_LIST[1]}"
					_TARGET_SUITE="${_LIST[2]}"
					_TARGET_KERNEL="${_LIST[3]}"
					_TARGET_MIRROR="${_LIST[8]}"
					break
				done
				;;
			--suite=*         )
				_TARGET_SUITE=""
				for _LINE in "${_OS_VERSION_HISTORY_LIST[@]}"
				do
					read -r -a _LIST < <(echo "${_LINE}")
					if [[ "${_LIST[0]}" != "o" ]]; then
						continue
					fi
					if [[ "${_LIST[2]}" != "${1#--suite=}" ]]; then
						continue
					fi
					_TARGET_VERSION="${_LIST[1]}"
					_TARGET_SUITE="${_LIST[2]}"
					_TARGET_KERNEL="${_LIST[3]}"
					_TARGET_MIRROR="${_LIST[8]}"
					break
				done
				;;
			--target=*        ) _TARGET_DIRECTORY="${1#--target=}";;
			--mirror=*        ) _TARGET_MIRROR="${1#--mirror=}";;
			-h | --help       | \
			--man             | \
			--version         ) mmdebstrap "${@}"; exit;;
			--variant=*       ) _VARIANT="${1#--variant=}";;
			--mode=*          ) _MODE="${1#--mode=}";;
			--format=*        ) _FORMAT="${1#--format=}";;
			--aptopt=*        ) _APTOPT="${1#--aptopt=}";;
			--keyring=*       ) _KEYRING="${1#--keyring=}";;
			--dpkgopt=*       ) _DPKGOPT="${1#--dpkgopt=}";;
			--include=*       ) _INCLUDE="${1#--include=}";;
			--components=*    ) _COMPONENTS="${1#--components=}";;
			--architectures=* ) _ARCHITECTURES="${1#--architectures=}";;
			--simulate        ) _SIMULATE="true";;
			--setup-hook=*    ) _SETUP_HOOK="${1#--setup-hook=}";;
			--extract-hook=*  ) _EXTRACT_HOOK="${1#--extract-hook=}";;
			--essential-hook=*) _ESSENTIAL_HOOK="${1#--essential-hook=}";;
			--customize-hook=*) _CUSTOMIZE_HOOK="${1#--customize-hook=}";;
			--hook-directory=*) _HOOK_DIRECTORY="${1#--hook-directory=}";;
			--skip=*          ) _SKIP="${1#--skip=}";;
			-q | --quiet      ) _QUIET="true";;
			-v | --verbose    ) _VERBOSE="true";;
			-d | --debug      ) _DEBUG="true";;
			--logfile=*       ) _LOGFILE="${1#--logfile=}";;
			*                 ) mmdebstrap "${@}"; exit;;
		esac
		shift
	done

	_INCLUDE="${_INCLUDE//_KERNEL_VERSION_/${_TARGET_KERNEL:+"-${_TARGET_KERNEL}"}}"
	_INCLUDE="${_INCLUDE//_VERSION_ID_/${_TARGET_VERSION##*-}}"
	_INCLUDE="${_INCLUDE//_ARCH_/${_ARCHITECTURES}}"
	_INCLUDE="${_INCLUDE//i386/686}"

	_TARGET_SUFFIX="${_TARGET_VERSION:?}-${_TARGET_SUITE:?}-${_ARCHITECTURES:?}"
	_TARGET_DIRECTORY="./initramfs-${_TARGET_SUFFIX:?}"
	_INITRD="initrd.gz-${_TARGET_SUFFIX:?}"

	_FILE_PATH="./hook.sh"
	# shellcheck disable=SC2312
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		dpkg                   --root="$1" --unpack  "$1"/var/cache/apt/archives/*.udeb                 || true
		dpkg --force-overwrite --root="$1" --unpack  "$1"/var/cache/apt/archives/kmod-udeb*.udeb        || true
		dpkg --force-overwrite --root="$1" --unpack  "$1"/var/cache/apt/archives/wget-udeb*.udeb        || true
		dpkg                   --root="$1" --install "$1"/var/cache/apt/archives/debian-installer_*.deb || true
_EOT_
	chmod +x "${_FILE_PATH}"
	_EXTRACT_HOOK="${_FILE_PATH} \"\$1\""

	_OPTION=( \
	    ${_VARIANT:+"--variant=${_VARIANT}"} \
	    ${_MODE:+"--mode=${_MODE}"} \
	    ${_FORMAT:+"--format=${_FORMAT}"} \
	    ${_APTOPT:+"--aptopt=${_APTOPT}"} \
	    ${_KEYRING:+"--keyring=${_KEYRING}"} \
	    ${_DPKGOPT:+"--dpkgopt=${_DPKGOPT}"} \
	    ${_INCLUDE:+"--include=${_INCLUDE}"} \
	    ${_COMPONENTS:+"--components=${_COMPONENTS}"} \
	    ${_ARCHITECTURES:+"--architectures=${_ARCHITECTURES}"} \
	    ${_SIMULATE:+"--simulate"} \
	    ${_SETUP_HOOK:+"--setup-hook=${_SETUP_HOOK}"} \
	    ${_EXTRACT_HOOK:+"--extract-hook=${_EXTRACT_HOOK}"} \
	    ${_ESSENTIAL_HOOK:+"--essential-hook=${_ESSENTIAL_HOOK}"} \
	    ${_CUSTOMIZE_HOOK:+"--customize-hook=${_CUSTOMIZE_HOOK}"} \
	    ${_HOOK_DIRECTORY:+"--hook-directory=${_HOOK_DIRECTORY}"} \
	    ${_SKIP:+"--skip=${_SKIP}"} \
	    ${_QUIET:+"--quiet"} \
	    ${_VERBOSE:+"--verbose"} \
	    ${_DEBUG:+"--debug"} \
	    ${_LOGFILE:+"--logfile=${_LOGFILE}"} \
	)

	echo "mmdebstrap ${_OPTION[*]} ${_TARGET_SUITE:+"${_TARGET_SUITE}"} ${_TARGET_DIRECTORY:+"${_TARGET_DIRECTORY}"} ${_TARGET_MIRROR:+"${_TARGET_MIRROR}"}"

	rm -rf "${_TARGET_DIRECTORY:?}"
	mmdebstrap "${_OPTION[@]}" ${_TARGET_SUITE:+"${_TARGET_SUITE}"} ${_TARGET_DIRECTORY:+"${_TARGET_DIRECTORY}"} ${_TARGET_MIRROR:+"${_TARGET_MIRROR}"}

#	dpkg --configure --root="${_TARGET_DIRECTORY}" debian-installer

#	rm -f "${_TARGET_DIRECTORY:?}/.inputrc"

	for _FILE_PATH in "${_TARGET_DIRECTORY}"/var/lib/dpkg/info/{ethdetect,hw-detect}.*
	do
		cp -a "${_FILE_PATH}" "${_FILE_PATH%/*}/00-${_FILE_PATH##*/}"
	done

	pushd "${_TARGET_DIRECTORY}" > /dev/null
		# shellcheck disable=SC2312
		find . | LC_ALL=C sort | cpio --quiet -R 0:0 --reproducible -o -H newc | gzip -q -k -9 > "../${_INITRD:?}"
	popd > /dev/null

	ls -lh "./${_INITRD}"

	exit
