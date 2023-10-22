#!/bin/bash

### initialization ############################################################
#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# Ends with status other than 0
	set -u								# End with undefined variable reference

	trap 'exit 1' 1 2 3 15

# --- check installation package ----------------------------------------------
#	dpkg -l curl lz4 lzma lzop dosfstools exfatprogs grub-pc-bin
#	apt-get install curl lz4 lzma lzop dosfstools exfatprogs grub-pc-bin
	declare -r -a APP_LIST=("fdisk" "coreutils" "curl" "exfatprogs" "ntfs-3g" "dosfstools" "grub2-common" "grub-pc-bin" "initramfs-tools-core" "cpio" "gzip" "bzip2" "lz4" "lzma" "lzop" "xz-utils" "zstd" "po-debconf")
	declare -r -a APP_FIND=($(LANG=C apt list "${APP_LIST[@]}" 2> /dev/null | sed -n -e '/\(^[[:blank:]]*$\|Listing\|installed\)/!p' | sed -n -e 's%^\([[:graph:]]*\)/.*$%\1%gp'))
	declare       APP_LINE=""
	for I in "${!APP_FIND[@]}"
	do
		if [[ -n "${APP_LINE}" ]]; then
			APP_LINE+=" "
		fi
		APP_LINE+="${APP_FIND[${I}]}"
	done
	if [[ -n "${APP_LINE}" ]]; then
		echo "please install these:"
		echo "sudo apt-get install ${APP_LINE}"
		exit 0
	fi

# --- working directory name --------------------------------------------------
	declare -r PROG_PATH="$0"
	declare -r PROG_PRAM="$@"
	declare -r PROG_NAME="${PROG_PATH##*/}"
	declare -r WORK_DIRS="${PROG_NAME%.*}"
	declare -r CACHE_FNAME="./${WORK_DIRS}/${PROG_NAME%.*}.cache.txt"

	# directory
	#   arc                         :   archive format file
	#   bld                         :   boot loader
	#   cfg                         :   config file
	#   deb                         :   deb format file
	#   img                         :   transfer image
	#   img/autoyast                :       yast format
	#   img/kickstart               :       kickstart format
	#   img/nocloud                 :       cloud init format
	#   img/nocloud/ubuntu.desktop  :           ubuntu desktop
	#   img/nocloud/ubuntu.server   :           ubuntu server
	#   img/preseed                 :       preseed format
	#   img/preseed/debian          :           debian
	#   img/preseed/ubuntu          :           ubuntu
	#   iso                         :   cdrom image
	#   iso/dvd                     :       dvd format
	#   iso/mini                    :       mini.iso
	#   iso/net                     :       net install
	#   mnt                         :   mount point (cdrom)
	#   opt                         :   option file
	#   pac                         :   unzip linux image
	#   ram                         :   unzip initramfs
	#   tmp                         :   temporary directory
	#   usb                         :   mount point (usb stick)
	# -------------------------------------------------------------------------
	# mkdir arc cfg opt (windows share directory)
	# -------------------------------------------------------------------------

	declare -r -a SDIR_LIST=(         \
#		"arc                        " \ #
		"bld                        " \
#		"cfg                        " \ #
		"deb                        " \
		"img                        " \
		"img/autoyast               " \
		"img/images                 " \
		"img/kickstart              " \
		"img/nocloud                " \
		"img/nocloud/ubuntu.desktop " \
		"img/nocloud/ubuntu.server  " \
		"img/preseed                " \
		"img/preseed/debian         " \
		"img/preseed/ubuntu         " \
		"iso                        " \
		"iso/dvd                    " \
		"iso/mini                   " \
		"iso/net                    " \
		"mnt                        " \
#		"opt                        " \ #
		"pac                        " \
		"ram                        " \
		"tmp                        " \
		"usb                        " \
	)

	declare -r -a LINK_LIST=(                                                                                                                                         \
		"/mnt/hgfs/workspace/Image/linux/workspace/arc                                          ./${WORK_DIRS}/arc                                                  " \
#		"/mnt/hgfs/workspace/Image/linux/workspace/bld                                          ./${WORK_DIRS}/bld                                                  " \ #
		"/mnt/hgfs/workspace/Image/linux/workspace/cfg                                          ./${WORK_DIRS}/cfg                                                  " \
#		"/mnt/hgfs/workspace/Image/linux/workspace/deb                                          ./${WORK_DIRS}/deb                                                  " \ #
		"/mnt/hgfs/workspace/Image/linux/workspace/opt                                          ./${WORK_DIRS}/opt                                                  " \
		"/mnt/hgfs/workspace/Image/linux/debian/mini-buster-amd64.iso                           ./${WORK_DIRS}/iso/mini/mini-buster-amd64.iso                       " \
		"/mnt/hgfs/workspace/Image/linux/debian/mini-bullseye-amd64.iso                         ./${WORK_DIRS}/iso/mini/mini-bullseye-amd64.iso                     " \
		"/mnt/hgfs/workspace/Image/linux/debian/mini-bookworm-amd64.iso                         ./${WORK_DIRS}/iso/mini/mini-bookworm-amd64.iso                     " \
		"/mnt/hgfs/workspace/Image/linux/debian/mini-trixie-amd64.iso                           ./${WORK_DIRS}/iso/mini/mini-trixie-amd64.iso                       " \
		"/mnt/hgfs/workspace/Image/linux/debian/mini-testing-amd64.iso                          ./${WORK_DIRS}/iso/mini/mini-testing-amd64.iso                      " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/mini-bionic-amd64.iso                           ./${WORK_DIRS}/iso/mini/mini-bionic-amd64.iso                       " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/mini-focal-amd64.iso                            ./${WORK_DIRS}/iso/mini/mini-focal-amd64.iso                        " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-10.13.0-amd64-netinst.iso                ./${WORK_DIRS}/iso/net/debian-10.13.0-amd64-netinst.iso             " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-11.8.0-amd64-netinst.iso                 ./${WORK_DIRS}/iso/net/debian-11.8.0-amd64-netinst.iso              " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-12.2.0-amd64-netinst.iso                 ./${WORK_DIRS}/iso/net/debian-12.2.0-amd64-netinst.iso              " \
#		"/mnt/hgfs/workspace/Image/linux/debian/debian-testing-amd64-netinst.iso                ./${WORK_DIRS}/iso/net/debian-13.0.0-amd64-netinst.iso              " \ #
		"/mnt/hgfs/workspace/Image/linux/debian/debian-testing-amd64-netinst.iso                ./${WORK_DIRS}/iso/net/debian-testing-amd64-netinst.iso             " \
#		"/mnt/hgfs/workspace/Image/linux/debian/debian-bookworm-DI-rc4-amd64-netinst.iso        ./${WORK_DIRS}/iso/net/debian-bookworm-DI-rc4-amd64-netinst.iso     " \ #
		"/mnt/hgfs/workspace/Image/linux/fedora/Fedora-Server-netinst-x86_64-37-1.7.iso         ./${WORK_DIRS}/iso/net/Fedora-Server-netinst-x86_64-37-1.7.iso      " \
		"/mnt/hgfs/workspace/Image/linux/fedora/Fedora-Server-netinst-x86_64-38-1.6.iso         ./${WORK_DIRS}/iso/net/Fedora-Server-netinst-x86_64-38-1.6.iso      " \
		"/mnt/hgfs/workspace/Image/linux/centos/CentOS-Stream-8-x86_64-latest-boot.iso          ./${WORK_DIRS}/iso/net/CentOS-Stream-8-x86_64-latest-boot.iso       " \
		"/mnt/hgfs/workspace/Image/linux/centos/CentOS-Stream-9-latest-x86_64-boot.iso          ./${WORK_DIRS}/iso/net/CentOS-Stream-9-latest-x86_64-boot.iso       " \
		"/mnt/hgfs/workspace/Image/linux/almalinux/AlmaLinux-9-latest-x86_64-boot.iso           ./${WORK_DIRS}/iso/net/AlmaLinux-9-latest-x86_64-boot.iso           " \
		"/mnt/hgfs/workspace/Image/linux/Rocky/Rocky-8.8-x86_64-boot.iso                        ./${WORK_DIRS}/iso/net/Rocky-8.8-x86_64-boot.iso                    " \
		"/mnt/hgfs/workspace/Image/linux/Rocky/Rocky-9-latest-x86_64-boot.iso                   ./${WORK_DIRS}/iso/net/Rocky-9-latest-x86_64-boot.iso               " \
		"/mnt/hgfs/workspace/Image/linux/miraclelinux/MIRACLELINUX-8.8-rtm-minimal-x86_64.iso   ./${WORK_DIRS}/iso/net/MIRACLELINUX-8.8-rtm-minimal-x86_64.iso      " \
		"/mnt/hgfs/workspace/Image/linux/miraclelinux/MIRACLELINUX-9.2-rtm-minimal-x86_64.iso   ./${WORK_DIRS}/iso/net/MIRACLELINUX-9.2-rtm-minimal-x86_64.iso      " \
		"/mnt/hgfs/workspace/Image/linux/openSUSE/openSUSE-Leap-15.5-NET-x86_64-Media.iso       ./${WORK_DIRS}/iso/net/openSUSE-Leap-15.5-NET-x86_64-Media.iso      " \
		"/mnt/hgfs/workspace/Image/linux/openSUSE/openSUSE-Leap-15.6-NET-x86_64-Media.iso       ./${WORK_DIRS}/iso/net/openSUSE-Leap-15.6-NET-x86_64-Media.iso      " \
		"/mnt/hgfs/workspace/Image/linux/openSUSE/openSUSE-Tumbleweed-NET-x86_64-Current.iso    ./${WORK_DIRS}/iso/net/openSUSE-Tumbleweed-NET-x86_64-Current.iso   " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-10.13.0-amd64-DVD-1.iso                  ./${WORK_DIRS}/iso/dvd/debian-10.13.0-amd64-DVD-1.iso               " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-11.8.0-amd64-DVD-1.iso                   ./${WORK_DIRS}/iso/dvd/debian-11.8.0-amd64-DVD-1.iso                " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-12.2.0-amd64-DVD-1.iso                   ./${WORK_DIRS}/iso/dvd/debian-12.2.0-amd64-DVD-1.iso                " \
#		"/mnt/hgfs/workspace/Image/linux/debian/debian-testing-amd64-DVD-1.iso                  ./${WORK_DIRS}/iso/dvd/debian-13.0.0-amd64-DVD-1.iso                " \ #
		"/mnt/hgfs/workspace/Image/linux/debian/debian-testing-amd64-DVD-1.iso                  ./${WORK_DIRS}/iso/dvd/debian-testing-amd64-DVD-1.iso               " \
#		"/mnt/hgfs/workspace/Image/linux/debian/debian-bookworm-DI-rc4-amd64-DVD-1.iso          ./${WORK_DIRS}/iso/dvd/debian-bookworm-DI-rc4-amd64-DVD-1.iso       " \ #
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-18.04.6-server-amd64.iso                 ./${WORK_DIRS}/iso/dvd/ubuntu-18.04.6-server-amd64.iso              " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-20.04.6-live-server-amd64.iso            ./${WORK_DIRS}/iso/dvd/ubuntu-20.04.6-live-server-amd64.iso         " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.04.3-live-server-amd64.iso            ./${WORK_DIRS}/iso/dvd/ubuntu-22.04.3-live-server-amd64.iso         " \
#		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.10-live-server-amd64.iso              ./${WORK_DIRS}/iso/dvd/ubuntu-22.10-live-server-amd64.iso           " \ #
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.04-live-server-amd64.iso              ./${WORK_DIRS}/iso/dvd/ubuntu-23.04-live-server-amd64.iso           " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.10-live-server-amd64.iso              ./${WORK_DIRS}/iso/dvd/ubuntu-23.10-live-server-amd64.iso           " \
#		"/mnt/hgfs/workspace/Image/linux/ubuntu/mantic-live-server-amd64.iso                    ./${WORK_DIRS}/iso/dvd/mantic-live-server-amd64.iso                 " \ #
		"/mnt/hgfs/workspace/Image/linux/fedora/Fedora-Server-dvd-x86_64-37-1.7.iso             ./${WORK_DIRS}/iso/dvd/Fedora-Server-dvd-x86_64-37-1.7.iso          " \
		"/mnt/hgfs/workspace/Image/linux/fedora/Fedora-Server-dvd-x86_64-38-1.6.iso             ./${WORK_DIRS}/iso/dvd/Fedora-Server-dvd-x86_64-38-1.6.iso          " \
		"/mnt/hgfs/workspace/Image/linux/centos/CentOS-Stream-8-x86_64-latest-dvd1.iso          ./${WORK_DIRS}/iso/dvd/CentOS-Stream-8-x86_64-latest-dvd1.iso       " \
		"/mnt/hgfs/workspace/Image/linux/centos/CentOS-Stream-9-latest-x86_64-dvd1.iso          ./${WORK_DIRS}/iso/dvd/CentOS-Stream-9-latest-x86_64-dvd1.iso       " \
		"/mnt/hgfs/workspace/Image/linux/almalinux/AlmaLinux-9-latest-x86_64-dvd.iso            ./${WORK_DIRS}/iso/dvd/AlmaLinux-9-latest-x86_64-dvd.iso            " \
		"/mnt/hgfs/workspace/Image/linux/Rocky/Rocky-8.8-x86_64-dvd1.iso                        ./${WORK_DIRS}/iso/dvd/Rocky-8.8-x86_64-dvd1.iso                    " \
		"/mnt/hgfs/workspace/Image/linux/miraclelinux/MIRACLELINUX-8.8-rtm-x86_64.iso           ./${WORK_DIRS}/iso/dvd/MIRACLELINUX-8.8-rtm-x86_64.iso              " \
		"/mnt/hgfs/workspace/Image/linux/miraclelinux/MIRACLELINUX-9.2-rtm-x86_64.iso           ./${WORK_DIRS}/iso/dvd/MIRACLELINUX-9.2-rtm-x86_64.iso              " \
		"/mnt/hgfs/workspace/Image/linux/openSUSE/openSUSE-Leap-15.5-DVD-x86_64-Media.iso       ./${WORK_DIRS}/iso/dvd/openSUSE-Leap-15.5-DVD-x86_64-Media.iso      " \
		"/mnt/hgfs/workspace/Image/linux/openSUSE/openSUSE-Leap-15.6-DVD-x86_64-Media.iso       ./${WORK_DIRS}/iso/dvd/openSUSE-Leap-15.6-DVD-x86_64-Media.iso      " \
		"/mnt/hgfs/workspace/Image/linux/openSUSE/openSUSE-Tumbleweed-DVD-x86_64-Current.iso    ./${WORK_DIRS}/iso/dvd/openSUSE-Tumbleweed-DVD-x86_64-Current.iso   " \
		"/mnt/hgfs/workspace/Image/linux/Rocky/Rocky-9-latest-x86_64-dvd.iso                    ./${WORK_DIRS}/iso/dvd/Rocky-9-latest-x86_64-dvd.iso                " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-live-10.13.0-amd64-lxde.iso              ./${WORK_DIRS}/iso/dvd/debian-live-10.13.0-amd64-lxde.iso           " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-live-11.8.0-amd64-lxde.iso               ./${WORK_DIRS}/iso/dvd/debian-live-11.8.0-amd64-lxde.iso            " \
		"/mnt/hgfs/workspace/Image/linux/debian/debian-live-12.2.0-amd64-lxde.iso               ./${WORK_DIRS}/iso/dvd/debian-live-12.2.0-amd64-lxde.iso            " \
#		"/mnt/hgfs/workspace/Image/linux/debian/debian-live-testing-amd64-lxde.iso              ./${WORK_DIRS}/iso/dvd/debian-live-13.0.0-amd64-lxde.iso            " \ #
		"/mnt/hgfs/workspace/Image/linux/debian/debian-live-testing-amd64-lxde.iso              ./${WORK_DIRS}/iso/dvd/debian-live-testing-amd64-lxde.iso           " \
#		"/mnt/hgfs/workspace/Image/linux/debian/debian-live-bkworm-DI-rc4-amd64-lxde.iso        ./${WORK_DIRS}/iso/dvd/debian-live-bkworm-DI-rc4-amd64-lxde.iso     " \ #
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-18.04.6-desktop-amd64.iso                ./${WORK_DIRS}/iso/dvd/ubuntu-18.04.6-desktop-amd64.iso             " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-20.04.6-desktop-amd64.iso                ./${WORK_DIRS}/iso/dvd/ubuntu-20.04.6-desktop-amd64.iso             " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.04.3-desktop-amd64.iso                ./${WORK_DIRS}/iso/dvd/ubuntu-22.04.3-desktop-amd64.iso             " \
#		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-22.10-desktop-amd64.iso                  ./${WORK_DIRS}/iso/dvd/ubuntu-22.10-desktop-amd64.iso               " \ #
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.04-desktop-amd64.iso                  ./${WORK_DIRS}/iso/dvd/ubuntu-23.04-desktop-amd64.iso               " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.04-desktop-legacy-amd64.iso           ./${WORK_DIRS}/iso/dvd/ubuntu-23.04-desktop-legacy-amd64.iso        " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.10.1-desktop-amd64.iso                ./${WORK_DIRS}/iso/dvd/ubuntu-23.10.1-desktop-amd64.iso             " \
		"/mnt/hgfs/workspace/Image/linux/ubuntu/ubuntu-23.10-desktop-legacy-amd64.iso           ./${WORK_DIRS}/iso/dvd/ubuntu-23.10-desktop-legacy-amd64.iso        " \
#		"/mnt/hgfs/workspace/Image/linux/ubuntu/mantic-desktop-amd64.iso                        ./${WORK_DIRS}/iso/dvd/mantic-desktop-amd64.iso                     " \ #
#		"/mnt/hgfs/workspace/Image/linux/ubuntu/mantic-desktop-legacy-amd64.iso                 ./${WORK_DIRS}/iso/dvd/mantic-desktop-legacy-amd64.iso              " \ #
	)

# --- CPU architecture --------------------------------------------------------
#	declare -r ARC_TYPE=i386				# 32bit
	declare -r ARC_TYPE=amd64				# 64bit

# --- grub.cfg / menu.cfg file name -------------------------------------------
	declare -r FNAME_GRUB="./${WORK_DIRS}/img/grub.cfg"
	declare -r FNAME_MENU="./${WORK_DIRS}/img/menu.cfg"

# --- menu.cfg list array -----------------------------------------------------
	declare -r -a MENU_LIST=(                               \
		"[ Unattended installation ]"                       \
		"- [ mini.iso ... ]"                                \
		"mini-testing-${ARC_TYPE}.iso"                      \
		"mini-trixie-${ARC_TYPE}.iso"                       \
		"mini-bookworm-${ARC_TYPE}.iso"                     \
		"mini-bullseye-${ARC_TYPE}.iso"                     \
		"mini-buster-${ARC_TYPE}.iso"                       \
		"mini-focal-${ARC_TYPE}.iso"                        \
		"mini-bionic-${ARC_TYPE}.iso"                       \
		"[]"                                                \
		"- [ net install ... ]"                             \
		"debian-testing-${ARC_TYPE}-netinst.iso"            \
		"debian-13.*-${ARC_TYPE}-netinst.iso"               \
		"debian-12.*-${ARC_TYPE}-netinst.iso"               \
		"debian-11.*-${ARC_TYPE}-netinst.iso"               \
		"debian-10.*-${ARC_TYPE}-netinst.iso"               \
		"Fedora-Server-netinst-x86_64-38-*.iso"             \
		"Fedora-Server-netinst-x86_64-37-*.iso"             \
		"CentOS-Stream-9-latest-x86_64-boot.iso"            \
		"CentOS-Stream-8-x86_64-latest-boot.iso"            \
		"AlmaLinux-9-latest-x86_64-boot.iso"                \
		"MIRACLELINUX-9.*-rtm-minimal-x86_64.iso"           \
		"MIRACLELINUX-8.*-rtm-minimal-x86_64.iso"           \
		"Rocky-9-latest-x86_64-boot.iso"                    \
		"Rocky-8.*-x86_64-boot.iso"                         \
		"openSUSE-Tumbleweed-NET-x86_64-Current.iso"        \
		"openSUSE-Leap-15.*-NET-x86_64-Media.iso"           \
		"[]"                                                \
		"- [ dvd media: server install ... ]"               \
		"debian-testing-${ARC_TYPE}-DVD-1.iso"              \
		"debian-13.*-${ARC_TYPE}-DVD-1.iso"                 \
		"debian-12.*-${ARC_TYPE}-DVD-1.iso"                 \
		"debian-11.*-${ARC_TYPE}-DVD-1.iso"                 \
		"debian-10.*-${ARC_TYPE}-DVD-1.iso"                 \
#		"mantic-live-server-${ARC_TYPE}.iso"                \ #
		"ubuntu-23.10*-live-server-${ARC_TYPE}.iso"         \
		"ubuntu-23.04*-live-server-${ARC_TYPE}.iso"         \
		"ubuntu-22.10*-live-server-${ARC_TYPE}.iso"         \
		"ubuntu-22.04*-live-server-${ARC_TYPE}.iso"         \
		"ubuntu-20.04*-live-server-${ARC_TYPE}.iso"         \
		"ubuntu-18.04*-server-${ARC_TYPE}.iso"              \
		"Fedora-Server-dvd-x86_64-38-*.iso"                 \
		"Fedora-Server-dvd-x86_64-37-*.iso"                 \
		"CentOS-Stream-9-latest-x86_64-dvd1.iso"            \
		"CentOS-Stream-8-x86_64-latest-dvd1.iso"            \
		"AlmaLinux-9-latest-x86_64-dvd.iso"                 \
		"MIRACLELINUX-9.*-rtm-x86_64.iso"                   \
		"MIRACLELINUX-8.*-rtm-x86_64.iso"                   \
		"Rocky-9-latest-x86_64-dvd.iso"                     \
		"Rocky-8.*-x86_64-dvd1.iso"                         \
		"openSUSE-Tumbleweed-DVD-x86_64-Current.iso"        \
		"openSUSE-Leap-15.*-DVD-x86_64-Media.iso"           \
		"[]"                                                \
		"- [ dvd media: desktop install / live ... ]"       \
		"debian-live-testing-${ARC_TYPE}-lxde.iso"          \
		"debian-live-13.*-${ARC_TYPE}-lxde.iso"             \
		"debian-live-12.*-${ARC_TYPE}-lxde.iso"             \
		"debian-live-11.*-${ARC_TYPE}-lxde.iso"             \
		"debian-live-10.*-${ARC_TYPE}-lxde.iso"             \
#		"mantic-desktop-${ARC_TYPE}.iso"                    \ #
		"ubuntu-23.10*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-23.04*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-22.10*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-22.04*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-20.04*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-18.04*-desktop-${ARC_TYPE}.iso"             \
#		"mantic-desktop-legacy-${ARC_TYPE}.iso"             \ #
		"ubuntu-23.10*-desktop-legacy-${ARC_TYPE}.iso"      \
		"ubuntu-23.04*-desktop-legacy-${ARC_TYPE}.iso"      \
		"[]"                                                \
		"[ Live system ]"                                   \
		"- [ Live media ... ]"                              \
		"debian-live-testing-${ARC_TYPE}-lxde.iso"          \
		"debian-live-13.*-${ARC_TYPE}-lxde.iso"             \
		"debian-live-12.*-${ARC_TYPE}-lxde.iso"             \
		"debian-live-11.*-${ARC_TYPE}-lxde.iso"             \
		"debian-live-10.*-${ARC_TYPE}-lxde.iso"             \
#		"mantic-desktop-${ARC_TYPE}.iso"                    \ #
		"ubuntu-23.10*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-23.04*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-22.10*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-22.04*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-20.04*-desktop-${ARC_TYPE}.iso"             \
		"ubuntu-18.04*-desktop-${ARC_TYPE}.iso"             \
#		"mantic-desktop-legacy-${ARC_TYPE}.iso"             \ #
		"ubuntu-23.10*-desktop-legacy-${ARC_TYPE}.iso"      \
		"ubuntu-23.04*-desktop-legacy-${ARC_TYPE}.iso"      \
		"[]"                                                \
	)

# --- web address -------------------------------------------------------------
	declare -r WEB_DEBIAN="https://deb.debian.org/debian"
	declare -r WEB_UBUNTU="http://archive.ubuntu.com/ubuntu"

# --- target list array -------------------------------------------------------
	declare -a TARGET_LIST=()

	#idx:value
	#  0:distribution
	#  1:codename
	#  2:download URL
	#  3:directory
	#  4:alias
	#  5:iso file size
	#  6:iso file date
	#  7:definition file
	#  8:release
	#  9:support
	# 10:status
	# 11:memo1
	# 12:memo2

	# --- mini,iso ------------------------------------------------------------
	declare -r -a TARGET_LIST_MINI=(                                                                                                                                                                                                                                                                                                                                                                                                                              \
#		"debian             buster              https://deb.debian.org/debian/dists/buster/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                       ./${WORK_DIRS}/iso/mini                     mini-buster-${ARC_TYPE}.iso                 -                   -           preseed_debian.cfg                              2019-07-06  2024-06-xx  -           oldoldstable        Debian_10.xx(buster)                " \ #
#		"debian             bullseye            https://deb.debian.org/debian/dists/bullseye/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                     ./${WORK_DIRS}/iso/mini                     mini-bullseye-${ARC_TYPE}.iso               -                   -           preseed_debian.cfg                              2021-08-14  2026-xx-xx  -           oldstable           Debian_11.xx(bullseye)              " \ #
#		"debian             bookworm            https://deb.debian.org/debian/dists/bookworm/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                     ./${WORK_DIRS}/iso/mini                     mini-bookworm-${ARC_TYPE}.iso               -                   -           preseed_debian.cfg                              2023-06-10  20xx-xx-xx  -           stable              Debian_12.xx(bookworm)              " \ #
#		"debian             trixie              https://deb.debian.org/debian/dists/trixie/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                       ./${WORK_DIRS}/iso/mini                     mini-trixie-${ARC_TYPE}.iso                 -                   -           preseed_debian.cfg                              202x-xx-xx  20xx-xx-xx  -           testing             Debian_13.xx(trixie)                " \ #
#		"debian             testing             https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/netboot/mini.iso                                                                      ./${WORK_DIRS}/iso/mini                     mini-testing-${ARC_TYPE}.iso                -                   -           preseed_debian.cfg                              202x-xx-xx  20xx-xx-xx  -           testing             Debian_xx.xx(testing)               " \ #
#		"ubuntu             bionic              http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                            ./${WORK_DIRS}/iso/mini                     mini-bionic-${ARC_TYPE}.iso                 -                   -           preseed_ubuntu.cfg                              2018-04-26  2028-04-26  -           bionic              Ubuntu_18.04(Bionic_Beaver):LTS     " \ #
#		"ubuntu             focal               http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-${ARC_TYPE}/current/legacy-images/netboot/mini.iso                      ./${WORK_DIRS}/iso/mini                     mini-focal-${ARC_TYPE}.iso                  -                   -           preseed_ubuntu.cfg                              2020-04-23  2030-04-23  -           focal               Ubuntu_20.04(Focal_Fossa):LTS       " \ #
	)	#0:distribution     1:codename          2:download URL                                                                                                                              3:directory                                 4:alias                                     5:iso file size     6:file date 7:definition file                               8:release   9:support   10:status   11:memo1            12:memo2                            

	# --- netinst -------------------------------------------------------------
	declare -r -a TARGET_LIST_NET=(                                                                                                                                                                                                                                                                                                                                                                                                                               \
		"debian             buster              https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/${ARC_TYPE}/iso-cd/debian-10.[0-9.]*-${ARC_TYPE}-netinst.iso                 ./${WORK_DIRS}/iso/net                      -                                           -                   -           preseed_debian.cfg                              2019-07-06  2024-06-xx  -           oldoldstable        Debian_10.xx(buster)                " \
		"debian             bullseye            https://cdimage.debian.org/cdimage/archive/latest-oldstable/${ARC_TYPE}/iso-cd/debian-11.[0-9.]*-${ARC_TYPE}-netinst.iso                    ./${WORK_DIRS}/iso/net                      -                                           -                   -           preseed_debian.cfg                              2021-08-14  2026-xx-xx  -           oldstable           Debian_11.xx(bullseye)              " \
		"debian             bookworm            https://cdimage.debian.org/cdimage/release/current/${ARC_TYPE}/iso-cd/debian-12.[0-9.]*-${ARC_TYPE}-netinst.iso                             ./${WORK_DIRS}/iso/net                      -                                           -                   -           preseed_debian.cfg                              2023-06-10  20xx-xx-xx  -           stable              Debian_12.xx(bookworm)              " \
#		"debian             trixie              -                                                                                                                                           ./${WORK_DIRS}/iso/net                      -                                           -                   -           preseed_debian.cfg                              202x-xx-xx  20xx-xx-xx  -           testing             Debian_13.xx(trixie)                " \ #
		"debian             testing             https://cdimage.debian.org/cdimage/daily-builds/daily/current/${ARC_TYPE}/iso-cd/debian-testing-${ARC_TYPE}-netinst.iso                     ./${WORK_DIRS}/iso/net                      -                                           -                   -           preseed_debian.cfg                              20xx-xx-xx  20xx-xx-xx  -           testing             Debian_xx.xx(testing)               " \
		"fedora             -                   https://download.fedoraproject.org/pub/fedora/linux/releases/37/Server/x86_64/iso/Fedora-Server-netinst-x86_64-37-[0-9.]*.iso               ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            2022-11-15  2023-11-14  -           kernel_6.0          -                                   " \
		"fedora             -                   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-netinst-x86_64-38-[0-9.]*.iso               ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            2023-04-18  2024-05-14  -           kernel_6.2          -                                   " \
#		"centos             -                   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-boot.iso                                          ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            20xx-xx-xx  2024-05-31  -           RHEL_8.x            -                                   " \ 
		"centos             -                   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                             ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            2021-xx-xx  20xx-xx-xx  -           RHEL_9.x            -                                   " \
		"almalinux          -                   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9[0-9.]*-latest-x86_64-boot.iso                                                ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            2022-05-26  20xx-xx-xx  -           RHEL_9.x            -                                   " \
#		"rockylinux         -                   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-boot.iso                                                      ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            2022-11-14  20xx-xx-xx  -           RHEL_8.x            -                                   " \ #
		"rockylinux         -                   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9[0-9.]*-latest-x86_64-boot.iso                                               ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            2022-07-14  20xx-xx-xx  -           RHEL_9.x            -                                   " \
#		"miraclelinux       -                   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-minimal-x86_64.iso                ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            2021-10-04  20xx-xx-xx  -           RHEL_x.x            -                                   " \ #
		"miraclelinux       -                   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-minimal-x86_64.iso                ./${WORK_DIRS}/iso/net                      -                                           -                   -           kickstart_common.cfg                            2021-10-04  20xx-xx-xx  -           RHEL_x.x            -                                   " \
		"opensuse           leap                https://ftp.riken.jp/Linux/opensuse/distribution/openSUSE-stable/iso/openSUSE-Leap-[0-9.]*-NET-x86_64-Media.iso                             ./${WORK_DIRS}/iso/net                      -                                           -                   -           yast_opensuse.xml                               2023-06-07  2024-12-31  -           kernel_5.14.21      -                                   " \
		"opensuse           leap                https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Media.iso                                      ./${WORK_DIRS}/iso/net                      -                                           -                   -           yast_opensuse.xml                               2024-06-xx  2025-xx-xx  -           kernel_x.xx.xx      -                                   " \
		"opensuse           tumbleweed          https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                               ./${WORK_DIRS}/iso/net                      -                                           -                   -           yast_opensuse.xml                               20xx-xx-xx  20xx-xx-xx  -           kernel_x.x          -                                   " \
	)	#0:distribution     1:codename          2:download URL                                                                                                                              3:directory                                 4:alias                                     5:iso file size     6:file date 7:definition file                               8:release   9:support   10:status   11:memo1            12:memo2                            

	# --- dvd media -----------------------------------------------------------
	declare -r -a TARGET_LIST_DVD=(                                                                                                                                                                                                                                                                                                                                                                                                                               \
#		"debian             buster              https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/${ARC_TYPE}/iso-dvd/debian-10.[0-9.]*-${ARC_TYPE}-DVD-1.iso                  ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              2019-07-06  2024-06-xx  -           oldoldstable        Debian_10.xx(buster)                " \ #
#		"debian             bullseye            https://cdimage.debian.org/cdimage/archive/latest-oldstable/${ARC_TYPE}/iso-dvd/debian-11.[0-9.]*-${ARC_TYPE}-DVD-1.iso                     ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              2021-08-14  2026-xx-xx  -           oldstable           Debian_11.xx(bullseye)              " \ #
		"debian             bookworm            https://cdimage.debian.org/cdimage/release/current/${ARC_TYPE}/iso-dvd/debian-12.[0-9.]*-${ARC_TYPE}-DVD-1.iso                              ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              2023-06-10  20xx-xx-xx  -           stable              Debian_12.xx(bookworm)              " \
#		"debian             trixie              -                                                                                                                                           ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              202x-xx-xx  20xx-xx-xx  -           testing             Debian_13.xx(trixie)                " \ #
		"debian             testing             https://cdimage.debian.org/cdimage/weekly-builds/${ARC_TYPE}/iso-dvd/debian-testing-${ARC_TYPE}-DVD-1.iso                                   ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              20xx-xx-xx  20xx-xx-xx  -           testing             Debian_xx.xx(testing)               " \
#		"ubuntu             bionic              https://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04[0-9.]*-server-${ARC_TYPE}.iso                                               ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg                              2018-04-26  2028-04-26  -           Bionic_Beaver       Ubuntu_18.04(Bionic_Beaver):LTS     " \ #
		"ubuntu             focal.server        https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-live-server-${ARC_TYPE}.iso                                                           ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2020-04-23  2030-04-23  -           Focal_Fossa         Ubuntu_20.04(Focal_Fossa):LTS       " \
		"ubuntu             jammy.server        https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-live-server-${ARC_TYPE}.iso                                                           ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2022-04-21  2032-04-21  -           Jammy_Jellyfish     Ubuntu_22.04(Jammy_Jellyfish):LTS   " \
# x		"ubuntu             kinetic.server      https://releases.ubuntu.com/kinetic/ubuntu-22.10[0-9.]*-live-server-${ARC_TYPE}.iso                                                         ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2022-10-20  2023-07-20  -           Kinetic_Kudu        Ubuntu_22.10(Kinetic_Kudu)          " \ #
		"ubuntu             lunar.server        https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-live-server-${ARC_TYPE}.iso                                                           ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2023-04-20  2024-01-20  -           Lunar_Lobster       Ubuntu_23.04(Lunar_Lobster)         " \
		"ubuntu             mantic.server       https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-live-server-${ARC_TYPE}.iso                                                          ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2023-10-12  20xx-xx-xx  -           Mantic_Minotaur     Ubuntu_23.10(Mantic_Minotaur)       " \
#		"fedora             -                   https://download.fedoraproject.org/pub/fedora/linux/releases/37/Server/x86_64/iso/Fedora-Server-dvd-x86_64-37-[0-9.]*.iso                   ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2022-11-15  2023-11-14  -           kernel_6.0          -                                   " \ #
		"fedora             -                   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-dvd-x86_64-38-[0-9.]*.iso                   ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2023-04-18  2024-05-14  -           kernel_6.2          -                                   " \
#		"centos             -                   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-dvd1.iso                                          ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2019-xx-xx  2024-05-31  -           RHEL_8.x            -                                   " \ #
		"centos             -                   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                             ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2021-xx-xx  20xx-xx-xx  -           RHEL_9.x            -                                   " \
		"almalinux          -                   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9[0-9.]*-latest-x86_64-dvd.iso                                                 ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2022-05-26  20xx-xx-xx  -           RHEL_9.x            -                                   " \
#		"rockylinux         -                   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-dvd1.iso                                                      ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2022-11-14  20xx-xx-xx  -           RHEL_8.x            -                                   " \ #
		"rockylinux         -                   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9[0-9.]*-latest-x86_64-dvd.iso                                                ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2022-07-14  20xx-xx-xx  -           RHEL_9.x            -                                   " \
#		"miraclelinux       -                   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-x86_64.iso                        ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2021-10-04  20xx-xx-xx  -           RHEL_x.x            -                                   " \ #
		"miraclelinux       -                   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso                        ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           kickstart_common.cfg                            2021-10-04  20xx-xx-xx  -           RHEL_x.x            -                                   " \
		"opensuse           leap                https://ftp.riken.jp/Linux/opensuse/distribution/openSUSE-stable/iso/openSUSE-Leap-[0-9.]*-DVD-x86_64-Media.iso                             ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           yast_opensuse.xml                               2023-06-07  2024-12-31  -           kernel_5.14.21      -                                   " \
		"opensuse           leap                https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso                                      ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           yast_opensuse.xml                               2024-06-xx  2025-xx-xx  -           kernel_x.xx.xx      -                                   " \
		"opensuse           tumbleweed          https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                               ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           yast_opensuse.xml                               2021-xx-xx  20xx-xx-xx  -           kernel_x.x          -                                   " \
#		"debian             buster.live         https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/${ARC_TYPE}/iso-hybrid/debian-live-10.[0-9.]*-${ARC_TYPE}-lxde.iso      ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              2019-07-06  2024-06-xx  -           oldoldstable        Debian_10.xx(buster)                " \ #
#		"debian             bullseye.live       https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/${ARC_TYPE}/iso-hybrid/debian-live-11.[0-9.]*-${ARC_TYPE}-lxde.iso         ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              2021-08-14  2026-xx-xx  -           oldstable           Debian_11.xx(bullseye)              " \ #
		"debian             bookworm.live       https://cdimage.debian.org/cdimage/release/current-live/${ARC_TYPE}/iso-hybrid/debian-live-12.[0-9.]*-${ARC_TYPE}-lxde.iso                  ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              2023-06-10  20xx-xx-xx  -           stable              Debian_12.xx(bookworm)              " \
#		"debian             trixie.live         -                                                                                                                                           ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              202x-xx-xx  20xx-xx-xx  -           testing             Debian_13.xx(trixie)                " \ #
		"debian             testing.live        https://cdimage.debian.org/cdimage/weekly-live-builds/${ARC_TYPE}/iso-hybrid/debian-live-testing-${ARC_TYPE}-lxde.iso                       ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              20xx-xx-xx  20xx-xx-xx  -           testing             Debian_xx.xx(testing)               " \
#		"ubuntu             bionic.desktop      https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-desktop-${ARC_TYPE}.iso                                                              ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg                              2018-04-26  2028-04-26  -           Bionic_Beaver       Ubuntu_18.04(Bionic_Beaver):LTS     " \ #
#		"ubuntu             focal.desktop       https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-desktop-${ARC_TYPE}.iso                                                               ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg                              2020-04-23  2030-04-23  -           Focal_Fossa         Ubuntu_20.04(Focal_Fossa):LTS       " \ #
#		"ubuntu             jammy.desktop       https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-desktop-${ARC_TYPE}.iso                                                               ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg                              2022-04-21  2032-04-21  -           Jammy_Jellyfish     Ubuntu_22.04(Jammy_Jellyfish):LTS   " \ #
# x		"ubuntu             kinetic.desktop     https://releases.ubuntu.com/kinetic/ubuntu-22.10[0-9.]*-desktop-${ARC_TYPE}.iso                                                             ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg                              2022-10-20  2023-07-20  -           Kinetic_Kudu        Ubuntu_22.10(Kinetic_Kudu)          " \ #
		"ubuntu             lunar.desktop       https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-desktop-${ARC_TYPE}.iso                                                               ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2023-04-20  2024-01-20  -           Lunar_Lobster       Ubuntu_23.04(Lunar_Lobster)         " \
		"ubuntu             lunar.legacy        http://cdimage.ubuntu.com/releases/lunar/release/ubuntu-23.04[0-9.]*-desktop-legacy-${ARC_TYPE}.iso                                         ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg                              2023-04-20  2024-01-20  -           Lunar_Lobster       Ubuntu_23.04(Lunar_Lobster)         " \
		"ubuntu             mantic.desktop      https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-desktop-${ARC_TYPE}.iso                                                              ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2023-10-12  20xx-xx-xx  -           Mantic_Minotaur     Ubuntu_23.10(Mantic_Minotaur)       " \
		"ubuntu             mantic.legacy       https://cdimage.ubuntu.com/releases/mantic/release/ubuntu-23.10[0-9.]*-desktop-legacy-${ARC_TYPE}.iso                                       ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg                              2023-10-12  20xx-xx-xx  -           Mantic_Minotaur     Ubuntu_23.10(Mantic_Minotaur)       " \
#		"ubuntu             mantic.server       http://cdimage.ubuntu.com/ubuntu-server/daily-live/current/mantic-live-server-${ARC_TYPE}.iso                                               ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2023-10-12  20xx-xx-xx  -           Mantic_Minotaur     Ubuntu_23.10(Mantic_Minotaur)       " \ #
#		"ubuntu             mantic.desktop      http://cdimage.ubuntu.com/daily-live/current/mantic-desktop-${ARC_TYPE}.iso                                                                 ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg,nocloud-ubuntu-user-data     2023-10-12  20xx-xx-xx  -           Mantic_Minotaur     Ubuntu_23.10(Mantic_Minotaur)       " \ #
#		"ubuntu             mantic.legacy       http://cdimage.ubuntu.com/daily-legacy/current/mantic-desktop-legacy-${ARC_TYPE}.iso                                                        ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_ubuntu.cfg                              2023-10-12  20xx-xx-xx  -           Mantic_Minotaur     Ubuntu_23.10(Mantic_Minotaur)       " \ #
	)	#0:distribution     1:codename          2:download URL                                                                                                                              3:directory                                 4:alias                                     5:iso file size     6:file date 7:definition file                               8:release   9:support   10:status   11:memo1            12:memo2                            

	TARGET_LIST+=("${TARGET_LIST_MINI[@]}")
	TARGET_LIST+=("${TARGET_LIST_NET[@]}")
	TARGET_LIST+=("${TARGET_LIST_DVD[@]}")

#	TARGET_LIST=(
#		"debian             testing             https://cdimage.debian.org/cdimage/weekly-builds/${ARC_TYPE}/iso-dvd/debian-testing-${ARC_TYPE}-DVD-1.iso                                   ./${WORK_DIRS}/iso/dvd                      -                                           -                   -           preseed_debian.cfg                              20xx-xx-xx  20xx-xx-xx  -           testing             Debian_xx.xx(testing)               " \
#	)

# --- config file -------------------------------------------------------------
	#idx: value
	#  0: distribution
	#  1: codename
	#  2: download URL
	#  3: directory

	declare -r -a CONFIG_FILE=(                                                                                                                                                                                                                                                                                                                                                                                                                                   \
		"-                  -                   https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/preseed_debian.cfg                                              ./${WORK_DIRS}/cfg                                                                                                                                                                                                                                                  " \
		"-                  -                   https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/preseed_ubuntu.cfg                                              ./${WORK_DIRS}/cfg                                                                                                                                                                                                                                                  " \
		"-                  -                   https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/nocloud-ubuntu-user-data                                        ./${WORK_DIRS}/cfg                                                                                                                                                                                                                                                  " \
		"-                  -                   https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/kickstart_common.cfg                                            ./${WORK_DIRS}/cfg                                                                                                                                                                                                                                                  " \
		"-                  -                   https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/yast_opensuse.xml                                               ./${WORK_DIRS}/cfg                                                                                                                                                                                                                                                  " \
	)	#0:distribution     1:codename          2:download URL                                                                                                                              3:directory                                 4:alias                                     5:iso file size     6:file date 7:definition file                               8:release   9:support   10:status   11:memo1            12:memo2                            

# --- debian installer --------------------------------------------------------
	#idx: value
	#  0: distribution
	#  1: codename
	#  2: download URL
	#  3: directory

	declare -r -a DEBIAN_INSTALLER=(                                                                                                                                                                                                                                                                                                                                                                                                                              \
		# --- stretch ---------------------------------------------------------
#		"debian             stretch             https://archive.debian.org/debian/dists/stretch/main/installer-${ARC_TYPE}/current/images/hd-media/boot.img.gz                              ./${WORK_DIRS}/cfg/debian.stretch                                                                                                                                                                                                                                   " \ #
#		"debian             stretch             https://archive.debian.org/debian/dists/stretch/main/installer-${ARC_TYPE}/current/images/hd-media/initrd.gz                                ./${WORK_DIRS}/cfg/debian.stretch                                                                                                                                                                                                                                   " \ #
#		"debian             stretch             https://archive.debian.org/debian/dists/stretch/main/installer-${ARC_TYPE}/current/images/hd-media/vmlinuz                                  ./${WORK_DIRS}/cfg/debian.stretch                                                                                                                                                                                                                                   " \ #
#		"debian             stretch             https://archive.debian.org/debian/dists/stretch/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/initrd.gz                            ./${WORK_DIRS}/cfg/debian.stretch/gtk                                                                                                                                                                                                                               " \ #
#		"debian             stretch             https://archive.debian.org/debian/dists/stretch/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/vmlinuz                              ./${WORK_DIRS}/cfg/debian.stretch/gtk                                                                                                                                                                                                                               " \ #
		# --- buster ----------------------------------------------------------
		"debian             buster              https://deb.debian.org/debian/dists/buster/main/installer-${ARC_TYPE}/current/images/hd-media/boot.img.gz                                   ./${WORK_DIRS}/cfg/debian.buster                                                                                                                                                                                                                                    " \
		"debian             buster              https://deb.debian.org/debian/dists/buster/main/installer-${ARC_TYPE}/current/images/hd-media/initrd.gz                                     ./${WORK_DIRS}/cfg/debian.buster                                                                                                                                                                                                                                    " \
		"debian             buster              https://deb.debian.org/debian/dists/buster/main/installer-${ARC_TYPE}/current/images/hd-media/vmlinuz                                       ./${WORK_DIRS}/cfg/debian.buster                                                                                                                                                                                                                                    " \
		"debian             buster              https://deb.debian.org/debian/dists/buster/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/initrd.gz                                 ./${WORK_DIRS}/cfg/debian.buster/gtk                                                                                                                                                                                                                                " \
		"debian             buster              https://deb.debian.org/debian/dists/buster/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/vmlinuz                                   ./${WORK_DIRS}/cfg/debian.buster/gtk                                                                                                                                                                                                                                " \
		# --- bullseye --------------------------------------------------------
		"debian             bullseye            https://deb.debian.org/debian/dists/bullseye/main/installer-${ARC_TYPE}/current/images/hd-media/boot.img.gz                                 ./${WORK_DIRS}/cfg/debian.bullseye                                                                                                                                                                                                                                  " \
		"debian             bullseye            https://deb.debian.org/debian/dists/bullseye/main/installer-${ARC_TYPE}/current/images/hd-media/initrd.gz                                   ./${WORK_DIRS}/cfg/debian.bullseye                                                                                                                                                                                                                                  " \
		"debian             bullseye            https://deb.debian.org/debian/dists/bullseye/main/installer-${ARC_TYPE}/current/images/hd-media/vmlinuz                                     ./${WORK_DIRS}/cfg/debian.bullseye                                                                                                                                                                                                                                  " \
		"debian             bullseye            https://deb.debian.org/debian/dists/bullseye/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/initrd.gz                               ./${WORK_DIRS}/cfg/debian.bullseye/gtk                                                                                                                                                                                                                              " \
		"debian             bullseye            https://deb.debian.org/debian/dists/bullseye/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/vmlinuz                                 ./${WORK_DIRS}/cfg/debian.bullseye/gtk                                                                                                                                                                                                                              " \
		# --- bookworm --------------------------------------------------------
		"debian             bookworm            https://deb.debian.org/debian/dists/bookworm/main/installer-${ARC_TYPE}/current/images/hd-media/boot.img.gz                                 ./${WORK_DIRS}/cfg/debian.bookworm                                                                                                                                                                                                                                  " \
		"debian             bookworm            https://deb.debian.org/debian/dists/bookworm/main/installer-${ARC_TYPE}/current/images/hd-media/initrd.gz                                   ./${WORK_DIRS}/cfg/debian.bookworm                                                                                                                                                                                                                                  " \
		"debian             bookworm            https://deb.debian.org/debian/dists/bookworm/main/installer-${ARC_TYPE}/current/images/hd-media/vmlinuz                                     ./${WORK_DIRS}/cfg/debian.bookworm                                                                                                                                                                                                                                  " \
		"debian             bookworm            https://deb.debian.org/debian/dists/bookworm/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/initrd.gz                               ./${WORK_DIRS}/cfg/debian.bookworm/gtk                                                                                                                                                                                                                              " \
		"debian             bookworm            https://deb.debian.org/debian/dists/bookworm/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/vmlinuz                                 ./${WORK_DIRS}/cfg/debian.bookworm/gtk                                                                                                                                                                                                                              " \
		# --- trixie ----------------------------------------------------------
		"debian             trixie              https://deb.debian.org/debian/dists/trixie/main/installer-${ARC_TYPE}/current/images/hd-media/boot.img.gz                                   ./${WORK_DIRS}/cfg/debian.trixie                                                                                                                                                                                                                                    " \
		"debian             trixie              https://deb.debian.org/debian/dists/trixie/main/installer-${ARC_TYPE}/current/images/hd-media/initrd.gz                                     ./${WORK_DIRS}/cfg/debian.trixie                                                                                                                                                                                                                                    " \
		"debian             trixie              https://deb.debian.org/debian/dists/trixie/main/installer-${ARC_TYPE}/current/images/hd-media/vmlinuz                                       ./${WORK_DIRS}/cfg/debian.trixie                                                                                                                                                                                                                                    " \
		"debian             trixie              https://deb.debian.org/debian/dists/trixie/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/initrd.gz                                 ./${WORK_DIRS}/cfg/debian.trixie/gtk                                                                                                                                                                                                                                " \
		"debian             trixie              https://deb.debian.org/debian/dists/trixie/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/vmlinuz                                   ./${WORK_DIRS}/cfg/debian.trixie/gtk                                                                                                                                                                                                                                " \
		# --- testing ---------------------------------------------------------
		"debian             testing             https://deb.debian.org/debian/dists/testing/main/installer-${ARC_TYPE}/current/images/hd-media/boot.img.gz                                  ./${WORK_DIRS}/cfg/debian.testing                                                                                                                                                                                                                                   " \
		"debian             testing             https://deb.debian.org/debian/dists/testing/main/installer-${ARC_TYPE}/current/images/hd-media/initrd.gz                                    ./${WORK_DIRS}/cfg/debian.testing                                                                                                                                                                                                                                   " \
		"debian             testing             https://deb.debian.org/debian/dists/testing/main/installer-${ARC_TYPE}/current/images/hd-media/vmlinuz                                      ./${WORK_DIRS}/cfg/debian.testing                                                                                                                                                                                                                                   " \
		"debian             testing             https://deb.debian.org/debian/dists/testing/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/initrd.gz                                ./${WORK_DIRS}/cfg/debian.testing/gtk                                                                                                                                                                                                                               " \
		"debian             testing             https://deb.debian.org/debian/dists/testing/main/installer-${ARC_TYPE}/current/images/hd-media/gtk/vmlinuz                                  ./${WORK_DIRS}/cfg/debian.testing/gtk                                                                                                                                                                                                                               " \
		"debian             testing             https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/hd-media/boot.img.gz                                                                  ./${WORK_DIRS}/cfg/debian.testing.daily                                                                                                                                                                                                                             " \
		"debian             testing             https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/hd-media/initrd.gz                                                                    ./${WORK_DIRS}/cfg/debian.testing.daily                                                                                                                                                                                                                             " \
		"debian             testing             https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/hd-media/vmlinuz                                                                      ./${WORK_DIRS}/cfg/debian.testing.daily                                                                                                                                                                                                                             " \
		"debian             testing             https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/hd-media/gtk/initrd.gz                                                                ./${WORK_DIRS}/cfg/debian.testing.daily/gtk                                                                                                                                                                                                                         " \
		"debian             testing             https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/hd-media/gtk/vmlinuz                                                                  ./${WORK_DIRS}/cfg/debian.testing.daily/gtk                                                                                                                                                                                                                         " \
		# --- bionic ----------------------------------------------------------
#		"ubuntu             bionic              http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-${ARC_TYPE}/current/images/hd-media/boot.img.gz                                ./${WORK_DIRS}/cfg/ubuntu.bionic                                                                                                                                                                                                                                    " \ #
#		"ubuntu             bionic              http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-${ARC_TYPE}/current/images/hd-media/initrd.gz                                  ./${WORK_DIRS}/cfg/ubuntu.bionic                                                                                                                                                                                                                                    " \ #
#		"ubuntu             bionic              http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-${ARC_TYPE}/current/images/hd-media/vmlinuz                                    ./${WORK_DIRS}/cfg/ubuntu.bionic                                                                                                                                                                                                                                    " \ #
		"ubuntu             bionic              http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-${ARC_TYPE}/current/images/hd-media/boot.img.gz                        ./${WORK_DIRS}/cfg/ubuntu.bionic-updates                                                                                                                                                                                                                            " \
		"ubuntu             bionic              http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-${ARC_TYPE}/current/images/hd-media/initrd.gz                          ./${WORK_DIRS}/cfg/ubuntu.bionic-updates                                                                                                                                                                                                                            " \
		"ubuntu             bionic              http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-${ARC_TYPE}/current/images/hd-media/vmlinuz                            ./${WORK_DIRS}/cfg/ubuntu.bionic-updates                                                                                                                                                                                                                            " \
		# --- focal -----------------------------------------------------------
#		"ubuntu             focal               http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-${ARC_TYPE}/current/legacy-images/hd-media/boot.img.gz                          ./${WORK_DIRS}/cfg/ubuntu.focal                                                                                                                                                                                                                                     " \ #
#		"ubuntu             focal               http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-${ARC_TYPE}/current/legacy-images/hd-media/initrd.gz                            ./${WORK_DIRS}/cfg/ubuntu.focal                                                                                                                                                                                                                                     " \ #
#		"ubuntu             focal               http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-${ARC_TYPE}/current/legacy-images/hd-media/vmlinuz                              ./${WORK_DIRS}/cfg/ubuntu.focal                                                                                                                                                                                                                                     " \ #
#		"ubuntu             focal               http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-${ARC_TYPE}/current/legacy-images/hd-media/boot.img.gz                  ./${WORK_DIRS}/cfg/ubuntu.focal-updates                                                                                                                                                                                                                             " \ #
#		"ubuntu             focal               http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-${ARC_TYPE}/current/legacy-images/hd-media/initrd.gz                    ./${WORK_DIRS}/cfg/ubuntu.focal-updates                                                                                                                                                                                                                             " \ #
#		"ubuntu             focal               http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-${ARC_TYPE}/current/legacy-images/hd-media/vmlinuz                      ./${WORK_DIRS}/cfg/ubuntu.focal-updates                                                                                                                                                                                                                             " \ #
	)	#0:distribution     1:codename          2:download URL                                                                                                                              3:directory                                 4:alias                                     5:iso file size     6:file date 7:definition file                               8:release   9:support   10:status   11:memo1            12:memo2                            

# --- linux image module ------------------------------------------------------
	#idx: value
	#  0: distribution
	#  1: codename
	#  2: download URL
	#  3: directory

	declare -r -a LINUX_IMAGE=(                                                                                                                                                                                                                                                                                                                                                                                                                                   \
		"debian             buster              https://deb.debian.org/debian/pool/main/l/linux-signed-${ARC_TYPE}/linux-image-4.19.0-21-${ARC_TYPE}_4.19.249-2_${ARC_TYPE}.deb             ./${WORK_DIRS}/deb/debian.buster                                                                                                                                                                                                                                    " \
		"debian             bullseye            https://deb.debian.org/debian/pool/main/l/linux-signed-${ARC_TYPE}/linux-image-5.10.0-22-${ARC_TYPE}_5.10.178-3_${ARC_TYPE}.deb             ./${WORK_DIRS}/deb/debian.bullseye                                                                                                                                                                                                                                  " \
		"debian             bookworm            https://deb.debian.org/debian/pool/main/l/linux-signed-${ARC_TYPE}/linux-image-6.1.0-9-${ARC_TYPE}_6.1.27-1_${ARC_TYPE}.deb                 ./${WORK_DIRS}/deb/debian.bookworm                                                                                                                                                                                                                                  " \
		"debian             testing             https://deb.debian.org/debian/pool/main/l/linux-signed-${ARC_TYPE}/linux-image-6.1.0-9-${ARC_TYPE}_6.1.27-1_${ARC_TYPE}.deb                 ./${WORK_DIRS}/deb/debian.testing                                                                                                                                                                                                                                   " \
#		"debian             testing             https://deb.debian.org/debian/pool/main/l/linux-signed-${ARC_TYPE}/linux-image-6.3.0-1-${ARC_TYPE}_6.3.7-1_${ARC_TYPE}.deb                  ./${WORK_DIRS}/deb/debian.testing                                                                                                                                                                                                                                   " \ #
#		"debian             testing             https://deb.debian.org/debian/pool/main/l/linux-signed-${ARC_TYPE}/linux-image-6.3.0-2-${ARC_TYPE}_6.3.11-1_${ARC_TYPE}.deb                 ./${WORK_DIRS}/deb/debian.testing                                                                                                                                                                                                                                   " \ #
#		"debian             testing             https://deb.debian.org/debian/pool/main/l/linux-signed-${ARC_TYPE}/linux-image-6.4.0-1-${ARC_TYPE}_6.4.4-1_${ARC_TYPE}.deb                  ./${WORK_DIRS}/deb/debian.testing                                                                                                                                                                                                                                   " \ #
		"debian             testing             https://deb.debian.org/debian/pool/main/l/linux-signed-${ARC_TYPE}/linux-image-6.4.0-1-${ARC_TYPE}_6.4.4-2_${ARC_TYPE}.deb                  ./${WORK_DIRS}/deb/debian.testing                                                                                                                                                                                                                                   " \
		"ubuntu             bionic.server       http://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed/linux-image-4.15.0-156-generic_4.15.0-156.163_${ARC_TYPE}.deb                     ./${WORK_DIRS}/deb/ubuntu.bionic                                                                                                                                                                                                                                    " \
		"ubuntu             bionic.server       http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-4.15.0-156-generic_4.15.0-156.163_${ARC_TYPE}.deb                          ./${WORK_DIRS}/deb/ubuntu.bionic                                                                                                                                                                                                                                    " \
		"ubuntu             bionic.server       http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-extra-4.15.0-156-generic_4.15.0-156.163_${ARC_TYPE}.deb                    ./${WORK_DIRS}/deb/ubuntu.bionic                                                                                                                                                                                                                                    " \
		"ubuntu             bionic.desktop      http://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed/linux-image-5.4.0-84-generic_5.4.0-84.94_${ARC_TYPE}.deb                          ./${WORK_DIRS}/deb/ubuntu.bionic                                                                                                                                                                                                                                    " \
		"ubuntu             bionic.desktop      http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-5.4.0-84-generic_5.4.0-84.94_${ARC_TYPE}.deb                               ./${WORK_DIRS}/deb/ubuntu.bionic                                                                                                                                                                                                                                    " \
		"ubuntu             bionic.desktop      http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-extra-5.4.0-84-generic_5.4.0-84.94_${ARC_TYPE}.deb                         ./${WORK_DIRS}/deb/ubuntu.bionic                                                                                                                                                                                                                                    " \
		"ubuntu             focal.server        http://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed/linux-image-5.4.0-144-generic_5.4.0-144.161_${ARC_TYPE}.deb                       ./${WORK_DIRS}/deb/ubuntu.focal                                                                                                                                                                                                                                     " \
		"ubuntu             focal.server        http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-5.4.0-144-generic_5.4.0-144.161_${ARC_TYPE}.deb                            ./${WORK_DIRS}/deb/ubuntu.focal                                                                                                                                                                                                                                     " \
		"ubuntu             focal.server        http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-extra-5.4.0-144-generic_5.4.0-144.161_${ARC_TYPE}.deb                      ./${WORK_DIRS}/deb/ubuntu.focal                                                                                                                                                                                                                                     " \
		"ubuntu             focal.desktop       http://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed-hwe-5.15/linux-image-5.15.0-67-generic_5.15.0-67.74~20.04.1_${ARC_TYPE}.deb       ./${WORK_DIRS}/deb/ubuntu.focal                                                                                                                                                                                                                                     " \
		"ubuntu             focal.desktop       http://archive.ubuntu.com/ubuntu/pool/main/l/linux-hwe-5.15/linux-modules-5.15.0-67-generic_5.15.0-67.74~20.04.1_${ARC_TYPE}.deb            ./${WORK_DIRS}/deb/ubuntu.focal                                                                                                                                                                                                                                     " \
		"ubuntu             focal.desktop       http://archive.ubuntu.com/ubuntu/pool/main/l/linux-hwe-5.15/linux-modules-extra-5.15.0-67-generic_5.15.0-67.74~20.04.1_${ARC_TYPE}.deb      ./${WORK_DIRS}/deb/ubuntu.focal                                                                                                                                                                                                                                     " \
		"ubuntu             jammy.server        http://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed-hwe-5.15/linux-image-5.15.0-60-generic_5.15.0-60.66~20.04.1_${ARC_TYPE}.deb       ./${WORK_DIRS}/deb/ubuntu.jammy                                                                                                                                                                                                                                     " \
		"ubuntu             jammy.server        http://archive.ubuntu.com/ubuntu/pool/main/l/linux-hwe-5.15/linux-modules-5.15.0-60-generic_5.15.0-60.66~20.04.1_${ARC_TYPE}.deb            ./${WORK_DIRS}/deb/ubuntu.jammy                                                                                                                                                                                                                                     " \
		"ubuntu             jammy.server        http://archive.ubuntu.com/ubuntu/pool/main/l/linux-hwe-5.15/linux-modules-extra-5.15.0-60-generic_5.15.0-60.66~20.04.1_${ARC_TYPE}.deb      ./${WORK_DIRS}/deb/ubuntu.jammy                                                                                                                                                                                                                                     " \
#		"ubuntu             jammy.desktop       5.19.0-32-generic                                                                                                                           ./${WORK_DIRS}/deb/ubuntu.jammy                                                                                                                                                                                                                                     " \ #
#		"ubuntu             jammy.desktop       5.19.0-32-generic                                                                                                                           ./${WORK_DIRS}/deb/ubuntu.jammy                                                                                                                                                                                                                                     " \ #
#		"ubuntu             jammy.desktop       5.19.0-32-generic                                                                                                                           ./${WORK_DIRS}/deb/ubuntu.jammy                                                                                                                                                                                                                                     " \ #
		"ubuntu             kinetic             http://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed/linux-image-5.19.0-21-generic_5.19.0-21.21_${ARC_TYPE}.deb                        ./${WORK_DIRS}/deb/ubuntu.kinetic                                                                                                                                                                                                                                   " \
		"ubuntu             kinetic             http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-5.19.0-21-generic_5.19.0-21.21_${ARC_TYPE}.deb                             ./${WORK_DIRS}/deb/ubuntu.kinetic                                                                                                                                                                                                                                   " \
		"ubuntu             kinetic             http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-extra-5.19.0-21-generic_5.19.0-21.21_${ARC_TYPE}.deb                       ./${WORK_DIRS}/deb/ubuntu.kinetic                                                                                                                                                                                                                                   " \
		"ubuntu             lunar               http://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed/linux-image-6.2.0-20-generic_6.2.0-20.20_${ARC_TYPE}.deb                          ./${WORK_DIRS}/deb/ubuntu.lunar                                                                                                                                                                                                                                     " \
		"ubuntu             lunar               http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-6.2.0-20-generic_6.2.0-20.20_${ARC_TYPE}.deb                               ./${WORK_DIRS}/deb/ubuntu.lunar                                                                                                                                                                                                                                     " \
		"ubuntu             lunar               http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-extra-6.2.0-20-generic_6.2.0-20.20_${ARC_TYPE}.deb                         ./${WORK_DIRS}/deb/ubuntu.lunar                                                                                                                                                                                                                                     " \
		"ubuntu             mantic              http://archive.ubuntu.com/ubuntu/pool/main/l/linux-signed/linux-image-6.3.0-7-generic_6.3.0-7.7+1_${ARC_TYPE}.deb                           ./${WORK_DIRS}/deb/ubuntu.mantic                                                                                                                                                                                                                                    " \
		"ubuntu             mantic              http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-6.3.0-7-generic_6.3.0-7.7_${ARC_TYPE}.deb                                  ./${WORK_DIRS}/deb/ubuntu.mantic                                                                                                                                                                                                                                    " \
		"ubuntu             mantic              http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-modules-extra-6.3.0-7-generic_6.3.0-7.7_${ARC_TYPE}.deb                            ./${WORK_DIRS}/deb/ubuntu.mantic                                                                                                                                                                                                                                    " \
	)	#0:distribution     1:codename          2:download URL                                                                                                                              3:directory                                 4:alias                                     5:iso file size     6:file date 7:definition file                               8:release   9:support   10:status   11:memo1            12:memo2                            

# --- package file ------------------------------------------------------------
	declare -r -a ADD_PACKAGE_LIST=(                \
		"libaio1"                                   \
		"libblkid[0-9.\-]\+"                        \
		"libc-l10n"                                 \
		"libfuse2"                                  \
		"libfuse3-[0-9.\-]\+"                       \
		"libgcrypt20"                               \
		"libgnutls30"                               \
		"libmount1"                                 \
		"libntfs-3g[0-9.\-]\+"                      \
		"libpcre3"                                  \
		"libselinux1"                               \
		"libsmartcols1"                             \
		"libtinfo[0-9.\-]\+"                        \
#		"libudev1"                                  \ #
		"libzstd1"                                  \
		"mount"                                     \
		"fuse3"                                     \
		"exfat-fuse"                                \
		"ntfs-3g"                                   \
#		"lvm2"                                      \ #
		"iso-scan"                                  \
		"load-iso"                                  \
#		"cdrom-checker"                             \ #
#		"cdrom-detect"                              \ #
#		"media-retriever"                           \ #
		"linux-image-[0-9.\-]\+-amd64"              \
		"linux-image-[0-9.\-]\+-generic"            \
		"linux-modules-[0-9.\-]\+-generic"          \
		"linux-modules-extra-[0-9.\-]\+-generic"    \
	)

	#idx: value
	#  0: distribution
	#  1: codename
	#  2: download URL
	#  3: directory

	declare -a PACKAGE_FILE=()

# --- USB device name for install's (sdX) -------------------------------------
	declare USB_INST="sda3"

# --- USB device name (sdX) ---------------------------------------------------
	declare USB_NAME="sda3"

# --- USB device format -------------------------------------------------------
	declare USB_FORMAT=""
	declare USB_NOFORMAT=0

# --- set minimum display size ------------------------------------------------
	declare -i ROW_SIZE=25
	declare -i COL_SIZE=80

# --- set color ---------------------------------------------------------------
	declare -r TXT_RESET='\033[m'		# reset all attributes
	declare -r TXT_ULINE='\033[4m'		# set underline
	declare -r TXT_ULINERST='\033[24m'	# reset underline
	declare -r TXT_REV='\033[7m'		# set reverse display
	declare -r TXT_REVRST='\033[27m'	# reset reverse display
	declare -r TXT_BLACK='\033[30m'		# text black
	declare -r TXT_RED='\033[31m'		# text red
	declare -r TXT_GREEN='\033[32m'		# text green
	declare -r TXT_YELLOW='\033[33m'	# text yellow
	declare -r TXT_BLUE='\033[34m'		# text blue
	declare -r TXT_MAGENTA='\033[35m'	# text purple
	declare -r TXT_CYAN='\033[36m'		# text light blue
	declare -r TXT_WHITE='\033[37m'		# text white
	declare -r TXT_BBLACK='\033[40m'	# text reverse black
	declare -r TXT_BRED='\033[41m'		# text reverse red
	declare -r TXT_BGREEN='\033[42m'	# text reverse green
	declare -r TXT_BYELLOW='\033[43m'	# text reverse yellow
	declare -r TXT_BBLUE='\033[44m'		# text reverse blue
	declare -r TXT_BMAGENTA='\033[45m'	# text reverse purple
	declare -r TXT_BCYAN='\033[46m'		# text reverse light blue
	declare -r TXT_BWHITE='\033[47m'	# text reverse white

### common function ###########################################################
# --- text color test ---------------------------------------------------------
function funcColorTest () {
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

#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "         1         2         3         4         5         6         7         8         9         0         1         2"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "　　　　　　　　　１　　　　　　　　　２　　　　　　　　　３　　　　　　　　　４　　　　　　　　　５　　　　　　　　　６　　　　　　　　　７　　　　　　　　　８　　　　　　　　　９　　　　　　　　　０　　　　　　　　　１　　　　　　　　　２"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "0　　　　　　　　　１　　　　　　　　　２　　　　　　　　　３　　　　　　　　　４　　　　　　　　　５　　　　　　　　　６　　　　　　　　　７　　　　　　　　　８　　　　　　　　　９　　　　　　　　　０　　　　　　　　　１　　　　　　　　　２"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "0１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０"
#	exit 0
}

# --- is numeric --------------------------------------------------------------
function funcIsNumeric () {
	if [[ "${1:-""}" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		echo 0
	else
		echo 1
	fi
}

# --- string output -----------------------------------------------------------
function funcString () {
	declare -r OLD_IFS="${IFS}"
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
function funcPrintf () {
	# https://www.tohoho-web.com/ex/dash-tilde.html
	declare -r OLD_IFS="${IFS}"
	declare -i RET_CD
	declare -r CHR_ESC="$(echo -n -e "\033")"
	declare -i MAX_COLS=${COL_SIZE:-80}
	declare    RET_STR=""
	declare    INP_STR=""
	declare    SJIS_STR=""
	declare -i SJIS_CNT=0
	declare    WORK_STR=""
	declare -i WORK_CNT=0
	declare    TEMP_STR=""
	declare -i TEMP_CNT=0
	declare -i CTRL_CNT=0
	# -------------------------------------------------------------------------
	IFS=$'\n'
	INP_STR="$(printf "$@")"
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
	RET_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932 | cut -b -${MAX_COLS} | iconv -f CP932 -t UTF-8 2> /dev/null)"
	RET_CD=$?
	set -e
	if [[ ${RET_CD} -ne 0 ]]; then
		set +e
		RET_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932 | cut -b -$((MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
		set -e
	fi
#	RET_STR+="$(echo -n -e ${TXT_RESET})"
	# -------------------------------------------------------------------------
	echo -e "${RET_STR}${TXT_RESET}"
	IFS="${OLD_IFS}"
}

# --- download ----------------------------------------------------------------
function funcCurl () {
#	declare -r OLD_IFS="${IFS}"
	declare -i RET_CD
	declare -i I
	declare INP_URL="$(echo "$@" | sed -n -e 's%^.* \(\(http\|https\)://.*\)$%\1%p')"
	declare OUT_DIR="$(echo "$@" | sed -n -e 's%^.* --output-dir *\(.*\) .*$%\1%p' | sed -e 's%/$%%')"
	declare OUT_FILE="$(echo "$@" | sed -n -e 's%^.* --output *\(.*\) .*$%\1%p' | sed -e 's%/$%%')"
	declare -a ARY_HED=("")
	declare ERR_MSG=""
	declare WEB_SIZ=""
	declare WEB_TIM=""
	declare WEB_FIL=""
	declare LOC_INF=""
	declare LOC_SIZ=""
	declare LOC_TIM=""
	declare TXT_SIZ=""
	declare -i INT_SIZ
	declare -i INT_UNT
	declare -a TXT_UNT=("Byte" "KiB" "MiB" "GiB" "TiB")
	set +e
	ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${INP_URL}" 2> /dev/null)")
	RET_CD=$?
	set -e
	if [[ ${RET_CD} -eq 6 ]] || [[ ${RET_CD} -eq 18 ]] || [[ ${RET_CD} -eq 22 ]] || [[ ${RET_CD} -eq 28 ]] || [[ "${#ARY_HED[@]}" -le 0 ]]; then
		ERR_MSG=$(echo "${ARY_HED[@]}" | sed -n -e '/^HTTP/p' | sed -z 's/\n\|\r\|\l//g')
		echo -e "${ERR_MSG} [${RET_CD}]: ${INP_URL}"
		return ${RET_CD}
	fi
	WEB_SIZ=$(echo "${ARY_HED[@],,}" | sed -n -e '/http\/.* 200/,/^$/ s/\'$'\r//gp' | sed -n -e '/content-length:/ s/.*: //p')
	WEB_TIM=$(TZ=UTC date -d "$(echo "${ARY_HED[@],,}" | sed -n -e '/http\/.* 200/,/^$/ s/\'$'\r//gp' | sed -n -e '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
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
		if [[ ${WEB_TIM:-0} -eq ${LOC_TIM:-0} ]] && [[ ${WEB_SIZ:-0} -eq ${LOC_SIZ:-0} ]]; then
			funcPrintf "same    file: ${WEB_FIL}"
			return
		fi
#		if [[ ${WEB_TIM:-0} -ne ${LOC_TIM:-0} ]]; then
#			funcPrintf "diff file: ${WEB_FIL}"
#			funcPrintf "WEB_TIM: ${WEB_TIM:-0}"
#			funcPrintf "LOC_TIM: ${LOC_TIM:-0}"
#		fi
#		if [[ ${WEB_SIZ:-0} -ne ${LOC_SIZ:-0} ]]; then
#			funcPrintf "diff file: ${WEB_FIL}"
#			funcPrintf "WEB_SIZ: ${WEB_SIZ:-0}"
#			funcPrintf "LOC_SIZ: ${LOC_SIZ:-0}"
#		fi
	fi

	if [[ ${WEB_SIZ} -lt 1024 ]]; then
		TXT_SIZ="$(printf "%'d Byte" "${WEB_SIZ}")"
	else
		for ((I=3; I>0; I--))
		do
			INT_UNT=$((1024**I))
			if [[ ${WEB_SIZ} -ge ${INT_UNT} ]]; then
				TXT_SIZ="$(echo "${WEB_SIZ}" "${INT_UNT}" | awk '{printf("%.1f", $1/$2)}') ${TXT_UNT[${I}]}"
#				INT_SIZ="$(((WEB_SIZ*1000)/(1024**I)))"
#				TXT_SIZ="$(printf "%'.1f ${TXT_UNT[${I}]}" "${INT_SIZ::${#INT_SIZ}-3}.${INT_SIZ:${#INT_SIZ}-3}")"
				break
			fi
		done
	fi

	funcPrintf "get     file: ${WEB_FIL} (${TXT_SIZ})"
	curl "$@"
	return $?
}

### subroutine ################################################################
# --- USB Device select -------------------------------------------------------
function funcUSB_Device_select () {
	declare DUMMY
	USB_NAME="${1:-""}"

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}select USB device${TXT_RESET}"
	while :
	do
		if [[ -n "${USB_NAME}" ]] && [[ -b "/dev/${USB_NAME}" ]]; then
			if [[ "$(lsblk --noheadings --nodeps --output TRAN /dev/${USB_NAME})" = "usb" ]]; then
				break
			fi
		fi
		lsblk --nodeps --output NAME,TYPE,TRAN,SIZE,VENDOR,MODEL /dev/sd[a-z]
		echo "Enter USB device name (sdX)"
		read USB_NAME
		if [[ ! "${USB_NAME}" =~ ^sd[a-z]$ ]]; then
			continue
		fi
		echo "/dev/${USB_NAME}, Are you sure? (YES or Ctrl-C)"
		read DUMMY
		if [[ "${DUMMY}" != "YES" ]]; then
			USB_NAME=""
			continue
		fi
	done
}

# -- make directory -----------------------------------------------------------
function funcMake_directory () {
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${SDIR_LIST[@]}")
	declare -a ARRAY_LINE=()
	declare DIR_PATH

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}remove file${TXT_RESET}"
#	rm -rf   "./${WORK_DIRS}"
#	rm -rf ./"${WORK_DIRS}"/{bld,deb,img,mnt,pac,ram,tmp,usb}
	rm -rf ./"${WORK_DIRS}"/{bld,img,mnt,pac,ram,tmp,usb}
	rm -rf "./${WORK_DIRS}/deb/"*~
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}make directory${TXT_RESET}"
	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		DIR_PATH="./${WORK_DIRS}/${ARRAY_LINE[0]}"
		if [[ ! -d "${DIR_PATH}/." ]]; then
			funcPrintf "make     dir: %-24.24s : %s\n" "make directory" "${DIR_PATH}"
			mkdir -p "${DIR_PATH}"
		fi
	done
}

# -- make symbolic link -------------------------------------------------------
function funcMake_link () {
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${LINK_LIST[@]}")
	declare -a ARRAY_LINE=()
	declare DIR_NAME
	declare BASE_NAME

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}make symbolic link${TXT_RESET}"
	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		DIR_NAME="${ARRAY_LINE[1]%/*}"
		BASE_NAME="${ARRAY_LINE[1]##*/}"
		if [[ ! -d "${DIR_NAME}/." ]]; then
			mkdir -p "${DIR_NAME}"
		fi
		if [[ ! -L "${ARRAY_LINE[1]}" ]]; then
			ln -s "${ARRAY_LINE[0]}" "${ARRAY_LINE[1]}"
		fi
	done
}

# --- read cache file ---------------------------------------------------------
function funcRead_cache () {
	declare -i I
	declare -i J
	declare -i CACHE_FTIME
	declare -a ARRAY_LIST=()
	declare -a ARRAY_LINE=()
	declare -a TARGET_LINE=()

	if [[ ! -f "${CACHE_FNAME}" ]]; then
		return
	fi

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}read cache file${TXT_RESET}"
	CACHE_FTIME="$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${CACHE_FNAME}" | awk '{print $6;}')"
	if [[ $(($(TZ=UTC date +"%Y%m%d%H%M%S") - CACHE_FTIME)) -gt 600 ]]; then
		return
	fi

	ARRAY_LIST=()
	while read -r ARRAY_LINE
	do
		ARRAY_LIST+=("${ARRAY_LINE[@]}")
	done < "${CACHE_FNAME}"
	for I in "${!TARGET_LIST[@]}"
	do
		TARGET_LINE=(${TARGET_LIST[${I}]})
		for J in "${!ARRAY_LIST[@]}"
		do
			ARRAY_LINE=(${ARRAY_LIST[${J}]})
			if [[ "${ARRAY_LINE[2]:-}" =~ ${TARGET_LINE[2]:-} ]]; then
				TARGET_LIST[I]="${ARRAY_LINE[@]}"
				break
			fi
		done
	done
}

# --- menu list ---------------------------------------------------------------
function funcMenu_list () {
#	declare -r OLD_IFS="${IFS}"
	declare -i RET_CD=0
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=()
	declare TXT_COLOR=""
	declare DIR_NAME
	declare BASE_NAME
	declare -a WEB_PAGE=()
	declare WEB_DISP
	declare -a WEB_INFO=()
	declare -i WEB_FTIME
	declare -a WEB_HEAD=()
	declare -i WEB_FSIZE
	declare WEB_FLAST
	declare FILE_INFO
	declare LOCAL_FNAME
	declare LOCAL_FINFO
	declare -i LOCAL_FSIZE
	declare -i LOCAL_FTIME
#	declare RMAKE_FNAME
#	declare -i RMAKE_FTIME

	#idx:value
	#  0:distribution
	#  1:codename
	#  2:download URL
	#  3:directory
	#  4:alias
	#  5:iso file size
	#  6:iso file date
	#  7:definition file
	#  8:release
	#  9:support
	# 10:status
	# 11:memo1
	# 12:memo2


#	funcPrintf "\033[${ROW_SIZE};1H${TXT_BBLUE}Now loading ...${TXT_RESET}"
	funcPrintf "%s\n" "# $(funcString $((COL_SIZE-4)) '-') #"
	funcPrintf "%s\n" "#ID:Version                                      :ReleaseDay:SupportEnd:Memo$(funcString $((COL_SIZE-77)) ' ')#"

	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		DIR_NAME="${ARRAY_LINE[2]%/*}"
		BASE_NAME="${ARRAY_LINE[2]##*/}"
		TXT_COLOR="${TXT_RESET}"
#		RET_CD=0
#		WEB_PAGE=()
		# --- URL completion --------------------------------------------------
		if [[ "${DIR_NAME}" =~ \[.*\] ]]; then
#			funcPrintf "\033[${ROW_SIZE};1H${TXT_BBLUE}Now download %-$((${COL_SIZE}-13)).$((${COL_SIZE}-13))s${TXT_RESET}" "${DIR_NAME%/*\[*}"
			set +e
			WEB_PAGE=("$(curl --location --http1.1 --no-progress-bar --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${DIR_NAME%/*\[*}" 2> /dev/null)")
			RET_CD=$?
			set -e
			if [[ ${RET_CD} -eq 6 ]] || [[ ${RET_CD} -eq 18 ]] || [[ ${RET_CD} -eq 22 ]] || [[ ${RET_CD} -eq 28 ]] || [[ ${#WEB_PAGE[@]} -le 0 ]]; then
				TXT_COLOR="${TXT_RED}"
			else
				WEB_DISP="$(echo "${DIR_NAME}" | sed -n -e 's%^'"${DIR_NAME%/*\[*}"'/\(.*\)/'"${DIR_NAME#*\]*/}"'$%\1%p')"
				DIR_NAME="${DIR_NAME%/*\[*}/$(echo "${WEB_PAGE[@]}" | sed -e 's/\'$'\r//gp' | LANG=C sed -n -e '/'"${WEB_DISP}"'/ s%^.*<a href=.*> *\('"${WEB_DISP}"'\)/ *</a.*>.*$%\1%p' | sort -r | head -n 1)/${DIR_NAME#*\]*/}"
			fi
		fi
		# --- get home page ---------------------------------------------------
		WEB_INFO=()
		FILE_INFO=()
		if [[ "${TXT_COLOR}" != "${TXT_RED}" ]] && [[ "${BASE_NAME}" =~ \[.*\] || "${ARRAY_LINE[10]}" = "-" ]]; then
#			funcPrintf "\033[${ROW_SIZE};1H${TXT_BBLUE}Now download %-$((${COL_SIZE}-13)).$((${COL_SIZE}-13))s${TXT_RESET}" "${DIR_NAME}"
			set +e
			WEB_INFO=("$(curl --location --http1.1 --no-progress-bar --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${DIR_NAME}" 2> /dev/null)")
			RET_CD=$?
			set -e
			if [[ ${RET_CD} -eq 6 ]] || [[ ${RET_CD} -eq 18 ]] || [[ ${RET_CD} -eq 22 ]] || [[ ${RET_CD} -eq 28 ]] || [[ ${#WEB_INFO[@]} -le 0 ]]; then
				TXT_COLOR="${TXT_RED}"
			else
				FILE_INFO=($(echo "${WEB_INFO[@]}" | sed -e 's/\'$'\r//g' | LANG=C sed -n -e "/${BASE_NAME}/ s/^.*<a href=.*> *\(${BASE_NAME}\) *<\/a.*> *\([0-9a-zA-Z]*-[0-9a-zA-Z]*-[0-9a-zA-Z]*\) *\([0-9]*:[0-9]*\).*$/\1 \2 \3/p" | sort -r | head -n 1))
				if [[ ${#FILE_INFO[@]} -le 0 ]]; then
					TXT_COLOR="${TXT_RED}"
				fi
			fi
		fi
		# --- filename completion ---------------------------------------------
		if [[ "${TXT_COLOR}" != "${TXT_RED}" ]] && [[ "${#FILE_INFO[@]}" -gt 0 && -n "${FILE_INFO[1]}" ]]; then
			TXT_COLOR="${TXT_CYAN}"
			if [[ -z "${FILE_INFO[2]}" ]]; then
				FILE_INFO[2]="00:00"
			fi
			FILE_INFO[2]="${FILE_INFO[2]}:00"
			FILE_INFO[2]="${FILE_INFO[2]::8}"
			BASE_NAME="${FILE_INFO[0]}"
			ARRAY_LINE[2]="${DIR_NAME}/${FILE_INFO[0]}"
			ARRAY_LINE[8]="$(TZ=UTC date -d "${FILE_INFO[1]} ${FILE_INFO[2]} GMT" "+%Y-%m-%d.%H:%M:%S")"
		fi
		# --- set local filename ----------------------------------------------
		if [[ "${ARRAY_LINE[4]}" =~ \[.*\] || "${ARRAY_LINE[10]}" = "-" ]] && [[ -d "${ARRAY_LINE[3]}/." ]]; then
			LOCAL_FNAME="$(find "${ARRAY_LINE[3]}" \( -type f -o -type l \) -regextype posix-basic -regex ".*/${ARRAY_LINE[4]}" -print)"
			if [[ -n "${LOCAL_FNAME}" ]] && [[ -f "${LOCAL_FNAME}" ]]; then
				LOCAL_FINFO="$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${LOCAL_FNAME}")"
				LOCAL_FTIME="$(echo "${LOCAL_FINFO}" | awk '{print $6;}')"
				ARRAY_LINE[4]="${LOCAL_FNAME##*/}"
				ARRAY_LINE[8]="${LOCAL_FTIME:0:4}-${LOCAL_FTIME:4:2}-${LOCAL_FTIME:6:2}.${LOCAL_FTIME:8:2}:${LOCAL_FTIME:10:2}:${LOCAL_FTIME:12:2}"
			fi
		fi
		# --- alias -----------------------------------------------------------
		if [[ "${ARRAY_LINE[4]}" = "-" ]]; then
			if [[ "${BASE_NAME%.*}" = "mini" ]]; then			# mini.iso
				ARRAY_LINE[4]="mini-${ARRAY_LINE[1]}-${ARC_TYPE}.iso"
			else
				ARRAY_LINE[4]="${BASE_NAME}"
			fi
			# --- set local filename information ------------------------------
			if [[ ${#WEB_INFO[@]} -le 0 ]]; then
				LOCAL_FNAME="$(find "${ARRAY_LINE[3]}" \( -type f -o -type l \) -regextype posix-basic -regex ".*/${ARRAY_LINE[4]}" -print)"
				if [[ -n "${LOCAL_FNAME}" ]] && [[ -f "${LOCAL_FNAME}" ]]; then
					LOCAL_FINFO="$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${LOCAL_FNAME}")"
					LOCAL_FTIME="$(echo "${LOCAL_FINFO}" | awk '{print $6;}')"
					ARRAY_LINE[4]="${LOCAL_FNAME##*/}"
					ARRAY_LINE[8]="${LOCAL_FTIME:0:4}-${LOCAL_FTIME:4:2}-${LOCAL_FTIME:6:2}.${LOCAL_FTIME:8:2}:${LOCAL_FTIME:10:2}:${LOCAL_FTIME:12:2}"
				fi
			fi
		fi
		# --- check local file ------------------------------------------------
		LOCAL_FNAME=""
		if [[ -d "${ARRAY_LINE[3]}/." ]]; then
			LOCAL_FNAME="$(find "${ARRAY_LINE[3]}" \( -type f -o -type l \) -regextype posix-basic -regex ".*/${ARRAY_LINE[4]}" -print)"
		fi
		if [[ -z "${LOCAL_FNAME}" ]] || [[ ! -f "${LOCAL_FNAME}" ]]; then
			TXT_COLOR+="${TXT_REV}"							# not exist
		else												# exist
			LOCAL_FINFO="$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${LOCAL_FNAME}")"
			LOCAL_FSIZE="$(echo "${LOCAL_FINFO}" | awk '{print $5;}')"
			LOCAL_FTIME="$(echo "${LOCAL_FINFO}" | awk '{print $6;}')"
			if [[ "${TXT_COLOR}" = "${TXT_RED}" ]]; then	# curl error
				ARRAY_LINE[8]="${LOCAL_FTIME:0:4}-${LOCAL_FTIME:4:2}-${LOCAL_FTIME:6:2}.${LOCAL_FTIME:8:2}:${LOCAL_FTIME:10:2}:${LOCAL_FTIME:12:2}"
			else											# curl no error
				TXT_COLOR="${TXT_GREEN}"
				# --- comparing local files and web files ---------------------
				WEB_FTIME="$(TZ=UTC date -d "${ARRAY_LINE[8]/./ } GMT" "+%Y%m%d%H%M%S")"
				if [[ ${WEB_FTIME::-2} -eq ${LOCAL_FTIME::-2} ]] && [[ "${ARRAY_LINE[10]}" = "-" ]]; then	# same
					TXT_COLOR="${TXT_RESET}"
				else										# different timestamp
					# --- get web header info ---------------------------------
#					funcPrintf "\033[${ROW_SIZE};1H${TXT_BBLUE}Now download %-$((${COL_SIZE}-13)).$((${COL_SIZE}-13))s${TXT_RESET}" "${ARRAY_LINE[2]}"
					set +e
					WEB_HEAD=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${ARRAY_LINE[2]}" 2> /dev/null)")
					RET_CD=$?
					set -e
					# --- check curl status -----------------------------------
					if [[ ${RET_CD} -eq 6 ]] || [[ ${RET_CD} -eq 18 ]] || [[ ${RET_CD} -eq 22 ]] || [[ ${RET_CD} -eq 28 ]] || [[ "${#WEB_HEAD[@]}" -le 0 ]]; then
						TXT_COLOR="${TXT_RED}"
					else
						# --- get web file info -------------------------------
						WEB_FSIZE=$(echo "${WEB_HEAD[@],,}" | sed -n -e '/http\/.* 200/,/^$/ s/\'$'\r//gp' | sed -n -e '/^content-length:/ s/^.*: //p')
						WEB_FLAST=$(echo "${WEB_HEAD[@],,}" | sed -n -e '/http\/.* 200/,/^$/ s/\'$'\r//gp' | sed -n -e '/^last-modified:/ s/^.*: //p')
						WEB_FTIME=$(TZ=UTC date -d "${WEB_FLAST}" "+%Y%m%d%H%M%S")
						ARRAY_LINE[8]="${WEB_FTIME:0:4}-${WEB_FTIME:4:2}-${WEB_FTIME:6:2}.${WEB_FTIME:8:2}:${WEB_FTIME:10:2}:${WEB_FTIME:12:2}"
						# --- comparing local files and web files -------------
						if [[ ${WEB_FSIZE:-0} -eq ${LOCAL_FSIZE:-0} ]] && [[ ${WEB_FTIME:-0} -eq ${LOCAL_FTIME:-0} ]]; then
							TXT_COLOR="${TXT_RESET}"
						else
							TXT_COLOR+="${TXT_REV}"
						fi
					fi
				fi
				# --- check remake file ---------------------------------------
#				RMAKE_FNAME=""
#				if [[ -d "${ARRY_LINE[3]}/." ]]; then
#					RMAKE_FNAME="$(find "${ARRY_LINE[3]}" \( -type f -o -type l \) -regextype posix-basic -regex ".*/${ARRY_LINE[4]%.*}-*\(custom\)*-\(autoyast\|kickstart\|nocloud\|preseed\)\.iso" -print)"
#				fi
#				if [[ -z "${RMAKE_FNAME}" ]] || [[ ! -f "${RMAKE_FNAME}" ]]; then
#					TXT_COLOR+="${TXT_GREEN}"
#				else
#					RMAKE_FTIME="$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${RMAKE_FNAME}" | awk '{print $6;}')"
#					# --- comparing remake files and web files ----------------
#					if [[ ${WEB_FTIME} -gt ${RMAKE_FTIME} ]]; then
#						TXT_COLOR+="${TXT_YELLOW}"
#					fi
#				fi
			fi
		fi
		ARRAY_LINE[10]="${TXT_COLOR}"
		TARGET_LIST[I]="${ARRAY_LINE[@]}"
		funcPrintf "${TXT_RESET}#${TXT_COLOR}%2d:%-45.45s:%-10.10s:%-10.10s:%-$((COL_SIZE-73)).$((COL_SIZE-73))s${TXT_RESET}#\n" "$((I+1))" "${ARRAY_LINE[4]}" "${ARRAY_LINE[8]::10}" "${ARRAY_LINE[9]}" "${ARRAY_LINE[11]}"
	done

	funcPrintf "%s\n" "# $(funcString $((COL_SIZE-4)) '-') #"
#	funcPrintf "\033[${ROW_SIZE};1H\033[2K"

	: > "${CACHE_FNAME}"
	for I in "${!ARRAY_LIST[@]}"
	do
		echo "${TARGET_LIST[${I}]}" >> "${CACHE_FNAME}"
	done
}

# --- set download module -----------------------------------------------------
function funcSet_download_module () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
	declare -i I
	declare -i J
	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=()
#	declare DIR_NAME
#	declare BASE_NAME
	declare -a DIST_LIST=()
	declare -a DIST_LINE=()
	declare -a PACKAGE_LINE=()
	declare FILE_NAME=""
#	declare FILE_URL=""
	declare -a FIND_DIRS=()

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}get  package: ${TXT_RESET}"
	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
#		DIR_NAME="${ARRAY_LINE[2]%/*}"
#		BASE_NAME="${ARRAY_LINE[2]##*/}"
		for J in "${!DIST_LIST[@]}"
		do
			DIST_LINE=(${DIST_LIST[${J}]})
			if [[ "${DIST_LINE[0]}" = "${ARRAY_LINE[0]}" ]] && [[ "${DIST_LINE[1]}" = "${ARRAY_LINE[1]%%.*}" ]]; then
				continue 2
			fi
		done
		case "${ARRAY_LINE[0]}" in
			debian ) DIST_LIST+=("${ARRAY_LINE[0]} ${ARRAY_LINE[1]%%.*} ${WEB_DEBIAN}");;
			ubuntu ) DIST_LIST+=("${ARRAY_LINE[0]} ${ARRAY_LINE[1]%%.*} ${WEB_UBUNTU}");;
			*      ) continue;;
		esac
	done
	# --- debian --------------------------------------------------------------
	funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "./${WORK_DIRS}/deb/debian" "${WEB_DEBIAN}/ls-lR.gz"
	gzip -k -d -f "./${WORK_DIRS}/deb/debian/ls-lR.gz"
	# --- ubuntu --------------------------------------------------------------
	funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "./${WORK_DIRS}/deb/ubuntu" "${WEB_UBUNTU}/ls-lR.gz"
	gzip -k -d -f "./${WORK_DIRS}/deb/ubuntu/ls-lR.gz"
	# -------------------------------------------------------------------------
	#idx: value
	#  0: distribution
	#  1: codename
	#  2: download URL
	#  3: directory
	PACKAGE_FILE=()
	for I in "${!DIST_LIST[@]}"
	do
		DIST_LINE=(${DIST_LIST[${I}]})
		funcPrintf "${TXT_BLACK}${TXT_BYELLOW}get  package: ${TXT_BGREEN}${DIST_LINE[0]}.${DIST_LINE[1]}${TXT_RESET}"
		funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}"                  "${DIST_LINE[2]}/dists/${DIST_LINE[1]}/Release"
		funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}/main"             "${DIST_LINE[2]}/dists/${DIST_LINE[1]}/main/binary-amd64/Packages.gz"
		funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}/debian-installer" "${DIST_LINE[2]}/dists/${DIST_LINE[1]}/main/debian-installer/binary-amd64/Packages.gz"
		gzip -k -d -f "./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}/main/Packages.gz"
		gzip -k -d -f "./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}/debian-installer/Packages.gz"
		# ---------------------------------------------------------------------
		if [[ "${DIST_LINE[0]}" = "ubuntu" ]]; then
			funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}/universe"             "${DIST_LINE[2]}/dists/${DIST_LINE[1]}/universe/binary-amd64/Packages.gz"
			gzip -k -d -f "./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}/universe/Packages.gz"
#			FIND_DIRS+=("./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}/main/Packages")
		fi
		# ---------------------------------------------------------------------
		FIND_DIRS=($(find "./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}/" -name 'Packages' \( -type f -o -type l \)))
		for J in "${!ADD_PACKAGE_LIST[@]}"
		do
			PACKAGE_LINE=(${ADD_PACKAGE_LIST[${J}]})
			FILE_NAME=""
			for FILE_NAME in $(sed -n -e "/^Package: ${PACKAGE_LINE}\(-udeb\)*$/,/^$/ s/^Filename: \(.*\)$/\1/gp" "${FIND_DIRS[@]}")
			do
				PACKAGE_FILE+=("${DIST_LINE[0]} ${DIST_LINE[1]} ${DIST_LINE[2]}/${FILE_NAME} ./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}")
				case "${FILE_NAME##*/}" in
					iso-scan_*        | \
					cdrom-checker_*   | \
					cdrom-detect_*    | \
					media-retriever_* )
						PACKAGE_FILE+=("${DIST_LINE[0]} ${DIST_LINE[1]} ${DIST_LINE[2]}/${FILE_NAME%_*}.tar.xz ./${WORK_DIRS}/deb/${DIST_LINE[0]}.${DIST_LINE[1]}")
						;;
				esac
			done
			funcPrintf "get  package: %-24.24s : %s\n" "${PACKAGE_LINE}" "${FILE_NAME##*/}"
		done
	done
#	PACKAGE_FILE+=("${LINUX_IMAGE[@]}")
}

# --- move download module ----------------------------------------------------
function funcMove_download_module () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
	declare -i I
#	declare -i J
#	declare -a ARRAY_LIST=()
#	declare -a ARRAY_LINE=()
	declare DIR_NAME
#	declare BASE_NAME
	declare PATH_NAME
	declare -a PACKAGE_LINE=()

	#idx: value
	#  0: distribution
	#  1: codename
	#  2: download URL
	#  3: directory

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}move package: ${TXT_RESET}"
	rm -rf "./${WORK_DIRS}/deb/"*~
	for I in "${!PACKAGE_FILE[@]}"
	do
		PACKAGE_LINE=(${PACKAGE_FILE[${I}]})
		if [[ -d "${PACKAGE_LINE[3]}/." ]] && [[ ! -d "${PACKAGE_LINE[3]}~/." ]]; then
			mv "${PACKAGE_LINE[3]}" "${PACKAGE_LINE[3]}~"
			mkdir -p "${PACKAGE_LINE[3]}"
		fi
		if [[ -f "${PACKAGE_LINE[3]}~/${PACKAGE_LINE[2]##*/}" ]] && [[ ! -f "${PACKAGE_LINE[3]}/${PACKAGE_LINE[2]##*/}" ]]; then
			funcPrintf "move package: %-24.24s : %s\n" "${PACKAGE_LINE[0]}.${PACKAGE_LINE[1]}" "${PACKAGE_LINE[2]##*/}"
			mv "${PACKAGE_LINE[3]}~/${PACKAGE_LINE[2]##*/}" "${PACKAGE_LINE[3]}/"
		fi
	done
	for DIR_NAME in $(find "./${WORK_DIRS}/deb/" -maxdepth 1 -name '*~' -type d)
	do
		for PATH_NAME in "Release" "debian-installer" "main" "contrib" "non-free" "non-free-firmware" "restricted" "universe" "multiverse"
		do
			if [[ -f "${DIR_NAME}/${PATH_NAME}" ]] || [[ -d "${DIR_NAME}/${PATH_NAME}" ]]; then
				mv "${DIR_NAME}/${PATH_NAME}" "${DIR_NAME%\~}"
			fi
		done
		rm -rf "${DIR_NAME}"
	done
}

# --- get module in dvd -------------------------------------------------------
function funcGet_module_in_dvd () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
	declare -i I
	declare -i J
	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=()
	declare DIR_NAME
	declare BASE_NAME
	declare DIR_SECT
	declare DIR_CODE
	declare DIR_DIST
	declare DIR_PATH
#	declare -a DIST_LIST=()
#	declare -a DIST_LINE=()
	declare -a PACKAGE_LINE=()
	declare FILE_NAME=""
#	declare FILE_URL=""
	declare -a FIND_DIRS=()

	#idx:value
	#  0:distribution
	#  1:codename
	#  2:download URL
	#  3:directory
	#  4:alias
	#  5:iso file size
	#  6:iso file date
	#  7:definition file
	#  8:release
	#  9:support
	# 10:status
	# 11:memo1
	# 12:memo2

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}get  package: ${TXT_RESET}"
	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		DIR_SECT="$(echo "${ARRAY_LINE[4],,}" | sed -n -e 's/^.*\(live\|dvd\|netinst\|netboot\|server\|boot\|minimal\|net\|rtm\|legacy\|desktop\).*$/\1/p')"
		DIR_CODE="${ARRAY_LINE[0]}.${ARRAY_LINE[1]%%.*}"
		DIR_DIST="${DIR_CODE}.${DIR_SECT:-desktop}"
		DIR_PATH="${ARRAY_LINE[3]}/${ARRAY_LINE[4]}"
		case "${ARRAY_LINE[0]}" in
			debian | \
			ubuntu )
				;;
			*      )
				continue
				;;
		esac
		funcPrintf "${TXT_BLACK}${TXT_BYELLOW}get  package: ${TXT_BGREEN}%-24.24s${TXT_RESET} : %s\n" "${DIR_DIST}" "${DIR_PATH}"
		mount -r -o loop "${DIR_PATH}" "./${WORK_DIRS}/mnt/"
		# --- Packages copy and unzip -----------------------------------------
		cp --preserve=timestamps --no-preserve=mode,ownership --recursive "./${WORK_DIRS}/mnt/dists/." "./${WORK_DIRS}/deb/${DIR_DIST}"
		for FILE_NAME in $(find "./${WORK_DIRS}/deb/${DIR_DIST}" -name 'Packages.gz' \( -type f -o -type l \))
		do
			if [[ ! -f "${FILE_NAME%.*}" ]]; then
				gzip -k -d -f "${FILE_NAME}"
			fi
		done
		# --- module copy -----------------------------------------------------
		FIND_DIRS=($(find "./${WORK_DIRS}/deb/${DIR_DIST}/" -name 'Packages' \( -type f -o -type l \)))
		for J in "${!ADD_PACKAGE_LIST[@]}"
		do
			PACKAGE_LINE=(${ADD_PACKAGE_LIST[${J}]})
			FILE_NAME=""
			for FILE_NAME in $(sed -n -e "/^Package: ${PACKAGE_LINE}\(-udeb\)*$/,/^$/ s/^Filename: \(.*\)$/\1/gp" "${FIND_DIRS[@]}")
			do
				if [[ ! -f "./${WORK_DIRS}/mnt/${FILE_NAME}" ]]; then
					continue
				fi
				cp --preserve=timestamps --no-preserve=mode,ownership "./${WORK_DIRS}/mnt/${FILE_NAME}" "./${WORK_DIRS}/deb/${DIR_DIST}/"
			done
			funcPrintf "get  package: %-24.24s : %s\n" "${PACKAGE_LINE}" "${FILE_NAME##*/}"
		done
		# --- make code name --------------------------------------------------
		if [[ "${DIR_PATH##*/}" =~ .*-testing-.* ]]; then
			ARRAY_LINE[1]="testing"
		else
			ARRAY_LINE[1]="$(ls -1 -I *stable -I testing "./${WORK_DIRS}/mnt/dists/")"
		fi
		ARRAY_LINE[1]+=".${DIR_SECT}"
		TARGET_LIST[I]="${ARRAY_LINE[@]}"
		funcPrintf "chage cdname: %-24.24s : %s\n" "${ARRAY_LINE[1]}" "${DIR_PATH##*/}"
		umount "./${WORK_DIRS}/mnt/"
	done

	: > "${CACHE_FNAME}"
	for I in "${!ARRAY_LIST[@]}"
	do
		echo "${TARGET_LIST[${I}]}" >> "${CACHE_FNAME}"
	done
}

# --- download ----------------------------------------------------------------
function funcDownload () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
	declare -i I
#	declare -i J
	declare -a ARRAY_LINE=()
	declare DIR
	declare DIR_NAME
	declare BASE_NAME

	#idx: value
	#  0: distribution
	#  1: codename
	#  2: download URL
	#  3: directory

	# --- set download module -------------------------------------------------
	funcSet_download_module
	# --- move download module ------------------------------------------------
	funcMove_download_module
	# --- config file ---------------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}get     file: ${TXT_BGREEN}get config file${TXT_RESET}"
	for I in "${!CONFIG_FILE[@]}"
	do
		ARRAY_LINE=(${CONFIG_FILE[${I}]})
		DIR_NAME="${ARRAY_LINE[2]%/*}"
		BASE_NAME="${ARRAY_LINE[2]##*/}"
		if [[ -f "${ARRAY_LINE[3]}/${BASE_NAME}" ]]; then
			funcPrintf "skip    file: ${ARRAY_LINE[3]}/${BASE_NAME}"
		else
			funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "${ARRAY_LINE[3]}" "${ARRAY_LINE[2]}"
		fi
	done
	# --- debian installer ----------------------------------------------------
#	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}get     file: ${TXT_BGREEN}get debian installer${TXT_RESET}"
#	for I in "${!DEBIAN_INSTALLER[@]}"
#	do
#		ARRAY_LINE=(${DEBIAN_INSTALLER[${I}]})
#		funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "${ARRAY_LINE[3]}" "${ARRAY_LINE[2]}"
#	done
	# --- package file --------------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}get     file: ${TXT_BGREEN}get package file${TXT_RESET}"
	for I in "${!PACKAGE_FILE[@]}"
	do
		ARRAY_LINE=(${PACKAGE_FILE[${I}]})
		funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "${ARRAY_LINE[3]}" "${ARRAY_LINE[2]}"
	done
	# --- iso file ------------------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}get     file: ${TXT_BGREEN}get iso file${TXT_RESET}"
	for  I in "${!TARGET_LIST[@]}"
	do
		ARRAY_LINE=(${TARGET_LIST[${I}]})
		if [[ "${ARRAY_LINE[10]}" = "${TXT_RESET}" ]]; then
			continue
		fi
		if [[ "${ARRAY_LINE[4]}" = "-" ]]; then
			funcCurl --location --progress-bar --remote-name --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output-dir "${ARRAY_LINE[3]}" "${ARRAY_LINE[2]}" || true
		else
			funcCurl --location --progress-bar --remote-time --show-error --fail --retry-max-time 3 --retry 3 --create-dirs --output "${ARRAY_LINE[3]}/${ARRAY_LINE[4]}" "${ARRAY_LINE[2]}" || true
		fi
	done
}

# --- make preseed sub command ------------------------------------------------
function funcMake_preseed_sub_command () {
	declare -r CONF_PATH="$1"
	declare -r CONF_DIRS="${CONF_PATH%/*}"
#	declare -r CONF_FILE="${CONF_PATH##*/}"
	declare -r COMD_FILE="${CONF_DIRS}/preseed_sub_command.sh"

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}make sub cmd: ${TXT_BGREEN}${COMD_FILE##*/}${TXT_RESET}"
	cat <<- '_EOT_SH_' | sed 's/^ *//g' > "${COMD_FILE}"
		#!/bin/sh
		
		### initialization ############################################################
		#	set -n								# Check for syntax errors
		#	set -x								# Show command and argument expansion
		 	set -o ignoreeof					# Do not exit with Ctrl+D
		 	set +m								# Disable job control
		 	set -e								# Ends with status other than 0
		 	set -u								# End with undefined variable reference
		
		 	trap 'exit 1' 1 2 3 15
		
		 	readonly PROG_PRAM="$@"
		 	readonly PROG_NAME="${0##*/}"
		 	readonly WORK_DIRS="${0%/*}"
		 	readonly DIST_NAME="$(uname -v | tr '[A-Z]' '[a-z]' | sed -n -e 's/.*\(debian\|ubuntu\).*/\1/p')"
		 	echo "${PROG_NAME}: PROG_PRAM=${PROG_PRAM}"
		 	echo "${PROG_NAME}: PROG_NAME=${PROG_NAME}"
		 	echo "${PROG_NAME}: WORK_DIRS=${WORK_DIRS}"
		 	echo "${PROG_NAME}: DIST_NAME=${DIST_NAME}"
		 	#--------------------------------------------------------------------------
		 	if [ -z "${PROG_PRAM}" ]; then
		 		ROOT_DIRS="/target"
		 		COMD_LINE=""
		 		CONF_FILE=""
		 		TEMP_FILE=""
		 		if [ -d /preseed/. ]; then
		 			PROG_PATH="/preseed/${PROG_NAME}"
		 			CONF_FILE=/preseed/preseed.cfg
		 		else
		 			PROG_PATH="$0"
		 			for COMD_LINE in $(cat /proc/cmdline)
		 			do
		 				case "${COMD_LINE}" in
		 					preseed/file=* ) CONF_FILE="${COMD_LINE#preseed/file=}"; break;;
		 					file=*         ) CONF_FILE="${COMD_LINE#file=}"        ; break;;
		 				esac
		 			done
		 		fi
		 		echo "${PROG_NAME}: PROG_PATH=${PROG_PATH}"
		 		if [ -z "${CONF_FILE}" ] || [ ! -f "${CONF_FILE}" ]; then
		 			echo "${PROG_NAME}: not found preseed file [${CONF_FILE}]"
		 			exit 0
		 		fi
		 		echo "${PROG_NAME}: now found preseed file [${CONF_FILE}]"
		 		cp -a "${PROG_PATH}" "${ROOT_DIRS}/tmp/"
		 		cp -a "${CONF_FILE}" "${ROOT_DIRS}/tmp/"
		 		TEMP_FILE="/tmp/${CONF_FILE##*/}"
		 		echo "${PROG_NAME}: ROOT_DIRS=${ROOT_DIRS}"
		 		echo "${PROG_NAME}: COMD_LINE=${COMD_LINE}"
		 		echo "${PROG_NAME}: CONF_FILE=${CONF_FILE}"
		 		echo "${PROG_NAME}: TEMP_FILE=${TEMP_FILE}"
		 		in-target --pass-stdout bash -c "/tmp/${PROG_NAME} ${TEMP_FILE}"
		 		exit 0
		 	fi
		 	ROOT_DIRS=""
		 	TEMP_FILE="${PROG_PRAM}"
		 	echo "${PROG_NAME}: ROOT_DIRS=${ROOT_DIRS}"
		 	echo "${PROG_NAME}: TEMP_FILE=${TEMP_FILE}"
		
		### common ###########################################################
		# --- IPv4 netmask conversion -------------------------------------------------
		funcIPv4GetNetmask () {
		 	readonly INP_ADDR="$1"
		 	readonly DEC_ADDR="$((0xFFFFFFFF ^ (2**(32-INP_ADDR)-1)))"
		 	printf '%d.%d.%d.%d' \
		 	    $(( DEC_ADDR >> 24        )) \
		 	    $(((DEC_ADDR >> 16) & 0xFF)) \
		 	    $(((DEC_ADDR >>  8) & 0xFF)) \
		 	    $(( DEC_ADDR        & 0xFF))
		 }
		
		# --- IPv4 netmask bit conversion ---------------------------------------------
		funcIPv4GetNetmaskBits () {
		 	readonly INP_ADDR="$1"
		 	echo "${INP_ADDR}" | \
		 	    awk -F '.' '{
		 	        split($0, octets);
		 	        for (i in octets) {
		 	            mask += 8 - log(2^8 - octets[i])/log(2);
		 	        }
		 	        print mask
		 	    }'
		}
		
		### subroutine ################################################################
		# --- packages ----------------------------------------------------------------
		funcInstallPackages () {
		 	echo "funcInstallPackages"
		 	#--------------------------------------------------------------------------
		 	LIST_TASK="$(sed -n -e '/^[[:blank:]]*tasksel[[:blank:]]\+tasksel\/first[[:blank:]]\+/,/[^\\]$/p' "${TEMP_FILE}" | \
		 	             sed -z -e 's/\\\n//g'                                                                               | \
		 	             sed -e 's/^.*[[:blank:]]\+multiselect[[:blank:]]\+//'                                                 \
		 	                 -e 's/[[:blank:]]\+/ /g')"
		 	LIST_PACK="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+pkgsel\/include[[:blank:]]\+/,/[^\\]$/p'    "${TEMP_FILE}" | \
		 	             sed -z -e 's/\\\n//g'                                                                               | \
		 	             sed -e 's/^.*[[:blank:]]\+string[[:blank:]]\+//'                                                      \
		 	                 -e 's/[[:blank:]]\+/ /g')"
		 	echo "${PROG_NAME}: LIST_TASK=${LIST_TASK}"
		 	echo "${PROG_NAME}: LIST_PACK=${LIST_PACK}"
		 	#--------------------------------------------------------------------------
		 	sed -i "${ROOT_DIRS}/etc/apt/sources.list" \
		 	    -e '/cdrom/ s/^ *\(deb\)/# \1/g'
		 	apt-get -qq    update
		 	apt-get -qq -y upgrade
		 	apt-get -qq -y dist-upgrade
		 	apt-get -qq -y install ${LIST_PACK}
		 	if [ -n "$(command -v tasksel 2> /dev/null)" ]; then
		 		tasksel install ${LIST_TASK}
		 	fi
		}
		
		# --- network -----------------------------------------------------------------
		funcSetupNetwork () {
		 	echo "funcSetupNetwork"
		 	#--------------------------------------------------------------------------
		 	FIX_IPV4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+\(netcfg\/disable_dhcp\|netcfg\/disable_autoconfig\)[[:blank:]]\+/ s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_IPV4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_ipaddress[[:blank:]]\+/   s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_MASK="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_netmask[[:blank:]]\+/     s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_GATE="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_gateway[[:blank:]]\+/     s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_DNS4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_nameservers[[:blank:]]\+/ s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_WGRP="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_domain[[:blank:]]\+/      s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_BIT4="$(funcIPv4GetNetmaskBits "${NIC_MASK}")"
		 	NIC_NAME="ens160"
		 	NIC_MADR="$(LANG=C ip address show dev "${NIC_NAME}" 2> /dev/null | sed -n -e '/link\/ether/ s%.*link/ether \([[:graph:]]\+\) .*$%\1%p')"
		 	CON_NAME="ethernet_$(echo "${NIC_MADR}" | sed -n -e 's/://gp')_cable"
		 	echo "${PROG_NAME}: FIX_IPV4=${FIX_IPV4}"
		 	echo "${PROG_NAME}: NIC_IPV4=${NIC_IPV4}"
		 	echo "${PROG_NAME}: NIC_MASK=${NIC_MASK}"
		 	echo "${PROG_NAME}: NIC_GATE=${NIC_GATE}"
		 	echo "${PROG_NAME}: NIC_DNS4=${NIC_DNS4}"
		 	echo "${PROG_NAME}: NIC_WGRP=${NIC_WGRP}"
		 	echo "${PROG_NAME}: NIC_BIT4=${NIC_BIT4}"
		 	echo "${PROG_NAME}: NIC_NAME=${NIC_NAME}"
		 	echo "${PROG_NAME}: NIC_MADR=${NIC_MADR}"
		 	echo "${PROG_NAME}: CON_NAME=${CON_NAME}"
		
		 	#--------------------------------------------------------------------------
		 	if [ "${FIX_IPV4}" != "true" ]; then
		 		return
		 	fi
		 	# --- connman -------------------------------------------------------------
		 	if [ -d "${ROOT_DIRS}/etc/connman" ]; then
		 		echo "funcSetupNetwork: connman"
		 		mkdir -p "${ROOT_DIRS}/var/lib/connman/${CON_NAME}"
		 		cat <<- _EOT_ | sed 's/^ *//g' > "${ROOT_DIRS}/var/lib/connman/settings"
		 			[global]
		 			OfflineMode=false
		 			
		 			[Wired]
		 			Enable=true
		 			Tethering=false
		_EOT_
		 		if [ -n "${CON_NAME}" ]; then
		 			cat <<- _EOT_ | sed 's/^ *//g' > "${ROOT_DIRS}/var/lib/connman/${CON_NAME}/settings"
		 				[${CON_NAME}]
		 				Name=Wired
		 				AutoConnect=true
		 				Modified=
		 				IPv6.method=auto
		 				IPv6.privacy=preferred
		 				IPv6.DHCP.DUID=
		 				IPv4.method=manual
		 				IPv4.DHCP.LastAddress=
		 				IPv4.netmask_prefixlen=${NIC_BIT4}
		 				IPv4.local_address=${NIC_IPV4}
		 				IPv4.gateway=${NIC_GATE}
		 				Nameservers=${NIC_DNS4};127.0.0.1;::1;
		 				Domains=${NIC_WGRP};
		 				Timeservers=ntp.nict.jp;
		 				mDNS=true
		_EOT_
		 		fi
		 	fi
		 	# --- netplan -------------------------------------------------------------
		 	if [ -d "${ROOT_DIRS}/etc/netplan" ]; then
		 		echo "funcSetupNetwork: netplan"
		 		cat <<- _EOT_ > "${ROOT_DIRS}/etc/netplan/99-network-manager-static.yaml"
		 			network:
		 			  version: 2
		 			  ethernets:
		 			    "${NIC_NAME}":
		 			      dhcp4: false
		 			      addresses: [ "${NIC_IPV4}/${NIC_BIT4}" ]
		 			      gateway4: "${NIC_GATE}"
		 			      nameservers:
		 			          search: [ "${NIC_WGRP}" ]
		 			          addresses: [ "${NIC_DNS4}" ]
		 			      dhcp6: true
		 			      ipv6-privacy: true
		 _EOT_
		 	fi
		}
		
		# --- gdm3 --------------------------------------------------------------------
		funcChange_gdm3_configure () {
		 	echo "funcChange_gdm3_configure"
		 	if [ -f "${ROOT_DIRS}/etc/gdm3/custom.conf" ]; then
		 		sed -i.orig "${ROOT_DIRS}/etc/gdm3/custom.conf" \
		 		    -e '/WaylandEnable=false/ s/^#//'
		 	fi
		}
		
		# --- Main --------------------------------------------------------------------
		funcMain () {
		 	case "${DIST_NAME}" in
		 		debian )
		#			funcInstallPackages
		 			funcSetupNetwork
		#			funcChange_gdm3_configure
		 			;;
		 		ubuntu )
		 			funcInstallPackages
		 			funcSetupNetwork
		#			funcChange_gdm3_configure
		 			;;
		 	esac
		}
		
		 	funcMain
		# --- Termination -------------------------------------------------------------
		 	exit 0
		# --- EOF ---------------------------------------------------------------------
_EOT_SH_

	chmod 544 "${COMD_FILE}"
}

# --- make config file preseed ------------------------------------------------
function funcMake_conf_preseed () {
	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
#	declare -i I
#	declare -i J
	declare DIR_NAME
	declare BASE_NAME
	declare CONF_NAME="$1"
	declare DIR="$(echo "${CONF_NAME##*/}" | sed -n -e 's/^.*\(debian\|ubuntu\).*$/\1/p')"
	declare WRK_PATH
	declare WRK_STR
	declare INS_STR

	funcMake_preseed_sub_command "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg"
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}make preseed: ${TXT_BGREEN}${DIR}${TXT_RESET}"
#	if [[ -f "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg" ]]; then
		cp --preserve=timestamps --no-preserve=mode,ownership --backup "${CONF_NAME}" "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg"
		sed "${CONF_NAME}"                                                                     \
		    -e "s%/cdrom/preseed/%/hd-media/preseed/${DIR}/%g"                                 \
		    -e 's%\(d-i[[:blank:]]\+debian-installer/language\)[[:blank:]]\+.*$%\1 string ja%' \
		> "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg"
#	fi
	if [[ -f "./${WORK_DIRS}/img/preseed/${DIR}/preseed_sub_command.sh" ]]; then
		case "${DIR}" in
			debian )
				IFS= INS_STR=$(
					cat <<- '_EOT_'
						  d-i preseed/late_command string \\\
						      LANG=C /hd-media/preseed/debian/preseed_sub_command.sh;
_EOT_
				)
				IFS=${OLD_IFS}
				WRK_STR='d-i[[:blank:]]\+preseed\/late_command[[:blank:]]\+'
				sed -i "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg" \
				    -e "s%^[[:blank:]]\*\(${WRK_STR}\)%# \1%"          \
				    -e "/\(${WRK_STR}\)/i \\${INS_STR}"
				;;
			ubuntu )
				IFS= INS_STR=$(
					cat <<- '_EOT_'
						  d-i preseed/late_command string \\\
						      LANG=C /preseed/preseed_sub_command.sh;
_EOT_
				)
				IFS=${OLD_IFS}
				WRK_STR='d-i[[:blank:]]\+preseed\/late_command[[:blank:]]\+'
				sed -i "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg" \
				    -e "s%^[[:blank:]]\*\(${WRK_STR}\)%# \1%"          \
				    -e "/\(${WRK_STR}\)/i \\${INS_STR}"
				# -------------------------------------------------------------
				IFS= INS_STR=$(
					cat <<- '_EOT_'
						  ubiquity ubiquity/success_command string \\\
						      LANG=C /preseed/ubuntu/preseed_sub_command.sh 2>&1 | \\\
						      tee -a /target/var/log/installer_preseed_sub_command.log;
_EOT_
				)
				IFS=${OLD_IFS}
				WRK_STR='ubiquity[[:blank:]]\+ubiquity\/success_command[[:blank:]]\+'
				sed -i "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg" \
				    -e "s%^[[:blank:]]\*\(${WRK_STR}\)%# \1%"          \
				    -e "/\(${WRK_STR}\)/i \\${INS_STR}"
				;;
		esac
	fi
#	if [[ ! -f "./${WORK_DIRS}/img/preseed/${DIR}/preseed_old.cfg" ]]; then
		cp --preserve=timestamps --no-preserve=mode,ownership --backup "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg" "./${WORK_DIRS}/img/preseed/${DIR}/preseed_old.cfg"
		sed "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg"                   \
		    -e 's/bind9-utils/bind9utils/'                                    \
		    -e 's/bind9-dnsutils/dnsutils/'                                   \
		    -e '/d-i[[:blank:]]\+partman\/unmount_active/ s/^#/ /'            \
		    -e '/d-i[[:blank:]]\+partman\/early_command.*\\/,/exit/ s/^#/ /g' \
		> "./${WORK_DIRS}/img/preseed/${DIR}/preseed_old.cfg"
#	fi
	sed -i "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg"                   \
	    -e '/d-i[[:blank:]]\+partman\/early_command.*\\/,/[[:blank:]]fi;/ {' \
	    -e 's/^#/ /g' -e 's/\([[:blank:]]fi;\).*$/\1/''}'

	for WRK_PATH in \
	    "./${WORK_DIRS}/img/preseed/${DIR}/preseed.cfg"     \
	    "./${WORK_DIRS}/img/preseed/${DIR}/preseed_old.cfg"
	do
		DIR_NAME="${WRK_PATH%/*}"
		BASE_NAME="${WRK_PATH##*/}"
#		if [[ -f "${WRK_PATH}" ]] && [[ ! -f "${DIR_NAME}/${BASE_NAME/\./_server\.}" ]]; then
			cp --preserve=timestamps --no-preserve=mode,ownership --backup "${WRK_PATH}" "${DIR_NAME}/${BASE_NAME/\./_server\.}"
			sed "${WRK_PATH}"                                                                            \
			    -e '/d-i[[:blank:]]\+pkgsel\/include /,/^\(#\|[[:blank:]]*d-i \)/ {'                     \
			    -e '/^[[:blank:]]*isc-dhcp-server[[:blank:]]*/                             s/^ /#/'      \
			    -e '/^[[:blank:]]*minidlna[[:blank:]]*/                                    s/^ /#/'      \
			    -e '/^[[:blank:]]*apache2[[:blank:]]*/                                     s/^ /#/'      \
			    -e '/^[[:blank:]]*task-desktop[[:blank:]]*/                                s/^ /#/'      \
			    -e '/^[[:blank:]]*task-lxde-desktop[[:blank:]]*/                           s/^ /#/'      \
			    -e '/^[[:blank:]]*task-laptop[[:blank:]]*/                                 s/^ /#/'      \
			    -e '/^[[:blank:]]*task-japanese[[:blank:]]*/                               s/^ /#/'      \
			    -e '/^[[:blank:]]*task-japanese-desktop[[:blank:]]*/                       s/^ /#/'      \
			    -e '/^[[:blank:]]*ubuntu-desktop[[:blank:]]*/                              s/^ /#/'      \
			    -e '/^[[:blank:]]*ubuntu-gnome-desktop[[:blank:]]*/                        s/^ /#/'      \
			    -e '/^[[:blank:]]*language-pack-ja[[:blank:]]*/                            s/^ /#/'      \
			    -e '/^[[:blank:]]*language-pack-gnome-ja[[:blank:]]*/                      s/^ /#/'      \
			    -e '/^[[:blank:]]*fonts-noto[[:blank:]]*/                                  s/^ /#/'      \
			    -e '/^[[:blank:]]*ibus-mozc[[:blank:]]*/                                   s/^ /#/'      \
			    -e '/^[[:blank:]]*mozc-utils-gui[[:blank:]]*/                              s/^ /#/'      \
			    -e '/^[[:blank:]]*libreoffice-l10n-ja[[:blank:]]*/                         s/^ /#/'      \
			    -e '/^[[:blank:]]*libreoffice-help-ja[[:blank:]]*/                         s/^ /#/'      \
			    -e '/^[[:blank:]]*firefox-esr-l10n-ja[[:blank:]]*/                         s/^ /#/'      \
			    -e '/^[[:blank:]]*firefox-locale-ja[[:blank:]]*/                           s/^ /#/'      \
			    -e '/^[[:blank:]]*thunderbird[[:blank:]]*/                                 s/^ /#/'      \
			    -e '/^[[:blank:]]*thunderbird-l10n-ja[[:blank:]]*/                         s/^ /#/}' |   \
			sed -e '/^[[:blank:]]*d-i pkgsel\/include /,/^\(#\|[[:blank:]]*d-i \)/ {'                    \
			    -e '/^#/! {:l; s/\n\([[:blank:]]*[[:alnum:]].*\)[[:blank:]]\\\n#/\n\1\n#/; t; N; b l;}}' \
			> "${DIR_NAME}/${BASE_NAME/\./_server\.}"
#		fi
	done
}

# --- make config file nocloud ------------------------------------------------
function funcMake_conf_nocloud () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
#	declare -i I
#	declare -i J
	declare DIR
#	declare DIR_NAME
#	declare BASE_NAME
	declare CONF_NAME="$1"
	declare WRK_PATH

	DIR="$(echo "${CONF_NAME##*/}" | sed -n -e 's%^.*\(debian\|ubuntu\).*$%\1%p')"
#	if [[ ! -f "./${WORK_DIRS}/img/nocloud/${DIR}.desktop/user-data" ]]; then
		cp --preserve=timestamps --no-preserve=mode,ownership --backup "${CONF_NAME}" "./${WORK_DIRS}/img/nocloud/${DIR}.desktop/user-data"
#	fi
	touch -a "./${WORK_DIRS}/img/nocloud/${DIR}.desktop/meta-data"
	touch -a "./${WORK_DIRS}/img/nocloud/${DIR}.desktop/vendor-data"
	touch -a "./${WORK_DIRS}/img/nocloud/${DIR}.desktop/network-config"
	sed "./${WORK_DIRS}/img/nocloud/${DIR}.desktop/user-data"            \
	    -e '/^[[:blank:]]*- isc-dhcp-server[[:blank:]]*/        s/^ /#/' \
	    -e '/^[[:blank:]]*- minidlna[[:blank:]]*/               s/^ /#/' \
	    -e '/^[[:blank:]]*- apache2[[:blank:]]*/                s/^ /#/' \
	    -e '/^[[:blank:]]*- ubuntu-desktop[[:blank:]]*/         s/^ /#/' \
	    -e '/^[[:blank:]]*- ubuntu-gnome-desktop[[:blank:]]*/   s/^ /#/' \
	    -e '/^[[:blank:]]*- language-pack-ja[[:blank:]]*/       s/^ /#/' \
	    -e '/^[[:blank:]]*- language-pack-gnome-ja[[:blank:]]*/ s/^ /#/' \
	    -e '/^[[:blank:]]*- fonts-noto[[:blank:]]*/             s/^ /#/' \
	    -e '/^[[:blank:]]*- ibus-mozc[[:blank:]]*/              s/^ /#/' \
	    -e '/^[[:blank:]]*- mozc-utils-gui[[:blank:]]*/         s/^ /#/' \
	    -e '/^[[:blank:]]*- libreoffice-l10n-ja[[:blank:]]*/    s/^ /#/' \
	    -e '/^[[:blank:]]*- libreoffice-help-ja[[:blank:]]*/    s/^ /#/' \
	    -e '/^[[:blank:]]*- firefox-locale-ja[[:blank:]]*/      s/^ /#/' \
	    -e '/^[[:blank:]]*- thunderbird[[:blank:]]*/            s/^ /#/' \
	    -e '/^[[:blank:]]*- thunderbird-locale-ja[[:blank:]]*/  s/^ /#/' \
	> "./${WORK_DIRS}/img/nocloud/${DIR}.server/user-data"
	touch -a "./${WORK_DIRS}/img/nocloud/${DIR}.server/meta-data"
	touch -a "./${WORK_DIRS}/img/nocloud/${DIR}.server/vendor-data"
	touch -a "./${WORK_DIRS}/img/nocloud/${DIR}.server/network-config"
}

# --- make config file kickstart ----------------------------------------------
function funcMake_conf_kickstart () {
	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=()
	declare DIR
	declare DIR_NAME
	declare BASE_NAME
	declare CONF_NAME="$1"
	declare WRK_PATH
	declare WRK_TEXT
	declare -i VER_RHL=0
	declare -i VER_NUM=0
	declare ARC_NUM
	declare NET_DVD
	declare FLABEL

	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		DIR_NAME="${ARRAY_LINE[2]%/*}"
		BASE_NAME="${ARRAY_LINE[2]##*/}"
#		ARC_NUM="x86_64"
#		VER_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $2;}')
#		VER_RHL=${VER_NUM}
#		WRK_TEXT="${ARRAY_LINE[0]}"
		NET_DVD="${ARRAY_LINE[3]##*/}"
		FLABEL="$(LANG=C blkid -s LABEL "${ARRAY_LINE[3]}/${ARRAY_LINE[4]}" | awk -F '\"' '{print $2;}')"
		case "${ARRAY_LINE[0]}" in
			fedora       )
				ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $4;}')
#				NET_DVD=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $3;}')
				VER_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $5;}')
				VER_RHL=$((${VER_NUM} - 29))
				WRK_TEXT="${ARRAY_LINE[0]}"
				;;
			centos       )
				if [[ ${VER_NUM} -eq 8 ]]; then
					ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $4;}')
				else
					ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $5;}')
				fi
#				NET_DVD=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $6;}')
				VER_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $3;}')
				VER_RHL=${VER_NUM}
				WRK_TEXT="${ARRAY_LINE[0]} .*${VER_NUM}"
				;;
			almalinux    )
				ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $4;}')
#				NET_DVD=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $5;}')
				VER_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $2;}')
				VER_RHL=${VER_NUM}
				WRK_TEXT="${ARRAY_LINE[0]}"
				;;
			rockylinux   )
				if [[ ${VER_NUM} -eq 8 ]]; then
					ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $3;}')
#					NET_DVD=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $4;}')
				else
					ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $4;}')
#					NET_DVD=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $5;}')
				fi
				VER_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $2;}')
				VER_RHL=${VER_NUM}
				WRK_TEXT="${ARRAY_LINE[0]}"
				;;
			miraclelinux )
				if [[ "${BASE_NAME}" =~ .*minimal.* ]]; then
					ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $6;}')
				else
					ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $5;}')
				fi
#				NET_DVD=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $4;}')
				VER_NUM=$(echo "${BASE_NAME}" | awk -F '[-.]' '{print $2;}')
				VER_RHL=${VER_NUM}
				WRK_TEXT="${ARRAY_LINE[0]}"
				;;
			*            )
				continue
				;;
		esac
		WRK_PATH="./${WORK_DIRS}/img/kickstart/ks_${ARRAY_LINE[0]}-${VER_NUM}_${NET_DVD}.cfg"
		cp --preserve=timestamps --no-preserve=mode,ownership --backup "${CONF_NAME}" "${WRK_PATH}"
		sed -i "${WRK_PATH}"                              \
		    -e "s/_HOSTNAME_/${ARRAY_LINE[0]}/"           \
		    -e '/^%post/,/^%end/                      { ' \
		    -e '/#dnf -y install/    s/^#//             ' \
		    -e '/#rpm --import/      s/^#//             ' \
		    -e "s/\$releasever/${VER_RHL}/g             " \
		    -e "s/\$basearch/${ARC_NUM}/g             } " \
		    -e "/harddrive/ s/\$label/${FLABEL}/"
		case "${ARRAY_LINE[3]##*/}" in
			*dvd* )
				sed -i "${WRK_PATH}"                              \
				    -e '/^cdrom/      s/^/#/'                     \
				    -e '/^#harddrive/ s/^#//'                     \
				    -e "/^#.*(${WRK_TEXT}).*$/,/^$/           { " \
				    -e '/^url[[:blank:]]\+/  s/^/#/             ' \
				    -e '/^repo[[:blank:]]\+/ s/^/#/           } '
				;;
			*   )
				sed -i "${WRK_PATH}"                              \
				    -e '/^cdrom/     s/^/#/'                      \
				    -e '/^harddrive/ s/^/#/'                      \
				    -e "/^#.*(${WRK_TEXT}).*$/,/^$/           { " \
				    -e '/^#url[[:blank:]]\+/  s/^#//            ' \
				    -e '/^#repo[[:blank:]]\+/ s/^#//          } '
				;;
		esac
		case "${ARRAY_LINE[0]}" in
			fedora       )
				sed -i "${WRK_PATH}"                              \
				    -e "/^#.*(${WRK_TEXT}).*$/,/^$/           { " \
				    -e '/^#repo[[:blank:]]\+/ s/^#//          } ' \
				    -e '/%anaconda/,/%end/ {/^#/! s/^/#/g}'
				;;
			centos       )
				sed -i "${WRK_PATH}"                              \
				    -e "/^#.*(${WRK_TEXT}).*$/,/^$/           { " \
				    -e '/^#repo[[:blank:]]\+/ s/^#//          } '
				;;
			almalinux    )
				sed -i "${WRK_PATH}"                              \
				    -e '/%anaconda/,/%end/ {/^#/! s/^/#/g}'
				;;
			rockylinux   )
				sed -i "${WRK_PATH}"                              \
				    -e '/%anaconda/,/%end/ {/^#/! s/^/#/g}'
				;;
			miraclelinux )
				sed -i "${WRK_PATH}"                              \
				    -e "/^#.*(${WRK_TEXT}).*$/,/^$/           { " \
				    -e "s/\$releasever/${VER_NUM}/g             " \
				    -e "s/\$basearch/${ARC_NUM}/g             } "
				;;
			*            )
				;;
		esac
		if [[ ${VER_RHL} -le 8 ]]; then
			declare TMZONE=$(awk '$1=="timezone" {print $2;}' "${WRK_PATH}")
			declare NTPSVR=$(awk -F '[ \t=]' '$1=="timesource" {print $3;}' "${WRK_PATH}")
			sed -i "${WRK_PATH}"                                                      \
			    -e "s~^\(timezone\).*\$~\1 ${TMZONE} --isUtc --ntpservers=${NTPSVR}~" \
			    -e '/timesource/d'
		fi
	done
}

# --- make config file yast ---------------------------------------------------
function funcMake_conf_yast () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=()
#	declare DIR
	declare DIR_NAME
	declare BASE_NAME
	declare CONF_NAME="$1"
	declare LABEL

	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		DIR_NAME="${ARRAY_LINE[2]%/*}"
		BASE_NAME="${ARRAY_LINE[2]##*/}"
		case "${ARRAY_LINE[1]}" in
			leap       )
#				WRK_PATH="./${WORK_DIRS}/img/autoyast/autoinst_leap.xml"
#				if [[ -f "${WRK_PATH}" ]]; then
#					continue
#				fi
#				cp --preserve=timestamps --no-preserve=mode,ownership --backup "${CONF_NAME}" "${WRK_PATH}"
				VER_NUM=$(echo "${BASE_NAME}" | awk -F '[-]' '{print $3;}')
				ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-]' '{print $5;}')
				WRK_PATH="./${WORK_DIRS}/img/autoyast/autoinst_leap_${VER_NUM}.xml"
				cp --preserve=timestamps --no-preserve=mode,ownership --backup "${CONF_NAME}" "${WRK_PATH}"
				sed -i "${WRK_PATH}"                                          \
				    -e "/<media_url>/ s~/\(leap\)/[0-9.]*/~/\1/${VER_NUM}/~g" \
				    -e "/<media_url>/ s~/\(leap\)/[0-9.]*/~/\1/${VER_NUM}/~g" \
				    -e 's~\(<product>\).*\(</product>\)~\1Leap\2~'            \
				    -e '/<add_on_products .*>/,/<\/add_on_products>/      { ' \
				    -e '/<!-- leap/d                                        ' \
				    -e '/leap -->/d                                       } '
				;;
			tumbleweed )
#				WRK_PATH="./${WORK_DIRS}/img/autoyast/autoinst_tumbleweed.xml"
#				if [[ -f "${WRK_PATH}" ]]; then
#					continue
#				fi
#				cp --preserve=timestamps --no-preserve=mode,ownership --backup "${CONF_NAME}" "${WRK_PATH}"
				VER_NUM=""
				ARC_NUM=$(echo "${BASE_NAME}" | awk -F '[-]' '{print $4;}')
				WRK_PATH="./${WORK_DIRS}/img/autoyast/autoinst_tumbleweed.xml"
				cp --preserve=timestamps --no-preserve=mode,ownership --backup "${CONF_NAME}" "${WRK_PATH}"
				sed -i "${WRK_PATH}"                                          \
				    -e '/<media_url>/ s~/leap/[0-9.]*/~/tumbleweed/~g'        \
				    -e '/<media_url>/ s~/leap/[0-9.]*/~/tumbleweed/~g'        \
				    -e 's~\(<product>\).*\(</product>\)~\1openSUSE\2~'        \
				    -e 's/eth0/ens160/g'                                      \
				    -e '/<add_on_products .*>/,/<\/add_on_products>/      { ' \
				    -e '/<!-- tumbleweed/d                                  ' \
				    -e '/tumbleweed -->/d                                 } '
				;;
		esac
		case "${ARRAY_LINE[1]}" in
			leap       | \
			tumbleweed )
				case "${ARRAY_LINE[1]}" in
					*DVD* )
						sed -i ${WRK_PATH}                                        \
						    -e '/<image_installation t="boolean">/ s/false/true/'
						;;
					* )
						sed -i ${WRK_PATH}                                        \
						    -e '/<image_installation t="boolean">/ s/true/false/'
						;;
				esac
				;;
		esac
	done
}

# --- make config file --------------------------------------------------------
function funcMake_conf () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i RET_CD=0
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${CONFIG_FILE[@]}")
	declare -a ARRAY_LINE=()
	declare DIR
	declare DIR_NAME
	declare BASE_NAME

	#idx: value
	#  0: distribution
	#  1: codename
	#  2: download URL
	#  3: directory
	#  4: alias
	#  5: definition file
	#  6: release
	#  7: support
	#  8: status
	#  9: memo1
	# 10: memo2

	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		DIR_NAME="${ARRAY_LINE[2]%/*}"
		BASE_NAME="${ARRAY_LINE[2]##*/}"
		if [[ ! -f "${ARRAY_LINE[3]}/${BASE_NAME}" ]]; then
			continue
		fi
		case "${BASE_NAME}" in
			preseed_debian.cfg       | \
			preseed_ubuntu.cfg       )
				funcMake_conf_preseed "${ARRAY_LINE[3]}/${BASE_NAME}"
				;;
			nocloud-ubuntu-user-data )
				funcMake_conf_nocloud "${ARRAY_LINE[3]}/${BASE_NAME}"
				;;
			kickstart_common.cfg     )
				funcMake_conf_kickstart "${ARRAY_LINE[3]}/${BASE_NAME}"
				;;
			yast_opensuse.xml        )
				funcMake_conf_yast "${ARRAY_LINE[3]}/${BASE_NAME}"
				;;
			*                        )
				;;
		esac
	done
}

# --- copy bld,cfg initrd -----------------------------------------------------
function funcCopy_initrd () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i I
#	declare -i J
#	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=("$@")
	declare DIR_NAME
#	declare BASE_NAME
#	declare -a MODULE_LIST=("${ADD_PACKAGE_LIST[@]}")
#	declare MODULE_LINE
	declare -r DIR_SECT="$(echo "${ARRAY_LINE[4],,}" | sed -n -e 's/^.*\(live\|dvd\|netinst\|netboot\|server\|boot\|minimal\|net\|rtm\|legacy\|desktop\).*$/\1/p')"
	declare -r DIR_CODE="${ARRAY_LINE[0]}.${ARRAY_LINE[1]%%.*}"
	declare -r DIR_DIST="${DIR_CODE}.${DIR_SECT:-desktop}"
#	declare -a DIR_LIST=()
	declare DIR_DEST
#	declare DIR_DIRS
	declare DIR_PATH
#	declare DIR_FILE
#	declare DIR_WORK
#	declare DIR_PACK

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}copy  initrd: ${TXT_BGREEN}${DIR_DIST}${TXT_RESET}"
	# --- mount -----------------------------------------------------------
#	funcPrintf "${TXT_BLACK}${TXT_BGREEN}mount    iso: %s${TXT_RESET}\n" "${${ARRAY_LINE[3]}/${ARRAY_LINE[4]}}"
	mount -r -o loop "${ARRAY_LINE[3]}/${ARRAY_LINE[4]}" "./${WORK_DIRS}/mnt/"
	# --- copy initrd and vmlinuz [iso -> bld] ----------------------------
	DIR_LIST=()
	if [[ -d "./${WORK_DIRS}/mnt/install/."     ]]; then DIR_LIST+=("./${WORK_DIRS}/mnt/install/")    ; fi
	if [[ -d "./${WORK_DIRS}/mnt/install.amd/". ]]; then DIR_LIST+=("./${WORK_DIRS}/mnt/install.amd/"); fi
	if [[ -d "./${WORK_DIRS}/mnt/live/."        ]]; then DIR_LIST+=("./${WORK_DIRS}/mnt/live/")       ; fi
	if [[ -d "./${WORK_DIRS}/mnt/casper/."      ]]; then DIR_LIST+=("./${WORK_DIRS}/mnt/casper/")     ; fi
	for DIR_PATH in $(find "${DIR_LIST[@]}" \( -name 'initrd*' -o  -name 'vmlinuz*' \) \( -type f -o -type l \))
	do
		funcPrintf "copy  initrd: %-24.24s : %s\n" "${DIR_DIST}" "${DIR_PATH#*/mnt/}"
		DIR_NAME="${DIR_PATH%/*}"
		DIR_DEST="./${WORK_DIRS}/bld/${DIR_DIST}/${DIR_NAME#\./"${WORK_DIRS}"/mnt/}"
		if [[ ! -d "${DIR_DEST}/." ]]; then
			mkdir -p "${DIR_DEST}"
		fi
		cp --preserve=timestamps --no-preserve=mode,ownership "${DIR_PATH}" "${DIR_DEST}/"
	done
	# --- umount ----------------------------------------------------------
#	funcPrintf "${TXT_BLACK}${TXT_BGREEN}umount   iso: %s${TXT_RESET}\n" "${${ARRAY_LINE[3]}/${ARRAY_LINE[4]}}"
	umount "./${WORK_DIRS}/mnt/"
}

# --- unzip bld,cfg initrd ----------------------------------------------------
function funcUnzip_initrd () {
#	declare -r OLD_IFS="${IFS}"
#	declare -i I
#	declare -i J
#	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=("$@")
#	declare DIR_NAME
#	declare BASE_NAME
#	declare -a MODULE_LIST=("${ADD_PACKAGE_LIST[@]}")
#	declare MODULE_LINE
	declare -r DIR_SECT="$(echo "${ARRAY_LINE[4],,}" | sed -n -e 's/^.*\(live\|dvd\|netinst\|netboot\|server\|boot\|minimal\|net\|rtm\|legacy\|desktop\).*$/\1/p')"
	declare -r DIR_CODE="${ARRAY_LINE[0]}.${ARRAY_LINE[1]%%.*}"
	declare -r DIR_DIST="${DIR_CODE}.${DIR_SECT:-desktop}"
#	declare -a DIR_LIST=()
	declare DIR_DEST
	declare DIR_DIRS
	declare DIR_PATH
#	declare DIR_FILE
	declare DIR_WORK
#	declare DIR_PACK
	declare DIR_IRAM
	declare DIR_VLNZ
	declare DIR_KVER
	declare DIR_MODU
#	declare -a WEB_HEAD=()
	declare -a WEB_PAGE=()
	declare WEB_DISP

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}unzip initrd: ${TXT_BGREEN}${DIR_DIST}${TXT_RESET}"
	# --- unzip initrd [bld,cfg > ram] ----------------------------------------
	for DIR_IRAM in $(find "./${WORK_DIRS}/bld/${DIR_DIST}/" -name 'initrd*' \( -type f -o -type l \) | sort)
	do
		case "${DIR_IRAM}" in
			*/initrd*- ) DIR_VLNZ="${DIR_IRAM//initrd*-/vmlinuz-}";;
			*          ) DIR_VLNZ="${DIR_IRAM//initrd*/vmlinuz}"  ;;
		esac
		if [[ ! -f "${DIR_VLNZ}" ]]; then
			continue
		fi
		DIR_KVER="$(file "${DIR_VLNZ}" | sed -n -e 's/^.*[[:blank:]]version[[:blank:]]\([[:graph:]]\+\)[[:blank:]].*$/\1/p')"
		DIR_DEST="${DIR_IRAM/bld/ram}"
		if [[ ! -d "${DIR_DEST}/." ]]; then
			mkdir -p "${DIR_DEST}"
		fi
#		if [[ "${DIR_DEST}" =~ .*/install.*/.* ]]; then
#			case "${DIR_CODE}" in
#				ubuntu.bionic  ) DIR_IRAM="./${WORK_DIRS}/cfg/${DIR_CODE}-updates/${DIR_IRAM#*/install*/}";;
#				*              ) DIR_IRAM="./${WORK_DIRS}/cfg/${DIR_CODE}/${DIR_IRAM#*/install*/}";;
#			esac
#			case "${DIR_IRAM}" in
#				*/initrd*- ) DIR_VLNZ="${DIR_IRAM//initrd*-/vmlinuz-}";;
#				*          ) DIR_VLNZ="${DIR_IRAM//initrd*/vmlinuz}"  ;;
#			esac
#			DIR_WORK="$(file "${DIR_VLNZ}" | sed -n -e 's/^.*[[:blank:]]version[[:blank:]]\([[:graph:]]\+\)[[:blank:]].*$/\1/p')"
#			if [[ "${DIR_KVER}" != "${DIR_WORK}" ]]; then
#				funcPrintf "unmatch kver: %-24.24s : %s\n" "unmatch kernel ver." "${DIR_IRAM#*/cfs/}"
#				case "${DIR_CODE}" in
#					debian.testing )
#						DIR_IRAM="./${WORK_DIRS}/cfg/${DIR_CODE}.daily/${DIR_IRAM#*/${DIR_CODE}/}"
#						case "${DIR_IRAM}" in
#							*/initrd*- ) DIR_VLNZ="${DIR_IRAM//initrd*-/vmlinuz-}";;
#							*          ) DIR_VLNZ="${DIR_IRAM//initrd*/vmlinuz}"  ;;
#						esac
#						DIR_WORK="$(file "${DIR_VLNZ}" | sed -n -e 's/^.*[[:blank:]]version[[:blank:]]\([[:graph:]]\+\)[[:blank:]].*$/\1/p')"
#						;;
#				esac
#			fi
#			if [[ -n "${DIR_WORK}" ]] && [[ "${DIR_KVER}" != "${DIR_WORK}" ]]; then
#				funcPrintf "unmatch kver: %-24.24s : %s\n" "unmatch kernel ver." "${DIR_IRAM#*/cfg/}"
#				funcPrintf "unmatch kver: %-24.24s : %s\n" "unmatch kernel ver." "${DIR_KVER} != ${DIR_WORK}"
#			fi
#		fi
#		if [[ ! -f "${DIR_IRAM}" ]]; then
#			funcPrintf "skip  initrd: %-24.24s : %s\n" "skip   initramfs" "${DIR_IRAM#*/${DIR_DIST}/}"
#			continue
#		fi
		funcPrintf "upac  initrd: %-24.24s : %s\n" "unzip initramfs" "${DIR_DEST#*/${DIR_DIST}/}"
		unmkinitramfs "${DIR_IRAM}" "${DIR_DEST}/" 2>/dev/null
		DIR_DIRS="${DIR_DEST}"
		if [[ -d "${DIR_DIRS}/main/." ]]; then
			DIR_DIRS+="/main"
		fi
		DIR_WORK=""
		DIR_MODU=""
		if [[ -d "${DIR_DIRS}/lib/modules/." ]]; then
			DIR_WORK="$(ls -r "${DIR_DIRS}/lib/modules/" | head -n 1)"
			DIR_MODU="${DIR_DIRS}/lib/modules/${DIR_KVER}"
		fi
		funcPrintf "upac  initrd: %-24.24s : %s\n" "get kernel version" "${DIR_KVER}"
		if [[ -n "${DIR_WORK}" ]] && [[ "${DIR_KVER}" != "${DIR_WORK}" ]]; then
			funcPrintf "unmatch kver: %-24.24s : %s\n" "unmatch kernel ver." "${DIR_WORK}"
		fi
	done
}

# --- get module status -------------------------------------------------------
function funcGetModuleStatus () {
	declare -r OLD_IFS="${IFS}"
	declare -r DIR_DEST="$1"
	declare -r DIR_PACK="$2"
	declare -r STR_LINE="$3"
	declare    STR_STAT=""

	IFS=$'\n'
	for STR_STAT in $(sed -n -e "/^Package: ${DIR_PACK}$/,/^$/p" "${DIR_DEST}/var/lib/dpkg/status")
	do
		if [[ "${STR_LINE%% *}" = "${STR_STAT%% *}" ]]; then
			echo "${STR_STAT}"
			return
		fi
	done
	echo "${STR_LINE}"
	IFS="${OLD_IFS}"
}

# --- change status file ------------------------------------------------------
function funcChangeStatusFile () {
	declare -r    OLD_IFS="${IFS}"
	declare -i I
	declare -r    DIR_DEST="$1"
	declare -r    DIR_DIRS="$2"
	declare -r -a DIR_LIST=($(find "${DIR_DIRS}" -name 'Packages' \( -type f -o -type l \)))
	declare    -a STR_LIST=()

	IFS=$'\n'
	if [[ ! -f "${DIR_DEST}/var/lib/dpkg/status" ]] || [[ ${#DIR_LIST[@]} -le 0 ]]; then
		return
	fi
	for DIR_PACK in $(sed -n -e '/^Package:/ s/^.* \(.*\)$/\1/gp' "${DIR_DEST}/var/lib/dpkg/status")
	do
#		funcPrintf "dpkg  update: %-24.24s : %s\n" "Packages -> status" "${DIR_PACK}"
		for STR_LINE in $(sed -n -e "/^Package: ${DIR_PACK}$/,/^$/p" "${DIR_LIST[@]}")
		do
			case "${STR_LINE}" in
				Filename:*       | \
				Size:*           | \
				Kernel-Version:* | \
				SHA256:*         | \
				MD5sum:*         | \
				Description-md5* )
					continue
					;;
				Package:* )
					STR_LINE="$(funcGetModuleStatus "${DIR_DEST}" "${DIR_PACK}" "${STR_LINE}")"
					STR_LIST+=("${STR_LINE}")
					STR_LINE="$(funcGetModuleStatus "${DIR_DEST}" "${DIR_PACK}" "Status: install ok unpacked")"
					;;
				* )
					STR_LINE="$(funcGetModuleStatus "${DIR_DEST}" "${DIR_PACK}" "${STR_LINE}")"
					;;
			esac
			STR_LIST+=("${STR_LINE}")
		done
		STR_LIST+=("")
	done

	for I in "${!STR_LIST[@]}"
	do
		echo "${STR_LIST[${I}]}"
	done > "${DIR_DEST}/var/lib/dpkg/status.work"
	IFS="${OLD_IFS}"
}

# --- add module --------------------------------------------------------------
function funcAdd_module () {
#	declare -r -a KERNEL_LIST=(              \
#		"kernel/crypto"                      \
#		"kernel/drivers/ata"                 \
#		"kernel/drivers/base"                \
#		"kernel/drivers/block"               \
#		"kernel/drivers/char"                \
#		"kernel/drivers/md"                  \
#		"kernel/drivers/message"             \
#		"kernel/drivers/misc"                \
#		"kernel/drivers/mmc"                 \
#		"kernel/drivers/media"               \
#		"kernel/drivers/nvme"                \
#		"kernel/drivers/scsi"                \
#		"kernel/drivers/usb"                 \
#		"kernel/fs/exfat"                    \
#		"kernel/fs/ext4"                     \
#		"kernel/fs/fat"                      \
#		"kernel/fs/fuse"                     \
#		"kernel/fs/fuse3"                    \
#		"kernel/fs/jbd2"                     \
#		"kernel/fs/nls"                      \
#		"kernel/fs/ntfs"                     \
#		"kernel/fs/ntfs3"                    \
#		"kernel/lib"                         \
#	)

	declare -r -a KERNEL_LIST=(              \
		"kernel/crypto"                      \
		"kernel/drivers/acpi"                \
		"kernel/drivers/ata"                 \
		"kernel/drivers/base"                \
		"kernel/drivers/bcma"                \
		"kernel/drivers/block"               \
		"kernel/drivers/bus"                 \
		"kernel/drivers/char"                \
		"kernel/drivers/clk"                 \
		"kernel/drivers/dax"                 \
		"kernel/drivers/dca"                 \
		"kernel/drivers/dma"                 \
		"kernel/drivers/extcon"              \
		"kernel/drivers/firewire"            \
		"kernel/drivers/fpga"                \
		"kernel/drivers/gpio"                \
		"kernel/drivers/gpu"                 \
		"kernel/drivers/hid"                 \
		"kernel/drivers/hv"                  \
		"kernel/drivers/i2c"                 \
		"kernel/drivers/iio"                 \
		"kernel/drivers/infiniband"          \
		"kernel/drivers/input"               \
		"kernel/drivers/iommu"               \
		"kernel/drivers/leds"                \
		"kernel/drivers/mcb"                 \
		"kernel/drivers/md"                  \
		"kernel/drivers/media"               \
		"kernel/drivers/message"             \
		"kernel/drivers/mfd"                 \
		"kernel/drivers/misc"                \
		"kernel/drivers/mmc"                 \
		"kernel/drivers/mtd"                 \
		"kernel/drivers/mux"                 \
		"kernel/drivers/net"                 \
		"kernel/drivers/ntb"                 \
		"kernel/drivers/nvdimm"              \
		"kernel/drivers/nvme"                \
		"kernel/drivers/parport"             \
		"kernel/drivers/pci"                 \
		"kernel/drivers/pcmcia"              \
		"kernel/drivers/phy"                 \
		"kernel/drivers/pinctrl"             \
		"kernel/drivers/platform"            \
		"kernel/drivers/power"               \
		"kernel/drivers/pwm"                 \
		"kernel/drivers/regulator"           \
		"kernel/drivers/reset"               \
		"kernel/drivers/rpmsg"               \
		"kernel/drivers/rtc"                 \
		"kernel/drivers/scsi"                \
		"kernel/drivers/siox"                \
		"kernel/drivers/slimbus"             \
		"kernel/drivers/spi"                 \
		"kernel/drivers/spmi"                \
		"kernel/drivers/ssb"                 \
		"kernel/drivers/target"              \
		"kernel/drivers/thunderbolt"         \
		"kernel/drivers/ufs"                 \
		"kernel/drivers/uio"                 \
		"kernel/drivers/usb"                 \
		"kernel/drivers/vfio"                \
		"kernel/drivers/vhost"               \
		"kernel/drivers/video"               \
		"kernel/drivers/virtio"              \
		"kernel/drivers/xen"                 \
		"kernel/fs/btrfs"                    \
		"kernel/fs/cifs"                     \
		"kernel/fs/exfat"                    \
		"kernel/fs/f2fs"                     \
		"kernel/fs/fat"                      \
		"kernel/fs/fscache"                  \
		"kernel/fs/fuse"                     \
		"kernel/fs/isofs"                    \
		"kernel/fs/jfs"                      \
		"kernel/fs/lockd"                    \
		"kernel/fs/netfs"                    \
		"kernel/fs/nfs"                      \
		"kernel/fs/nfs_common"               \
		"kernel/fs/nls"                      \
		"kernel/fs/ntfs"                     \
		"kernel/fs/ntfs3"                    \
		"kernel/fs/overlayfs"                \
		"kernel/fs/reiserfs"                 \
		"kernel/fs/smbfs_common"             \
		"kernel/fs/udf"                      \
		"kernel/fs/xfs"                      \
		"kernel/lib"                         \
	)

	declare -r -a REMOVE_LIST=(                              \
#		"bin/cdrom-checker"                                  \ #
#		"usr/lib/debian-installer/retriever/media-retriever" \ #
#		"usr/lib/finish-install.d/15cdrom-detect"            \ #
#		"var/lib/dpkg/info/cdrom-checker.postinst"           \ #
#		"var/lib/dpkg/info/cdrom-checker.templates"          \ #
		"var/lib/dpkg/info/cdrom-detect.postinst"            \ 
#		"var/lib/dpkg/info/cdrom-detect.templates"           \ #
#		"var/lib/dpkg/info/load-cdrom.postinst"              \ #
#		"var/lib/dpkg/info/load-cdrom.templates"             \ #
#		"var/lib/dpkg/info/media-retriever.templates"        \ #
	)

	declare -r OLD_IFS="${IFS}"
	declare -i I
#	declare -i J
#	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=("$@")
	declare DIR_NAME
	declare BASE_NAME
	declare -a MODULE_LIST=("${KERNEL_LIST[@]}")
	declare MODULE_LINE
	declare -r DIR_SECT="$(echo "${ARRAY_LINE[4],,}" | sed -n -e 's/^.*\(live\|dvd\|netinst\|netboot\|server\|boot\|minimal\|net\|rtm\|legacy\|desktop\).*$/\1/p')"
	declare -r DIR_CODE="${ARRAY_LINE[0]}.${ARRAY_LINE[1]%%.*}"
	declare -r DIR_DIST="${DIR_CODE}.${DIR_SECT:-desktop}"
	declare -a DIR_LIST=()
	declare DIR_DEST
#	declare DIR_EXTE
	declare DIR_IRAM
	declare DIR_VLNZ
	declare DIR_DIRS
	declare DIR_PATH
	declare DIR_FILE
	declare DIR_WORK
	declare DIR_PACK
	declare DIR_KVER
	declare DIR_MODU
	declare -a PACKAGE_LIST=()

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}upac  module: ${TXT_BGREEN}${DIR_DIST}${TXT_RESET}"
	# --- add module [deb,opt > ram] ------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}add  kmodule: ${TXT_BGREEN}${DIR_DIST}${TXT_RESET}"
	for DIR_DEST in $(find "./${WORK_DIRS}/ram/${DIR_DIST}" -name 'initrd*' -type d | sort)
	do
		DIR_IRAM="${DIR_DEST}"
		if [[ -d "${DIR_DEST}/main/." ]]; then
			DIR_DEST+="/main"
		fi
		if [[ ! -d "${DIR_DEST}/lib/modules/." ]]; then
			funcPrintf "skip kmodule: %-24.24s : %s\n" "not exist" "${DIR_DEST#*/${DIR_DIST}/}/lib/modules/."
			continue
		fi
		DIR_WORK="${DIR_IRAM/\/ram\//\/bld\/}"
		case "${DIR_WORK}" in
			*/initrd*- ) DIR_VLNZ="${DIR_WORK//initrd*-/vmlinuz-}";;
			*          ) DIR_VLNZ="${DIR_WORK//initrd*/vmlinuz}"  ;;
		esac
#		DIR_VLNZ="$(find "${DIR_WORK%/*}" -maxdepth 1 -name 'vmlinuz*' \( -type f -o -type l \))"
		if [[ -z "${DIR_VLNZ}" ]] || [[ ! -f "${DIR_VLNZ}" ]]; then
			funcPrintf "skip kmodule: %-24.24s : %s\n" "not exist" "${DIR_VLNZ#*/bld/}"
			continue
		fi
#		DIR_KVER="$(file "${DIR_VLNZ}" | sed -n -e 's/^.*[[:blank:]]version[[:blank:]]\([[:graph:]]\+\)[[:blank:]].*$/\1/p')"
#		if [[ -z "${DIR_KVER}" ]]; then
#			funcPrintf "skip kmodule: %-24.24s : %s\n" "not get kernel version" "${DIR_VLNZ#*/bld/}"
#			continue
#		fi
		DIR_KVER="$(ls -r "${DIR_DEST}/lib/modules/" | head -n 1)"
		DIR_MODU="${DIR_DEST}/lib/modules/${DIR_KVER}"
		funcPrintf "copy kmodule: %-24.24s : %s\n" "get kernel version" "${DIR_KVER}"
		# --- linux image unzip [deb > pac] -----------------------------------
		DIR_WORK=""
		for DIR_FILE in "linux-"{image,modules,modules-extra}"-${DIR_KVER}_*_"${ARC_TYPE}.{udeb,deb}
		do
			if [[ -n "${DIR_WORK}" ]]; then
				DIR_WORK+=" -o "
			fi
			DIR_WORK+="-name "${DIR_FILE}
		done
		for DIR_PATH in $(find "./${WORK_DIRS}/deb/${DIR_CODE}" "./${WORK_DIRS}/deb/${DIR_DIST}" \( ${DIR_WORK} \) \( -type f -o -type l \))
		do
#			if [[ -d "./${WORK_DIRS}/pac/${DIR_DIST}/${DIR_KVER}/." ]]; then
#				funcPrintf "skip lnx img: %-24.24s : %s\n" "${DIR_DIST}" "${DIR_PATH##*/}"
#				continue
#			fi
			funcPrintf "upac lnx img: %-24.24s : %s\n" "${DIR_DIST}" "${DIR_PATH##*/}"
			mkdir -p "./${WORK_DIRS}/pac/${DIR_DIST}/${DIR_KVER}"
			dpkg -x "${DIR_PATH}" "./${WORK_DIRS}/pac/${DIR_DIST}/${DIR_KVER}/"
		done
		# --- add kernel module -----------------------------------------------
		funcPrintf "${TXT_BLACK}${TXT_BYELLOW}add  kmodule: ${TXT_BGREEN}${DIR_DEST}${TXT_RESET}"
		if [[ ! -d "${DIR_DEST}/var/lib/dpkg/." ]]; then
			mkdir -p "${DIR_DEST}/var/lib/dpkg"
		fi
		if [[ ! -f "${DIR_DEST}/var/lib/dpkg/status" ]]; then
			touch "${DIR_DEST}/var/lib/dpkg/status"
		fi
		for MODULE_LINE in "${MODULE_LIST[@]}"
		do
			DIR_PACK="./${WORK_DIRS}/pac/${DIR_DIST}/${DIR_KVER}/lib/modules/${DIR_KVER}/${MODULE_LINE}"
			if [[ ! -d "${DIR_PACK}/." ]]; then
				funcPrintf "skip kmodule: %-24.24s : %s\n" "${DIR_DIST}" "${MODULE_LINE}"
				continue
			fi
			funcPrintf "copy kmodule: %-24.24s : %s\n" "${DIR_DIST}" "${MODULE_LINE}"
			if [[ ! -d "${DIR_MODU}/${MODULE_LINE}/." ]]; then
				mkdir -p "${DIR_MODU}/${MODULE_LINE}"
			fi
			cp --archive --backup "${DIR_PACK}/." "${DIR_MODU}/${MODULE_LINE}/"
		done
		# --- dpkg db update --------------------------------------------------
		funcPrintf "dpkg  update: %-24.24s : %s\n" "Packages -> status" "${DIR_DEST#*/${DIR_DIST}/}/var/lib/dpkg/status"
		DIR_DIRS="./${WORK_DIRS}/deb/${DIR_CODE}"
		funcChangeStatusFile "${DIR_DEST}" "${DIR_DIRS}"
		if [[ -f "${DIR_DEST}/var/lib/dpkg/status.work" ]]; then
			cp --archive --backup "${DIR_DEST}/var/lib/dpkg/status" "${DIR_DEST}/var/lib/dpkg/status~"
			cat "${DIR_DEST}/var/lib/dpkg/status.work" > "${DIR_DEST}/var/lib/dpkg/status"
			rm "${DIR_DEST}/var/lib/dpkg/status.work"
		fi
		# --- add package list ------------------------------------------------
		DIR_PACK=""
		for DIR_FILE in "linux-"{image,modules,modules-extra}"-*-"{${ARC_TYPE},generic}"_*_"${ARC_TYPE}.{udeb,deb}
		do
			DIR_PACK+=" -a -not -name "${DIR_FILE}
		done
		PACKAGE_LIST=()
		for DIR_PATH in $(find "${DIR_DIRS}" \( \( -name '*.deb' -o -name '*.udeb' \) ${DIR_PACK} \) \( -type f -o -type l \) | sort -u)
		do
			DIR_NAME="${DIR_PATH%/*}"
			BASE_NAME="${DIR_PATH##*/}"
			# --- skip registered modules -------------------------------------
			if [[ -n "$(sed -n "/^Package: ${BASE_NAME%%_*}$/p" "${DIR_DEST}/var/lib/dpkg/status")" ]]; then
				funcPrintf "skip    pack: %-24.24s : %s\n" "skip inst  package" "${BASE_NAME}"
				continue
			fi
			# --- priority to udev file ---------------------------------------
			DIR_WORK="$(find "${DIR_NAME}" -name "${BASE_NAME%%_*}-udeb*" \( -type f -o -type l \))"
			if [[ -n "${DIR_WORK}" ]] ; then
				for I in "${!PACKAGE_LIST[@]}"
				do
					if [[ "${PACKAGE_LIST[${I}]}" = "${DIR_WORK}" ]]; then
						continue 2
					fi
				done
				DIR_PATH="${DIR_WORK}"
			fi
			PACKAGE_LIST+=("${DIR_PATH}")
		done
		# --- unpack package --------------------------------------------------
		DIR_DIRS="./${WORK_DIRS}/deb/${DIR_CODE}"
		DIR_LIST=($(find "${DIR_DIRS}" -name 'Packages' \( -type f -o -type l \)))
		cp --archive --backup "${DIR_DEST}/var/lib/dpkg/status" "${DIR_DEST}/var/lib/dpkg/status.orig"
		: > "${DIR_DEST}/var/lib/dpkg/status.work"
		for I in "${!PACKAGE_LIST[@]}"
		do
			DIR_PATH="${PACKAGE_LIST[${I}]}"
			BASE_NAME="${DIR_PATH##*/}"
			if [[ "${BASE_NAME%%_*}" = "mount" ]] || [[ "${BASE_NAME%%_*}" = "libmount1" ]]; then
				if [[ -f "${DIR_DEST}/bin/mount" ]] && [[ "$(readlink -q "${DIR_DEST}/bin/mount")" != "busybox" ]]; then
					funcPrintf "upac    pack: %-24.24s : %s\n" "skip package" "${BASE_NAME}"
					continue
				fi
			fi
			funcPrintf "upac    pack: %-24.24s : %s\n" "unpack package" "${BASE_NAME}"
			rm -rf "./${WORK_DIRS}/tmp/"*
			dpkg -x "${DIR_PATH}" "./${WORK_DIRS}/tmp/"
			if [[ -n "$(ls -A "./${WORK_DIRS}/tmp/")" ]]; then
				for DIR_WORK in "./${WORK_DIRS}/tmp/"*
				do
					cp --archive --backup "${DIR_WORK/}/." "${DIR_DEST}/${DIR_WORK##*/}/"
				done
			fi
			rm -rf "./${WORK_DIRS}/tmp/"*
#			funcPrintf "upac    pack: %-24.24s : %s\n" "update status" "${BASE_NAME}"
			DIR_PACK="${BASE_NAME%%_*}"
			if [[ -n "$(sed -n -e "/^Package: ${DIR_PACK}/p" "${DIR_DEST}/var/lib/dpkg/status")" ]]; then
				sed -i "${DIR_DEST}/var/lib/dpkg/status" \
				    -e "/^Package: ${DIR_PACK}/,/^$/d"
			fi
			sed -n -e "/^Package: ${DIR_PACK}/,/^$/p" "${DIR_LIST[@]}"                                  | \
			sed -e '1a Status: install ok unpacked'                                                     | \
			sed -e '/^\(Filename:*|\Size:*|\Kernel-Version:*\|SHA256:*|\MD5sum:*|\Description-md5*\)/d'   \
			>> "${DIR_DEST}/var/lib/dpkg/status.work"
		done
		cat "${DIR_DEST}/var/lib/dpkg/status.work" >> "${DIR_DEST}/var/lib/dpkg/status"
		rm "${DIR_DEST}/var/lib/dpkg/status.work" \
		   "${DIR_DEST}/var/lib/dpkg/status.orig"
		# --- unpack tar.xz file ----------------------------------------------
		rm -rf "./${WORK_DIRS}/tmp/"*
		for DIR_PATH in $(find "${DIR_DIRS}" -name '*.tar.xz' \( -type f -o -type l \))
		do
			BASE_NAME="${DIR_PATH##*/}"
			funcPrintf "upac    pack: %-24.24s : %s\n" "unpack package" "${BASE_NAME}"
			tar -C "./${WORK_DIRS}/tmp/" -xJf ${DIR_PATH}
		done
		for DIR_PATH in $(find "./${WORK_DIRS}/tmp/" \( -name '*.postinst' -o -name '*.templates' \) \( -type f -o -type l \))
		do
			BASE_NAME="${DIR_PATH##*/}"
			if [[ ! -d "${DIR_DEST}/var/lib/dpkg/info/." ]]; then
				mkdir -p "${DIR_DEST}/var/lib/dpkg/info"
			fi
			if [[ -f "${DIR_DEST}/var/lib/dpkg/info/${BASE_NAME}" ]]; then
				funcPrintf "upac    pack: %-24.24s : %s\n" "skip package" "${BASE_NAME}"
			else
				funcPrintf "upac    pack: %-24.24s : %s\n" "copy package" "${BASE_NAME}"
				case "${DIR_PATH##*/}" in
					*.templates ) po2debconf "${DIR_PATH}" > "${DIR_DEST}/var/lib/dpkg/info/${DIR_PATH##*/}";;
					*           ) cp --archive --backup "${DIR_PATH}" "${DIR_DEST}/var/lib/dpkg/info/";;
				esac
			fi
		done
		rm -rf "./${WORK_DIRS}/tmp/"*
		# --- remove file -----------------------------------------------------
		for I in "${!REMOVE_LIST[@]}"
		do
			DIR_PATH="${DIR_DEST}/${REMOVE_LIST[${I}]}"
			if [[ -f "${DIR_PATH}" ]]; then
				funcPrintf "rename  file: %-24.24s : %s\n" "rename file" "${DIR_PATH##*/}"
				mv "${DIR_PATH}" "${DIR_PATH}~"
			fi
		done
		# --- probe all modules -----------------------------------------------
		funcPrintf "updt pack db: %-24.24s : %s\n" "probe all modules" "${DIR_MODU#*/${DIR_DIST}/}"
		touch "${DIR_MODU}/modules.builtin.modinfo"
		touch "${DIR_MODU}/modules.order"
		touch "${DIR_MODU}/modules.builtin"
		depmod --all --basedir="${DIR_DEST}" "${DIR_KVER}"
	done
}

# --- edit script -------------------------------------------------------------
function funcEdit_script () {
	declare -r OLD_IFS="${IFS}"
#	declare -i I
#	declare -i J
#	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=("$@")
	declare DIR_NAME
	declare BASE_NAME
	declare -a MODULE_LIST=("${KERNEL_LIST[@]}")
	declare MODULE_LINE
	declare -r DIR_SECT="$(echo "${ARRAY_LINE[4],,}" | sed -n -e 's/^.*\(live\|dvd\|netinst\|netboot\|server\|boot\|minimal\|net\|rtm\|legacy\|desktop\).*$/\1/p')"
	declare -r DIR_CODE="${ARRAY_LINE[0]}.${ARRAY_LINE[1]%%.*}"
	declare -r DIR_DIST="${DIR_CODE}.${DIR_SECT:-desktop}"
	declare -a DIR_LIST=()
	declare DIR_DEST
#	declare DIR_DIRS
	declare DIR_PATH
#	declare DIR_FILE
	declare DIR_WORK
#	declare DIR_PACK
	declare DIR_KVER
	declare DIR_MODU
#	declare -a PACKAGE_LIST=()

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}edit  script: ${TXT_BGREEN}${DIR_DIST}${TXT_RESET}"
	# --- edit script [ram] ---------------------------------------------------
	for DIR_DEST in $(find "./${WORK_DIRS}/ram/${DIR_DIST}" -name 'initrd*' -type d | sort | sed -n -e '/\(initrd.*\/initrd*\|\/.*netboot\/\)/!p')
	do
		if [[ -d "${DIR_DEST}/main/." ]]; then
			DIR_DEST+="/main"
		fi
#		funcPrintf "edit  script: %-24.24s : %s\n" "edit script file" "${DIR_DIST}"
		# --- add file system -------------------------------------------------
		DIR_WORK="${DIR_DEST}/var/lib/dpkg/info/iso-scan.postinst"
		if [[ -f "${DIR_WORK}" ]]; then
			funcPrintf "edit  script: %-24.24s : %s\n" "edit script file" "${DIR_WORK##*/}"
			sed -i "${DIR_WORK}"                                                       \
			    -e 's/^\([[:blank:]]*FS\)="\(.*\)".*$/\1="\2 fuse fuse3 exfat ntfs3"/'
		fi
		# --- change mount process --------------------------------------------
		case "${DIR_DIST}" in
			debian.*        )
				;;
			ubuntu.bionic.server )
				DIR_WORK="${DIR_DEST}/var/lib/dpkg/info/iso-scan.postinst"
				if [[ -f "${DIR_WORK}" ]]; then
					funcPrintf "edit  script: %-24.24s : %s\n" "edit script file" "${DIR_WORK##*/}"
					INS_ROW=$(
						sed -n -e '/^[[:blank:]]*use_this_iso[[:blank:]]*([[:blank:]]*)/,/^[[:blank:]]*}$/ {/[[:blank:]]*mount .* \/cdrom/=}' \
						    "${DIR_WORK}"
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
							 		log "Skipping debconf question iso-scan/copy_iso_to_ram:" \\
							 		    "not enough memory available ($ram kB) to copy" \\
							 		    "/hd-media/$iso_to_try ($iso_size kB) into RAM and still" \\
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
					IFS="${OLD_IFS}"
					sed -i "${DIR_WORK}"                                                                                            \
					    -e '/^[[:blank:]]*use_this_iso[[:blank:]]*([[:blank:]]*/,/^}$/ s~^\([[:blank:]]*mount .* /cdrom .*$\)~#\1~' \
					    -e "${INS_ROW:-1}a \\${INS_STR}"
					# ---------------------------------------------------------
#					INS_ROW=$(
#						sed -n -e '/^[[:blank:]]*use_this_iso[[:blank:]]*([[:blank:]]*)/,/^[[:blank:]]*}$/ {/^[[:blank:]]*use_this_iso/=}' \
#						    "${DIR_WORK}"
#					)
#					IFS= INS_STR=$(
#						cat <<- '_EOT_' | sed -e 's/^ //g' | sed -z -e 's/\n/\\n/g' | sed -z -e 's/\\n$//'
#							use_this_iso () {
#							 	local iso_to_try=${1#/}
#							 	local iso_device=$2
#							 	local ram=$(grep ^MemAvailable: /proc/meminfo | { read label size unit; echo ${size:-0}; })
#							 	local iso_size=0
#							 	local RET
#							 
#							 	mount -t auto -o ro $iso_device /hd-media 2>/dev/null
#							 
#							 	# Get iso size in kB to compare with $ram in kB too
#							 	iso_size=$(ls -sk /hd-media/$iso_to_try | { read size filename; echo ${size:-0}; })
#							 
#							 	if [ $(( $iso_size + 100000 )) -lt $ram ]; then
#							 		# We have enough RAM to be able to copy the ISO to RAM,
#							 		# let's offer it to the user
#							 		db_input low iso-scan/copy_iso_to_ram || true
#							 		db_go
#							 		db_get iso-scan/copy_iso_to_ram
#							 	else
#							 		log "Skipping debconf question iso-scan/copy_iso_to_ram:" \\
#							 		    "not enough memory available ($ram kB) to copy" \\
#							 		    "/hd-media/$iso_to_try ($iso_size kB) into RAM and still" \\
#							 		    "have 100 MB free."
#							 		RET="false"
#							 	fi
#							 
#							 	if [ "$RET" = false ]; then
#							 		# Direct mount
#							 		log "Mounting /hd-media/$iso_to_try on /cdrom"
#							 		mount -t iso9660 -o loop,ro,exec /hd-media/$iso_to_try /cdrom 2>/dev/null
#							 	else
#							 		# We copy the ISO to RAM before mounting it
#							 		log "Copying /hd-media/$iso_to_try to /installer.iso"
#							 		cp /hd-media/$iso_to_try /installer.iso
#							 		log "Mounting /installer.iso on /cdrom"
#							 		mount -t iso9660 -o loop,ro,exec /installer.iso /cdrom 2>/dev/null
#							 		# So that we can free the original device
#							 		umount /hd-media
#							 	fi
#							 
#							 	analyze_cd
#							 
#							 	db_subst iso-scan/success FILENAME $iso_to_try
#							 	db_set iso-scan/filename $iso_to_try
#							 	db_subst iso-scan/success DEVICE $iso_device
#							 	# FIXME !!!
#							 	db_subst iso-scan/success SUITE FIXME
#							 	db_input medium iso-scan/success || true
#							 	db_go || true
#							 
#							 	anna-install apt-mirror-setup || true
#							 	if [ ! -e /cdrom/.disk/base_installable ]; then
#							 		log "Base system not installable from CD image, requesting choose-mirror"
#							 		anna-install choose-mirror || true
#							 	else
#							 		anna-install apt-cdrom-setup || true
#							 
#							 		# Install <codename>-support udeb (if available)
#							 		db_get cdrom/codename
#							 		anna-install $RET-support || true
#							 	fi
#							 	exit 0
#							}
#_EOT_
#					)
#					IFS="${OLD_IFS}"
#					sed -i "${DIR_WORK}"                                                 \
#					    -e '/^[[:blank:]]*use_this_iso[[:blank:]]*([[:blank:]]*/,/^}$/d'
#					sed -i "${DIR_WORK}"                                                 \
#					    -e "${INS_ROW:-1}i \\${INS_STR}"
					cat <<- '_EOT_' | sed -e 's/^ //g' >> "${DIR_WORK/.postinst/.templates}"
						 
						Template: iso-scan/copy_iso_to_ram
						Type: boolean
						Default: false
						Description: copy the ISO image to a ramdisk with enough space?
						Description-ja.UTF-8: ISO イメージを十分な容量のある RAM ディスクにコピーしますか?
_EOT_
				fi
				;;
			ubuntu.*        )
				DIR_WORK="${DIR_DEST}/scripts/casper-premount"
				if [[ -d  "${DIR_WORK}/." ]]; then
					funcPrintf "edit  script: %-24.24s : %s\n" "edit script file" "${DIR_WORK##*/}"
					DIR_WORK="${DIR_DEST}/scripts/casper-bottom/ORDER"
					INS_ROW=$(
						sed -n -e '/^.*\/24preseed .*$/,/^\[.*$/ {/24preseed/=}' \
						    "${DIR_WORK}"
					)
					IFS= INS_STR=$(
						cat <<- '_EOT_' | sed -e 's/^ //g' | sed -z -e 's/\n/\\n/g'
							/scripts/casper-bottom/24copy_cloud_init "$@"
							[ -e /conf/param.conf ] && . /conf/param.conf
							/scripts/casper-bottom/24copy_preseed_cfg "$@"
							[ -e /conf/param.conf ] && . /conf/param.conf
_EOT_
					)
					IFS="${OLD_IFS}"
					sed -i "${DIR_WORK}" -e "${INS_ROW:-1}i \\${INS_STR}"
					sed -i "${DIR_WORK}" -e '/^$/d'
					# --- transfer cloud init script --------------------------
					DIR_WORK="${DIR_DEST}/scripts/casper-bottom/24copy_cloud_init"
					cat <<- '_EOT_' >> "${DIR_WORK}"
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
						if [[ -f /scripts/lupin-helpers ]]; then
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
						        nocloud_path=${x#*=file:*/}
						        break
						        ;;
						      *s=*        | \
						      *seedfrom=* )
						        nocloud_path=${x#*=*/}
						        break
						        ;;
						    esac
						    ;;
						  esac
						done
						
						if [[ "${nocloud_path}" ]]; then
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
					chmod +x "${DIR_DEST}/scripts/casper-bottom/24copy_cloud_init"
					# --- transfer preseed.cfg script -------------------------
					DIR_WORK="${DIR_DEST}/scripts/casper-bottom/24copy_preseed_cfg"
					cat <<- '_EOT_' >> "${DIR_WORK}"
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
						if [[ -f /scripts/lupin-helpers ]]; then
						  . /scripts/lupin-helpers
						fi
						
						preseed_path=
						for x in $(cat /proc/cmdline); do
						  case ${x} in
						    file=* )
						      preseed_path=${x#file=*/}
						      break
						    ;;
						  esac
						done
						
						if [[ "${preseed_path}" ]]; then
						  if find_path "/${preseed_path%/*}" /isodevice rw; then
						    echo "mkdir -p /root/${preseed_path%/*}"
						    mkdir -p /root/${preseed_path%/*}
						    echo "cp -dR ${FOUNDPATH}/. /root/${preseed_path%/*}"
						    cp -dR ${FOUNDPATH}/. /root/${preseed_path%/*}
						  else
						    panic "
						Preseed not find the preseed /${preseed_path}
						"
						  fi
						fi
_EOT_
					chmod +x "${DIR_DEST}/scripts/casper-bottom/24copy_preseed_cfg"
				fi
				DIR_WORK="${DIR_DEST}/scripts/casper-helpers"
				if [[ -f  "${DIR_WORK}" ]]; then
					funcPrintf "edit  script: %-24.24s : %s\n" "edit script file" "${DIR_WORK##*/}"
					case "${DIR_DIST}" in
						ubuntu.bionic.desktop )
							sed -i "${DIR_WORK}"                                                                                                                                 \
							    -e '/[[:blank:]]*find_files[[:blank:]]*([[:blank:]]*)/,/[[:blank:]]*}$/ {'                                                                       \
							    -e '/vfat/ s/\([[:blank:]]*;[[:blank:]]\+then\)/ || \[ "${devfstype}" = "exfat" \] || \[ "${devfstype}" = "ntfs" \]\1/}'                         
#							    -e '/[[:blank:]]*find_cow_device[[:blank:]]*([[:blank:]]*)/,/[[:blank:]]*}$/ {'                                                                  \
#							    -e '/vfat/ s/\([[:blank:]]*;[[:blank:]]\+then\)/ || \[ "$(get_fstype ${devname})" = "exfat" \] || \[ "$(get_fstype ${devname})" = "ntfs" \]\1/}'
							sed -i "${DIR_DEST}/scripts/casper-bottom/ORDER" \
							    -e '/05mountpoints_lupin/,/\[/d' \
							;;
					esac
					sed -i "${DIR_WORK}"                                                                                                            \
					    -e '/[[:blank:]]*is_supported_fs[[:blank:]]*([[:blank:]]*)/,/[[:blank:]]*}$/ s/\(vfat.*\))/\1|exfat)/'                      \
					    -e '/[[:blank:]]*wait_for_devs[[:blank:]]*([[:blank:]]*)/,/[[:blank:]]*}$/ {/touch/i \\    mkdir -p /dev/.initramfs' -e '}'
					INS_ROW=$(
						sed -n -e '/^[[:blank:]]*find_files[[:blank:]]*([[:blank:]]*)/,/^[[:blank:]]*}$/ {/[[:blank:]]*vfat|ext2)/,/.*;;$/=}' \
						    "${DIR_WORK}"                                                                                                     \
						| awk 'END {print}'
					)
					if [[ -n "${INS_ROW}" ]]; then
						IFS= INS_STR=$(
							cat <<- '_EOT_' | sed -e 's/^ //g' | sed -z -e 's/\n/\\n/g'
								                 exfat|ntfs)
								                     :;;
_EOT_
						)
						IFS="${OLD_IFS}"
						sed -i "${DIR_WORK}"                 \
						    -e "${INS_ROW:-1}a \\${INS_STR}"
					fi
				fi
				DIR_WORK="${DIR_DEST}/scripts/lupin-helpers"
				if [[ -f "${DIR_WORK}" ]]; then
					funcPrintf "edit  script: %-24.24s : %s\n" "edit script file" "${DIR_WORK##*/}"
					sed -i "${DIR_WORK}"                                                                                                            \
					    -e '/[[:blank:]]*is_supported_fs[[:blank:]]*([[:blank:]]*)/,/[[:blank:]]*}$/ s/\(vfat.*\))/\1|exfat)/'                      \
					    -e '/[[:blank:]]*wait_for_devs[[:blank:]]*([[:blank:]]*)/,/[[:blank:]]*}$/ {/touch/i \\    mkdir -p /dev/.initramfs' -e '}'
				fi
				;;
			*               )
				;;
		esac
	done
	IFS="${OLD_IFS}"
}

# --- make initramfs ----------------------------------------------------------
function funcMake_initrdt () {
	declare -r OLD_IFS="${IFS}"
#	declare -i I
#	declare -i J
#	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=("$@")
	declare DIR_NAME
	declare BASE_NAME
	declare -a MODULE_LIST=("${KERNEL_LIST[@]}")
	declare MODULE_LINE
	declare -r DIR_SECT="$(echo "${ARRAY_LINE[4],,}" | sed -n -e 's/^.*\(live\|dvd\|netinst\|netboot\|server\|boot\|minimal\|net\|rtm\|legacy\|desktop\).*$/\1/p')"
	declare -r DIR_CODE="${ARRAY_LINE[0]}.${ARRAY_LINE[1]%%.*}"
	declare -r DIR_DIST="${DIR_CODE}.${DIR_SECT:-desktop}"
	declare -a DIR_LIST=()
	declare DIR_DEST
	declare DIR_DIRS
	declare DIR_PATH
	declare DIR_FILE
	declare DIR_WORK
#	declare DIR_PACK
	declare DIR_KVER
	declare DIR_MODU
#	declare -a PACKAGE_LIST=()

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}make  initrd: ${TXT_BGREEN}${DIR_DIST}${TXT_RESET}"
	# --- edit script [ram] ---------------------------------------------------
	for DIR_DEST in $(find "./${WORK_DIRS}/ram/${DIR_DIST}" -name 'initrd*' -type d | sort | sed -n -e '/\(initrd.*\/initrd*\|\/.*netboot\/\)/!p')
	do
		# --- source ----------------------------------------------------------
		if [[ -d "${DIR_DEST}/main/." ]]; then
			DIR_DEST+="/main"
		fi
		DIR_WORK="${DIR_DEST#*/ram/}"
		funcPrintf "make  initrd: %-24.24s : %s\n" "make initramfs file" "${DIR_WORK#*${DIR_DIST}/}"
		DIR_LIST=($(echo "${DIR_WORK}" | sed -n -e 's%^.*/\(install.*\|live\|casper\)/\(initrd.*\|gtk\|xen\)/*.*$%\1 \2%p'))
		DIR_WORK="${DIR_LIST[0]%/*}"
		if [[ "${DIR_WORK}" = "install" ]]; then
			DIR_WORK+=".amd"
		fi
		DIR_DIRS="./${WORK_DIRS}/img/${DIR_WORK}/${DIR_DIST}"
		if [[ "${DIR_LIST[0]%/*}" != "${DIR_LIST[0]#*/}" ]]; then
			DIR_DIRS+="/${DIR_LIST[0]#*/}"
		fi
		mkdir -p "${DIR_DIRS}"
		# --- initrd ----------------------------------------------------------
		DIR_FILE="${DIR_LIST[1]%/*}"
		if [[ "${DIR_LIST[0]#*/}" = "xen" ]]; then
			DIR_PATH="./${WORK_DIRS}/bld/${DIR_DIST}/${DIR_LIST[0]%/*}"
			if [[ "${DIR_LIST[0]%/*}" != "${DIR_LIST[0]#*/}" ]]; then
				DIR_PATH+="/${DIR_LIST[0]#*/}"
			fi
			DIR_PATH+="/${DIR_FILE}"
#			funcPrintf "make  initrd: %-24.24s : %s\n" "make initramfs file" "${DIR_PATH#*/${DIR_DIST}/}"
			cp --preserve=timestamps --no-preserve=mode,ownership "${DIR_PATH}" "${DIR_DIRS}/"
		else
			if [[ "${DIR_FILE}" = "${DIR_FILE%.*}" ]]; then
				DIR_FILE+=".gz"
			fi
			DIR_PATH="$(pwd)/${DIR_DIRS}/${DIR_FILE/.img/.gz}"
			pushd "${DIR_DEST}" > /dev/null
				find . -name '*~' -prune -o -print | cpio -R 0:0 -o -H newc --quie | gzip -c > "/${DIR_PATH}"
			popd > /dev/null
		fi
		# --- vmlinuz ---------------------------------------------------------
		DIR_PATH="./${WORK_DIRS}/bld/${DIR_DIST}/${DIR_LIST[0]%/*}"
		if [[ "${DIR_LIST[0]%/*}" != "${DIR_LIST[0]#*/}" ]]; then
			DIR_PATH+="/${DIR_LIST[0]#*/}"
		fi
		DIR_PATH+="/vmlinuz"
		funcPrintf "make  initrd: %-24.24s : %s\n" "make initramfs file" "${DIR_PATH#*/${DIR_DIST}/}"
		cp --preserve=timestamps --no-preserve=mode,ownership "${DIR_PATH}"* "${DIR_DIRS}/"
	done
}

# --- remake initramfs --------------------------------------------------------
function funcRemake_initrd () {
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=()
#	declare DIR_NAME
	declare BASE_NAME
	declare CDIMG
#	declare -r FLABEL="$(LANG=C blkid -s LABEL "${${ARRAY_LINE[3]}/${ARRAY_LINE[4]}}" | awk -F '\"' '{print $2;}')"

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}remake module${TXT_RESET}"
	# --- delete old module ---------------------------------------------------
	rm -rf ./"${WORK_DIRS}"/{bld,pac,ram}
#	rm -rf ./"${WORK_DIRS}"/{bld,deb,pac,ram}
	# --- processing loop -----------------------------------------------------
	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
#		DIR_NAME="${ARRAY_LINE[2]%/*}"
#		BASE_NAME="${ARRAY_LINE[2]##*/}"
		BASE_NAME="${ARRAY_LINE[4]}"
		# --- target selection ------------------------------------------------
		case "${ARRAY_LINE[0]}" in
			debian | \
			ubuntu )
				if [[ "${BASE_NAME}" =~ mini.*\.iso ]]; then
					continue
				fi
				;;
			*      )
				continue
				;;
		esac
		if [[ "${ARRAY_LINE[4]}" = "-" ]]; then
			CDIMG="${ARRAY_LINE[3]}/${BASE_NAME}"
		else
			CDIMG="${ARRAY_LINE[3]}/${ARRAY_LINE[4]}"
		fi
		if [[ ! -f "${CDIMG}" ]]; then
			funcPrintf "${TXT_BLACK}${TXT_BRED}not    exist: %s${TXT_RESET}\n" "${CDIMG}"
			continue
		fi
		# --- module remake ---------------------------------------------------
		funcPrintf "${TXT_BLACK}${TXT_BYELLOW}make initramfs file: ${TXT_BCYAN}${CDIMG}${TXT_RESET}"
		funcCopy_initrd  "${ARRAY_LINE[@]}"
		funcUnzip_initrd "${ARRAY_LINE[@]}"
		funcAdd_module   "${ARRAY_LINE[@]}"
		funcEdit_script  "${ARRAY_LINE[@]}"
		funcMake_initrdt "${ARRAY_LINE[@]}"
	done
}

# --- make menu.cfg file sub --------------------------------------------------
function funcMake_menu_sub () {
	declare -r STR_MENU="$1"
	declare -r TAB_SPACE="$2"
	declare -r SUB_MENU="$3"
	declare -r FPATH="$(find "./${WORK_DIRS}/iso/" -name "${STR_MENU}" \( -type f -o -type l \))"
	declare -r DNAME="${FPATH%/*}"
	declare -r FNAME="${FPATH##*/}"
	declare -r DTYPE="${DNAME##*/}"
	declare -i I
	declare -i J
	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=()
	# --- common parameter ----------------------------------------------------
	declare    ENTRY=""
	declare    LABEL=""
	declare    DISTR=""
	declare    VERNO=""
	declare    STAMP=""
	declare    MTYPE=""
	# --- debian / ubuntu parameter -------------------------------------------
	declare    CDNEM=""
	declare    SUITE=""
	declare    ISCAN=""
	declare    RDIRS=""
	declare    RFILE=""
	declare    PSEED=""
#	declare -r DEVNO="sdb3"
	# --- get media information -----------------------------------------------
	if [[ -z "${FPATH}" ]]; then
		return
	fi
	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		if [[ "${FNAME}" = "${ARRAY_LINE[4]}" ]]; then
			LABEL="$(LANG=C blkid -s LABEL "${FPATH}" | awk -F '\"' '{print $2;}')"
			DISTR="${ARRAY_LINE[0]}"
			CDNEM="${ARRAY_LINE[1]%%.*}"
			STAMP="${ARRAY_LINE[8]/./ }"
			ENTRY="$(printf "%-60.60s%20.20s" "${FNAME}" "${STAMP}")"
			VERNO="$(echo "${FNAME}"   | sed -n -e 's/^.*-\([0-9\.]*\)-.*$/\1/p')"
			MTYPE="$(echo "${FNAME,,}" | sed -n -e 's/^.*\(live\|dvd\|netinst\|netboot\|server\|boot\|minimal\|net\|rtm\|legacy\|desktop\).*$/\1/p')"
			break
		fi
	done
	if [[ -z "${DISTR}" ]]; then
		return
	fi
#	case "${FNAME}" in
#		debian-*.iso           | \
#		ubuntu-*.iso           | \
#		*-desktop-legacy-*.iso )
#	case "$(echo "${LABEL,,}" | sed -e 's/^.*\(debian\|ubuntu\).*$/\1/p')" in
	case "${DISTR}" in
		debian | \
		ubuntu )
			RDIRS="./${WORK_DIRS}/deb/${DISTR}.${CDNEM}.${MTYPE:-desktop}"
			RFILE="$(find "${RDIRS}" -maxdepth 2 -name 'Release' \( -type f -o -type l \) | sed -n '/\/\(testing\|stable\|oldstable\|oldoldstable\|unstable\)\//!p')"
			SUITE="$(sed -n 's/^Suite: *//p'    "${RFILE}")"
			VERNO="$(sed -n 's/^Version: *//p'  "${RFILE}")"
#			CDNEM="$(sed -n 's/^Codename: *//p' "${RFILE}")"
			ISCAN="${SUITE}${VERNO:+ - ${VERNO}}"
			PSEED="preseed.cfg"
			if [[ -n "${VERNO}" ]] \
			&& [[ "${DISTR}" = "debian" && ${VERNO%%\.*} -lt 11    \
			||    "${DISTR}" = "ubuntu" && ${VERNO%%\.*} -lt 20 ]]; then
				PSEED="preseed_old.cfg"
			fi
			;;
		*            )
			;;
	esac
	# --- make menu block -----------------------------------------------------
	case "${FNAME}" in
		mini*.iso                    )
			;;
		debian-live-*.iso            )
			case "${SUB_MENU}" in
				'[ Unattended installation ]' )
					cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
						menuentry '${ENTRY}' {
						    set isofile="/images/${FNAME}"
						    set isoscan="\${isofile} (${ISCAN})"
						    set isodist="${DISTR}.${CDNEM}.${MTYPE}"
						    set preseed="auto=true file=/hd-media/preseed/${DISTR}/${PSEED} netcfg/disable_autoconfig=true"
						    set locales="locales=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
						    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
						    echo "Loading \${isofile} ..."
						    linux   (\${cfgpart})/install.amd/\${isodist}/vmlinuz root=\${cfgpart} shared/ask_device=/dev/${USB_INST} iso-scan/ask_which_iso="[${USB_INST}] \${isoscan}" \${locales} fsck.mode=skip \${preseed} ---
						    initrd  (\${cfgpart})/install.amd/\${isodist}/initrd.gz
						}
_EOT_
					;;
				*                             )
					cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
						menuentry '${ENTRY}' {
						    set isofile="/images/${FNAME}"
						    set isodist="${DISTR}.${CDNEM}.${MTYPE}"
						    set preseed="auto=true file=/hd-media/preseed/${DISTR}/${PSEED} netcfg/disable_autoconfig=true"
						    set locales="locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
						    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
						    echo "Loading \${isofile} ..."
						    linux   (\${cfgpart})/live/\${isodist}/vmlinuz root=\${cfgpart} boot=live components quiet splash findiso=\${isofile} \${locales} fsck.mode=skip
						    initrd  (\${cfgpart})/live/\${isodist}/initrd.gz
						}
_EOT_
					;;
			esac
			;;
		debian-*.iso                 | \
		ubuntu-1*-server-*.iso       )
			cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
				menuentry '${ENTRY}' {
				    set isofile="/images/${FNAME}"
				    set isoscan="\${isofile} (${ISCAN})"
				    set isodist="${DISTR}.${CDNEM}.${MTYPE}"
				    set preseed="auto=true file=/hd-media/preseed/${DISTR}/${PSEED} netcfg/disable_autoconfig=true"
				    set locales="locales=C timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
				    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				    echo "Loading \${isofile} ..."
				    linux   (\${cfgpart})/install.amd/\${isodist}/vmlinuz root=\${cfgpart} shared/ask_device=/dev/${USB_INST} iso-scan/ask_which_iso="[${USB_INST}] \${isoscan}" \${locales} fsck.mode=skip \${preseed} ---
				    initrd  (\${cfgpart})/install.amd/\${isodist}/initrd.gz
				}
_EOT_
			;;
		ubuntu-1*-desktop-*.iso      | \
		ubuntu-2[0-2]*-desktop-*.iso | \
		*-desktop-legacy-*.iso       )
			case "${SUB_MENU}" in
				'[ Unattended installation ]' )
					cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
						menuentry '${ENTRY}' {
						    set isofile="/images/${FNAME}"
						    set isoscan="iso-scan/filename=\${isofile}"
						    set isodist="${DISTR}.${CDNEM}.${MTYPE}"
						    set preseed="auto=true file=/preseed/${DISTR}/${PSEED} netcfg/disable_autoconfig=true automatic-ubiquity noprompt"
						    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
						    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
						    echo "Loading \${isofile} ..."
						    linux   (\${cfgpart})/casper/\${isodist}/vmlinuz boot=casper \${isoscan} \${locales} fsck.mode=skip \${preseed} ---
						    initrd  (\${cfgpart})/casper/\${isodist}/initrd.gz
						}
_EOT_
					;;
				*                             )
					cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
						menuentry '${ENTRY}' {
						    set isofile="/images/${FNAME}"
						    set isoscan="iso-scan/filename=\${isofile}"
						    set isodist="${DISTR}.${CDNEM}.${MTYPE}"
						    set preseed="auto=true file=/preseed/${DISTR}/${PSEED} netcfg/disable_autoconfig=true automatic-ubiquity noprompt"
						    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
						    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
						    echo "Loading \${isofile} ..."
						    linux   (\${cfgpart})/casper/\${isodist}/vmlinuz boot=casper \${isoscan} \${locales} fsck.mode=skip ---
						    initrd  (\${cfgpart})/casper/\${isodist}/initrd.gz
						}
_EOT_
					;;
			esac
			;;
		ubuntu-*-desktop-*.iso       | \
		*-desktop-*.iso              )
			case "${SUB_MENU}" in
				'[ Unattended installation ]' )
					cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
						menuentry '${ENTRY}' {
						    set isofile="/images/${FNAME}"
						    set isoscan="iso-scan/filename=\${isofile}"
						    set isodist="${DISTR}.${CDNEM}.${MTYPE}"
						    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
						    set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/${DISTR}.${MTYPE}/'
						    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
						    echo "Loading \${isofile} ..."
						    linux   (\${cfgpart})/casper/\${isodist}/vmlinuz layerfs-path=minimal.standard.live.squashfs --- quiet splash \${isoscan} \${locales} fsck.mode=skip \${nocloud} ip=dhcp ipv6.disable=0 ---
						    initrd  (\${cfgpart})/casper/\${isodist}/initrd.gz
						}
_EOT_
					;;
				*                             )
					cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
						menuentry '${ENTRY}' {
						    set isofile="/images/${FNAME}"
						    set isoscan="iso-scan/filename=\${isofile}"
						    set isodist="${DISTR}.${CDNEM}.${MTYPE}"
						    set locales="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
						    set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/${DISTR}.${MTYPE}/'
						    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
						    echo "Loading \${isofile} ..."
						    linux   (\${cfgpart})/casper/\${isodist}/vmlinuz layerfs-path=minimal.standard.live.squashfs --- quiet splash \${isoscan} \${locales} fsck.mode=skip
						    initrd  (\${cfgpart})/casper/\${isodist}/initrd.gz
						}
_EOT_
					;;
			esac
			;;
		ubuntu-*.iso                 | \
		*-live-server-*.iso          )
			cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
				menuentry '${ENTRY}' {
				    set isofile="/images/${FNAME}"
				    set isoscan="iso-scan/filename=\${isofile}"
				    set isodist="${DISTR}.${CDNEM}.${MTYPE}"
				    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				    set nocloud='autoinstall ds=nocloud-net;s=file:///nocloud/${DISTR}.${MTYPE}/'
				    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				    echo "Loading \${isofile} ..."
				    linux   (\${cfgpart})/casper/\${isodist}/vmlinuz boot=casper \${isoscan} \${locales} fsck.mode=skip \${nocloud} ip=dhcp ipv6.disable=0 ---
				    initrd  (\${cfgpart})/casper/\${isodist}/initrd.gz
				}
_EOT_
			;;
		CentOS-*.iso                 )
			# https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/8/html-single/performing_an_advanced_rhel_8_installation/index#kickstart-and-advanced-boot-options_installing-rhel-as-an-experienced-user
			cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
				menuentry '${ENTRY}' {
				    set isofile="/images/${FNAME}"
				    set ksstart="inst.ks=hd:/dev/${USB_INST}:/kickstart/ks_${DISTR}-${VERNO%%\.*}_${DTYPE}.cfg"
				    set isoscan="iso-scan/filename=\${isofile}"
				    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				    set options="inst.sshd rd.live.ram"
				    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				    echo "Loading \${isofile} ..."
				    loopback loop (\${isopart})\${isofile}
				    probe --label --set=hdlabel (loop)
				    linux  (loop)/images/pxeboot/vmlinuz inst.repo=hd:/dev/${USB_INST}:\${isofile} quiet \${isoscan} \${ksstart}
				    initrd (loop)/images/pxeboot/initrd.img
				    loopback --delete loop
				}
_EOT_
			;;
		AlmaLinux-*.iso              | \
		Fedora-*.iso                 | \
		MIRACLELINUX-*.iso           | \
		Rocky-*.iso                  )
			# https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/8/html-single/performing_an_advanced_rhel_8_installation/index#kickstart-and-advanced-boot-options_installing-rhel-as-an-experienced-user
			cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
				menuentry '${ENTRY}' {
				    set isofile="/images/${FNAME}"
				    set ksstart="inst.ks=hd:/dev/${USB_INST}:/kickstart/ks_${DISTR}-${VERNO%%\.*}_${DTYPE}.cfg"
				    set isoscan="iso-scan/filename=\${isofile}"
				    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				    set options="inst.sshd rd.live.ram"
				    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				    echo "Loading \${isofile} ..."
				    loopback loop (\${isopart})\${isofile}
				    probe --label --set=hdlabel (loop)
				    linux  (loop)/images/pxeboot/vmlinuz inst.repo=hd:LABEL=\${hdlabel} quiet \${isoscan} \${ksstart}
				    initrd (loop)/images/pxeboot/initrd.img
				    loopback --delete loop
				}
_EOT_
			;;
		openSUSE-Leap-*.iso          )
			cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
				menuentry '${ENTRY}' {
				    set isofile="/images/${FNAME}"
				    set autoxml="autoyast=usb:/${USB_INST}/autoyast/autoinst_leap_${VERNO}.xml"
				    set isoscan="iso-scan/filename=\${isofile}"
				    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				    echo "Loading \${isofile} ..."
				    loopback loop (\${isopart})\${isofile}
				    linux  (loop)/boot/x86_64/loader/linux splash=silent \${autoxml} ifcfg=e*=dhcp
				    initrd (loop)/boot/x86_64/loader/initrd
				    loopback --delete loop
				}
_EOT_
			;;
		openSUSE-Tumbleweed*.iso     )
			cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g"
				menuentry '${ENTRY}' {
				    set isofile="/images/${FNAME}"
				    set autoxml="autoyast=usb:/${USB_INST}/autoyast/autoinst_tumbleweed.xml"
				    set isoscan="iso-scan/filename=\${isofile}"
				    set locales="locale=C timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				    echo "Loading \${isofile} ..."
				    loopback loop (\${isopart})\${isofile}
				    linux  (loop)/boot/x86_64/loader/linux splash=silent \${autoxml} ifcfg=e*=dhcp
				    initrd (loop)/boot/x86_64/loader/initrd
				    loopback --delete loop
				}
_EOT_
			;;
		*                            )
			;;
	esac
}

# --- make menu.cfg file ------------------------------------------------------
function funcMake_menu_cfg () {
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${MENU_LIST[@]}")
	declare -a ARRAY_LINE=()
	declare -i TAB_COUNT=0
	declare TAB_SPACE=""
	declare SUB_MENU=""
	declare STR_MENU=""

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}make menu.cfg file${TXT_RESET}"
	# --- header --------------------------------------------------------------
	cat <<- '_EOT_' | sed -e 's/^ //g' > "${FNAME_MENU}"
		set default=0
		set timeout=-1
		
		insmod play
		play 960 440 1 0 4 440 1
		
_EOT_
	# --- menu block ----------------------------------------------------------
	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		STR_MENU="${ARRAY_LINE[@]}"
		case "${STR_MENU}" in
			'- ['*...*']' )				# sub menu
				TAB_SPACE="$(funcString "$(("${TAB_COUNT}"*4))" " ")"
				cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g" >> "${FNAME_MENU}"
					submenu '${STR_MENU}' {
_EOT_
#				SUB_MENU="${STR_MENU}"
				((TAB_COUNT++)) || true
				;;
			'['']' )					# return to menu
#				SUB_MENU="${STR_MENU}"
				((TAB_COUNT--)) || true
				TAB_SPACE="$(funcString "$(("${TAB_COUNT}"*4))" " ")"
				cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g" >> "${FNAME_MENU}"
					}
_EOT_
				;;
			'['*']' )					# menu title
				SUB_MENU="${STR_MENU}"
				TAB_SPACE="$(funcString "$(("${TAB_COUNT}"*4))" " ")"
				cat <<- _EOT_ | sed -e "s/^/${TAB_SPACE}/g" >> "${FNAME_MENU}"
					menuentry '${STR_MENU}' {
					    true
					}
_EOT_
				;;
			* )							# list up file name
				TAB_SPACE="$(funcString "$(("${TAB_COUNT}"*4))" " ")"
				funcMake_menu_sub "${STR_MENU}" "${TAB_SPACE}" "${SUB_MENU}" >> "${FNAME_MENU}"
				;;
		esac
		if [[ ${TAB_COUNT} -le 0 ]]; then
			TAB_COUNT=0
		fi
	done
	# --- footer --------------------------------------------------------------
	cat <<- '_EOT_' | sed -e 's/^ //g' >> "${FNAME_MENU}"
		menuentry '[ System command ]' {
		    true
		}
		menuentry '- System shutdown' {
		    echo "System shutting down ..."
		    halt
		}
		menuentry '- System restart' {
		    echo "System rebooting ..."
		    reboot
		}
_EOT_
}

# --- make grub.cfg file ------------------------------------------------------
function funcMake_grub_cfg () {
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}make grub.cfg file${TXT_RESET}"

	cat <<- '_EOT_' | sed -e 's/^ //g' > "${FNAME_GRUB}"
		set default=0
		set timeout=-1
		
		insmod font
		if loadfont ${prefix}/fonts/unicode.pf2 ; then
		 	set locale_dir=${prefix}/locale
		 	set lang=ja_JP
		 	set gfxmode=1280x720
		 	set gfxpayload=keep
		
		 	if [ "${grub_platform}" == "efi" ]; then
		 		insmod efi_gop
		 		insmod efi_uga
		 	else
		 		insmod vbe
		 		insmod vga
		 	fi
		
		 	insmod gfxterm
		 	insmod gettext
		 	terminal_output gfxterm
		 #	insmod terminal
		 #	insmod keylayouts
		 #	terminal_input at_keyboard
		 #	keymap ${prefix}/layouts/jp.gkb
		fi
		
		set menu_color_normal=cyan/blue
		set menu_color_highlight=white/blue

		search.fs_label "ISOFILE" cfgpart hd1,gpt3
		# search.fs_label "ISOFILE" isopart hd1,gpt3
		set isopart=${cfgpart}
		
		export cfgpart
		export isopart
		export lang
		export gfxmode
		export gfxpayload
		export menu_color_normal
		export menu_color_highlight
		
		source (${cfgpart})/menu.cfg
_EOT_
}

# --- copy iso image file -----------------------------------------------------
function funcCopy_iso_image () {
	declare -i I
#	declare -i J
	declare -a ARRAY_LIST=("${TARGET_LIST[@]}")
	declare -a ARRAY_LINE=()
#	declare DIR_NAME
#	declare BASE_NAME
	declare DIR_DEST
	declare DIR_PATH
	declare DIR_WORK

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}copy iso image file${TXT_RESET}"

	DIR_DEST="./${WORK_DIRS}/img/images"
	if [[ -d "${DIR_DEST}/." ]]; then
		rm -rf "${DIR_DEST}"
	fi

	#idx:value
	#  0:distribution
	#  1:codename
	#  2:download URL
	#  3:directory
	#  4:alias
	#  5:iso file size
	#  6:iso file date
	#  7:definition file
	#  8:release
	#  9:support
	# 10:status
	# 11:memo1
	# 12:memo2

	for I in "${!ARRAY_LIST[@]}"
	do
		ARRAY_LINE=(${ARRAY_LIST[${I}]})
		DIR_NAME="${ARRAY_LINE[3]}"
		BASE_NAME="${ARRAY_LINE[4]}"
		DIR_PATH="${DIR_NAME}/${BASE_NAME}"
		DIR_DEST="./${WORK_DIRS}/img/images/${DIR_NAME##*/}"
		if [[ ! -f "${DIR_PATH}" ]]; then
			continue
		fi
		if [[ ! -d "${DIR_DEST}/." ]]; then
			mkdir -p "${DIR_DEST}"
		fi
		funcPrintf "copy    file: %-24.24s : %s\n" "copy iso image file" "${BASE_NAME}"
		DIR_WORK="$(echo "${DIR_DEST#\./"${WORK_DIRS}"/}" | sed -e "s%[[:alnum:]]*%\.\.%g")"
		DIR_WORK+="/${DIR_PATH#\./"${WORK_DIRS}"/}"
		pushd "${DIR_DEST}" > /dev/null
			if [[ ! -f "./${BASE_NAME}" ]]; then
				cp --symbolic-link "${DIR_WORK}" "./"
			fi
		popd > /dev/null
	done
}

# --- USB Device format [sdX] -------------------------------------------------
function funcUSB_Device_format () {
	declare -r USB_DEVICE="/dev/${USB_NAME}"
	declare -r USB_BOOT="/dev/${USB_NAME}1"
	declare -r USB_UEFI="/dev/${USB_NAME}2"
	declare -r USB_DATA="/dev/${USB_NAME}3"

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}format USB device ${USB_DEVICE}${TXT_RESET}"
	funcPrintf "USB   device: %-24.24s : %s\n" "partition" "${USB_DEVICE}"
	# --- make partition ------------------------------------------------------
	# sdX1: 1007KiB: boot partition (no format)
	# sdX2:  256MiB: UEFI partition (vFAT)
	# sdX3:        : data partition (exFAT or NTFS)
	sfdisk --wipe always --wipe-partitions always "${USB_DEVICE}" <<- _EOT_
		label: gpt
		first-lba: 34
		start=34, size=  2014, type=21686148-6449-6E6F-744E-656564454649, attrs="GUID:62,63"
		start=  , size=256MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
		start=  , size=      , type=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7
_EOT_
	sleep 3
	sync
	# --- make format ---------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "format" "${USB_DEVICE}"
	mkfs.vfat -F 32              "${USB_UEFI}"				# UEFI partition (vFAT)
	if [[ "${USB_FORMAT,,}" = "ntfs" ]]; then
		funcPrintf "USB   device: %-24.24s : %s\n" "format type NTFS" "${USB_DEVICE}"
		mkfs.ntfs -Q    -L "ISOFILE" "${USB_DATA}"			# data partition (NTFS)
	else
		funcPrintf "USB   device: %-24.24s : %s\n" "format type exFAT" "${USB_DEVICE}"
		mkfs.exfat      -n "ISOFILE" "${USB_DATA}"			# data partition (exFAT)
	fi
	sleep 3
	sync
	lsblk -o NAME,TYPE,TRAN,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL "${USB_DEVICE}"
}

# --- USB Device install bootloader [sdX1 / sdX2] -----------------------------
function funcUSB_Device_inst_bootloader () {
	declare -r USB_DEVICE="/dev/${USB_NAME}"
	declare -r USB_BOOT="/dev/${USB_NAME}1"
	declare -r USB_UEFI="/dev/${USB_NAME}2"
	declare -r USB_DATA="/dev/${USB_NAME}3"

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}install USB device ${USB_DEVICE}1${TXT_RESET}"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "mount" "${USB_UEFI}"
	mount "${USB_UEFI}" "./${WORK_DIRS}/usb"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "bootloader" "${USB_BOOT}"
	grub-install --target=i386-pc    --recheck   --boot-directory="./${WORK_DIRS}/usb/boot" "${USB_DEVICE}"
	grub-install --target=x86_64-efi --removable --boot-directory="./${WORK_DIRS}/usb/boot" --efi-directory="./${WORK_DIRS}/usb"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "mkdir" "${USB_UEFI}"
	mkdir -p "./${WORK_DIRS}/usb/.disk"
	touch "./${WORK_DIRS}/usb/.disk/info"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "umount" "${USB_UEFI}"
	umount "./${WORK_DIRS}/usb"
}

# --- USB Device install keyboard layout [sdX2] -------------------------------
function funcUSB_Device_inst_kbd () {
	declare -r USB_DEVICE="/dev/${USB_NAME}"
	declare -r USB_BOOT="/dev/${USB_NAME}1"
	declare -r USB_UEFI="/dev/${USB_NAME}2"
	declare -r USB_DATA="/dev/${USB_NAME}3"
	declare -r DIR_KBRD="./${WORK_DIRS}/usb/boot/grub/layouts"

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}install USB device ${USB_UEFI}${TXT_RESET}"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "mount" "${USB_UEFI}"
	mount "${USB_UEFI}" "./${WORK_DIRS}/usb"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "grub Keyboard" "${USB_UEFI}"
	if [[ ! -d "${DIR_KBRD}/." ]]; then
		mkdir -p "${DIR_KBRD}"
	fi
	grub-kbdcomp -o "${DIR_KBRD}/jp.gkb" jp 2> /dev/null
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "umount" "${USB_UEFI}"
	umount "./${WORK_DIRS}/usb"
}

# --- USB Device install grub.cfg [sdX2] --------------------------------------
function funcUSB_Device_inst_grub () {
	declare -r USB_DEVICE="/dev/${USB_NAME}"
	declare -r USB_BOOT="/dev/${USB_NAME}1"
	declare -r USB_UEFI="/dev/${USB_NAME}2"
	declare -r USB_DATA="/dev/${USB_NAME}3"

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}install USB device ${USB_UEFI}${TXT_RESET}"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "mount" "${USB_UEFI}"
	mount "${USB_UEFI}" "./${WORK_DIRS}/usb"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "${FNAME_GRUB##*/}" "${USB_UEFI}"
	cp --preserve=timestamps --no-preserve=mode,ownership "${FNAME_GRUB}" "./${WORK_DIRS}/usb/boot/grub/"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "umount" "${USB_UEFI}"
	umount "./${WORK_DIRS}/usb"
}

# --- USB Device install menu.cfg [sdX3] --------------------------------------
function funcUSB_Device_inst_menu () {
	declare -r USB_DEVICE="/dev/${USB_NAME}"
	declare -r USB_BOOT="/dev/${USB_NAME}1"
	declare -r USB_UEFI="/dev/${USB_NAME}2"
	declare -r USB_DATA="/dev/${USB_NAME}3"

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}install USB device ${USB_DATA}${TXT_RESET}"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "mount" "${USB_DATA}"
	mount "${USB_DATA}" "./${WORK_DIRS}/usb"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "${FNAME_MENU##*/}" "${USB_DATA}"
	cp --preserve=timestamps --no-preserve=mode,ownership "${FNAME_MENU}" "./${WORK_DIRS}/usb/"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "umount" "${USB_DATA}"
	umount "./${WORK_DIRS}/usb"
}

# --- USB Device install config file [sdX3] -----------------------------------
function funcUSB_Device_inst_conf () {
	declare -r USB_DEVICE="/dev/${USB_NAME}"
	declare -r USB_BOOT="/dev/${USB_NAME}1"
	declare -r USB_UEFI="/dev/${USB_NAME}2"
	declare -r USB_DATA="/dev/${USB_NAME}3"
	declare DIR_DIRS
	declare DIR_SRCS
	declare DIR_DEST
	declare DIR_PATH
#	declare DIR_WORK

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}install USB device ${USB_DATA}${TXT_RESET}"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "mount" "${USB_DATA}"
	mount "${USB_DATA}" "./${WORK_DIRS}/usb"
	# -------------------------------------------------------------------------
	for DIR_DIRS in "preseed" "nocloud" "kickstart" "autoyast"
	do
		DIR_SRCS="./${WORK_DIRS}/img/${DIR_DIRS}"
		DIR_DEST="./${WORK_DIRS}/usb/${DIR_DIRS}"
		if [[ ! -d "${DIR_SRCS}/." ]]; then
			continue
		fi
		if [[ ! -d "${DIR_DEST}/." ]]; then
			mkdir -p "${DIR_DEST}"
		fi
		funcPrintf "USB   device: %-24.24s : %s\n" "${DIR_DIRS}" "${USB_DATA}"
		DIR_PATH="$(pwd)/${DIR_DEST#\./}"
		pushd "${DIR_SRCS}" > /dev/null
			find . -name '*~' -prune -o -print | cpio -pdmu --quie "${DIR_PATH}/"
		popd > /dev/null
#		cp --preserve=timestamps --no-preserve=mode,ownership --recursive "${DIR_PATH}" "${DIR_DEST}/"
	done
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "umount" "${USB_DATA}"
	umount "./${WORK_DIRS}/usb"
}

# --- USB Device install initrd/vmlinuz image file [sdX3] ---------------------
function funcUSB_Device_inst_initrd () {
	declare -r USB_DEVICE="/dev/${USB_NAME}"
	declare -r USB_BOOT="/dev/${USB_NAME}1"
	declare -r USB_UEFI="/dev/${USB_NAME}2"
	declare -r USB_DATA="/dev/${USB_NAME}3"
	declare DIR_DIRS
	declare DIR_SRCS
	declare DIR_DEST
#	declare DIR_PATH
#	declare DIR_WORK

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}install USB device ${USB_DATA}${TXT_RESET}"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "mount" "${USB_DATA}"
	mount "${USB_DATA}" "./${WORK_DIRS}/usb"
	# -------------------------------------------------------------------------
	for DIR_DIRS in "install.amd" "live" "casper"
	do
		DIR_SRCS="./${WORK_DIRS}/img/${DIR_DIRS}"
		DIR_DEST="./${WORK_DIRS}/usb/${DIR_DIRS}"
		if [[ ! -d "${DIR_SRCS}/." ]]; then
			continue
		fi
		if [[ ! -d "${DIR_DEST}/." ]]; then
			mkdir -p "${DIR_DEST}"
		fi
		for DIR_PATH in "${DIR_SRCS}"/*
		do
			funcPrintf "USB   device: %-24.24s : %s\n" "copy ${DIR_DIRS}" "${DIR_PATH##*/}"
			nice -n 10 cp --preserve=timestamps --no-preserve=mode,ownership --recursive --update --dereference "${DIR_PATH}" "${DIR_DEST}/"
		done
	done

#	for DIR_SRCS in "./${WORK_DIRS}/img/images"/*
#	do
#		DIR_DIRS="${DIR_SRCS##*/}"
#		DIR_DEST="./${WORK_DIRS}/usb/images/${DIR_DIRS}"
#		if [[ ! -d "${DIR_DEST}/." ]]; then
#			mkdir -p "${DIR_DEST}"
#		fi
#		for DIR_PATH in "${DIR_SRCS}"/*
#		do
#			funcPrintf "USB   device: %-24.24s : %s\n" "copy ${DIR_DIRS}" "${DIR_PATH##*/}"
#			nice -n 10 cp --preserve=timestamps --no-preserve=mode,ownership --recursive --update --dereference "${DIR_PATH}" "${DIR_DEST}/"
#		done
#	done
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "umount" "${USB_DATA}"
	umount "./${WORK_DIRS}/usb"
}

# --- USB Device install iso image file [sdX3] --------------------------------
function funcUSB_Device_inst_iso () {
	declare -r USB_DEVICE="/dev/${USB_NAME}"
	declare -r USB_BOOT="/dev/${USB_NAME}1"
	declare -r USB_UEFI="/dev/${USB_NAME}2"
	declare -r USB_DATA="/dev/${USB_NAME}3"
	declare DIR_DIRS
	declare DIR_SRCS
	declare DIR_DEST
#	declare DIR_PATH
#	declare DIR_WORK

	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}install USB device ${USB_DATA}${TXT_RESET}"
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "mount" "${USB_DATA}"
	mount "${USB_DATA}" "./${WORK_DIRS}/usb"
	# -------------------------------------------------------------------------
	# <important> iso-scan does not search subdirectories
	# -------------------------------------------------------------------------
	for DIR_SRCS in "./${WORK_DIRS}/img/images"/*
	do
		DIR_DIRS="${DIR_SRCS##*/}"
		DIR_DEST="./${WORK_DIRS}/usb/images"
#		DIR_DEST="./${WORK_DIRS}/usb/images/${DIR_DIRS}"
		if [[ ! -d "${DIR_DEST}/." ]]; then
			mkdir -p "${DIR_DEST}"
		fi
		for DIR_PATH in "${DIR_SRCS}"/*
		do
			funcPrintf "USB   device: %-24.24s : %s\n" "copy ${DIR_DIRS}" "${DIR_PATH##*/}"
			nice -n 10 cp --preserve=timestamps --no-preserve=mode,ownership --recursive --update --dereference "${DIR_PATH}" "${DIR_DEST}/"
		done
	done
	# -------------------------------------------------------------------------
	funcPrintf "USB   device: %-24.24s : %s\n" "umount" "${USB_DATA}"
	umount "./${WORK_DIRS}/usb"
}

# --- Option ------------------------------------------------------------------
function funcOption () {
	while [ -n "${1:-}" ]
	do
		case $1 in
			-d | --device   ) shift; funcUSB_Device_select "$1";;
			-s | --source   ) shift; USB_INST="$1";;
			-f | --format   ) shift; USB_FORMAT="$1";;
			-n | --noformat )        USB_NOFORMAT=1;;
			* )
		esac
		shift
	done
}

### main ######################################################################
main () {
	declare -i start_time
	declare -i end_time

	if [[ "$(whoami)" != "root" ]]; then
		funcPrintf "execute as root user."
		exit 1
	fi
	# --- initialization ------------------------------------------------------
	if [[ "$(command -v tput 2> /dev/null)" != "" ]]; then
		ROW_SIZE=$(tput lines)
		COL_SIZE=$(tput cols)
	fi
	if [[ ${ROW_SIZE} -lt 25 ]]; then
		ROW_SIZE=25
	fi
	if [[ ${COL_SIZE} -lt 80 ]]; then
		COL_SIZE=80
	fi
	# --- test ----------------------------------------------------------------
#	funcColorTest
	# --- main ----------------------------------------------------------------
	start_time=$(date +%s)
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"
	# -------------------------------------------------------------------------
	mountpoint -q "./${WORK_DIRS}/mnt/" && (umount -q -f "./${WORK_DIRS}/mnt" || umount -q -lf "./${WORK_DIRS}/mnt" || true)
	mountpoint -q "./${WORK_DIRS}/usb/" && (umount -q -f "./${WORK_DIRS}/usb" || umount -q -lf "./${WORK_DIRS}/usb" || true)
	# -------------------------------------------------------------------------
	funcOption ${PROG_PRAM}
	# -------------------------------------------------------------------------
	if [[ ! "${USB_NAME}" =~ ^sd[a-z]$ ]]; then
		funcUSB_Device_select
	fi
	# -------------------------------------------------------------------------
	funcMake_directory
	if [[ -d "/mnt/hgfs/." ]]; then
		funcMake_link
	fi
	# -------------------------------------------------------------------------
#	touch "${CACHE_FNAME}"
#	funcRead_cache
	# -------------------------------------------------------------------------
	funcMenu_list
	funcDownload
	funcGet_module_in_dvd
	# -------------------------------------------------------------------------
	funcMake_conf
	funcRemake_initrd
	# -------------------------------------------------------------------------
	funcMake_grub_cfg
	funcMake_menu_cfg
	# -------------------------------------------------------------------------
	funcCopy_iso_image
	# -------------------------------------------------------------------------
	if [[ ! "${USB_NAME}" =~ ^sd[a-z]$ ]]; then
		funcPrintf "${TXT_RED}error USB device name [/dev/${USB_DEV}]${TXT_RESET}"
		exit 1
	fi
	# -------------------------------------------------------------------------
	if [[ USB_NOFORMAT -eq 0 ]]; then
		funcUSB_Device_format
		funcUSB_Device_inst_bootloader
	fi
	funcUSB_Device_inst_kbd
	funcUSB_Device_inst_grub
	funcUSB_Device_inst_menu
	funcUSB_Device_inst_conf
	funcUSB_Device_inst_initrd
	funcUSB_Device_inst_iso
	# -------------------------------------------------------------------------
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing end${TXT_RESET}"
	end_time=$(date +%s)
	echo "elapsed time: $((end_time-start_time)) [sec]"
}

	# === main ================================================================
	main

### memo ######################################################################
#   x   buzz        debian  1.1                             end of support    #
#   x   rex         debian  1.2                             end of support    #
#   x   bo          debian  1.3                             end of support    #
#   x   hamm        debian  2.0                             end of support    #
#   x   slink       debian  2.1                             end of support    #
#   x   potato      debian  2.2                             end of support    #
#   x   woody       debian  3.0                             end of support    #
#   x   sarge       debian  3.1                             end of support    #
#   x   etch        debian  4.0                             end of support    #
#   x   lenny       debian  5.0                             end of support    #
#   x   squeeze     debian  6.0                             end of support    #
#   x   wheezy      debian  7.0                             end of support    #
#   x   jessie      debian  8.0                             end of support    #
#   x   stretch     debian  9.0                             end of support    #
#   .   buster      debian 10.0     oldoldstable                              #
#   .   bullseye    debian 11.0     oldstable                                 #
#   .   bookworm    debian 12.0     stable                                    #
#   .   trixie      debian 13.0     testing                 test version      #
#   -   forky       debian 14.0                             unreleased        #
#   .   testing     debian xx.x     testing                 test version      #
#   x   warty       ubuntu  4.10    Warty Warthog           end of support    #
#   x   hoary       ubuntu  5.04    Hoary Hedgehog          end of support    #
#   x   breezy      ubuntu  5.10    Breezy Badger           end of support    #
#   x   dapper      ubuntu  6.06    Dapper Drake LTS        end of support    #
#   x   edgy        ubuntu  6.10    Edgy Eft                end of support    #
#   x   feisty      ubuntu  7.04    Feisty Fawn             end of support    #
#   x   gutsy       ubuntu  7.10    Gutsy Gibbon            end of support    #
#   x   hardy       ubuntu  8.04    Hardy Heron LTS         end of support    #
#   x   intrepid    ubuntu  8.10    Intrepid Ibex           end of support    #
#   x   jaunty      ubuntu  9.04    Jaunty Jackalope        end of support    #
#   x   karmic      ubuntu  9.10    Karmic Koala            end of support    #
#   x   lucid       ubuntu 10.04    Lucid Lynx LTS          end of support    #
#   x   maverick    ubuntu 10.10    Maverick Meerkat        end of support    #
#   x   natty       ubuntu 11.04    Natty Narwhal           end of support    #
#   x   oneiric     ubuntu 11.10    Oneiric Ocelot          end of support    #
#   x   precise     ubuntu 12.04    Precise Pangolin LTS    end of support    #
#   x   quantal     ubuntu 12.10    Quantal Quetzal         end of support    #
#   x   raring      ubuntu 13.04    Raring Ringtail         end of support    #
#   x   saucy       ubuntu 13.10    Saucy Salamander        end of support    #
#   x   trusty      ubuntu 14.04    Trusty Tahr LTS         end of support    #
#   x   utopic      ubuntu 14.10    Utopic Unicorn          end of support    #
#   x   vivid       ubuntu 15.04    Vivid Vervet            end of support    #
#   x   wily        ubuntu 15.10    Wily Werewolf           end of support    #
#   x   xenial      ubuntu 16.04    Xenial Xerus LTS        end of support    #
#   x   yakkety     ubuntu 16.10    Yakkety Yak             end of support    #
#   x   zesty       ubuntu 17.04    Zesty Zapus             end of support    #
#   x   artful      ubuntu 17.10    Artful Aardvark         end of support    #
#   x   bionic      ubuntu 18.04    Bionic Beaver LTS       end of support    #
#   x   cosmic      ubuntu 18.10    Cosmic Cuttlefish       end of support    #
#   x   disco       ubuntu 19.04    Disco Dingo             end of support    #
#   x   eoan        ubuntu 19.10    Eoan Ermine             end of support    #
#   .   focal       ubuntu 20.04    Focal Fossa LTS                           #
#   x   groovy      ubuntu 20.10    Groovy Gorilla          end of support    #
#   x   hirsute     ubuntu 21.04    Hirsute Hippo           end of support    #
#   x   impish      ubuntu 21.10    Impish Indri            end of support    #
#   .   jammy       ubuntu 22.04    Jammy Jellyfish LTS                       #
#   x   kinetic     ubuntu 22.10    Kinetic Kudu            end of support    #
#   .   lunar       ubuntu 23.04    Lunar Lobster                             #
#   .   mantic      ubuntu 23.10    Mantic Minotaur         test version      #
### eof #######################################################################
