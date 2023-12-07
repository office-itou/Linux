#!/bin/bash
###############################################################################
##
##	pxeboot configuration shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2023/12/05
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2023/12/05 000.0000 J.Itou         first release
##
###############################################################################

# *** initialization **********************************************************

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# Ends with status other than 0
	set -u								# End with undefined variable reference

	trap 'exit 1' 1 2 3 15

# --- check installation package ----------------------------------------------
#	dpkg --search filename
	declare -r -a APP_LIST=("grub-common" "grub-efi-amd64-bin" "grub-pc-bin" "7zip")
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

# *** data section ************************************************************

	if [[ -f "${0%.*}.cfg" ]]; then
		source "${0%.*}.cfg"
	else
		# --- server parameters -----------------------------------------------
		declare -r    DIRS_TFTP="/var/tftp"					# tftp directory
		declare -r    DIRS_HTTP="/var/www/html/pxe"			# http directory
		declare -r    DIRS_HGFS=""							# vmware shared directory
		declare -r    DIRS_TMPL="${PWD}/mkcd"				# configuration file's directory
		declare -r    ADDR_HTTP="http://192.168.1.254/pxe"	# http server address
		# --- setup pc parameters ---------------------------------------------
		declare -r    IPV4_ADDR="192.168.1.1"				# IPv4 address
		declare -r    IPV4_CIDR="24"						# IPv4 cidr
		declare -r    IPV4_MASK="255.255.255.0"				# IPv4 netmask
		declare -r    IPV4_GWAY="192.168.1.254"				# IPv4 gateway
		declare -r    IPV4_NSVR="192.168.1.254"				# IPv4 namesaver
	fi

# --- data list ---------------------------------------------------------------
#	 0: [m] menu / [o] output / [else] hidden
#	 1: iso image file copy destination directory
#	 2: entry name
#	 3: [unused]
#	 4: iso image file name
#	 5: boot loader's directory
#	 6: initial ramdisk
#	 7: kernel
#	 8: configuration file
#	 9: iso image file copy source directory
	if [[ -f "${0%.*}.lst" ]]; then
		source "${0%.*}.lst"
	else
		declare -r -a DATA_LIST=(                                                                                                                                                                                                                                                                         \
			"m  -                           Auto%20install%20mini.iso           -               -                                           -                                       -                           -                       -                                           -                   " \
			"o  debian-mini-10              Debian%2010                         debian          mini-buster-amd64.iso                       .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server_old.cfg       linux/debian        " \
			"o  debian-mini-11              Debian%2011                         debian          mini-bullseye-amd64.iso                     .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-mini-12              Debian%2012                         debian          mini-bookworm-amd64.iso                     .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-mini-13              Debian%2013                         debian          mini-trixie-amd64.iso                       .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-mini-testing         Debian%20testing                    debian          mini-testing-amd64.iso                      .                                       initrd.gz                   linux                   conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  ubuntu-mini-18.04           Ubuntu%2018.04                      ubuntu          mini-bionic-amd64.iso                       .                                       initrd.gz                   linux                   conf/preseed/ps_ubuntu_server_old.cfg       linux/ubuntu        " \
			"o  ubuntu-mini-20.04           Ubuntu%2020.04                      ubuntu          mini-focal-amd64.iso                        .                                       initrd.gz                   linux                   conf/preseed/ps_ubuntu_server_old.cfg       linux/ubuntu        " \
			"m  -                           Auto%20install%20Net%20install      -               -                                           -                                       -                           -                       -                                           -                   " \
			"o  debian-netinst-10           Debian%2010                         debian          debian-10.13.0-amd64-netinst.iso            install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server_old.cfg       linux/debian        " \
			"o  debian-netinst-11           Debian%2011                         debian          debian-11.8.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-netinst-12           Debian%2012                         debian          debian-12.2.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-netinst-13           Debian%2013                         debian          debian-13.0.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-netinst-testing      Debian%20testing                    debian          debian-testing-amd64-netinst.iso            install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  fedora-netinst-38           Fedora%20Server%2038                fedora          Fedora-Server-netinst-x86_64-38-1.6.iso     images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_fedora-38.cfg             linux/fedora        " \
			"o  fedora-netinst-39           Fedora%20Server%2039                fedora          Fedora-Server-netinst-x86_64-39-1.5.iso     images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_fedora-39.cfg             linux/fedora        " \
			"o  centos-stream-netinst-8     CentOS%20Stream%208                 centos          CentOS-Stream-8-x86_64-latest-boot.iso      images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_centos-stream-8.cfg       linux/centos        " \
			"o  centos-stream-netinst-9     CentOS%20Stream%209                 centos          CentOS-Stream-9-latest-x86_64-boot.iso      images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_centos-stream-9.cfg       linux/centos        " \
			"o  almalinux-netinst-9         Alma%20Linux%209                    almalinux       AlmaLinux-9-latest-x86_64-boot.iso          images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_almalinux-9.cfg           linux/almalinux     " \
			"o  rockylinux-netinst-8        Rocky%20Linux%208                   Rocky           Rocky-8.9-x86_64-boot.iso                   images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_rockylinux-8.cfg          linux/Rocky         " \
			"o  rockylinux-netinst-9        Rocky%20Linux%209                   Rocky           Rocky-9-latest-x86_64-boot.iso              images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_rockylinux-9.cfg          linux/Rocky         " \
			"o  miraclelinux-netinst-8      Miracle%20Linux%208                 miraclelinux    MIRACLELINUX-8.8-rtm-minimal-x86_64.iso     images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_miraclelinux-8.cfg        linux/miraclelinux  " \
			"o  miraclelinux-netinst-9      Miracle%20Linux%209                 miraclelinux    MIRACLELINUX-9.2-rtm-minimal-x86_64.iso     images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_miraclelinux-9.cfg        linux/miraclelinux  " \
			"o  opensuse-leap-netinst-15.5  openSUSE%20Leap%2015.5              openSUSE        openSUSE-Leap-15.5-NET-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_leap-15.5.xml        linux/openSUSE/     " \
			"o  opensuse-leap-netinst-15.6  openSUSE%20Leap%2015.6              openSUSE        openSUSE-Leap-15.6-NET-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_leap-15.6.xml        linux/openSUSE/     " \
			"o  opensuse-tumbleweednetinst  openSUSE%20Tumbleweed               openSUSE        openSUSE-Tumbleweed-NET-x86_64-Current.iso  boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_tumbleweed.xml       linux/openSUSE/     " \
			"m  -                           Auto%20install%20DVD%20media        -               -                                           -                                       -                           -                       -                                           -                   " \
			"o  debian-10                   Debian%2010                         debian          debian-10.13.0-amd64-DVD-1.iso              install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server_old.cfg       linux/debian        " \
			"o  debian-11                   Debian%2011                         debian          debian-11.8.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-12                   Debian%2012                         debian          debian-12.2.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-13                   Debian%2013                         debian          debian-13.0.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-testing              Debian%20testing                    debian          debian-testing-amd64-DVD-1.iso              install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  ubuntu-server-18.04         Ubuntu%2018.04%20Server             ubuntu          ubuntu-18.04.6-server-amd64.iso             install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   conf/preseed/ps_ubuntu_server_old.cfg       linux/ubuntu        " \
			"o  ubuntu-live-18.04           Ubuntu%2018.04%20Live%20Server      ubuntu          ubuntu-18.04.6-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server_old              linux/ubuntu        " \
			"o  ubuntu-live-20.04           Ubuntu%2020.04%20Live%20Server      ubuntu          ubuntu-20.04.6-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        " \
			"o  ubuntu-live-22.04           Ubuntu%2022.04%20Live%20Server      ubuntu          ubuntu-22.04.3-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        " \
			"o  ubuntu-live-23.04           Ubuntu%2023.04%20Live%20Server      ubuntu          ubuntu-23.04-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        " \
			"o  ubuntu-live-23.10           Ubuntu%2023.10%20Live%20Server      ubuntu          ubuntu-23.10-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        " \
			"o  ubuntu-live-24.04           Ubuntu%2024.04%20Live%20Server      ubuntu          ubuntu-24.04-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        " \
			"o  ubuntu-live-noble           Ubuntu%20noble%20Live%20Server      ubuntu          noble-live-server-amd64.iso                 casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_server                  linux/ubuntu        " \
			"o  fedora-38                   Fedora%20Server%2038                fedora          Fedora-Server-dvd-x86_64-38-1.6.iso         images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_fedora-38.cfg             linux/fedora        " \
			"o  fedora-39                   Fedora%20Server%2039                fedora          Fedora-Server-dvd-x86_64-39-1.5.iso         images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_fedora-39.cfg             linux/fedora        " \
			"o  centos-stream-8             CentOS%20Stream%208                 centos          CentOS-Stream-8-x86_64-latest-dvd1.iso      images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_centos-stream-8.cfg       linux/centos        " \
			"o  centos-stream-9             CentOS%20Stream%209                 centos          CentOS-Stream-9-latest-x86_64-dvd1.iso      images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_centos-stream-9.cfg       linux/centos        " \
			"o  almalinux-9                 Alma%20Linux%209                    almalinux       AlmaLinux-9-latest-x86_64-dvd.iso           images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_almalinux-9.cfg           linux/almalinux     " \
			"o  rockylinux-8                Rocky%20Linux%208                   Rocky           Rocky-8.8-x86_64-dvd1.iso                   images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_rockylinux-8.cfg          linux/Rocky         " \
			"o  rockylinux-9                Rocky%20Linux%209                   Rocky           Rocky-9-latest-x86_64-dvd.iso               images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_rockylinux-9.cfg          linux/Rocky         " \
			"o  miraclelinux-8              Miracle%20Linux%208                 miraclelinux    MIRACLELINUX-8.8-rtm-x86_64.iso             images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_miraclelinux-8.cfg        linux/miraclelinux  " \
			"o  miraclelinux-9              Miracle%20Linux%209                 miraclelinux    MIRACLELINUX-9.2-rtm-x86_64.iso             images/pxeboot                          initrd.img                  vmlinuz                 conf/kickstart/ks_miraclelinux-9.cfg        linux/miraclelinux  " \
			"o  opensuse-leap-15.5          openSUSE%20Leap%2015.5              openSUSE        openSUSE-Leap-15.5-DVD-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_leap-15.5.xml        linux/openSUSE/     " \
			"o  opensuse-leap-15.6          openSUSE%20Leap%2015.6              openSUSE        openSUSE-Leap-15.6-DVD-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_leap-15.6.xml        linux/openSUSE/     " \
			"o  opensuse-tumbleweed         openSUSE%20Tumbleweed               openSUSE        openSUSE-Tumbleweed-DVD-x86_64-Current.iso  boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_tumbleweed.xml       linux/openSUSE/     " \
			"o  windows-10                  Windows%2010                        windows         Win10_22H2_Japanese_x64.iso                 -                                       -                           -                       -                                           windows/Windows10   " \
			"o  windows-11                  Windows%2011                        windows         Win11_23H2_Japanese_x64_custom.iso          -                                       -                           -                       -                                           windows/Windows11   " \
			"m  -                           Live%20media                        -               -                                           -                                       -                           -                       -                                           -                   " \
			"o  debian-live-10              Debian%2010%20Live                  debian          debian-live-10.13.0-amd64-lxde.iso          live                                    initrd.img-4.19.0-21-amd64  vmlinuz-4.19.0-21-amd64 conf/preseed/ps_debian_desktop_old.cfg      linux/debian        " \
			"o  debian-live-11              Debian%2011%20Live                  debian          debian-live-11.8.0-amd64-lxde.iso           live                                    initrd.img-5.10.0-26-amd64  vmlinuz-5.10.0-26-amd64 conf/preseed/ps_debian_desktop.cfg          linux/debian        " \
			"o  debian-live-12              Debian%2012%20Live                  debian          debian-live-12.2.0-amd64-lxde.iso           live                                    initrd.img                  vmlinuz                 conf/preseed/ps_debian_desktop.cfg          linux/debian        " \
			"o  debian-live-13              Debian%2013%20Live                  debian          debian-live-13.0.0-amd64-lxde.iso           live                                    initrd.img                  vmlinuz                 conf/preseed/ps_debian_desktop.cfg          linux/debian        " \
			"o  debian-live-testing         Debian%20testing%20Live             debian          debian-live-testing-amd64-lxde.iso          live                                    initrd.img                  vmlinuz                 conf/preseed/ps_debian_desktop.cfg          linux/debian        " \
			"x  ubuntu-desktop-18.04        Ubuntu%2018.04%20Desktop            ubuntu          ubuntu-18.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop_old.cfg    linux/ubuntu        " \
			"o  ubuntu-desktop-20.04        Ubuntu%2020.04%20Desktop            ubuntu          ubuntu-20.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        " \
			"o  ubuntu-desktop-22.04        Ubuntu%2022.04%20Desktop            ubuntu          ubuntu-22.04.3-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        " \
			"o  ubuntu-desktop-23.04        Ubuntu%2023.04%20Desktop            ubuntu          ubuntu-23.04-desktop-amd64.iso              casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        " \
			"o  ubuntu-desktop-23.10        Ubuntu%2023.10%20Desktop            ubuntu          ubuntu-23.10.1-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_desktop                 linux/ubuntu        " \
			"o  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop            ubuntu          ubuntu-24.04-desktop-amd64.iso              casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_desktop                 linux/ubuntu        " \
			"o  ubuntu-desktop-noble        Ubuntu%20noble%20Desktop            ubuntu          noble-desktop-amd64.iso                     casper                                  initrd                      vmlinuz                 conf/nocloud/ubuntu_desktop                 linux/ubuntu        " \
			"o  ubuntu-legacy-23.04         Ubuntu%2023.04%20Legacy%20Desktop   ubuntu          ubuntu-23.04-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop_old.cfg    linux/ubuntu        " \
			"o  ubuntu-legacy-23.10         Ubuntu%2023.10%20Legacy%20Desktop   ubuntu          ubuntu-23.10-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        " \
			"o  ubuntu-legacy-24.04         Ubuntu%2024.04%20Legacy%20Desktop   ubuntu          ubuntu-24.04-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        " \
			"o  ubuntu-legacy-noble         Ubuntu%20noble%20Legacy%20Desktop   ubuntu          noble-desktop-legacy-amd64.iso              casper                                  initrd                      vmlinuz                 conf/preseed/ps_ubiquity_desktop.cfg        linux/ubuntu        " \
			"m  -                           System%20tools                      -               -                                           -                                       -                           -                       -                                           -                   " \
			"o  memtest86+                  Memtest86+                          memtest86+      mt86plus_6.20_64.grub.iso                   .                                       EFI/BOOT/memtest            boot/memtest            -                                           linux/memtest86+    " \
		) # 0:  1:                          2:                                  3:              4:                                          5:                                      6:                          7:                      8:                                          9:
	fi

# --- working directory name --------------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r    PROG_PRAM="$@"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    WORK_DIRS="${PROG_NAME%.*}"
	declare -a    COMD_LINE=("")
	if [[ ${#@} -gt 0 ]]; then
		COMD_LINE=($@)
	fi

# --- work variables ----------------------------------------------------------
	declare -r    OLD_IFS="${IFS}"
	declare -i    RET_CD=0
	declare -i    I=0
	declare -i    J=0
	declare       INS_STR=""

# --- set minimum display size ------------------------------------------------
	declare -i    ROW_SIZE=80
	declare -i    COL_SIZE=25

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

# *** function section (common functions) **************************************

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

#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "         1         2         3         4         5         6         7         8         9         0         1         2"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "　　　　　　　　　１　　　　　　　　　２　　　　　　　　　３　　　　　　　　　４　　　　　　　　　５　　　　　　　　　６　　　　　　　　　７　　　　　　　　　８　　　　　　　　　９　　　　　　　　　０　　　　　　　　　１　　　　　　　　　２"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "0　　　　　　　　　１　　　　　　　　　２　　　　　　　　　３　　　　　　　　　４　　　　　　　　　５　　　　　　　　　６　　　　　　　　　７　　　　　　　　　８　　　　　　　　　９　　　　　　　　　０　　　　　　　　　１　　　　　　　　　２"
#	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}%s${TXT_RESET}\n" "0１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０１２３４５６７８９０"
#	exit 0
}

# --- is numeric --------------------------------------------------------------
function funcIsNumeric() {
	if [[ "${1:-""}" =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
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
	# https://www.tohoho-web.com/ex/dash-tilde.html
#	declare -r    OLD_IFS="${IFS}"
#	declare -i    RET_CD
	declare -r    CHR_ESC="$(echo -n -e "\033")"
	declare -i    MAX_COLS=${COL_SIZE:-80}
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
function funcCurl() {
#	declare -r    OLD_IFS="${IFS}"
#	declare -i    RET_CD
#	declare -i    I
	declare       INP_URL="$(echo "$@" | sed -n -e 's%^.* \(\(http\|https\)://.*\)$%\1%p')"
	declare       OUT_DIR="$(echo "$@" | sed -n -e 's%^.* --output-dir *\(.*\) .*$%\1%p' | sed -e 's%/$%%')"
	declare       OUT_FILE="$(echo "$@" | sed -n -e 's%^.* --output *\(.*\) .*$%\1%p' | sed -e 's%/$%%')"
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
	declare -i    INT_UNT
	declare -a    TXT_UNT=("Byte" "KiB" "MiB" "GiB" "TiB")
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

# *** function section (sub functions) ****************************************

# --- preseed_kill_dhcp.sh ----------------------------------------------------
function funcMake_preseed_kill_dhcp_sh() {
	declare -r    FILE_NAME="${DIRS_HTTP}/conf/preseed/preseed_kill_dhcp.sh"

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_preseed_kill_dhcp_sh${TXT_RESET}"

	# --- make directory ------------------------------------------------------
	mkdir -p "${FILE_NAME%/*}"

	# --- make shell ----------------------------------------------------------
	cat <<- '_EOT_SH_' | sed 's/^ *//g' > "${FILE_NAME}"
		#!/bin/sh
		
		### initialization ############################################################
		#	set -n								# Check for syntax errors
		#	set -x								# Show command and argument expansion
		 	set -o ignoreeof					# Do not exit with Ctrl+D
		 	set +m								# Disable job control
		 	set -e								# Ends with status other than 0
		 	set -u								# End with undefined variable reference
		
		 	trap 'exit 1' 1 2 3 15
		
		### Main ######################################################################
		 	/bin/kill-all-dhcp
		 	/bin/netcfg
		### Termination ###############################################################
		 	exit 0
		### EOF #######################################################################
_EOT_SH_
}

# --- preseed_sub_command.sh --------------------------------------------------
function funcMake_preseed_sub_command_sh() {
	declare -r    FILE_NAME="${DIRS_HTTP}/conf/preseed/preseed_sub_command.sh"

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_preseed_sub_command_sh${TXT_RESET}"

	# --- make directory ------------------------------------------------------
	mkdir -p "${FILE_NAME%/*}"

	# --- make shell ----------------------------------------------------------
	cat <<- '_EOT_SH_' | sed 's/^ *//g' > "${FILE_NAME}"
		#!/bin/sh
		
		### initialization ############################################################
		#	set -n								# Check for syntax errors
		#	set -x								# Show command and argument expansion
		 	set -o ignoreeof					# Do not exit with Ctrl+D
		 	set +m								# Disable job control
		 	set -e								# Ends with status other than 0
		 	set -u								# End with undefined variable reference
		
		 	trap 'exit 1' 1 2 3 15
		
		 	readonly PROG_PRAM="$*"
		 	readonly PROG_NAME="${0##*/}"
		 	readonly WORK_DIRS="${0%/*}"
		 	readonly DIST_NAME="$(uname -v | tr [A-Z] [a-z] | sed -n -e 's/.*\(debian\|ubuntu\).*/\1/p')"
		 	readonly COMD_LINE="$(cat /proc/cmdline)"
		 	echo "${PROG_NAME}: === Start ==="
		 	echo "${PROG_NAME}: PROG_PRAM=${PROG_PRAM}"
		 	echo "${PROG_NAME}: PROG_NAME=${PROG_NAME}"
		 	echo "${PROG_NAME}: WORK_DIRS=${WORK_DIRS}"
		 	echo "${PROG_NAME}: DIST_NAME=${DIST_NAME}"
		 	echo "${PROG_NAME}: COMD_LINE=${COMD_LINE}"
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
		 		cp -a "${PROG_PATH}" "${ROOT_DIRS}/tmp/"
		 		cp -a "${CONF_FILE}" "${ROOT_DIRS}/tmp/"
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
		
		### common ###########################################################
		# --- IPv4 netmask conversion -------------------------------------------------
		funcIPv4GetNetmask () {
		 	INP_ADDR="$1"
		#	DEC_ADDR="$((0xFFFFFFFF ^ (2**(32-INP_ADDR)-1)))"
		 	WORK=1
		 	LOOP=$((32-INP_ADDR))
		 	while [ $LOOP -gt 0 ]
		 	do
		 		LOOP=$((LOOP-1))
		 		WORK=$((WORK*2))
		 	done
		 	DEC_ADDR="$((0xFFFFFFFF ^ (WORK-1)))"
		 	printf '%d.%d.%d.%d' \
		 	    $(( DEC_ADDR >> 24        )) \
		 	    $(((DEC_ADDR >> 16) & 0xFF)) \
		 	    $(((DEC_ADDR >>  8) & 0xFF)) \
		 	    $(( DEC_ADDR        & 0xFF))
		 }
		
		# --- IPv4 netmask bit conversion ---------------------------------------------
		funcIPv4GetNetmaskBits () {
		 	INP_ADDR="$1"
		 	echo "${INP_ADDR}" | \
		 	    awk -F '.' '{
		 	        split($0, OCTETS);
		 	        for (I in OCTETS) {
		 	            MASK += 8 - log(2^8 - OCTETS[I])/log(2);
		 	        }
		 	        print MASK
		 	    }'
		}
		
		### subroutine ################################################################
		# --- packages ----------------------------------------------------------------
		funcInstallPackages () {
		 	echo "${PROG_NAME}: funcInstallPackages"
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
		 	LIST_DPKG="$(LANG=C dpkg-query --list ${LIST_PACK} 2>&1 | grep -E -v '^ii|^\+|^\||^Desired' || true)"
		 	if [ -z "${LIST_DPKG}" ]; then
		 		echo "${PROG_NAME}: Finish the installation"
		 		return
		 	fi
		 	echo "${PROG_NAME}: Run the installation"
		 	echo "${PROG_NAME}: LIST_DPKG="
		 	echo "${PROG_NAME}: <<<"
		 	echo "${LIST_DPKG}"
		 	echo "${PROG_NAME}: >>>"
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
		 	echo "${PROG_NAME}: funcSetupNetwork"
		 	#--- preseed.cfg parameter ------------------------------------------------
		 	FIX_IPV4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/\(disable_dhcp\|disable_autoconfig\)[[:blank:]]\+/ s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_IPV4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_ipaddress[[:blank:]]\+/                        s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_MASK="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_netmask[[:blank:]]\+/                          s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_GATE="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_gateway[[:blank:]]\+/                          s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_DNS4="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_nameservers[[:blank:]]\+/                      s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_WGRP="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_domain[[:blank:]]\+/                           s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_HOST="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_hostname[[:blank:]]\+/                         s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_WGRP="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/get_domain[[:blank:]]\+/                           s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_NAME="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+netcfg\/choose_interface[[:blank:]]\+/                     s/^.*[[:blank:]]//p' "${TEMP_FILE}")"
		 	NIC_FQDN="${NIC_HOST}"
		 	if [ -n "${NIC_WGRP}" ]; then
		 		NIC_FQDN="${NIC_HOST}.${NIC_WGRP}"
		 	fi
		 	NIC_BIT4=""
		 	NIC_MADR=""
		 	CON_NAME=""
		 	#--- /proc/cmdline parameter  ---------------------------------------------
		 	for LINE in ${COMD_LINE}
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
		 		esac
		 	done
		 	#--- network parameter ----------------------------------------------------
		 	NIC_HOST="${NIC_FQDN%.*}"
		 	NIC_WGRP="${NIC_FQDN#*.}"
		 	if [ -z "${NIC_WGRP}" ]; then
		 		NIC_WGRP="$(awk '/[ \t]*search[ \t]+/ {print $2;}' /etc/resolv.conf)"
		 	fi
		 	if [ -n "${NIC_MASK}" ]; then
		 		NIC_BIT4="$(funcIPv4GetNetmaskBits "${NIC_MASK}")"
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
		 	CON_NAME="ethernet_$(echo "${NIC_MADR}" | sed -n -e 's/://gp')_cable"
		 	#--- hostname / hosts -----------------------------------------------------
		 	OLD_FQDN="$(cat /etc/hostname)";
		 	OLD_HOST="${OLD_FQDN%.*}"
		 	OLD_WGRP="${OLD_FQDN#*.}"
		 	echo "${NIC_FQDN}" > /etc/hostname;
		 	sed -i /etc/hosts                                                          \
		 	    -e 's/\([ \t]\+\)'${OLD_HOST}'\([ \t]*\)$/\1'${NIC_HOST}'\2/'          \
		 	    -e 's/\([ \t]\+\)'${OLD_FQDN}'\([ \t]*$\|[ \t]\+\)/\1'${NIC_FQDN}'\2/'
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
		 	echo "${PROG_NAME}: CON_NAME=${CON_NAME}"
		 	echo "${PROG_NAME}: --- hostname ---"
		 	cat /etc/hostname
		 	echo "${PROG_NAME}: --- hosts ---"
		 	cat /etc/hosts
		 	echo "${PROG_NAME}: --- resolv.conf ---"
		 	cat /etc/resolv.conf
		 	#--- exit for DHCP --------------------------------------------------------
		 	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		 		return
		 	fi
		 	# --- connman -------------------------------------------------------------
		 	if [ -d "${ROOT_DIRS}/etc/connman" ]; then
		 		echo "${PROG_NAME}: funcSetupNetwork: connman"
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
		 		echo "${PROG_NAME}: funcSetupNetwork: netplan"
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
		 	echo "${PROG_NAME}: funcChange_gdm3_configure"
		 	if [ -f "${ROOT_DIRS}/etc/gdm3/custom.conf" ]; then
		 		sed -i.orig "${ROOT_DIRS}/etc/gdm3/custom.conf" \
		 		    -e '/WaylandEnable=false/ s/^#//'
		 	fi
		}
		
		### Main ######################################################################
		funcMain () {
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
		 	esac
		}
		
		 	funcMain
		### Termination ###############################################################
		 	echo "${PROG_NAME}: === End ==="
		 	exit 0
		### EOF #######################################################################
_EOT_SH_
}

# --- preseed.cfg -------------------------------------------------------------
function funcMake_preseed_cfg() {
	declare -r    DIRS_NAME="${DIRS_HTTP}/conf/preseed"
	declare -r -a FILE_LIST=(                       \
		"ps_debian_"{server,desktop}{,_old}".cfg"   \
		"ps_ubuntu_"{server,desktop}{,_old}".cfg"   \
		"ps_ubiquity_"{server,desktop}{,_old}".cfg" \
	)
	declare       DSTR_NAME=""
	declare       FILE_PATH=""
	declare       FILE_NAME=""
	declare       FILE_TMPL=""

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_preseed_cfg${TXT_RESET}"

	# --- make directory ------------------------------------------------------
	mkdir -p "${DIRS_NAME}"

	# --- make confl ----------------------------------------------------------
	for I in "${!FILE_LIST[@]}"
	do
		FILE_NAME="${FILE_LIST[I]}"
		FILE_PATH="${DIRS_NAME}/${FILE_NAME}"
		DSTR_NAME="${FILE_NAME#*_}"
		DSTR_NAME="${DSTR_NAME%%_*}"
		FILE_TMPL="${DIRS_TMPL}/preseed_${DSTR_NAME}.cfg"
		if [[ "${DSTR_NAME}" = "ubiquity" ]]; then
			FILE_TMPL="${FILE_TMPL/ubiquity/ubuntu}"
		fi
		# ---------------------------------------------------------------------
		echo "${FILE_PATH}"
		# ---------------------------------------------------------------------
		cp "${FILE_TMPL}" "${FILE_PATH}"
		if [[ "${FILE_PATH}" =~ _old ]]; then
			sed -i "${FILE_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'  \
			    -e 's/bind9-dnsutils/dnsutils/'
		fi
		if [[ "${FILE_PATH}" =~ _desktop ]]; then
			sed -i "${FILE_PATH}"                                                                                        \
			    -e '/^[ \t]*packages:$/,/^[ \t]*-.*$/                                                                { ' \
			    -e ':l; /\(^[# \t]*d-i[ \t]\+\|^#.*-$\)/! { /^#.*[^-]*$/! { /\\$/! s/$/ \\/ }; s/^# /  /; n; b l; }; } '
		fi
		if [[ "${DSTR_NAME}" = "ubiquity" ]]; then
			IFS= INS_STR=$(
				sed -n '/^[^#].*preseed\/late_command/,/[^\\]$/p' "${FILE_PATH}" | \
				sed -e 's/\\/\\\\/g'                                               \
				    -e 's/d-i/ubiquity/'                                           \
				    -e 's%preseed\/late_command%ubiquity\/success_command%'      | \
				sed -e ':l; N; s/\n/\\n/; b l;'
			)
			IFS=${OLD_IFS}
			if [ -n "${INS_STR}" ]; then
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
}

# --- nocloud -----------------------------------------------------------------
function funcMake_nocloud() {
	declare -r -a DIRS_LIST=("${DIRS_HTTP}/conf/nocloud/ubuntu_"{server,desktop}{,_old})
	declare       DIRS_NAME=""
	declare -r    FILE_TMPL="${DIRS_TMPL}/nocloud-ubuntu-user-data"

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_nocloud${TXT_RESET}"

	# --- make confl ----------------------------------------------------------
	for I in "${!DIRS_LIST[@]}"
	do
		DIRS_NAME="${DIRS_LIST[I]}"
		# ---------------------------------------------------------------------
		echo "${DIRS_NAME}"
		# --- make directory --------------------------------------------------
		mkdir -p "${DIRS_NAME}"
		# ---------------------------------------------------------------------
		cp "${FILE_TMPL}" "${DIRS_NAME}/user-data"
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
	done
}

# --- kickstart ---------------------------------------------------------------
function funcMake_kickstart() {
	declare -r    DIRS_NAME="${DIRS_HTTP}/conf/kickstart"
	declare -r -a FILE_LIST=(
		"ks_almalinux-9.cfg"            \
		"ks_centos-stream-"{8..9}".cfg" \
		"ks_fedora-"{38..39}".cfg"      \
		"ks_miraclelinux-"{8..9}".cfg"  \
		"ks_rockylinux-"{8..9}".cfg"    \
	)
	declare       FILE_PATH=""
	declare       FILE_NAME=""
	declare -r    FILE_TMPL="${DIRS_TMPL}/kickstart_common.cfg"
	declare       DSTR_NAME=""
	declare       DSTR_NUMS=""
	declare       RLNX_NUMS=""
	declare -r    BASE_ARCH="x86_64"
	declare       DSTR_SECT=""

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_kickstart${TXT_RESET}"

	# --- make directory ------------------------------------------------------
	mkdir -p "${DIRS_NAME}"

	# --- make confl ----------------------------------------------------------
	for I in "${!FILE_LIST[@]}"
	do
		FILE_NAME="${FILE_LIST[I]}"
		FILE_PATH="${DIRS_NAME}/${FILE_NAME}"
		DSTR_NAME="${FILE_NAME#*_}"
		DSTR_NAME="${DSTR_NAME%-*}"
		DSTR_NUMS="${FILE_NAME##*-}"
		DSTR_NUMS="${DSTR_NUMS%.*}"
		RLNX_NUMS="${DSTR_NUMS}"
		if [[ "${DSTR_NAME}" = "fedora" ]] && [[ ${DSTR_NUMS} -ge 38 ]] && [[ ${DSTR_NUMS} -le 39 ]]; then
			RLNX_NUMS="9"
		fi
		# ---------------------------------------------------------------------
		echo "${FILE_PATH}"
		# ---------------------------------------------------------------------
		cp "${FILE_TMPL}" "${FILE_PATH}"
		# ---------------------------------------------------------------------
		DSTR_SECT="${DSTR_NAME/-/ }"
		if [[ "${DSTR_NAME}" = "centos-stream" ]]; then
			DSTR_SECT="${DSTR_NAME/-/ }-${DSTR_NUMS}"
		fi
		sed -i "${FILE_PATH}"                          \
		    -e "/^cdrom/ s/^/#/                      " \
		    -e "s/_HOSTNAME_/${DSTR_NAME%%-*}/       " \
		    -e "/^#.*(${DSTR_SECT}).*$/,/^$/       { " \
		    -e "/_WEBADDR_/                        { " \
		    -e "/^#url[ \t]\+/  s/^#//g              " \
		    -e "/^#repo[ \t]\+/ s/^#//g              " \
		    -e "s/\$releasever/${DSTR_NUMS}/g        " \
		    -e "s/\$basearch/${BASE_ARCH}/g       }} " \
		    -e "/%post/,/%end/                     { " \
		    -e "s/\$releasever/${RLNX_NUMS}/g      } "
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
		sed -i "${FILE_PATH}"                          \
		    -e "/^#.*(${DSTR_SECT}).*$/,/^$/       { " \
		    -e "s%_WEBADDR_%${ADDR_HTTP}/imgs%g    } "
		sed -e "/%packages/,/%end/ {"                  \
		    -e "/desktop/ s/^-//g  }"                  \
		    "${FILE_PATH}"                             \
		>   "${FILE_PATH/.cfg/_desktop.cfg}"
	done
}

# --- autoyast ----------------------------------------------------------------
function funcMake_autoyast() {
	declare -r    DIRS_NAME="${DIRS_HTTP}/conf/autoyast"
	declare -r -a FILE_LIST=(
		"autoinst_"{leap-{15.5,15.6},tumbleweed}{,_lxde}".xml"
	)
	declare       FILE_PATH=""
	declare       FILE_NAME=""
	declare -r    FILE_TMPL="${DIRS_TMPL}/yast_opensuse.xml"
	declare       DSTR_NUMS=""
	declare -r    BASE_ARCH="x86_64"

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_autoyast${TXT_RESET}"

	# --- make directory ------------------------------------------------------
	mkdir -p "${DIRS_NAME}"
	# --- make confl ----------------------------------------------------------
	for I in "${!FILE_LIST[@]}"
	do
		FILE_NAME="${FILE_LIST[I]}"
		FILE_PATH="${DIRS_NAME}/${FILE_NAME}"
		DSTR_NUMS="${FILE_NAME#*_}"
		DSTR_NUMS="${DSTR_NUMS%.*}"
		DSTR_NUMS="${DSTR_NUMS%_*}"
		# ---------------------------------------------------------------------
		echo "${FILE_PATH}"
		# ---------------------------------------------------------------------
		cp "${FILE_TMPL}" "${FILE_PATH}"
		# ---------------------------------------------------------------------
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
}

# --- grub.cfg ----------------------------------------------------------------
function funcMake_grub_cfg() {
	declare -r    DIRS_NAME="${DIRS_TFTP}/grub"
	declare -r    FILE_PATH="${DIRS_NAME}/grub.cfg"

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_grub_cfg${TXT_RESET}"

	# -------------------------------------------------------------------------
	echo "${FILE_PATH}"

	# --- make directory ------------------------------------------------------
	mkdir -p "${DIRS_NAME}"

	# --- make grub.cfg -------------------------------------------------------
	cat <<- '_EOT_' | sed 's/^ *//g' > "${FILE_PATH}"
		set default=0
		set timeout=-1
		
		if [ x${feature_default_font_path} = xy ] ; then
		 	font=unicode
		else
		 	font=${prefix}/font.pf2
		fi
		
		if loadfont $font ; then
		#	set lang=ja_JP
		 	set gfxmode=1280x720
		 	set gfxpayload=keep
		
		 	if [ "${grub_platform}" = "efi" ]; then
		 		insmod efi_gop
		 		insmod efi_uga
		 	else
		 		insmod vbe
		 		insmod vga
		 	fi
		
		 	insmod gfxterm
		 	insmod gettext
		 	terminal_output gfxterm
		fi
		
		set menu_color_normal=cyan/blue
		set menu_color_highlight=white/blue
		
		#export lang
		export gfxmode
		export gfxpayload
		export menu_color_normal
		export menu_color_highlight
		
		insmod play
		play 960 440 1 0 4 440 1
		
		source /grub/menu.cfg
		
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
		
		if [ "${grub_platform}" = "efi" ]; then
		 	menuentry '- Boot from next volume' {
		 		exit 1
		 	}
		
		 	menuentry '- UEFI Firmware Settings' {
		 		fwsetup
		 	}
		fi
_EOT_
}

# --- menu.cfg ----------------------------------------------------------------
function funcMake_menu_cfg() {
	declare -r    DIRS_NAME="${DIRS_TFTP}/grub"
	declare -r    DIRS_BOOT="${DIRS_TFTP}/boot"
	declare -r    DIRS_IMGS="${DIRS_HTTP}/imgs"
	declare -r    FILE_PATH="${DIRS_NAME}/menu.cfg"
	declare -a    DATA_LINE=""
	declare       ISOS_PATH=""
	declare       LINK_PATH=""
	declare       MENU_ETRY=""
	declare       FILE_TIME=""
	declare -r    HTTP_PROT="${ADDR_HTTP%%:*}"
	declare       HTTP_ADDR="${ADDR_HTTP#*//}"
	              HTTP_ADDR="${HTTP_ADDR%%/*}"
	declare -r    HTTP_DIRS="${ADDR_HTTP##*/}"
	declare -r    HTTP_ROOT="${HTTP_PROT}://${HTTP_ADDR}${HTTP_DIRS}"
	declare       NETS_CONF=""
	declare       AUTO_CONF=""
	declare       LANG_CONF=""
	declare       OPTN_PARM=""
	declare       LOOP_BACK=""

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_menu_cfg${TXT_RESET}"

	# -------------------------------------------------------------------------
	echo "${FILE_PATH}"

	# --- make directory ------------------------------------------------------
	mkdir -p "${DIRS_NAME}"

	# --- make menu.cfg -------------------------------------------------------
	rm "${FILE_PATH}"
	for I in "${!DATA_LIST[@]}"
	do
		DATA_LINE=(${DATA_LIST[I]})
		ISOS_PATH="${DIRS_HTTP}/isos/${DATA_LINE[4]}"
		LINK_PATH="${DIRS_HGFS}/${DATA_LINE[9]}/${DATA_LINE[4]}"
		# --- menu entry ------------------------------------------------------
		if [[ "${DATA_LINE[0]}" = "m" ]]; then
			MENU_ETRY="[ ${DATA_LINE[2]//%20/ } ... ]"
			echo "${MENU_ETRY}"
			cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
				menuentry '${MENU_ETRY}' {
				 	true
				}
		
_EOT_
			continue
		fi
		# --- make link -------------------------------------------------------
		if [[ -n "${DIRS_HGFS}" ]]; then
			if [[ "${DATA_LINE[0]}" != "o" ]] || [[ ! -f "${LINK_PATH}" ]]; then
				continue
			fi
			mkdir -p "${ISOS_PATH%/*}"
			ln -s -f "${LINK_PATH}" "${ISOS_PATH%/*}"
		fi
		# --- file existence check --------------------------------------------
		if [[ "${DATA_LINE[0]}" != "o" ]] || [[ ! -f "${ISOS_PATH}" ]]; then
			continue
		fi
		echo "${ISOS_PATH}"
		# --- copy file -------------------------------------------------------
		mount -r -o loop "${ISOS_PATH}" /media
		mkdir -p "${DIRS_BOOT}/${DATA_LINE[1]}"
		case "${DATA_LINE[1]}" in
			debian-live-*         | \
			ubuntu-desktop-*      | \
			ubuntu-legacy-*       )     # loopback ----------------------------
				;;
			*-mini-*              )     # mini.iso ----------------------------
				rsync --archive --human-readable --update --delete "/media/"{"${DATA_LINE[6]}","${DATA_LINE[7]}"}                 "${DIRS_BOOT}/${DATA_LINE[1]}/"
				;;
			debian-*              )     # DVD / netinst
				rsync --archive --human-readable --update --delete "/media/${DATA_LINE[5]}/"{"${DATA_LINE[6]}","${DATA_LINE[7]}"} "${DIRS_BOOT}/${DATA_LINE[1]}/"
				;;
			ubuntu-*              | \
			fedora-*              | \
			centos-*              | \
			almalinux-*           | \
			rockylinux-*          | \
			miraclelinux-*        | \
			opensuse-*            )     # DVD / netinst -----------------------
				rsync --archive --human-readable --update --delete "/media/${DATA_LINE[5]}/"{"${DATA_LINE[6]}","${DATA_LINE[7]}"} "${DIRS_BOOT}/${DATA_LINE[1]}/"
				mkdir -p "${DIRS_IMGS}/${DATA_LINE[1]}"
				rsync --archive --human-readable --update --delete  /media/                                                       "${DIRS_IMGS}/${DATA_LINE[1]}/"
				;;
			memtest86\+           )     # memtest86+ --------------------------
				mkdir -p "${DIRS_BOOT}/${DATA_LINE[1]}/"{"${DATA_LINE[6]%/*}","${DATA_LINE[7]%/*}"}
				rsync --archive --human-readable --update --delete "/media/${DATA_LINE[6]}"                                       "${DIRS_BOOT}/${DATA_LINE[1]}/${DATA_LINE[6]%/*}/"
				rsync --archive --human-readable --update --delete "/media/${DATA_LINE[7]}"                                       "${DIRS_BOOT}/${DATA_LINE[1]}/${DATA_LINE[7]%/*}/"
				;;
		esac
		umount /media
		FILE_TIME="$(TZ=UTC ls -lL --time-style="+%Y-%m-%d %H:%M:%S" "${ISOS_PATH}" | awk '{print $6" "$7;}')"
		MENU_ETRY="$(printf "%-60.60s%20.20s" "${DATA_LINE[2]//%20/ }" "${FILE_TIME}")"
		# --- now thinking ----------------------------------------------------
		#     ${DATA_LINE[1]}        ${DATA_LINE[4]}
		# debian:
		#   netinst: debian-installer -----------------------------------------
		#     debian-netinst-10      debian-10.13.0-amd64-netinst.iso
		#     debian-netinst-11      debian-11.8.0-amd64-netinst.iso
		#     debian-netinst-12      debian-12.2.0-amd64-netinst.iso
		#     debian-netinst-testing debian-testing-amd64-netinst.iso
		#   dvd: debian-installer ---------------------------------------------
		#     debian-10              debian-10.13.0-amd64-DVD-1.iso
		#     debian-11              debian-11.8.0-amd64-DVD-1.iso
		#     debian-12              debian-12.2.0-amd64-DVD-1.iso
		#     debian-testing         debian-testing-amd64-DVD-1.iso
		#   live: debian-installer --------------------------------------------
		#     debian-live-10         debian-live-10.13.0-amd64-lxde.iso
		#     debian-live-11         debian-live-11.8.0-amd64-lxde.iso
		#     debian-live-12         debian-live-12.2.0-amd64-lxde.iso
		#     debian-live-testing    debian-live-testing-amd64-lxde.iso
		# ubuntu:
		#   legacy server: debian-installer -----------------------------------
		#     ubuntu-server-18.04    ubuntu-18.04.6-server-amd64.iso
		#   legacy desktop: ubiquity ------------------------------------------
		#     ubuntu-desktop-18.04   ubuntu-18.04.6-desktop-amd64.iso
		#     ubuntu-desktop-20.04   ubuntu-20.04.6-desktop-amd64.iso
		#     ubuntu-desktop-22.04   ubuntu-22.04.3-desktop-amd64.iso
		#     ubuntu-legacy-23.04    ubuntu-23.04-desktop-legacy-amd64.iso
		#     ubuntu-legacy-23.10    ubuntu-23.10-desktop-legacy-amd64.iso
		#   desktop: cloud-init -----------------------------------------------
		#     ubuntu-desktop-23.04   ubuntu-23.04-desktop-amd64.iso
		#     ubuntu-desktop-23.10   ubuntu-23.10.1-desktop-amd64.iso
		#     ubuntu-desktop-noble   noble-desktop-amd64.iso
		#   live server: cloud-init -------------------------------------------
		#     ubuntu-live-18.04      ubuntu-18.04.6-live-server-amd64.iso
		#     ubuntu-live-20.04      ubuntu-20.04.6-live-server-amd64.iso
		#     ubuntu-live-22.04      ubuntu-22.04.3-live-server-amd64.iso
		#     ubuntu-live-23.04      ubuntu-23.04-live-server-amd64.iso
		#     ubuntu-live-23.10      ubuntu-23.10-live-server-amd64.iso
		#     ubuntu-live-noble      noble-live-server-amd64.iso
		case "${DATA_LINE[1]}" in
			debian-*              | \
			ubuntu-server-*       )                         # debian-installer
				;;
			ubuntu-desktop-18.*   | \
			ubuntu-desktop-20.*   | \
			ubuntu-desktop-22.*   | \
			ubuntu-legacy-*       )                         # ubiquity
				;;
			ubuntu-*              )                         # cloud-init
				;;
		esac
		# --- make menu.cfg ---------------------------------------------------
		case "${DATA_LINE[1]}" in
			*-mini-*              )     # mini.iso
				NETS_CONF="netcfg/disable_autoconfig=true netcfg/get_hostname=\${hstfqdn} netcfg/get_ipaddress=\${ip4addr} netcfg/get_netmask=\${ip4mask} netcfg/get_gateway=\${ip4gway} netcfg/get_nameservers=\${ip4nsvr}"
				AUTO_CONF="auto=true preseed/url=\${webroot}/${DATA_LINE[8]}"
				LANG_CONF="locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
				HTTP_FILE="fetch=\${webroot}/isos/\${isofile}"
				OPTN_PARM="\${autocnf} \${netscnf} \${locales}"
				ROOT_PARM=""
				LOOP_BACK=""
				;;
			debian-*              )
				NETS_CONF="netcfg/disable_autoconfig=true netcfg/get_hostname=\${hstfqdn} netcfg/get_ipaddress=\${ip4addr} netcfg/get_netmask=\${ip4mask} netcfg/get_gateway=\${ip4gway} netcfg/get_nameservers=\${ip4nsvr}"
				AUTO_CONF="auto=true preseed/url=\${webroot}/${DATA_LINE[8]}"
				LANG_CONF="locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
				HTTP_FILE="fetch=\${webroot}/isos/\${isofile}"
				ROOT_PARM=""
				case "${DATA_LINE[1]}" in
					debian-live-{10,11}   ) LOOP_BACK="yes"; OPTN_PARM="\${locales} \${urlfile} ip=dhcp ide=nodma fsck.mode=skip boot=live root=/boot toram=filesystem.squashfs";;
					debian-live-*         ) LOOP_BACK="yes"; OPTN_PARM="\${locales} \${urlfile} ip=dhcp ide=nodma fsck.mode=skip boot=live components"                          ;;
					debian-*              ) LOOP_BACK=""   ; OPTN_PARM="\${autocnf} \${netscnf} \${locales}"                                                                    ;;
				esac
				;;
			ubuntu-server-*       )							# only ubuntu-18.04.6-server-amd64.iso
				NETS_CONF="netcfg/disable_autoconfig=true netcfg/get_hostname=\${hstfqdn} netcfg/get_ipaddress=\${ip4addr} netcfg/get_netmask=\${ip4mask} netcfg/get_gateway=\${ip4gway} netcfg/get_nameservers=\${ip4nsvr}"
				AUTO_CONF="auto=true preseed/url=\${webroot}/${DATA_LINE[8]}"
				LANG_CONF="locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
				HTTP_FILE="live-installer/net-image=\${webroot}/imgs/${DATA_LINE[1]}/install/filesystem.squashfs"
				OPTN_PARM="\${autocnf} \${urlfile} \${netscnf} \${locales}"
				ROOT_PARM=""
				LOOP_BACK=""
				;;
			ubuntu-desktop-*      )
				NETS_CONF="netcfg/disable_autoconfig=true netcfg/get_hostname=\${hstfqdn} netcfg/get_ipaddress=\${ip4addr} netcfg/get_netmask=\${ip4mask} netcfg/get_gateway=\${ip4gway} netcfg/get_nameservers=\${ip4nsvr}"
				AUTO_CONF="auto=true preseed/url=\${webroot}/${DATA_LINE[8]}"
				LANG_CONF="debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				HTTP_FILE="url=\${webroot}/isos/\${isofile}"
				ROOT_PARM=""
				LOOP_BACK=""
				case "${DATA_LINE[1]}" in
					ubuntu-desktop-18.*   ) continue;;      # This version does not support pxeboot
					ubuntu-desktop-20.*   | \
					ubuntu-desktop-22.*   | \
					ubuntu-legacy-*       ) OPTN_PARM="\${locales} \${urlfile} ip=dhcp ide=nodma fsck.mode=skip boot=casper maybe-ubiquity"                             ;;
					ubuntu-desktop-*      )	OPTN_PARM="\${locales} \${urlfile} ip=dhcp ide=nodma fsck.mode=skip boot=casper layerfs-path=minimal.standard.live.squashfs";;
				esac
				;;
			ubuntu-live-*         )
				NETS_CONF="ip=\${ip4addr}::\${ip4gway}:\${ip4mask}:\${hstfqdn}:ens160:static:\${ip4nsvr}"
				AUTO_CONF="automatic-ubiquity noprompt autoinstall ds=nocloud-net;s=\${webroot}/${DATA_LINE[8]}"
				LANG_CONF="debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				HTTP_FILE="url=\${webroot}/isos/\${isofile}"
				OPTN_PARM="\${autocnf} \${urlfile} \${netscnf} \${locales} fsck.mode=skip boot=casper"
				ROOT_PARM=""
				LOOP_BACK=""
				;;
			fedora-*              | \
			centos-*              | \
			almalinux-*           | \
			rockylinux-*          | \
			miraclelinux-*        )
				NETS_CONF="ip=\${ip4addr}::\${ip4gway}:\${ip4mask}:\${hstfqdn}:ens160:none,auto6 nameserver=\${ip4nsvr}"
				AUTO_CONF="inst.ks=\${webroot}/${DATA_LINE[8]}"
				LANG_CONF="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				HTTP_FILE="url=\${webroot}/isos/\${isofile}"
				OPTN_PARM="\${autocnf} \${netscnf} \${locales} inst.repo=\${webroot}/imgs/${DATA_LINE[1]}"
				ROOT_PARM=""
				LOOP_BACK=""
					;;
			opensuse-*            )
				NETS_CONF="hostname=\${hstfqdn} ifcfg=e*=\${ip4addr}/\${ip4cidr},\${ip4gway},\${ip4nsvr},\${wkgroup}"
				AUTO_CONF="autoyast=\${webroot}/${DATA_LINE[8]}"
				LANG_CONF="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				HTTP_FILE="install=\${webroot}/imgs/${DATA_LINE[1]}"
				ROOT_PARM=""
				LOOP_BACK=""
				case "${DATA_LINE[1]}" in
					opensuse-*-netinst-*  ) OPTN_PARM="\${autocnf} \${netscnf} \${locales} root=/dev/ram0 load_ramdisk=1 showopts ramdisk_size=4096"            ;;
					opensuse-*            ) OPTN_PARM="\${autocnf} \${netscnf} \${locales} \${urlfile} root=/dev/ram0 load_ramdisk=1 showopts ramdisk_size=4096";;
				esac
				;;
			windows-*             )
					continue
					;;
			memtest86\+           )
				cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
					menuentry '- ${MENU_ETRY}' {
					 	if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
					 	echo "Loading ${MENU_ETRY} ..."
					 	if [ "\${grub_platform}" = "efi" ]; then
					 		linux "boot/${DATA_LINE[1]}/${DATA_LINE[6]}"
					 	else
					 		linux "boot/${DATA_LINE[1]}/${DATA_LINE[7]}"
					 	fi
					}
					
_EOT_
				continue
				;;
		esac
		cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
			menuentry '- ${MENU_ETRY}' {
			 	set webprot="${HTTP_PROT}"
			 	set webaddr="${HTTP_ADDR}"
			 	set webdirs="${HTTP_DIRS}"
			 	set webroot="\${webprot}://\${webaddr}/\${webdirs}"
			 	set isofile="${DATA_LINE[4]}"
			 	set urlfile="${HTTP_FILE}"
			 	set dnsname="workgroup"
			 	set hstname="sv-${DATA_LINE[1]%%-*}"
			 	set hstfqdn="\${hstname}.\${dnsname}"
			 	set ip4addr="${IPV4_ADDR}"
			 	set ip4cidr="${IPV4_CIDR}"
			 	set ip4mask="${IPV4_MASK}"
			 	set ip4gway="${IPV4_GWAY}"
			 	set ip4nsvr="${IPV4_NSVR}"
			 	set netscnf="${NETS_CONF}"
			 	set autocnf="${AUTO_CONF}"
			 	set locales="${LANG_CONF}"
			 	set options="${OPTN_PARM}"
			#	set root="${ROOT_PARM}"
			 	if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
			 	echo "Loading \${isofile} ..."
_EOT_
		if [[ -z "${LOOP_BACK}" ]]; then
			cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
				 	linux     boot/${DATA_LINE[1]}/${DATA_LINE[7]} \${options} ---
				 	initrd    boot/${DATA_LINE[1]}/${DATA_LINE[6]}
_EOT_
		else
			cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
				 	loopback loop (\${webprot},\${webaddr})/\${webdirs}/isos/\${isofile}
				 	linux    (loop)/${DATA_LINE[5]}/${DATA_LINE[7]} \${options} ---
				 	initrd   (loop)/${DATA_LINE[5]}/${DATA_LINE[6]}
				 	loopback --delete loop
_EOT_
		fi
		cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
			}
			
_EOT_
	done
}

# --- grubi386.img ------------------------------------------------------------
function funcMake_grubi386_img() {
	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_grubi386_img${TXT_RESET}"

	# -------------------------------------------------------------------------
	grub-mkimage \
	    -d /usr/lib/grub/i386-pc \
	    -O i386-pc-pxe \
	    -o "${DIRS_TFTP}/grubi386.img" \
	    -p 'grub' \
	    all_video boot btrfs cat chain configfile cpuid echo ext2 extcmd fat \
	    font gettext gfxmenu gfxterm gfxterm_background gzio halt help \
	    hfsplus http iso9660 jpeg keystatus linux loadenv loopback ls memdisk \
	    minicmd normal ntfs part_apple part_gpt part_msdos password_pbkdf2 \
	    play png probe pxe reboot regexp search search_fs_file search_fs_uuid \
	    search_label sleep smbios squash4 test tftp true udf vbe vga video \
	    xfs zfs zfscrypt zfsinfo cryptodisk gcry_arcfour gcry_blowfish \
	    gcry_camellia gcry_cast5 gcry_crc gcry_des gcry_dsa gcry_idea \
	    gcry_md4 gcry_md5 gcry_rfc2268 gcry_rijndael gcry_rmd160 gcry_rsa \
	    gcry_seed gcry_serpent gcry_sha1 gcry_sha256 gcry_sha512 gcry_tiger \
	    gcry_twofish gcry_whirlpool luks lvm mdraid09 raid5rec raid6rec
}

# --- grubx64.efi -------------------------------------------------------------
function funcMake_grubx64_efi() {
	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_grubx64_efi${TXT_RESET}"

	# -------------------------------------------------------------------------
	grub-mkimage \
	    -C auto \
	    -d /usr/lib/grub/x86_64-efi \
	    -O x86_64-efi  \
	    -o "${DIRS_TFTP}/grubx64.efi" \
	    -p 'grub' \
	    all_video boot btrfs cat chain configfile cpuid echo efifwsetup \
	    efinet ext2 extcmd fat font gettext gfxmenu gfxterm \
	    gfxterm_background gzio halt help hfsplus http iso9660 jpeg keystatus \
	    linux linuxefi loadenv loopback ls lsefi lsefimmap lsefisystab lssal \
	    memdisk minicmd normal ntfs part_apple part_gpt part_msdos \
	    password_pbkdf2 play png probe reboot regexp search search_fs_file \
	    search_fs_uuid search_label sleep smbios squash4 test tftp tpm true \
	    udf video xfs zfs zfscrypt zfsinfo cryptodisk gcry_arcfour \
	    gcry_blowfish gcry_camellia gcry_cast5 gcry_crc gcry_des \
	    gcry_dsa gcry_idea gcry_md4 gcry_md5 gcry_rfc2268 gcry_rijndael \
	    gcry_rmd160 gcry_rsa gcry_seed gcry_serpent gcry_sha1 gcry_sha256 \
	    gcry_sha512 gcry_tiger gcry_twofish gcry_whirlpool luks lvm mdraid09 \
	    raid5rec raid6rec
}

# --- copy font ---------------------------------------------------------------
function funcCopy_font() {
	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcCopy_font${TXT_RESET}"

	# -------------------------------------------------------------------------
	mkdir -p "${DIRS_TFTP}/grub/fonts"
	cp -a /usr/share/grub/unicode.pf2 "${DIRS_TFTP}/grub/fonts/"
}

# --- restart service ---------------------------------------------------------
function funcRestart_service() {
	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcRestart_service${TXT_RESET}"

	# -------------------------------------------------------------------------
	systemctl restart \
	    isc-dhcp-server.service \
	    tftpd-hpa.service \
	    apache2.service
}

# --- status service ----------------------------------------------------------
function funcStatus_service() {
	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcStatus_service${TXT_RESET}"

	# -------------------------------------------------------------------------
	systemctl status \
	    --no-pager \
	    isc-dhcp-server.service \
	    tftpd-hpa.service \
	    apache2.service
}

### main ######################################################################
function main() {
	declare -i    start_time=0
	declare -i    end_time=0

	# --- check the execution user --------------------------------------------
	if [[ "$(whoami)" != "root" ]]; then
		funcPrintf "run as root user."
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

	# --- main ----------------------------------------------------------------
	start_time=$(date +%s)
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"

	case "${COMD_LINE[0]}" in
		-a | --all)
			COMD_LINE=( \
				"--config=preseed,nocloud,kickstart,autoyast" \
				"--menu=grub,menu" \
				"--grub=i386,x64,font" \
				"--service=restart,status" \
			)
			;;
	esac

	for ((I=0; I<${#COMD_LINE[@]}; I++))
	do
		case "${COMD_LINE[I]}" in
			-c   | --config  )
				COMD_LINE[I]="--config=preseed,nocloud,kickstart,autoyast"
				;;
			-m | --menu)
				COMD_LINE[I]="--menu=grub,menu"
				;;
			-g | --grub)
				COMD_LINE[I]="--grub=i386,x64,font"
				;;
			-s | --service)
				COMD_LINE[I]="--service=restart,status"
				;;
		esac
		IFS=','
		set -f
		set -- ${COMD_LINE[I]#*=}
		set +f
		IFS=${OLD_IFS}
		case "${COMD_LINE[I]}" in
			-c=* | --config=*)
				while [ -n "${1:-}" ]
				do
					case "$1" in
						preseed)	# --- make preseed directory files ----------------------------------------
							funcMake_preseed_kill_dhcp_sh
							funcMake_preseed_sub_command_sh
							funcMake_preseed_cfg
							;;
						nocloud)	# --- make nocloud directory files ----------------------------------------
							funcMake_nocloud
							;;
						kickstart)	# --- make kickstart directory files --------------------------------------
							funcMake_kickstart
							;;
						autoyast)	# --- make autoyast directory files ---------------------------------------
							funcMake_autoyast
							;;
					esac
					shift
				done
				;;
			-m=* | --menu=*)
				while [ -n "${1:-}" ]
				do
					case "$1" in
						grub)		# --- make grub.cfg file --------------------------------------------------
							funcMake_grub_cfg
							;;
						menu)		# --- make menu.cfg file --------------------------------------------------
							funcMake_menu_cfg
							;;
					esac
					shift
				done
				;;
			-g=* | --grub=*)
				while [ -n "${1:-}" ]
				do
					case "$1" in
						i386)		# --- make grubi386.img ---------------------------------------------------
							funcMake_grubi386_img
							;;
						x64)		# --- make grubx64.efi ----------------------------------------------------
							funcMake_grubx64_efi
							;;
						font)		# --- copy font -----------------------------------------------------------
							funcCopy_font
							;;
					esac
					shift
				done
				;;
			-s=* | --service=*)
				while [ -n "${1:-}" ]
				do
					case "$1" in
						restart)	# --- restart service -----------------------------------------------------
							funcRestart_service
							;;
						status)	# --- status service ------------------------------------------------------
							funcStatus_service
							;;
					esac
					shift
				done
				;;
			*)
				echo "$0"
				echo "-c | --config  [={ preseed | nocloud | kickstart | autoyast }]"
				echo "-m | --menu    [={ grub | menu }]"
				echo "-g | --grub    [={ i386 | x64 | font }]"
				echo "-s | --service [={ restart | status }]"
				echo "ex: $0 --config=preseed,nocloud,kickstart,autoyast"
				break
				;;
		esac
	done

	# -------------------------------------------------------------------------
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing end${TXT_RESET}"
	end_time=$(date +%s)
	echo "elapsed time: $((end_time-start_time)) [sec]"
}

	# === main ================================================================
	main
	exit 0

### eof #######################################################################
