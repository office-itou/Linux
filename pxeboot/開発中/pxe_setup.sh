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
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

# --- check installation package ----------------------------------------------
#	dpkg --search filename
	case "${0##*/}" in
		pxe_setup_dnsmasq.sh )
			declare -r -a APP_LIST=( "syslinux-common" "syslinux-efi" "pxelinux" "dnsmasq" "apache2" "7zip" "rsync")
			;;
		* )
			declare -r -a APP_LIST=("grub-common" "grub-efi-amd64-bin" "grub-pc-bin" "isc-dhcp-server" "tftpd-hpa" "apache2" "7zip" "rsync")
			;;
	esac
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
		exit 1
	fi

# *** data section ************************************************************

# --- working directory name --------------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    WORK_DIRS="${PROG_DIRS}/${PROG_NAME%.*}"
	if [[ "${WORK_DIRS}" = "/" ]]; then
		echo "terminate the process because the working directory is root"
		exit 1
	fi

# --- work variables ----------------------------------------------------------
	declare -r    OLD_IFS="${IFS}"

# --- set minimum display size ------------------------------------------------
	declare -i    ROW_SIZE=80
	declare -i    COL_SIZE=25

# --- set parameters ----------------------------------------------------------
	if [[ -f "${PROG_DIRS}/${PROG_NAME%.*}.cfg" ]]; then
		source "${PROG_DIRS}/${PROG_NAME%.*}.cfg"
	else
		# --- server parameters ------------------------------------------------
		declare -r    DIRS_TFTP="/var/tftp"										# tftp directory
		declare -r    DIRS_HTTP="/var/www/html/pxe"								# http directory
		declare -r    DIRS_HGFS=""												# vmware shared directory
		declare -r    DIRS_TMPL="${PWD}/tmpl"									# configuration file's directory
		declare -r    DHCP_NAME="sv-server"										# dhcp server name
		declare -r    DHCP_ADDR="192.168.1.254"									# dhcp server address
		declare -r    DHCP_ROUT="192.168.1.254"									# dhcp router address
		declare -r    DHCP_SNET="192.168.1.0"									# dhcp subnet address
		declare -r    DHCP_MASK="255.255.255.0"									# dhcp netmask
		declare -r    DHCP_BROD="192.168.1.255"									# dhcp broad cast
		declare -r    DHCP_RANG="192.168.1.16 192.168.1.31"						# dhcp range address
		declare -r    WEBS_ADDR="http://192.168.1.254/pxe"						# http server address
		declare -r    TFTP_MAPS="/etc/tftpd-hpa.map"							# tftp map file
		declare -r    TFTP_OPTN="--secure --verbose --map-file ${TFTP_MAPS}"	# tftp options
		# --- setup pc parameters ----------------------------------------------
		declare -r    IPV4_ADDR="192.168.1.1"									# IPv4 address
		declare -r    IPV4_CIDR="24"											# IPv4 cidr
		declare -r    IPV4_MASK="255.255.255.0"									# IPv4 netmask
		declare -r    IPV4_GWAY="192.168.1.254"									# IPv4 gateway
		declare -r    IPV4_NSVR="192.168.1.254"									# IPv4 namesaver
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
	if [[ -f "${PROG_DIRS}/${PROG_NAME%.*}.lst" ]]; then
		source "${PROG_DIRS}/${PROG_NAME%.*}.lst"
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
			"o  debian-netinst-12           Debian%2012                         debian          debian-12.4.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
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
			"o  opensuse-tumbleweed-netinst openSUSE%20Tumbleweed               openSUSE        openSUSE-Tumbleweed-NET-x86_64-Current.iso  boot/x86_64/loader                      initrd                      linux                   conf/autoyast/autoinst_tumbleweed.xml       linux/openSUSE/     " \
			"m  -                           Auto%20install%20DVD%20media        -               -                                           -                                       -                           -                       -                                           -                   " \
			"o  debian-10                   Debian%2010                         debian          debian-10.13.0-amd64-DVD-1.iso              install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server_old.cfg       linux/debian        " \
			"o  debian-11                   Debian%2011                         debian          debian-11.8.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
			"o  debian-12                   Debian%2012                         debian          debian-12.4.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 conf/preseed/ps_debian_server.cfg           linux/debian        " \
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
			"o  debian-live-12              Debian%2012%20Live                  debian          debian-live-12.4.0-amd64-lxde.iso           live                                    initrd.img                  vmlinuz                 conf/preseed/ps_debian_desktop.cfg          linux/debian        " \
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
	if [[ "$1" = "--no-cutting" ]]; then
		shift
		printf "%s\n" "$@"
		return
	fi
	IFS=$'\n'
	INP_STR="$(printf "%s" "$@")"
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

# --- download ----------------------------------------------------------------
function funcCurl() {
#	declare -r    OLD_IFS="${IFS}"
	declare -i    RET_CD=0
	declare -i    I
	# shellcheck disable=SC2155
	declare       INP_URL="$(echo "$@" | sed -n -e 's%^.* \(\(http\|https\)://.*\)$%\1%p')"
	# shellcheck disable=SC2155
	declare       OUT_DIR="$(echo "$@" | sed -n -e 's%^.* --output-dir *\(.*\) .*$%\1%p' | sed -e 's%/$%%')"
	# shellcheck disable=SC2155
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
	if [[ "${RET_CD}" -eq 6 ]] || [[ "${RET_CD}" -eq 18 ]] || [[ "${RET_CD}" -eq 22 ]] || [[ "${RET_CD}" -eq 28 ]] || [[ "${#ARY_HED[@]}" -le 0 ]]; then
		ERR_MSG=$(echo "${ARY_HED[@]}" | sed -n -e '/^HTTP/p' | sed -z 's/\n\|\r\|\l//g')
		echo -e "${ERR_MSG} [${RET_CD}]: ${INP_URL}"
		return "${RET_CD}"
	fi
	WEB_SIZ=$(echo "${ARY_HED[@],,}" | sed -n -e '/http\/.* 200/,/^$/ s/'''$'\r//gp' | sed -n -e '/content-length:/ s/.*: //p')
	# shellcheck disable=SC2312
	WEB_TIM=$(TZ=UTC date -d "$(echo "${ARY_HED[@],,}" | sed -n -e '/http\/.* 200/,/^$/ s/'''$'\r//gp' | sed -n -e '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
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

	if [[ "${WEB_SIZ}" -lt 1024 ]]; then
		TXT_SIZ="$(printf "%'d Byte" "${WEB_SIZ}")"
	else
		for ((I=3; I>0; I--))
		do
			INT_UNT=$((1024**I))
			if [[ "${WEB_SIZ}" -ge "${INT_UNT}" ]]; then
				TXT_SIZ="$(echo "${WEB_SIZ}" "${INT_UNT}" | awk '{printf("%.1f", $1/$2)}') ${TXT_UNT[${I}]})"
#				INT_SIZ="$(((WEB_SIZ*1000)/(1024**I)))"
#				TXT_SIZ="$(printf "%'.1f ${TXT_UNT[${I}]}" "${INT_SIZ::${#INT_SIZ}-3}.${INT_SIZ:${#INT_SIZ}-3}")"
				break
			fi
		done
	fi

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

# --- dhcpd.conf --------------------------------------------------------------
function funcMake_dhcpd_conf() {
	declare -r    FILE_NAME="$(find /etc/ -name 'dhcpd.conf' -type f)"
	declare -r    READ_FILE="${PROG_DIRS}/${PROG_NAME%.*}.mac"
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare       LINE=""

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_dhcpd_conf${TXT_RESET}"

	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_NAME}.orig" ]]; then
		cp --archive --update "${FILE_NAME}" "${FILE_NAME}.orig"
	else
		cp --archive --update "${FILE_NAME}" "${FILE_NAME}.orig.${DATE_TIME}"
	fi

	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_NAME}"
		option arch code 93 = unsigned integer 16;
		
		default-lease-time 600;
		max-lease-time 7200;
		
		option domain-name "workgroup";
		option domain-name-servers ${DHCP_ADDR};
		option routers ${DHCP_ROUT};
		
		option time-servers ntp.nict.jp;
		option netbios-dd-server ${DHCP_ADDR};
		
		class "pxe" {
		 	match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
		 	if option arch = 00:07 or option arch = 00:09 {
		#		filename "bootnetx64.efi";
		 		filename "grubx64.efi";
		 	} else {
		#		filename "pxelinux.0";
		 		filename "grubi386.img";
		 	}
		}
		
		class "etherboot" {
		 	match if substring (option vendor-class-identifier, 0, 9) = "Etherboot";
		}
		
		subnet ${DHCP_SNET} netmask ${DHCP_MASK} {
		 	option broadcast-address ${DHCP_BROD};
		 	pool {
		 		default-lease-time 60;
		 		max-lease-time  300;
		 		server-name "${DHCP_NAME}";
		 		next-server ${DHCP_ADDR};
		 		allow members of "pxe";
		 		allow members of "etherboot";
		 		range ${DHCP_RANG};
		 	}
		}
_EOT_

	# -------------------------------------------------------------------------
	if [[ -f "${READ_FILE}" ]]; then
		sed -i "${FILE_NAME}" \
		    -e '/^[ \t]*pool[ \t]*{$/,/^[ \t]*}$/ {' \
		    -e '/^[ \t]*}$/i \\' \
		    -e '}'
		while read -r LINE
		do
			sed -i "${FILE_NAME}" \
			    -e '/^[ \t]*pool[ \t]*{$/,/^[ \t]*}$/ {' \
			    -e '/^[ \t]*}$/i \\t\t'"${LINE}"'' \
			    -e '}'
		done < "${READ_FILE}"
	fi
}

# --- isc-dhcp-server ---------------------------------------------------------
function funcMake_isc_dhcp_server() {
	declare -r    FILE_NAME="/etc/default/isc-dhcp-server"
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    IPV4_INFO="$(LANG=C ip -a address show 2> /dev/null | sed -n '/^2:/ { :l1; p; n; { /^[0-9]\+:/ Q; }; t; b l1; }')"
	declare -r    NICS_NAME="$(echo "${IPV4_INFO}" | awk '/^2:/ {gsub(":","",$2); print $2;}')"

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_isc_dhcp_server${TXT_RESET}"

	# -------------------------------------------------------------------------
	if [[ -z "${FILE_NAME}" ]] || [[ ! -f "${FILE_NAME}" ]]; then
		funcPrintf "${TXT_BLACK}${TXT_RED}file not exist: ${FILE_NAME}${TXT_RESET}"
		exit 1
	fi

	if [[ ! -f "${FILE_NAME}.orig" ]]; then
		cp --archive --update "${FILE_NAME}" "${FILE_NAME}.orig"
	else
		cp --archive --update "${FILE_NAME}" "${FILE_NAME}.orig.${DATE_TIME}"
	fi

	sed -i "${FILE_NAME}"                                \
	    -e "/^INTERFACESv4=/ s/\".*\"/\"${NICS_NAME}\"/"
}

# --- tftpd-hpa ---------------------------------------------------------------
function funcMake_tftpd_hpa() {
	declare -r    FILE_NAME="/etc/default/tftpd-hpa"
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_tftpd_hpa${TXT_RESET}"

	# -------------------------------------------------------------------------
	if [[ -z "${FILE_NAME}" ]] || [[ ! -f "${FILE_NAME}" ]]; then
		funcPrintf "${TXT_BLACK}${TXT_RED}file not exist: ${FILE_NAME}${TXT_RESET}"
		exit 1
	fi

	if [[ ! -f "${FILE_NAME}.orig" ]]; then
		cp --archive --update "${FILE_NAME}" "${FILE_NAME}.orig"
	else
		cp --archive --update "${FILE_NAME}" "${FILE_NAME}.orig.${DATE_TIME}"
	fi

	sed -i "${FILE_NAME}"                                   \
	    -e "/^TFTP_DIRECTORY=/ s%\".*\"%\"${DIRS_TFTP}/\"%" \
	    -e "/^TFTP_ADDRESS=/ s/\".*\"/\"0.0.0.0:69\"/"      \
	    -e "/^TFTP_OPTIONS=/ s%\".*\"%\"${TFTP_OPTN}\"%"

	if [[ -z "${TFTP_MAPS}" ]]; then
		return
	fi

	# -------------------------------------------------------------------------
	if [[ -f "${TFTP_MAPS}" ]]; then
		if [[ ! -f "${TFTP_MAPS}.orig" ]]; then
			cp --archive --update "${TFTP_MAPS}" "${TFTP_MAPS}.orig"
		else
			cp --archive --update "${TFTP_MAPS}" "${TFTP_MAPS}.orig.${DATE_TIME}"
		fi
	fi

	cat <<- _EOT_ | sed 's/^ *//g' > "${TFTP_MAPS}"
		r   ^               ${DIRS_TFTP}/
		rg  //              /
_EOT_
}

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
		 	set -e								# End with status other than 0
		 	set -u								# End with undefined variable reference
		#	set -o pipefail						# End with in pipe error
		
		 	trap 'exit 1' 1 2 3 15
		
		 	readonly PROG_PRAM="$*"
		 	readonly PROG_NAME="${0##*/}"
		 	readonly WORK_DIRS="${0%/*}"
		# shellcheck disable=SC2155
		 	readonly DIST_NAME="$(uname -v | sed -n -e 's/.*\(debian\|ubuntu\).*/\L\1/ip')"
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
		 	LIST_TASK="$(sed -n -e '/^[[:blank:]]*tasksel[[:blank:]]\+tasksel\/first[[:blank:]]\+/,/[^\\]$/p' "${TEMP_FILE}" | \
		 	             sed -z -e 's/\\\n//g'                                                                               | \
		 	             sed -e 's/^.*[[:blank:]]\+multiselect[[:blank:]]\+//'                                                 \
		 	                 -e 's/[[:blank:]]\+/ /g')"
		 	LIST_PACK="$(sed -n -e '/^[[:blank:]]*d-i[[:blank:]]\+pkgsel\/include[[:blank:]]\+/,/[^\\]$/p'    "${TEMP_FILE}" | \
		 	             sed -z -e 's/\\\n//g'                                                                               | \
		 	             sed -e 's/^.*[[:blank:]]\+string[[:blank:]]\+//'                                                      \
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
		#	CON_NAME="ethernet_$(echo "${NIC_MADR}" | sed -n -e 's/://gp')_cable"
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
		#	echo "${PROG_NAME}: CON_NAME=${CON_NAME}"
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
		 		for MAC_ADDR in $(LANG=C ip -4 -oneline link show | awk '/^[0-9]+:/&&!/^1:/ {gsub(":","",$17); print $17;}')
		 		do
		 			CON_NAME="ethernet_${MAC_ADDR}_cable"
		 			CON_DIRS="${ROOT_DIRS}/var/lib/connman/${CON_NAME}"
		 			CON_FILE="${CON_FILE}/settings"
		 			mkdir -p "${CON_DIRS}"
		 			chmod 600 "${CON_DIRS}"
		 			cat <<- _EOT_ | sed 's/^ *//g' > "${ROOT_DIRS}/var/lib/connman/settings"
		 				[global]
		 				OfflineMode=false
		 				
		 				[Wired]
		 				Enable=true
		 				Tethering=false
		_EOT_
		 			if [ "${MAC_ADDR}" != "${NIC_MADR}" ]; then
		 				cat <<- _EOT_ | sed 's/^ *//g' > "${CON_FILE}"
		 					[${CON_NAME}]
		 					Name=Wired
		 					AutoConnect=false
		_EOT_
		 			else
		 				cat <<- _EOT_ | sed 's/^ *//g' > "${CON_FILE}"
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
		 					Nameservers=127.0.0.1;::1;${NIC_DNS4};
		 					Domains=${NIC_WGRP};
		 					Timeservers=ntp.nict.jp;
		 					mDNS=true
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
	declare       INS_STR=""
	declare -i    I=0

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
		cp --update --backup "${FILE_TMPL}" "${FILE_PATH}"
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
	declare -i    I=0

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
		cp --update --backup "${FILE_TMPL}" "${DIRS_NAME}/user-data"
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
	declare -i    I=0

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
		cp --update --backup "${FILE_TMPL}" "${FILE_PATH}"
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
		    -e "s%_WEBADDR_%${WEBS_ADDR}/imgs%g    } "
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
	declare -i    I=0

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
		cp --update --backup "${FILE_TMPL}" "${FILE_PATH}"
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

		#	set gfxmode=7680x4320	# 8K UHD (16:9)
		#	set gfxmode=3840x2400	#        (16:10)
		#	set gfxmode=3840x2160	# 4K UHD (16:9)
		#	set gfxmode=2880x1800	#        (16:10)
		#	set gfxmode=2560x1600	#        (16:10)
		#	set gfxmode=2560x1440	# WQHD   (16:9)
		#	set gfxmode=1920x1440	#        (4:3)
		#	set gfxmode=1920x1200	# WUXGA  (16:10)
		#	set gfxmode=1920x1080	# FHD    (16:9)
		#	set gfxmode=1856x1392	#        (4:3)
		#	set gfxmode=1792x1344	#        (4:3)
		#	set gfxmode=1680x1050	# WSXGA+ (16:10)
		#	set gfxmode=1600x1200	# UXGA   (4:3)
		#	set gfxmode=1400x1050	#        (4:3)
		#	set gfxmode=1440x900	# WXGA+  (16:10)
		#	set gfxmode=1360x768	# HD     (16:9)
		 	set gfxmode=1280x1024	# SXGA   (5:4)
		#	set gfxmode=1280x960	#        (4:3)
		#	set gfxmode=1280x800	#        (16:10)
		#	set gfxmode=1280x768	#        (4:3)
		#	set gfxmode=1280x720	# WXGA   (16:9)
		#	set gfxmode=1152x864	#        (4:3)
		#	set gfxmode=1024x768	# XGA    (4:3)
		#	set gfxmode=800x600		# SVGA   (4:3)
		#	set gfxmode=640x480		# VGA    (4:3)

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

# --- syslinux.cfg ------------------------------------------------------------
function funcMake_syslinux_cfg() {
	declare -r -a DIRS_LIST=("${DIRS_TFTP}/menu-"{bios,efi{32,64}})
	declare -r    FILE_NAME="syslinux.cfg"
	declare -r    MENU_NAME="menu.cfg"
	declare       DIRS_NAME=""
	declare       FILE_PATH=""
	declare -i    I=0

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_syslinux_cfg${TXT_RESET}"

	# -------------------------------------------------------------------------
	for I in "${!DIRS_LIST[@]}"
	do
		DIRS_NAME="${DIRS_LIST[I]}"
		FILE_PATH="${DIRS_NAME}/${FILE_NAME}"
		echo "${FILE_PATH}"
		# --- make directory --------------------------------------------------
		mkdir -p "${DIRS_NAME}/pxelinux.cfg" \
		         "${DIRS_TFTP}/boot"
		# --- make symbolic link ----------------------------------------------
		ln -s -f "${FILE_PATH}" "${DIRS_NAME}/pxelinux.cfg/default"
		ln -s -f "${DIRS_TFTP}/boot" "${DIRS_NAME}/"
		# --- remove menu.cfg -------------------------------------------------
		rm -f "${DIRS_NAME}/${MENU_NAME}"
		# --- copy module -----------------------------------------------------
		case "${DIRS_NAME}" in
			*bios )
				cp --archive --update /usr/lib/syslinux/modules/bios/.  "${DIRS_NAME}/"
				cp --archive --update /usr/lib/PXELINUX/.               "${DIRS_NAME}/"
				;;
			*efi32)
				cp --archive --update /usr/lib/syslinux/modules/efi32/. "${DIRS_NAME}/"
				cp --archive --update /usr/lib/SYSLINUX.EFI/efi32/.     "${DIRS_NAME}/"
				;;
			*efi64)
				cp --archive --update /usr/lib/syslinux/modules/efi64/. "${DIRS_NAME}/"
				cp --archive --update /usr/lib/SYSLINUX.EFI/efi64/.     "${DIRS_NAME}/"
				;;
		esac
		# --- make syslinux.cfg -----------------------------------------------
		cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
			path ./
			prompt 0
			timeout 0
			default vesamenu.c32
			
			#menu resolution		7680 4320	# 8K UHD (16:9)
			#menu resolution		3840 2400	#        (16:10)
			#menu resolution		3840 2160	# 4K UHD (16:9)
			#menu resolution		2880 1800	#        (16:10)
			#menu resolution		2560 1600	#        (16:10)
			#menu resolution		2560 1440	# WQHD   (16:9)
			#menu resolution		1920 1440	#        (4:3)
			#menu resolution		1920 1200	# WUXGA  (16:10)
			#menu resolution		1920 1080	# FHD    (16:9)
			#menu resolution		1856 1392	#        (4:3)
			#menu resolution		1792 1344	#        (4:3)
			#menu resolution		1680 1050	# WSXGA+ (16:10)
			#menu resolution		1600 1200	# UXGA   (4:3)
			#menu resolution		1400 1050	#        (4:3)
			#menu resolution		1440 900	# WXGA+  (16:10)
			#menu resolution		1360 768	# HD     (16:9)
			menu resolution			1280 1024	# SXGA   (5:4)
			#menu resolution		1280 960	#        (4:3)
			#menu resolution		1280 800	#        (16:10)
			#menu resolution		1280 768	#        (4:3)
			#menu resolution		1280 720	# WXGA   (16:9)
			#menu resolution		1152 864	#        (4:3)
			#menu resolution		1024 768	# XGA    (4:3)
			#menu resolution		800 600		# SVGA   (4:3)
			#menu resolution		640 480		# VGA    (4:3)

			#menu background		splash.png
			
			menu color screen		* #ffffffff #ee000080 *
			menu color title		* #ffffffff #ee000080 *
			menu color border		* #ffffffff #ee000080 *
			menu color sel			* #ffffffff #76a1d0ff *
			menu color hotsel		* #ffffffff #76a1d0ff *
			menu color unsel		* #ffffffff #ee000080 *
			menu color hotkey		* #ffffffff #ee000080 *
			menu color tabmsg		* #ffffffff #ee000080 *
			menu color timeout_msg	* #ffffffff #ee000080 *
			menu color timeout		* #ffffffff #ee000080 *
			menu color disabled		* #ffffffff #ee000080 *
			menu color cmdmark		* #ffffffff #ee000080 *
			menu color cmdline		* #ffffffff #ee000080 *
			menu color scrollbar	* #ffffffff #ee000080 *
			menu color help			* #ffffffff #ee000080 *
			
			menu margin				4
			menu vshift				5
			menu rows				25
			menu tabmsgrow			31
			menu cmdlinerow			33
			menu timeoutrow			33
			menu helpmsgrow			37
			menu hekomsgendrow		39
			
			menu title - Boot Menu -
			menu tabmsg Press ENTER to boot or TAB to edit a menu entry
			
			include ${MENU_NAME}
			
			label System-command
			 	menu label [ System command ... ]
			
			label System-shutdown
			 	menu label - System shutdown
			 	com32 poweroff.c32
			
			label System-restart
			 	menu label - System restart
			 	com32 reboot.c32
_EOT_
	done
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
	declare       MENU_OPTN=""
	declare       FILE_TIME=""
	declare -r    HTTP_PROT="${WEBS_ADDR%%:*}"
	declare       HTTP_ADDR="${WEBS_ADDR#*//}"
	              HTTP_ADDR="${HTTP_ADDR%%/*}"
	declare -r    HTTP_DIRS="${WEBS_ADDR##*/}"
#	declare -r    HTTP_ROOT="${HTTP_PROT}://${HTTP_ADDR}${HTTP_DIRS}"
	declare       NETS_CONF=""
	declare       AUTO_CONF=""
	declare       LANG_CONF=""
	declare       OPTN_PARM=""
	declare       LOOP_BACK=""
	declare -r -a DIRS_SLNX=("${DIRS_TFTP}/menu-"{bios,efi{32,64}})
	declare -r    MENU_SLNX="menu.cfg"
	declare -i    I=0
	declare -i    J=0

	# --- message display -----------------------------------------------------
	funcPrintf "${TXT_BLACK}${TXT_BYELLOW}funcMake_menu_cfg${TXT_RESET}"

	# -------------------------------------------------------------------------
	echo "${FILE_PATH}"

	# --- make directory ------------------------------------------------------
	mkdir -p "${DIRS_NAME}"

	# --- make menu.cfg -------------------------------------------------------
	rm -f "${FILE_PATH}"
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
			for J in "${!DIRS_SLNX[@]}"
			do
				cat <<- _EOT_ | sed 's/^ *//g' >> "${DIRS_SLNX[J]}/${MENU_SLNX}"
					label ${DATA_LINE[2]//%20/-}
					 	menu label ${MENU_ETRY}
					
_EOT_
			done
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
		mount -r -o loop "${ISOS_PATH}" "${WORK_DIRS}/mnt"
		mkdir -p "${DIRS_BOOT}/${DATA_LINE[1]}"
		case "${DATA_LINE[1]}" in
			debian-live-*         | \
			ubuntu-desktop-*      | \
			ubuntu-legacy-*       )     # loopback ----------------------------
				rsync --archive --human-readable --update --delete "${WORK_DIRS}/mnt/${DATA_LINE[5]}/"{"${DATA_LINE[6]}","${DATA_LINE[7]}"} "${DIRS_BOOT}/${DATA_LINE[1]}/"
				;;
			*-mini-*              )     # mini.iso ----------------------------
				rsync --archive --human-readable --update --delete "${WORK_DIRS}/mnt/"{"${DATA_LINE[6]}","${DATA_LINE[7]}"}                 "${DIRS_BOOT}/${DATA_LINE[1]}/"
				;;
			debian-*              )     # DVD / netinst
				rsync --archive --human-readable --update --delete "${WORK_DIRS}/mnt/${DATA_LINE[5]}/"{"${DATA_LINE[6]}","${DATA_LINE[7]}"} "${DIRS_BOOT}/${DATA_LINE[1]}/"
				;;
			ubuntu-*              | \
			fedora-*              | \
			centos-*              | \
			almalinux-*           | \
			rockylinux-*          | \
			miraclelinux-*        | \
			opensuse-*            )     # DVD / netinst -----------------------
				rsync --archive --human-readable --update --delete "${WORK_DIRS}/mnt/${DATA_LINE[5]}/"{"${DATA_LINE[6]}","${DATA_LINE[7]}"} "${DIRS_BOOT}/${DATA_LINE[1]}/"
				mkdir -p "${DIRS_IMGS}/${DATA_LINE[1]}"
				rsync --archive --human-readable --update --delete "${WORK_DIRS}/mnt/"                                                      "${DIRS_IMGS}/${DATA_LINE[1]}/"
				;;
			memtest86\+           )     # memtest86+ --------------------------
				mkdir -p "${DIRS_BOOT}/${DATA_LINE[1]}/"{"${DATA_LINE[6]%/*}","${DATA_LINE[7]%/*}"}
				rsync --archive --human-readable --update --delete "${WORK_DIRS}/mnt/${DATA_LINE[6]}"                                       "${DIRS_BOOT}/${DATA_LINE[1]}/${DATA_LINE[6]%/*}/"
				rsync --archive --human-readable --update --delete "${WORK_DIRS}/mnt/${DATA_LINE[7]}"                                       "${DIRS_BOOT}/${DATA_LINE[1]}/${DATA_LINE[7]%/*}/"
				;;
		esac
		umount "${WORK_DIRS}/mnt"
		FILE_TIME="$(TZ=UTC ls -lL --time-style="+%Y-%m-%d %H:%M:%S" "${ISOS_PATH}" | awk '{print $6" "$7;}')"
		MENU_ETRY="$(printf "%-60.60s%20.20s" "${DATA_LINE[2]//%20/ }" "${FILE_TIME}")"
		# --- now thinking ----------------------------------------------------
		#     ${DATA_LINE[1]}        ${DATA_LINE[4]}
		# debian:
		#   netinst: debian-installer -----------------------------------------
		#     debian-netinst-10      debian-10.13.0-amd64-netinst.iso
		#     debian-netinst-11      debian-11.8.0-amd64-netinst.iso
		#     debian-netinst-12      debian-12.4.0-amd64-netinst.iso
		#     debian-netinst-testing debian-testing-amd64-netinst.iso
		#   dvd: debian-installer ---------------------------------------------
		#     debian-10              debian-10.13.0-amd64-DVD-1.iso
		#     debian-11              debian-11.8.0-amd64-DVD-1.iso
		#     debian-12              debian-12.4.0-amd64-DVD-1.iso
		#     debian-testing         debian-testing-amd64-DVD-1.iso
		#   live: debian-installer --------------------------------------------
		#     debian-live-10         debian-live-10.13.0-amd64-lxde.iso
		#     debian-live-11         debian-live-11.8.0-amd64-lxde.iso
		#     debian-live-12         debian-live-12.4.0-amd64-lxde.iso
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
			ubuntu-live-18.*      | \
			ubuntu-live-20.*      )                         # cloud-init
				;;
		esac
		# --- make menu.cfg ---------------------------------------------------
		case "${DATA_LINE[1]}" in
			*-mini-*              )     # mini.iso
				HTTP_FILE="fetch=\${webroot}/isos/\${isofile}"
				OPTN_PARM="\${autocnf} \${netscnf} \${locales}"
				ROOT_PARM=""
				LOOP_BACK=""
				# -------------------------------------------------------------
				AUTO_CONF="auto=true preseed/url=\${webroot}/${DATA_LINE[8]}"
				NETS_CONF="netcfg/disable_autoconfig=true"
				NETS_CONF+=" netcfg/choose_interface=ens160"
				NETS_CONF+=" netcfg/get_hostname=\${hstfqdn}"
				NETS_CONF+=" netcfg/get_ipaddress=\${ip4addr}"
				NETS_CONF+=" netcfg/get_netmask=\${ip4mask}"
				NETS_CONF+=" netcfg/get_gateway=\${ip4gway}"
				NETS_CONF+=" netcfg/get_nameservers=\${ip4nsvr}"
				LANG_CONF="locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
				# -------------------------------------------------------------
				MENU_OPTN="auto=true preseed/url=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/${DATA_LINE[8]}"
				MENU_OPTN+=" netcfg/disable_autoconfig=true"
				MENU_OPTN+=" netcfg/choose_interface=ens160"
				MENU_OPTN+=" netcfg/get_hostname=sv-${DATA_LINE[1]%%-*}.workgroup"
				MENU_OPTN+=" netcfg/get_ipaddress=${IPV4_ADDR}"
				MENU_OPTN+=" netcfg/get_netmask=${IPV4_MASK}"
				MENU_OPTN+=" netcfg/get_gateway=${IPV4_GWAY}"
				MENU_OPTN+=" netcfg/get_nameservers=${IPV4_NSVR}"
				MENU_OPTN+=" ${LANG_CONF}"
				;;
			debian-*              )
				HTTP_FILE="fetch=\${webroot}/isos/\${isofile}"
				OPTN_PARM="\${autocnf} \${netscnf} \${locales}"
				ROOT_PARM=""
				LOOP_BACK=""
				# -------------------------------------------------------------
				AUTO_CONF="auto=true preseed/url=\${webroot}/${DATA_LINE[8]}"
				NETS_CONF="netcfg/disable_autoconfig=true"
				NETS_CONF+=" netcfg/choose_interface=ens160"
				NETS_CONF+=" netcfg/get_hostname=\${hstfqdn}"
				NETS_CONF+=" netcfg/get_ipaddress=\${ip4addr}"
				NETS_CONF+=" netcfg/get_netmask=\${ip4mask}"
				NETS_CONF+=" netcfg/get_gateway=\${ip4gway}"
				NETS_CONF+=" netcfg/get_nameservers=\${ip4nsvr}"
				LANG_CONF="locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
				# -------------------------------------------------------------
				MENU_OPTN="auto=true preseed/url=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/${DATA_LINE[8]}"
				MENU_OPTN+=" netcfg/disable_autoconfig=true"
				MENU_OPTN+=" netcfg/choose_interface=ens160"
				MENU_OPTN+=" netcfg/get_hostname=sv-${DATA_LINE[1]%%-*}.workgroup"
				MENU_OPTN+=" netcfg/get_ipaddress=${IPV4_ADDR}"
				MENU_OPTN+=" netcfg/get_netmask=${IPV4_MASK}"
				MENU_OPTN+=" netcfg/get_gateway=${IPV4_GWAY}"
				MENU_OPTN+=" netcfg/get_nameservers=${IPV4_NSVR}"
				MENU_OPTN+=" ${LANG_CONF}"
				# -------------------------------------------------------------
				case "${DATA_LINE[1]}" in
					debian-live-{10,11}   )
						LOOP_BACK="yes"
						OPTN_PARM="\${locales} \${urlfile} ip=dhcp ide=nodma fsck.mode=skip boot=live root=/boot toram=filesystem.squashfs"
						MENU_OPTN="fetch=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/isos/${DATA_LINE[4]}"
						MENU_OPTN+=" ip=dhcp ide=nodma fsck.mode=skip boot=live root=/boot toram=filesystem.squashfs"
						MENU_OPTN+=" ${LANG_CONF}"
						;;
					debian-live-*         )
						LOOP_BACK="yes"
						OPTN_PARM="\${locales} \${urlfile} ip=dhcp ide=nodma fsck.mode=skip boot=live components"
						MENU_OPTN="fetch=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/isos/${DATA_LINE[4]}"
						MENU_OPTN+=" ip=dhcp ide=nodma fsck.mode=skip boot=live components"
						MENU_OPTN+=" ${LANG_CONF}"
						;;
					*                     )
						;;
				esac
				;;
			ubuntu-server-*       )							# only ubuntu-18.04.6-server-amd64.iso
				HTTP_FILE="live-installer/net-image=\${webroot}/imgs/${DATA_LINE[1]}/install/filesystem.squashfs"
				OPTN_PARM="\${autocnf} \${urlfile} \${netscnf} \${locales}"
				ROOT_PARM=""
				LOOP_BACK=""
				# -------------------------------------------------------------
				AUTO_CONF="auto=true preseed/url=\${webroot}/${DATA_LINE[8]}"
				NETS_CONF="netcfg/disable_autoconfig=true"
				NETS_CONF+=" netcfg/choose_interface=ens160"
				NETS_CONF+=" netcfg/get_hostname=\${hstfqdn}"
				NETS_CONF+=" netcfg/get_ipaddress=\${ip4addr}"
				NETS_CONF+=" netcfg/get_netmask=\${ip4mask}"
				NETS_CONF+=" netcfg/get_gateway=\${ip4gway}"
				NETS_CONF+=" netcfg/get_nameservers=\${ip4nsvr}"
				LANG_CONF="locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
				# -------------------------------------------------------------
				MENU_OPTN="auto=true preseed/url=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/${DATA_LINE[8]}"
				MENU_OPTN+=" netcfg/disable_autoconfig=true"
				MENU_OPTN+=" netcfg/choose_interface=ens160"
				MENU_OPTN+=" netcfg/get_hostname=sv-${DATA_LINE[1]%%-*}.workgroup"
				MENU_OPTN+=" netcfg/get_ipaddress=${IPV4_ADDR}"
				MENU_OPTN+=" netcfg/get_netmask=${IPV4_MASK}"
				MENU_OPTN+=" netcfg/get_gateway=${IPV4_GWAY}"
				MENU_OPTN+=" netcfg/get_nameservers=${IPV4_NSVR}"
				MENU_OPTN+=" ${LANG_CONF}"
				;;
			ubuntu-legacy-*       | \
			ubuntu-desktop-*      )
				HTTP_FILE="url=\${webroot}/isos/\${isofile}"
				OPTN_PARM="\${locales} \${urlfile} ip=dhcp ide=nodma fsck.mode=skip boot=casper layerfs-path=minimal.standard.live.squashfs"
				ROOT_PARM=""
				LOOP_BACK=""
				LANG_CONF="debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				case "${DATA_LINE[1]}" in
					ubuntu-desktop-18.*   ) continue;;      # This version does not support pxeboot
					ubuntu-desktop-20.*   | \
					ubuntu-desktop-22.*   | \
					ubuntu-legacy-*       )
						OPTN_PARM="\${locales} \${urlfile} ip=dhcp ide=nodma fsck.mode=skip boot=casper maybe-ubiquity"
						MENU_OPTN="url=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/isos/${DATA_LINE[4]}"
						MENU_OPTN+=" ip=dhcp ide=nodma fsck.mode=skip boot=casper maybe-ubiquity"
						MENU_OPTN+=" ${LANG_CONF}"
						;;
					*                     )
						MENU_OPTN="url=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/isos/${DATA_LINE[4]}"
						MENU_OPTN+=" ip=dhcp ide=nodma fsck.mode=skip boot=casper layerfs-path=minimal.standard.live.squashfs"
						MENU_OPTN+=" ${LANG_CONF}"
						;;
				esac
				;;
			ubuntu-live-*         )
				HTTP_FILE="url=\${webroot}/isos/\${isofile}"
				OPTN_PARM="\${autocnf} \${urlfile} \${netscnf} \${locales} fsck.mode=skip boot=casper"
				ROOT_PARM=""
				LOOP_BACK=""
				AUTO_CONF="automatic-ubiquity noprompt autoinstall ds=nocloud-net;s=\${webroot}/${DATA_LINE[8]}"
				NETS_CONF="ip=\${ip4addr}::\${ip4gway}:\${ip4mask}:\${hstfqdn}:ens160:static:\${ip4nsvr}"
				LANG_CONF="debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				OPTN_PARM="${AUTO_CONF} ${HTTP_FILE} ${NETS_CONF} ${LANG_CONF} fsck.mode=skip boot=casper"
				MENU_OPTN="automatic-ubiquity noprompt autoinstall ds=nocloud-net;s=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/${DATA_LINE[8]}"
				MENU_OPTN+=" url=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/isos/${DATA_LINE[4]}"
				MENU_OPTN+=" ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:sv-${DATA_LINE[1]%%-*}.workgroup:ens160:static:${IPV4_NSVR}"
				MENU_OPTN+=" fsck.mode=skip boot=casper"
				MENU_OPTN+=" ${LANG_CONF}"
				;;
			fedora-*              | \
			centos-*              | \
			almalinux-*           | \
			rockylinux-*          | \
			miraclelinux-*        )
				HTTP_FILE="url=\${webroot}/isos/\${isofile}"
				OPTN_PARM="\${autocnf} \${netscnf} \${locales} inst.repo=\${webroot}/imgs/${DATA_LINE[1]}"
				ROOT_PARM=""
				LOOP_BACK=""
				AUTO_CONF="inst.ks=\${webroot}/${DATA_LINE[8]}"
				NETS_CONF="ip=\${ip4addr}::\${ip4gway}:\${ip4mask}:\${hstfqdn}:ens160:none,auto6 nameserver=\${ip4nsvr}"
				LANG_CONF="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				MENU_OPTN="inst.ks=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/${DATA_LINE[8]}"
				MENU_OPTN+=" inst.repo=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/imgs/${DATA_LINE[1]}"
				MENU_OPTN+=" ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:sv-${DATA_LINE[1]%%-*}.workgroup:ens160:none,auto6 nameserver=${IPV4_NSVR}"
				MENU_OPTN+=" inst.repo=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/imgs/${DATA_LINE[1]}"
				MENU_OPTN+=" ${LANG_CONF}"
					;;
			opensuse-*            )
				HTTP_FILE="install=\${webroot}/imgs/${DATA_LINE[1]}"
				ROOT_PARM=""
				LOOP_BACK=""
				AUTO_CONF="autoyast=\${webroot}/${DATA_LINE[8]}"
				NETS_CONF="hostname=\${hstfqdn} ifcfg=e*=\${ip4addr}/\${ip4cidr},\${ip4gway},\${ip4nsvr},\${wkgroup}"
				LANG_CONF="locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
				MENU_OPTN="autoyast=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/${DATA_LINE[8]}"
				MENU_OPTN+=" hostname=sv-${DATA_LINE[1]%%-*}.workgroup ifcfg=e*=${IPV4_ADDR}/${IPV4_CIDR},${IPV4_GWAY},${IPV4_NSVR},workgroup"
				case "${DATA_LINE[1]}" in
					opensuse-*-netinst    | \
					opensuse-*-netinst-*  )
						OPTN_PARM="\${autocnf} \${netscnf} \${locales} root=/dev/ram0 load_ramdisk=1 showopts ramdisk_size=4096"
						;;
					*                     )
						OPTN_PARM="\${autocnf} \${netscnf} \${locales} \${urlfile} root=/dev/ram0 load_ramdisk=1 showopts ramdisk_size=4096"
						MENU_OPTN+=" install=${HTTP_PROT}://${HTTP_ADDR}/${HTTP_DIRS}/imgs/${DATA_LINE[1]}"
						;;
				esac
				MENU_OPTN+=" root=/dev/ram0 load_ramdisk=1 showopts ramdisk_size=4096"
				MENU_OPTN+=" ${LANG_CONF}"
				;;
			windows-*             )
					continue
					;;
			memtest86\+           )
				# --- grub menu.cfg -------------------------------------------
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
				# --- syslinux menu.cfg ---------------------------------------
				for J in "${!DIRS_SLNX[@]}"
				do
					if [[ "${DIRS_SLNX[J]}" =~ efi ]]; then
						cat <<- _EOT_ | sed 's/^ *//g' >> "${DIRS_SLNX[J]}/${MENU_SLNX}"
							label ${DATA_LINE[1]}
							 	menu label - ${MENU_ETRY}
							 	kernel boot/${DATA_LINE[1]}/${DATA_LINE[6]}
							
_EOT_
					else
						cat <<- _EOT_ | sed 's/^ *//g' >> "${DIRS_SLNX[J]}/${MENU_SLNX}"
							label ${DATA_LINE[1]}
							 	menu label - ${MENU_ETRY}
							 	kernel boot/${DATA_LINE[1]}/${DATA_LINE[7]}
							
_EOT_
					fi
				done
				continue
				;;
		esac
		# --- grub menu.cfg ---------------------------------------------------
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
		if [[ -z "${LOOP_BACK}" ]]; then					# --- tftp dl -----
			cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
				 	linux     boot/${DATA_LINE[1]}/${DATA_LINE[7]} \${options} ---
				 	initrd    boot/${DATA_LINE[1]}/${DATA_LINE[6]}
_EOT_
		else												# --- loopback ----
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
		# --- syslinux menu.cfg -----------------------------------------------
		for J in "${!DIRS_SLNX[@]}"
		do
			cat <<- _EOT_ | sed 's/^ *//g' >> "${DIRS_SLNX[J]}/${MENU_SLNX}"
				label ${DATA_LINE[1]}
				 	menu label - ${MENU_ETRY}
				 	kernel boot/${DATA_LINE[1]}/${DATA_LINE[7]}
				 	append initrd=boot/${DATA_LINE[1]}/${DATA_LINE[6]} vga=791 ${MENU_OPTN} ---
				
_EOT_
		done
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
	cp --archive --update /usr/share/grub/unicode.pf2 "${DIRS_TFTP}/grub/fonts/"
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

# ---- function test ----------------------------------------------------------
function funcCall_function() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call function test"
	declare -r    FILE_WRK1="${DIRS_TEMP}/testfile1.txt"
	declare -r    FILE_WRK2="${DIRS_TEMP}/testfile2.txt"
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

# --- main --------------------------------------------------------------------
function funcMain() {
	declare -i    start_time=0
	declare -i    end_time=0
	declare -i    I=0
	declare -a    COMD_LINE=("${PROG_PARM[@]}")

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
	if [[ "${ROW_SIZE}" -lt 25 ]]; then
		ROW_SIZE=25
	fi
	if [[ "${COL_SIZE}" -lt 80 ]]; then
		COL_SIZE=80
	fi

	# --- main ----------------------------------------------------------------
	start_time=$(date +%s)
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"

	mkdir -p "${WORK_DIRS}/"{mnt,tmp}

	case "${COMD_LINE[0]}" in
		-a | --all)                     # --- all operations ------------------
			COMD_LINE=( \
				"--config=preseed,nocloud,kickstart,autoyast" \
				"--menu=grub,menu" \
				"--grub=i386,x64,font" \
			)
			;;
	esac

	for ((I=0; I<${#COMD_LINE[@]}; I++))
	do
		case "${COMD_LINE[I]}" in
#			-i | --install)             # --- all server environment setup ----
#				COMD_LINE[I]="--install=dhcp,tftp,http"
#				;;
			-c | --config)              # --- all configuration files ---------
				COMD_LINE[I]="--config=preseed,nocloud,kickstart,autoyast"
				;;
			-m | --menu)                # --- all grub menu files -------------
				COMD_LINE[I]="--menu=grub,menu"
				;;
			-g | --grub)                # --- all grub environment files ------
				COMD_LINE[I]="--grub=i386,x64,font"
				;;
			-s | --service)             # --- all services control ------------
				COMD_LINE[I]="--service=restart,status"
				;;
		esac
		IFS=','
		set -f
		# shellcheck disable=SC2086
		set -- ${COMD_LINE[I]#*=}
		set +f
		IFS=${OLD_IFS}
		case "${COMD_LINE[I]}" in
			-i=* | --install=*)			# --- setup server environment --------
				while [[ -n "${1:-}" ]]
				do
					case "$1" in
						dhcp)			# --- make dhcpd.conf -----------------
							funcMake_dhcpd_conf
							;;
						tftp)
							;;
						http)
							;;
						default.dhcp)	# --- change isc-dhcp-server ----------
							funcMake_isc_dhcp_server
							;;
						default.tftp)	# --- change tftpd-hpa ----------------
							funcMake_tftpd_hpa
							;;
					esac
					shift
				done
				;;
			-c=* | --config=*)          # --- make configuration file ---------
				while [[ -n "${1:-}" ]]
				do
					case "$1" in
						preseed)        # --- make preseed directory files ----
							funcMake_preseed_kill_dhcp_sh
							funcMake_preseed_sub_command_sh
							funcMake_preseed_cfg
							;;
						nocloud)        # --- make nocloud directory files ----
							funcMake_nocloud
							;;
						kickstart)      # --- make kickstart directory files --
							funcMake_kickstart
							;;
						autoyast)       # --- make autoyast directory files ---
							funcMake_autoyast
							;;
					esac
					shift
				done
				;;
			-m=* | --menu=*)            # --- make grub menu file -------------
				while [[ -n "${1:-}" ]]
				do
					case "$1" in
						grub)           # --- make grub.cfg file --------------
							funcMake_grub_cfg
							funcMake_syslinux_cfg
							;;
						menu)           # --- make menu.cfg file --------------
							funcMake_menu_cfg
							;;
					esac
					shift
				done
				;;
			-g=* | --grub=*)            # --- make grub environment -----------
				while [[ -n "${1:-}" ]]
				do
					case "$1" in
						i386)           # --- make grubi386.img ---------------
							funcMake_grubi386_img
							;;
						x64)            # --- make grubx64.efi ----------------
							funcMake_grubx64_efi
							;;
						font)           # --- copy font -----------------------
							funcCopy_font
							;;
					esac
					shift
				done
				;;
			-s=* | --service=*)         # --- services control ----------------
				while [[ -n "${1:-}" ]]
				do
					case "$1" in
						restart)        # --- restart service -----------------
							funcRestart_service
							;;
						status)         # --- status service ------------------
							funcStatus_service
							;;
					esac
					shift
				done
				;;
			-d)
				funcCall_function
				;;
			*)                          # --- help ----------------------------
				echo "${PROG_PATH}"
				echo "-a | --all     all operations"
				echo "-c | --config  [={ preseed | nocloud | kickstart | autoyast }]"
				echo "-m | --menu    [={ grub | menu }]"
				echo "-g | --grub    [={ i386 | x64 | font }]"
				echo "-s | --service [={ restart | status }]"
				echo "ex: ${PROG_PATH} --config=preseed,nocloud,kickstart,autoyast"
				echo "    ${PROG_PATH} --config : no parameters, set as all"
				break
				;;
		esac
	done

	rm -rf "${WORK_DIRS}"

	# common functions --------------------------------------------------------
#	funcColorTest						# --- text color test -----------------
#	funcIsNumeric ""					# --- is numeric ----------------------
#	funcString 0 ""						# --- string output -------------------
#	funcPrintf ""						# --- print with screen control -------
#	funcCurl ""							# --- download ------------------------

	# -------------------------------------------------------------------------
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing end${TXT_RESET}"
	end_time=$(date +%s)
	echo "elapsed time: $((end_time-start_time)) [sec]"
}

# *** main processing section *************************************************
	funcMain
	exit 0

### eof #######################################################################
