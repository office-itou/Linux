#!/bin/bash
###############################################################################
##
##	custom iso image creation shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2023/12/24
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2023/12/24 000.0000 J.Itou         first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# *** initialization **********************************************************

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

# *** data section ************************************************************

# --- working directory name --------------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    DIRS_WORK="${PWD}/${PROG_NAME%.*}"
	if [[ "${DIRS_WORK}" = "/" ]]; then
		echo "terminate the process because the working directory is root"
		exit 1
	fi
#	declare -r    DIRS_BACK="${DIRS_WORK=}/back"			# backup
	declare -r    DIRS_CONF="${DIRS_WORK=}/conf"			# configure file
#	declare -r    DIRS_IMGS="${DIRS_WORK=}/imgs"			# image destination
	declare -r    DIRS_ISOS="${DIRS_WORK=}/isos"			# iso file
#	declare -r    DIRS_ORIG="${DIRS_WORK=}/orig"			# original file
	declare -r    DIRS_RMAK="${DIRS_WORK=}/rmak"			# remake file
	declare -r    DIRS_TEMP="${DIRS_WORK=}/temp"			# temporary

# --- work variables ----------------------------------------------------------
	declare -r    OLD_IFS="${IFS}"

# --- set minimum display size ------------------------------------------------
	declare -i    ROWS_SIZE=80
	declare -i    COLS_SIZE=25

# --- set parameters ----------------------------------------------------------

	# === network =============================================================

	declare       HOST_NAME=""								# hostname
	declare -r    WGRP_NAME="workgroup"						# domain
	declare -r    ETHR_NAME="ens160"						# network device name
	declare -r    IPV4_ADDR="192.168.1.1"					# IPv4 address
	declare -r    IPV4_CIDR="24"							# IPv4 cidr
	declare -r    IPV4_MASK="255.255.255.0"					# IPv4 subnetmask
	declare -r    IPV4_GWAY="192.168.1.254"					# IPv4 gateway
	declare -r    IPV4_NSVR="192.168.1.254"					# IPv4 nameserver

	# === system ==============================================================

	# --- open-vm-tools -------------------------------------------------------
	declare -r    HGFS_DIRS="/mnt/hgfs/workspace/Image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
	declare -r    CONF_DIRS="${HGFS_DIRS}/linux/bin"
	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	# --- media information ---------------------------------------------------
	#  0: [m] menu / [o] output / [else] hidden
	#  1: iso image file copy destination directory
	#  2: entry name
	#  3: [unused]
	#  4: iso image file name
	#  5: boot loader's directory
	#  6: initial ramdisk
	#  7: kernel
	#  8: configuration file
	#  9: iso image file copy source directory
	# 10: release date
	# 11: support end
	# 12: time stamp
	# 13: file size
	# 14: volume id
	# 15: status
	# 16: download URL

#	declare -a    DATA_LIST=()

	# --- mini.iso ------------------------------------------------------------
	declare -r -a DATA_LIST_MINI=(                                                                                                                                                                                                                                                                                                                                                                                                                                                    \
		"m  -                           Auto%20install%20mini.iso           -               -                                           -                                       -                           -                       -                                           -                   -           -           -           -   -   -   -                                                                                                                               " \
		"o  debian-mini-10              Debian%2010                         debian          mini-buster-amd64.iso                       .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server_old.cfg       linux/debian        2019-07-06  2024-06-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/mini.iso                                 " \
		"o  debian-mini-11              Debian%2011                         debian          mini-bullseye-amd64.iso                     .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server.cfg           linux/debian        2021-08-14  2026-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso                               " \
		"o  debian-mini-12              Debian%2012                         debian          mini-bookworm-amd64.iso                     .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server.cfg           linux/debian        2023-06-10  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso                               " \
		"o  debian-mini-13              Debian%2013                         debian          mini-trixie-amd64.iso                       .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server.cfg           linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso                                 " \
		"o  debian-mini-testing         Debian%20testing                    debian          mini-testing-amd64.iso                      .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server.cfg           linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso                                                                " \
		"o  ubuntu-mini-18.04           Ubuntu%2018.04                      ubuntu          mini-bionic-amd64.iso                       .                                       initrd.gz                   linux                   conf/preseed/ps_ubuntu_server_old.cfg       linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso                      " \
		"o  ubuntu-mini-20.04           Ubuntu%2020.04                      ubuntu          mini-focal-amd64.iso                        .                                       initrd.gz                   linux                   conf/preseed/ps_ubuntu_server_old.cfg       linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso                " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                           9                   10          11          12          13  14  15  16

	# --- netinst -------------------------------------------------------------
	declare -r -a DATA_LIST_NET=(                                                                                                                                                                                                                                                                                                                                                                                                                                                     \
		"m  -                           Auto%20install%20Net%20install      -               -                                           -                                       -                           -                       -                                           -                   -           -           -           -   -   -   -                                                                                                                               " \
		"o  debian-netinst-10           Debian%2010                         debian          debian-10.13.0-amd64-netinst.iso            install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server_old.cfg       linux/debian        2019-07-06  2024-06-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-10.[0-9.]*-amd64-netinst.iso                 " \
		"o  debian-netinst-11           Debian%2011                         debian          debian-11.8.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        2021-08-14  2026-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-11.[0-9.]*-amd64-netinst.iso                    " \
		"o  debian-netinst-12           Debian%2012                         debian          debian-12.4.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        2023-06-10  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso                             " \
		"o  debian-netinst-13           Debian%2013                         debian          debian-13.0.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  debian-netinst-testing      Debian%20testing                    debian          debian-testing-amd64-netinst.iso            install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso                     " \
		"o  fedora-netinst-38           Fedora%20Server%2038                fedora          Fedora-Server-netinst-x86_64-38-1.6.iso     images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_fedora-38.cfg             linux/fedora        2023-04-18  2024-05-14  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-netinst-x86_64-38-[0-9.]*.iso   " \
		"o  fedora-netinst-39           Fedora%20Server%2039                fedora          Fedora-Server-netinst-x86_64-39-1.5.iso     images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_fedora-39.cfg             linux/fedora        2023-11-07  2024-11-12  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-netinst-x86_64-39-[0-9.]*.iso   " \
		"o  centos-stream-netinst-8     CentOS%20Stream%208                 centos          CentOS-Stream-8-x86_64-latest-boot.iso      images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_centos-stream-8.cfg       linux/centos        20xx-xx-xx  2024-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-boot.iso                              " \
		"o  centos-stream-netinst-9     CentOS%20Stream%209                 centos          CentOS-Stream-9-latest-x86_64-boot.iso      images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_centos-stream-9.cfg       linux/centos        2021-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                 " \
		"o  almalinux-netinst-9         Alma%20Linux%209                    almalinux       AlmaLinux-9-latest-x86_64-boot.iso          images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_almalinux-9.cfg           linux/almalinux     2022-05-26  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9[0-9.]*-latest-x86_64-boot.iso                                    " \
		"o  rockylinux-netinst-8        Rocky%20Linux%208                   Rocky           Rocky-8.9-x86_64-boot.iso                   images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_rockylinux-8.cfg          linux/Rocky         2022-11-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-boot.iso                                          " \
		"o  rockylinux-netinst-9        Rocky%20Linux%209                   Rocky           Rocky-9-latest-x86_64-boot.iso              images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_rockylinux-9.cfg          linux/Rocky         2022-07-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9[0-9.]*-latest-x86_64-boot.iso                                   " \
		"o  miraclelinux-netinst-8      Miracle%20Linux%208                 miraclelinux    MIRACLELINUX-8.8-rtm-minimal-x86_64.iso     images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_miraclelinux-8.cfg        linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-minimal-x86_64.iso    " \
		"o  miraclelinux-netinst-9      Miracle%20Linux%209                 miraclelinux    MIRACLELINUX-9.2-rtm-minimal-x86_64.iso     images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_miraclelinux-9.cfg        linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-minimal-x86_64.iso    " \
		"o  opensuse-leap-netinst-15.5  openSUSE%20Leap%2015.5              openSUSE        openSUSE-Leap-15.5-NET-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_leap-15.5.xml        linux/openSUSE      2023-06-07  2024-12-31  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/openSUSE-stable/iso/openSUSE-Leap-[0-9.]*-NET-x86_64-Media.iso                 " \
		"o  opensuse-leap-netinst-15.6  openSUSE%20Leap%2015.6              openSUSE        openSUSE-Leap-15.6-NET-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_leap-15.6.xml        linux/openSUSE      2024-06-xx  2025-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Media.iso                          " \
		"o  opensuse-tumbleweed-netinst openSUSE%20Tumbleweed               openSUSE        openSUSE-Tumbleweed-NET-x86_64-Current.iso  boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_tumbleweed.xml       linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                   " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                           9                   10          11          12          13  14  15  16

	# --- dvd image -----------------------------------------------------------
	declare -r -a DATA_LIST_DVD=(                                                                                                                                                                                                                                                                                                                                                                                                                                                     \
		"m  -                           Auto%20install%20DVD%20media        -               -                                           -                                       -                           -                       -                                           -                   -           -           -           -   -   -   -                                                                                                                               " \
		"o  debian-10                   Debian%2010                         debian          debian-10.13.0-amd64-DVD-1.iso              install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server_old.cfg       linux/debian        2019-07-06  2024-06-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-10.[0-9.]*-amd64-DVD-1.iso                  " \
		"o  debian-11                   Debian%2011                         debian          debian-11.8.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        2021-08-14  2026-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.[0-9.]*-amd64-DVD-1.iso                     " \
		"o  debian-12                   Debian%2012                         debian          debian-12.4.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        2023-06-10  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-12.[0-9.]*-amd64-DVD-1.iso                              " \
		"o  debian-13                   Debian%2013                         debian          debian-13.0.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  debian-testing              Debian%20testing                    debian          debian-testing-amd64-DVD-1.iso              install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                                   " \
		"o  ubuntu-server-18.04         Ubuntu%2018.04%20Server             ubuntu          ubuntu-18.04.6-server-amd64.iso             install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   conf/preseed/ps_ubuntu_server_old.cfg       linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04[0-9.]*-server-amd64.iso                                         " \
		"o  ubuntu-live-18.04           Ubuntu%2018.04%20Live%20Server      ubuntu          ubuntu-18.04.6-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server_old              linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-live-server-amd64.iso                                                    " \
		"o  ubuntu-live-20.04           Ubuntu%2020.04%20Live%20Server      ubuntu          ubuntu-20.04.6-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-live-server-amd64.iso                                                     " \
		"o  ubuntu-live-22.04           Ubuntu%2022.04%20Live%20Server      ubuntu          ubuntu-22.04.3-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-live-server-amd64.iso                                                     " \
		"o  ubuntu-live-23.04           Ubuntu%2023.04%20Live%20Server      ubuntu          ubuntu-23.04-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        2023-04-20  2024-01-20  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-live-server-amd64.iso                                                     " \
		"o  ubuntu-live-23.10           Ubuntu%2023.10%20Live%20Server      ubuntu          ubuntu-23.10-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        2023-10-12  2024-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-live-server-amd64.iso                                                    " \
		"o  ubuntu-live-24.04           Ubuntu%2024.04%20Live%20Server      ubuntu          ubuntu-24.04-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-live-server-amd64.iso                                                     " \
		"o  ubuntu-live-noble           Ubuntu%20noble%20Live%20Server      ubuntu          noble-live-server-amd64.iso                 casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/noble-live-server-amd64.iso                                         " \
		"o  fedora-38                   Fedora%20Server%2038                fedora          Fedora-Server-dvd-x86_64-38-1.6.iso         images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_fedora-38.cfg             linux/fedora        2023-04-18  2024-05-14  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-dvd-x86_64-38-[0-9.]*.iso       " \
		"o  fedora-39                   Fedora%20Server%2039                fedora          Fedora-Server-dvd-x86_64-39-1.5.iso         images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_fedora-39.cfg             linux/fedora        2023-11-07  2024-11-12  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-dvd-x86_64-39-[0-9.]*.iso       " \
		"o  centos-stream-8             CentOS%20Stream%208                 centos          CentOS-Stream-8-x86_64-latest-dvd1.iso      images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_centos-stream-8.cfg       linux/centos        2019-xx-xx  2024-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-dvd1.iso                              " \
		"o  centos-stream-9             CentOS%20Stream%209                 centos          CentOS-Stream-9-latest-x86_64-dvd1.iso      images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_centos-stream-9.cfg       linux/centos        2021-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                 " \
		"o  almalinux-9                 Alma%20Linux%209                    almalinux       AlmaLinux-9-latest-x86_64-dvd.iso           images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_almalinux-9.cfg           linux/almalinux     2022-05-26  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9[0-9.]*-latest-x86_64-dvd.iso                                     " \
		"o  rockylinux-8                Rocky%20Linux%208                   Rocky           Rocky-8.8-x86_64-dvd1.iso                   images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_rockylinux-8.cfg          linux/Rocky         2022-11-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-dvd1.iso                                          " \
		"o  rockylinux-9                Rocky%20Linux%209                   Rocky           Rocky-9-latest-x86_64-dvd.iso               images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_rockylinux-9.cfg          linux/Rocky         2022-07-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9[0-9.]*-latest-x86_64-dvd.iso                                    " \
		"o  miraclelinux-8              Miracle%20Linux%208                 miraclelinux    MIRACLELINUX-8.8-rtm-x86_64.iso             images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_miraclelinux-8.cfg        linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-x86_64.iso            " \
		"o  miraclelinux-9              Miracle%20Linux%209                 miraclelinux    MIRACLELINUX-9.2-rtm-x86_64.iso             images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_miraclelinux-9.cfg        linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso            " \
		"o  opensuse-leap-15.5          openSUSE%20Leap%2015.5              openSUSE        openSUSE-Leap-15.5-DVD-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_leap-15.5.xml        linux/openSUSE      2023-06-07  2024-12-31  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/openSUSE-stable/iso/openSUSE-Leap-[0-9.]*-DVD-x86_64-Media.iso                 " \
		"o  opensuse-leap-15.6          openSUSE%20Leap%2015.6              openSUSE        openSUSE-Leap-15.6-DVD-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_leap-15.6.xml        linux/openSUSE      2024-06-xx  2025-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso                          " \
		"o  opensuse-tumbleweed         openSUSE%20Tumbleweed               openSUSE        openSUSE-Tumbleweed-DVD-x86_64-Current.iso  boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_tumbleweed.xml       linux/openSUSE      2021-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                   " \
		"o  windows-10                  Windows%2010                        windows         Win10_22H2_Japanese_x64.iso                 -                                       -                           -                       -                                           windows/Windows10   -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  windows-11                  Windows%2011                        windows         Win11_23H2_Japanese_x64_custom.iso          -                                       -                           -                       -                                           windows/Windows11   -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                           9                   10          11          12          13  14  15  16

	# --- live media ----------------------------------------------------------
	declare -r -a DATA_LIST_LIVE=(                                                                                                                                                                                                                                                                                                                                                                                                                                                    \
		"m  -                           Live%20media                        -               -                                           -                                       -                           -                       -                                           -                   -           -           -           -   -   -   -                                                                                                                               " \
		"o  debian-live-10              Debian%2010%20Live                  debian          debian-live-10.13.0-amd64-lxde.iso          live                                    initrd.img-4.19.0-21-amd64  vmlinuz-4.19.0-21-amd64 conf/preseed/ps_debian_desktop_old.cfg      linux/debian        2019-07-06  2024-06-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-10.[0-9.]*-amd64-lxde.iso      " \
		"o  debian-live-11              Debian%2011%20Live                  debian          debian-live-11.8.0-amd64-lxde.iso           live                                    initrd.img-5.10.0-26-amd64  vmlinuz-5.10.0-26-amd64 conf/preseed/ps_debian_desktop.cfg          linux/debian        2021-08-14  2026-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso         " \
		"o  debian-live-12              Debian%2012%20Live                  debian          debian-live-12.4.0-amd64-lxde.iso           live                                    initrd.img                  vmlinuz                 conf/preseed/ps_debian_desktop.cfg          linux/debian        2023-06-10  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                  " \
		"o  debian-live-13              Debian%2013%20Live                  debian          debian-live-13.0.0-amd64-lxde.iso           live                                    initrd.img                  vmlinuz                 conf/preseed/ps_debian_desktop.cfg          linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  debian-live-testing         Debian%20testing%20Live             debian          debian-live-testing-amd64-lxde.iso          live                                    initrd.img                  vmlinuz                 conf/preseed/ps_debian_desktop.cfg          linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                       " \
		"x  ubuntu-desktop-18.04        Ubuntu%2018.04%20Desktop            ubuntu          ubuntu-18.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop_old.cfg    linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-desktop-amd64.iso                                                        " \
		"o  ubuntu-desktop-20.04        Ubuntu%2020.04%20Desktop            ubuntu          ubuntu-20.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                         " \
		"o  ubuntu-desktop-22.04        Ubuntu%2022.04%20Desktop            ubuntu          ubuntu-22.04.3-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                         " \
		"o  ubuntu-desktop-23.04        Ubuntu%2023.04%20Desktop            ubuntu          ubuntu-23.04-desktop-amd64.iso              casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        2023-04-20  2024-01-20  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-desktop-amd64.iso                                                         " \
		"o  ubuntu-desktop-23.10        Ubuntu%2023.10%20Desktop            ubuntu          ubuntu-23.10.1-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_desktop                 linux/ubuntu        2023-10-12  2024-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-desktop-amd64.iso                                                        " \
		"o  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop            ubuntu          ubuntu-24.04-desktop-amd64.iso              casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_desktop                 linux/ubuntu        -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  ubuntu-desktop-noble        Ubuntu%20noble%20Desktop            ubuntu          noble-desktop-amd64.iso                     casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_desktop                 linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/noble-desktop-amd64.iso                                                           " \
		"o  ubuntu-legacy-23.04         Ubuntu%2023.04%20Legacy%20Desktop   ubuntu          ubuntu-23.04-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop_old.cfg    linux/ubuntu        2023-04-20  2024-01-20  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/lunar/release/ubuntu-23.04[0-9.]*-desktop-legacy-amd64.iso                                  " \
		"o  ubuntu-legacy-23.10         Ubuntu%2023.10%20Legacy%20Desktop   ubuntu          ubuntu-23.10-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        2023-10-12  2024-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/mantic/release/ubuntu-23.10[0-9.]*-desktop-legacy-amd64.iso                                 " \
		"o  ubuntu-legacy-24.04         Ubuntu%2024.04%20Legacy%20Desktop   ubuntu          ubuntu-24.04-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  ubuntu-legacy-noble         Ubuntu%20noble%20Legacy%20Desktop   ubuntu          noble-desktop-legacy-amd64.iso              casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                           9                   10          11          12          13  14  15  16

	# --- tool ----------------------------------------------------------------
	declare -r -a DATA_LIST_TOOL=(                                                                                                                                                                                                                                                                                                                                                                                                                                                    \
		"m  -                           System%20tools                      -               -                                           -                                       -                           -                       -                                           -                   -           -           -           -   -   -   -                                                                                                                               " \
		"o  memtest86+                  Memtest86+                          memtest86+      mt86plus_6.20_64.grub.iso                   .                                       EFI/BOOT/memtest            boot/memtest            -                                           linux/memtest86+    -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                           9                   10          11          12          13  14  15  16

	# --- target of creation --------------------------------------------------
	declare -a    TGET_LIST=()
	declare       TGET_INDX=""

# --- set color ---------------------------------------------------------------
	declare -r    TXT_RESET='\033[m'						# reset all attributes
	declare -r    TXT_ULINE='\033[4m'						# set underline
	declare -r    TXT_ULINERST='\033[24m'					# reset underline
	declare -r    TXT_REV='\033[7m'							# set reverse display
	declare -r    TXT_REVRST='\033[27m'						# reset reverse display
	declare -r    TXT_BLACK='\033[30m'						# text black
	declare -r    TXT_RED='\033[31m'						# text red
	declare -r    TXT_GREEN='\033[32m'						# text green
	declare -r    TXT_YELLOW='\033[33m'						# text yellow
	declare -r    TXT_BLUE='\033[34m'						# text blue
	declare -r    TXT_MAGENTA='\033[35m'					# text purple
	declare -r    TXT_CYAN='\033[36m'						# text light blue
	declare -r    TXT_WHITE='\033[37m'						# text white
	declare -r    TXT_BBLACK='\033[40m'						# text reverse black
	declare -r    TXT_BRED='\033[41m'						# text reverse red
	declare -r    TXT_BGREEN='\033[42m'						# text reverse green
	declare -r    TXT_BYELLOW='\033[43m'					# text reverse yellow
	declare -r    TXT_BBLUE='\033[44m'						# text reverse blue
	declare -r    TXT_BMAGENTA='\033[45m'					# text reverse purple
	declare -r    TXT_BCYAN='\033[46m'						# text reverse light blue
	declare -r    TXT_BWHITE='\033[47m'						# text reverse white

# *** function section (common functions) *************************************

# --- text color test ---------------------------------------------------------
function funcColorTest() {
	echo -e "${TXT_RESET} : TXT_RESET    : ${TXT_RESET}"
	echo -e "${TXT_ULINE} : TXT_ULINE    : ${TXT_RESET}"
	echo -e "${TXT_ULINERST} : TXT_ULINERST : ${TXT_RESET}"
#	echo -e "${TXT_BLINK} : TXT_BLINK    : ${TXT_RESET}"
#	echo -e "${TXT_BLINKRST} : TXT_BLINKRST : ${TXT_RESET}"
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

# --- diff --------------------------------------------------------------------
function funcDiff() {
	if [[ ! -f "$1" ]] || [[ ! -f "$2" ]]; then
		return
	fi
	funcPrintf "$3"
	diff -y -W "${COLS_SIZE}" --suppress-common-lines "$1" "$2" || true
}

# --- substr ------------------------------------------------------------------
function funcSubstr() {
	echo "$1" | awk '{print substr($0,'"$2"','"$3"');}'
}

# --- IPv6 full address -------------------------------------------------------
function funcIPv6GetFullAddr() {
#	declare -r    OLD_IFS="${IFS}"
	declare       INP_ADDR="$1"
	declare -r    STR_FSEP="${INP_ADDR//[^:]}"
	declare -r -i CNT_FSEP=$((7-${#STR_FSEP}))
	declare -a    OUT_ARRY=()
	declare       OUT_TEMP=""
	if [[ "${CNT_FSEP}" -gt 0 ]]; then
		OUT_TEMP="$(eval printf ':%.s' "{1..$((CNT_FSEP+2))}")"
		INP_ADDR="${INP_ADDR/::/${OUT_TEMP}}"
	fi
	IFS=':'
	# shellcheck disable=SC2206
	OUT_ARRY=(${INP_ADDR/%:/::})
	IFS=${OLD_IFS}
	OUT_TEMP="$(printf ':%04x' "${OUT_ARRY[@]/#/0x0}")"
	echo "${OUT_TEMP:1}"
}

# --- IPv6 reverse address ----------------------------------------------------
function funcIPv6GetRevAddr() {
	declare -r    INP_ADDR="$1"
	echo "${INP_ADDR//:/}"                   | \
	    awk '{for(i=length();i>1;i--)          \
	        printf("%c.", substr($0,i,1));     \
	        printf("%c" , substr($0,1,1));}'
}

# --- IPv4 netmask conversion -------------------------------------------------
function funcIPv4GetNetmask() {
	declare -r    INP_ADDR="$1"
#	declare       DEC_ADDR="$((0xFFFFFFFF ^ (2**(32-INP_ADDR)-1)))"
	declare -i    LOOP=$((32-INP_ADDR))
	declare -i    WORK=1
	declare       DEC_ADDR=""
	while [[ "${LOOP}" -gt 0 ]]
	do
		LOOP=$((LOOP-1))
		WORK=$((WORK*2))
	done
	DEC_ADDR="$((0xFFFFFFFF ^ (WORK-1)))"
	printf '%d.%d.%d.%d'             \
	    $(( DEC_ADDR >> 24        )) \
	    $(((DEC_ADDR >> 16) & 0xFF)) \
	    $(((DEC_ADDR >>  8) & 0xFF)) \
	    $(( DEC_ADDR        & 0xFF))
}

# --- IPv4 cidr conversion ----------------------------------------------------
function funcIPv4GetNetCIDR() {
	declare -r    INP_ADDR="$1"
	#declare -a    OCTETS=()
	#declare -i    MASK=0
	echo "${INP_ADDR}" | \
	    awk -F '.' '{
	        split($0, OCTETS);
	        for (I in OCTETS) {
	            MASK += 8 - log(2^8 - OCTETS[I])/log(2);
	        }
	        print MASK
	    }'
}

# --- is numeric --------------------------------------------------------------
function funcIsNumeric() {
	if [[ ${1:-} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		echo 0
	else
		echo 1
	fi
}

# --- string output -----------------------------------------------------------
function funcString() {
#	declare -r    OLD_IFS="${IFS}"
	IFS=$'\n'
	if [[ "$1" -le 0 ]]; then
		echo ""
	else
		if [[ "$2" = " " ]]; then
			echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); print s;}'
		else
			echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); gsub(" ","'"$2"'",s); print s;}'
		fi
	fi
	IFS="${OLD_IFS}"
}

# --- print with screen control -----------------------------------------------
function funcPrintf() {
	declare -r    SET_ENV_X="$(set -o | awk '$1=="xtrace"  {print $2;}')"
#	declare -r    SET_ENV_E="$(set -o | awk '$1=="errexit" {print $2;}')"
	set +x
	# https://www.tohoho-web.com/ex/dash-tilde.html
#	declare -r    OLD_IFS="${IFS}"
	declare -i    RET_CD=0
	declare -r    CHR_ESC="$(echo -n -e "\033")"
	declare -i    MAX_COLS=${COLS_SIZE:-80}
	declare       RET_STR=""
	declare       INP_STR=""
	declare       SJIS_STR=""
	declare -i    SJIS_CNT=0
	declare       WORK_STR=""
	declare -i    WORK_CNT=0
	declare       TEMP_STR=""
	declare -i    TEMP_CNT=0
	declare -i    CTRL_CNT=0
	# -------------------------------------------------------------------------
	# %[-9.9][diouxXfeEgGcs]
	if [[ "$1" = "--no-cutting" ]]; then
		shift
		# shellcheck disable=SC2312
		if [[ -n "$(echo "$1" | sed -ne '/%[0-9.-]*[diouxXfeEgGcs]\+/p')" ]]; then
			# shellcheck disable=SC2059
			INP_STR="$(printf "$@")"
		else
			INP_STR="$(echo -e "$@")"
		fi
		echo -e "${INP_STR}${TXT_RESET}"
		return
	fi
	IFS=$'\n'
#	INP_STR="$(echo -e "$@")"
	# shellcheck disable=SC2312
	if [[ -n "$(echo "$1" | sed -ne '/%[0-9.-]*[diouxXfeEgGcs]\+/p')" ]]; then
		# shellcheck disable=SC2059
		INP_STR="$(printf "$@")"
	else
		INP_STR="$(echo -e "$@")"
	fi
	# --- convert sjis code ---------------------------------------------------
	SJIS_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932)"
	SJIS_CNT="$(echo -n "${SJIS_STR}" | wc -c)"
	# --- remove escape code --------------------------------------------------
	TEMP_STR="$(echo -n "${SJIS_STR}" | sed -e "s/${CHR_ESC}\[[0-9]*m//g")"
	TEMP_CNT="$(echo -n "${TEMP_STR}" | wc -c)"
	# --- count escape code ---------------------------------------------------
	CTRL_CNT=$((SJIS_CNT-TEMP_CNT))
	# --- string cut ----------------------------------------------------------
	WORK_STR="$(echo -n "${SJIS_STR}" | cut -b $((MAX_COLS+CTRL_CNT))-)"
	WORK_CNT="$(echo -n "${WORK_STR}" | wc -c)"
	# --- remove escape code --------------------------------------------------
	TEMP_STR="$(echo -n "${WORK_STR}" | sed -e "s/${CHR_ESC}\[[0-9]*m//g")"
	TEMP_CNT="$(echo -n "${TEMP_STR}" | wc -c)"
	# --- calc ----------------------------------------------------------------
	MAX_COLS+=$((CTRL_CNT-(WORK_CNT-TEMP_CNT)))
	# --- convert utf-8 code --------------------------------------------------
	set +e
	RET_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932 | cut -b -"${MAX_COLS}" | iconv -f CP932 -t UTF-8 2> /dev/null)"
	RET_CD=$?
	set -e
	if [[ "${RET_CD}" -ne 0 ]]; then
		set +e
		RET_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932 | cut -b -$((MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
		set -e
	fi
#	RET_STR+="$(echo -n -e "${TXT_RESET}")"
	# -------------------------------------------------------------------------
	echo -e "${RET_STR}${TXT_RESET}"
	IFS="${OLD_IFS}"
	# -------------------------------------------------------------------------
#	if [[ "${SET_ENV_E}" = "on" ]]; then
#		set -e
#	else
#		set +e
#	fi
	if [[ "${SET_ENV_X}" = "on" ]]; then
		set -x
	else
		set +x
	fi
}

# ----- unit conversion -------------------------------------------------------
function funcUnit_conversion() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r -a TEXT_UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    CALC_UNIT=0
	declare -i    I=0

	if [[ "$1" -lt 1024 ]]; then
		printf "%'d Byte" "$1"
		return
	fi
	for ((I=3; I>0; I--))
	do
		CALC_UNIT=$((1024**I))
		if [[ "$1" -ge "${CALC_UNIT}" ]]; then
			# shellcheck disable=SC2312
			printf "%s %s" "$(echo "$1" "${CALC_UNIT}" | awk '{printf("%.1f", $1/$2)}')" "${TEXT_UNIT[${I}]}"
			return
		fi
	done
	echo -n "$1"
}

# --- download ----------------------------------------------------------------
function funcCurl() {
#	declare -r    OLD_IFS="${IFS}"
	declare -i    RET_CD=0
	declare -i    I
	# shellcheck disable=SC2155
	declare       INP_URL="$(echo "$@" | sed -ne 's%^.* \(\(http\|https\)://.*\)$%\1%p')"
	# shellcheck disable=SC2155
	declare       OUT_DIR="$(echo "$@" | sed -ne 's%^.* --output-dir *\(.*\) .*$%\1%p' | sed -e 's%/$%%')"
	# shellcheck disable=SC2155
	declare       OUT_FILE="$(echo "$@" | sed -ne 's%^.* --output *\(.*\) .*$%\1%p' | sed -e 's%/$%%')"
	declare -a    ARY_HED=("")
	declare       ERR_MSG=""
	declare       WEB_SIZ=""
	declare       WEB_TIM=""
	declare       WEB_FIL=""
	declare       LOC_INF=""
	declare       LOC_SIZ=""
	declare       LOC_TIM=""
	declare       TXT_SIZ=""
#	declare -i    INT_SIZ
#	declare -i    INT_UNT
#	declare -a    TXT_UNT=("Byte" "KiB" "MiB" "GiB" "TiB")
	set +e
	ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${INP_URL}" 2> /dev/null)")
	RET_CD=$?
	set -e
	if [[ "${RET_CD}" -eq 6 ]] || [[ "${RET_CD}" -eq 18 ]] || [[ "${RET_CD}" -eq 22 ]] || [[ "${RET_CD}" -eq 28 ]] || [[ "${#ARY_HED[@]}" -le 0 ]]; then
		ERR_MSG=$(echo "${ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -z 's/\n\|\r\|\l//g')
		echo -e "${ERR_MSG} [${RET_CD}]: ${INP_URL}"
		return "${RET_CD}"
	fi
	WEB_SIZ=$(echo "${ARY_HED[@],,}" | sed -ne '/http\/.* 200/,/^$/ s/'''$'\r//gp' | sed -ne '/content-length:/ s/.*: //p')
	# shellcheck disable=SC2312
	WEB_TIM=$(TZ=UTC date -d "$(echo "${ARY_HED[@],,}" | sed -ne '/http\/.* 200/,/^$/ s/'''$'\r//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
	WEB_FIL="${OUT_DIR:-.}/${INP_URL##*/}"
	if [[ -n "${OUT_DIR}" ]] && [[ ! -d "${OUT_DIR}/." ]]; then
		mkdir -p "${OUT_DIR}"
	fi
	if [[ -n "${OUT_FILE}" ]] && [[ -f "${OUT_FILE}" ]]; then
		WEB_FIL="${OUT_FILE}"
	fi
	if [[ -n "${WEB_FIL}" ]] && [[ -f "${WEB_FIL}" ]]; then
		LOC_INF=$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${WEB_FIL}")
		LOC_TIM=$(echo "${LOC_INF}" | awk '{print $6;}')
		LOC_SIZ=$(echo "${LOC_INF}" | awk '{print $5;}')
		if [[ "${WEB_TIM:-0}" -eq "${LOC_TIM:-0}" ]] && [[ "${WEB_SIZ:-0}" -eq "${LOC_SIZ:-0}" ]]; then
			funcPrintf "same    file: ${WEB_FIL}"
			return
		fi
	fi

	TXT_SIZ="$(funcUnit_conversion "${WEB_SIZ}")"
#	if [[ "${WEB_SIZ}" -lt 1024 ]]; then
#		TXT_SIZ="$(printf "%'d Byte" "${WEB_SIZ}")"
#	else
#		for ((I=3; I>0; I--))
#		do
#			INT_UNT=$((1024**I))
#			if [[ "${WEB_SIZ}" -ge "${INT_UNT}" ]]; then
#				TXT_SIZ="$(echo "${WEB_SIZ}" "${INT_UNT}" | awk '{printf("%.1f", $1/$2)}') ${TXT_UNT[${I}]})"
##				INT_SIZ="$(((WEB_SIZ*1000)/(1024**I)))"
##				TXT_SIZ="$(printf "%'.1f ${TXT_UNT[${I}]}" "${INT_SIZ::${#INT_SIZ}-3}.${INT_SIZ:${#INT_SIZ}-3}")"
#				break
#			fi
#		done
#	fi

	funcPrintf "get     file: ${WEB_FIL} (${TXT_SIZ})"
	curl "$@"
	RET_CD=$?
	if [[ "${RET_CD}" -ne 0 ]]; then
		for ((I=0; I<3; I++))
		do
			funcPrintf "retry  count: ${I}"
			curl --continue-at "$@"
			RET_CD=$?
			if [[ "${RET_CD}" -eq 0 ]]; then
				break
			fi
		done
	fi
	return "${RET_CD}"
}

# --- service status ----------------------------------------------------------
function funcServiceStatus() {
#	declare -r    OLD_IFS="${IFS}"
	# shellcheck disable=SC2155
	declare       SRVC_STAT="$(systemctl is-enabled "$1" 2> /dev/null || true)"
	# -------------------------------------------------------------------------
	if [[ -z "${SRVC_STAT}" ]]; then
		SRVC_STAT="not-found"
	fi
	case "${SRVC_STAT}" in
		disabled        ) SRVC_STAT="disabled";;
		enabled         | \
		enabled-runtime ) SRVC_STAT="enabled";;
		linked          | \
		linked-runtime  ) SRVC_STAT="linked";;
		masked          | \
		masked-runtime  ) SRVC_STAT="masked";;
		alias           ) ;;
		static          ) ;;
		indirect        ) ;;
		generated       ) ;;
		transient       ) ;;
		bad             ) ;;
		not-found       ) ;;
		*               ) SRVC_STAT="undefined";;
	esac
	echo "${SRVC_STAT}"
}

# *** function section (sub functions) ****************************************

# === create ==================================================================

# ----- create link -----------------------------------------------------------
function funcCreate_link() {
	declare -r -a DATA_LIST=(  \
		"${DATA_LIST_MINI[@]}" \
		"${DATA_LIST_NET[@]}"  \
		"${DATA_LIST_DVD[@]}"  \
		"${DATA_LIST_LIVE[@]}" \
		"${DATA_LIST_TOOL[@]}" \
	)
	declare -a    DATA_LINE=()
	declare       DIRS_NAME=""
	declare -i    I=0

	for ((I=0; I<"${#DATA_LIST[@]}"; I++))
	do
		read -r -a DATA_LINE < <(echo "${DATA_LIST[I]}")
		if [[ "${DATA_LINE[0]}" != "o" ]]; then
			continue
		fi
		mkdir -p "${DIRS_ISOS}"
		if [[ -L "${DIRS_ISOS}/${DATA_LINE[4]}" ]]; then
			funcPrintf "symbolic link exist : ${DIRS_ISOS}/${DATA_LINE[4]}"
		else
			funcPrintf "symbolic link create: ${HGFS_DIRS}/${DATA_LINE[9]}/${DATA_LINE[4]} -> ${DIRS_ISOS}"
			ln -s "${HGFS_DIRS}/${DATA_LINE[9]}/${DATA_LINE[4]}" "${DIRS_ISOS}"
		fi
	done
}

# ----- create preseed kill dhcp ----------------------------------------------
function funcCreate_preseed_kill_dhcp() {
	declare -r    DIRS_NAME="${DIRS_CONF}/preseed"
	declare -r    FILE_NAME="${DIRS_NAME}/preseed_kill_dhcp.sh"
	# -------------------------------------------------------------------------
	funcPrintf "create filet: ${FILE_NAME/${PWD}\/}"
	mkdir -p "${DIRS_NAME}"
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' | sed 's/^ *//g' > "${FILE_NAME}"
		#!/bin/sh
		
		### initialization ############################################################
		#	set -n								# Check for syntax errors
		#	set -x								# Show command and argument expansion
		 	set -o ignoreeof					# Do not exit with Ctrl+D
		 	set +m								# Disable job control
		 	set -e								# End with status other than 0
		 	set -u								# End with undefined variable reference
		#	set -o pipefail						# End with in pipe error
		
		 	trap 'exit 1' 1 2 3 15
		
		### Main ######################################################################
		 	/bin/kill-all-dhcp
		 	/bin/netcfg
		### Termination ###############################################################
		 	exit 0
		### EOF #######################################################################
_EOT_SH_
}

# ----- create preseed sub command --------------------------------------------
function funcCreate_preseed_sub_command() {
	declare -r    DIRS_NAME="${DIRS_CONF}/preseed"
	declare -r    FILE_NAME="${DIRS_NAME}/preseed_sub_command.sh"
	# -------------------------------------------------------------------------
	funcPrintf "create filet: ${FILE_NAME/${PWD}\/}"
	mkdir -p "${DIRS_NAME}"
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' | sed 's/^ *//g' > "${FILE_NAME}"
		#!/bin/sh
		
		### initialization ############################################################
		#	set -n								# Check for syntax errors
		#	set -x								# Show command and argument expansion
		 	set -o ignoreeof					# Do not exit with Ctrl+D
		 	set +m								# Disable job control
		 	set -e								# End with status other than 0
		 	set -u								# End with undefined variable reference
		#	set -o pipefail						# End with in pipe error
		
		 	trap 'exit 1' 1 2 3 15
		
		 	readonly PROG_PRAM="$*"
		 	readonly PROG_NAME="${0##*/}"
		 	readonly WORK_DIRS="${0%/*}"
		# shellcheck disable=SC2155
		 	readonly DIST_NAME="$(uname -v | sed -ne 's/.*\(debian\|ubuntu\).*/\L\1/ip')"
		# shellcheck disable=SC2155
		 	readonly PROG_PARM="$(cat /proc/cmdline)"
		 	echo "${PROG_NAME}: === Start ==="
		 	echo "${PROG_NAME}: PROG_PRAM=${PROG_PRAM}"
		 	echo "${PROG_NAME}: PROG_NAME=${PROG_NAME}"
		 	echo "${PROG_NAME}: WORK_DIRS=${WORK_DIRS}"
		 	echo "${PROG_NAME}: DIST_NAME=${DIST_NAME}"
		 	echo "${PROG_NAME}: PROG_PARM=${PROG_PARM}"
		 	#--------------------------------------------------------------------------
		 	if [ -z "${PROG_PRAM}" ]; then
		 		ROOT_DIRS="/target"
		 		CONF_FILE="${WORK_DIRS}/preseed.cfg"
		 		TEMP_FILE=""
		 		PROG_PATH="$0"
		 		if [ -z "${CONF_FILE}" ] || [ ! -f "${CONF_FILE}" ]; then
		 			echo "${PROG_NAME}: not found preseed file [${CONF_FILE}]"
		 			exit 1
		 		fi
		 		echo "${PROG_NAME}: now found preseed file [${CONF_FILE}]"
		 		cp --archive --update "${PROG_PATH}" "${ROOT_DIRS}/tmp/"
		 		cp --archive --update "${CONF_FILE}" "${ROOT_DIRS}/tmp/"
		 		TEMP_FILE="/tmp/${CONF_FILE##*/}"
		 		echo "${PROG_NAME}: ROOT_DIRS=${ROOT_DIRS}"
		 		echo "${PROG_NAME}: CONF_FILE=${CONF_FILE}"
		 		echo "${PROG_NAME}: TEMP_FILE=${TEMP_FILE}"
		 		in-target --pass-stdout sh -c "LANG=C /tmp/${PROG_NAME} ${TEMP_FILE}"
		 		exit 0
		 	fi
		 	ROOT_DIRS=""
		 	TEMP_FILE="${PROG_PRAM}"
		 	echo "${PROG_NAME}: ROOT_DIRS=${ROOT_DIRS}"
		 	echo "${PROG_NAME}: TEMP_FILE=${TEMP_FILE}"
		
		### common ####################################################################
		# --- IPv4 netmask conversion -------------------------------------------------
		funcIPv4GetNetmask() {
		 	INP_ADDR="$1"
		 	LOOP=$((32-INP_ADDR))
		 	WORK=1
		 	DEC_ADDR=""
		 	while [ "${LOOP}" -gt 0 ]
		 	do
		 		LOOP=$((LOOP-1))
		 		WORK=$((WORK*2))
		 	done
		 	DEC_ADDR="$((0xFFFFFFFF ^ (WORK-1)))"
		 	printf '%d.%d.%d.%d'             \
		 	    $(( DEC_ADDR >> 24        )) \
		 	    $(((DEC_ADDR >> 16) & 0xFF)) \
		 	    $(((DEC_ADDR >>  8) & 0xFF)) \
		 	    $(( DEC_ADDR        & 0xFF))
		}
		
		# --- IPv4 cidr conversion ----------------------------------------------------
		funcIPv4GetNetCIDR() {
		 	INP_ADDR="$1"
		 	echo "${INP_ADDR}" | \
		 	    awk -F '.' '{
		 	        split($0, OCTETS)
		 	        for (I in OCTETS) {
		 	            MASK += 8 - log(2^8 - OCTETS[I])/log(2)
		 	        }
		 	        print MASK
		 	    }'
		}
		
		### subroutine ################################################################
		# --- packages ----------------------------------------------------------------
		funcInstallPackages() {
		 	echo "${PROG_NAME}: funcInstallPackages"
		 	#--------------------------------------------------------------------------
		 	LIST_TASK="$(sed -ne '/^[[:blank:]]*tasksel[[:blank:]]\+tasksel\/first[[:blank:]]\+/,/[^\\]$/p' "${TEMP_FILE}" | \
		 	             sed -z -e 's/\\\n//g'                                                                             | \
		 	             sed -e 's/^.*[[:blank:]]\+multiselect[[:blank:]]\+//'                                               \
		 	                 -e 's/[[:blank:]]\+/ /g')"
		 	LIST_PACK="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+pkgsel\/include[[:blank:]]\+/,/[^\\]$/p'    "${TEMP_FILE}" | \
		 	             sed -z -e 's/\\\n//g'                                                                             | \
		 	             sed -e 's/^.*[[:blank:]]\+string[[:blank:]]\+//'                                                    \
		 	                 -e 's/[[:blank:]]\+/ /g')"
		 	echo "${PROG_NAME}: LIST_TASK=${LIST_TASK:-}"
		 	echo "${PROG_NAME}: LIST_PACK=${LIST_PACK:-}"
		 	#--------------------------------------------------------------------------
		 	sed -i "${ROOT_DIRS}/etc/apt/sources.list" \
		 	    -e '/cdrom/ s/^ *\(deb\)/# \1/g'
		 	#--------------------------------------------------------------------------
		 	LIST_DPKG=""
		 	if [ -n "${LIST_PACK:-}" ]; then
		 		LIST_DPKG="$(LANG=C dpkg-query --list "${LIST_PACK:-}" | grep -E -v '^ii|^\+|^\||^Desired' || true 2> /dev/null)"
		 	fi
		 	if [ -z "${LIST_DPKG:-}" ]; then
		 		echo "${PROG_NAME}: Finish the installation"
		 		return
		 	fi
		 	#--------------------------------------------------------------------------
		 	echo "${PROG_NAME}: Run the installation"
		 	echo "${PROG_NAME}: LIST_DPKG="
		 	echo "${PROG_NAME}: <<<"
		 	echo "${LIST_DPKG}"
		 	echo "${PROG_NAME}: >>>"
		 	#--------------------------------------------------------------------------
		 	apt-get -qq    update
		 	apt-get -qq -y upgrade
		 	apt-get -qq -y dist-upgrade
		 	apt-get -qq -y install "${LIST_PACK}"
		 	# shellcheck disable=SC2312
		 	if [ -n "$(command -v tasksel 2> /dev/null)" ]; then
		 		tasksel install "${LIST_TASK}"
		 	fi
		}
		
		# --- network -----------------------------------------------------------------
		funcSetupNetwork() {
		 	echo "${PROG_NAME}: funcSetupNetwork"
		 	#--- preseed.cfg parameter ------------------------------------------------
		 	FIX_IPV4="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/\(disable_dhcp\|disable_autoconfig\)[[:blank:]]\+/ s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_IPV4="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_ipaddress[[:blank:]]\+/                        s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_MASK="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_netmask[[:blank:]]\+/                          s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_GATE="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_gateway[[:blank:]]\+/                          s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_DNS4="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_nameservers[[:blank:]]\+/                      s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_WGRP="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_domain[[:blank:]]\+/                           s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_HOST="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_hostname[[:blank:]]\+/                         s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_WGRP="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_domain[[:blank:]]\+/                           s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_NAME="$(sed -ne '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/choose_interface[[:blank:]]\+/                     s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_FQDN="${NIC_HOST}"
		 	if [ -n "${NIC_WGRP}" ]; then
		 		NIC_FQDN="${NIC_HOST}.${NIC_WGRP}"
		 	fi
		 	NIC_BIT4=""
		 	NIC_MADR=""
		 	CON_NAME=""
		 	#--- /proc/cmdline parameter  ---------------------------------------------
		 	for LINE in ${PROG_PARM}
		 	do
		 		case "${LINE}" in
		 			netcfg/choose_interface=*   ) NIC_NAME="${LINE#netcfg/choose_interface=}"  ;;
		 			netcfg/disable_dhcp=*       ) FIX_IPV4="${LINE#netcfg/disable_dhcp=}"      ;;
		 			netcfg/disable_autoconfig=* ) FIX_IPV4="${LINE#netcfg/disable_autoconfig=}";;
		 			netcfg/get_ipaddress=*      ) NIC_IPV4="${LINE#netcfg/get_ipaddress=}"     ;;
		 			netcfg/get_netmask=*        ) NIC_MASK="${LINE#netcfg/get_netmask=}"       ;;
		 			netcfg/get_gateway=*        ) NIC_GATE="${LINE#netcfg/get_gateway=}"       ;;
		 			netcfg/get_nameservers=*    ) NIC_DNS4="${LINE#netcfg/get_nameservers=}"   ;;
		 			netcfg/get_hostname=*       ) NIC_FQDN="${LINE#netcfg/get_hostname=}"      ;;
		 			netcfg/get_domain=*         ) NIC_WGRP="${LINE#netcfg/get_domain=}"        ;;
		 			interface=*                 ) NIC_NAME="${LINE#interface=}"                ;;
		 			hostname=*                  ) NIC_FQDN="${LINE#hostname=}"                 ;;
		 			domain=*                    ) NIC_WGRP="${LINE#domain=}"                   ;;
		 			ip=dhcp                     ) FIX_IPV4="false"; break                      ;;
		 			ip=*                        ) FIX_IPV4="true"
		 			                              OLD_IFS=${IFS}
		 			                              IFS=':'
		 			                              set -f
		 			                              # shellcheck disable=SC2086
		 			                              set -- ${LINE#ip=}
		 			                              set +f
		 			                              NIC_IPV4="${1}"
		 			                              NIC_GATE="${3}"
		 			                              NIC_MASK="${4}"
		 			                              NIC_FQDN="${5}"
		 			                              NIC_NAME="${6}"
		 			                              NIC_DNS4="${8}"
		 			                              IFS=${OLD_IFS}
		 			                              break
		 			                              ;;
		 			*) ;;
		 		esac
		 	done
		 	#--- network parameter ----------------------------------------------------
		 	NIC_HOST="${NIC_FQDN%.*}"
		 	NIC_WGRP="${NIC_FQDN#*.}"
		 	if [ -z "${NIC_WGRP}" ]; then
		 		NIC_WGRP="$(awk '/[ \t]*search[ \t]+/ {print $2;}' "${ROOT_DIRS}/etc/resolv.conf")"
		 	fi
		 	if [ -n "${NIC_MASK}" ]; then
		 		NIC_BIT4="$(funcIPv4GetNetCIDR "${NIC_MASK}")"
		 	fi
		 	if [ -n "${NIC_IPV4#*/}" ] && [ "${NIC_IPV4#*/}" != "${NIC_IPV4}" ]; then
		 		FIX_IPV4="true"
		 		NIC_BIT4="${NIC_IPV4#*/}"
		 		NIC_IPV4="${NIC_IPV4%/*}"
		 		NIC_MASK="$(funcIPv4GetNetmask "${NIC_BIT4}")"
		 	fi
		 	#--- nic parameter --------------------------------------------------------
		 	if [ -z "${NIC_NAME}" ] || [ "${NIC_NAME}" = "auto" ]; then
		 		IP4_INFO="$(LANG=C ip -a address show 2> /dev/null | sed -n '/^2:/ { :l1; p; n; { /^[0-9]\+:/ Q; }; t; b l1; }')"
		 		NIC_NAME="$(echo "${IP4_INFO}" | awk '/^2:/ {gsub(":","",$2); print $2;}')"
		 	fi
		 	IP4_INFO="$(LANG=C ip -f link address show dev "${NIC_NAME}" 2> /dev/null | sed -n '/^2:/ { :l1; p; n; { /^[0-9]\+:/ Q; }; t; b l1; }')"
		 	NIC_MADR="$(echo "${IP4_INFO}" | awk '/link\/ether/ {print$2;}')"
		 	CON_MADR="$(echo "${NIC_MADR}" | sed -ne 's/://gp')"
		 	#--- hostname / hosts -----------------------------------------------------
		 	OLD_FQDN="$(cat "${ROOT_DIRS}/etc/hostname")"
		 	OLD_HOST="${OLD_FQDN%.*}"
		#	OLD_WGRP="${OLD_FQDN#*.}"
		 	echo "${NIC_FQDN}" > "${ROOT_DIRS}/etc/hostname"
		 	sed -i "${ROOT_DIRS}/etc/hosts"                                \
		 	    -e '/^127\.0\.1\.1/d'                                      \
		 	    -e "/^${NIC_IPV4}/d"                                       \
		 	    -e 's/^\([0-9.]\+\)[ \t]\+/\1\t/g'                         \
		 	    -e 's/^\([0-9a-zA-Z:]\+\)[ \t]\+/\1\t\t/g'                 \
		 	    -e "/^127\.0\.0\.1/a ${NIC_IPV4}\t${NIC_FQDN} ${NIC_HOST}" \
		 	    -e "s/${OLD_HOST}/${NIC_HOST}/g"                           \
		 	    -e "s/${OLD_FQDN}/${NIC_FQDN}/g"
		#	sed -i "${ROOT_DIRS}/etc/hosts"                                            \
		#	    -e 's/\([ \t]\+\)'${OLD_HOST}'\([ \t]*\)$/\1'${NIC_HOST}'\2/'          \
		#	    -e 's/\([ \t]\+\)'${OLD_FQDN}'\([ \t]*$\|[ \t]\+\)/\1'${NIC_FQDN}'\2/'
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: FIX_IPV4=${FIX_IPV4}"
		 	echo "${PROG_NAME}: NIC_IPV4=${NIC_IPV4}"
		 	echo "${PROG_NAME}: NIC_MASK=${NIC_MASK}"
		 	echo "${PROG_NAME}: NIC_GATE=${NIC_GATE}"
		 	echo "${PROG_NAME}: NIC_DNS4=${NIC_DNS4}"
		 	echo "${PROG_NAME}: NIC_FQDN=${NIC_FQDN}"
		 	echo "${PROG_NAME}: NIC_HOST=${NIC_HOST}"
		 	echo "${PROG_NAME}: NIC_WGRP=${NIC_WGRP}"
		 	echo "${PROG_NAME}: NIC_BIT4=${NIC_BIT4}"
		 	echo "${PROG_NAME}: NIC_NAME=${NIC_NAME}"
		 	echo "${PROG_NAME}: NIC_MADR=${NIC_MADR}"
		 	echo "${PROG_NAME}: CON_MADR=${CON_MADR}"
		 	echo "${PROG_NAME}: --- hostname ---"
		 	cat "${ROOT_DIRS}/etc/hostname"
		 	echo "${PROG_NAME}: --- hosts ---"
		 	cat "${ROOT_DIRS}/etc/hosts"
		 	echo "${PROG_NAME}: --- resolv.conf ---"
		 	cat "${ROOT_DIRS}/etc/resolv.conf"
		 	# --- avahi ---------------------------------------------------------------
		 	if [ -f "${ROOT_DIRS}/etc/avahi/avahi-daemon.conf" ]; then
		 		echo "${PROG_NAME}: funcSetupNetwork: avahi"
		#		sed -i "${ROOT_DIRS}/etc/avahi/avahi-daemon.conf" \
		#			-e '/allow-interfaces=/ {'                    \
		#			-e 's/^#//'                                   \
		#			-e "s/=.*/=${NIC_NAME}/ }"
		 		echo "${PROG_NAME}: --- avahi-daemon.conf ---"
		 		cat "${ROOT_DIRS}/etc/avahi/avahi-daemon.conf"
		 	fi
		 	#--- exit for DHCP --------------------------------------------------------
		 	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		 		return
		 	fi
		 	# --- connman -------------------------------------------------------------
		 	if [ -d "${ROOT_DIRS}/etc/connman" ]; then
		 		echo "${PROG_NAME}: funcSetupNetwork: connman"
		#		CNF_FILE="${ROOT_DIRS}/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
		#		mkdir -p "${CNF_FILE%/*}"
		#		# shellcheck disable=SC2312
		#		cat <<- _EOT_ | sed 's/^ *//g' > "${CNF_FILE}"
		#			[Service]
		#			ExecStart=
		#			ExecStart=$(command -v connmand 2> /dev/null) -n --nodnsproxy
		#_EOT_
		 		SET_FILE="${ROOT_DIRS}/var/lib/connman/settings"
		 		mkdir -p "${SET_FILE%/*}"
		 		cat <<- _EOT_ | sed 's/^ *//g' > "${SET_FILE}"
		 			[global]
		 			OfflineMode=false
		 			
		 			[Wired]
		 			Enable=true
		 			Tethering=false
		_EOT_
		 		for MAC_ADDR in $(LANG=C ip -4 -oneline link show | awk '/^[0-9]+:/&&!/^1:/ {gsub(":","",$17); print $17;}')
		 		do
		 			CON_NAME="ethernet_${MAC_ADDR}_cable"
		 			CON_DIRS="${ROOT_DIRS}/var/lib/connman/${CON_NAME}"
		 			CON_FILE="${CON_DIRS}/settings"
		 			mkdir -p "${CON_DIRS}"
		 			chmod 700 "${CON_DIRS}"
		 			if [ "${MAC_ADDR}" != "${CON_MADR}" ]; then
		 				cat <<- _EOT_ | sed 's/^ *//g' > "${CON_FILE}"
		 					[${CON_NAME}]
		 					Name=Wired
		 					AutoConnect=false
		 					Modified=
		 					IPv4.method=dhcp
		 					IPv4.DHCP.LastAddress=
		 					IPv6.method=auto
		 					IPv6.privacy=disabled
		_EOT_
		 			else
		 				cat <<- _EOT_ | sed 's/^ *//g' > "${CON_FILE}"
		 					[${CON_NAME}]
		 					Name=Wired
		 					AutoConnect=true
		 					Modified=
		 					IPv4.method=manual
		 					IPv4.netmask_prefixlen=${NIC_BIT4}
		 					IPv4.local_address=${NIC_IPV4}
		 					IPv4.gateway=${NIC_GATE}
		 					IPv6.method=auto
		 					IPv6.privacy=disabled
		 					Nameservers=127.0.0.1;::1;${NIC_DNS4};
		 					Timeservers=ntp.nict.jp;
		 					Domains=${NIC_WGRP};
		 					mDNS=true
		 					IPv6.DHCP.DUID=
		_EOT_
		 			fi
		 			echo "${PROG_NAME}: --- ${CON_NAME}/settings ---"
		 			cat "${CON_FILE}"
		 		done
		 	fi
		 	# --- netplan -------------------------------------------------------------
		 	if [ -d "${ROOT_DIRS}/etc/netplan" ]; then
		 		echo "${PROG_NAME}: funcSetupNetwork: netplan"
		 		for FILE_LINE in "${ROOT_DIRS}"/etc/netplan/*
		 		do
		 			# shellcheck disable=SC2312
		 			if [ -n "$(sed -n "/${NIC_IPV4}\/${NIC_BIT4}/p" "${FILE_LINE}")" ]; then
		 				echo "${PROG_NAME}: funcSetupNetwork: file already exists [${FILE_LINE}]"
		 				cat "${FILE_LINE}"
		 				return
		 			fi
		 		done
		 		echo "${PROG_NAME}: funcSetupNetwork: create file"
		 		cat <<- _EOT_ > "${ROOT_DIRS}/etc/netplan/99-network-manager-static.yaml"
		 			network:
		 			  version: 2
		 			  ethernets:
		 			    ${NIC_NAME}:
		 			      dhcp4: false
		 			      addresses: [ ${NIC_IPV4}/${NIC_BIT4} ]
		 			      gateway4: ${NIC_GATE}
		 			      nameservers:
		 			          search: [ ${NIC_WGRP} ]
		 			          addresses: [ ${NIC_DNS4} ]
		 			      dhcp6: true
		 			      ipv6-privacy: true
		_EOT_
		 		echo "${PROG_NAME}: --- 99-network-manager-static.yaml ---"
		 		cat "${ROOT_DIRS}/etc/netplan/99-network-manager-static.yaml"
		 	fi
		 	# --- NetworkManager ------------------------------------------------------
		 	if [ -d "${ROOT_DIRS}/etc/NetworkManager/." ]; then
		 		echo "${PROG_NAME}: funcSetupNetwork: NetworkManager"
		 		mkdir -p "${ROOT_DIRS}/etc/NetworkManager/conf.d"
		 		cat <<- _EOT_ > "${ROOT_DIRS}/etc/NetworkManager/conf.d/none-dns.conf"
		 			[main]
		 			dns=none
		_EOT_
		 	fi
		#	if [ -d "${ROOT_DIRS}/etc/NetworkManager/." ]; then
		#		echo "${PROG_NAME}: funcSetupNetwork: NetworkManager"
		#		mkdir -p "${ROOT_DIRS}/etc/NetworkManager/conf.d"
		#		if [ -f "${ROOT_DIRS}/etc/dnsmasq.conf" ]; then
		#			cat <<- _EOT_ > "${ROOT_DIRS}/etc/NetworkManager/conf.d/dns.conf"
		#				[main]
		#				dns=dnsmasq
		#_EOT_
		#		else
		#			cat <<- _EOT_ > "${ROOT_DIRS}/etc/NetworkManager/conf.d/none-dns.conf"
		#				[main]
		#				dns=none
		#_EOT_
		#		fi
		#		sed -i "${ROOT_DIRS}/etc/NetworkManager/NetworkManager.conf" \
		#		-e '/[main]/a dns=none'
		#	fi
		}
		
		# --- gdm3 --------------------------------------------------------------------
		#funcChange_gdm3_configure() {
		#	echo "${PROG_NAME}: funcChange_gdm3_configure"
		#	if [ -f "${ROOT_DIRS}/etc/gdm3/custom.conf" ]; then
		#		sed -i.orig "${ROOT_DIRS}/etc/gdm3/custom.conf" \
		#		    -e '/WaylandEnable=false/ s/^#//'
		#	fi
		#}
		
		### Main ######################################################################
		funcMain() {
		 	echo "${PROG_NAME}: funcMain"
		 	case "${DIST_NAME}" in
		 		debian )
		 			funcInstallPackages
		 			funcSetupNetwork
		#			funcChange_gdm3_configure
		 			;;
		 		ubuntu )
		 			funcInstallPackages
		 			funcSetupNetwork
		#			funcChange_gdm3_configure
		 			;;
		 		* )
		 			;;
		 	esac
		}
		
		 	funcMain
		### Termination ###############################################################
		 	echo "${PROG_NAME}: === End ==="
		 	exit 0
		### EOF #######################################################################
_EOT_SH_
}

# ----- create preseed.cfg ----------------------------------------------------
function funcCreate_preseed_cfg() {
	declare -r    DIRS_NAME="${DIRS_CONF}/preseed"
	declare       FILE_PATH=""
	declare -r -a FILE_LIST=(                       \
		"ps_debian_"{server,desktop}{,_old}".cfg"   \
		"ps_ubuntu_"{server,desktop}{,_old}".cfg"   \
		"ps_ubiquity_"{server,desktop}{,_old}".cfg" \
	)
	declare -i    I=0
	# -------------------------------------------------------------------------
	for ((I=0; I<"${#FILE_LIST[@]}"; I++))
	do
		case "${FILE_LIST[I]}" in
			*_debian_*   ) FILE_TMPL="${CONF_SEDD}";;
			*_ubuntu_*   ) FILE_TMPL="${CONF_SEDU}";;
			*_ubiquity_* ) FILE_TMPL="${CONF_SEDU}";;
			* ) continue;;
		esac
		FILE_PATH="${DIRS_NAME}/${FILE_LIST[I]}"
		funcPrintf "create filet: ${FILE_PATH/${PWD}\/}"
		mkdir -p "${FILE_PATH%/*}"
		# ---------------------------------------------------------------------
		cp --update --backup "${FILE_TMPL}" "${FILE_PATH}"
		if [[ "${FILE_LIST[I]}" =~ _old ]]; then
			sed -i "${FILE_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'  \
			    -e 's/bind9-dnsutils/dnsutils/'
		fi
		if [[ "${FILE_LIST[I]}" =~ _desktop ]]; then
			sed -i "${FILE_PATH}"                                                                                        \
			    -e '/^[ \t]*d-i[ \t]\+pkgsel\/include[ \t]\+/,/\(^[# \t]*d-i[ \t]\+\|^#.*-$\)/                       { ' \
			    -e ':l; /\(^[# \t]*d-i[ \t]\+\|^#.*-$\)/! { /^#.*[^-]*$/! { /\\$/! s/$/ \\/ }; s/^# /  /; n; b l; }; } '
		fi
		if [[ "${FILE_LIST[I]}" =~ _ubiquity_ ]]; then
			IFS= INS_STR=$(
				sed -n '/^[^#].*preseed\/late_command/,/[^\\]$/p' "${FILE_PATH}" | \
				sed -e 's/\\/\\\\/g'                                               \
				    -e 's/d-i/ubiquity/'                                           \
				    -e 's%preseed\/late_command%ubiquity\/success_command%'      | \
				sed -e ':l; N; s/\n/\\n/; b l;'
			)
			IFS=${OLD_IFS}
			if [[ -n "${INS_STR}" ]]; then
				sed -i "${FILE_PATH}"                                   \
				    -e '/^[^#].*preseed\/late_command/,/[^\\]$/     { ' \
				    -e 's/^/#/g'                                        \
				    -e 's/#  /# /g                                  } ' \
				    -e '/^[^#].*ubiquity\/success_command/,/[^\\]$/ { ' \
				    -e 's/^/#/g'                                        \
				    -e 's/#  /# /g                                  } '
				sed -i "${FILE_PATH}"                                   \
				    -e "/ubiquity\/success_command/i \\${INS_STR}"
			fi
		fi
	done
	chmod -x "${DIRS_NAME}/"*
}

# ----- create nocloud --------------------------------------------------------
function funcCreate_nocloud() {
	declare -r -a DIRS_LIST=("${DIRS_CONF}/nocloud/ubuntu_"{server,desktop}{,_old})
	declare       DIRS_NAME=""
	declare -i    I=0
	# -------------------------------------------------------------------------
	for ((I=0; I<"${#DIRS_LIST[@]}"; I++))
	do
		DIRS_NAME="${DIRS_LIST[I]}"
		funcPrintf "create filet: ${DIRS_NAME/${PWD}\/}"
		mkdir -p "${DIRS_NAME}"
		# ---------------------------------------------------------------------
		cp --update --backup "${CONF_CLUD}" "${DIRS_NAME}/user-data"
		if [[ "${DIRS_NAME}" =~ _old ]]; then
			sed -i "${DIRS_NAME}/user-data"     \
			    -e 's/bind9-utils/bind9utils/'  \
			    -e 's/bind9-dnsutils/dnsutils/'
		fi
		if [[ "${DIRS_NAME}" =~ _desktop ]]; then
			sed -i "${DIRS_NAME}/user-data"                                             \
			    -e '/^[ \t]*packages:$/,/:$/ { :l; /^#[ \t]*-[ \t]/ s/^#/ /; n; b l; }'
		fi
		touch "${DIRS_NAME}/meta-data"      --reference "${DIRS_NAME}/user-data"
		touch "${DIRS_NAME}/network-config" --reference "${DIRS_NAME}/user-data"
#		touch "${DIRS_NAME}/user-data"      --reference "${DIRS_NAME}/user-data"
		touch "${DIRS_NAME}/vendor-data"    --reference "${DIRS_NAME}/user-data"
		chmod -x "${DIRS_NAME}/"*
	done
}

# ----- create kickstart ------------------------------------------------------
function funcCreate_kickstart() {
	declare -r    DIRS_NAME="${DIRS_CONF}/kickstart"
	declare       FILE_PATH=""
	declare -r -a FILE_LIST=(                       \
		"ks_almalinux-9_"{net,dvd}".cfg"            \
		"ks_centos-stream-"{8..9}"_"{net,dvd}".cfg" \
		"ks_fedora-"{38..39}"_"{net,dvd}".cfg"      \
		"ks_miraclelinux-"{8..9}"_"{net,dvd}".cfg"  \
		"ks_rockylinux-"{8..9}"_"{net,dvd}".cfg"    \
	)
	declare       DSTR_NAME=""
	declare       DSTR_NUMS=""
	declare       RLNX_NUMS=""
	declare -r    BASE_ARCH="x86_64"
	declare       DSTR_SECT=""
	declare -i    I=0
	# -------------------------------------------------------------------------
	for ((I=0; I<"${#FILE_LIST[@]}"; I++))
	do
		FILE_PATH="${DIRS_NAME}/${FILE_LIST[I]}"
		funcPrintf "create filet: ${FILE_PATH/${PWD}\/}"
		mkdir -p "${FILE_PATH%/*}"
		# ---------------------------------------------------------------------
		DSTR_NAME="$(echo "${FILE_LIST[I]}" | sed -ne 's%^.*_\(almalinux\|centos-stream\|fedora\|miraclelinux\|rockylinux\)-.*$%\1%p')"
		DSTR_NUMS="$(echo "${FILE_LIST[I]}" | sed -ne 's%^.*'"${DSTR_NAME}"'-\([0-9.]\+\)_.*$%\1%p')"
		DSTR_SECT="${DSTR_NAME/-/ }"
		RLNX_NUMS="${DSTR_NUMS}"
		if [[ "${DSTR_NAME}" = "fedora" ]] && [[ ${DSTR_NUMS} -ge 38 ]] && [[ ${DSTR_NUMS} -le 39 ]]; then
			RLNX_NUMS="9"
		fi
		# ---------------------------------------------------------------------
		cp --update --backup "${CONF_KICK}" "${FILE_PATH}"
		if [[ "${DSTR_NAME}" = "centos-stream" ]]; then
			DSTR_SECT="${DSTR_NAME/-/ }-${DSTR_NUMS}"
		fi
		case "${FILE_LIST[I]}" in
			*_dvd* )
				sed -i "${FILE_PATH}"                          \
				    -e "/^#cdrom/ s/^#//                     " \
				    -e "s/_HOSTNAME_/${DSTR_NAME%%-*}/       " \
				    -e "/^#.*(${DSTR_SECT}).*$/,/^$/       { " \
				    -e '/_WEBADDR_/                        { ' \
				    -e '/^url[ \t]\+/   s/^/#/g              ' \
				    -e '/^repo[ \t]\+/  s/^/#/g            } ' \
				    -e "/_WEBADDR_/!                       { " \
				    -e "/^url[ \t]\+/   s/^/#/g              " \
				    -e "/^repo[ \t]\+/  s/^/#/g              " \
				    -e "s/\$releasever/${DSTR_NUMS}/g        " \
				    -e "s/\$basearch/${BASE_ARCH}/g       }} " \
				    -e "/%post/,/%end/                     { " \
				    -e "s/\$releasever/${RLNX_NUMS}/g      } "
				;;
			* )
				sed -i "${FILE_PATH}"                          \
				    -e "/^cdrom/ s/^/#/                      " \
				    -e "s/_HOSTNAME_/${DSTR_NAME%%-*}/       " \
				    -e "/^#.*(${DSTR_SECT}).*$/,/^$/       { " \
				    -e '/_WEBADDR_/                        { ' \
				    -e '/^url[ \t]\+/   s/^/#/g              ' \
				    -e '/^repo[ \t]\+/  s/^/#/g            } ' \
				    -e "/_WEBADDR_/!                       { " \
				    -e "/^#url[ \t]\+/  s/^#//g              " \
				    -e "/^#repo[ \t]\+/ s/^#//g              " \
				    -e "s/\$releasever/${DSTR_NUMS}/g        " \
				    -e "s/\$basearch/${BASE_ARCH}/g       }} " \
				    -e "/%post/,/%end/                     { " \
				    -e "s/\$releasever/${RLNX_NUMS}/g      } "
				;;
		esac
		if [[ ${RLNX_NUMS} -le 8 ]]; then
			sed -i "${FILE_PATH}"                      \
			    -e "/^timesource/             s/^/#/g" \
			    -e "/^timezone/               s/^/#/g" \
			    -e "/timezone.* --ntpservers/ s/^#//g"
		fi
		if [[ "${DSTR_NAME}" = "fedora" ]]; then
			sed -i "${FILE_PATH}"                      \
			    -e "/^#.*(${DSTR_SECT}).*$/,/^$/   { " \
			    -e "/_WEBADDR_/                    { " \
			    -e "/^repo[ \t]\+/  s/^/#/g        } " \
			    -e "/_WEBADDR_/!                   { " \
			    -e "/^#repo[ \t]\+/ s/^#//g       }} "
		fi
#		sed -i "${FILE_PATH}"                          \
#		    -e "/^#.*(${DSTR_SECT}).*$/,/^$/       { " \
#		    -e "s%_WEBADDR_%${WEBS_ADDR}/imgs%g    } "
		sed -e "/%packages/,/%end/ {"                  \
		    -e "/desktop/ s/^-//g  }"                  \
		    "${FILE_PATH}"                             \
		>   "${FILE_PATH/.cfg/_desktop.cfg}"
	done
	chmod -x "${DIRS_NAME}/"*
}

# ----- create autoyast -------------------------------------------------------
function funcCreate_autoyast() {
	declare -r    DIRS_NAME="${DIRS_CONF}/autoyast"
	declare       FILE_PATH=""
	declare -r -a FILE_LIST=(
		"autoinst_"{leap-{15.5,15.6},tumbleweed}"_"{net,dvd}{,_lxde}".xml"
	)
	declare       DSTR_NUMS=""
	declare -r    BASE_ARCH="x86_64"
	declare -i    I=0
	# -------------------------------------------------------------------------
	for ((I=0; I<"${#FILE_LIST[@]}"; I++))
	do
		FILE_PATH="${DIRS_NAME}/${FILE_LIST[I]}"
		funcPrintf "create filet: ${FILE_PATH/${PWD}\/}"
		mkdir -p "${FILE_PATH%/*}"
		# ---------------------------------------------------------------------
		DSTR_NUMS="$(echo "${FILE_LIST[I]}" | sed -ne 's%^.*_\(leap-[0-9.]\+\|tumbleweed\)_.*$%\1%p')"
		# ---------------------------------------------------------------------
		cp --update --backup "${CONF_YAST}" "${FILE_PATH}"
		if [[ "${DSTR_NUMS}" =~ leap ]]; then
			sed -i "${FILE_PATH}"                                                 \
			    -e '/<add_on_products .*>/,/<\/add_on_products>/              { ' \
			    -e '/<!-- leap/,/leap -->/                                    { ' \
			    -e "/<media_url>/ s~/\(leap\)/[0-9.]*/~/\1/${DSTR_NUMS#*-}/~g   " \
			    -e "/<media_url>/ s~/\(leap\)/[0-9.]*/~/\1/${DSTR_NUMS#*-}/~g } " \
			    -e '/<!-- leap$/ s/$/ -->/g                                     ' \
			    -e '/^leap -->/  s/^/<!-- /g                                  } ' \
			    -e 's/ens160/eth0/g                                             ' \
			    -e 's~\(<product>\).*\(</product>\)~\1Leap\2~                   '
		else
			sed -i "${FILE_PATH}"                                                 \
			    -e '/<add_on_products .*>/,/<\/add_on_products>/              { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/                        { ' \
			    -e '/<media_url>/ s~/leap/[0-9.]*/~/tumbleweed/~g               ' \
			    -e '/<media_url>/ s~/leap/[0-9.]*/~/tumbleweed/~g             } ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                               ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                            } ' \
			    -e 's/eth0/ens160/g                                             ' \
			    -e 's~\(<product>\).*\(</product>\)~\1openSUSE\2~               '
		fi
		if [[ "${FILE_PATH}" =~ _lxde ]]; then
			sed -i "${FILE_PATH}"                     \
			    -e '/<!-- desktop lxde$/ s/$/ -->/g ' \
			    -e '/^desktop lxde -->/  s/^/<!-- /g'
		fi
	done
	chmod -x "${DIRS_NAME}/"*
}

# ----- create menu -----------------------------------------------------------
function funcCreate_menu() {
	declare -r -a CURL_OPTN=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -a    DATA_LINE=()
	declare       TEXT_COLR=""
	declare       TEXT_LINE=""
	declare       DIRS_NAME=""
	declare -a    FILE_INFO=()
	declare       FILE_ORIG=""
	declare       FILE_ISOS=""
	declare       FILE_NAME=""
	declare       FILE_SIZE=""
	declare       FILE_TIME=""
	declare       FILE_VLID=""
	declare -a    WEBS_PAGE=()			# web page data
	declare       WEBS_DISP=""			# web display data
	declare       WEBS_REXP=""			# regular expression part of url
	declare       DIRS_SECT=""
	declare -i    I=0
	declare -i    J=0
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
#	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	DATA_LIST=("$@")
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "# $(funcString $((COLS_SIZE-4)) '-') #"
	TEXT_COLR=""
	TEXT_LINE="$(printf "%-2.2s:%-42.42s:%-10.10s:%-10.10s:%-$((COLS_SIZE-70)).$((COLS_SIZE-70))s" "ID" "Version" "ReleaseDay" "SupportEnd" "Memo")"
	funcPrintf "${TXT_RESET}#${TEXT_COLR}${TEXT_LINE}${TXT_RESET}#"
	TGET_LIST=()
	for ((I=0, J=1; I<"${#DATA_LIST[@]}"; I++))
	do
		read -r -a DATA_LINE < <(echo "${DATA_LIST[I]}")
		if [[ "${DATA_LINE[0]}" != "o" ]] || { [[ ! "${DATA_LINE[16]}" =~ ^http://.*$ ]] && [[ ! "${DATA_LINE[16]}" =~ ^https://.*$ ]]; }; then
			continue
		fi
		TEXT_COLR=""
		DIRS_NAME="${DATA_LINE[16]%/*}"
		FILE_NAME="${DATA_LINE[16]##*/}"
		# --- URL completion [dir name] ---------------------------------------
		if [[ "${DIRS_NAME}" =~ \[.*\] ]]; then
			set +e
			WEBS_PAGE=("$(curl "${CURL_OPTN[@]}" "${DIRS_NAME%/*\[*}" 2> /dev/null)")
			RET_CD=$?
			set -e
			if [[ "${RET_CD}" -eq 6 ]] || [[ "${RET_CD}" -eq 18 ]] || [[ "${RET_CD}" -eq 22 ]] || [[ "${RET_CD}" -eq 28 ]] || [[ "${#WEBS_PAGE[@]}" -le 0 ]]; then
				TEXT_COLR="${TXT_RED}"
			else
				WEBS_REXP="$(echo "${DIRS_NAME}" | sed -ne 's%^.*/\([^/]*\[[^/]*\][^/]*\)/.*$%\1%p')"
				WEBS_DISP="$(echo "${WEBS_PAGE[@]}" | sed -ne '/'"${WEBS_REXP}"'/ s%^.*<a href=.*> *\('"${WEBS_REXP}"'\)/* *</a>.*$%\1%p' | sort -r | head -n 1)"
				DIRS_NAME="${DIRS_NAME%/*\[*}/${WEBS_DISP}/${DIRS_NAME#*\]*/}"
				DATA_LINE[16]="${DIRS_NAME}/${FILE_NAME}"
			fi
		fi
		# --- URL completion [file name] --------------------------------------
		if [[ "${TEXT_COLR}" != "${TXT_RED}" ]] && [[ "${FILE_NAME}" =~ \[.*\] ]]; then
			set +e
			WEBS_PAGE=("$(curl "${CURL_OPTN[@]}" "${DIRS_NAME}" 2> /dev/null)")
			RET_CD=$?
			set -e
			if [[ "${RET_CD}" -eq 6 ]] || [[ "${RET_CD}" -eq 18 ]] || [[ "${RET_CD}" -eq 22 ]] || [[ "${RET_CD}" -eq 28 ]] || [[ "${#WEBS_PAGE[@]}" -le 0 ]]; then
				TEXT_COLR="${TXT_RED}"
			else
				FILE_NAME="$(echo "${WEBS_PAGE[@]}" | sed -ne '/'"${FILE_NAME}"'/ s%^.*<a href=.*> *\('"${FILE_NAME}"'\)/* *</a>.*$%\1%p' | sort -r | head -n 1)"
				DATA_LINE[16]="${DIRS_NAME}/${FILE_NAME}"
				DATA_LINE[4]="${FILE_NAME}"
			fi
		fi
		# --- file information completion -------------------------------------
		if [[ "${TEXT_COLR}" != "${TXT_RED}" ]]; then
			set +e
			WEBS_PAGE=("$(curl "${CURL_OPTN[@]}" --head "${DATA_LINE[16]}" 2> /dev/null)")
			RET_CD=$?
			set -e
			if [[ "${RET_CD}" -eq 6 ]] || [[ "${RET_CD}" -eq 18 ]] || [[ "${RET_CD}" -eq 22 ]] || [[ "${RET_CD}" -eq 28 ]] || [[ "${#WEBS_PAGE[@]}" -le 0 ]]; then
				TEXT_COLR="${TXT_RED}"
			else
				FILE_INFO=("$(echo "${WEBS_PAGE[@],,}" | sed -ne '/^http\/.\+ 200/,/^$/ s/'$'\r''//gp')")
				FILE_SIZE="$(echo "${FILE_INFO[@]}" | sed -ne '/^content-length:/ s/^[^ \t]\+: *//p')"
				FILE_TIME="$(echo "${FILE_INFO[@]}" | sed -ne '/^last-modified:/ s/^[^ \t]\+: *//p')"
				FILE_TIME="$(TZ=UTC date -d "${FILE_TIME}" "+%Y-%m-%d %H:%M:%S")"
				DATA_LINE[10]="${FILE_TIME% *}"
				DATA_LINE[12]="${FILE_TIME#* }"
				DATA_LINE[13]="${FILE_SIZE}"
			fi
		fi
		# --- local original file information ---------------------------------
		# shellcheck disable=SC2001
		DIRS_SECT="$(echo "${DATA_LINE[8]}" | sed -e 's%^.*\(preseed\|nocloud\|kickstar\|autoyast\).*$%\1%')"
		FILE_ORIG="${DIRS_ISOS}/${DATA_LINE[4]}"										# original file
		FILE_ISOS="${DIRS_RMAK}/${DATA_LINE[4]%.*}_${DIRS_SECT}.${DATA_LINE[4]##*.}"	# custom file
		if [[ "${TEXT_COLR}" != "${TXT_RED}" ]]; then
			if [[ ! -f "${FILE_ORIG}" ]]; then
				TEXT_COLR="${TXT_CYAN}"
			else
				# shellcheck disable=SC2312
				read -r -a FILE_INFO < <(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${FILE_ORIG}")
				FILE_SIZE="${FILE_INFO[4]}"
				FILE_TIME="${FILE_INFO[5]}"
				if [[ "${DATA_LINE[10]//-}${DATA_LINE[12]//:}" != "${FILE_TIME}" ]] || [[ "${DATA_LINE[13]}" -ne "${FILE_SIZE}" ]]; then
					TEXT_COLR="${TXT_GREEN}"
				fi
			fi
		fi
		# --- local custom file information -----------------------------------
		if [[ ! -f "${FILE_ISOS}" ]]; then
			if [[ -z "${TEXT_COLR}" ]]; then
				TEXT_COLR="${TXT_YELLOW}"
			fi
			TEXT_COLR+="${TXT_REV}"
		else
			# shellcheck disable=SC2312
			read -r -a FILE_INFO < <(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${FILE_ISOS}")
			FILE_SIZE="${FILE_INFO[4]}"
			FILE_TIME="${FILE_INFO[5]}"
			if [[ "${DATA_LINE[10]//-}${DATA_LINE[12]//:}" != "${FILE_TIME}" ]] || [[ "${DATA_LINE[13]}" -ne "${FILE_SIZE}" ]]; then
				if [[ -z "${TEXT_COLR}" ]]; then
					TEXT_COLR="${TXT_YELLOW}"
				fi
				TEXT_COLR+="${TXT_REV}"
			fi
		fi
		# --- data display ----------------------------------------------------
		# TXT_RESET  local files are up to date
		# TXT_RED    failed to get web information
		# TXT_CYAN   local file does not exist
		# TXT_GREEN  local file is old
		# TXT_YELLOW custom file is old
		# TXT_REV    requires creation of custom file
		TEXT_LINE="$(printf "%2d:%-42.42s:%-10.10s:%-10.10s:%-$((COLS_SIZE-70)).$((COLS_SIZE-70))s" "${J}" "${DATA_LINE[4]}" "${DATA_LINE[10]}" "${DATA_LINE[11]}" "${DATA_LINE[2]//%20/ }[${DIRS_SECT}]")"
		funcPrintf "${TXT_RESET}#${TEXT_COLR}${TEXT_LINE}${TXT_RESET}#"
		# --- data restore ----------------------------------------------------
		# shellcheck disable=SC2312
		if [[ -n "$(command -v volname 2> /dev/null)" ]]; then
			FILE_VLID="$(volname "${FILE_ORIG}")"
		else
			FILE_VLID="$(LANG=C blkid -s LABEL "${FILE_ORIG}" | sed -ne 's/^.*="\(.*\)"/\1/p')"
		fi
		DATA_LINE[14]="${FILE_VLID}"
		DATA_LINE[15]="${TEXT_COLR}"
		TGET_LIST+=("${DATA_LINE[*]}")
		((J++))
	done
	# shellcheck disable=SC2312
	funcPrintf "# $(funcString $((COLS_SIZE-4)) '-') #"
}

# ----- create target list ----------------------------------------------------
function funcCreate_target_list() {
	declare -i    RET_CD=0

	if [[ "${#TGET_LIST[@]}" -le 0 ]]; then
		return
	fi

#	funcPrintf "after 10 seconds, select all number to continue"
	echo -n "enter the number to create: "
	set +e
#	read -r -t 10 TGET_INDX
	read -r TGET_INDX
	RET_CD=$?
	set -e
	if [[ ${RET_CD} -ne 0 ]] && [[ -z "${TGET_INDX:-}" ]]; then
		echo "{1..${#TGET_LIST[@]}}"
		TGET_INDX="{1..${#TGET_LIST[@]}}"
		return
	fi
	case "${TGET_INDX,,}" in
		a | all ) TGET_INDX="{1..${#TGET_LIST[@]}}";;
		*       ) ;;
	esac
}

# ----- create remaster download-----------------------------------------------
function funcCreate_remaster_download() {
#	declare -r    OLD_IFS="${IFS}"
#	declare -r    MSGS_TITL="create target list"
#	declare -r -a DATA_LIST=("$@")
	declare -r -a CURL_OPTN=("--location" "--http1.1" "--progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -a    TGET_LINE=("$@")
	declare -i    RET_CD=0
	declare -i    I=0
	# --- download ------------------------------------------------------------
	case "${TGET_LINE[15]}" in
		*${TXT_CYAN}*  | \
		*${TXT_GREEN}* )
			# shellcheck disable=SC2312
			funcPrintf "    download: ${TGET_LINE[4]} $(funcUnit_conversion "${TGET_LINE[13]}")"
			set +e
			curl "${CURL_OPTN[@]}" --create-dirs --output-dir "${DIRS_ISOS}" --output "${TGET_LINE[4]}" "${TGET_LINE[16]}"
			RET_CD=$?
			set -e
			if [[ "${RET_CD}" -ne 0 ]]; then
				for ((I=0; I<3; I++))
				do
					set +e
					curl "${CURL_OPTN[@]}" --continue-at - --remote-name --create-dirs --output-dir "${DIRS_ISOS}" --output "${TGET_LINE[4]}" "${TGET_LINE[16]}"
					RET_CD=$?
					set -e
					if [[ "${RET_CD}" -eq 0 ]]; then
						break
					fi
				done
			fi
			if [[ "${RET_CD}" -eq 18 ]] || [[ "${RET_CD}" -eq 22 ]] || [[ "${RET_CD}" -eq 28 ]] || [[ "${RET_CD}" -eq 56 ]]; then
				funcPrintf "       error: ${TXT_RED}Download was skipped because an ${TXT_REV}error${TXT_REVRST} occurred [${RET_CD}]${TXT_RESET}"
			fi
			;;
		* )
			;;
	esac
}

# ----- copy iso contents to hdd ----------------------------------------------
function funcCreate_copy_iso2hdd() {
	declare -r -a TGET_LINE=("$@")
	declare -r    FILE_PATH="${DIRS_ISOS}/${TGET_LINE[4]}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_MNTP="${WORK_DIRS}/mnt"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -r    WORK_RAMS="${WORK_DIRS}/ram"
	declare       DIRS_IRAM=""
	declare       FILE_IRAM=""
	declare -i    RET_CD=0
	funcPrintf "        copy: ${TGET_LINE[4]}"
	# --- forced unmount ------------------------------------------------------
	if [[ -d "${WORK_MNTP}/." ]]; then
		set +e
		mountpoint -q "${WORK_MNTP}"
		RET_CD=$?
		if [[ "${RET_CD}" -eq 0 ]]; then
			if [[ "${WORK_MNTP##*/}" = "dev" ]]; then
				umount -q "${WORK_MNTP}/pts" || umount -q -lf "${WORK_MNTP}/pts"
			fi
			umount -q "${WORK_MNTP}" || umount -q -lf "${WORK_MNTP}"
		fi
		set -e
	fi
	# --- remove directory ----------------------------------------------------
	rm -rf "${WORK_DIRS}"
	# --- create directory ----------------------------------------------------
	mkdir -p "${WORK_DIRS}/"{mnt,img,ram}
	# --- copy iso -> hdd -----------------------------------------------------
	mount -o ro,loop "${FILE_PATH}" "${WORK_MNTP}"
	nice -n 10 cp -a "${WORK_MNTP}/." "${WORK_IMGS}/"
	umount "${WORK_MNTP}"
	# --- copy initrd -> hdd --------------------------------------------------
	if [[ "${TGET_LINE[1]}" =~ -mini- ]]; then
		funcPrintf "        copy: initrd"
		# shellcheck disable=SC2312
		while read -r FILE_IRAM
		do
			DIRS_IRAM="${WORK_RAMS}/${FILE_IRAM##*/}"
			mkdir -p "${DIRS_IRAM}"
			unmkinitramfs "${FILE_IRAM}" "${DIRS_IRAM}/" 2>/dev/null
		done < <(find "${WORK_IMGS}" -name 'initrd*' -type f)
	fi
	# --- remove directory ----------------------------------------------------
#	rm -rf "${WORK_DIRS}"
}

# ----- create autoinst.cfg for syslinux --------------------------------------
function funcCreate_autoinst_cfg_syslinux() {
	declare -r    AUTO_INST="$1"							# autoinst.cfg path
	declare -r    BOOT_OPTN="$2"							# boot option
	shift 2
	declare -r -a TGET_LINE=("$@")
	declare -r    DIRS_MENU="${AUTO_INST%/*}"				# configuration file path
	declare       FILE_CONF=""								# configuration file path
	declare       INSR_STRS=""								# string to insert
	declare       FILE_IRAM=""								# initrd path
	declare       FILE_VLNZ=""								# kernel path
	declare -a    WORK_ARRY=()								# work

	for FILE_CONF in "${DIRS_MENU}/"{txt.cfg,gtk.cfg,isolinux.cfg}
	do
		if [[ ! -f "${FILE_CONF}" ]]; then
			continue
		fi
		funcPrintf "      search: ${FILE_CONF##*/}"
		case "${FILE_CONF##*/}" in
			txt.cfg | \
			gtk.cfg )
				WORK_ARRY=("$(sed -ne '/^label[ \t]\+install\(gui\)*[^[:graph:]]*$/,/\(^$\|^label[ \t]\+\)/p' "${FILE_CONF}")")
				FILE_IRAM="$(echo "${WORK_ARRY[@]}" | sed -ne '/^[ \t]*append[ \t]\+/ s/^.*[ \t]\+initrd=\([[:graph:]]\+\)[^[:graph:]]*.*$/\1/p')"
				FILE_VLNZ="$(echo "${WORK_ARRY[@]}" | sed -ne '/^[ \t]*kernel[ \t]\+/ s/^.*[ \t]\+\([[:graph:]]\+\)[^[:graph:]]*.*$/\1/p')"
				;;
			* )
				;;
		esac
		case "${TGET_LINE[1]}" in
			*-mini-* ) FILE_IRAM="${FILE_IRAM/initrd*/initps.gz}";;
			*        ) ;;
		esac
		case "${FILE_CONF##*/}" in
			txt.cfg )
				cat <<- _EOT_ | sed 's/^ *//g' > "${AUTO_INST}"
					timeout 50
					default auto_install
					
					label auto_install
					 	menu label ^Auto_install
					 	menu default
					 	kernel ${FILE_VLNZ}
					 	append initrd=${FILE_IRAM} vga=791 ${BOOT_OPTN} ---
					
_EOT_
				;;
			gtk.cfg )
				cat <<- _EOT_ | sed 's/^ *//g' >> "${AUTO_INST}"
					label auto_installgui
					 	menu label ^Auto_installgui
					 	kernel ${FILE_VLNZ}
					 	append initrd=${FILE_IRAM} vga=791 ${BOOT_OPTN} ---
					
_EOT_
				;;
			* )
				;;
		esac
	done
}

# ----- create autoinst.cfg for grub ------------------------------------------
function funcCreate_autoinst_cfg_grub() {
	declare -r    AUTO_INST="$1"							# autoinst.cfg path
	declare -r    BOOT_OPTN="$2"							# boot option
	shift 2
	declare -r -a TGET_LINE=("$@")
	declare -r    DIRS_MENU="${AUTO_INST%/*}"				# configuration file path
	declare       FILE_CONF="${DIRS_MENU}/grub.cfg"			# configuration file path
	declare       MENU_ETRY=""								# menu entry
	declare       INSR_STRS=""								# string to insert
	declare       FILE_IRAM=""								# initrd path
	declare       FILE_VLNZ=""								# kernel path
	declare -a    WORK_ARRY=()								# work

	for MENU_ETRY in "Install" "Graphical install"
	do
		WORK_ARRY=("$(sed -ne "/^menuentry[ \t]\+.*['\"]${MENU_ETRY}['\"][ \t]\+{/,/}/p" "${FILE_CONF}")")
		if [[ -z "${WORK_ARRY[*]}" ]]; then
			continue
		fi
		funcPrintf "      search: ${MENU_ETRY##*/}"
		FILE_VLNZ="$(echo "${WORK_ARRY[@]}" | sed -ne '/^[ \t]*linux\(\|efi\)[ \t]\+/ s/^[ \t]*[[:graph:]]\+[ \t]\+\([[:graph:]]\+\)[ \t]\+.*$/\1/p')"
		FILE_IRAM="$(echo "${WORK_ARRY[@]}" | sed -ne '/^[ \t]*initrd\(\|efi\)[ \t]\+/ s/^[ \t]*[[:graph:]]\+[ \t]\+\([[:graph:]]\+\)[ \t]*.*$/\1/p')"
		case "${TGET_LINE[1]}" in
			*-mini-* ) FILE_IRAM="${FILE_IRAM/initrd*/initps.gz}";;
			*        ) ;;
		esac
		case "${MENU_ETRY}" in
			Install )
				cat <<- _EOT_ | sed 's/^ *//g' > "${DIRS_MENU}/autoinst.cfg"
					set default=0
					set timeout=5
					
					menuentry 'Auto install' {
					 	set background_color=black
					 	linux  ${FILE_VLNZ} vga=791 ${BOOT_OPTN} ---
					 	initrd ${FILE_IRAM}
					}
					
_EOT_
				;;
			Graphical\ install )
				cat <<- _EOT_ | sed 's/^ *//g' >> "${DIRS_MENU}/autoinst.cfg"
					menuentry 'Auto installgui' {
					 	set background_color=black
					 	linux  ${FILE_VLNZ} vga=791 ${BOOT_OPTN} ---
					 	initrd ${FILE_IRAM}
					}
					
_EOT_
				;;
			* )
				;;
		esac
	done
}

# ----- create syslinux.cfg ---------------------------------------------------
function funcCreate_syslinux_cfg() {
	declare -r    BOOT_OPTN="$1"
	shift
	declare -r -a TGET_LINE=("$@")
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -a    WORK_ARRY=()
	declare -r    AUTO_INST="autoinst.cfg"
	declare -i    AUTO_FLAG=0
	declare       FILE_MENU=""			# syslinux or isolinux path
	declare       DIRS_MENU=""			# configuration file directory
	declare       FILE_CONF=""			# configuration file path
	declare       INSR_STRS=""			# string to insert
	declare       FILE_IRAM=""			# initrd path
	declare       FILE_VLNZ=""			# kernel path
	funcPrintf "      create: ${AUTO_INST} for syslinux"
	# shellcheck disable=SC2312
	while read -r FILE_MENU
	do
		DIRS_MENU="${FILE_MENU%/*}"
		AUTO_FLAG=0
		# --- editing the configuration file ----------------------------------
		for FILE_CONF in "${DIRS_MENU}/"*.cfg
		do
			# --- comment out "timeout" and "menu default" --------------------
			set +e
			read -r -a WORK_ARRY < <(                                   \
				sed -ne '/^[ \t]*timeout[ \t]\+[0-9]\+[^[:graph:]]*$/p' \
				    -ne '/^[ \t]*menu[ \t]\+default[^[:graph:]]*$/p'    \
				    "${FILE_CONF}"
			)
			set -e
			if [[ -n "${WORK_ARRY[*]}" ]]; then
				sed -i "${FILE_CONF}"                                         \
				    -e '/^[ \t]*timeout[ \t]\+[0-9]\+[^[:graph:]]*$/ s/^/#/g' \
				    -e '/^[ \t]*menu[ \t]\+default[^[:graph:]]*$/    s/^/#/g'
			fi
			# --- insert "autoinst.cfg" ---------------------------------------
			set +e
			read -r -a WORK_ARRY < <(                            \
				sed -ne '/^include[ \t]\+.*stdmenu.cfg[^[:graph:]]*$/p' \
				    "${FILE_CONF}"
			)
			set -e
			if [[ -n "${WORK_ARRY[*]}" ]]; then
				AUTO_FLAG=1
				INSR_STRS="$(sed -ne '/^include[ \t]\+[^ \t]*stdmenu.cfg[^[:graph:]]*$/p' "${FILE_CONF}")"
				sed -i "${FILE_CONF}"                                                                               \
				    -e '/^\(include[ \t]\+\)[^ \t]*stdmenu.cfg[^[:graph:]]*$/ a '"${INSR_STRS/stdmenu.cfg/${AUTO_INST}}"''
			fi
		done
		if [[ "${AUTO_FLAG}" -ne 0 ]]; then
			funcCreate_autoinst_cfg_syslinux "${DIRS_MENU}/${AUTO_INST}" "${BOOT_OPTN}" "${TGET_LINE[@]}"
		fi
	done < <(find "${WORK_IMGS}" \( -name 'syslinux.cfg' -o -name 'isolinux.cfg' \) -type f)
}

# ----- create grub.cfg -------------------------------------------------------
function funcCreate_grub_cfg() {
	declare -r    BOOT_OPTN="$1"
	shift
	declare -r -a TGET_LINE=("$@")
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -a    WORK_ARRY=()
	declare -r    AUTO_INST="autoinst.cfg"
	declare       FILE_MENU=""			# syslinux or isolinux path
	declare       DIRS_MENU=""			# configuration file directory
	declare       FILE_CONF=""			# configuration file path
	declare       INSR_STRS=""			# string to insert
	declare       FILE_IRAM=""			# initrd path
	declare       FILE_VLNZ=""			# kernel path
	funcPrintf "      create: ${AUTO_INST} for grub.cfg"
	# shellcheck disable=SC2312
	while read -r FILE_MENU
	do
		# shellcheck disable=SC2312
		if [[ -z "$(sed -ne '/^menuentry/p' "${FILE_MENU}")" ]]; then
			continue
		fi
		DIRS_MENU="${FILE_MENU%/*}"
		# --- comment out "timeout" and "menu default" --------------------
		# --- insert "autoinst.cfg" ---------------------------------------
		sed -i "${FILE_MENU}" \
		    -e "/^menuentry/ i source ${DIRS_MENU/${WORK_IMGS}/}/${AUTO_INST}"
		funcCreate_autoinst_cfg_grub "${DIRS_MENU}/${AUTO_INST}" "${BOOT_OPTN}" "${TGET_LINE[@]}"
	done < <(find "${WORK_IMGS}" -name 'grub.cfg' -type f)
}

# ----- create remaster preseed -----------------------------------------------
function funcCreate_remaster_preseed() {
	declare -r -a TGET_LINE=("$@")
	declare       BOOT_OPTN=""
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -r    WORK_RAMS="${WORK_DIRS}/ram"
	declare -r    WORK_CONF="${WORK_IMGS}/preseed"
	declare       DIRS_IRAM=""
	funcPrintf "      create: boot options for preseed"
	# --- boot option ---------------------------------------------------------
	case "${TGET_LINE[1]}" in
		*-mini-* ) BOOT_OPTN="auto=true";;
		*        ) BOOT_OPTN="auto=true preseed/file=/${TGET_LINE[8]%*/}";;
	esac
	BOOT_OPTN+=" netcfg/disable_autoconfig=true"
	BOOT_OPTN+=" netcfg/choose_interface=${ETHR_NAME}"
	BOOT_OPTN+=" netcfg/get_hostname=${HOST_NAME}.${WGRP_NAME}"
	BOOT_OPTN+=" netcfg/get_ipaddress=${IPV4_ADDR}"
	BOOT_OPTN+=" netcfg/get_netmask=${IPV4_MASK}"
	BOOT_OPTN+=" netcfg/get_gateway=${IPV4_GWAY}"
	BOOT_OPTN+=" netcfg/get_nameservers=${IPV4_NSVR}"
	BOOT_OPTN+=" locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	BOOT_OPTN+=" fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	case "${TGET_LINE[1]}" in
		*-mini-* )
			# shellcheck disable=SC2312
			while read -r FILE_IRAM
			do
				DIRS_IRAM="${WORK_RAMS}/${FILE_IRAM##*/}"
				cp -a "${DIRS_CONF}/preseed/preseed_kill_dhcp.sh"         "${DIRS_IRAM}"
				cp -a "${DIRS_CONF}/preseed/preseed_sub_command.sh"       "${DIRS_IRAM}"
				cp -a "${DIRS_CONF}/preseed/ps_${TGET_LINE[1]%%-*}_"*.cfg "${DIRS_IRAM}"
				ln -s "ps_${TGET_LINE[1]%%-*}_server.cfg"                 "${DIRS_IRAM}/preseed.cfg"
			done < <(find "${WORK_IMGS}" -name 'initrd*' -type f)
			;;
		debian-*         | \
		ubuntu-server-*  )
			mkdir -p "${WORK_CONF}"
			cp -a "${DIRS_CONF}/preseed/preseed_kill_dhcp.sh"         "${WORK_CONF}"
			cp -a "${DIRS_CONF}/preseed/preseed_sub_command.sh"       "${WORK_CONF}"
			cp -a "${DIRS_CONF}/preseed/ps_${TGET_LINE[1]%%-*}_"*.cfg "${WORK_CONF}"
			;;
		ubuntu-live-*    ) ;;
		ubuntu-desktop-* ) ;;
		ubuntu-legacy-*  ) ;;
		fedora-*         | \
		centos-*         | \
		almalinux-*      | \
		miraclelinux-*   | \
		rockylinux-*     ) ;;
		opensuse-*       ) ;;
		*                ) funcPrintf "not supported on ${TGET_LINE[1]}"; exit 1;;
	esac
}

# ----- create remaster nocloud -----------------------------------------------
function funcCreate_remaster_nocloud() {
	declare -r -a TGET_LINE=("$@")
	declare       BOOT_OPTN=""
	funcPrintf "      create: boot options for nocloud"
	# --- boot option ---------------------------------------------------------
	BOOT_OPTN="automatic-ubiquity noprompt autoinstall ds=nocloud-net;s=/${TGET_LINE[8]%*/}"
	BOOT_OPTN+=" ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:${HOST_NAME}.${WGRP_NAME}:${ETHR_NAME}:static:${IPV4_NSVR}"
	BOOT_OPTN+=" debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	BOOT_OPTN+=" fsck.mode=skip boot=casper"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
}

# ----- create remaster kickstart ---------------------------------------------
function funcCreate_remaster_kickstart() {
	declare -r -a TGET_LINE=("$@")
	declare       BOOT_OPTN=""
	funcPrintf "      create: boot options for kickstart"
	# --- boot option ---------------------------------------------------------
	BOOT_OPTN="inst.ks=hd:sr0:/${TGET_LINE[8]%*/}"
	BOOT_OPTN+=" ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:${HOST_NAME}.${WGRP_NAME}:${ETHR_NAME}:none,auto6 nameserver=${IPV4_NSVR}"
	BOOT_OPTN+=" locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	BOOT_OPTN+=" fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
}

# ----- create remaster autoyast ----------------------------------------------
function funcCreate_remaster_autoyast() {
	declare -r -a TGET_LINE=("$@")
	declare       BOOT_OPTN=""
	funcPrintf "      create: boot options for autoyast"
	# --- boot option ---------------------------------------------------------
	BOOT_OPTN="autoyast=cd:/${TGET_LINE[8]%*/}"
	BOOT_OPTN+=" hostname=${HOST_NAME}.${WGRP_NAME} ifcfg=${ETHR_NAME}=${IPV4_ADDR}/${IPV4_CIDR},${IPV4_GWAY},${IPV4_NSVR},${WGRP_NAME}"
	BOOT_OPTN+=" locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	BOOT_OPTN+=" fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
}

# ----- create remaster iso file ----------------------------------------------
function funcCreate_remaster_iso_file() {
	declare -r -a TGET_LINE=("$@")
	# shellcheck disable=SC2001
	declare -r    DIRS_SECT="$(echo "${TGET_LINE[8]}" | sed -e 's%^.*\(preseed\|nocloud\|kickstar\|autoyast\).*$%\1%')"
	declare -r    FILE_NAME="${TGET_LINE[4]%.*}_${DIRS_SECT}.${TGET_LINE[4]##*.}"
	declare -r    FILE_PATH="${DIRS_RMAK}/${FILE_NAME}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_MNTP="${WORK_DIRS}/mnt"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -r    WORK_RAMS="${WORK_DIRS}/ram"
	declare       DIRS_IRAM=""
	declare       FILE_IRAM=""
	declare       FILE_HBRD=""
	declare       FILE_BCAT=""
	declare       FILE_IBIN=""
	declare       FILE_UEFI=""
	declare -i    RET_CD=0
	# --- create initrd file --------------------------------------------------
	if [[ "${TGET_LINE[1]}" =~ -mini- ]]; then
		# shellcheck disable=SC2312
		while read -r DIRS_IRAM
		do
			funcPrintf "      create: remaster initps.gz"
			FILE_IRAM="${WORK_IMGS}/${DIRS_IRAM/${WORK_RAMS}/}"
			pushd "${DIRS_IRAM}" > /dev/null
				find . | cpio --format=newc --create --quiet | gzip > "${FILE_IRAM%/*}/initps.gz"
			popd > /dev/null
		done < <(find "${WORK_RAMS}" -name 'initrd*' -type d | sort | sed -ne '/\(initrd.*\/initrd*\|\/.*netboot\/\)/!p')
	fi
	# --- create iso file -----------------------------------------------------
	funcPrintf "      create: remaster iso file"
	funcPrintf "      create: ${FILE_NAME}"
	mkdir -p "${DIRS_RMAK}"
	pushd "${WORK_IMGS}" > /dev/null
		chmod -w -R .
		rm -f md5sum.txt
		find . -follow -type f ! -name 'md5sum.txt' -exec md5sum {} \; > md5sum.txt
		chmod -w md5sum.txt
		FILE_HBRD="$(find /usr/lib -follow -type f -name 'isohdpfx.bin'             )"
		FILE_BCAT="$(find .        -follow -type f -name 'boot.cat'     -printf "%P")"
		FILE_IBIN="$(find .        -follow -type f -name 'isolinux.bin' -printf "%P")"
		FILE_UEFI="$(find .        -follow -type f -name 'efi*.img'     -printf "%P")"
		nice -n 10 xorriso -as mkisofs \
		    -quiet \
		    -volid "${TGET_LINE[14]}" \
		    -eltorito-boot "${FILE_IBIN}" \
		    -eltorito-catalog "${FILE_BCAT}" \
		    -no-emul-boot -boot-load-size 4 -boot-info-table \
		    -isohybrid-mbr "${FILE_HBRD}" \
		    -eltorito-alt-boot -e "${FILE_UEFI}" \
		    -no-emul-boot -isohybrid-gpt-basdat \
		    -output "${FILE_PATH}" \
		    . > /dev/null 2>&1
	popd > /dev/null
	# --- remove directory ----------------------------------------------------
#	rm -rf "${WORK_DIRS}"
}

# ----- create remaster -------------------------------------------------------
function funcCreate_remaster() {
#	declare -r    OLD_IFS="${IFS}"
#	declare -r    MSGS_TITL="create target list"
#	declare -r -a DATA_LIST=("$@")
	declare -a    TGET_LINE=()
#	declare -i    RET_CD=0
	declare -i    I=0
#	declare -i    J=0
	# -------------------------------------------------------------------------
	for I in $(eval "echo ${TGET_INDX}")
	do
		read -r -a TGET_LINE < <(echo "${TGET_LIST[--I]}")
		# shellcheck disable=SC2312
		funcPrintf "===    start: ${TGET_LINE[4]} $(funcString "${COLS_SIZE}" '=')"
		# --- download --------------------------------------------------------
		funcCreate_remaster_download "${TGET_LINE[@]}"
		# --- copy iso contents to hdd ----------------------------------------
		funcCreate_copy_iso2hdd "${TGET_LINE[@]}"
		# --- rewriting syslinux.cfg and grub.cfg -----------------------------
		HOST_NAME="sv-${TGET_LINE[1]%%-*}"
		case "${TGET_LINE[1]%%-*}" in
			debian       | \
			ubuntu       ) 
				case "$(echo "${TGET_LINE[8]}" | sed -ne 's/^.*\(preseed\|nocloud\).*$/\1/p')" in
					preseed* ) funcCreate_remaster_preseed "${TGET_LINE[@]}";;
					nocloud* ) funcCreate_remaster_nocloud "${TGET_LINE[@]}";;
					*        ) funcPrintf "not supported on ${TGET_LINE[1]}"; exit 1;;
				esac
				;;
			fedora       | \
			centos       | \
			almalinux    | \
			miraclelinux | \
			rockylinux   )
				funcCreate_remaster_kickstart "${TGET_LINE[@]}"
				;;
			opensuse     )
				funcCreate_remaster_autoyast "${TGET_LINE[@]}"
				;;
			*            )				# --- not supported -------------------
				funcPrintf "not supported on ${TGET_LINE[1]}"
				exit 1
				;;
		esac
		# --- create iso file -------------------------------------------------
		funcCreate_remaster_iso_file "${TGET_LINE[@]}"
		# shellcheck disable=SC2312
		funcPrintf "=== complete: ${TGET_LINE[4]} $(funcString "${COLS_SIZE}" '=')"
	done
}

# === call function ===========================================================

# ---- function test ----------------------------------------------------------
function funcCall_function() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call function test"
	declare -r    FILE_WRK1="/tmp/testfile1.txt"
	declare -r    FILE_WRK2="/tmp/testfile2.txt"
	declare -r    HTTP_ADDR="https://raw.githubusercontent.com/office-itou/Linux/master/README.md"
	declare -r -a CURL_OPTN=(         \
		"--location"                  \
		"--progress-bar"              \
		"--remote-name"               \
		"--remote-time"               \
		"--show-error"                \
		"--fail"                      \
		"--retry-max-time" "3"        \
		"--retry" "3"                 \
		"--create-dirs"               \
		"--output-dir" "${DIRS_TEMP}" \
		"${HTTP_ADDR}"                \
	)
	declare       TEST_PARM=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_WRK1}"
		line 1
		line 2
		line 3
_EOT_
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_WRK2}"
		line 1
		Line 2
		line 3
_EOT_
	# --- text color test -----------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- text color test $(funcString "${COLS_SIZE}" '-')"
	funcPrintf "--no-cutting" "funcColorTest"
	funcColorTest
	echo ""

	# --- printf --------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- printf $(funcString "${COLS_SIZE}" '-')"
	funcPrintf "--no-cutting" "funcPrintf"
	funcPrintf "%s : %-12.12s : %s" "${TXT_RESET}"    "TXT_RESET"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_ULINE}"    "TXT_ULINE"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_ULINERST}" "TXT_ULINERST" "${TXT_RESET}"
#	funcPrintf "%s : %-12.12s : %s" "${TXT_BLINK}"    "TXT_BLINK"    "${TXT_RESET}"
#	funcPrintf "%s : %-12.12s : %s" "${TXT_BLINKRST}" "TXT_BLINKRST" "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_REV}"      "TXT_REV"      "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_REVRST}"   "TXT_REVRST"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BLACK}"    "TXT_BLACK"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_RED}"      "TXT_RED"      "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_GREEN}"    "TXT_GREEN"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_YELLOW}"   "TXT_YELLOW"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BLUE}"     "TXT_BLUE"     "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_MAGENTA}"  "TXT_MAGENTA"  "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_CYAN}"     "TXT_CYAN"     "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_WHITE}"    "TXT_WHITE"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BBLACK}"   "TXT_BBLACK"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BRED}"     "TXT_BRED"     "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BGREEN}"   "TXT_BGREEN"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BYELLOW}"  "TXT_BYELLOW"  "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BBLUE}"    "TXT_BBLUE"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BMAGENTA}" "TXT_BMAGENTA" "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BCYAN}"    "TXT_BCYAN"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_BWHITE}"   "TXT_BWHITE"   "${TXT_RESET}"
	echo ""

	# --- diff ----------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- diff $(funcString "${COLS_SIZE}" '-')"
	funcPrintf "--no-cutting" "funcDiff \"${FILE_WRK1/${PWD}\//}\" \"${FILE_WRK2/${PWD}\//}\" \"function test\""
	funcDiff "${FILE_WRK1/${PWD}\//}" "${FILE_WRK2/${PWD}\//}" "function test"
	echo ""

	# --- substr --------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- substr $(funcString "${COLS_SIZE}" '-')"
	TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcSubstr \"${TEST_PARM}\" 1 19"
	funcPrintf "--no-cutting" "         1         2         3         4"
	funcPrintf "--no-cutting" "1234567890123456789012345678901234567890"
	funcPrintf "--no-cutting" "${TEST_PARM}"
	funcSubstr "${TEST_PARM}" 1 19
	echo ""

	# --- service status ------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- service status $(funcString "${COLS_SIZE}" '-')"
	funcPrintf "--no-cutting" "funcServiceStatus \"sshd.service\""
	funcServiceStatus "sshd.service"
	echo ""

	# --- IPv6 full address ---------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- IPv6 full address $(funcString "${COLS_SIZE}" '-')"
	TEST_PARM="fe80::1"
	funcPrintf "--no-cutting" "funcIPv6GetFullAddr \"${TEST_PARM}\""
	funcIPv6GetFullAddr "${TEST_PARM}"
	echo ""

	# --- IPv6 reverse address ------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- IPv6 reverse address $(funcString "${COLS_SIZE}" '-')"
	TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcIPv6GetRevAddr \"${TEST_PARM}\""
	funcIPv6GetRevAddr "${TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 netmask conversion ---------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- IPv4 netmask conversion $(funcString "${COLS_SIZE}" '-')"
	TEST_PARM="24"
	funcPrintf "--no-cutting" "funcIPv4GetNetmask \"${TEST_PARM}\""
	funcIPv4GetNetmask "${TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 cidr conversion ------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- IPv4 cidr conversion $(funcString "${COLS_SIZE}" '-')"
	TEST_PARM="255.255.255.0"
	funcPrintf "--no-cutting" "funcIPv4GetNetCIDR \"${TEST_PARM}\""
	funcIPv4GetNetCIDR "${TEST_PARM}"
	echo ""

	# --- is numeric ----------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- is numeric $(funcString "${COLS_SIZE}" '-')"
	TEST_PARM="123.456"
	funcPrintf "--no-cutting" "funcIsNumeric \"${TEST_PARM}\""
	funcIsNumeric "${TEST_PARM}"
	echo ""
	TEST_PARM="abc.def"
	funcPrintf "--no-cutting" "funcIsNumeric \"${TEST_PARM}\""
	funcIsNumeric "${TEST_PARM}"
	echo ""

	# --- string output -------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- string output $(funcString "${COLS_SIZE}" '-')"
	TEST_PARM="50"
	funcPrintf "--no-cutting" "funcString \"${TEST_PARM}\" \"#\""
	funcString "${TEST_PARM}" "#"
	echo ""

	# --- print with screen control -------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- print with screen control $(funcString "${COLS_SIZE}" '-')"
	TEST_PARM="test"
	funcPrintf "--no-cutting" "funcPrintf \"${TEST_PARM}\""
	funcPrintf "${TEST_PARM}"
	echo ""

	# --- download ------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- download $(funcString "${COLS_SIZE}" '-')"
	funcPrintf "--no-cutting" "funcCurl ${CURL_OPTN[*]}"
	funcCurl "${CURL_OPTN[@]}"
	echo ""

	# -------------------------------------------------------------------------
	rm -f "${FILE_WRK1}" "${FILE_WRK2}"
	ls -l "${DIRS_TEMP}"
}

# ---- debug ------------------------------------------------------------------
function funcCall_debug() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call debug"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	shift 2
#	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
#		COMD_LIST=("" "" "$@")
#		IFS=' =,'
#		set -f
#		set -- "${COMD_LIST[@]:-}"
#		set +f
#		IFS=${OLD_IFS}
#	fi
	while [[ -n "${1:-}" ]]
	do
		# shellcheck disable=SC2034
		COMD_LIST=("${@:-}")
		case "${1:-}" in
			func )						# ===== function test =================
				funcCall_function
				;;
			text )						# ===== text color test ===============
				funcColorTest
				;;
			-* )
				break
				;;
			* )
				;;
		esac
		shift
	done
	# shellcheck disable=SC2034
	COMD_RETN="COMD_LIST[@]:-}"
}

# ---- config -----------------------------------------------------------------
function funcCall_config() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call config"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("cmd" "preseed" "nocloud" "kickstart" "autoyast" "$@")
		IFS=' =,'
		set -f
		set -- "${COMD_LIST[@]:-}"
		set +f
		IFS=${OLD_IFS}
	fi
	while [[ -n "${1:-}" ]]
	do
		# shellcheck disable=SC2034
		COMD_LIST=("${@:-}")
		case "${1:-}" in
			cmd )						# ==== create preseed kill dhcp / sub command
				funcCreate_preseed_kill_dhcp
				funcCreate_preseed_sub_command
				;;
			preseed )					# ==== create preseed.cfg =============
				funcCreate_preseed_cfg
				;;
			nocloud )					# ==== create nocloud =================
				funcCreate_nocloud
				;;
			kickstart )					# ==== create kickstart ===============
				funcCreate_kickstart
				;;
			autoyast )					# ==== create autoyast ================
				funcCreate_autoyast
				;;
			-* )
				break
				;;
			* )
				;;
		esac
		shift
	done
	# shellcheck disable=SC2034
	COMD_RETN="COMD_LIST[@]:-}"
}

# ---- create -----------------------------------------------------------------
function funcCall_create() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call create"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	declare -a    DATA_LIST=()
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("mini" "net" "dvd" "live" "tool" "$@")
		IFS=' =,'
		set -f
		set -- "${COMD_LIST[@]:-}"
		set +f
		IFS=${OLD_IFS}
	fi
	while [[ -n "${1:-}" ]]
	do
		# shellcheck disable=SC2034
		COMD_LIST=("${@:-}")
		DATA_LIST=()
		case "${1:-}" in
			mini ) DATA_LIST=("${DATA_LIST_MINI[@]}");;
			net  ) DATA_LIST=("${DATA_LIST_NET[@]}") ;;
			dvd  ) DATA_LIST=("${DATA_LIST_DVD[@]}") ;;
			live ) DATA_LIST=("${DATA_LIST_LIVE[@]}");;
#			tool ) DATA_LIST=("${DATA_LIST_TOOL[@]}");;
			-* )
				break
				;;
			* )
				;;
		esac
		if [[ "${#DATA_LIST[@]}" -gt 0 ]]; then
			funcCreate_menu "${DATA_LIST[@]}"
			case "${2:-}" in
				a | all ) shift; TGET_INDX="{1..${#TGET_LIST[@]}}";;
				*       ) funcCreate_target_list;;
			esac
			funcCreate_remaster
		fi
		shift
	done
	# shellcheck disable=SC2034
	COMD_RETN="COMD_LIST[@]:-}"
}

# === main ====================================================================

function funcMain() {
#	declare -r    OLD_IFS="${IFS}"
	declare -i    start_time=0
	declare -i    end_time=0
	declare -i    I=0
	declare -a    COMD_LINE=("${PROG_PARM[@]}")

	# ==== start ==============================================================

	# --- check the execution user --------------------------------------------
	# shellcheck disable=SC2312
	if [[ "$(whoami)" != "root" ]]; then
		funcPrintf "run as root user."
		exit 1
	fi

	# --- initialization ------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -n "$(command -v tput 2> /dev/null)" ]]; then
		ROWS_SIZE=$(tput lines)
		COLS_SIZE=$(tput cols)
	fi
	if [[ "${ROWS_SIZE}" -lt 25 ]]; then
		ROWS_SIZE=25
	fi
	if [[ "${COLS_SIZE}" -lt 80 ]]; then
		COLS_SIZE=80
	fi

	# --- main ----------------------------------------------------------------
	start_time=$(date +%s)
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"
	# shellcheck disable=SC2312
	funcPrintf "--- start $(funcString "${COLS_SIZE}" '-')"
	# shellcheck disable=SC2312
	funcPrintf "--- main $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ -z "${PROG_PARM[*]}" ]]; then
		funcPrintf "sudo ./${PROG_NAME} [ options ]"
	else
		IFS=' =,'
		set -f
		set -- "${COMD_LINE[@]:-}"
		set +f
		IFS=${OLD_IFS}
		while [[ -n "${1:-}" ]]
		do
			case "${1:-}" in
				-d | --debug   )			# ==== debug ======================
					funcCall_debug COMD_LINE "$@"
					;;
				-l | --link )				# ==== create symbolic link =======
					funcCreate_link
					shift
					COMD_LINE=("${@:-}")
					;;
				--conf )
					funcCall_config COMD_LINE "$@"
					;;
				--create )
					funcCall_create COMD_LINE "$@"
					;;
				* )
					shift
					COMD_LINE=("${@:-}")
					;;
			esac
			if [[ -z "${COMD_LINE[*]:-}" ]]; then
				break
			fi
			IFS=' =,'
			set -f
			set -- "${COMD_LINE[@]:-}"
			set +f
			IFS=${OLD_IFS}
		done
	fi

	# ==== complete ===========================================================
	# shellcheck disable=SC2312
	funcPrintf "--- complete $(funcString "${COLS_SIZE}" '-')"
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing end${TXT_RESET}"
	end_time=$(date +%s)
	funcPrintf "elapsed time: $((end_time-start_time)) [sec]"
}

# *** main processing section *************************************************
	funcMain
	exit 0

### eof #######################################################################
