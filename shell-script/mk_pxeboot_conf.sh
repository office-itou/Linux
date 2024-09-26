#!/bin/bash
###############################################################################
##
##	pxeboot configuration shell
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

	# -------------------------------------------------------------------------
	declare -r -a APP_LIST=("tftpd-hpa" "syslinux-common" "syslinux-efi" "pxelinux" "grub-common" "grub-efi-amd64" "grub-pc-bin" "dnsmasq" "apache2" "7zip" "rsync" "bzip2" "gzip" "lz4" "lzop" "xz-utils" "zstd")
	declare -a    APP_FIND=()
	declare       APP_LINE=""
	# shellcheck disable=SC2312
	mapfile APP_FIND < <(LANG=C apt list "${APP_LIST[@]}" 2> /dev/null | sed -e '/\(^[[:blank:]]*$\|WARNING\|Listing\|installed\)/! {' -e 's%\([[:graph:]]\)/.*%\1%g' -ne 'p}' | sed -z 's/[\r\n]\+/ /g')
	for I in "${!APP_FIND[@]}"
	do
		APP_LINE+="${APP_LINE:+" "}${APP_FIND[${I}]}"
	done
	if [[ -n "${APP_LINE}" ]]; then
		echo "please install these:"
		echo "sudo apt-get install ${APP_LINE}"
		exit 1
	fi

# *** data section ************************************************************

	# --- tftp server ---------------------------------------------------------
	# funcNetwork_pxe_conf creates directory
	#
	# tree diagram
	#   ${HOME}/share
	#   |-- back ------------------------------ backup directory
	#   |-- conf ------------------------------ configuration file
	#   |   |-- _template
	#   |   |   |-- kickstart_common.cfg
	#   |   |   |-- live_debian.yaml
	#   |   |   |-- live_ubuntu.yaml
	#   |   |   |-- nocloud-ubuntu-user-data
	#   |   |   |-- preseed_debian.cfg
	#   |   |   |-- preseed_ubuntu.cfg
	#   |   |   `-- yast_opensuse.xml
	#   |   |-- autoyast
	#   |   |-- kickstart
	#   |   |-- nocloud
	#   |   |-- preseed
	#   |   |-- script
	#   |   |   |-- late_command.sh
	#   |   |   |-- live_0000-user-conf-param.sh
	#   |   |   |-- live_9999-user-conf-debug.sh
	#   |   |   `-- live_9999-user-conf-setup.sh
	#   |   `-- windows
	#   |       |-- bypass.cmd
	#   |       |-- inst_w10.cmd
	#   |       |-- inst_w11.cmd
	#   |       |-- shutdown.cmd
	#   |       |-- startnet.cmd
	#   |       |-- unattend.xml
	#   |       `-- winpeshl.ini
	#   |-- html <- /var/www/html ------------- html contents
	#   |   |-- conf -> ../conf
	#   |   |-- imgs -> ../imgs
	#   |   |-- isos -> ../isos
	#   |   |-- load -> ../tftp/load
	#   |   |-- pack -> ../pack
	#   |   `-- rmak -> ../rmak
	#   |-- imgs ------------------------------ iso file extraction destination
	#   |-- isos ------------------------------ iso file
	#   |-- keys ------------------------------ keyring file
	#   |-- live ------------------------------ live media file
	#   |-- orig ------------------------------ backup directory (original file)
	#   |-- pack
	#   |   |-- debian
	#   |   `-- ubuntu
	#   |-- rmak ------------------------------ remake file
	#   |-- temp ------------------------------ temporary directory
	#   `-- tftp <- /var/lib/tftpboot --------- tftp contents
	#       |-- autoexec.ipxe ----------------- ipxe script file (menu file)
	#       |-- memdisk ----------------------- memdisk of syslinux
	#       |-- boot
	#       |   `-- grub
	#       |       |-- bootx64.efi ----------- bootloader (i386-pc-pxe)
	#       |       |-- grub.cfg -------------- menu base
	#       |       |-- menu.cfg -------------- menu file
	#       |       |-- pxelinux.0 ------------ bootloader (x86_64-efi)
	#       |       |-- fonts
	#       |       |   `-- unicode.pf2
	#       |       |-- i386-pc
	#       |       |-- locale
	#       |       `-- x86_64-efi
	#       |-- imgs -> ../imgs
	#       |-- ipxe -------------------------- ipxe module
	#       |   |-- ipxe.efi
	#       |   |-- undionly.kpxe
	#       |   `-- wimboot
	#       |-- isos -> ../isos
	#       |-- load -------------------------- load module
	#       |-- menu-bios
	#       |   |-- syslinux.cfg -------------- syslinux configuration for mbr environment
	#       |   |-- imgs -> ../../imgs
	#       |   |-- isos -> ../../isos
	#       |   |-- load -> ../load
	#       |   `-- pxelinux.cfg
	#       |       `-- default -> ../syslinux.cfg
	#       `-- menu-efi64
	#           |-- syslinux.cfg -------------- syslinux configuration for uefi(x86_64) environment
	#           |-- imgs -> ../../imgs
	#           |-- isos -> ../../isos
	#           |-- load -> ../load
	#           `-- pxelinux.cfg
	#               `-- default -> ../syslinux.cfg
	#   
	#   /var/lib/
	#   `-- tftpboot -> ${HOME}/share/tftp
	#   
	#   /var/www/
	#   `-- html -> ${HOME}/share/html
	#   
	#   /etc/dnsmasq.d/
	#   `-- pxe.conf -------------------------- pxeboot dnsmasq configuration file

# --- working directory name --------------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
#	declare -r    DIRS_WORK="${PWD}/${PROG_NAME%.*}"
	declare -r    DIRS_WORK="${PWD}/share"
	if [[ "${DIRS_WORK}" = "/" ]]; then
		echo "terminate the process because the working directory is root"
		exit 1
	fi
	declare -r    DIRS_BACK="${DIRS_WORK}/back"					# backup
	declare -r    DIRS_CONF="${DIRS_WORK}/conf"					# configuration file
	declare -r    DIRS_HTML="${DIRS_WORK}/html"					# html contents
	declare -r    DIRS_IMGS="${DIRS_WORK}/imgs"					# iso file extraction destination
	declare -r    DIRS_ISOS="${DIRS_WORK}/isos"					# iso file
	declare -r    DIRS_ORIG="${DIRS_WORK}/orig"					# original file
	declare -r    DIRS_RMAK="${DIRS_WORK}/rmak"					# remake file
	declare -r    DIRS_TEMP="${DIRS_WORK}/temp/${PROG_PROC}"	# temporary directory
	declare -r    DIRS_TFTP="${DIRS_WORK}/tftp"					# tftp contents

	# --- server service ------------------------------------------------------
	declare -r    HTML_ROOT="/var/www/html"						# html contents
	declare -r    TFTP_ROOT="/var/lib/tftpboot"					# tftp contents
#	declare -r    TFTP_ROOT="/var/tftp"							# tftp contents

# --- work variables ----------------------------------------------------------
	declare -r    OLD_IFS="${IFS}"

# --- set minimum display size ------------------------------------------------
	declare -i    ROWS_SIZE=80
	declare -i    COLS_SIZE=25

# --- niceness values ---------------------------------------------------------
	declare -r -i NICE_VALU=19								# -20: favorable to the process
															#  19: least favorable to the process
	declare -r -i IONICE_CLAS=3								#   1: Realtime
															#   2: Best-effort
															#   3: Idle
#	declare -r -i IONICE_VALU=0								#   0: favorable to the process
															#   7: least favorable to the process

# --- set parameters ----------------------------------------------------------

	# === menu ================================================================

	# --- menu timeout --------------------------------------------------------
#	declare -r    MENU_TOUT="50"							# timeout [m sec]

	# --- menu resolution -----------------------------------------------------
															# resolution
#	declare -r    MENU_RESO="7680x4320"						# 8K UHD (16:9)
#	declare -r    MENU_RESO="3840x2400"						#        (16:10)
#	declare -r    MENU_RESO="3840x2160"						# 4K UHD (16:9)
#	declare -r    MENU_RESO="2880x1800"						#        (16:10)
#	declare -r    MENU_RESO="2560x1600"						#        (16:10)
#	declare -r    MENU_RESO="2560x1440"						# WQHD   (16:9)
#	declare -r    MENU_RESO="1920x1440"						#        (4:3)
#	declare -r    MENU_RESO="1920x1200"						# WUXGA  (16:10)
#	declare -r    MENU_RESO="1920x1080"						# FHD    (16:9)
#	declare -r    MENU_RESO="1856x1392"						#        (4:3)
#	declare -r    MENU_RESO="1792x1344"						#        (4:3)
#	declare -r    MENU_RESO="1680x1050"						# WSXGA+ (16:10)
#	declare -r    MENU_RESO="1600x1200"						# UXGA   (4:3)
#	declare -r    MENU_RESO="1400x1050"						#        (4:3)
#	declare -r    MENU_RESO="1440x900"						# WXGA+  (16:10)
#	declare -r    MENU_RESO="1360x768"						# HD     (16:9)
#	declare -r    MENU_RESO="1280x1024"						# SXGA   (5:4)
#	declare -r    MENU_RESO="1280x960"						#        (4:3)
#	declare -r    MENU_RESO="1280x800"						#        (16:10)
#	declare -r    MENU_RESO="1280x768"						#        (4:3)
#	declare -r    MENU_RESO="1280x720"						# WXGA   (16:9)
#	declare -r    MENU_RESO="1152x864"						#        (4:3)
	declare -r    MENU_RESO="1024x768"						# XGA    (4:3)
#	declare -r    MENU_RESO="800x600"						# SVGA   (4:3)
#	declare -r    MENU_RESO="640x480"						# VGA    (4:3)

															# colors
#	declare -r    MENU_DPTH="8"								# 256
#	declare -r    MENU_DPTH="16"							# 65536
#	declare -r    MENU_DPTH="24"							# 16 million
#	declare -r    MENU_DPTH="32"							# 4.2 billion

	# === screen mode (vga=nnn) ===============================================
#															# 7680x4320   : 8K UHD (16:9)
#															# 3840x2400   :        (16:10)
#															# 3840x2160   : 4K UHD (16:9)
#															# 2880x1800   :        (16:10)
#															# 2560x1600   :        (16:10)
#															# 2560x1440   : WQHD   (16:9)
#															# 1920x1440   :        (4:3)
#	declare -r    SCRN_MODE="893"							# 1920x1200x 8: WUXGA  (16:10)
#	declare -r    SCRN_MODE=""								#          x16
#	declare -r    SCRN_MODE=""								#          x24
#	declare -r    SCRN_MODE=""								#          x32
#	declare -r    SCRN_MODE=""								# 1920x1080x 8: FHD    (16:9)
#	declare -r    SCRN_MODE=""								#          x16
#	declare -r    SCRN_MODE=""								#          x24
#	declare -r    SCRN_MODE="980"							#          x32
#															# 1856x1392   :        (4:3)
#															# 1792x1344   :        (4:3)
#															# 1680x1050   : WSXGA+ (16:10)
#															# 1600x1200   : UXGA   (4:3)
#															# 1400x1050   :        (4:3)
#															# 1440x 900   : WXGA+  (16:10)
#															# 1360x 768   : HD     (16:9)
#	declare -r    SCRN_MODE="775"							# 1280x1024x 8: SXGA   (5:4)
#	declare -r    SCRN_MODE="794"							#          x16
#	declare -r    SCRN_MODE="795"							#          x24
#	declare -r    SCRN_MODE="829"							#          x32
#															# 1280x 960   :        (4:3)
#															# 1280x 800   :        (16:10)
#															# 1280x 768   :        (4:3)
#															# 1280x 720   : WXGA   (16:9)
#															# 1152x 864   :        (4:3)
#	declare -r    SCRN_MODE="773"							# 1024x 768x 8: XGA    (4:3)
#	declare -r    SCRN_MODE="791"							#          x16
#	declare -r    SCRN_MODE="792"							#          x24
#	declare -r    SCRN_MODE="824"							#          x32
#	declare -r    SCRN_MODE="771"							#  800x 600x 8: SVGA   (4:3)
#	declare -r    SCRN_MODE="788"							#          x16
#	declare -r    SCRN_MODE="789"							#          x24
#	declare -r    SCRN_MODE="814"							#          x32
#	declare -r    SCRN_MODE="769"							#  640x 480x 8: VGA    (4:3)
#	declare -r    SCRN_MODE="785"							#          x16
#	declare -r    SCRN_MODE="786"							#          x24
#	declare -r    SCRN_MODE="809"							#          x32

	# --- vga mode ------------------------------------------------------------
	# |           | video |   8 |  16 |  24 |  32 | bit
	# |screnn size| info  | 256 | 64k | 16M |  4G | colors
	# |  320x 200 | 0x000 | --- | --- | --- | --- |        (16:10)
	# |  320x 240 | 0x00b | --- | --- | --- | --- |        (4:3)
	# |  400x 300 | 0x00c | --- | --- | --- | --- |        (4:3)
	# |  512x 384 | 0x00d | --- | --- | --- | --- |        (4:3)
	# |  640x 480 | 0x001 | 769 | 785 | 786 | 809 | VGA    (4:3)
	# |  720x 480 | 0x012 | --- | --- | --- | --- |        (3:2)
	# |  720x 576 | 0x013 | --- | --- | --- | --- |        ()
	# |  800x 480 | 0x014 | --- | --- | --- | --- |        (5:3)
	# |  800x 600 | 0x002 | 771 | 788 | 789 | 814 | SVGA   (4:3)
	# |  854x 480 | 0x00e | --- | --- | --- | --- |        (16:9)
	# | 1024x 768 | 0x003 | 773 | 791 | 792 | 824 | XGA    (4:3)
	# | 1152x 864 | 0x005 | --- | --- | --- | --- |        (4:3)
	# | 1280x 720 | 0x00f | --- | --- | --- | --- | WXGA   (16:9)
	# | 1280x 768 | 0x015 | --- | --- | --- | --- |        (4:3)
	# | 1280x 800 | 0x010 | --- | --- | --- | --- |        (16:10)
	# | 1280x 960 | 0x006 | --- | --- | --- | --- |        (4:3)
	# | 1280x1024 | 0x004 | 775 | 794 | 795 | 829 | SXGA   (5:4)
	# | 1280x1024 | 0x007 | --- | --- | --- | --- | SXGA   (5:4)
	# | 1360x 768 | 0x00a | --- | --- | --- | --- | HD     (16:9)
	# | 1400x1050 | 0x008 | --- | --- | --- | --- |        (4:3)
	# | 1440x 900 | 0x011 | --- | --- | --- | --- | WXGA+  (16:10)
	# | 1600x1200 | 0x009 | --- | --- | --- | --- | UXGA   (4:3)
	# | 1680x1050 |       | --- | --- | --- | --- | WSXGA+ (16:10)
	# | 1792x1344 |       | --- | --- | --- | --- |        (4:3)
	# | 1856x1392 |       | --- | --- | --- | --- |        (4:3)
	# | 1920x1080 |       | --- | --- | --- | 980 | FHD    (16:9)
	# | 1920x1200 |       | 893 | --- | --- | --- | WUXGA  (16:10)
	# | 1920x1440 |       | --- | --- | --- | --- |        (4:3)
	# | 2560x1440 |       | --- | --- | --- | --- | WQHD   (16:9)
	# | 2560x1600 |       | --- | --- | --- | --- |        (16:10)
	# | 2880x1800 |       | --- | --- | --- | --- |        (16:10)
	# | 3840x2160 |       | --- | --- | --- | --- | 4K UHD (16:9)
	# | 3840x2400 |       | --- | --- | --- | --- |        (16:10)
	# | 7680x4320 |       | --- | --- | --- | --- | 8K UHD (16:9)

	# === network =============================================================

#	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"		# hostname
	declare -r    WGRP_NAME="workgroup"						# domain
	declare -r    ETHR_NAME="ens160"						# network device name
	declare -r    IPV4_ADDR="192.168.1.1"					# IPv4 address
	declare -r    IPV4_CIDR="24"							# IPv4 cidr
	declare -r    IPV4_MASK="255.255.255.0"					# IPv4 subnetmask
	declare -r    IPV4_GWAY="192.168.1.254"					# IPv4 gateway
	declare -r    IPV4_NSVR="192.168.1.254"					# IPv4 nameserver

	# === system ==============================================================

	# --- tftp / web server address -------------------------------------------
	# shellcheck disable=SC2155
	declare -r    SRVR_ADDR="$(LANG=C ip -4 -oneline address show scope global | awk '{split($4,s,"/"); print s[1];}')"
#	declare -r    TFTP_PROT="http://"
#	declare -r    TFTP_ADDR="\${net_default_server}"
	declare -r    HTTP_ADDR="http://\${svraddr}"

	# --- open-vm-tools -------------------------------------------------------
	declare -r    HGFS_DIRS="/mnt/hgfs/workspace/Image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
	declare -r    CONF_LINK="${HGFS_DIRS}/linux/bin/conf/_template"
	declare -r    CONF_DIRS="${DIRS_CONF}/_template"
	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	# --- autoinstall configuration file --------------------------------------
#	declare -r    AUTO_INST="autoinst.cfg"

	# --- initial ram disk of mini.iso including preseed ----------------------
#	declare -r    MINI_IRAM="initps.gz"

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

# --- mini.iso ----------------------------------------------------------------
	declare -r -a DATA_LIST_MINI=(                                                                                                                                                                                                                                                                                                                                                                                                                                                \
		"m  menu-entry                  Auto%20install%20mini.iso           -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
		"x  debian-mini-10              Debian%2010                         debian          mini-buster-amd64.iso                       .                                       initrd.gz                   linux                   preseed/ps_debian_server_old.cfg        linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/mini.iso                                 " \
		"o  debian-mini-11              Debian%2011                         debian          mini-bullseye-amd64.iso                     .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso                               " \
		"o  debian-mini-12              Debian%2012                         debian          mini-bookworm-amd64.iso                     .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso                               " \
		"o  debian-mini-13              Debian%2013                         debian          mini-trixie-amd64.iso                       .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso                                 " \
		"-  debian-mini-14              Debian%2014                         debian          mini-forky-amd64.iso                        .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso                                  " \
		"o  debian-mini-testing         Debian%20testing                    debian          mini-testing-amd64.iso                      .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso                                                                " \
		"o  ubuntu-mini-18.04           Ubuntu%2018.04                      ubuntu          mini-bionic-amd64.iso                       .                                       initrd.gz                   linux                   preseed/ps_ubuntu_server_old.cfg        linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso                      " \
		"o  ubuntu-mini-20.04           Ubuntu%2020.04                      ubuntu          mini-focal-amd64.iso                        .                                       initrd.gz                   linux                   preseed/ps_ubuntu_server_old.cfg        linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso                " \
		"m  menu-entry                  -                                   -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

# --- netinst -----------------------------------------------------------------
	declare -r -a DATA_LIST_NET=(                                                                                                                                                                                                                                                                                                                                                                                                                                                 \
		"m  menu-entry                  Auto%20install%20Net%20install      -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
		"x  debian-netinst-10           Debian%2010                         debian          debian-10.13.0-amd64-netinst.iso            install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_old.cfg        linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-10.[0-9.]*-amd64-netinst.iso                 " \
		"o  debian-netinst-11           Debian%2011                         debian          debian-11.11.0-amd64-netinst.iso            install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-11.[0-9.]*-amd64-netinst.iso                    " \
		"o  debian-netinst-12           Debian%2012                         debian          debian-12.7.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso                             " \
		"o  debian-netinst-13           Debian%2013                         debian          debian-13.0.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"-  debian-netinst-14           Debian%2014                         debian          debian-14.0.0-amd64-netinst.iso             install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  debian-netinst-testing      Debian%20testing                    debian          debian-testing-amd64-netinst.iso            install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso                 " \
		"x  fedora-netinst-38           Fedora%20Server%2038                fedora          Fedora-Server-netinst-x86_64-38-1.6.iso     images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-38_net.cfg          linux/fedora        2023-04-18  2024-05-14  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-netinst-x86_64-38-[0-9.]*.iso   " \
		"o  fedora-netinst-39           Fedora%20Server%2039                fedora          Fedora-Server-netinst-x86_64-39-1.5.iso     images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-39_net.cfg          linux/fedora        2023-11-07  2024-11-12  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-netinst-x86_64-39-[0-9.]*.iso   " \
		"o  fedora-netinst-40           Fedora%20Server%2040                fedora          Fedora-Server-netinst-x86_64-40-1.14.iso    images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-40_net.cfg          linux/fedora        2024-04-16  2025-05-13  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-netinst-x86_64-40-[0-9.]*.iso   " \
		"x  centos-stream-netinst-8     CentOS%20Stream%208                 centos          CentOS-Stream-8-x86_64-latest-boot.iso      images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-8_net.cfg    linux/centos        20xx-xx-xx  2024-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-boot.iso                              " \
		"o  centos-stream-netinst-9     CentOS%20Stream%209                 centos          CentOS-Stream-9-latest-x86_64-boot.iso      images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-9_net.cfg    linux/centos        2021-xx-xx  2027-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                 " \
		"o  centos-stream-netinst-10    CentOS%20Stream%2010                centos          CentOS-Stream-10-latest-x86_64-boot.iso     images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-10_net.cfg   linux/centos        2024-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso               " \
		"o  almalinux-netinst-9         Alma%20Linux%209                    almalinux       AlmaLinux-9-latest-x86_64-boot.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_almalinux-9_net.cfg        linux/almalinux     2022-05-26  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9[0-9.]*-latest-x86_64-boot.iso                                    " \
		"o  rockylinux-netinst-8        Rocky%20Linux%208                   Rocky           Rocky-8.10-x86_64-boot.iso                  images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-8_net.cfg       linux/Rocky         2022-11-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-boot.iso                                          " \
		"o  rockylinux-netinst-9        Rocky%20Linux%209                   Rocky           Rocky-9-latest-x86_64-boot.iso              images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-9_net.cfg       linux/Rocky         2022-07-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9[0-9.]*-latest-x86_64-boot.iso                                   " \
		"o  miraclelinux-netinst-8      Miracle%20Linux%208                 miraclelinux    MIRACLELINUX-8.8-rtm-minimal-x86_64.iso     images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-8_net.cfg     linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-minimal-x86_64.iso    " \
		"o  miraclelinux-netinst-9      Miracle%20Linux%209                 miraclelinux    MIRACLELINUX-9.4-rtm-minimal-x86_64.iso     images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-9_net.cfg     linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-minimal-x86_64.iso    " \
		"o  opensuse-leap-netinst-15.5  openSUSE%20Leap%2015.5              openSUSE        openSUSE-Leap-15.5-NET-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.5_net.xml     linux/openSUSE      2023-06-07  2024-12-31  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.5/iso/openSUSE-Leap-15.5-NET-x86_64-Media.iso                          " \
		"o  opensuse-leap-netinst-15.6  openSUSE%20Leap%2015.6              openSUSE        openSUSE-Leap-15.6-NET-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.6_net.xml     linux/openSUSE      2024-06-xx  2025-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Media.iso                          " \
		"o  opensuse-tumbleweed-netinst openSUSE%20Tumbleweed               openSUSE        openSUSE-Tumbleweed-NET-x86_64-Current.iso  boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_tumbleweed_net.xml    linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                   " \
		"m  menu-entry                  -                                   -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

# --- dvd image ---------------------------------------------------------------
	declare -r -a DATA_LIST_DVD=(                                                                                                                                                                                                                                                                                                                                                                                                                                                 \
		"m  menu-entry                  Auto%20install%20DVD%20media        -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
		"x  debian-10                   Debian%2010                         debian          debian-10.13.0-amd64-DVD-1.iso              install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_old.cfg        linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-10.[0-9.]*-amd64-DVD-1.iso                  " \
		"o  debian-11                   Debian%2011                         debian          debian-11.11.0-amd64-DVD-1.iso              install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.[0-9.]*-amd64-DVD-1.iso                     " \
		"o  debian-12                   Debian%2012                         debian          debian-12.7.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-12.[0-9.]*-amd64-DVD-1.iso                              " \
		"o  debian-13                   Debian%2013                         debian          debian-13.0.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"-  debian-14                   Debian%2014                         debian          debian-14.0.0-amd64-DVD-1.iso               install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  debian-testing              Debian%20testing                    debian          debian-testing-amd64-DVD-1.iso              install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                                   " \
		"x  ubuntu-server-14.04         Ubuntu%2014.04%20Server             ubuntu          ubuntu-14.04.6-server-amd64.iso             install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_old.cfg        linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"-  ubuntu-server-16.04         Ubuntu%2016.04%20Server             ubuntu          ubuntu-16.04.6-server-amd64.iso             install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_old.cfg        linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  ubuntu-server-18.04         Ubuntu%2018.04%20Server             ubuntu          ubuntu-18.04.6-server-amd64.iso             install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_old.cfg        linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04[0-9.]*-server-amd64.iso                                         " \
		"o  ubuntu-live-18.04           Ubuntu%2018.04%20Live%20Server      ubuntu          ubuntu-18.04.6-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server_old               linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-live-server-amd64.iso                                                    " \
		"o  ubuntu-live-20.04           Ubuntu%2020.04%20Live%20Server      ubuntu          ubuntu-20.04.6-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-live-server-amd64.iso                                                     " \
		"o  ubuntu-live-22.04           Ubuntu%2022.04%20Live%20Server      ubuntu          ubuntu-22.04.5-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-live-server-amd64.iso                                                     " \
		"x  ubuntu-live-23.04           Ubuntu%2023.04%20Live%20Server      ubuntu          ubuntu-23.04-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-live-server-amd64.iso                                                     " \
		"x  ubuntu-live-23.10           Ubuntu%2023.10%20Live%20Server      ubuntu          ubuntu-23.10-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-live-server-amd64.iso                                                    " \
		"o  ubuntu-live-24.04           Ubuntu%2024.04%20Live%20Server      ubuntu          ubuntu-24.04.1-live-server-amd64.iso        casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-live-server-amd64.iso                                                     " \
		"-  ubuntu-live-24.10           Ubuntu%2024.10%20Live%20Server      ubuntu          ubuntu-24.10-live-server-amd64.iso          casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-live-server-amd64.iso                                                  " \
		"o  ubuntu-live-oracular        Ubuntu%20oracular%20Live%20Server   ubuntu          oracular-live-server-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/oracular-live-server-amd64.iso                                      " \
		"x  fedora-38                   Fedora%20Server%2038                fedora          Fedora-Server-dvd-x86_64-38-1.6.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-38_dvd.cfg          linux/fedora        2023-04-18  2024-05-14  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-dvd-x86_64-38-[0-9.]*.iso       " \
		"o  fedora-39                   Fedora%20Server%2039                fedora          Fedora-Server-dvd-x86_64-39-1.5.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-39_dvd.cfg          linux/fedora        2023-11-07  2024-11-12  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-dvd-x86_64-39-[0-9.]*.iso       " \
		"o  fedora-40                   Fedora%20Server%2040                fedora          Fedora-Server-dvd-x86_64-40-1.14.iso        images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-40_dvd.cfg          linux/fedora        2024-04-16  2025-05-13  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-dvd-x86_64-40-[0-9.]*.iso       " \
		"x  centos-stream-8             CentOS%20Stream%208                 centos          CentOS-Stream-8-x86_64-latest-dvd1.iso      images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-8_dvd.cfg    linux/centos        2019-xx-xx  2024-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-dvd1.iso                              " \
		"o  centos-stream-9             CentOS%20Stream%209                 centos          CentOS-Stream-9-latest-x86_64-dvd1.iso      images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-9_dvd.cfg    linux/centos        2021-xx-xx  2027-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                 " \
		"o  centos-stream-10            CentOS%20Stream%2010                centos          CentOS-Stream-10-latest-x86_64-dvd1.iso     images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-10_dvd.cfg   linux/centos        2024-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso               " \
		"o  almalinux-9                 Alma%20Linux%209                    almalinux       AlmaLinux-9-latest-x86_64-dvd.iso           images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_almalinux-9_dvd.cfg        linux/almalinux     2022-05-26  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9[0-9.]*-latest-x86_64-dvd.iso                                     " \
		"o  rockylinux-8                Rocky%20Linux%208                   Rocky           Rocky-8.10-x86_64-dvd1.iso                  images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-8_dvd.cfg       linux/Rocky         2022-11-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-dvd1.iso                                          " \
		"o  rockylinux-9                Rocky%20Linux%209                   Rocky           Rocky-9-latest-x86_64-dvd.iso               images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-9_dvd.cfg       linux/Rocky         2022-07-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9[0-9.]*-latest-x86_64-dvd.iso                                    " \
		"o  miraclelinux-8              Miracle%20Linux%208                 miraclelinux    MIRACLELINUX-8.8-rtm-x86_64.iso             images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-8_dvd.cfg     linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-x86_64.iso            " \
		"o  miraclelinux-9              Miracle%20Linux%209                 miraclelinux    MIRACLELINUX-9.4-rtm-x86_64.iso             images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-9_dvd.cfg     linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso            " \
		"o  opensuse-leap-15.5          openSUSE%20Leap%2015.5              openSUSE        openSUSE-Leap-15.5-DVD-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.5_dvd.xml     linux/openSUSE      2023-06-07  2024-12-31  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.5/iso/openSUSE-Leap-15.5-DVD-x86_64-Media.iso                          " \
		"o  opensuse-leap-15.6          openSUSE%20Leap%2015.6              openSUSE        openSUSE-Leap-15.6-DVD-x86_64-Media.iso     boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.6_dvd.xml     linux/openSUSE      2024-06-xx  2025-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso                          " \
		"o  opensuse-tumbleweed         openSUSE%20Tumbleweed               openSUSE        openSUSE-Tumbleweed-DVD-x86_64-Current.iso  boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_tumbleweed_dvd.xml    linux/openSUSE      2021-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                   " \
		"o  windows-10                  Windows%2010                        windows         Win10_22H2_Japanese_x64.iso                 -                                       -                           -                       -                                       windows/Windows10   -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  windows-11                  Windows%2011                        windows         Win11_23H2_Japanese_x64v2.iso               -                                       -                           -                       -                                       windows/Windows11   -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"-  windows-11                  Windows%2011%20custom               windows         Win11_23H2_Japanese_x64v2_custom.iso        -                                       -                           -                       -                                       windows/Windows11   -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"m  menu-entry                  -                                   -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

# --- live media install mode -------------------------------------------------
	declare -r -a DATA_LIST_INST=(                                                                                                                                                                                                                                                                                                                                                                                                                                                \
		"m  menu-entry                  Live%20media%20Install%20mode       -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
		"x  debian-live-10              Debian%2010%20Live                  debian          debian-live-10.13.0-amd64-lxde.iso          d-i                                     initrd.gz                   vmlinuz                 preseed/ps_debian_desktop_old.cfg       linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-10.[0-9.]*-amd64-lxde.iso      " \
		"o  debian-live-11              Debian%2011%20Live                  debian          debian-live-11.11.0-amd64-lxde.iso          d-i                                     initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso         " \
		"o  debian-live-12              Debian%2012%20Live                  debian          debian-live-12.7.0-amd64-lxde.iso           install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                  " \
		"o  debian-live-13              Debian%2013%20Live                  debian          debian-live-13.0.0-amd64-lxde.iso           install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  debian-live-testing         Debian%20testing%20Live             debian          debian-live-testing-amd64-lxde.iso          install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                       " \
		"x  ubuntu-desktop-14.04        Ubuntu%2014.04%20Desktop            ubuntu          ubuntu-14.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_old.cfg     linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"x  ubuntu-desktop-16.04        Ubuntu%2016.04%20Desktop            ubuntu          ubuntu-16.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_old.cfg     linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"x  ubuntu-desktop-18.04        Ubuntu%2018.04%20Desktop            ubuntu          ubuntu-18.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_old.cfg     linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-desktop-amd64.iso                                                        " \
		"o  ubuntu-desktop-20.04        Ubuntu%2020.04%20Desktop            ubuntu          ubuntu-20.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                         " \
		"o  ubuntu-desktop-22.04        Ubuntu%2022.04%20Desktop            ubuntu          ubuntu-22.04.5-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                         " \
		"x  ubuntu-desktop-23.04        Ubuntu%2023.04%20Desktop            ubuntu          ubuntu-23.04-desktop-amd64.iso              casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-desktop-amd64.iso                                                         " \
		"x  ubuntu-desktop-23.10        Ubuntu%2023.10%20Desktop            ubuntu          ubuntu-23.10.1-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-desktop-amd64.iso                                                        " \
		"o  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop            ubuntu          ubuntu-24.04.1-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-desktop-amd64.iso                                                         " \
		"-  ubuntu-desktop-24.10        Ubuntu%2024.10%20Desktop            ubuntu          ubuntu-24.10-desktop-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-desktop-amd64.iso                                                      " \
		"x  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop            ubuntu          ubuntu-24.04-beta-desktop-amd64.iso         casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-beta-desktop-amd64.iso                                                    " \
		"o  ubuntu-desktop-oracular     Ubuntu%20oracular%20Desktop         ubuntu          oracular-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/oracular-desktop-amd64.iso                                                        " \
		"x  ubuntu-legacy-23.04         Ubuntu%2023.04%20Legacy%20Desktop   ubuntu          ubuntu-23.04-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_old.cfg     linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/lunar/release/ubuntu-23.04[0-9.]*-desktop-legacy-amd64.iso                                  " \
		"x  ubuntu-legacy-23.10         Ubuntu%2023.10%20Legacy%20Desktop   ubuntu          ubuntu-23.10-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/mantic/release/ubuntu-23.10[0-9.]*-desktop-legacy-amd64.iso                                 " \
		"m  menu-entry                  -                                   -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

# --- live media live mode ----------------------------------------------------
	declare -r -a DATA_LIST_LIVE=(                                                                                                                                                                                                                                                                                                                                                                                                                                                \
		"m  menu-entry                  Live%20media%20Live%20mode          -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
		"x  debian-live-10              Debian%2010%20Live                  debian          debian-live-10.13.0-amd64-lxde.iso          live                                    initrd.img-4.19.0-21-amd64  vmlinuz-4.19.0-21-amd64 preseed/-                               linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-10.[0-9.]*-amd64-lxde.iso      " \
		"o  debian-live-11              Debian%2011%20Live                  debian          debian-live-11.11.0-amd64-lxde.iso          live                                    initrd.img-5.10.0-30-amd64  vmlinuz-5.10.0-30-amd64 preseed/-                               linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso         " \
		"o  debian-live-12              Debian%2012%20Live                  debian          debian-live-12.7.0-amd64-lxde.iso           live                                    initrd.img                  vmlinuz                 preseed/-                               linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                  " \
		"o  debian-live-13              Debian%2013%20Live                  debian          debian-live-13.0.0-amd64-lxde.iso           live                                    initrd.img                  vmlinuz                 preseed/-                               linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  debian-live-testing         Debian%20testing%20Live             debian          debian-live-testing-amd64-lxde.iso          live                                    initrd.img                  vmlinuz                 preseed/-                               linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                       " \
		"x  ubuntu-desktop-14.04        Ubuntu%2014.04%20Desktop            ubuntu          ubuntu-14.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/-                               linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"x  ubuntu-desktop-16.04        Ubuntu%2016.04%20Desktop            ubuntu          ubuntu-16.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/-                               linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                               " \
		"x  ubuntu-desktop-18.04        Ubuntu%2018.04%20Desktop            ubuntu          ubuntu-18.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/-                               linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-desktop-amd64.iso                                                        " \
		"o  ubuntu-desktop-20.04        Ubuntu%2020.04%20Desktop            ubuntu          ubuntu-20.04.6-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/-                               linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                         " \
		"o  ubuntu-desktop-22.04        Ubuntu%2022.04%20Desktop            ubuntu          ubuntu-22.04.5-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 preseed/-                               linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                         " \
		"x  ubuntu-desktop-23.04        Ubuntu%2023.04%20Desktop            ubuntu          ubuntu-23.04-desktop-amd64.iso              casper                                  initrd                      vmlinuz                 preseed/-                               linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-desktop-amd64.iso                                                         " \
		"x  ubuntu-desktop-23.10        Ubuntu%2023.10%20Desktop            ubuntu          ubuntu-23.10.1-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/-                               linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-desktop-amd64.iso                                                        " \
		"o  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop            ubuntu          ubuntu-24.04.1-desktop-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/-                               linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-desktop-amd64.iso                                                         " \
		"-  ubuntu-desktop-24.10        Ubuntu%2024.10%20Desktop            ubuntu          ubuntu-24.10-desktop-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/-                               linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-desktop-amd64.iso                                                      " \
		"x  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop            ubuntu          ubuntu-24.04-beta-desktop-amd64.iso         casper                                  initrd                      vmlinuz                 nocloud/-                               linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-beta-desktop-amd64.iso                                                    " \
		"o  ubuntu-desktop-oracular     Ubuntu%20oracular%20Desktop         ubuntu          oracular-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 nocloud/-                               linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/oracular-desktop-amd64.iso                                                        " \
		"x  ubuntu-legacy-23.04         Ubuntu%2023.04%20Legacy%20Desktop   ubuntu          ubuntu-23.04-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 preseed/-                               linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/lunar/release/ubuntu-23.04[0-9.]*-desktop-legacy-amd64.iso                                  " \
		"x  ubuntu-legacy-23.10         Ubuntu%2023.10%20Legacy%20Desktop   ubuntu          ubuntu-23.10-desktop-legacy-amd64.iso       casper                                  initrd                      vmlinuz                 preseed/-                               linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/mantic/release/ubuntu-23.10[0-9.]*-desktop-legacy-amd64.iso                                 " \
		"m  menu-entry                  -                                   -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

# --- tool --------------------------------------------------------------------
	declare -r -a DATA_LIST_TOOL=(                                                                                                                                                                                                                                                                                                                                                                                                                                                \
		"m  menu-entry                  System%20tools                      -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
		"o  memtest86+                  Memtest86+                          memtest86+      mt86plus_7.00_64.grub.iso                   .                                       EFI/BOOT/memtest            boot/memtest            -                                       linux/memtest86+    -           -           xx:xx:xx    0   -   -   https://www.memtest.org/download/v7.00/mt86plus_7.00_64.grub.iso.zip                                                            " \
		"o  winpe-x64                   WinPE%20x64                         windows         WinPEx64.iso                                .                                       -                           -                       -                                       windows/WinPE       -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  winpe-x86                   WinPE%20x86                         windows         WinPEx86.iso                                .                                       -                           -                       -                                       windows/WinPE       -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  ati2020x64                  ATI2020x64                          windows         WinPE_ATI2020x64.iso                        .                                       -                           -                       -                                       windows/ati         -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"o  ati2020x86                  ATI2020x86                          windows         WinPE_ATI2020x86.iso                        .                                       -                           -                       -                                       windows/ati         -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
		"m  menu-entry                  -                                   -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

# --- custom live image -------------------------------------------------------
#	declare -r -a DATA_LIST_CSTM=(                                                                                                                                                                                                                                                                                                                                                                                                                                                \
#		"m  menu-entry                  Live%20media%20Live%20mode          -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
#		"x  live-debian-10-buster       Live%20Debian%2010                  debian          live-debian-10-buster-amd64-lxde.iso        live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
#		"o  live-debian-11-bullseye     Live%20Debian%2011                  debian          live-debian-11-bullseye-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
#		"o  live-debian-12-bookworm     Live%20Debian%2012                  debian          live-debian-12-bookworm-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
#		"o  live-debian-13-trixie       Live%20Debian%2013                  debian          live-debian-13-trixie-amd64-lxde.iso        live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
#		"o  live-debian-xx-unstable     Live%20Debian%20xx                  debian          live-debian-xx-unstable-amd64-lxde.iso      live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                   " \
#		"x  live-ubuntu-14.04-trusty    Live%20Ubuntu%2014.04               ubuntu          live-ubuntu-14.04-trusty                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"o  live-ubuntu-16.04-xenial    Live%20Ubuntu%2016.04               ubuntu          live-ubuntu-16.04-xenial                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"o  live-ubuntu-18.04-bionic    Live%20Ubuntu%2018.04               ubuntu          live-ubuntu-18.04-bionic                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"o  live-ubuntu-20.04-focal     Live%20Ubuntu%2020.04               ubuntu          live-ubuntu-20.04-focal                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"o  live-ubuntu-22.04-jammy     Live%20Ubuntu%2022.04               ubuntu          live-ubuntu-22.04-jammy                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"x  live-ubuntu-23.04-lunar     Live%20Ubuntu%2023.04               ubuntu          live-ubuntu-23.04-lunar                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"x  live-ubuntu-23.10-mantic    Live%20Ubuntu%2023.10               ubuntu          live-ubuntu-23.10-mantic                    live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"o  live-ubuntu-24.04-noble     Live%20Ubuntu%2024.04               ubuntu          live-ubuntu-24.04-noble                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"o  live-ubuntu-24.10-oracular  Live%20Ubuntu%2024.10               ubuntu          live-ubuntu-24.10-oracular                  live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#		"o  live-ubuntu-xx.xx-devel     Live%20Ubuntu%20xx.xx               ubuntu          live-ubuntu-xx.xx-devel                     live                                    initrd.gz                   vmlinuz                 preseed/-                               linux/ubuntu        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                " \
#	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

# --- system command ----------------------------------------------------------
#	declare -r -a DATA_LIST_SCMD=(                                                                                                                                                                                                                                                                                                                                                                                                                                                \
#		"m  menu-entry                  System%20command                    -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
#		"o  hdt                         Hardware%20info                     system          -                                           -                                       hdt.c32                     -                       -                                       -                   -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
#		"o  shutdown                    System%20shutdown                   system          -                                           -                                       poweroff.c32                -                       -                                       -                   -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
#		"o  restart                     System%20restart                    system          -                                           -                                       reboot.c32                  -                       -                                       -                   -           -           xx:xx:xx    0   -   -   -                                                                                                                               " \
#		"m  menu-entry                  -                                   -               -                                           -                                       -                           -                       -                                       -                   -           -           -           -   -   -   -                                                                                                                               " \
#	) #  0  1                           2                                   3               4                                           5                                       6                           7                       8                                       9                   10          11          12          13  14  15  16

	# --- target of creation --------------------------------------------------
#	declare -a    TGET_LIST=()
#	declare       TGET_INDX=""

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
	declare -r    SET_ENV_E="$(set -o | awk '$1=="errexit" {print $2;}')"
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
	if RET_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932 | cut -b -"${MAX_COLS}" | iconv -f CP932 -t UTF-8 2> /dev/null)"; then
		RET_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932 | cut -b -$((MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
	fi
	set -e
#	set +e
#	RET_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932 | cut -b -"${MAX_COLS}" | iconv -f CP932 -t UTF-8 2> /dev/null)"
#	RET_CD=$?
#	set -e
#	if [[ "${RET_CD}" -ne 0 ]]; then
#		set +e
#		RET_STR="$(echo -n "${INP_STR}" | iconv -f UTF-8 -t CP932 | cut -b -$((MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
#		set -e
#	fi
#	RET_STR+="$(echo -n -e "${TXT_RESET}")"
	# -------------------------------------------------------------------------
	echo -e "${RET_STR}${TXT_RESET}"
	IFS="${OLD_IFS}"
	# -------------------------------------------------------------------------
	if [[ "${SET_ENV_E}" = "on" ]]; then
		set -e
	else
		set +e
	fi
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
#	if [[ "${RET_CD}" -eq 6 ]] || [[ "${RET_CD}" -eq 18 ]] || [[ "${RET_CD}" -eq 22 ]] || [[ "${RET_CD}" -eq 28 ]] || [[ "${RET_CD}" -eq 35 ]] || [[ "${#WEBS_PAGE[@]}" -le 0 ]]; then
	if [[ "${RET_CD}" -ne 0 ]] || [[ "${#ARY_HED[@]}" -le 0 ]]; then
		ERR_MSG=$(echo "${ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -e 's/\r\n*/\n/g' -ze 's/\n//g')
		echo -e "${ERR_MSG} [${RET_CD}]: ${INP_URL}"
		return "${RET_CD}"
	fi
	WEB_SIZ=$(echo "${ARY_HED[@],,}" | sed -ne '/http\/.* 200/,/^$/ s/'$'\r''//gp' | sed -ne '/content-length:/ s/.*: //p')
	# shellcheck disable=SC2312
	WEB_TIM=$(TZ=UTC date -d "$(echo "${ARY_HED[@],,}" | sed -ne '/http\/.* 200/,/^$/ s/'$'\r''//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
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

# ----- create directory ------------------------------------------------------
function funcCreate_directory() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r -a DIRS_LIST=(                                                                            \
		"${DIRS_WORK}"                                                                                   \
		"${DIRS_BACK}"                                                                                   \
		"${DIRS_CONF}"/{_template,autoyast,kickstart,nocloud,preseed}                                    \
		"${DIRS_HTML}"                                                                                   \
		"${DIRS_IMGS}"                                                                                   \
		"${DIRS_ISOS}"                                                                                   \
		"${DIRS_ORIG}"                                                                                   \
		"${DIRS_RMAK}"                                                                                   \
		"${DIRS_TEMP}"                                                                                   \
		"${DIRS_TFTP}"/{boot/grub/{fonts,i386-pc,locale,x86_64-efi},load,menu-{bios,efi64}/pxelinux.cfg} \

	)
	declare -r -a LINK_LIST=(                                                                            \
		"${DIRS_CONF}                         ${DIRS_HTML}/"                                             \
		"${DIRS_IMGS}                         ${DIRS_HTML}/"                                             \
		"${DIRS_ISOS}                         ${DIRS_HTML}/"                                             \
		"${DIRS_RMAK}                         ${DIRS_HTML}/"                                             \
		"${DIRS_IMGS}                         ${DIRS_TFTP}/"                                             \
		"${DIRS_ISOS}                         ${DIRS_TFTP}/"                                             \
		"${DIRS_TFTP}/load                    ${DIRS_HTML}/"                                             \
		"${DIRS_TFTP}/load                    ${DIRS_TFTP}/menu-bios/"                                   \
		"${DIRS_TFTP}/load                    ${DIRS_TFTP}/menu-efi64/"                                  \
		"${DIRS_TFTP}/menu-bios/syslinux.cfg  ${DIRS_TFTP}/menu-bios/pxelinux.cfg/default"               \
		"${DIRS_TFTP}/menu-efi64/syslinux.cfg ${DIRS_TFTP}/menu-efi64/pxelinux.cfg/default"              \
		"${DIRS_IMGS}                         ${DIRS_TFTP}/menu-bios/"                                   \
		"${DIRS_IMGS}                         ${DIRS_TFTP}/menu-efi64/"                                  \
		"${DIRS_ISOS}                         ${DIRS_TFTP}/menu-bios/"                                   \
		"${DIRS_ISOS}                         ${DIRS_TFTP}/menu-efi64/"                                  \
	)
	declare -a    LINK_LINE=()
	declare       LINK_NAME=""
	declare       BACK_NAME=""
	declare       WORK_DIRS=""
#	declare       WORK_ATTR=""
	declare -i    I=0

	mkdir -p "${DIRS_LIST[@]}"

	for ((I=0; I<"${#LINK_LIST[@]}"; I++))
	do
		read -r -a LINK_LINE < <(echo "${LINK_LIST[I]}")
		mkdir -p "${LINK_LINE[1]%/*}"
		if [[ -z "${LINK_LINE[1]##*/}" ]]; then
			LINK_NAME="${LINK_LINE[1]%/}/${LINK_LINE[0]##*/}"
		else
			LINK_NAME="${LINK_LINE[1]}"
		fi
		if [[ -h "${LINK_NAME}" ]] || [[ -d "${LINK_NAME}/." ]]; then
			if [[ -h "${LINK_NAME}" ]]; then
				funcPrintf "symbolic link exist : ${LINK_NAME}"
			else
				funcPrintf "directory exist     : ${LINK_NAME}"
			fi
			continue
#			BACK_NAME="${DIRS_BACK}/${LINK_NAME}.${DATE_TIME}"
#			funcPrintf "directory move      : ${LINK_NAME} -> ${BACK_NAME}"
#			mkdir -p "${BACK_NAME%/*}"
#			mv "${LINK_NAME}" "${BACK_NAME}"
		fi
		funcPrintf "symbolic link create: ${LINK_LINE[0]} -> ${LINK_LINE[1]}"
		if [[ "${LINK_LINE[1]}" =~ ${DIRS_WORK} ]]; then
			ln -sr "${LINK_LINE[0]}" "${LINK_LINE[1]}"
		else
			ln -s "${LINK_LINE[0]}" "${LINK_LINE[1]}"
		fi
	done
	# -------------------------------------------------------------------------
	if [[ -h "${HTML_ROOT}" ]]; then
		funcPrintf "symbolic link exist : ${HTML_ROOT}"
	else
		if [[ -d "${HTML_ROOT}/." ]]; then
			BACK_NAME="${HTML_ROOT}.back.${DATE_TIME}"
			funcPrintf "directory move      : ${HTML_ROOT} -> ${BACK_NAME}"
			mv "${HTML_ROOT}" "${BACK_NAME}"
		fi
		funcPrintf "symbolic link create: ${DIRS_HTML} -> ${HTML_ROOT}"
		ln -s "${DIRS_HTML}" "${HTML_ROOT}"
	fi
	if [[ -h "${TFTP_ROOT}" ]]; then
		funcPrintf "symbolic link exist : ${TFTP_ROOT}"
	else
		if [[ -d "${TFTP_ROOT}/." ]]; then
			BACK_NAME="${TFTP_ROOT}.back.${DATE_TIME}"
			funcPrintf "directory move      : ${TFTP_ROOT} -> ${BACK_NAME}"
			mv "${TFTP_ROOT}" "${BACK_NAME}"
		fi
		funcPrintf "symbolic link create: ${DIRS_TFTP} -> ${TFTP_ROOT}"
		ln -s "${DIRS_TFTP}" "${TFTP_ROOT}"
	fi
#	WORK_DIRS="${DIRS_TFTP}"
#	while [[ -n "${WORK_DIRS:-}" ]]
#	do
#		WORK_ATTR="$(stat --format=%a "${WORK_DIRS:-}")"
#		if [[ "${WORK_ATTR:-}" != "755" ]]; then
#			funcPrintf "the attribute of '${WORK_DIRS}' is '${WORK_ATTR}', so access via tftp is not possible"
#			funcPrintf "when running tftp, set the directory attribute to '755'"
#			funcPrintf "chmod go=rx ${WORK_DIRS}"
#			exit 1
#		fi
#		WORK_DIRS="${WORK_DIRS%/*}"
#	done
}

# ----- create link -----------------------------------------------------------
function funcCreate_link() {
	declare -r -a DATA_LIST=(  \
		"${DATA_LIST_MINI[@]}" \
		"${DATA_LIST_NET[@]}"  \
		"${DATA_LIST_DVD[@]}"  \
		"${DATA_LIST_INST[@]}" \
		"${DATA_LIST_LIVE[@]}" \
		"${DATA_LIST_TOOL[@]}" \
	)
	declare -a    DATA_LINE=()
	declare       DIRS_NAME=""
	declare       FILE_NAME=""
	declare -i    I=0

	if [[ -n "${CONF_LINK}" ]] && [[ -d "${CONF_LINK}/." ]]; then
		for FILE_NAME in \
			"${CONF_KICK}" \
			"${CONF_CLUD}" \
			"${CONF_SEDD}" \
			"${CONF_SEDU}" \
			"${CONF_YAST}"
		do
			mkdir -p "${CONF_DIRS}"
			if [[ -f "${FILE_NAME}" ]]; then
				funcPrintf "         file exist : ${FILE_NAME##*/}"
			elif [[ -L "${FILE_NAME}" ]]; then
				funcPrintf "symbolic link exist : ${FILE_NAME##*/}"
			else
				funcPrintf "symbolic link create: ${CONF_LINK}/${FILE_NAME##*/} -> ${CONF_DIRS/${PWD}\//}"
				ln -s "${CONF_LINK}/${FILE_NAME##*/}" "${CONF_DIRS}"
			fi
		done
	fi

	for ((I=0; I<"${#DATA_LIST[@]}"; I++))
	do
		read -r -a DATA_LINE < <(echo "${DATA_LIST[I]}")
#		if [[ "${DATA_LINE[0]}" != "o" ]] || [[ ! -f "${HGFS_DIRS}/${DATA_LINE[9]}/${DATA_LINE[4]}" ]]; then
		if [[ "${DATA_LINE[0]}" != "o" ]]; then
			continue
		fi
		mkdir -p "${DIRS_ISOS}"
		if [[ -L "${DIRS_ISOS}/${DATA_LINE[4]}" ]]; then
			funcPrintf "symbolic link exist : ${DIRS_ISOS/${PWD}\//}/${DATA_LINE[4]}"
		else
			funcPrintf "symbolic link create: ${HGFS_DIRS}/${DATA_LINE[9]}/${DATA_LINE[4]} -> ${DIRS_ISOS/${PWD}\//}"
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
	cat <<- '_EOT_SH_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_NAME}"
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

# ----- create late command ---------------------------------------------------
function funcCreate_late_command() {
	declare -r    DIRS_NAME="${DIRS_CONF}/script"
	declare -r    FILE_NAME="${DIRS_NAME}/late_command.sh"
	# -------------------------------------------------------------------------
	funcPrintf "create filet: ${FILE_NAME/${PWD}\/}"
	mkdir -p "${DIRS_NAME}"
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_NAME}"
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
		 	export LANG=C
		
		 	#--------------------------------------------------------------------------
		 	readonly PROG_PATH="$0"
		 	readonly PROG_PRAM="$*"
		 	readonly PROG_NAME="${0##*/}"
		 	readonly PROG_DIRS="${0%/*}"
		 	readonly TGET_DIRS="/target"
		 	readonly ORIG_DIRS="${PROG_DIRS}/orig"
		 	readonly CRNT_DIRS="${PROG_DIRS}/crnt"
		#	readonly LOGS_NAME="${PROG_DIRS}/${PROG_NAME%.*}.log"
		 	readonly COMD_PARM="${PROG_DIRS}/${PROG_NAME%.*}.prm";
		 	DIST_NAME="$(uname -v | sed -ne 's/.*\(debian\|ubuntu\).*/\1/ip' | tr '[:upper:]' '[:lower:]')"
		 	readonly DIST_NAME
		 	if [ -f "${COMD_PARM}" ]; then
		 		COMD_LINE="$(cat "${COMD_PARM}")"
		 	else
		 		COMD_LINE="$(cat /proc/cmdline)"
		 	fi
		 	readonly COMD_LINE
		 	SEED_FILE=""
		 	for LINE in ${COMD_LINE};
		 	do
		 		case "${LINE}" in
		 			iso-url=*.iso  | url=*.iso )                                     ;;
		 			preseed/file=* | file=*    ) SEED_FILE="${PROG_DIRS}/preseed.cfg";;
		 			preseed/url=*  | url=*     ) SEED_FILE="${PROG_DIRS}/preseed.cfg";;
		 			ds=nocloud*                ) SEED_FILE="${PROG_DIRS}/user-data"  ;;
		 			*                          )                                     ;;
		 		esac
		 	done
		 	readonly SEED_FILE
		
		 	#--------------------------------------------------------------------------
		 	echo "${PROG_NAME}: === Start ==="
		 	echo "${PROG_NAME}: PROG_PATH=${PROG_PATH}"
		 	echo "${PROG_NAME}: PROG_PRAM=${PROG_PRAM}"
		 	echo "${PROG_NAME}: PROG_NAME=${PROG_NAME}"
		 	echo "${PROG_NAME}: PROG_DIRS=${PROG_DIRS}"
		 	echo "${PROG_NAME}: SEED_FILE=${SEED_FILE}"
		 	echo "${PROG_NAME}: TGET_DIRS=${TGET_DIRS}"
		 	echo "${PROG_NAME}: ORIG_DIRS=${ORIG_DIRS}"
		 	echo "${PROG_NAME}: CRNT_DIRS=${CRNT_DIRS}"
		 	echo "${PROG_NAME}: COMD_PARM=${COMD_PARM}"
		 	echo "${PROG_NAME}: DIST_NAME=${DIST_NAME}"
		 	echo "${PROG_NAME}: COMD_LINE=${COMD_LINE}"
		
		 	#--- parameter  -----------------------------------------------------------
		 	NTP_ADDR="ntp.nict.jp"
		 	IP6_LHST="::1"
		 	IP4_LHST="127.0.0.1"
		 	IP4_DUMY="127.0.1.1"
		 	OLD_FQDN="$(cat /etc/hostname)"
		 	OLD_HOST="${OLD_FQDN%.*}"
		 	OLD_WGRP="${OLD_FQDN#*.}"
		 	NIC_BIT4=""
		 	NIC_MADR=""
		 	NMN_FLAG=""					# nm_config, ifupdown, loopback
		 	FIX_IPV4=""
		 	NIC_IPV4=""
		 	NIC_GATE=""
		 	NIC_MASK=""
		 	NIC_FQDN=""
		 	NIC_NAME=""
		 	NIC_DNS4=""
		 	NIC_HOST=""
		 	NIC_WGRP=""
		
		### common ####################################################################
		
		# --- private ip address ------------------------------------------------------
		# class | ipv4 address range            | subnet mask range
		#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
		#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
		#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
		
		# --- ipv4 netmask conversion -------------------------------------------------
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
		#	INP_ADDR="$1"
		#	echo "${INP_ADDR}" | \
		#	    awk -F '.' '{
		#	        split($0, OCTETS)
		#	        for (I in OCTETS) {
		#	            MASK += 8 - log(2^8 - OCTETS[I])/log(2)
		#	        }
		#	        print MASK
		#	    }'
		 	INP_ADDR="$1"
		
		 	OLD_IFS=${IFS}
		 	IFS='.'
		 	set -f
		 	# shellcheck disable=SC2086
		 	set -- ${INP_ADDR}
		 	set +f
		 	OCTETS1="${1}"
		 	OCTETS2="${2}"
		 	OCTETS3="${3}"
		 	OCTETS4="${4}"
		 	IFS=${OLD_IFS}
		
		 	MASK=0
		 	for OCTETS in "${OCTETS1}" "${OCTETS2}" "${OCTETS3}" "${OCTETS4}"
		 	do
		 		case "${OCTETS}" in
		 			  0) MASK=$((MASK+0));;
		 			128) MASK=$((MASK+1));;
		 			192) MASK=$((MASK+2));;
		 			224) MASK=$((MASK+3));;
		 			240) MASK=$((MASK+4));;
		 			248) MASK=$((MASK+5));;
		 			252) MASK=$((MASK+6));;
		 			254) MASK=$((MASK+7));;
		 			255) MASK=$((MASK+8));;
		 			*  )                 ;;
		 		esac
		 	done
		 	printf '%d' "${MASK}"
		}
		
		# --- service status ----------------------------------------------------------
		funcServiceStatus() {
		 	SRVC_STAT="undefined"
		 	case "$1" in
		 		is-enabled )
		 			SRVC_STAT="$(systemctl is-enabled "$2" 2> /dev/null || true)"
		 			if [ -z "${SRVC_STAT}" ]; then
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
		 				*               ) ;;
		 			esac
		 			;;
		 		is-active  )
		 			SRVC_STAT="$(systemctl is-active "$2" 2> /dev/null || true)"
		 			if [ -z "${SRVC_STAT}" ]; then
		 				SRVC_STAT="not-found"
		 			fi
		 			;;
		 		*          ) ;;
		 	esac
		 	echo "${SRVC_STAT}"
		}
		
		### subroutine ################################################################
		# --- blacklist ---------------------------------------------------------------
		# run on target
		funcSetupBlacklist() {
		 	FUNC_NAME="funcSetupBlacklist"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# -------------------------------------------------------------------------
		 	FILE_DIRS="/etc/modprobe.d"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
		 	fi
		 	if [ ! -d "${FILE_DIRS}/." ]; then
		 		echo "${PROG_NAME}: mkdir ${FILE_DIRS}"
		 		mkdir -p "${FILE_DIRS}"
		 	fi
		 	FILE_NAME="${FILE_DIRS}/blacklist-floppy.conf"
		 	# shellcheck disable=SC2312
		 	if [ -n "$(lsmod | sed -ne '/floppy/p')" ]; then
		#		echo "${PROG_NAME}: rmmod floppy"
		#		rmmod floppy || true
		 		echo "${PROG_NAME}: create file ${FILE_DIRS}"
		 		echo 'blacklist floppy' > "${FILE_NAME}"
		 		#--- debug print ------------------------------------------------------
		 		echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 		cat "${FILE_NAME}"
		 		# shellcheck disable=SC2312
		 		if [ -n "$(command -v dpkg-reconfigure 2> /dev/null)" ]; then
		 			dpkg-reconfigure initramfs-tools
		 		fi
		 	fi
		}
		
		# --- packages ----------------------------------------------------------------
		# run on target
		funcInstallPackages() {
		 	FUNC_NAME="funcInstallPackages"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	#--------------------------------------------------------------------------
		 	FILE_DIRS="/etc/apt"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_DIRS}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -d "${FILE_DIRS}/." ]; then
		 		echo "${PROG_NAME}: directory does not exist ${FILE_DIRS}"
		 		return
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	if [ ! -d "${BACK_DIRS}/." ]; then
		 		mkdir -p "${BACK_DIRS}"
		 	fi
		 	find "${FILE_DIRS}" -name '*.list' -type f | \
		 	while read -r FILE_NAME
		 	do
		 		echo "${PROG_NAME}: ${FILE_NAME} moved"
		 		cp -a "${FILE_NAME}" "${BACK_DIRS}"
		 	done
		 	FILE_NAME="${FILE_DIRS}/sources.list"
		 	sed -i "${FILE_NAME}"                     \
		 	    -e '/^[ \t]*deb[ \t]\+cdrom/ s/^/#/g'
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		 	#--------------------------------------------------------------------------
		 	if [ ! -f "${SEED_FILE}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${SEED_FILE}"
		 		return
		 	fi
		 	#--------------------------------------------------------------------------
		 	LIST_TASK="$(sed -ne '/^[ \t]*tasksel[ \t]\+tasksel\/first[ \t]\+/,/[^\\]$/p' "${SEED_FILE}" | \
		 	             sed -e  '/^[ \t]*tasksel[ \t]\+/d'                                                \
		 	                 -e  's/\\//g'                                                               | \
		 	             sed -e  's/\r\n*/\n/g'                                                            \
		 	                 -e  ':l; N; s/\n/ /; b l;'                                                  | \
		 	             sed -e  's/[ \t]\+/ /g')"
		 	LIST_PACK="$(sed -ne '/^[ \t]*d-i[ \t]\+pkgsel\/include[ \t]\+/,/[^\\]$/p'    "${SEED_FILE}" | \
		 	             sed -e  '/^[ \t]*d-i[ \t]\+/d'                                                    \
		 	                 -e  's/\\//g'                                                               | \
		 	             sed -e  's/\r\n*/\n/g'                                                            \
		 	                 -e  ':l; N; s/\n/ /; b l;'                                                  | \
		 	             sed -e  's/[ \t]\+/ /g')"
		 	echo "${PROG_NAME}: LIST_TASK=${LIST_TASK:-}"
		 	echo "${PROG_NAME}: LIST_PACK=${LIST_PACK:-}"
		 	#--------------------------------------------------------------------------
		 	LIST_DPKG=""
		 	if [ -n "${LIST_PACK:-}" ]; then
		 		# shellcheck disable=SC2086
		 		LIST_DPKG="$(dpkg-query --show --showformat='${Status} ${Package}\n' ${LIST_PACK:-} 2>&1 | \
		 		             sed -ne '/install ok installed:/! s/^.*[ \t]\([[:graph:]]\)/\1/gp'          | \
		 		             sed -e  's/\r\n*/\n/g'                                                        \
		 		                 -e  ':l; N; s/\n/ /; b l;'                                              | \
		 		             sed -e  's/[ \t]\+/ /g')"
		 	fi
		 	#--------------------------------------------------------------------------
		 	echo "${PROG_NAME}: Run the installation"
		 	echo "${PROG_NAME}: LIST_DPKG=${LIST_DPKG:-}"
		 	echo "${PROG_NAME}: LIST_TASK=${LIST_TASK:-}"
		 	#--------------------------------------------------------------------------
		 	apt-get -qq    update
		 	apt-get -qq -y upgrade
		 	apt-get -qq -y dist-upgrade
		 	if [ -n "${LIST_DPKG:-}" ]; then
		 		# shellcheck disable=SC2086
		 		apt-get -qq -y install ${LIST_DPKG}
		 	fi
		 	# shellcheck disable=SC2312
		 	if [ -n "${LIST_TASK:-}" ] && [ -n "$(command -v tasksel 2> /dev/null)" ]; then
		 		# shellcheck disable=SC2086
		 		tasksel install ${LIST_TASK}
		 	fi
		 	echo "${PROG_NAME}: Installation completed"
		}
		
		# --- network get parameter ---------------------------------------------------
		# run on target
		funcGetNetwork_parameter_sub() {
		 	LIST="${1}"
		 	for LINE in ${LIST}
		 	do
		 		case "${LINE}" in
		 			netcfg/target_network_config=* ) NMN_FLAG="${LINE#netcfg/target_network_config=}";;
		 			netcfg/choose_interface=*      ) NIC_NAME="${LINE#netcfg/choose_interface=}"     ;;
		 			netcfg/disable_dhcp=*          ) FIX_IPV4="${LINE#netcfg/disable_dhcp=}"         ;;
		 			netcfg/disable_autoconfig=*    ) FIX_IPV4="${LINE#netcfg/disable_autoconfig=}"   ;;
		 			netcfg/get_ipaddress=*         ) NIC_IPV4="${LINE#netcfg/get_ipaddress=}"        ;;
		 			netcfg/get_netmask=*           ) NIC_MASK="${LINE#netcfg/get_netmask=}"          ;;
		 			netcfg/get_gateway=*           ) NIC_GATE="${LINE#netcfg/get_gateway=}"          ;;
		 			netcfg/get_nameservers=*       ) NIC_DNS4="${LINE#netcfg/get_nameservers=}"      ;;
		 			netcfg/get_hostname=*          ) NIC_FQDN="${LINE#netcfg/get_hostname=}"         ;;
		 			netcfg/get_domain=*            ) NIC_WGRP="${LINE#netcfg/get_domain=}"           ;;
		 			interface=*                    ) NIC_NAME="${LINE#interface=}"                   ;;
		 			hostname=*                     ) NIC_FQDN="${LINE#hostname=}"                    ;;
		 			domain=*                       ) NIC_WGRP="${LINE#domain=}"                      ;;
		 			ip=dhcp | ip4=dhcp | ipv4=dhcp ) FIX_IPV4="false"; break                         ;;
		 			ip=* | ip4=* | ipv4=*          ) FIX_IPV4="true"
		 			                                 OLD_IFS=${IFS}
		 			                                 IFS=':,'
		 			                                 set -f
		 			                                 # shellcheck disable=SC2086
		 			                                 set -- ${LINE#ip*=}
		 			                                 set +f
		 			                                 NIC_IPV4="${1}"
		 			                                 NIC_GATE="${3}"
		 			                                 NIC_MASK="${4}"
		 			                                 NIC_FQDN="${5}"
		 			                                 NIC_NAME="${6}"
		 			                                 NIC_DNS4="${8}"
		 			                                 IFS=${OLD_IFS}
		 			                                 ;;
		 			*)  ;;
		 		esac
		 	done
		}
		
		# --- network get parameter ---------------------------------------------------
		# run on target
		funcGetNetwork_parameter() {
		 	FUNC_NAME="funcGetNetwork_parameter"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	#--- nic parameter --------------------------------------------------------
		 	IP4_INFO="$(ip -4 -oneline address show primary | sed -ne '/^2:[ \t]\+/p')"
		 	LNK_INFO="$(ip -4 -oneline link show | sed -ne '/^2:[ \t]\+/p')"
		 	NIC_NAME="$(echo "${IP4_INFO}" | sed -ne 's/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\)[ \t]\+inet.*$/\1/p')"
		 	NIC_MADR="$(echo "${LNK_INFO}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
		 	CON_MADR="$(echo "${NIC_MADR}" | sed -ne 's/://gp')"
		 	NIC_IPV4="$(echo "${IP4_INFO}" | sed -ne 's%^.*inet[ \t]\+\([0-9.]\+\)/*\([0-9]*\)[ \t]\+.*$%\1%p')"
		 	NIC_BIT4="$(echo "${IP4_INFO}" | sed -ne 's%^.*inet[ \t]\+\([0-9.]\+\)/*\([0-9]*\)[ \t]\+.*$%\2%p')"
		 	NIC_BIT4="$([ -n "${NIC_BIT4}" ] && echo "${NIC_BIT4}" || echo 0)"
		 	NIC_MASK="$(funcIPv4GetNetmask "${NIC_BIT4}")"
		 	FIX_IPV4="$([ -n "${NIC_BIT4}" ] && echo "true" || echo "false")"
		 	NIC_DNS4="$(sed -ne '/nameserver/ s/^.*[ \t]\+\([0-9.:]\+\)[ \t]*/\1/p' /etc/resolv.conf | head -n 1)"
		 	NIC_GATE="$(ip -4 -oneline route list dev "${NIC_NAME}" default | sed -ne 's/^.*via[ \t]\+\([0-9.]\+\)[ \t]\+.*/\1/p')"
		 	NIC_FQDN="$(hostname -f)"
		 	NIC_HOST="${NIC_FQDN%.*}"
		 	NIC_WGRP="${NIC_FQDN##*.}"
		 	NMN_FLAG=""
		 	#--- preseed parameter ----------------------------------------------------
		 	if [ -f "${SEED_FILE}" ]; then
		 		# shellcheck disable=SC2312
		 		funcGetNetwork_parameter_sub "$(cat "${SEED_FILE}")"
		 		if [ -n "${NIC_WGRP}" ]; then
		 			NIC_FQDN="${NIC_HOST}.${NIC_WGRP}"
		 		fi
		 	fi
		 	#--- /proc/cmdline parameter ----------------------------------------------
		 	funcGetNetwork_parameter_sub "${COMD_LINE}"
		 	#--- hostname -------------------------------------------------------------
		 	if [ -z "${NIC_HOST}" ] && [ -n "${NIC_FQDN%.*}" ]; then
		 		NIC_HOST="${NIC_FQDN%.*}"
		 	fi
		 	if [ -z "${NIC_WGRP}" ] && [ -n "${NIC_FQDN##*.}" ]; then
		 		NIC_WGRP="${NIC_FQDN##*.}"
		 	fi
		 	if [ -z "${NIC_WGRP}" ]; then
		 		NIC_WGRP="$(sed -ne 's/^search[ \t]\+\([[:alnum:]]\+\)[ \t]*/\1/p' /etc/resolv.conf)"
		 	fi
		 	#--- network parameter ----------------------------------------------------
		 	if [ -n "${NIC_IPV4#*/}" ] && [ "${NIC_IPV4#*/}" != "${NIC_IPV4}" ]; then
		 		FIX_IPV4="true"
		 		NIC_BIT4="${NIC_IPV4#*/}"
		 		NIC_IPV4="${NIC_IPV4%/*}"
		 		NIC_MASK="$(funcIPv4GetNetmask "${NIC_BIT4}")"
		 	else
		 		NIC_BIT4="$(funcIPv4GetNetCIDR "${NIC_MASK}")"
		 	fi
		#	#--- nic parameter --------------------------------------------------------
		#	if [ -z "${NIC_NAME}" ] || [ "${NIC_NAME}" = "auto" ]; then
		#		IP4_INFO="$(ip -4 -oneline address show primary | sed -ne '/^2:[ \t]\+/p')"
		#		NIC_NAME="$(echo "${IP4_INFO}" | sed -ne 's/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\)[ \t]\+inet.*$/\1/p')"
		#	fi
		#	IP4_INFO="$(ip -4 -oneline link show "${NIC_NAME}" 2> /dev/null)"
		#	NIC_MADR="$(echo "${IP4_INFO}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
		#	CON_MADR="$(echo "${NIC_MADR}" | sed -ne 's/://gp')"
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: FIX_IPV4=${FIX_IPV4}"
		 	echo "${PROG_NAME}: NIC_NAME=${NIC_NAME}"
		 	echo "${PROG_NAME}: NIC_MADR=${NIC_MADR}"
		 	echo "${PROG_NAME}: CON_MADR=${CON_MADR}"
		 	echo "${PROG_NAME}: NIC_IPV4=${NIC_IPV4}"
		 	echo "${PROG_NAME}: NIC_MASK=${NIC_MASK}"
		 	echo "${PROG_NAME}: NIC_BIT4=${NIC_BIT4}"
		 	echo "${PROG_NAME}: NIC_DNS4=${NIC_DNS4}"
		 	echo "${PROG_NAME}: NIC_GATE=${NIC_GATE}"
		 	echo "${PROG_NAME}: NIC_FQDN=${NIC_FQDN}"
		 	echo "${PROG_NAME}: NIC_HOST=${NIC_HOST}"
		 	echo "${PROG_NAME}: NIC_WGRP=${NIC_WGRP}"
		 	echo "${PROG_NAME}: IP6_LHST=${IP6_LHST}"
		 	echo "${PROG_NAME}: IP4_LHST=${IP4_LHST}"
		 	echo "${PROG_NAME}: IP4_DUMY=${IP4_DUMY}"
		 	echo "${PROG_NAME}: NTP_ADDR=${NTP_ADDR}"
		 	echo "${PROG_NAME}: OLD_FQDN=${OLD_FQDN}"
		 	echo "${PROG_NAME}: OLD_HOST=${OLD_HOST}"
		 	echo "${PROG_NAME}: OLD_WGRP=${OLD_WGRP}"
		 	echo "${PROG_NAME}: NMN_FLAG=${NMN_FLAG}"
		}
		
		# --- network setup hostname --------------------------------------------------
		# run on target
		funcSetupNetwork_hostname() {
		 	FUNC_NAME="funcSetupNetwork_hostname"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# --- hostname ------------------------------------------------------------
		 	FILE_NAME="/etc/hostname"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	echo "${PROG_NAME}: ${FILE_NAME}"
		 	if [ ! -d "${BACK_DIRS}/." ]; then
		 		mkdir -p "${BACK_DIRS}"
		 	fi
		 	cp -a "${FILE_NAME}" "${BACK_DIRS}"
		 	echo "${NIC_FQDN}" > "${FILE_NAME}"
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		}
		
		# --- network setup hosts -----------------------------------------------------
		# run on target
		funcSetupNetwork_hosts() {
		 	FUNC_NAME="funcSetupNetwork_hosts"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# --- hosts ---------------------------------------------------------------
		 	FILE_NAME="/etc/hosts"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	echo "${PROG_NAME}: ${FILE_NAME}"
		 	if [ ! -d "${BACK_DIRS}/." ]; then
		 		mkdir -p "${BACK_DIRS}"
		 	fi
		 	cp -a "${FILE_NAME}" "${BACK_DIRS}"
		 	sed -i "${FILE_NAME}"                                          \
		 	    -e "/^${IP4_DUMY}/d"                                       \
		 	    -e "/^${NIC_IPV4}/d"                                       \
		 	    -e 's/^\([0-9.]\+\)[ \t]\+/\1\t/g'                         \
		 	    -e 's/^\([0-9a-zA-Z:]\+\)[ \t]\+/\1\t\t/g'                 \
		 	    -e "/^${IP4_LHST}/a ${NIC_IPV4}\t${NIC_FQDN} ${NIC_HOST}"  \
		 	    -e "s/${OLD_HOST}/${NIC_HOST}/g"                           \
		 	    -e "s/${OLD_FQDN}/${NIC_FQDN}/g"
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		}
		
		# --- network setup firewalld -------------------------------------------------
		# run on target
		funcSetupNetwork_firewalld() {
		 	FUNC_NAME="funcSetupNetwork_firewalld"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# --- firewalld -----------------------------------------------------------
		 	SRVC_NAME="firewalld.service"
		 	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	FILE_NAME="/etc/firewalld/firewalld.conf"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	ULIB_NAME="/usr/lib/firewalld/zones/home.xml"
		 	FILE_NAME="/etc/firewalld/zones/home.xml"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		ULIB_NAME="${TGET_DIRS}${ULIB_NAME}"
		 	fi
		 	echo "${PROG_NAME}: ${FILE_NAME}"
		 	sed -e '/<\/zone>/i \  <interface name="'"${NIC_NAME}"'"\/>' \
		 	    "${ULIB_NAME}"                                           \
		 	>   "${FILE_NAME}"
		 	# shellcheck disable=SC2312
		 	if [ -z "$(sed -ne '/^[ \t]*<service name="samba"\/>[ \t]*$/p' "${FILE_NAME}")" ]; then
		 		sed -i "${FILE_NAME}"                                \
		 		    -e '/samba-client/i \  <service name="samba"\/>'
		 	fi
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		 	#--- systemctl ------------------------------------------------------------
		 	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
		 	if [ "${SYSD_STAT}" = "enabled" ]; then
		 		echo "${PROG_NAME}: ${SRVC_NAME} restarted"
		 		systemctl restart "${SRVC_NAME}"
		 	fi
		 	echo "${PROG_NAME}: ${SRVC_NAME} completed"
		}
		
		# --- network setup avahi -----------------------------------------------------
		# run on target
		funcSetupNetwork_avahi() {
		 	FUNC_NAME="funcSetupNetwork_avahi"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# --- avahi ---------------------------------------------------------------
		 	SRVC_NAME="avahi-daemon.service"
		 	SOCK_NAME="avahi-daemon.socket"
		 	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	# --- systemctl -----------------------------------------------------------
		 	echo "${PROG_NAME}: daemon-reload"
		 	systemctl daemon-reload
		 	for SYSD_NAME in "${SRVC_NAME}" "${SOCK_NAME}"
		 	do
		 		SYSD_STAT="$(funcServiceStatus "is-enabled" "${SYSD_NAME}")"
		 		if [ "${SYSD_STAT}" != "enabled" ]; then
		 			continue
		 		fi
		 		echo "${PROG_NAME}: ${SRVC_NAME} stop"
		 		systemctl stop "${SYSD_NAME}"
		 		echo "${PROG_NAME}: ${SRVC_NAME} masked"
		 		systemctl mask "${SYSD_NAME}"
		#		echo "${PROG_NAME}: ${SRVC_NAME} disabled"
		#		systemctl disable --now "${SYSD_NAME}"
		 	done
		 	echo "${PROG_NAME}: ${SRVC_NAME} completed"
		}
		
		# --- network setup resolv.conf -----------------------------------------------
		# run on target
		funcSetupNetwork_resolv() {
		 	FUNC_NAME="funcSetupNetwork_resolv"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	#--- systemd-resolved -----------------------------------------------------
		 	SRVC_NAME="systemd-resolved.service"
		 	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	# --- systemctl -----------------------------------------------------------
		 	echo "${PROG_NAME}: daemon-reload"
		 	systemctl daemon-reload
		 	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
		 	if [ "${SYSD_STAT}" = "enabled" ]; then
		 		echo "${PROG_NAME}: ${SRVC_NAME} stop"
		 		systemctl stop "${SRVC_NAME}"
		 		echo "${PROG_NAME}: ${SRVC_NAME} masked"
		 		systemctl mask "${SRVC_NAME}"
		#		echo "${PROG_NAME}: ${SRVC_NAME} disabled"
		#		systemctl disable --now "${SRVC_NAME}"
		 	fi
		 	# --- resolv.conf ---------------------------------------------------------
		 	FILE_NAME="/etc/resolv.conf"
		 	CLUD_DIRS="/etc/cloud/cloud.cfg.d"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		CLUD_DIRS="${TGET_DIRS}${CLUD_DIRS}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	echo "${PROG_NAME}: ${FILE_NAME}"
		 	if [ -f "${FILE_NAME}" ]; then
		 		if [ ! -d "${BACK_DIRS}/." ]; then
		 			mkdir -p "${BACK_DIRS}"
		 		fi
		 		cp -a "${FILE_NAME}" "${BACK_DIRS}"
		 	fi
		 	# --- create file ---------------------------------------------------------
		 	CONF_FILE="${FILE_NAME}.manually-configured"
		 	# shellcheck disable=SC2312
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CONF_FILE}"
		 		# Generated by user script
		 		search ${NIC_WGRP}
		 		nameserver ${IP6_LHST}
		 		nameserver ${IP4_LHST}
		 		nameserver ${NIC_DNS4}
		_EOT_
		 	rm -f "${FILE_NAME}"
		 	cp -a "${CONF_FILE}" "${FILE_NAME}"
		#	ln -s "${CONF_FILE}" "${FILE_NAME}"
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ls -l ${CONF_FILE} ${FILE_NAME} ---"
		 	ls -l "${CONF_FILE}" "${FILE_NAME}"
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		 	#--- 99-disable-network-config.cfg ----------------------------------------
		 	if [ -d "${CLUD_DIRS}/." ] && [ -d /etc/NetworkManager/ ]; then
		 		CONF_FILE="${CLUD_DIRS}/99-disable-network-config.cfg"
		 		# shellcheck disable=SC2312
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CONF_FILE}"
		 			network: {config: disabled}
		_EOT_
		 		#--- debug print ------------------------------------------------------
		 		echo "${PROG_NAME}: --- ${CONF_FILE} ---"
		 		cat "${CONF_FILE}"
		 	fi
		 	echo "${PROG_NAME}: ${FILE_NAME##*/} completed"
		}
		
		# --- network setup dnsmasq ---------------------------------------------------
		# run on target
		funcSetupNetwork_dnsmasq() {
		 	FUNC_NAME="funcSetupNetwork_dnsmasq"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# --- dnsmasq -------------------------------------------------------------
		 	SRVC_NAME="dnsmasq.service"
		 	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	echo "${PROG_NAME}: ${FILE_NAME}"
		 	if [ ! -d "${BACK_DIRS}/." ]; then
		 		mkdir -p "${BACK_DIRS}"
		 	fi
		 	cp -a "${FILE_NAME}" "${BACK_DIRS}"
		 	# --- dnsmasq.service -----------------------------------------------------
		 	sed -i "${FILE_NAME}"                           \
		 	    -e '/\[Unit\]/,/\[.\+\]/                 {' \
		 	    -e '/^Requires=/                         {' \
		 	    -e 's/^/#/g'                                \
		 	    -e 'a Requires=network-online.target'       \
		 	    -e '                                     }' \
		 	    -e '/^After=/                            {' \
		 	    -e 's/^/#/g'                                \
		 	    -e 'a After=network-online.target'          \
		 	    -e '                                     }' \
		 	    -e '                                     }' \
		 	    -e '/^ExecStartPost=.*-resolvconf$/ s/^/#/' \
		 	    -e '/^ExecStop=.*-resolvconf$/      s/^/#/'
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		 	#--- none-dns.conf --------------------------------------------------------
		 	FILE_DIRS="/etc/NetworkManager/conf.d"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
		 	fi
		 	if [ -d "${FILE_DIRS}/." ]; then
		 		FILE_NAME="${FILE_DIRS}/none-dns.conf"
		 		echo "${PROG_NAME}: ${FILE_NAME}"
		 		cat <<- _EOT_ > "${FILE_NAME}"
		 			[main]
		 			systemd-resolved=false
		 			dns=none
		_EOT_
		 		#--- debug print ------------------------------------------------------
		 		echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 		cat "${FILE_NAME}"
		 	fi
		 	echo "${PROG_NAME}: ${FILE_NAME##*/} completed"
		}
		
		# --- network setup samba -----------------------------------------------------
		# run on target
		funcSetupNetwork_samba() {
		 	FUNC_NAME="funcSetupNetwork_samba"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# --- smb.conf ------------------------------------------------------------
		 	FILE_NAME="/etc/samba/smb.conf"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	echo "${PROG_NAME}: ${FILE_NAME}"
		 	if [ ! -d "${BACK_DIRS}/." ]; then
		 		mkdir -p "${BACK_DIRS}"
		 	fi
		 	cp -a "${FILE_NAME}" "${BACK_DIRS}"
		 	sed -i "${FILE_NAME}"                                                   \
		 	    -e "/^[;#]*[ \t]*interfaces[ \t]*=/a \    interfaces = ${NIC_NAME}"
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		 	#--- systemctl ------------------------------------------------------------
		 	if [ -f /lib/systemd/system/smbd.service ]; then
		 		SRVC_SMBD="smbd.service"
		 		SRVC_NMBD="nmbd.service"
		 	else
		 		SRVC_SMBD="smb.service"
		 		SRVC_NMBD="nmb.service"
		 	fi
		 	echo "${PROG_NAME}: daemon-reload"
		 	systemctl daemon-reload
		 	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_SMBD}")"
		 	if [ "${SYSD_STAT}" = "enabled" ]; then
		 		echo "${PROG_NAME}: ${SRVC_SMBD} restarted"
		 		systemctl restart "${SRVC_SMBD}"
		 	fi
		 	echo "${PROG_NAME}: ${SRVC_NMBD} completed"
		 	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NMBD}")"
		 	if [ "${SYSD_STAT}" = "enabled" ]; then
		 		echo "${PROG_NAME}: ${SRVC_NMBD} restarted"
		 		systemctl restart "${SRVC_NMBD}"
		 	fi
		 	echo "${PROG_NAME}: ${SRVC_NMBD} completed"
		}
		
		# --- network setup connman ---------------------------------------------------
		# run on target
		funcSetupNetwork_connman() {
		 	FUNC_NAME="funcSetupNetwork_connman"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	#--- exit for DHCP --------------------------------------------------------
		 	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		 		return
		 	fi
		 	# --- connman -------------------------------------------------------------
		 	SRVC_NAME="connman.service"
		 	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	# --- disable_dns_proxy.conf ----------------------------------------------
		 	FILE_DIRS="/etc/systemd/system/connman.service.d"
		 	FILE_NAME="${FILE_DIRS}/disable_dns_proxy.conf"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	echo "${PROG_NAME}: ${FILE_NAME}"
		 	if [ -f "${FILE_NAME}" ]; then
		 		if [ ! -d "${BACK_DIRS}/." ]; then
		 			mkdir -p "${BACK_DIRS}"
		 		fi
		 		cp -a "${FILE_NAME}" "${BACK_DIRS}"
		 	fi
		 	# --- create file ---------------------------------------------------------
		 	mkdir -p "${FILE_DIRS}"
		 	# shellcheck disable=SC2312
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_NAME}"
		 		[Service]
		 		ExecStart=
		 		ExecStart=$(command -v connmand 2> /dev/null) -n --nodnsproxy
		_EOT_
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		 	# --- settings ------------------------------------------------------------
		 	FILE_DIRS="/var/lib/connman"
		 	FILE_NAME="${FILE_DIRS}/settings"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_NAME%/*}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_DIRS="${TGET_DIRS}/var/lib/connman"
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	echo "${PROG_NAME}: ${FILE_NAME}"
		 	if [ -f "${FILE_NAME}" ]; then
		 		if [ ! -d "${BACK_DIRS}/." ]; then
		 			mkdir -p "${BACK_DIRS}"
		 		fi
		 		cp -a "${FILE_NAME}" "${BACK_DIRS}"
		 	fi
		 	# --- create file ---------------------------------------------------------
		 	mkdir -p "${FILE_NAME%/*}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_NAME}"
		 		[global]
		 		OfflineMode=false
		 		
		 		[Wired]
		 		Enable=true
		 		Tethering=false
		_EOT_
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		 	# --- create file ---------------------------------------------------------
		 	for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
		 	do
		 		MAC_ADDR="$(ip -4 -oneline link show dev "${NICS_NAME}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
		 		CON_ADDR="$(echo "${MAC_ADDR}" | sed -ne 's/://gp')"
		 		CON_NAME="ethernet_${CON_ADDR}_cable"
		 		CON_DIRS="${FILE_DIRS}/${CON_NAME}"
		 		CON_FILE="${CON_DIRS}/settings"
		 		mkdir -p "${CON_DIRS}"
		 		chmod 700 "${CON_DIRS}"
		 		if [ "${NICS_NAME}" = "${NIC_NAME}" ]; then
		 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CON_FILE}"
		 				[${CON_NAME}]
		 				Name=Wired
		 				AutoConnect=true
		 				Modified=
		 				IPv4.method=manual
		 				IPv4.netmask_prefixlen=${NIC_BIT4}
		 				IPv4.local_address=${NIC_IPV4}
		 				IPv4.gateway=${NIC_GATE}
		 				IPv6.method=auto
		 				IPv6.privacy=preferred
		 				Nameservers=${IP6_LHST};${IP4_LHST};${NIC_DNS4};
		 				Timeservers=${NTP_ADDR};
		 				Domains=${NIC_WGRP};
		 				mDNS=false
		 				IPv6.DHCP.DUID=
		_EOT_
		 		else
		 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CON_FILE}"
		 				[${CON_NAME}]
		 				Name=Wired
		 				AutoConnect=false
		 				Modified=
		 				IPv4.method=dhcp
		 				IPv4.DHCP.LastAddress=
		 				IPv6.method=auto
		 				IPv6.privacy=preferred
		_EOT_
		 		fi
		 		chmod 600 "${CON_FILE}"
		 		#--- debug print ------------------------------------------------------
		 		echo "${PROG_NAME}: --- ${CON_FILE} ---"
		 		cat "${CON_FILE}"
		 	done
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_DIRS} ---"
		 	ls -lR "${FILE_DIRS}"
		 	echo "${PROG_NAME}: daemon-reload"
		 	systemctl daemon-reload
		 	#--- systemctl ------------------------------------------------------------
		 	echo "${PROG_NAME}: daemon-reload"
		 	systemctl daemon-reload
		 	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
		 	if [ "${SYSD_STAT}" = "enabled" ]; then
		 		echo "${PROG_NAME}: ${SRVC_NAME} restarted"
		 		systemctl restart "${SRVC_NAME}"
		 	fi
		 	echo "${PROG_NAME}: ${SRVC_NAME} completed"
		}
		
		# --- network setup netplan ---------------------------------------------------
		# run on target
		funcSetupNetwork_netplan() {
		 	FUNC_NAME="funcSetupNetwork_netplan"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	#--- exit for DHCP --------------------------------------------------------
		 	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		 		return
		 	fi
		 	# --- netplan -------------------------------------------------------------
		 	FILE_DIRS="/etc/netplan"
		 	CLUD_DIRS="/etc/cloud/cloud.cfg.d"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_DIRS}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
		 		CLUD_DIRS="${TGET_DIRS}${CLUD_DIRS}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -d "${FILE_DIRS}/." ]; then
		 		echo "${PROG_NAME}: directory does not exist ${FILE_DIRS}"
		 		return
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	if [ ! -d "${BACK_DIRS}/." ]; then
		 		mkdir -p "${BACK_DIRS}"
		 	fi
		#	for FILE_NAME in "${FILE_DIRS}"/*.yaml
		#	do
		#		if [ ! -f "${FILE_NAME}" ]; then
		#			continue
		#		fi
		#		echo "${PROG_NAME}: ${FILE_NAME} moved"
		#		mv "${FILE_NAME}" "${BACK_DIRS}"
		#	done
		 	find "${FILE_DIRS}" -name '*.yaml' -type f | \
		 	while read -r FILE_NAME
		 	do
		 		echo "${PROG_NAME}: ${FILE_NAME} moved"
		 		mv "${FILE_NAME}" "${BACK_DIRS}"
		 	done
		 	# --- create --------------------------------------------------------------
		 	NMAN_DIRS="/etc/NetworkManager"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		NMAN_DIRS="${TGET_DIRS}${NMAN_DIRS}"
		 	fi
		 	if [ -d "${NMAN_DIRS}/." ]; then
		 		if [ -d "${CLUD_DIRS}/." ]; then
		 			FILE_NAME="${CLUD_DIRS}/99-disable-network-config.cfg"
		 			cat <<- _EOT_ > "${FILE_NAME}"
		 				network: {config: disabled}
		_EOT_
		 			#--- debug print --------------------------------------------------
		 			echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 			cat "${FILE_NAME}"
		 		fi
		 		# --- 99-network-manager-all.yaml -------------------------------------
		 		FILE_NAME="${FILE_DIRS}/99-network-manager-all.yaml"
		 		cat <<- _EOT_ > "${FILE_NAME}"
		 			network:
		 			  version: 2
		 			  renderer: NetworkManager
		_EOT_
		 		chmod 600 "${FILE_NAME}"
		 		# --- reload netplan --------------------------------------------------
		#		echo "${PROG_NAME}: netplan apply"
		#		netplan apply
		 		return
		 	fi
		 	# --- 99-network-config-all.yaml ------------------------------------------
		 	echo "${PROG_NAME}: directory does not exist ${NMAN_DIRS}"
		 	FILE_NAME="${FILE_DIRS}/99-network-config-all.yaml"
		 	cat <<- _EOT_ > "${FILE_NAME}"
		 		network:
		 		  version: 2
		 		  renderer: networkd
		 		  ethernets:
		_EOT_
		 	for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
		 	do
		 		if [ "${NICS_NAME}" = "${NIC_NAME}" ] && [ "${FIX_IPV4}" = "true" ]; then
		 			cat <<- _EOT_ >> "${FILE_NAME}"
		 				    ${NICS_NAME}:
		 				      addresses:
		 				      - ${NIC_IPV4}/${NIC_BIT4}
		 				      routes:
		 				      - to: default
		 				        via: ${NIC_GATE}
		 				      nameservers:
		 				        search:
		 				        - ${NIC_WGRP}
		 				        addresses:
		 				        - ${IP6_LHST}
		 				        - ${IP4_LHST}
		 				        - ${NIC_DNS4}
		 				      dhcp4: false
		 				      dhcp6: true
		 				      ipv6-privacy: true
		_EOT_
		 		else
		 			cat <<- _EOT_ >> "${FILE_NAME}"
		 				    ${NICS_NAME}:
		 				      dhcp4: false
		 				      dhcp6: false
		 				      ipv6-privacy: true
		_EOT_
		 		fi
		 		chmod 600 "${FILE_NAME}"
		 	done
		 	#--- debug print ----------------------------------------------------------
		 	echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 	cat "${FILE_NAME}"
		 	echo "${PROG_NAME}: netplan apply"
		 	netplan apply
		}
		
		# --- network setup network manager -------------------------------------------
		# run on target
		funcSetupNetwork_nmanagr() {
		 	FUNC_NAME="funcSetupNetwork_nmanagr"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	#--- exit for DHCP --------------------------------------------------------
		 	if [ "${FIX_IPV4}" != "true" ] || [ -z "${NIC_IPV4}" ]; then
		 		return
		 	fi
		 	# --- network manager -----------------------------------------------------
		 	SRVC_NAME="NetworkManager.service"
		 	FILE_NAME="/lib/systemd/system/${SRVC_NAME}"
		 	FILE_DIRS="/etc/NetworkManager"
		 	CONF_FILE="${FILE_DIRS}/NetworkManager.conf"
		 	BACK_DIRS="${ORIG_DIRS}${FILE_DIRS}"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 		FILE_DIRS="${TGET_DIRS}${FILE_DIRS}"
		 		CONF_FILE="${TGET_DIRS}${CONF_FILE}"
		 		BACK_DIRS="${TGET_DIRS}${BACK_DIRS}"
		 	fi
		 	if [ ! -f "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	if [ ! -d "${BACK_DIRS}/system-connections/." ]; then
		 		mkdir -p "${BACK_DIRS}/system-connections"
		 	fi
		 	echo "${PROG_NAME}: ${CONF_FILE}"
		 	if [ -f "${CONF_FILE}" ]; then
		 		cp -a "${CONF_FILE}" "${BACK_DIRS}"
		 	fi
		 	find "${FILE_DIRS}/system-connections" -name '*.yaml' -type f | \
		 	while read -r FILE_NAME
		 	do
		 		echo "${PROG_NAME}: ${FILE_NAME} moved"
		 		mv "${FILE_NAME}" "${BACK_DIRS}/system-connections"
		 	done
		 	# --- change --------------------------------------------------------------
		#	echo "${PROG_NAME}: change file"
		#	sed -e '/^\[ifupdown\]$/,/^\[.*]$/  {' \
		#	    -e '/^managed=.*$/ s/=.*$/=true/}' \
		#	      "${BACK_DIRS}/${CONF_FILE##*/}"  \
		#	    > "${CONF_FILE}"
		 	#--- debug print ----------------------------------------------------------
		#	echo "${PROG_NAME}: --- ${CONF_FILE} ---"
		#	cat "${CONF_FILE}"
		 	# --- delete --------------------------------------------------------------
		 	SYSD_STAT="$(funcServiceStatus "is-active" "${SRVC_NAME}")"
		 	if [ "${SYSD_STAT}" = "active" ]; then
		 		echo "${PROG_NAME}: delete connection"
		 		IFS='' nmcli connection show | while read -r LINE
		 		do
		 			if [ -z "${LINE}" ]; then
		 				break
		 			fi
		 			case "${LINE}" in
		 				"NAME "*)
		 					TEXT_LINE="${LINE%%UUID[ \t]*}"
		 					TEXT_CONT="${#TEXT_LINE}"
		 					;;
		 				*)
		 					CON_NAME="$(echo "${LINE}" | cut -c 1-"${TEXT_CONT}" | sed -e 's/[ \t]*$//g')"
		 					echo "${PROG_NAME}: ${CON_NAME}"
		 					nmcli connection delete "${CON_NAME}" || true
		 					;;
		 			esac
		 		done
		 	fi
		 	# --- create --------------------------------------------------------------
		 	echo "${PROG_NAME}: create file"
		 	I=1
		 	for NICS_NAME in $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
		 	do
		 		FILE_NAME="${FILE_DIRS}/system-connections/Wired connection ${I}"
		 		MAC_ADDR="$(ip -4 -oneline link show dev "${NICS_NAME}" | sed -ne 's/^.*link\/ether[ \t]\+\(.*\)[ \t]\+brd.*$/\1/p')"
		 		echo "${PROG_NAME}: ${FILE_NAME}"
		 		if [ -f "${FILE_NAME}" ]; then
		 			nmcli connection delete "${FILE_NAME##*/}" || true
		 		fi
		 		if [ "${NICS_NAME}" = "${NIC_NAME}" ]; then
		 			cat <<- _EOT_ > "${FILE_NAME}"
		 				[connection]
		 				id=${FILE_NAME##*/}
		 				#uuid=
		 				type=802-3-ethernet
		 				interface-name=${NICS_NAME}
		 				autoconnect=true
		 				zone=home
		 				
		 				[802-3-ethernet]
		 				mac=${MAC_ADDR}
		 				
		 				[ipv4]
		 				method=manual
		 				dns=${NIC_DNS4};
		 				address1=${NIC_IPV4}/${NIC_BIT4},${NIC_GATE}
		 				dns-search=${NIC_WGRP};
		 				
		 				[ipv6]
		 				method=auto
		 				ip6-privacy=2
		_EOT_
		 		else
		 			cat <<- _EOT_ > "${FILE_NAME}"
		 				[connection]
		 				id=${FILE_NAME##*/}
		 				#uuid=
		 				type=802-3-ethernet
		 				interface-name=${NICS_NAME}
		 				autoconnect=false
		 				#zone=home
		 				
		 				[802-3-ethernet]
		 				mac=${MAC_ADDR}
		 				
		 				[ipv4]
		 				method=auto
		 				
		 				[ipv6]
		 				method=auto
		 				ip6-privacy=2
		_EOT_
		 		fi
		 		chmod 600 "${FILE_NAME}"
		 		if [ -d "${TGET_DIRS}/." ]; then
		 			cp --archive "${FILE_NAME}" "${FILE_DIRS#*/}"
		 		fi
		 		#--- debug print ------------------------------------------------------
		 		echo "${PROG_NAME}: --- ${FILE_NAME} ---"
		 		cat "${FILE_NAME}"
		 		I=$((I+1))
		 	done
		 	#--- systemctl ------------------------------------------------------------
		 	echo "${PROG_NAME}: daemon-reload"
		 	systemctl daemon-reload
		 	SRVC_NWKD="systemd-networkd.service"
		 	SOCK_NWKD="systemd-networkd.socket"
		 	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
		 	if [ "${SYSD_STAT}" = "enabled" ]; then
		 		echo "${PROG_NAME}: ${SRVC_NWKD} ${SOCK_NWKD} stop"
		 		systemctl stop "${SRVC_NWKD}" "${SOCK_NWKD}"
		 		echo "${PROG_NAME}: ${SRVC_NWKD} ${SOCK_NWKD} mask"
		 		systemctl mask "${SRVC_NWKD}" "${SOCK_NWKD}"
		 	fi
		 	SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
		 	if [ "${SYSD_STAT}" = "enabled" ]; then
		 		echo "${PROG_NAME}: ${SRVC_NAME} restarted"
		 		systemctl restart "${SRVC_NAME}"
		 		for NICS_NAME in lo $(ip -4 -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
		 		do
		 			echo "${PROG_NAME}: nmcli device set ${NICS_NAME} managed true"
		 			nmcli device set "${NICS_NAME}" managed true || true
		 		done
		 		echo "${PROG_NAME}: nmcli general reload"
		 		nmcli general reload
		 		echo "${PROG_NAME}: nmcli connection up Wired connection 1"
		 		nmcli connection up "Wired connection 1"
		 		echo "${PROG_NAME}: nmcli networking off"
		 		nmcli networking off
		 		echo "${PROG_NAME}: nmcli networking on"
		 		nmcli networking on
		 		echo "${PROG_NAME}: nmcli connection show"
		 		nmcli connection show
		 		# --- reload netplan --------------------------------------------------
		 		# shellcheck disable=SC2312
		 		if [ -n "$(command -v netplan 2> /dev/null)" ]; then
		 			echo "${PROG_NAME}: netplan apply"
		 			netplan apply
		 		fi
		 		# --- restart winbind.service -----------------------------------------
		#		SRVC_WBND="winbind.service"
		#		SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_WBND}")"
		#		if [ "${SYSD_STAT}" = "enabled" ]; then
		#			echo "${PROG_NAME}: ${SRVC_WBND} restarted"
		#			systemctl restart smbd.service nmbd.service winbind.service
		#		fi
		 	fi
		 	echo "${PROG_NAME}: ${SRVC_NAME} completed"
		}
		
		# --- network -----------------------------------------------------------------
		funcSetupNetwork_software() {
		 	FUNC_NAME="funcSetupNetwork_software"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# -------------------------------------------------------------------------
		 	funcGetNetwork_parameter
		 	funcSetupNetwork_hostname
		 	funcSetupNetwork_hosts
		 	funcSetupNetwork_firewalld
		 	funcSetupNetwork_avahi
		 	funcSetupNetwork_resolv
		 	funcSetupNetwork_dnsmasq
		 	funcSetupNetwork_samba
		}
		
		funcSetupNetwork_hardware() {
		 	FUNC_NAME="funcSetupNetwork_hardware"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# -------------------------------------------------------------------------
		 	funcGetNetwork_parameter
		 	funcSetupNetwork_connman
		 	funcSetupNetwork_netplan
		 	funcSetupNetwork_nmanagr
		}
		
		# --- service -----------------------------------------------------------------
		funcSetupService() {
		 	FUNC_NAME="funcSetupService"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	# -------------------------------------------------------------------------
		 	echo "${PROG_NAME}: daemon-reload"
		 	systemctl daemon-reload
		 	OLD_IFS="${IFS}"
		 	for SRVC_LINE in \
		 		"1 systemd-resolved.service"                \
		 		"1 connman.service"                         \
		 		"1 NetworkManager.service"                  \
		 		"1 firewalld.service"                       \
		 		"- ssh.service"                             \
		 		"1 dnsmasq.service"                         \
		 		"- apache2.service"                         \
		 		"1 smbd.service"                            \
		 		"1 nmbd.service"                            \
		 		"1 winbind.service"
		 	do
		 		IFS=' '
		 		set -f
		 		# shellcheck disable=SC2086
		 		set -- ${SRVC_LINE:-}
		 		set +f
		 		IFS=${OLD_IFS}
		 		SRVC_FLAG="${1:-}"
		 		SRVC_NAME="${2:-}"
		 		if [ "${SRVC_FLAG}" = "-" ]; then
		 			continue
		 		fi
		 		SYSD_STAT="$(funcServiceStatus "is-enabled" "${SRVC_NAME}")"
		 		if [ "${SYSD_STAT}" != "enabled" ]; then
		 			continue
		 		fi
		 		echo "${PROG_NAME}: ${SRVC_NAME} restarted"
		 		systemctl restart "${SRVC_NAME}"
		 	done
		}
		
		# --- gdm3 --------------------------------------------------------------------
		#funcChange_gdm3_configure() {
		#	FUNC_NAME="funcChange_gdm3_configure"
		#	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		#	if [ -f "${TGET_DIRS}/etc/gdm3/custom.conf" ]; then
		#		sed -i.orig "${TGET_DIRS}/etc/gdm3/custom.conf" \
		#		    -e '/WaylandEnable=false/ s/^#//'
		#	fi
		#}
		
		### Main ######################################################################
		funcMain() {
		 	FUNC_NAME="funcMain"
		 	echo "${PROG_NAME}: *** [${FUNC_NAME}] ***"
		 	PRAM_LIST="${PROG_PRAM}"
		 	OLD_IFS="${IFS}"
		 	IFS=' =,'
		 	set -f
		 	# shellcheck disable=SC2086
		 	set -- ${PRAM_LIST:-}
		 	set +f
		 	IFS=${OLD_IFS}
		 	while [ -n "${1:-}" ]
		 	do
		 		case "${1:-}" in
		 			-b | --blacklist )
		 				shift
		 				funcSetupBlacklist
		 				;;
		 			-p | --packages )
		 				shift
		 				funcInstallPackages
		 				;;
		 			-n | --network  )
		 				shift
		 				case "${1:-}" in
		 					s | software ) shift; funcSetupNetwork_software;;
		 					h | hardware ) shift; funcSetupNetwork_hardware;;
		 					*            ) ;;
		 				esac
		 				;;
		 			-s | --service  )
		 				shift
		 				funcSetupService
		 				;;
		 			* )
		 				shift
		 				;;
		 		esac
		 	done
		}
		
		 	funcMain
		
		### Termination ###############################################################
		 	echo "${PROG_NAME}: === End ==="
		 	exit 0
		### EOF #######################################################################
_EOT_SH_
	# -------------------------------------------------------------------------
	mkdir -p "${DIRS_CONF}"/{preseed,nocloud,kickstart,autoyast}
	cp -a "${FILE_NAME}" "${DIRS_CONF}/preseed/preseed_late_command.sh"
	cp -a "${FILE_NAME}" "${DIRS_CONF}/nocloud/nocloud-late-commands.sh"
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
	declare       FILE_TMPL=""
	declare       INSR_STRS=""			# string to insert
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
		cp --backup "${FILE_TMPL}" "${FILE_PATH}"
		if [[ "${FILE_LIST[I]}" =~ _old ]]; then
			sed -i "${FILE_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'  \
			    -e 's/bind9-dnsutils/dnsutils/'
		fi
		if [[ "${FILE_LIST[I]}" =~ _desktop ]]; then
			sed -i "${FILE_PATH}"                                              \
			    -e '/^[ \t]*d-i[ \t]\+pkgsel\/include[ \t]\+/,/^#.*[^\\]$/ { ' \
			    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                 \
			    -e 's/^#/ /g                                               }'
		fi
		if [[ "${FILE_LIST[I]}" =~ _ubiquity_ ]]; then
			IFS= INSR_STRS=$(
				sed -n '/^[^#].*preseed\/late_command/,/[^\\]$/p' "${FILE_PATH}" | \
				sed -e 's/\\/\\\\/g'                                               \
				    -e 's/d-i/ubiquity/'                                           \
				    -e 's%preseed\/late_command%ubiquity\/success_command%'      | \
				sed -e ':l; N; s/\n/\\n/; b l;'
			)
			IFS=${OLD_IFS}
			if [[ -n "${INSR_STRS}" ]]; then
				sed -i "${FILE_PATH}"                                   \
				    -e '/^[^#].*preseed\/late_command/,/[^\\]$/     { ' \
				    -e 's/^/#/g                                       ' \
				    -e 's/^#  /# /g                                 } ' \
				    -e '/^[^#].*ubiquity\/success_command/,/[^\\]$/ { ' \
				    -e 's/^/#/g                                       ' \
				    -e 's/^#  /# /g                                 } '
				sed -i "${FILE_PATH}"                                   \
				    -e "/ubiquity\/success_command/i \\${INSR_STRS}"
			fi
		fi
	done
	# --- expert --------------------------------------------------------------
	FILE_TMPL="${DIRS_NAME}/ps_debian_server.cfg"
	FILE_PATH="${FILE_TMPL/\.cfg/_expert\.cfg}"
	sed -e '/^[ \t]*d-i[ \t]\+partman-auto\/init_automatically_partition[ \t]\+/                            { ' \
	    -e 's/^/#/g                                                                                           ' \
	    -e 's/^#  /# /g                                                                                     } ' \
	    -e '/^[ \t]*d-i[ \t]\+partman-auto\/disk[ \t]\+/                                                    { ' \
	    -e 's/^/#/g                                                                                           ' \
	    -e 's/^#  /# /g                                                                                     } ' \
	    -e '/^[ \t]*d-i[ \t]\+partman-auto\/choose_recipe[ \t]\+/                                           { ' \
	    -e 's/^/#/g                                                                                           ' \
	    -e 's/^#  /# /g                                                                                     } ' \
	    -e '/^[ \t]*d-i[ \t]\+partman\/early_command[ \t]\+/,/[^\\]$/                                       { ' \
	    -e '0,/[^\\]$/                                                                                      { ' \
	    -e '/pvremove[ \t]\+/a \      pvremove /dev/sda*     -ff -y; '\\\\''                                    \
	    -e '/dd[ \t]\+/a \      dd if=/dev/zero of=/dev/sda     bs=1M count=10; '\\\\''                         \
	    -e '                                                                                               }} ' \
	    -e '/^#*[ \t]*d-i[ \t]\+partman-auto\/expert_recipe[ \t]\+/,/[^\\]$/                                { ' \
	    -e '0,/[^\\]$/                                                                                      { ' \
	    -e 's/^#/ /g                                                                                       }} ' \
	    -e '/^#[ \t]*d-i[ \t]\+partman-auto\/disk[ \t]\+string[ \t]\+\/dev\/nvme0n1[ \t]\+\/dev\/sda[ \t]*/ { ' \
	    -e '0,/[^\\]$/                                                                                      { ' \
	    -e 's/^#/ /g                                                                                       }} ' \
	    "${FILE_TMPL}"                                                                                          \
	>   "${FILE_PATH}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${DIRS_NAME}/"*
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
		cp --backup "${CONF_CLUD}" "${DIRS_NAME}/user-data"
		if [[ "${DIRS_NAME}" =~ _old ]]; then
			sed -i "${DIRS_NAME}/user-data"     \
			    -e 's/bind9-utils/bind9utils/'  \
			    -e 's/bind9-dnsutils/dnsutils/'
		fi
		if [[ "${DIRS_NAME}" =~ _desktop ]]; then
			sed -i "${DIRS_NAME}/user-data"                                    \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
		fi
		touch "${DIRS_NAME}/meta-data"      --reference "${DIRS_NAME}/user-data"
		touch "${DIRS_NAME}/network-config" --reference "${DIRS_NAME}/user-data"
#		touch "${DIRS_NAME}/user-data"      --reference "${DIRS_NAME}/user-data"
		touch "${DIRS_NAME}/vendor-data"    --reference "${DIRS_NAME}/user-data"
		chmod ugo-x "${DIRS_NAME}/"*
	done
}

# ----- create kickstart.cfg --------------------------------------------------
function funcCreate_kickstart() {
	declare -r    IMGS_ADDR="http://${SRVR_ADDR}/imgs"
	declare -r    DIRS_NAME="${DIRS_CONF}/kickstart"
	declare       FILE_PATH=""
	declare -r -a FILE_LIST=(                            \
		"ks_almalinux-9_"{net,dvd,web}".cfg"             \
		"ks_centos-stream-"{8..10}"_"{net,dvd,web}".cfg" \
		"ks_fedora-"{39..40}"_"{net,dvd,web}".cfg"       \
		"ks_miraclelinux-"{8..9}"_"{net,dvd,web}".cfg"   \
		"ks_rockylinux-"{8..9}"_"{net,dvd,web}".cfg"     \
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
		if [[ "${DSTR_NAME}" = "fedora" ]] && [[ ${DSTR_NUMS} -ge 38 ]] && [[ ${DSTR_NUMS} -le 40 ]]; then
			RLNX_NUMS="9"
		fi
		# ---------------------------------------------------------------------
		cp --backup "${CONF_KICK}" "${FILE_PATH}"
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
				    -e "s/\$releasever/${RLNX_NUMS}/g        " \
				    -e "s/\$basearch/${BASE_ARCH}/g        } "
				;;
			*_web* )
				sed -i "${FILE_PATH}"                          \
				    -e "/^cdrom/ s/^/#/                      " \
				    -e "s/_HOSTNAME_/${DSTR_NAME%%-*}/       " \
				    -e "/^#.*(${DSTR_SECT}).*$/,/^$/       { " \
				    -e '/_WEBADDR_/                        { ' \
				    -e "/^#url[ \t]\+/  s/^#//g              " \
				    -e "/^#repo[ \t]\+/ s/^#//g              " \
				    -e "/_WEBADDR_/!                       { " \
				    -e '/^url[ \t]\+/   s/^/#/g              ' \
				    -e '/^repo[ \t]\+/  s/^/#/g            } ' \
				    -e "s/\$releasever/${DSTR_NUMS}/g        " \
				    -e "s/\$basearch/${BASE_ARCH}/g       }} " \
				    -e "/%post/,/%end/                     { " \
				    -e "s/\$releasever/${RLNX_NUMS}/g        " \
				    -e "s/\$basearch/${BASE_ARCH}/g        } "
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
				    -e "s/\$releasever/${RLNX_NUMS}/g        " \
				    -e "s/\$basearch/${BASE_ARCH}/g        } "
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
		case "${FILE_LIST[I]}" in
			*_web* )
				sed -i "${FILE_PATH}"                          \
				    -e "/^#.*(${DSTR_SECT}).*$/,/^$/       { " \
				    -e "s%_WEBADDR_%${IMGS_ADDR}%g         } " \
				;;
			* )
				;;
		esac
#		sed -i "${FILE_PATH}"                          \
#		    -e "/^#.*(${DSTR_SECT}).*$/,/^$/       { " \
#		    -e "s%_WEBADDR_%${WEBS_ADDR}/imgs%g    } "
		sed -e "/%packages/,/%end/ {"                  \
		    -e "/desktop/ s/^-//g  }"                  \
		    "${FILE_PATH}"                             \
		>   "${FILE_PATH/\.cfg/_desktop\.cfg}"
	done
	chmod ugo-x "${DIRS_NAME}/"*
}

# ----- create autoyast.xml ---------------------------------------------------
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
		cp --backup "${CONF_YAST}" "${FILE_PATH}"
		if [[ "${DSTR_NUMS}" =~ leap ]]; then
			sed -i "${FILE_PATH}"                                                 \
			    -e '/<add_on_products .*>/,/<\/add_on_products>/              { ' \
			    -e '/<!-- leap/,/leap -->/                                    { ' \
			    -e "/<media_url>/ s~/\(leap\)/[0-9.]*/~/\1/${DSTR_NUMS#*-}/~g   " \
			    -e "/<media_url>/ s~/\(leap\)/[0-9.]*/~/\1/${DSTR_NUMS#*-}/~g } " \
			    -e '/<!-- leap$/ s/$/ -->/g                                     ' \
			    -e '/^leap -->/  s/^/<!-- /g                                  } ' \
			    -e 's~\(<product>\).*\(</product>\)~\1Leap\2~                   '
		else
			sed -i "${FILE_PATH}"                                                 \
			    -e '/<add_on_products .*>/,/<\/add_on_products>/              { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/                        { ' \
			    -e '/<media_url>/ s~/leap/[0-9.]*/~/tumbleweed/~g               ' \
			    -e '/<media_url>/ s~/leap/[0-9.]*/~/tumbleweed/~g             } ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                               ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                            } ' \
			    -e 's~\(<product>\).*\(</product>\)~\1openSUSE\2~               '
		fi
		if [[ "${FILE_PATH}" =~ _lxde ]]; then
			sed -i "${FILE_PATH}"                     \
			    -e '/<!-- desktop lxde$/ s/$/ -->/g ' \
			    -e '/^desktop lxde -->/  s/^/<!-- /g'
		fi
		if [[ "${FILE_PATH}" =~ _dvd ]]; then
			sed -i "${FILE_PATH}"                                     \
			    -e '/<image_installation t="boolean">/ s/false/true/'
		else
			sed -i "${FILE_PATH}"                                     \
			    -e '/<image_installation t="boolean">/ s/true/false/'
		fi
	done
	chmod ugo-x "${DIRS_NAME}/"*
}

# ----- copy iso contents to hdd ----------------------------------------------
function funcCreate_copy_iso2hdd() {
	declare -r -a TGET_LINE=("$@")
	declare -r    FILE_PATH="${DIRS_ISOS}/${TGET_LINE[4]}"
	declare -r    DEST_DIRS="${DIRS_IMGS}/${TGET_LINE[1]}"
	declare -r    BOOT_DIRS="${DIRS_TFTP}/load/${TGET_LINE[1]}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_MNTP="${WORK_DIRS}/mnt"
#	declare -r    WORK_IMGS="${WORK_DIRS}/img"
#	declare -r    WORK_RAMS="${WORK_DIRS}/ram"
	declare       DIRS_KRNL=""
	declare       DIRS_IRAM=""
#	declare       FILE_IRAM=""
	declare -i    RET_CD=0
	funcPrintf "        copy: ${TGET_LINE[4]}"
	if [[ "${TGET_LINE[0]}" != "o" ]] || [[ ! -f "${FILE_PATH}" ]]; then
		return
	fi
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
	rm -rf "${WORK_DIRS:?}"
#	rm -rf "${DEST_DIRS:?}"
#	rm -rf "${BOOT_DIRS:?}"
	# --- create directory ----------------------------------------------------
	mkdir -p "${WORK_DIRS}/"{mnt,img,ram}
	mkdir -p "${DEST_DIRS}"
	mkdir -p "${BOOT_DIRS}"
	# --- copy iso -> hdd -----------------------------------------------------
	mount -o ro,loop "${FILE_PATH}" "${WORK_MNTP}"
	touch -c "${DEST_DIRS}" 2>/dev/null
	RET_CD=$?
	if [[ "${RET_CD}" -eq 0 ]]; then
		ionice -c "${IONICE_CLAS}" rsync --archive --human-readable --update --delete "${WORK_MNTP}/." "${DEST_DIRS}/" 2>/dev/null || true
#	else
#		funcPrintf "        skip: ${TGET_LINE[4]}"
	fi
	if [[ -f "${WORK_MNTP}/${TGET_LINE[5]}/${TGET_LINE[6]}" ]] && [[ -f "${WORK_MNTP}/${TGET_LINE[5]}/${TGET_LINE[7]}" ]]; then
		DIRS_IRAM="${BOOT_DIRS}"
		DIRS_KRNL="${BOOT_DIRS}"
		if [[ "${TGET_LINE[6]%/*}" != "${TGET_LINE[6]##*/}" ]]; then
			DIRS_IRAM="${BOOT_DIRS}/${TGET_LINE[6]%/*}"
		fi
		if [[ "${TGET_LINE[7]%/*}" != "${TGET_LINE[7]##*/}" ]]; then
			DIRS_KRNL="${BOOT_DIRS}/${TGET_LINE[7]%/*}"
		fi
		rm -rf "${DIRS_IRAM:?}/${TGET_LINE[6]##*/}" "${DIRS_KRNL:?}/${TGET_LINE[7]##*/}"
		mkdir -p "${DIRS_IRAM}" "${DIRS_KRNL}"
		ionice -c "${IONICE_CLAS}" rsync --archive --human-readable --update --delete "${WORK_MNTP}/${TGET_LINE[5]}/${TGET_LINE[6]}" "${DIRS_IRAM}/"
		ionice -c "${IONICE_CLAS}" rsync --archive --human-readable --update --delete "${WORK_MNTP}/${TGET_LINE[5]}/${TGET_LINE[7]}" "${DIRS_KRNL}/"
#		ln -s -r "${DEST_DIRS}/${TGET_LINE[5]}/${TGET_LINE[6]}" "${DIRS_IRAM}/"
#		ln -s -r "${DEST_DIRS}/${TGET_LINE[5]}/${TGET_LINE[7]}" "${DIRS_KRNL}/"
	fi
	umount "${WORK_MNTP}"
	# --- copy initrd -> hdd --------------------------------------------------
#	if [[ "${TGET_LINE[1]}" =~ -mini- ]]; then
#		funcPrintf "        copy: initrd"
#		# shellcheck disable=SC2312
#		while read -r FILE_IRAM
#		do
#			DIRS_IRAM="${WORK_RAMS}/${FILE_IRAM##*/}"
#			mkdir -p "${DIRS_IRAM}"
#			unmkinitramfs "${FILE_IRAM}" "${DIRS_IRAM}/" 2>/dev/null
#		done < <(find "${WORK_IMGS}" -name 'initrd*' -type f)
#	fi
	# --- remove directory ----------------------------------------------------
	rm -rf "${WORK_DIRS:?}"
}

# ----- create menu.cfg preseed -----------------------------------------------
function funcCreate_menu_cfg_preseed() {
	declare -r -a TGET_LINE=("$@")
	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"
#	declare -r    CONF_FILE="file=/cdrom/${TGET_LINE[8]}"
	declare -r    CONF_FILE="url=${HTTP_ADDR}/conf/${TGET_LINE[8]}"
	declare -r    RAMS_DISK="root=/dev/ram0 ramdisk_size=1500000"
	declare -r    LIVE_IMGS="live/filesystem.squashfs"
	declare -a    BOOT_WORK=()
	declare       BOOT_BIOS=""
#	declare       WORK_ETHR="${ETHR_NAME}"
#	funcPrintf "      create: boot options for preseed"
	# --- boot clear ----------------------------------------------------------
	BOOT_WORK=()
	# --- 00: root option -----------------------------------------------------
	BOOT_WORK+=("tftp")
#	BOOT_WORK+=("${HTTP_ADDR%%:*},${HTTP_ADDR##*/}")
	# --- 01: iso file option -------------------------------------------------
	BOOT_WORK+=("${TGET_LINE[4]}")
	# --- 02: iso addr option -------------------------------------------------
	BOOT_WORK+=("fetch=${HTTP_ADDR}/isos/\${isofile}")
	case "${TGET_LINE[1]}" in
		ubuntu-*              ) BOOT_WORK[2]="iso-url=${HTTP_ADDR}/isos/\${isofile}";;
		*                     ) ;;
	esac
	# --- 03: install option --------------------------------------------------
	BOOT_WORK+=("auto=true ${CONF_FILE}")
	case "${TGET_LINE[1]}" in
		ubuntu-desktop-*      | \
		ubuntu-legacy-*       ) BOOT_WORK[3]="automatic-ubiquity noprompt ${BOOT_WORK[3]}";;
		*                     ) ;;
	esac
	# --- 04: host name -------------------------------------------------------
	BOOT_WORK+=("${HOST_NAME}.${WGRP_NAME}")
	# --- 05: network option --------------------------------------------------
	BOOT_WORK+=("netcfg/disable_autoconfig=true netcfg/choose_interface=${ETHR_NAME} netcfg/get_hostname=\${netname} netcfg/get_ipaddress=${IPV4_ADDR} netcfg/get_netmask=${IPV4_MASK} netcfg/get_gateway=${IPV4_GWAY} netcfg/get_nameservers=${IPV4_NSVR}")
	case "${TGET_LINE[1]}" in
		ubuntu-live-18.04     ) BOOT_WORK[5]="ip=${ETHR_NAME},${IPV4_ADDR},${IPV4_MASK},${IPV4_GWAY} hostname=\${netname}";;
		ubuntu-desktop-*      | \
		ubuntu-legacy-*       ) BOOT_WORK[5]="ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:\${netname}:${ETHR_NAME}:static:${IPV4_NSVR}";;
		ubuntu-*              ) BOOT_WORK[5]="${BOOT_WORK[4]} netcfg/target_network_config=NetworkManager";;
		*                     ) ;;
	esac
	# --- 06: locales option --------------------------------------------------
	BOOT_WORK+=("locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106")
	case "${TGET_LINE[1]}" in
		ubuntu-desktop-*      | \
		ubuntu-legacy-*       ) BOOT_WORK[6]="debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                     ) ;;
	esac
	# --- 07: ramdisk option --------------------------------------------------
	BOOT_WORK+=("")
	case "${TGET_LINE[1]}" in
		ubuntu-*              ) BOOT_WORK[7]="${RAMS_DISK}";;
		*                     ) ;;
	esac
	# --- 08: boot option -----------------------------------------------------
	BOOT_WORK+=("\${isoaddr} \${install} \${network} \${locales} \${ramdisk} fsck.mode=skip")
	# --- 09: kernel addr option ----------------------------------------------
	BOOT_WORK+=("${HTTP_ADDR}/imgs/${TGET_LINE[1]}")
	# --- live mode -----------------------------------------------------------
	if [[ "${TGET_LINE[8]#*/}" = "-" ]]; then
		BOOT_WORK[3]=""
		BOOT_WORK[4]=""
		BOOT_WORK[5]="ip=dhcp"
		case "${TGET_LINE[1]}" in
			debian-live-*         ) BOOT_WORK[2]="boot=live components fetch=${HTTP_ADDR}/imgs/${TGET_LINE[1]}/${LIVE_IMGS}";;
			ubuntu-desktop-18.*   ) ;;	# This version does not support pxeboot
			ubuntu-desktop-20.*   | \
			ubuntu-desktop-22.*   | \
			ubuntu-legacy-*       ) BOOT_WORK[2]="boot=casper maybe-ubiquity ${BOOT_WORK[2]}";;
			ubuntu-desktop-*      ) BOOT_WORK[2]="boot=casper layerfs-path=minimal.standard.live.squashfs ${BOOT_WORK[2]}";;
			*                     ) ;;
		esac
	fi
	# --- output --------------------------------------------------------------
	BOOT_BIOS="${BOOT_WORK[2]/\$\{isofile\}/${BOOT_WORK[1]}} ${BOOT_WORK[3]} ${BOOT_WORK[5]//\${netname}/${HOST_NAME}.${WGRP_NAME}} ${BOOT_WORK[6]} ${BOOT_WORK[7]} fsck.mode=skip"
	IFS=
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		${BOOT_BIOS//\${svraddr}/${SRVR_ADDR}}"
		set root='${BOOT_WORK[0]}'
		set svraddr='${SRVR_ADDR}'
		set isofile='${BOOT_WORK[1]}'
		set isoaddr="${BOOT_WORK[2]}"
		set install="${BOOT_WORK[3]}"
		set netname='${BOOT_WORK[4]}'
		set network="${BOOT_WORK[5]}"
		set locales='${BOOT_WORK[6]}'
		set ramdisk='${BOOT_WORK[7]}'
		set options="${BOOT_WORK[8]}"
		set knladdr="${BOOT_WORK[9]}"
_EOT_
	IFS="${OLD_IFS}"
#	echo "${BOOT_WORK[2]/\$\{isofile\}/${BOOT_WORK[1]}} ${BOOT_WORK[3]} ${BOOT_WORK[4]} ${BOOT_WORK[5]} ${BOOT_WORK[6]} fsck.mode=skip"
}

# ----- create menu.cfg nocloud -----------------------------------------------
function funcCreate_menu_cfg_nocloud() {
	declare -r -a TGET_LINE=("$@")
	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"
#	declare -r    CONF_FILE="file:///cdrom/${TGET_LINE[8]}"
	declare -r    CONF_FILE="${HTTP_ADDR}/conf/${TGET_LINE[8]}"
	declare -r    RAMS_DISK="root=/dev/ram0 ramdisk_size=1500000"
#	declare -r    LIVE_IMGS="live/filesystem.squashfs"
#	declare       WORK_ETHR="${ETHR_NAME}"
#	funcPrintf "      create: boot options for nocloud"
	# --- boot clear ----------------------------------------------------------
	BOOT_WORK=()
	# --- 00: root option -----------------------------------------------------
	BOOT_WORK+=("tftp")
#	BOOT_WORK+=("${HTTP_ADDR%%:*},${HTTP_ADDR##*/}")
	# --- 01: iso file option -------------------------------------------------
	BOOT_WORK+=("${TGET_LINE[4]}")
	# --- 02: iso addr option -------------------------------------------------
	BOOT_WORK+=("")
	case "${TGET_LINE[1]}" in
		ubuntu-live-18.*      | \
		ubuntu-live-20.*      | \
		ubuntu-live-22.*      | \
		ubuntu-desktop-22.*   ) BOOT_WORK[2]="url=${HTTP_ADDR}/isos/\${isofile}";;
		ubuntu-*              ) BOOT_WORK[2]="iso-url=${HTTP_ADDR}/isos/\${isofile}";;
		*                     ) ;;
	esac
	# --- 03: install option --------------------------------------------------
	BOOT_WORK+=("")
	case "${TGET_LINE[1]}" in
		ubuntu-*              ) BOOT_WORK[3]="automatic-ubiquity noprompt autoinstall ds=nocloud-net;s=${CONF_FILE}";;
		*                     ) ;;
	esac
	# --- 04: host name -------------------------------------------------------
	BOOT_WORK+=("${HOST_NAME}.${WGRP_NAME}")
	# --- 05: network option --------------------------------------------------
	BOOT_WORK+=("")
	case "${TGET_LINE[1]}" in
		ubuntu-live-18.04     ) BOOT_WORK[5]="ip=${ETHR_NAME},${IPV4_ADDR},${IPV4_MASK},${IPV4_GWAY} hostname=\${netname}";;
		ubuntu-*              ) BOOT_WORK[5]="ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}::${ETHR_NAME}:static:${IPV4_NSVR} hostname=\${netname}";;
		*                     ) ;;
	esac
	# --- 06: locales option --------------------------------------------------
	BOOT_WORK+=("")
	case "${TGET_LINE[1]}" in
		ubuntu-*              ) BOOT_WORK[6]="debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                     ) ;;
	esac
	# --- 07: ramdisk option --------------------------------------------------
	BOOT_WORK+=("")
	case "${TGET_LINE[1]}" in
		ubuntu-*              ) BOOT_WORK[7]="${RAMS_DISK}";;
		*                     ) ;;
	esac
	# --- 08: boot option -----------------------------------------------------
	BOOT_WORK+=("\${isoaddr} \${install} \${network} \${locales} \${ramdisk} fsck.mode=skip")
	# --- 09: kernel addr option ----------------------------------------------
	BOOT_WORK+=("${HTTP_ADDR}/imgs/${TGET_LINE[1]}")
	# --- live mode -----------------------------------------------------------
	if [[ "${TGET_LINE[8]#*/}" = "-" ]]; then
#		BOOT_WORK[0]="${HTTP_ADDR%%:*},${HTTP_ADDR##*/}"
		BOOT_WORK[3]=""
		BOOT_WORK[4]=""
		BOOT_WORK[5]="ip=dhcp"
		case "${TGET_LINE[1]}" in
			ubuntu-desktop-18.*   ) ;;	# This version does not support pxeboot
			ubuntu-desktop-20.*   | \
			ubuntu-desktop-22.*   | \
			ubuntu-legacy-*       ) BOOT_WORK[2]="boot=casper maybe-ubiquity ${BOOT_WORK[2]}";;
			ubuntu-desktop-*      ) BOOT_WORK[2]="boot=casper layerfs-path=minimal.standard.live.squashfs ${BOOT_WORK[2]}";;
			*                     ) ;;
		esac
	fi
	# --- output --------------------------------------------------------------
	BOOT_BIOS="${BOOT_WORK[2]/\$\{isofile\}/${BOOT_WORK[1]}} ${BOOT_WORK[3]} ${BOOT_WORK[5]//\${netname}/${HOST_NAME}.${WGRP_NAME}} ${BOOT_WORK[6]} ${BOOT_WORK[7]} fsck.mode=skip"
	IFS=
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		${BOOT_BIOS//\${svraddr}/${SRVR_ADDR}}"
		set root='${BOOT_WORK[0]}'
		set svraddr='${SRVR_ADDR}'
		set isofile='${BOOT_WORK[1]}'
		set isoaddr="${BOOT_WORK[2]}"
		set install="${BOOT_WORK[3]}"
		set netname='${BOOT_WORK[4]}'
		set network="${BOOT_WORK[5]}"
		set locales='${BOOT_WORK[6]}'
		set ramdisk='${BOOT_WORK[7]}'
		set options="${BOOT_WORK[8]}"
		set knladdr="${BOOT_WORK[9]}"
_EOT_
	IFS="${OLD_IFS}"
#	echo "${BOOT_WORK[2]/\$\{isofile\}/${BOOT_WORK[1]}} ${BOOT_WORK[3]} ${BOOT_WORK[4]} ${BOOT_WORK[5]} ${BOOT_WORK[6]} fsck.mode=skip"
}

# ----- create menu.cfg kickstart ---------------------------------------------
function funcCreate_menu_cfg_kickstart() {
	declare -r -a TGET_LINE=("$@")
	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"
#	declare -r    CONF_FILE="hd:sr0:/${TGET_LINE[8]} inst.stage2=hd:LABEL=${TGET_LINE[14]}"
	declare -r    CONF_FILE="${HTTP_ADDR}/conf/${TGET_LINE[8]/_dvd/_web}"
#	declare -r    RAMS_DISK="root=/dev/ram0 ramdisk_size=1500000"
#	declare -r    LIVE_IMGS="live/filesystem.squashfs"
#	declare       WORK_ETHR="${ETHR_NAME}"
#	funcPrintf "      create: boot options for kickstart"
	# --- boot clear ----------------------------------------------------------
	BOOT_WORK=()
	# --- 00: root option -----------------------------------------------------
	BOOT_WORK+=("tftp")
#	BOOT_WORK+=("${HTTP_ADDR%%:*},${HTTP_ADDR##*/}")
	# --- 01: iso file option -------------------------------------------------
	BOOT_WORK+=("${TGET_LINE[4]}")
	# --- 02: iso addr option -------------------------------------------------
	BOOT_WORK+=("inst.stage2=${HTTP_ADDR}/imgs/${TGET_LINE[1]}")
#	BOOT_WORK+=("inst.stage2=${HTTP_ADDR}/imgs/\${isofile}")
#	case "${TGET_LINE[1]}" in
#		*-netinst*            ) BOOT_WORK[2]="";;
#		*                     ) ;;
#	esac
	# --- 03: install option --------------------------------------------------
	BOOT_WORK+=("inst.ks=${CONF_FILE}")
	# --- 04: host name -------------------------------------------------------
	BOOT_WORK+=("${HOST_NAME}.${WGRP_NAME}")
	# --- 05: network option --------------------------------------------------
	BOOT_WORK+=("ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:\${netname}:${ETHR_NAME}:none,auto6 nameserver=${IPV4_NSVR}")
	# --- 06: locales option --------------------------------------------------
	BOOT_WORK+=("locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106")
	# --- 07: ramdisk option --------------------------------------------------
	BOOT_WORK+=("")
	# --- 08: boot option -----------------------------------------------------
	BOOT_WORK+=("\${isoaddr} \${install} \${network} \${locales} \${ramdisk} fsck.mode=skip")
	# --- 09: kernel addr option ----------------------------------------------
	BOOT_WORK+=("${HTTP_ADDR}/imgs/${TGET_LINE[1]}")
	# --- live mode -----------------------------------------------------------
	if [[ "${TGET_LINE[8]#*/}" = "-" ]]; then
		BOOT_WORK[3]=""
		BOOT_WORK[4]=""
		BOOT_WORK[5]="ip=dhcp"
	fi
	# --- output --------------------------------------------------------------
	BOOT_BIOS="${BOOT_WORK[2]/\$\{isofile\}/${BOOT_WORK[1]}} ${BOOT_WORK[3]} ${BOOT_WORK[5]//\${netname}/${HOST_NAME}.${WGRP_NAME}} ${BOOT_WORK[6]} ${BOOT_WORK[7]} fsck.mode=skip"
	IFS=
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		${BOOT_BIOS//\${svraddr}/${SRVR_ADDR}}"
		set root='${BOOT_WORK[0]}'
		set svraddr='${SRVR_ADDR}'
		set isofile='${BOOT_WORK[1]}'
		set isoaddr="${BOOT_WORK[2]}"
		set install="${BOOT_WORK[3]}"
		set netname='${BOOT_WORK[4]}'
		set network="${BOOT_WORK[5]}"
		set locales='${BOOT_WORK[6]}'
		set ramdisk='${BOOT_WORK[7]}'
		set options="${BOOT_WORK[8]}"
		set knladdr="${BOOT_WORK[9]}"
_EOT_
	IFS="${OLD_IFS}"
#	echo "${BOOT_WORK[2]/\$\{isofile\}/${BOOT_WORK[1]}} ${BOOT_WORK[3]} ${BOOT_WORK[4]} ${BOOT_WORK[5]} ${BOOT_WORK[6]} fsck.mode=skip"
}

# ----- create menu.cfg autoyast ----------------------------------------------
function funcCreate_menu_cfg_autoyast() {
	declare -r -a TGET_LINE=("$@")
	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"
#	declare -r    CONF_FILE="cd:/${TGET_LINE[8]}"
	declare -r    CONF_FILE="${HTTP_ADDR}/conf/${TGET_LINE[8]}"
	declare -r    RAMS_DISK="root=/dev/ram0 load_ramdisk=1 showopts ramdisk_size=4096"
#	declare -r    LIVE_IMGS="live/filesystem.squashfs"
	declare       WORK_ETHR="${ETHR_NAME}"
#	funcPrintf "      create: boot options for autoyast"
	# --- boot clear ----------------------------------------------------------
	BOOT_WORK=()
	# --- 00: root option -----------------------------------------------------
	BOOT_WORK+=("tftp")
#	BOOT_WORK+=("${HTTP_ADDR%%:*},${HTTP_ADDR##*/}")
	# --- 01: iso file option -------------------------------------------------
	BOOT_WORK+=("${TGET_LINE[4]}")
	# --- 02: iso addr option -------------------------------------------------
#	BOOT_WORK+=("install=${HTTP_ADDR}/imgs/\${isofile}")
	BOOT_WORK+=("install=${HTTP_ADDR}/imgs/${TGET_LINE[1]}")
	case "${TGET_LINE[1]}" in
		*-netinst*            ) BOOT_WORK[2]="";;
		*                     ) ;;
	esac
	# --- 03: install option --------------------------------------------------
	BOOT_WORK+=("autoyast=${CONF_FILE}")
	# --- 04: host name -------------------------------------------------------
	BOOT_WORK+=("${HOST_NAME}.${WGRP_NAME}")
	# --- 05: network option --------------------------------------------------
	case "${TGET_LINE[1]}" in
		opensuse-*-15* ) WORK_ETHR="eth0";;
		*              ) ;;
	esac
	BOOT_WORK+=("ifcfg=${WORK_ETHR}=${IPV4_ADDR}/${IPV4_CIDR},${IPV4_GWAY},${IPV4_NSVR},${WGRP_NAME} hostname=\${netname}")
	# --- 06: locales option --------------------------------------------------
	BOOT_WORK+=("locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106")
	# --- 07: ramdisk option --------------------------------------------------
	BOOT_WORK+=("${RAMS_DISK}")
	# --- 08: boot option -----------------------------------------------------
	BOOT_WORK+=("\${isoaddr} \${install} \${network} \${locales} \${ramdisk} fsck.mode=skip")
	# --- 09: kernel addr option ----------------------------------------------
	BOOT_WORK+=("${HTTP_ADDR}/imgs/${TGET_LINE[1]}")
	# --- live mode -----------------------------------------------------------
	if [[ "${TGET_LINE[8]#*/}" = "-" ]]; then
		BOOT_WORK[3]=""
		BOOT_WORK[4]=""
		BOOT_WORK[5]="ip=dhcp"
	fi
	# --- output --------------------------------------------------------------
	BOOT_BIOS="${BOOT_WORK[2]/\$\{isofile\}/${BOOT_WORK[1]}} ${BOOT_WORK[3]} ${BOOT_WORK[5]//\${netname}/${HOST_NAME}.${WGRP_NAME}} ${BOOT_WORK[6]} ${BOOT_WORK[7]} fsck.mode=skip"
	IFS=
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		${BOOT_BIOS//\${svraddr}/${SRVR_ADDR}}"
		set root='${BOOT_WORK[0]}'
		set svraddr='${SRVR_ADDR}'
		set isofile='${BOOT_WORK[1]}'
		set isoaddr="${BOOT_WORK[2]}"
		set install="${BOOT_WORK[3]}"
		set netname='${BOOT_WORK[4]}'
		set network="${BOOT_WORK[5]}"
		set locales='${BOOT_WORK[6]}'
		set ramdisk='${BOOT_WORK[7]}'
		set options="${BOOT_WORK[8]}"
		set knladdr="${BOOT_WORK[9]}"
_EOT_
	IFS="${OLD_IFS}"
#	echo "${BOOT_WORK[2]/\$\{isofile\}/${BOOT_WORK[1]}} ${BOOT_WORK[3]} ${BOOT_WORK[4]} ${BOOT_WORK[5]} ${BOOT_WORK[6]} fsck.mode=skip"
}

# ----- create menu for syslinux ----------------------------------------------
function funcCreate_syslinux_cfg() {
	declare -r    MENU_DIRS="$1"							# menu directory
	declare -r -n MENU_NAME="$2"							# menu file name
	declare       BOOT_OPTN="$3"							# boot option
	declare -r -n TGET_INFO="$4"							# media information
	declare -r -i TABS_CONT="$5"							# tabs count
	declare       TABS_STRS=""								# tabs string
	declare       MENU_PATH=""								# menu path
	declare       MENU_ENTR=""								# meny entry
#	funcPrintf "      create: ${TGET_INFO[2]//%20/ }"
	if [[ "${TABS_CONT}" -gt 0 ]]; then
		TABS_STRS="$(funcString "${TABS_CONT}" $'\t')"
	else
		TABS_STRS=""
	fi
	# --- create syslinux.cfg -------------------------------------------------
	MENU_PATH="${MENU_DIRS}/${MENU_NAME[0]}"
	if [[ ! -f "${MENU_PATH}" ]] \
	|| [[ ! -s "${MENU_PATH}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${MENU_PATH}"
			path ./
			prompt 0
			timeout 0
			default vesamenu.c32
			
			menu resolution ${MENU_RESO/x/ }
			
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
			
_EOT_
	fi
	case "${TGET_INFO[0]}" in
		m )
			if [[ "${TGET_INFO[2]}" = "-" ]]; then
				return
			fi
			MENU_ENTR="[ ${TGET_INFO[2]//%20/ } ... ]"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${MENU_PATH}"
				label ${TGET_INFO[2]//%20/-}
				 	menu label ^${MENU_ENTR}
				
_EOT_
			;;
		o )
			MENU_ENTR="$(printf "%-60.60s" "- ${TGET_INFO[2]//%20/ }")"
			case "${TGET_INFO[1]}" in
				windows-* )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					if [[ "${MENU_PATH}" =~ bios ]]; then
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${MENU_PATH}"
							label ${TGET_INFO[1]}
							 	menu label ^${MENU_ENTR}
							 	kernel memdisk
							 	append initrd=${HTTP_ADDR}/isos/${TGET_INFO[4]} iso raw
							
_EOT_
					fi
					;;
				memtest86\+ )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					if [[ "${MENU_PATH}" =~ bios ]]; then
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${MENU_PATH}"
							label ${TGET_INFO[1]}
							 	menu label ^${MENU_ENTR}
							 	kernel load/${TGET_INFO[1]}/${TGET_INFO[7]}
							
_EOT_
					else
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${MENU_PATH}"
							label ${TGET_INFO[1]}
							 	menu label ^${MENU_ENTR}
							 	kernel load/${TGET_INFO[1]}/${TGET_INFO[6]}
							
_EOT_
					fi
					;;
				winpe-*    | \
				ati2020x64 | \
				ati2020x86 )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					if [[ "${MENU_PATH}" =~ bios ]]; then
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${MENU_PATH}"
							label ${TGET_INFO[1]}
							 	menu label ^${MENU_ENTR}
							 	kernel memdisk
							 	append initrd=${HTTP_ADDR}/isos/${TGET_INFO[4]} iso raw
							
_EOT_
					fi
					;;
				hdt      | \
				shutdown | \
				restart  )
					if [[ ! "${MENU_PATH}" =~ bios ]]; then
						return
					fi
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${MENU_PATH}"
						label ${TGET_INFO[1]}
						 	menu label ^${MENU_ENTR}
						 	com32 ${TGET_INFO[6]}
						
_EOT_
					;;
				* )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					MENU_ENTR="$(printf "%-60.60s%20.20s" "- ${TGET_INFO[2]//%20/ }" "${TGET_INFO[10]} ${TGET_INFO[12]}")"
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${MENU_PATH}"
						label ${TGET_INFO[1]}
						 	menu label ^${MENU_ENTR}
						 	kernel load/${TGET_INFO[1]}/${TGET_INFO[7]}
						 	append initrd=load/${TGET_INFO[1]}/${TGET_INFO[6]} ${BOOT_OPTN} ---
						
_EOT_
					;;
			esac
			;;
		* )
			;;
	esac
}

# ----- create menu for grub --------------------------------------------------
function funcCreate_grub_cfg() {
	declare -r    MENU_DIRS="$1"							# menu directory
	declare -r -n MENU_NAME="$2"							# menu file name
	declare -r -n BOOT_OPTN="$3"							# boot option
	declare -r -n TGET_INFO="$4"							# media information
	declare -r -i TABS_CONT="$5"							# tabs count
	declare       TABS_STRS=""								# tabs string
	declare       MENU_PATH=""								# menu path
	declare       MENU_ENTR=""								# meny entry
	declare -i    I=0
#	funcPrintf "      create: ${TGET_INFO[2]//%20/ }"
	if [[ "${TABS_CONT}" -gt 0 ]]; then
		TABS_STRS="$(funcString "${TABS_CONT}" $'\t')"
	else
		TABS_STRS=""
	fi
	# --- create grub.cfg -----------------------------------------------------
	MENU_PATH="${MENU_DIRS}/${MENU_NAME[0]}"
	if [[ ! -f "${MENU_PATH}" ]] \
	|| [[ ! -s "${MENU_PATH}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${MENU_PATH}"
			set default="0"
			set timeout="-1"
			
			if [ "x\${feature_default_font_path}" = "xy" ] ; then
			 	font="unicode"
			else
			 	font="\${prefix}/font.pf2"
			fi
			
			if loadfont "\$font" ; then
			#	set lang="ja_JP"
			
			#	set gfxmode="7680x4320" # 8K UHD (16:9)
			#	set gfxmode="3840x2400" #        (16:10)
			#	set gfxmode="3840x2160" # 4K UHD (16:9)
			#	set gfxmode="2880x1800" #        (16:10)
			#	set gfxmode="2560x1600" #        (16:10)
			#	set gfxmode="2560x1440" # WQHD   (16:9)
			#	set gfxmode="1920x1440" #        (4:3)
			#	set gfxmode="1920x1200" # WUXGA  (16:10)
			#	set gfxmode="1920x1080" # FHD    (16:9)
			#	set gfxmode="1856x1392" #        (4:3)
			#	set gfxmode="1792x1344" #        (4:3)
			#	set gfxmode="1680x1050" # WSXGA+ (16:10)
			#	set gfxmode="1600x1200" # UXGA   (4:3)
			#	set gfxmode="1400x1050" #        (4:3)
			#	set gfxmode="1440x900"  # WXGA+  (16:10)
			#	set gfxmode="1360x768"  # HD     (16:9)
			#	set gfxmode="1280x1024" # SXGA   (5:4)
			#	set gfxmode="1280x960"  #        (4:3)
			#	set gfxmode="1280x800"  #        (16:10)
			#	set gfxmode="1280x768"  #        (4:3)
			#	set gfxmode="1280x720"  # WXGA   (16:9)
			#	set gfxmode="1152x864"  #        (4:3)
			#	set gfxmode="1024x768"  # XGA    (4:3)
			#	set gfxmode="800x600"   # SVGA   (4:3)
			#	set gfxmode="640x480"   # VGA    (4:3)
			 	set gfxmode="${MENU_RESO}"
			 	set gfxpayload="keep"
			
			 	if [ "\${grub_platform}" = "efi" ]; then
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
			
			set menu_color_normal="cyan/blue"
			set menu_color_highlight="white/blue"
			
			#export lang
			export gfxmode
			export gfxpayload
			export menu_color_normal
			export menu_color_highlight
			
			insmod play
			play 960 440 1 0 4 440 1
			
			source "\${prefix}/${MENU_NAME[1]}"
			
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
			
			if [ "\${grub_platform}" = "efi" ]; then
			 	menuentry '- Boot from next volume' {
			 		exit 1
			 	
			
			 	menuentry '- UEFI Firmware Settings' {
			 		fwsetup
			 	
			fi
_EOT_
	fi
	# --- create menu.cfg -----------------------------------------------------
	MENU_PATH="${MENU_DIRS}/${MENU_NAME[1]}"
	case "${TGET_INFO[0]}" in
		m )
			MENU_ENTR="[ ${TGET_INFO[2]//%20/ } ... ]"
			case "${TGET_INFO[2]}" in
				System%20command ) return;;
				-                ) echo "}"                        >> "${MENU_PATH}";;
				*                ) echo "submenu '${MENU_ENTR}' {" >> "${MENU_PATH}";;
			esac
			;;
		o )
			MENU_ENTR="$(printf "%-60.60s" "- ${TGET_INFO[2]//%20/ }")"
			case "${TGET_INFO[1]}" in
				windows-* )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${TABS_STRS}/g" >> "${MENU_PATH}"
						if [ "\${grub_platform}" = "pc" ]; then
						 	menuentry '${MENU_ENTR}' {
						 		echo 'Loading ${TGET_INFO[2]//%20/ } ...'
						 		insmod progress
						 		set isofile="(${HTTP_ADDR%%:*},${HTTP_ADDR##*/})/isos/${TGET_INFO[4]}"
						 		export isofile
						 		echo 'Loading linux ...'
						 		linux16 (tftp,\${net_default_server})/memdisk iso raw
						 		echo 'Loading initrd ...'
						 		initrd16 "\$isofile"
						 	}
						fi
_EOT_
					;;
				memtest86\+ )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${TABS_STRS}/g" >> "${MENU_PATH}"
						menuentry '${MENU_ENTR}' {
						 	echo 'Loading ${TGET_INFO[2]//%20/ } ...'
						 	if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
						 	insmod progress
						 	echo   'Loading linux ...'
						 	if [ "\${grub_platform}" = "efi" ]; then
						 		echo 'Loading UEFI Version ...'
						 		linux  (tftp,\${net_default_server})/load/${TGET_INFO[1]}/${TGET_INFO[6]}
						 	else
						 		echo 'Loading BIOS Version ...'
						 		linux  (tftp,\${net_default_server})/load/${TGET_INFO[1]}/${TGET_INFO[7]}
						 	fi
						}
_EOT_
					;;
				winpe-*    | \
				ati2020x64 | \
				ati2020x86 )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${TABS_STRS}/g" >> "${MENU_PATH}"
						if [ "\${grub_platform}" = "pc" ]; then
						 	menuentry '${MENU_ENTR}' {
						 		echo 'Loading ${TGET_INFO[2]//%20/ } ...'
						 		insmod progress
						 		set isofile="(${HTTP_ADDR%%:*},${HTTP_ADDR##*/})/isos/${TGET_INFO[4]}"
						 		export isofile
						 		echo 'Loading linux ...'
						 		linux16 (tftp,\${net_default_server})/memdisk iso raw
						 		echo 'Loading initrd ...'
						 		initrd16 "\$isofile"
						 	}
						fi
_EOT_
					;;
				hdt      | \
				shutdown | \
				restart  )
					;;
				* )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					MENU_ENTR="$(printf "%-60.60s%20.20s" "- ${TGET_INFO[2]//%20/ }" "${TGET_INFO[10]} ${TGET_INFO[12]}")"
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${TABS_STRS}/g" >> "${MENU_PATH}"
						menuentry '${MENU_ENTR}' {
						 	echo 'Loading ${TGET_INFO[2]//%20/ } ...'
_EOT_
					for ((I=0; I<"${#BOOT_OPTN[@]}"; I++))
					do
						if [[ "${BOOT_OPTN[I]}" =~ set\ svraddr ]]; then
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${TABS_STRS}/g" >> "${MENU_PATH}"
							 	${BOOT_OPTN[I]}
							 	if [ -n "\${net_default_server}" ]; then ${BOOT_OPTN[I]/svraddr/net_default_server}; fi
_EOT_
							continue
						fi
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${TABS_STRS}/g" >> "${MENU_PATH}"
							 	${BOOT_OPTN[I]}
_EOT_
					done
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${TABS_STRS}/g" >> "${MENU_PATH}"
						 	if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
						 	insmod progress
						 	echo 'Loading linux ...'
						 	linux  (tftp,\${net_default_server})/load/${TGET_INFO[1]}/${TGET_INFO[7]} \${options} ---
						 	echo 'Loading initrd ...'
						 	initrd (tftp,\${net_default_server})/load/${TGET_INFO[1]}/${TGET_INFO[6]}
						}
_EOT_
					;;
			esac
			;;
		* )
			;;
	esac
}

# ----- create menu for ipxe script -------------------------------------------
function funcCreate_autoexec_ipxe() {
	declare -r    MENU_DIRS="$1"							# menu directory
	declare -r -n MENU_NAME="$2"							# menu file name
	declare -r -n BOOT_OPTN="$3"							# boot option
	declare -r -n TGET_INFO="$4"							# media information
	declare -r -i TABS_CONT="$5"							# tabs count
	declare       TABS_STRS=""								# tabs string
	declare       WORK_STRS=""								# work string
	declare       MENU_PATH=""								# menu path
	declare       MENU_ENTR=""								# meny entry
	declare       MENU_TEXT=""								# meny text
#	declare -a    MENU_ARRY=()								# meny text
	declare -r -i MENU_SPCS=40
	declare -i    I=0
#	funcPrintf "      create: ${TGET_INFO[2]//%20/ }"
	if [[ "${TABS_CONT}" -gt 0 ]]; then
		TABS_STRS="$(funcString "${TABS_CONT}" $'\t')"
	else
		TABS_STRS=""
	fi
	# --- create autoexec.ipxe ------------------------------------------------
	MENU_PATH="${MENU_DIRS}/${MENU_NAME[0]}"
	if [[ ! -f "${MENU_PATH}" ]] \
	|| [[ ! -s "${MENU_PATH}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${MENU_PATH}"
			#!ipxe
			
			cpuid --ext 29 && set arch amd64 || set arch x86
			
			dhcp
			
			set optn-timeout 3000
			set menu-timeout 0
			isset \${menu-default} || set menu-default exit
			
			:start
			
			:menu
			menu Select the OS type you want to boot
			item --gap --                           --------------------------------------------------------------------------
			item --gap --                           [ System command ]
			item -- shell                           - iPXE shell
			#item -- shutdown                       - System shutdown
			item -- restart                         - System reboot
			item --gap --                           --------------------------------------------------------------------------
			choose --timeout \${menu-timeout} --default \${menu-default} selected || goto menu
			goto \${selected}
			
			:shell
			echo "Booting iPXE shell ..."
			shell
			goto start
			
			:shutdown
			echo "System shutting down ..."
			poweroff
			exit
			
			:restart
			echo "System rebooting ..."
			reboot
			exit
			
			:error
			prompt Press any key to continue
			exit
			
			:exit
			exit
_EOT_
	fi
	case "${TGET_INFO[0]}" in
		m )
			if [[ "${TGET_INFO[2]}" = "-" ]]; then
				return
			fi
			MENU_ENTR="[ ${TGET_INFO[2]//%20/ } ... ]"
			MENU_TEXT="$(printf "%-${MENU_SPCS}.${MENU_SPCS}s%s" "item --gap --" "${MENU_ENTR}")"
			sed -i "${MENU_PATH}" -e "/\[ System command \]/i ${MENU_TEXT}"
			;;
		o )
			MENU_ENTR="$(printf "%-60.60s" "- ${TGET_INFO[2]//%20/ }")"
			MENU_TEXT="$(printf "%-${MENU_SPCS}.${MENU_SPCS}s%s" "item -- ${TGET_INFO[1]}" "${MENU_ENTR}")"
			case "${TGET_INFO[1]}" in
				windows-* )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					sed -i "${MENU_PATH}" -e "/\[ System command \]/i ${MENU_TEXT}"
					MENU_TEXT="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
							:${TGET_INFO[1]}
							echo Loading ${TGET_INFO[2]//%20/ } ...
							set svraddr ${SRVR_ADDR}
							isset \${next-server} && set svraddr \${next-server} ||
							set cfgaddr http://\${svraddr}/conf/windows
							set knladdr http://\${svraddr}/imgs/${TGET_INFO[1]}
							echo Loading kernel and initrd ...
							kernel ipxe/wimboot
							initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
							initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
							initrd -n install.cmd \${cfgaddr}/inst_w${TGET_INFO[1]##*-}.cmd  install.cmd  || goto error
							initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
							initrd \${knladdr}/boot/bcd                     BCD          || goto error
							initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
							initrd -n boot.wim \${knladdr}/sources/boot.wim boot.wim     || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					sed -i "${MENU_PATH}" -e "/^:shell$/i ${MENU_TEXT}"
					;;
				winpe-*    | \
				ati2020x64 | \
				ati2020x86 )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					sed -i "${MENU_PATH}" -e "/\[ System command \]/i ${MENU_TEXT}"
					MENU_TEXT="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
							:${TGET_INFO[1]}
							echo Loading ${TGET_INFO[2]//%20/ } ...
							set svraddr ${SRVR_ADDR}
							isset \${next-server} && set svraddr \${next-server} ||
							set knladdr http://\${svraddr}/imgs/${TGET_INFO[1]}
							echo Loading kernel and initrd ...
							kernel ipxe/wimboot
							initrd \${knladdr}/Boot/BCD                     BCD      || goto error
							initrd \${knladdr}/Boot/boot.sdi                boot.sdi || goto error
							initrd -n boot.wim \${knladdr}/sources/boot.wim boot.wim || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					sed -i "${MENU_PATH}" -e "/^:shell$/i ${MENU_TEXT}"
					;;
				memtest86\+ )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					sed -i "${MENU_PATH}" -e "/\[ System command \]/i ${MENU_TEXT}"
					MENU_TEXT="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
							:${TGET_INFO[1]}
							echo Loading ${TGET_INFO[2]//%20/ } ...
							set svraddr ${SRVR_ADDR}
							isset \${next-server} && set svraddr \${next-server} ||
							set knladdr http://\${svraddr}/imgs/${TGET_INFO[1]}
							iseq \${platform} efi && set knlfile \${knladdr}/${TGET_INFO[6]} || set knlfile \${knladdr}/${TGET_INFO[7]}
							echo Loading kernel ...
							kernel \${knlfile} || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					sed -i "${MENU_PATH}" -e "/^:shell$/i ${MENU_TEXT}"
					;;
				* )
					if [[ ! -f "${DIRS_ISOS}/${TGET_INFO[4]}" ]]; then
						return
					fi
					if [[ "${TGET_INFO[8]#*/}" = "-" ]]; then
						TGET_INFO[1]="live-${TGET_INFO[1]}"
					fi
					# shellcheck disable=SC2312
					MENU_ENTR="$(printf "%-54.54s%20.20s" "- ${TGET_INFO[2]//%20/ } $(funcString 60 '.')" "${TGET_INFO[10]} ${TGET_INFO[12]}")"
					MENU_TEXT="$(printf "%-${MENU_SPCS}.${MENU_SPCS}s%s" "item -- ${TGET_INFO[1]}" "${MENU_ENTR}")"
					sed -i "${MENU_PATH}" -e "/\[ System command \]/i ${MENU_TEXT}"
					MENU_TEXT="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
							:${TGET_INFO[1]}
							echo Loading ${TGET_INFO[2]//%20/ } ...
_EOT_
					)"
					sed -i "${MENU_PATH}" -e "/^:shell$/i ${MENU_TEXT}"
					for ((I=0; I<"${#BOOT_OPTN[@]}"; I++))
					do
						MENU_TEXT="$(
							if [[ "${BOOT_OPTN[I]}" =~ set\ svraddr ]]; then
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
									${BOOT_OPTN[I]}
									isset \${next-server} && ${BOOT_OPTN[I]/${SRVR_ADDR}/\$\{next-server\}} ||
_EOT_
							else
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
										${BOOT_OPTN[I]}
_EOT_
							fi
						)"
						if [[ -n "${MENU_TEXT##* }" ]]; then
							sed -i "${MENU_PATH}" -e "/^:shell\$/i ${MENU_TEXT}"
						fi
					done
					MENU_TEXT="$(
						if [[ "${TGET_INFO[5]}" = "." ]]; then
							WORK_STRS="\${knladdr}"
						else
							WORK_STRS="\${knladdr}/${TGET_INFO[5]}"
						fi
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
							form                                    Configure Boot Options
							item options                            Boot Options
							present ||
							echo Loading kernel and initrd ...
							kernel ${WORK_STRS}/${TGET_INFO[7]} \${options} --- || goto error
							initrd ${WORK_STRS}/${TGET_INFO[6]} || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					sed -i "${MENU_PATH}" -e "/^:shell$/i ${MENU_TEXT}"
					;;
			esac
			;;
		* )
			;;
	esac
}

# === call function ===========================================================

# ---- function test ----------------------------------------------------------
function funcCall_function() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call function test"
	declare -r    FILE_WRK1="${DIRS_TEMP}/testfile1.txt"
	declare -r    FILE_WRK2="${DIRS_TEMP}/testfile2.txt"
	declare -r    HTTP_ADDR="https://raw.githubusercontent.com/office-itou/Linux/master/Readme.md"
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
	declare -i    I=0
	declare       H1=""
	declare       H2=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_WRK1}"
		line 1
		line 2
		line 3
_EOT_
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_WRK2}"
		line 1
		Line 2
		line 3
_EOT_

	# --- text print test -----------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- text print test $(funcString "${COLS_SIZE}" '-')"
	H1=""
	H2=""
	for ((I=1; I<="${COLS_SIZE}"+10; I++))
	do
		if [[ $((I % 10)) -eq 0 ]]; then
			H1+="         $((I%100/10))"
		fi
		H2+="$((I%10))"
	done
	funcPrintf "${H1}"
	funcPrintf "${H2}"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '->')"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '→')"
	echo ""

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
	COMD_RETN="${COMD_LIST[*]:-}"
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
			cmd )						# ==== create preseed kill dhcp / late command
				funcCreate_preseed_kill_dhcp
				funcCreate_late_command
				;;
			preseed )					# ==== create preseed.cfg =============
				funcCreate_preseed_cfg
				;;
			nocloud )					# ==== create nocloud =================
				funcCreate_nocloud
				;;
			kickstart )					# ==== create kickstart.cfg ===========
				funcCreate_kickstart
				;;
			autoyast )					# ==== create autoyast.xml ============
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
	COMD_RETN="${COMD_LIST[*]:-}"
}

# ---- create -----------------------------------------------------------------
function funcCall_create() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call create"
	declare -n    COMD_RETN="$1"
#	shift 2
#	declare -a    COMD_LIST=("$@")
#	declare -r -a COMD_ENUM=("mini" "net" "dvd" "live" "tool")
#	declare       WORK_PARM=""
#	declare       WORK_ENUM=""
	declare       WORK_LINE=""
	declare       WORK_FILE=""
	declare -a    DATA_LIST=(  \
		"${DATA_LIST_MINI[@]}" \
		"${DATA_LIST_NET[@]}"  \
		"${DATA_LIST_DVD[@]}"  \
		"${DATA_LIST_INST[@]}" \
		"${DATA_LIST_LIVE[@]}" \
		"${DATA_LIST_TOOL[@]}" \
		"${DATA_LIST_SCMD[@]}" \
	)
	declare -a    DATA_LINE=()
	declare -r    DIRS_GRUB="boot/grub"						# grub directory
	declare -r    BOOT_PXE0="pxelinux.0"					# pxeboot module for bios
	declare -r    BOOT_UEFI="bootx64.efi"					# pxeboot module for uefi
	declare -r -a MENU_GRUB=("grub.cfg" "menu.cfg")			# grub.cfg / menu.cfg
	declare -r -a MENU_SLNX=("syslinux.cfg")				# syslinux.cfg
	declare -r -a MENU_IPXE=("../autoexec.ipxe")			# autoexec.ipxe
	declare       MENU_DIRS=""								# menu directory
	declare       MENU_PATH=""								# menu file path
	declare -a    BOOT_ARRY=()								# boot option array
	declare       BOOT_OPTN=""								# boot option (syslinux)
	declare -a    BOOT_GRUB=()								# boot option (grub)
	declare -a    BOOT_IPXE=()								# boot option (ipxe)
	declare       COMD_NAME="grub-mkimage"					# debian / ubuntu
	declare -i    COMD_INST=0								# command install skip or forced
	declare -r -a MODU_LIST=( \
		"all_video" "boot" "btrfs" "cat" "chain" "configfile" "echo" \
		"ext2" "fat" "font" "gettext" "gfxmenu" "gfxterm" \
		"gfxterm_background" "gzio" "halt" "help" "hfsplus" "http" \
		"iso9660" "jpeg" "keystatus" "linux" "loadenv" "loopback" \
		"ls" "lvm" "memdisk" "minicmd" "nativedisk" "net" "normal" \
		"ntfs" "part_apple" "part_gpt" "part_msdos" "password_pbkdf2" \
		"png" "probe" "progress" "reboot" "regexp" "search" \
		"search_fs_file" "search_fs_uuid" "search_label" "sleep" \
		"smbios" "squash4" "test" "tftp" "true" "udf" "video" \
		"xfs" "zfs" "zfscrypt" "zfsinfo" \
	)
	declare -r -a CURL_OPTN=("--location" "--http1.1" "--progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare       FILE_PATH=""
	declare -a    FILE_INFO=()
	declare       FILE_SIZE=""
	declare       FILE_TIME=""
	declare -i    TABS_CONT=0
	declare -i    I=0
#	declare -i    J=0
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	funcPrintf "      create: syslinux /grub menu file"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v "${COMD_NAME}" 2> /dev/null)" ]]; then
		COMD_NAME="grub2-mkimage"
	fi
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("cmd" "menu" "$@")
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
			cmd )						# ==== create system command
				case "${2:-}" in
					F | force ) COMD_INST=1; shift;;
					* ) ;;
				esac
				for MENU_DIRS in "${DIRS_TFTP}/"{menu-{bios,efi64},${DIRS_GRUB},ipxe}
				do
					if [[ "${COMD_INST}" -eq 0 ]]; then
						funcPrintf "        copy: ${MENU_DIRS##*/}"
					else
						funcPrintf " forced copy: ${MENU_DIRS##*/}"
					fi
					mkdir -p "${MENU_DIRS}"
					case "${MENU_DIRS}" in
						*bios )
#							for ((I=0; I<"${#MENU_SLNX[@]}"; I++))
#							do
#								: > "${MENU_DIRS}/${MENU_SLNX[I]}"
#							done
							if [[ "${COMD_INST}" -ne 0 ]] || [[ ! -f "${MENU_DIRS}/pxelinux.0" ]]; then
								if [[ -d /usr/lib/syslinux/modules/bios/. ]]; then
									cp --archive --update /usr/lib/syslinux/memdisk         "${MENU_DIRS}/"
									cp --archive --update /usr/lib/syslinux/modules/bios/.  "${MENU_DIRS}/"
									cp --archive --update /usr/lib/PXELINUX/.               "${MENU_DIRS}/"
								else
									cp --archive --update /usr/share/syslinux/memdisk       "${MENU_DIRS}/"
									cp --archive --update /usr/share/syslinux/.             "${MENU_DIRS}/"
								fi
							fi
							;;
						*efi32)
#							for ((I=0; I<"${#MENU_SLNX[@]}"; I++))
#							do
#								: > "${MENU_DIRS}/${MENU_SLNX[I]}"
#							done
							if [[ "${COMD_INST}" -ne 0 ]] || [[ ! -f "${MENU_DIRS}/syslinux.efi" ]]; then
								if [[ -d /usr/lib/syslinux/modules/efi32/. ]]; then
									cp --archive --update /usr/lib/syslinux/modules/efi32/. "${MENU_DIRS}/"
									cp --archive --update /usr/lib/SYSLINUX.EFI/efi32/.     "${MENU_DIRS}/"
								fi
							fi
							;;
						*efi64)
#							for ((I=0; I<"${#MENU_SLNX[@]}"; I++))
#							do
#								: > "${MENU_DIRS}/${MENU_SLNX[I]}"
#							done
							if [[ "${COMD_INST}" -ne 0 ]] || [[ ! -f "${MENU_DIRS}/syslinux.efi" ]]; then
								if [[ -d /usr/lib/syslinux/modules/efi64/. ]]; then
									cp --archive --update /usr/lib/syslinux/modules/efi64/. "${MENU_DIRS}/"
									cp --archive --update /usr/lib/SYSLINUX.EFI/efi64/.     "${MENU_DIRS}/"
								fi
							fi
							;;
						*grub )
#							for ((I=0; I<"${#MENU_GRUB[@]}"; I++))
#							do
#								: > "${MENU_DIRS}/${MENU_GRUB[I]}"
#							done
							if [[ "${COMD_INST}" -ne 0 ]] \
							|| [[ ! -f "${MENU_DIRS}/x86_64-efi/grub.cfg" ]] \
							|| [[ ! -f "${MENU_DIRS}/i386-pc/grub.cfg"    ]]; then
								mkdir -p "${DIRS_TFTP}/boot/grub/"{fonts,locale,i386-pc,x86_64-efi}
								if [[ -f /usr/lib/syslinux/memdisk ]]; then
									cp --archive --update /usr/lib/syslinux/memdisk "${DIRS_TFTP}/"
									cp --archive --update /usr/lib/syslinux/memdisk "${DIRS_HTML}/"
									grub-mknetdir --net-directory="${DIRS_TFTP}" --subdir="${DIRS_GRUB}"
								else
									cp --archive --update /usr/share/syslinux/memdisk "${DIRS_TFTP}/"
									cp --archive --update /usr/share/syslinux/memdisk "${DIRS_HTML}/"
									cp --archive --update /usr/lib/grub/i386-pc/.     "${MENU_DIRS}/i386-pc/"
									cp --archive --update /usr/lib/grub/x86_64-efi/.  "${MENU_DIRS}/x86_64-efi/"
									cp --archive --update /usr/share/grub/*.pf2       "${MENU_DIRS}/fonts/"
								fi
							fi
							# -------------------------------------------------
							mkdir -p "${DIRS_TEMP}"
							WORK_FILE="${DIRS_TEMP}/setvars.conf"
							cat <<- _EOT_ | sed 's/^ *//g' > "${WORK_FILE}"
								set net_default_server="${HTTP_ADDR#*://}"
_EOT_
							# -------------------------------------------------
							if [[ "${COMD_INST}" -ne 0 ]] || [[ ! -f "${MENU_DIRS}/${BOOT_PXE0}"  ]]; then
								"${COMD_NAME}" \
								    --directory=/usr/lib/grub/i386-pc \
								    --format=i386-pc-pxe \
								    --output="${MENU_DIRS}/${BOOT_PXE0}" \
								    --prefix="(tftp,${HTTP_ADDR#*://})/boot/grub" \
								    --compression=auto \
								    --config="${WORK_FILE}" \
								    "${MODU_LIST[@]}" cpuid play pxe vga
							fi
							# -------------------------------------------------
							if [[ "${COMD_INST}" -ne 0 ]] || [[ ! -f "${MENU_DIRS}/${BOOT_UEFI}" ]]; then
								"${COMD_NAME}" \
								    --directory=/usr/lib/grub/x86_64-efi \
								    --format=x86_64-efi \
								    --output="${MENU_DIRS}/${BOOT_UEFI}" \
								    --prefix="(tftp,${HTTP_ADDR#*://})/boot/grub" \
								    --compression=auto \
								    --config="${WORK_FILE}" \
								    "${MODU_LIST[@]}" cpuid play tpm efifwsetup efinet lsefi lsefimmap lsefisystab lssal
							fi
							;;
						*ipxe )
#							for ((I=0; I<"${#MENU_IPXE[@]}"; I++))
#							do
#								: > "${MENU_DIRS}/${MENU_IPXE[I]}"
#							done
							if [[ "${COMD_INST}" -ne 0 ]] \
							|| [[ ! -f "${MENU_DIRS}/undionly.kpxe" ]] \
							|| [[ ! -f "${MENU_DIRS}/ipxe.efi"      ]]; then
								rm -f "${MENU_DIRS}/"{undionly.kpxe,ipxe.efi,wimboot}
								mkdir -p "${DIRS_TEMP}"
#								pushd "${DIRS_TEMP}" > /dev/null
#									# shellcheck disable=SC2312
#									if [[ -n "$(command -v apt-get 2> /dev/null)" ]]; then
#										apt-get -qq download ipxe 2> /dev/null
#										dpkg -x ipxe_*_all.deb ipxe
#										cp -a ipxe/usr/lib/ipxe/undionly.kpxe "${MENU_DIRS}"
#										cp -a ipxe/boot/ipxe.efi              "${MENU_DIRS}"
#									fi
#								popd  > /dev/null
							fi
							if [[ ! -f "${MENU_DIRS}/undionly.kpxe" ]]; then
								curl "${CURL_OPTN[@]}" --remote-name --create-dirs --output-dir "${MENU_DIRS}" "https://boot.ipxe.org/undionly.kpxe"
							fi
							if [[ ! -f "${MENU_DIRS}/ipxe.efi"      ]]; then
								curl "${CURL_OPTN[@]}" --remote-name --create-dirs --output-dir "${MENU_DIRS}" "https://boot.ipxe.org/ipxe.efi"
							fi
							if [[ ! -f "${MENU_DIRS}/wimboot"       ]]; then
								curl "${CURL_OPTN[@]}" --remote-name --create-dirs --output-dir "${MENU_DIRS}" "https://github.com/ipxe/wimboot/releases/latest/download/wimboot"
							fi
							;;
						* )
							;;
					esac
				done
				;;
			menu )						# ==== create menu fle
				for MENU_DIRS in "${DIRS_TFTP}/"{menu-{bios,efi64},${DIRS_GRUB},ipxe}
				do
					mkdir -p "${MENU_DIRS}"
					case "${MENU_DIRS}" in
						*bios )
							for ((I=0; I<"${#MENU_SLNX[@]}"; I++))
							do
								: > "${MENU_DIRS}/${MENU_SLNX[I]}"
							done
							;;
						*efi32)
							for ((I=0; I<"${#MENU_SLNX[@]}"; I++))
							do
								: > "${MENU_DIRS}/${MENU_SLNX[I]}"
							done
							;;
						*efi64)
							for ((I=0; I<"${#MENU_SLNX[@]}"; I++))
							do
								: > "${MENU_DIRS}/${MENU_SLNX[I]}"
							done
							;;
						*grub )
							for ((I=0; I<"${#MENU_GRUB[@]}"; I++))
							do
								: > "${MENU_DIRS}/${MENU_GRUB[I]}"
							done
							;;
						*ipxe )
							for ((I=0; I<"${#MENU_IPXE[@]}"; I++))
							do
								: > "${MENU_DIRS}/${MENU_IPXE[I]}"
							done
							;;
						* )
							;;
					esac
				done
				# -------------------------------------------------------------
				for ((I=0; I<"${#DATA_LIST[@]}"; I++))
				do
					read -r -a DATA_LINE < <(echo "${DATA_LIST[I]}")
					FILE_PATH="${DIRS_ISOS}/${DATA_LINE[4]}"
#					if [[ "${DATA_LINE[0]}" != "o" ]] || [[ ! -f "${FILE_PATH}" ]]; then
#						continue
#					fi
					if [[ "${DATA_LINE[0]}" = "o" ]] && [[ -f "${FILE_PATH}" ]]; then
						# --- copy iso contents to hdd ------------------------
						funcCreate_copy_iso2hdd "${DATA_LINE[@]}"
						# --- file information --------------------------------
						# shellcheck disable=SC2312
						read -r -a FILE_INFO < <(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${FILE_PATH}")
						FILE_SIZE="${FILE_INFO[4]}"
						FILE_TIME="${FILE_INFO[5]}"
						DATA_LINE[10]="${FILE_TIME:0:4}-${FILE_TIME:4:2}-${FILE_TIME:6:2}"
						DATA_LINE[12]="${FILE_TIME:8:2}:${FILE_TIME:10:2}:${FILE_TIME:12:2}"
						DATA_LINE[13]="${FILE_SIZE}"
						DATA_LIST[I]="${DATA_LINE[*]}"
					fi
					# --- create menu -----------------------------------------
					BOOT_ARRY=()
					# shellcheck disable=SC2312
					case "${DATA_LINE[1]%%-*}" in
						menu         ) ;;
						debian       | \
						ubuntu       ) 
							# shellcheck disable=SC2312
							case "${DATA_LINE[8]%%/*}" in
								preseed* ) while IFS='' read -r WORK_LINE; do BOOT_ARRY+=("${WORK_LINE}"); done < <(funcCreate_menu_cfg_preseed "${DATA_LINE[@]}");;
								nocloud* ) while IFS='' read -r WORK_LINE; do BOOT_ARRY+=("${WORK_LINE}"); done < <(funcCreate_menu_cfg_nocloud "${DATA_LINE[@]}");;
								*        ) funcPrintf "not supported on ${DATA_LINE[1]}"; exit 1;;
							esac
							;;
						fedora       | \
						centos       | \
						almalinux    | \
						miraclelinux | \
						rockylinux   ) while IFS='' read -r WORK_LINE; do BOOT_ARRY+=("${WORK_LINE}"); done < <(funcCreate_menu_cfg_kickstart "${DATA_LINE[@]}");;
						opensuse     ) while IFS='' read -r WORK_LINE; do BOOT_ARRY+=("${WORK_LINE}"); done < <(funcCreate_menu_cfg_autoyast "${DATA_LINE[@]}");;
						windows      ) ;;
						memtest86\+  ) ;;
						winpe        | \
						ati2020x64   | \
						ati2020x86   ) ;;
						hdt          | \
						shutdown     | \
						restart      ) ;;
						*            )				# --- not supported -------
							funcPrintf "not supported on ${DATA_LINE[1]}"
							exit 1
							;;
					esac
					IFS="${OLD_IFS}"
					# ---------------------------------------------------------
					BOOT_OPTN=""
					BOOT_GRUB=()
					BOOT_IPXE=()
					for ((J=0; J<"${#BOOT_ARRY[@]}"; J++))
					do
						case "${J}" in
							0 ) BOOT_OPTN="${BOOT_ARRY[J]}";;
							* ) BOOT_GRUB+=("${BOOT_ARRY[J]}")
							    BOOT_IPXE+=("${BOOT_ARRY[J]}");;
						esac
					done
					# ---------------------------------------------------------
					if [[ "${DATA_LINE[0]}" = "m" ]]; then
						if [[ "${DATA_LINE[2]}" = "-" ]]; then
							TABS_CONT=$(("${TABS_CONT}" - 1))
						else
							TABS_CONT=$(("${TABS_CONT}" + 1))
						fi
					fi
					if [[ "${TABS_CONT}" -lt 0 ]]; then
						TABS_CONT=0
					fi
					# ---------------------------------------------------------
					for MENU_DIRS in "${DIRS_TFTP}/"{menu-{bios,efi64},boot/grub,ipxe}
					do
						case "${MENU_DIRS}" in
							*bios | \
							*efi32| \
							*efi64) funcCreate_syslinux_cfg  "${MENU_DIRS}" MENU_SLNX "${BOOT_OPTN}" DATA_LINE "${TABS_CONT}";;
							*grub ) funcCreate_grub_cfg      "${MENU_DIRS}" MENU_GRUB    BOOT_GRUB   DATA_LINE "${TABS_CONT}";;
							*ipxe ) funcCreate_autoexec_ipxe "${MENU_DIRS}" MENU_IPXE    BOOT_IPXE   DATA_LINE "${TABS_CONT}";;
							*     ) ;;
						esac
					done
				done
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
	COMD_RETN="${COMD_LIST[*]:-}"
	# -------------------------------------------------------------------------
	rm -rf "${DIRS_TEMP:?}"
}

# === main ====================================================================

function funcMain() {
#	declare -r    OLD_IFS="${IFS}"
	declare -i    start_time=0
	declare -i    end_time=0
	declare -i    I=0
	declare -a    COMD_LINE=("${PROG_PARM[@]}")
	declare -a    DIRS_LIST=()
	declare       DIRS_NAME=""
	declare       PSID_NAME=""

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
	renice -n "${NICE_VALU}"   -p "$$" > /dev/null
	ionice -c "${IONICE_CLAS}" -p "$$"
	# -------------------------------------------------------------------------
	DIRS_LIST=()
	for DIRS_NAME in "${DIRS_TEMP%.*}."*
	do
		if [[ ! -d "${DIRS_NAME}/." ]]; then
			continue
		fi
		PSID_NAME="$(ps --pid "${DIRS_NAME##*.}" --format comm= || true)"
		if [[ -z "${PSID_NAME:-}" ]]; then
			DIRS_LIST+=("${DIRS_NAME}")
		fi
	done
	if [[ "${#DIRS_LIST[@]}" -gt 0 ]]; then
		funcPrintf "remove unnecessary temporary directories"
		rm -rf "${DIRS_LIST[@]}"
	fi
	# -------------------------------------------------------------------------
	if [[ -z "${PROG_PARM[*]}" ]]; then
		funcPrintf "sudo ./${PROG_NAME} [ options ]"
		funcPrintf "debug print and test (empty is [ options ])"
		funcPrintf "  -d | --debug [ options ]"
		funcPrintf "    func    function test"
		funcPrintf "    text    text color test"
		funcPrintf "create symbolic link"
		funcPrintf "  -l | --link"
		funcPrintf "create config files"
		funcPrintf "  --conf [ options ]"
		funcPrintf "    cmd         preseed kill dhcp / sub command"
		funcPrintf "    preseed     preseed.cfg"
		funcPrintf "    nocloud     nocloud"
		funcPrintf "    kickstart   kickstart.cfg"
		funcPrintf "    autoyast    autoyast.xml"
		funcPrintf "create pxeboot environment"
		funcPrintf "  --create"
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
					funcCreate_directory
					funcCreate_link
					shift
					COMD_LINE=("${@:-}")
					;;
				--conf )
					funcCall_config COMD_LINE "$@"
					;;
				--create )
					if [[ ! -d "${DIRS_TFTP}/." ]]; then
						funcCreate_directory
#						funcCreate_link
					fi
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

	rm -rf "${DIRS_TEMP:?}"
	# ==== complete ===========================================================
	# shellcheck disable=SC2312
	funcPrintf "--- complete $(funcString "${COLS_SIZE}" '-')"
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing end${TXT_RESET}"
	end_time=$(date +%s)
#	funcPrintf "elapsed time: $((end_time-start_time)) [sec]"
	funcPrintf "elapsed time: %dd%02dh%02dm%02ds\n" $(((end_time-start_time)/86400)) $(((end_time-start_time)%86400/3600)) $(((end_time-start_time)%3600/60)) $(((end_time-start_time)%60))
}

# *** main processing section *************************************************
	funcMain
	exit 0

### eof #######################################################################
