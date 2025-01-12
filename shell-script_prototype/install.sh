#!/bin/bash
###############################################################################
##
##	initial configuration shell
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

	case "${1:-}" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
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

	# -------------------------------------------------------------------------
	CODE_NAME="$(sed -ne '/VERSION_CODENAME/ s/^.*=//p' /etc/os-release)"
	declare -r    CODE_NAME

	if command -v apt-get > /dev/null 2>&1; then
		if ! ls /var/lib/apt/lists/*_"${CODE_NAME:-}"_InRelease > /dev/null 2>&1; then
			echo "please execute apt-get update:"
			if [[ "${0:-}" = "${SUDO_COMMAND:-}" ]]; then
				echo -n "sudo "
			fi
			echo "apt-get update"
			exit 1
		fi
		# ---------------------------------------------------------------------
		declare -r -a APP_TGET=(\
			"bind9-dnsutils" \
			"samba-common-bin" \
		)
		case "$(arch)" in
			x86_64) CPU_ARCH="amd64";;
			*     ) CPU_ARCH="";;
		esac
		declare -r -a APP_FIND=("$(LANG=C apt list "${APP_TGET[@]}" 2> /dev/null | sed -ne '/'"${CPU_ARCH:-"amd64"}"'/{' -e '/^[ \t]*$\|WARNING\|Listing\|installed/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g')")
		declare -a    APP_LIST=()
		for I in  "${!APP_FIND[@]}"
		do
			APP_LIST+=("${APP_FIND[${I}]}")
		done
		if [[ -n "${APP_LIST[*]}" ]]; then
			echo "please install these:"
			if [[ "${0:-}" = "${SUDO_COMMAND:-}" ]]; then
				echo -n "sudo "
			fi
			echo "apt-get install ${APP_LIST[*]}"
			exit 1
		fi
	fi

# *** data section ************************************************************

# --- working directory name --------------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    DIRS_WORK="${PWD}/${PROG_NAME%.*}"
	if [[ "${DIRS_WORK}" = "/" ]]; then
		echo "terminate the process because the working directory is root"
		exit 1
	fi
	declare -r    DIRS_ARCH="${DIRS_WORK=}/arch"
	declare -r    DIRS_BACK="${DIRS_WORK=}/back"
	declare -r    DIRS_ORIG="${DIRS_WORK=}/orig"
	declare -r    DIRS_TEMP="${DIRS_WORK=}/temp"

# --- work variables ----------------------------------------------------------
	declare -r    OLD_IFS="${IFS}"

# --- set minimum display size ------------------------------------------------
	declare -i    ROWS_SIZE=80
	declare -i    COLS_SIZE=25
	declare       TEXT_GAP1=""
	declare       TEXT_GAP2=""

# --- set parameters ----------------------------------------------------------

	# === system ==============================================================

	# --- base language -------------------------------------------------------
	declare -r    LANG_BASE="ja_JP.UTF-8"

	# --- os information ------------------------------------------------------
	declare       DIST_NAME=""			# distribution name (ex. debian)
	declare       DIST_CODE=""			# code name         (ex. bookworm)
	declare       DIST_VERS=""			# version name      (ex. 12 (bookworm))
	declare       DIST_VRID=""			# version number    (ex. 12)

	# --- package manager -----------------------------------------------------
	declare       PKGS_MNGR=""			# package manager   (ex. apt-get | dnf | zypper)
	declare -a    PKGS_OPTN=()			# package manager option

	# --- screen size ---------------------------------------------------------
#	declare -r    SCRN_SIZE="7680x4320"	# 8K UHD (16:9)
#	declare -r    SCRN_SIZE="3840x2400"	#        (16:10)
#	declare -r    SCRN_SIZE="3840x2160"	# 4K UHD (16:9)
#	declare -r    SCRN_SIZE="2880x1800"	#        (16:10)
#	declare -r    SCRN_SIZE="2560x1600"	#        (16:10)
#	declare -r    SCRN_SIZE="2560x1440"	# WQHD   (16:9)
#	declare -r    SCRN_SIZE="1920x1440"	#        (4:3)
#	declare -r    SCRN_SIZE="1920x1200"	# WUXGA  (16:10)
#	declare -r    SCRN_SIZE="1920x1080"	# FHD    (16:9)
#	declare -r    SCRN_SIZE="1856x1392"	#        (4:3)
#	declare -r    SCRN_SIZE="1792x1344"	#        (4:3)
	declare -r    SCRN_SIZE="1680x1050"	# WSXGA+ (16:10)
#	declare -r    SCRN_SIZE="1600x1200"	# UXGA   (4:3)
#	declare -r    SCRN_SIZE="1400x1050"	#        (4:3)
#	declare -r    SCRN_SIZE="1440x900"	# WXGA+  (16:10)
#	declare -r    SCRN_SIZE="1360x768"	# HD     (16:9)
#	declare -r    SCRN_SIZE="1280x1024"	# SXGA   (5:4)
#	declare -r    SCRN_SIZE="1280x960"	#        (4:3)
#	declare -r    SCRN_SIZE="1280x800"	#        (16:10)
#	declare -r    SCRN_SIZE="1280x768"	#        (4:3)
#	declare -r    SCRN_SIZE="1280x720"	# WXGA   (16:9)
#	declare -r    SCRN_SIZE="1152x864"	#        (4:3)
#	declare -r    SCRN_SIZE="1024x768"	# XGA    (4:3)
#	declare -r    SCRN_SIZE="800x600"	# SVGA   (4:3)
#	declare -r    SCRN_SIZE="640x480"	# VGA    (4:3)

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

	# === screen mode (vga=nnn) [ VMware ] ====================================
															# Mode:	Resolution:		Type
#	declare -r    SCRN_MODE="3840"							# 0	F00	  80x  25		VGA
#	declare -r    SCRN_MODE="3841"							# 1	F01	  80x  50		VGA
#	declare -r    SCRN_MODE="3842"							# 2	F02	  80x  43		VGA
#	declare -r    SCRN_MODE="3843"							# 3	F03	  80x  28		VGA
#	declare -r    SCRN_MODE="3845"							# 4	F05	  80x  30		VGA
#	declare -r    SCRN_MODE="3846"							# 5	F06	  80x  34		VGA
#	declare -r    SCRN_MODE="3847"							# 6	F07	  80x  60		VGA
#	declare -r    SCRN_MODE="768"							# 7	300	 640x 400x 8	VESA
#	declare -r    SCRN_MODE="769"							# 8	301	 640x 480x 8	VESA
#	declare -r    SCRN_MODE="771"							# 9	303	 800x 600x 8	VESA
#	declare -r    SCRN_MODE="773"							# a	305	1024x 768x 8	VESA
#	declare -r    SCRN_MODE="782"							# b	30E	 320x 200x16	VESA
#	declare -r    SCRN_MODE="785"							# c	311	 640x 480x16	VESA
#	declare -r    SCRN_MODE="788"							# d	314	 800x 600x16	VESA
#	declare -r    SCRN_MODE="791"							# e	317	1024x 768x16	VESA
#	declare -r    SCRN_MODE="800"							# f	320	 320x 200x 8	VESA
#	declare -r    SCRN_MODE="801"							# g	321	 320x 400x 8	VESA
#	declare -r    SCRN_MODE="802"							# h	322	 640x 400x 8	VESA
#	declare -r    SCRN_MODE="803"							# i	323	 640x 480x 8	VESA
#	declare -r    SCRN_MODE="804"							# j	324	 800x 600x 8	VESA
#	declare -r    SCRN_MODE="805"							# k	325	1024x 768x 8	VESA
#	declare -r    SCRN_MODE="806"							# l	326	1152x 864x 8	VESA
#	declare -r    SCRN_MODE="814"							# m	32E	 320x 200x16	VESA
#	declare -r    SCRN_MODE="815"							# n	32F	 320x 400x16	VESA
#	declare -r    SCRN_MODE="816"							# o	330	 640x 400x16	VESA
#	declare -r    SCRN_MODE="817"							# p	331	 640x 480x16	VESA
#	declare -r    SCRN_MODE="818"							# q	332	 800x 600x16	VESA
#	declare -r    SCRN_MODE="819"							# r	333	1024x 768x16	VESA
#	declare -r    SCRN_MODE="820"							# s	334	1152x 864x16	VESA
#	declare -r    SCRN_MODE="828"							# t	33C	 320x 200x32	VESA
#	declare -r    SCRN_MODE="829"							# u	33D	 320x 400x32	VESA
#	declare -r    SCRN_MODE="830"							# v	33E	 640x 400x32	VESA
#	declare -r    SCRN_MODE="831"							# w	33F	 640x 480x32	VESA
#	declare -r    SCRN_MODE="832"							# x	340	 800x 600x32	VESA
#	declare -r    SCRN_MODE="833"							# y	341	1024x 768x32	VESA
#	declare -r    SCRN_MODE="834"							# z	342	1152x 864x32	VESA
#	declare -r    SCRN_MODE="854"							# -	356	 320x 240x 8	VESA
#	declare -r    SCRN_MODE="855"							# -	357	 320x 240x16	VESA
#	declare -r    SCRN_MODE="856"							# -	358	 320x 240x32	VESA
#	declare -r    SCRN_MODE="857"							# -	359	 400x 300x 8	VESA
#	declare -r    SCRN_MODE="858"							# -	35A	 400x 300x16	VESA
#	declare -r    SCRN_MODE="859"							# -	35B	 400x 300x32	VESA
#	declare -r    SCRN_MODE="860"							# -	35C	 512x 384x 8	VESA
#	declare -r    SCRN_MODE="861"							# -	35D	 512x 384x16	VESA
#	declare -r    SCRN_MODE="862"							# -	35E	 512x 384x32	VESA
#	declare -r    SCRN_MODE="863"							# -	35F	 854x 480x 8	VESA
#	declare -r    SCRN_MODE="864"							# -	360	 854x 480x16	VESA
#	declare -r    SCRN_MODE="865"							# -	361	 854x 480x32	VESA
#	declare -r    SCRN_MODE="878"							# -	36E	 720x 480x 8	VESA
#	declare -r    SCRN_MODE="879"							# -	36F	 720x 480x16	VESA
#	declare -r    SCRN_MODE="880"							# -	370	 720x 480x32	VESA
#	declare -r    SCRN_MODE="881"							# -	371	 720x 576x 8	VESA
#	declare -r    SCRN_MODE="882"							# -	372	 720x 576x16	VESA
#	declare -r    SCRN_MODE="883"							# -	373	 720x 576x32	VESA
#	declare -r    SCRN_MODE="884"							# -	374	 800x 480x 8	VESA
#	declare -r    SCRN_MODE="885"							# -	375	 800x 480x16	VESA
#	declare -r    SCRN_MODE="886"							# -	376	 800x 480x32	VESA

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

	# --- user information ----------------------------------------------------
	# USER_LIST
	#  0: status flag (a:add, s: skip, e: error, o: export)
	#  1: administrator flag (1: sambaadmin)
	#  2: full name
	#  3: user name
	#  4: user password (unused)
	#  5: user id
	#  6: lanman password
	#  7: nt password
	#  8: account flags
	#  9:last change time
	# sample: administrator's password="password"
	declare -a    USER_LIST=( \
		"a:1:Administrator:administrator:unused:1001:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:8846F7EAEE8FB117AD06BDD830B7586C:[U          ]:LCT-00000000:" \
	)	#0:1:2            :3            :4     :5   :6                               :7                               :8            :9
	declare -r    FILE_USER="${PROG_DIRS}/${PROG_NAME}.user.lst"

	# --- samba ---------------------------------------------------------------
	# funcApplication_system creates directory
	#
	# tree diagram
	#   /share/
	#   |-- cifs
	#   |-- data
	#   |   |-- adm
	#   |   |   |-- netlogon
	#   |   |   |   `-- logon.bat
	#   |   |   `-- profiles
	#   |   |-- arc
	#   |   |-- bak
	#   |   |-- pub
	#   |   `-- usr
	#   `-- dlna
	#       |-- movies
	#       |-- others
	#       |-- photos
	#       `-- sounds

	declare -r    DIRS_SHAR="/share"		# root of shared directory
	declare -r    SAMB_USER="sambauser"		# force user
	declare -r    SAMB_GRUP="sambashare"	# force group
	declare -r    SAMB_GADM="sambaadmin"	# admin group

	# --- open-vm-tools -------------------------------------------------------
	if [[ -d /srv/hgfs/. ]]; then
		declare -r    HGFS_DIRS="/srv/hgfs"	# vmware shared directory
	else
		declare -r    HGFS_DIRS="/mnt/hgfs"	# vmware shared directory
	fi

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

	declare -r    TFTP_ROOT="/var/lib/tftpboot"
#	declare -r    TFTP_ROOT="/var/tftp"

	# --- firewall ------------------------------------------------------------
	declare -r    FWAL_ZONE="home"			# firewall zone name
											# firewall port
	declare -r -a FWAL_PRTS=( \
		"30000-60000/udp" \
	)
											# firewall additional service list
	declare -r -a FWAL_LIST=( \
		"dns"        \
		"tftp"       \
		"proxy-dhcp" \
		"dhcp"       \
		"dhcpv6"     \
		"http"       \
		"https"      \
		"samba"      \
	)

	# --- service control -----------------------------------------------------
	# name: service name
	# flag: 0:disable/1:enable
	#   "name  flag"

	declare -r -a SRVC_LIST=( \
		"fwl 1" \
		"sel 1" \
		"ssh 1" \
		"dns 1" \
		"web 1" \
		"smb 1" \
	)

	# === network =============================================================
	# <important>
	#  not support multiple nic
	#  only support first nic

	# --- ntp server ----------------------------------------------------------
	declare -r    NTPS_NAME="ntp.nict.jp"		# ntp server name
	declare -r    NTPS_ADDR="133.243.238.164"	# ntp server IPv4 address

	# --- hostname ------------------------------------------------------------
	# shellcheck disable=SC2155
	declare -r    HOST_FQDN="$(hostname -f)"	# host fqdn
	declare -r    HOST_NAME="${HOST_FQDN%.*}"	# host name
	declare -r    HOST_DMAN="${HOST_FQDN##*.}"	# domain

	# --- localhost -----------------------------------------------------------
	declare -r    IPV6_LHST="::1"		# IPv6 localhost address
	declare -r    IPV4_LHST="127.0.0.1"	# IPv4 localhost address

	# --- dummy parameter -----------------------------------------------------
#	declare -r    IPV4_DUMY="127.0.1.1"	# IPv4 dummy address

	# --- hosts.allow ---------------------------------------------------------
	declare -r -a HOST_ALLW=(                   \
		"ALL : ${IPV4_LHST}"                    \
		"ALL : [${IPV6_LHST}]"                  \
		"ALL : _IPV4_UADR_0_.0/_IPV4_CIDR_0_"   \
		"ALL : [_LINK_UADR_0_::]/_LINK_CIDR_0_" \
		"ALL : [_IPV6_UADR_0_::]/_IPV6_CIDR_0_" \
	)

	# --- hosts.deny ----------------------------------------------------------
	declare -r -a HOST_DENY=( \
		"ALL : ALL" \
	)

	# --- variable parameter --------------------------------------------------
	declare -a    ETHR_NAME=()			# network device name (ex. eth0/ens160)
	declare -a    ETHR_MADR=()			# network mac address (ex. xx:xx:xx:xx:xx:xx)
	# --- ipv4 ----------------------------------------------------------------
	declare -a    IPV4_ADDR=()			# IPv4 address        (ex. 192.168.1.1)
	declare -a    IPV4_CIDR=()			# IPv4 cidr           (ex. 24)
	declare -a    IPV4_MASK=()			# IPv4 subnetmask     (ex. 255.255.255.0)
	declare -a    IPV4_GWAY=()			# IPv4 gateway        (ex. 192.168.1.254)
	declare -a    IPV4_NSVR=()			# IPv4 nameserver     (ex. 192.168.1.254)
	declare -a    IPV4_WGRP=()			# IPv4 domain         (ex. workgroup)
	declare -a -i IPV4_DHCP=()			# IPv4 dhcp mode      (ex. 0=static,1=dhcp)
	# --- ipv6 ----------------------------------------------------------------
	declare -a    IPV6_ADDR=()			# IPv6 address        (ex. ::1)
	declare -a    IPV6_CIDR=()			# IPv6 cidr           (ex. 64)
	declare -a    IPV6_MASK=()			# IPv6 subnetmask     (ex. ...)
	declare -a    IPV6_GWAY=()			# IPv6 gateway        (ex. ...)
	declare -a    IPV6_NSVR=()			# IPv6 nameserver     (ex. ...)
	declare -a    IPV6_WGRP=()			# IPv6 domain         (ex. ...)
	declare -a -i IPV6_DHCP=()			# IPv6 dhcp mode      (ex. 0=static,1=dhcp)
	# --- link ----------------------------------------------------------------
	declare -a    LINK_ADDR=()			# LINK address        (ex. fe80::1)
	declare -a    LINK_CIDR=()			# LINK cidr           (ex. 64)
	# --- variation -----------------------------------------------------------
	declare -a    IPV4_UADR=()			# IPv4 address up     (ex. 192.168.1)
	declare -a    IPV4_LADR=()			# IPv4 address low    (ex. 1)
	declare -a    IPV4_NTWK=()			# IPv4 network addr   (ex. 192.168.1.0)
	declare -a    IPV4_BCST=()			# IPv4 broadcast addr (ex. 192.168.1.255)
	declare -a    IPV4_LGWY=()			# IPv4 gateway low    (ex. 254)
	declare -a    IPV4_RADR=()			# IPv4 reverse addr   (ex. 1.168.192)
	declare -a    IPV6_FADR=()			# IPv6 full address   (ex. ...)
	declare -a    IPV6_UADR=()			# IPv6 address up     (ex. ...)
	declare -a    IPV6_LADR=()			# IPv6 address low    (ex. ...)
	declare -a    IPV6_RADR=()			# IPv6 reverse addr   (ex. ...)
	declare -a    LINK_FADR=()			# LINK full address   (ex. ...)
	declare -a    LINK_UADR=()			# LINK address up     (ex. ...)
	declare -a    LINK_LADR=()			# LINK address low    (ex. ...)
	declare -a    LINK_RADR=()			# LINK reverse addr   (ex. ...)
	# --- dhcp range ----------------------------------------------------------
	declare -r    DHCP_SADR="64"		# IPv4 DHCP start address
	declare -r    DHCP_EADR="79"		# IPv4 DHCP end address
	declare -r    DHCP_LEAS="12h"		# IPv4 DHCP lease time

# *** function section (common functions) *************************************

# --- set color ---------------------------------------------------------------
#	declare -r    ESC="$(printf '\033')"
	declare -r    ESC=$'\033'
	declare -r    TXT_RESET="${ESC}[m"						# reset all attributes
	declare -r    TXT_ULINE="${ESC}[4m"						# set underline
	declare -r    TXT_ULINERST="${ESC}[24m"					# reset underline
	declare -r    TXT_REV="${ESC}[7m"						# set reverse display
	declare -r    TXT_REVRST="${ESC}[27m"					# reset reverse display
	declare -r    TXT_BLACK="${ESC}[90m"					# text black
	declare -r    TXT_RED="${ESC}[91m"						# text red
	declare -r    TXT_GREEN="${ESC}[92m"					# text green
	declare -r    TXT_YELLOW="${ESC}[93m"					# text yellow
	declare -r    TXT_BLUE="${ESC}[94m"						# text blue
	declare -r    TXT_MAGENTA="${ESC}[95m"					# text purple
	declare -r    TXT_CYAN="${ESC}[96m"						# text light blue
	declare -r    TXT_WHITE="${ESC}[97m"					# text white
	declare -r    TXT_BBLACK="${ESC}[40m"					# text reverse black
	declare -r    TXT_BRED="${ESC}[41m"						# text reverse red
	declare -r    TXT_BGREEN="${ESC}[42m"					# text reverse green
	declare -r    TXT_BYELLOW="${ESC}[43m"					# text reverse yellow
	declare -r    TXT_BBLUE="${ESC}[44m"					# text reverse blue
	declare -r    TXT_BMAGENTA="${ESC}[45m"					# text reverse purple
	declare -r    TXT_BCYAN="${ESC}[46m"					# text reverse light blue
	declare -r    TXT_BWHITE="${ESC}[47m"					# text reverse white

# --- text color test ---------------------------------------------------------
function funcColorTest() {
	printf "%s : %-12.12s : %s\n" "${TXT_RESET}"    "TXT_RESET"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_ULINE}"    "TXT_ULINE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_ULINERST}" "TXT_ULINERST" "${TXT_RESET}"
#	printf "%s : %-12.12s : %s\n" "${TXT_BLINK}"    "TXT_BLINK"    "${TXT_RESET}"
#	printf "%s : %-12.12s : %s\n" "${TXT_BLINKRST}" "TXT_BLINKRST" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_REV}"      "TXT_REV"      "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_REVRST}"   "TXT_REVRST"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BLACK}"    "TXT_BLACK"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_RED}"      "TXT_RED"      "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_GREEN}"    "TXT_GREEN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_YELLOW}"   "TXT_YELLOW"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BLUE}"     "TXT_BLUE"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_MAGENTA}"  "TXT_MAGENTA"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_CYAN}"     "TXT_CYAN"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_WHITE}"    "TXT_WHITE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BBLACK}"   "TXT_BBLACK"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BRED}"     "TXT_BRED"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BGREEN}"   "TXT_BGREEN"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BYELLOW}"  "TXT_BYELLOW"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BBLUE}"    "TXT_BBLUE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BMAGENTA}" "TXT_BMAGENTA" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BCYAN}"    "TXT_BCYAN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BWHITE}"   "TXT_BWHITE"   "${TXT_RESET}"
}

# --- diff --------------------------------------------------------------------
function funcDiff() {
	if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
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
	IFS= mapfile -d ':' -t OUT_ARRY < <(echo -n "${INP_ADDR/%:/::}")
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
#	declare -r    SET_ENV_E="$(set -o | awk '$1=="errexit" {print $2;}')"
	declare -r    SET_ENV_X="$(set -o | awk '$1=="xtrace"  {print $2;}')"
	set +x
	# https://www.tohoho-web.com/ex/dash-tilde.html
#	declare -r    OLD_IFS="${IFS}"
#	declare -i    RET_CD=0
	declare       FLAG_CUT=""
	declare       TEXT_FMAT=""
	declare -r    CTRL_ESCP=$'\033['
	declare       PRNT_STR=""
	declare       SJIS_STR=""
	declare       TEMP_STR=""
	declare       WORK_STR=""
	declare -i    CTRL_CNT=0
	declare -i    MAX_COLS="${COLS_SIZE:-80}"
	# -------------------------------------------------------------------------
	IFS=$'\n'
	if [[ "$1" = "--no-cutting" ]]; then					# no cutting print
		FLAG_CUT="true"
		shift
	fi
	if [[ "$1" =~ %[0-9.-]*[diouxXfeEgGcs]+ ]]; then
		# shellcheck disable=SC2001
		TEXT_FMAT="$(echo "$1" | sed -e 's/%\([0-9.-]*\)s/%\1b/g')"
		shift
	fi
	# shellcheck disable=SC2059
	PRNT_STR="$(printf "${TEXT_FMAT:-%b}" "${@:-}")"
	if [[ -z "${FLAG_CUT}" ]]; then
		SJIS_STR="$(echo -n "${PRNT_STR:-}" | iconv -f UTF-8 -t CP932)"
		TEMP_STR="$(echo -n "${SJIS_STR}" | sed -e "s/${CTRL_ESCP}[0-9]*m//g")"
		if [[ "${#TEMP_STR}" -gt "${MAX_COLS}" ]]; then
			CTRL_CNT=$((${#SJIS_STR}-${#TEMP_STR}))
			WORK_STR="$(echo -n "${SJIS_STR}" | cut -b $((MAX_COLS+CTRL_CNT))-)"
			TEMP_STR="$(echo -n "${WORK_STR}" | sed -e "s/${CTRL_ESCP}[0-9]*m//g")"
			MAX_COLS+=$((CTRL_CNT-(${#WORK_STR}-${#TEMP_STR})))
			# shellcheck disable=SC2312
			if ! PRNT_STR="$(echo -n "${SJIS_STR:-}" | cut -b -"${MAX_COLS}"   | iconv -f CP932 -t UTF-8 2> /dev/null)"; then
				 PRNT_STR="$(echo -n "${SJIS_STR:-}" | cut -b -$((MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
			fi
		fi
	fi
	printf "%b\n" "${PRNT_STR:-}"
	IFS="${OLD_IFS}"
	# -------------------------------------------------------------------------
	if [[ "${SET_ENV_X}" = "on" ]]; then
		set -x
	else
		set +x
	fi
#	if [[ "${SET_ENV_E}" = "on" ]]; then
#		set -e
#	else
#		set +e
#	fi
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

	if command -v numfmt > /dev/null 2>&1; then
		echo "$1" | numfmt --to=iec-i --suffix=B
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
	declare       INP_URL=""
	declare       OUT_DIR=""
	declare       OUT_FILE=""
	declare       MSG_FLG=""
	declare -a    OPT_PRM=()
	declare -a    ARY_HED=()
	declare       ERR_MSG=""
	declare       WEB_SIZ=""
	declare       WEB_TIM=""
	declare       WEB_FIL=""
	declare       LOC_INF=""
	declare       LOC_SIZ=""
	declare       LOC_TIM=""
	declare       TXT_SIZ=""

	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			http://* | https://* )
				OPT_PRM+=("${1}")
				INP_URL="${1}"
				;;
			--output-dir )
				OPT_PRM+=("${1}")
				shift
				OPT_PRM+=("${1}")
				OUT_DIR="${1}"
				;;
			--output )
				OPT_PRM+=("${1}")
				shift
				OPT_PRM+=("${1}")
				OUT_FILE="${1}"
				;;
			--quiet )
				MSG_FLG="true"
				;;
			* )
				OPT_PRM+=("${1}")
				;;
		esac
		shift
	done
	if [[ -z "${OUT_FILE}" ]]; then
		OUT_FILE="${INP_URL##*/}"
	fi
	if ! ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${INP_URL}" 2> /dev/null)"); then
		RET_CD="$?"
		ERR_MSG=$(echo "${ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -e 's/\r\n*/\n/g' -ze 's/\n//g')
#		echo -e "${ERR_MSG} [${RET_CD}]: ${INP_URL}"
		if [[ -z "${MSG_FLG}" ]]; then
			printf "%s\n" "${ERR_MSG} [${RET_CD}]: ${INP_URL}"
		fi
		return "${RET_CD}"
	fi
	WEB_SIZ=$(echo "${ARY_HED[@],,}" | sed -ne '/http\/.* 200/,/^$/ s/'$'\r''//gp' | sed -ne '/content-length:/ s/.*: //p')
	# shellcheck disable=SC2312
	WEB_TIM=$(TZ=UTC date -d "$(echo "${ARY_HED[@],,}" | sed -ne '/http\/.* 200/,/^$/ s/'$'\r''//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
	WEB_FIL="${OUT_DIR:-.}/${INP_URL##*/}"
	if [[ -n "${OUT_DIR}" ]] && [[ ! -d "${OUT_DIR}/." ]]; then
		mkdir -p "${OUT_DIR}"
	fi
	if [[ -n "${OUT_FILE}" ]] && [[ -e "${OUT_FILE}" ]]; then
		WEB_FIL="${OUT_FILE}"
	fi
	if [[ -n "${WEB_FIL}" ]] && [[ -e "${WEB_FIL}" ]]; then
		LOC_INF=$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${WEB_FIL}")
		LOC_TIM=$(echo "${LOC_INF}" | awk '{print $6;}')
		LOC_SIZ=$(echo "${LOC_INF}" | awk '{print $5;}')
		if [[ "${WEB_TIM:-0}" -eq "${LOC_TIM:-0}" ]] && [[ "${WEB_SIZ:-0}" -eq "${LOC_SIZ:-0}" ]]; then
			if [[ -z "${MSG_FLG}" ]]; then
				funcPrintf "same    file: ${WEB_FIL}"
			fi
			return
		fi
	fi

	TXT_SIZ="$(funcUnit_conversion "${WEB_SIZ}")"

	if [[ -z "${MSG_FLG}" ]]; then
		funcPrintf "get     file: ${WEB_FIL} (${TXT_SIZ})"
	fi
	if curl "${OPT_PRM[@]}"; then
		return $?
	fi

	for ((I=0; I<3; I++))
	do
		if [[ -z "${MSG_FLG}" ]]; then
			funcPrintf "retry  count: ${I}"
		fi
		if curl --continue-at "${OPT_PRM[@]}"; then
			return "$?"
		else
			RET_CD="$?"
		fi
	done
	if [[ "${RET_CD}" -ne 0 ]]; then
		rm -f "${:?}"
	fi
	return "${RET_CD}"
}

# --- service status ----------------------------------------------------------
function funcServiceStatus() {
	declare       SRVC_STAT
	# -------------------------------------------------------------------------
	SRVC_STAT="$(systemctl is-enabled "$1" 2> /dev/null || true)"
	case "${SRVC_STAT:-}" in
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
	echo "${SRVC_STAT:-"not-found"}"
}

# --- function is package -----------------------------------------------------
function funcIsPackage () {
	LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed'
}

# *** function section (sub functions) ****************************************

# ------ system control -------------------------------------------------------
function funcSystem_control() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="system control"
	declare -a    SRVC_LINE=()
	declare -a    SYSD_ARRY=()
	declare -a    SYSD_NAME=()
	declare -i    I=0
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: service"
	for ((I=0; I<"${#SRVC_LIST[@]}"; I++))
	do
		# shellcheck disable=SC2206
		SRVC_LINE=(${SRVC_LIST[I]})
		SYSD_ARRY=()
		SYSD_NAME=()
		#                    debian/ubuntu                               fedora/centos/...                           opensuse
		case "${SRVC_LINE[0]}" in
			fwl ) SYSD_ARRY=("firewalld.service"                         "firewalld.service"                         "firewalld.service"                         );;
			sel ) SYSD_ARRY=(""                                          "selinux-autorelabel.service"               ""                                          );;
			ssh ) SYSD_ARRY=("ssh.service"                               "sshd.service"                              "sshd.service"                              );;
			dns ) SYSD_ARRY=("dnsmasq.service"                           "dnsmasq.service"                           "dnsmasq.service"                           );;
			web ) SYSD_ARRY=("apache2.service"                           "httpd.service"                             "apache2.service"                           );;
			smb ) SYSD_ARRY=("smbd.service nmbd.service winbind.service" "smb.service nmb.service winbind.service"   "smb.service nmb.service"                   );;
			*   ) ;;
		esac
		case "${DIST_NAME}" in
			debian       | \
			ubuntu       ) read -r -a SYSD_NAME < <(echo "${SYSD_ARRY[0]}");;
			fedora       | \
			centos       | \
			almalinux    | \
			miraclelinux | \
			rocky        ) read -r -a SYSD_NAME < <(echo "${SYSD_ARRY[1]}");;
			opensuse-*   ) read -r -a SYSD_NAME < <(echo "${SYSD_ARRY[2]}");;
			*            ) ;;
		esac
		if [[ -z "${SYSD_NAME[*]}" ]]; then
			continue
		fi
		case "$(funcServiceStatus "${SYSD_NAME}")" in
			enabled  | \
			disabled )
				;;
			* )
				continue
				;;
		esac
		if [[ "${SRVC_LINE[1]}" -eq 0 ]]; then
			funcPrintf "      ${MSGS_TITL}: disable ${SYSD_NAME[*]}"
			systemctl --quiet disable "${SYSD_NAME[@]}"
		else
			funcPrintf "      ${MSGS_TITL}: enable  ${SYSD_NAME[*]}"
			systemctl --quiet enable "${SYSD_NAME[@]}"
		fi
	done
}

# ------ system parameter -----------------------------------------------------
function funcSystem_parameter() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="system parameter"
	declare       PARM_LINE=""
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: os information"
	while read -r PARM_LINE
	do
		PARM_LINE="${PARM_LINE//\"/}"
		case "${PARM_LINE}" in
			ID=*               ) DIST_NAME="${PARM_LINE#*=}";;	# distribution name (ex. debian)
			VERSION_CODENAME=* ) DIST_CODE="${PARM_LINE#*=}";;	# code name         (ex. bookworm)
			VERSION=*          ) DIST_VERS="${PARM_LINE#*=}";;	# version name      (ex. 12 (bookworm))
			VERSION_ID=*       ) DIST_VRID="${PARM_LINE#*=}";;	# version number    (ex. 12)
			* ) ;;
		esac
	done < /etc/os-release
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: package manager"
	case "${DIST_NAME}" in
		debian       | \
		ubuntu       )
			PKGS_MNGR="apt-get"
			PKGS_OPTN=("-y" "-qq")
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		miraclelinux | \
		rocky        )
			PKGS_MNGR="dnf"
			PKGS_OPTN=("--assumeyes" "--quiet")
			;;
		opensuse-*   )
			PKGS_MNGR="zypper"
			PKGS_OPTN=("--non-interactive" "--terse")
			;;
		*            )
			funcPrintf "not supported on ${DIST_NAME}"
			exit 1
			;;
	esac
}

# ------ network parameter ----------------------------------------------------
function funcNetwork_parameter() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="network parameter"
	declare       PARM_LINE=""
	declare -a    PARM_ARRY=()
	declare -a    IPV4_INFO=()
#	declare -a    IPV6_INFO=()
	declare -a    LINK_INFO=()
	declare -a    GWAY_INFO=()
#	declare -a    NSVR_INFO=()
	declare       WORK_PARM=""
	declare       WORK_TEXT=""
	declare       FILE_PATH=""
	declare -i    I=0
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	IFS=$'\n'
	# shellcheck disable=SC2207
	IPV4_INFO=($(LANG=C ip -4 -oneline address show scope global))
	IFS=${OLD_IFS}
	# -------------------------------------------------------------------------
	for ((I=0; I<"${#IPV4_INFO[@]}"; I++))
	do
		# shellcheck disable=SC2206
		PARM_ARRY=(${IPV4_INFO[I]})
		# shellcheck disable=SC2207
		LINK_INFO=($(LANG=C ip -4 -oneline link show dev "${PARM_ARRY[1]}"))
		# ---------------------------------------------------------------------
		ETHR_NAME+=("${PARM_ARRY[1]}")
		ETHR_MADR+=("${LINK_INFO[16]}")
		# ---------------------------------------------------------------------
		# shellcheck disable=SC2207
		GWAY_INFO=($(LANG=C ip -4 -oneline route list dev "${ETHR_NAME[I]}" default))
		# ---------------------------------------------------------------------
		IPV4_ADDR+=("${PARM_ARRY[3]%/*}")
		IPV4_CIDR+=("${PARM_ARRY[3]##*/}")
		IPV4_MASK+=("$(funcIPv4GetNetmask "${IPV4_CIDR[I]}")")
		IPV4_GWAY+=("${GWAY_INFO[2]:-}")
		IPV4_WGRP+=("${HOST_DMAN:-}")
		# shellcheck disable=SC2312
		if [[ -n "$(LANG=C ip -oneline -4 address show dev "${ETHR_NAME[I]}" scope global dynamic)" ]]; then
			IPV4_DHCP+=("1")
		else
			IPV4_DHCP+=("0")
		fi
		# ---------------------------------------------------------------------
		IPV4_UADR+=("${IPV4_ADDR[I]%.*}")
		IPV4_LADR+=("${IPV4_ADDR[I]##*.}")
		IPV4_NTWK+=("${IPV4_UADR[I]}.0")
		IPV4_BCST+=("${IPV4_UADR[I]}.255")
		IPV4_LGWY+=("${IPV4_GWAY[I]##*.}")
		# --- nameserver ------------------------------------------------------
		WORK_PARM=""
		# shellcheck disable=SC2312
		if [[ -z "${WORK_PARM:-}" ]] && [[ -n "$(command -v systemd-resolve 2> /dev/null)" ]] \
		&& [[ "$(systemctl status "systemd-resolved.service" | awk '/Active:/ {print $2;}')" = "active" ]]; then
			WORK_PARM="$(LANG=C systemd-resolve --status "${ETHR_NAME[I]}"         \
			           | sed -ne '/DNS Servers:/,/DNS Domain:/                  {' \
			                  -e "s/.*[ \t]\+\(${IPV4_UADR[I]}\.[0-9]\+\).*/\1/p}" \
			)"
		fi
		# shellcheck disable=SC2312
		if [[ -z "${WORK_PARM:-}" ]] && [[ -n "$(command -v connmanctl 2> /dev/null)" ]] \
		&& [[ "$(systemctl status "connman.service" | awk '/Active:/ {print $2;}')" = "active" ]]; then
			WORK_TEXT="$(find /var/lib/connman/ -name "*_${ETHR_MADR[I]//:/}_*" -type d -printf "%P")"
			WORK_PARM="$(LANG=C connmanctl services "${WORK_TEXT}"                 \
			           | sed -ne '/^[ \t]*Nameservers[ \t]*=/                   {' \
			                  -e "s/.*[ \t]\+\(${IPV4_UADR[I]}\.[0-9]\+\).*/\1/p}" \
			)"
		fi
		# shellcheck disable=SC2312
		if [[ -z "${WORK_PARM:-}" ]] && [[ -n "$(command -v nmcli 2> /dev/null)" ]] \
		&& [[ "$(systemctl status "NetworkManager.service" | awk '/Active:/ {print $2;}')" = "active" ]]; then
			WORK_PARM="$(LANG=C nmcli device show "${ETHR_NAME[I]}"                \
			           | sed -ne '/IP4.DNS/                                     {' \
			                  -e "s/.*[ \t]\+\(${IPV4_UADR[I]}\.[0-9]\+\).*/\1/p}" \
			)"
		fi
		# shellcheck disable=SC2312
		if [[ -z "${WORK_PARM:-}" ]] && [[ -n "$(command -v netplan 2> /dev/null)" ]] \
		&& [[ -n "$(netplan help 2>&1 | sed -ne '/^[ \t]\+get[ \t]/p')" ]]; then
			WORK_TEXT="ethernets.${ETHR_NAME[I]}.nameservers.addresses"
			WORK_PARM="$(netplan get "${WORK_TEXT}" 2>&1                           \
			           | sed -ne "s/.*[ \t]\+\(${IPV4_UADR[I]}\.[0-9]\+\).*/\1/p"  \
			)"
		fi
		if [[ -z "${WORK_PARM:-}" ]]; then
			WORK_PARM="$(awk '$1=="nameserver"&&$2~"'"${IPV4_ADDR[I]%.*}"'" {print $2;}' /etc/resolv.conf)"
		fi
		IPV4_NSVR+=("${WORK_PARM}")
		# ---------------------------------------------------------------------
		IFS='.'
		set -f
		# shellcheck disable=SC2086
		set -- ${IPV4_UADR[I]:-}
		set +f
		IFS=${OLD_IFS}
		IPV4_RADR+=("$3.$2.$1")
		# ---------------------------------------------------------------------
#		IFS=$'\n'
#		IPV6_INFO=($(LANG=C ip -6 -oneline address show dev "${ETHR_NAME[I]}" | sed -n '/temporary/!p'))
#		IFS=${OLD_IFS}
#		GWAY_INFO=($(LANG=C ip -6 -oneline route list dev "${ETHR_NAME[I]}" default))
		# ---------------------------------------------------------------------
		PARM_LINE="$(LANG=C ip -6 -oneline address show dev "${ETHR_NAME[I]}" | awk '$7!="temporary"&&$4!~"^fe80:" {print $4;}')"
		IPV6_ADDR+=("${PARM_LINE%/*}")
		IPV6_CIDR+=("${PARM_LINE##*/}")
		IPV6_MASK+=("")
		IPV6_GWAY+=("$(LANG=C ip -6 -oneline route list dev "${ETHR_NAME[I]}" default | awk '{print $3;}')")
		IPV6_NSVR+=("$(awk '$1=="nameserver"&&$2~'\"'${IPV6_ADDR[I]%.*}'\"' {print $2;}' /etc/resolv.conf)")
		IPV6_WGRP+=("${HOST_DMAN:-}")
		# shellcheck disable=SC2312
		if [[ -n "$(LANG=C ip -oneline -6 address show dev "${ETHR_NAME[I]}" scope global dynamic)" ]]; then
			IPV6_DHCP+=("1")
		else
			IPV6_DHCP+=("0")
		fi
		IPV6_FADR+=("$(funcIPv6GetFullAddr "${IPV6_ADDR[I]:-}")")
		IPV6_RADR+=("$(funcIPv6GetRevAddr  "${IPV6_FADR[I]:-}")")
		# ---------------------------------------------------------------------
		PARM_LINE="$(LANG=C ip -6 -oneline address show dev "${ETHR_NAME[I]}" | awk '$7!="temporary"&&$4~"^fe80:" {print $4;}')"
		LINK_ADDR+=("${PARM_LINE%/*}")
		LINK_CIDR+=("${PARM_LINE##*/}")
		LINK_FADR+=("$(funcIPv6GetFullAddr "${LINK_ADDR[I]:-}")")
		LINK_RADR+=("$(funcIPv6GetRevAddr  "${LINK_FADR[I]:-}")")
		# ---------------------------------------------------------------------
		IPV6_UADR+=("$(funcSubstr "${IPV6_FADR[I]:-}"  1 19)")
		IPV6_LADR+=("$(funcSubstr "${IPV6_FADR[I]:-}" 21 19)")
		LINK_UADR+=("$(funcSubstr "${LINK_FADR[I]:-}"  1 19)")
		LINK_LADR+=("$(funcSubstr "${LINK_FADR[I]:-}" 21 19)")
	done
}

# ------ nsswitch -------------------------------------------------------------
function funcNetwork_nsswitch() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="nsswitch"
	declare -r    DIRS_PATH="$(find /usr -maxdepth 1 -name 'etc' -type d)"
	# shellcheck disable=SC2086
	declare -r    FILE_PATH="$(find /etc ${DIRS_PATH} -name 'nsswitch.conf' -type f)"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	# --- nsswitch ------------------------------------------------------------
	sed -i "${FILE_PATH}"         \
	    -e '/^hosts:/          {' \
	    -e '/wins/! s/$/ wins/ }'
}

# ------ hosts ----------------------------------------------------------------
function funcNetwork_hosts() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="hosts"
	declare -r    FILE_PATH="/etc/hosts"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare -r    SYSD_NAME="dnsmasq.service"
	declare -i    I=0
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# --- hosts ---------------------------------------------------------------
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	sed -i "${FILE_PATH}"                          \
	    -e '/^127\.0\.1\.1/d'                      \
	    -e 's/^\([0-9.]\+\)[ \t]\+/\1\t/g'         \
	    -e 's/^\([0-9a-zA-Z:]\+\)[ \t]\+/\1\t\t/g'
#	for ((I="${#LINK_FADR[@]}"-1; I>=0; I--))
#	do
#		sed -i "${FILE_PATH}"                                                \
#		    -e "/^${LINK_FADR[I]}/d"                                         \
#		    -e "/^127\.0\.0\.1/a ${LINK_FADR[I]}\t${HOST_FQDN} ${HOST_NAME}"
#	done
#	for ((I="${#IPV6_FADR[@]}"-1; I>=0; I--))
#	do
#		sed -i "${FILE_PATH}"                                                \
#		    -e "/^${IPV6_FADR[I]}/d"                                         \
#		    -e "/^127\.0\.0\.1/a ${IPV6_FADR[I]}\t${HOST_FQDN} ${HOST_NAME}"
#	done
	for ((I="${#IPV4_ADDR[@]}"-1; I>=0; I--))
	do
		sed -i "${FILE_PATH}"                                                \
		    -e "/^${IPV4_ADDR[I]}/d"                                         \
		    -e "/^127\.0\.0\.1/a ${IPV4_ADDR[I]}\t${HOST_FQDN} ${HOST_NAME}"
	done
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ------ hosts.allow / hosts.deny ---------------------------------------------
function funcNetwork_hosts_allow_deny() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="hosts.allow / hosts.deny"
	declare       FILE_PATH=""
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	declare -i    I=0
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# --- hosts.allow ---------------------------------------------------------
	FILE_PATH="/etc/hosts.allow"
	FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	: > "${FILE_PATH}"
	for ((I=0; I<"${#HOST_ALLW[@]}"; I++))
	do
		echo "${HOST_ALLW[I]}" >> "${FILE_PATH}"
	done
	sed -i "${FILE_PATH}"                     \
	    -e "s/_IPV4_UADR_0_/${IPV4_UADR[0]}/" \
	    -e "s/_IPV4_CIDR_0_/${IPV4_CIDR[0]}/" \
	    -e "s/_LINK_UADR_0_/${LINK_UADR[0]}/" \
	    -e "s/_LINK_CIDR_0_/${LINK_CIDR[0]}/" \
	    -e "s/_IPV6_UADR_0_/${IPV6_UADR[0]}/" \
	    -e "s/_IPV6_CIDR_0_/${IPV6_CIDR[0]}/" \
	    -e 's/0000//g'                        \
	    -e 's/::\+/::/g'
	# --- hosts.deny ----------------------------------------------------------
	FILE_PATH="/etc/hosts.deny"
	FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	: > "${FILE_PATH}"
	for ((I=0; I<"${#HOST_DENY[@]}"; I++))
	do
		echo "${HOST_DENY[I]}" >> "${FILE_PATH}"
	done
}

# ------ dnsmasq --------------------------------------------------------------
function funcNetwork_dnsmasq() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="dnsmasq"
	declare       FILE_PATH="/lib/systemd/system/dnsmasq.service"
	declare       FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare       FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       SYSD_NAME="dnsmasq.service"
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_PATH}" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	# -------------------------------------------------------------------------
	sed -i "${FILE_PATH}"                     \
	    -e '/\[Unit\]/,/\[.\+\]/           {' \
	    -e '/^Requires=/                   {' \
	    -e 's/^/#/g'                          \
	    -e 'a Requires=network-online.target' \
	    -e '                               }' \
	    -e '/^After=/                      {' \
	    -e 's/^/#/g'                          \
	    -e 'a After=network-online.target'    \
	    -e '                               }' \
	    -e '}'
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: daemon reload"
	systemctl --quiet daemon-reload
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
#	sleep 1
}

# ------ connman --------------------------------------------------------------
function funcNetwork_connmanctl() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="connmanctl"
	declare       FILE_PATH=""
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	declare       SYSD_NAME=""
	declare -a    NICS_NAME=()
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v connmanctl 2> /dev/null)" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	FILE_PATH="/etc/connman/main.conf"
	FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
		if [[ -s "${FILE_PATH}" ]]; then
			funcPrintf "      ${MSGS_TITL}: setup config file"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			sed -e '/^AllowHostnameUpdates[ \t]*=/      s/^/#/'                                    \
			    -e '/^PreferredTechnologies[ \t]*=/     s/^/#/'                                    \
			    -e '/^SingleConnectedTechnology[ \t]*=/ s/^/#/'                                    \
			    -e '/^EnableOnlineCheck[ \t]*=/         s/^/#/'                                    \
			    -e '/^NetworkInterfaceBlacklist*=/      s/^/#/'                                    \
			    -e '/^#[ \t]*AllowHostnameUpdates[ \t]*=/a AllowHostnameUpdates = false'           \
			    -e '/^#[ \t]*PreferredTechnologies[ \t]*=/a PreferredTechnologies = ethernet,wifi' \
			    -e '/^#[ \t]*SingleConnectedTechnology[ \t]*=/a SingleConnectedTechnology = true'  \
			    -e '/^#[ \t]*EnableOnlineCheck[ \t]*=/a EnableOnlineCheck = false'                 \
			   "${FILE_ORIG}"                                                                      \
			>  "${FILE_PATH}"
		else
			funcPrintf "      ${MSGS_TITL}: create config file, because empty"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
				AllowHostnameUpdates = false
				PreferredTechnologies = ethernet,wifi
				SingleConnectedTechnology = true
				EnableOnlineCheck = false
				# NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb,ve-,vb-
_EOT_
		fi
		if [[ "${#ETHR_NAME[@]}" -gt 1 ]]; then
			sed -i "${FILE_PATH}"                              \
			    -e '/SingleConnectedTechnology/ s/true/false/'
		fi
		# shellcheck disable=SC2312
		mapfile NICS_NAME < <(ip -oneline link show | sed -ne '/1:[ \t]\+lo:/! s/^[0-9]\+:[ \t]\+\([[:alnum:]]\+\):[ \t]\+.*$/\1/p')
		unset 'NICS_NAME[0]'
		if [[ "${#NICS_NAME[@]}" -ge 1 ]]; then
			sed -i "${FILE_PATH}"                                                                            \
			    -e "/^#[ \t]*NetworkInterfaceBlacklist[ \t]*=/a NetworkInterfaceBlacklist = ${NICS_NAME[*]}"
		fi
	fi
	# -------------------------------------------------------------------------
	FILE_PATH="/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
	FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	mkdir -p "${FILE_PATH%/*}"
	# shellcheck disable=SC2312
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		[Service]
		ExecStart=
		ExecStart=$(command -v connmand 2> /dev/null) -n --nodnsproxy
_EOT_
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: daemon reload"
	systemctl --quiet daemon-reload
	SYSD_NAME="connman.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
	SYSD_NAME="dnsmasq.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
#	sleep 1
}

# ------ netplan --------------------------------------------------------------
function funcNetwork_netplan() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="netplan"
	declare -r    FILE_PATH="/etc/netplan/99-network-manager-static.yaml"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       FILE_LINE=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v netplan 2> /dev/null)" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	while read -r FILE_LINE
	do
		# shellcheck disable=SC2312
		if [[ -n "$(sed -n "/${IPV4_ADDR[0]}\/${IPV4_CIDR[0]}/p" "${FILE_LINE}")" ]]; then
			funcPrintf "      ${MSGS_TITL}: file already exists"
			funcPrintf "      ${MSGS_TITL}: ${FILE_LINE}"
			return
		fi
		if [[ "$(awk '$1=="renderer:" {print $2;}' "${FILE_LINE}")" = "NetworkManager" ]]; then
			funcPrintf "      ${MSGS_TITL}: management by network-manager"
			funcPrintf "      ${MSGS_TITL}: ${FILE_LINE}"
			return
		fi
	done < <(find "${FILE_PATH%/*}" \( -type f -o -type l \))
	# -------------------------------------------------------------------------
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		network:
		  version: 2
		  ethernets:
		    ${ETHR_NAME[0]}:
		      dhcp4: false
		      addresses: [ ${IPV4_ADDR[0]}/${IPV4_CIDR[0]} ]
		      gateway4: ${IPV4_GWAY[0]}
		      nameservers:
		          search: [ ${IPV4_WGRP[0]} ]
		          addresses: [ ${IPV4_NSVR[0]} ]
		      dhcp6: true
		      ipv6-privacy: true
_EOT_
}

# ------ networkmanager -------------------------------------------------------
function funcNetwork_networkmanager() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="networkmanager"
	declare       FILE_PATH="/etc/NetworkManager/conf.d"
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	declare       SYSD_NAME=""
	declare       CONF_PARM=""
	declare -i    I=0
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v nmcli 2> /dev/null)" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	for ((I=1; I<"${#ETHR_NAME[@]}"; I++))
	do
		funcPrintf "      ${MSGS_TITL}: disconnect ${ETHR_NAME[${I}]}"
		nmcli device disconnect "${ETHR_NAME[${I}]}"
	done
	# -------------------------------------------------------------------------
#	if [[ -e /etc/dnsmasq.conf ]]; then
#		SYSD_NAME="dnsmasq.service"
#		FILE_PATH+="/dnsmasq.conf"
#		CONF_PARM="[main]"$'\n'"systemd-resolved=false"$'\n'"dns=dnsmasq"
#	else
		SYSD_NAME="systemd-resolved.service"
		FILE_PATH+="/none-dns.conf"
		CONF_PARM="[main]"$'\n'"systemd-resolved=false"$'\n'"dns=none"
#	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: stop ${SYSD_NAME}"
		systemctl --quiet stop "${SYSD_NAME}"
		funcPrintf "      ${MSGS_TITL}: disable ${SYSD_NAME}"
		systemctl --quiet disable "${SYSD_NAME}"
	fi
	# -------------------------------------------------------------------------
	FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		${CONF_PARM}
_EOT_
	# -------------------------------------------------------------------------
	SYSD_NAME="NetworkManager.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ------ resolv.conf ----------------------------------------------------------
function funcNetwork_resolv_conf() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="resolv.conf"
	declare -r    FILE_PATH="/etc/resolv.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare -r    CONF_FILE="${FILE_PATH}.manually-configured"
	declare -r    SYSD_NAME="systemd-resolved.service"
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ -h "${FILE_PATH}" ]]; then
		# shellcheck disable=SC2312
		if [[ "$(realpath "${FILE_PATH}")" = "${CONF_FILE}" ]]; then
			funcPrintf "      ${MSGS_TITL}: link file already exists"
			return
		fi
		touch "${CONF_FILE}"
		rm -f "${FILE_PATH}"
		ln -s "${CONF_FILE}" "${FILE_PATH}"
#		# shellcheck disable=SC2312,SC2310
#		if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
#			return
#		fi
#		funcPrintf "      ${MSGS_TITL}: rm -f ${FILE_PATH}"
#		rm -f "${FILE_PATH}"
	fi
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
#	chattr +i "${FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		# Generated by user script
		search ${IPV4_WGRP[0]}
		nameserver ::1
		nameserver 127.0.0.1
		nameserver ${IPV4_NSVR[0]}
_EOT_
#	chattr -i "${FILE_PATH}"
#	lsattr "${FILE_PATH}"
}

# ------ tftpd-hpa ------------------------------------------------------------
function funcNetwork_tftpd_hpa() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="tftpd-hpa"
	declare -r    DIRS_PATH="/etc/default"
	declare -r    CONF_PATH="${DIRS_PATH}/tftpd-hpa"
	declare -r    CONF_ORIG="${DIRS_ORIG}/${CONF_PATH}"
	declare -r    CONF_BACK="${DIRS_BACK}/${CONF_PATH}.${DATE_TIME}"
	declare       SYSD_NAME="tftp.socket"
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: create directory"
	funcPrintf "      ${MSGS_TITL}: ${TFTP_ROOT}"
	mkdir -p "${TFTP_ROOT}/"{menu-{bios,efi64},boot/grub}
	# -------------------------------------------------------------------------
	if [[ -e "${CONF_PATH}" ]]; then
		if [[ ! -e "${CONF_ORIG}" ]]; then
			mkdir -p "${CONF_ORIG%/*}"
			cp --archive "${CONF_PATH}" "${CONF_ORIG}"
		else
			mkdir -p "${CONF_BACK%/*}"
			cp --archive "${CONF_PATH}" "${CONF_BACK}"
		fi
		funcPrintf "      ${MSGS_TITL}: edit config file"
		funcPrintf "      ${MSGS_TITL}: ${CONF_PATH}"
		sed -i "${CONF_PATH}"                                     \
		    -e "/^TFTP_DIRECTORY=/ s%=.*$%=\"${TFTP_ROOT}\"%"     \
		    -e '/^TFTP_OPTIONS=/   s/=.*$/="--secure --verbose"/'
		SYSD_NAME="tftpd-hpa.service"
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ------ pxe.conf -------------------------------------------------------------
function funcNetwork_pxe_conf() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="pxe.conf"
	declare -r    DIRS_PATH="/etc/dnsmasq.d"
	declare -r    FILE_PATH="${DIRS_PATH}/pxe.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare -r    CONF_PATH="/etc/dnsmasq.conf"
	declare -r    CONF_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    CONF_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       FILE_LINE=""
#	declare       WORK_DIRS=""
#	declare       WORK_TYPE=""
#	declare       WORK_FILE=""
	declare       SYSD_NAME=""
#	declare -a    SELX_OPTN=()
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: create directory"
	funcPrintf "      ${MSGS_TITL}: ${DIRS_PATH}"
	mkdir -p "${DIRS_PATH}"
	touch "${FILE_PATH}"
	# -------------------------------------------------------------------------
	if [[ -e /etc/selinux/config ]]; then
		funcPrintf "      ${MSGS_TITL}: setsebool"
		setsebool -P httpd_enable_homedirs 1
#		setsebool -P httpd_use_nfs 1
#		setsebool -P httpd_use_fusefs 1
#		setsebool -P tftp_home_dir 1
#		setsebool -P tftp_anon_write 1
	fi
	# -------------------------------------------------------------------------
	if [[ -e "${CONF_PATH}" ]]; then
		if [[ ! -e "${CONF_ORIG}" ]]; then
			mkdir -p "${CONF_ORIG%/*}"
			cp --archive "${CONF_PATH}" "${CONF_ORIG}"
		else
			mkdir -p "${CONF_BACK%/*}"
			cp --archive "${CONF_PATH}" "${CONF_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: edit config file"
	funcPrintf "      ${MSGS_TITL}: ${CONF_PATH}"
	sed -i "${CONF_PATH}"               \
	    -e '/^bind-interfaces$/ s/^/#/'
	# -------------------------------------------------------------------------
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		# --- log ---------------------------------------------------------------------
		#log-queries												# dns query log output
		#log-dhcp													# dhcp transaction log output
		#log-facility=												# log output file name
		
		# --- dns ---------------------------------------------------------------------
		#port=5353													# listening port
		bogus-priv													# do not perform reverse lookup of private ip address on upstream server
		domain-needed												# do not forward plain names
		domain=${HOST_DMAN}											# local domain name
		expand-hosts												# add domain name to host
		filterwin2k													# filter for windows
		interface=lo,${ETHR_NAME[0]}											# listen to interface
		listen-address=${IPV6_LHST},${IPV4_LHST},${IPV4_ADDR[0]}					# listen to ip address
		#server=8.8.8.8												# directly specify upstream server
		#server=8.8.4.4												# directly specify upstream server
		#no-hosts													# don't read the hostnames in /etc/hosts
		#no-poll													# don't poll /etc/resolv.conf for changes
		#no-resolv													# don't read /etc/resolv.conf
		strict-order												# try in the registration order of /etc/resolv.conf
		bind-dynamic												# enable bind-interfaces and the default hybrid network mode
		
		# --- dhcp --------------------------------------------------------------------
		dhcp-range=${IPV4_NTWK[0]},proxy,${IPV4_CIDR[0]}								# proxy dhcp
		#dhcp-range=${IPV4_UADR[0]}.${DHCP_SADR},${IPV4_UADR[0]}.${DHCP_EADR},${DHCP_LEAS}					# dhcp range
		#dhcp-option=option:netmask,${IPV4_MASK[0]}					#  1 netmask
		dhcp-option=option:router,${IPV4_GWAY[0]}						#  3 router
		dhcp-option=option:dns-server,${IPV4_ADDR[0]},${IPV4_NSVR[0]}	#  6 dns-server
		dhcp-option=option:domain-name,${HOST_DMAN}					# 15 domain-name
		#dhcp-option=option:28,${IPV4_BCST[0]}						# 28 broadcast
		#dhcp-option=option:ntp-server,${NTPS_ADDR}				# 42 ntp-server
		#dhcp-option=option:tftp-server,${IPV4_ADDR[0]}					# 66 tftp-server
		#dhcp-option=option:bootfile-name,							# 67 bootfile-name
		dhcp-no-override											# disable re-use of the dhcp servername and filename fields as extra option space
		
		# --- pxe boot ----------------------------------------------------------------
		#pxe-prompt="Press F8 for boot menu", 0						# pxe boot prompt
		#pxe-service=x86PC            , "PXEBoot-x86PC"            , boot/grub/pxelinux		#  0 Intel x86PC
		#pxe-service=PC98             , "PXEBoot-PC98"             ,						#  1 NEC/PC98
		#pxe-service=IA64_EFI         , "PXEBoot-IA64_EFI"         ,						#  2 EFI Itanium
		#pxe-service=Alpha            , "PXEBoot-Alpha"            ,						#  3 DEC Alpha
		#pxe-service=Arc_x86          , "PXEBoot-Arc_x86"          ,						#  4 Arc x86
		#pxe-service=Intel_Lean_Client, "PXEBoot-Intel_Lean_Client",						#  5 Intel Lean Client
		#pxe-service=IA32_EFI         , "PXEBoot-IA32_EFI"         ,						#  6 EFI IA32
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , boot/grub/bootx64.efi	#  7 EFI BC
		#pxe-service=Xscale_EFI       , "PXEBoot-Xscale_EFI"       ,						#  8 EFI Xscale
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , boot/grub/bootx64.efi	#  9 EFI x86-64
		#pxe-service=ARM32_EFI        , "PXEBoot-ARM32_EFI"        ,						# 10 ARM 32bit
		#pxe-service=ARM64_EFI        , "PXEBoot-ARM64_EFI"        ,						# 11 ARM 64bit
		
		# --- ipxe block --------------------------------------------------------------
		#dhcp-match=set:iPXE,175																# 
		#pxe-prompt="Press F8 for boot menu", 0												# pxe boot prompt
		#pxe-service=tag:iPXE ,x86PC     , "PXEBoot-x86PC"     , /autoexec.ipxe				#  0 Intel x86PC (iPXE)
		#pxe-service=tag:!iPXE,x86PC     , "PXEBoot-x86PC"     , ipxe/undionly.kpxe			#  0 Intel x86PC
		#pxe-service=tag:!iPXE,BC_EFI    , "PXEBoot-BC_EFI"    , ipxe/ipxe.efi				#  7 EFI BC
		#pxe-service=tag:!iPXE,x86-64_EFI, "PXEBoot-x86-64_EFI", ipxe/ipxe.efi				#  9 EFI x86-64
		
		# --- tftp --------------------------------------------------------------------
		#enable-tftp=${ETHR_NAME[0]}											# enable tftp server
		#tftp-root=${TFTP_ROOT}								# tftp root directory
		#tftp-lowercase												# convert tftp request path to all lowercase
		#tftp-no-blocksize											# stop negotiating "block size" option
		#tftp-no-fail												# do not abort startup even if tftp directory is not accessible
		#tftp-secure												# enable tftp secure mode
		
		# --- dnsmasq manual page -----------------------------------------------------
		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
		
		# --- eof ---------------------------------------------------------------------
_EOT_
	# -------------------------------------------------------------------------
	SYSD_NAME="dnsmasq.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ==== application ============================================================

# ----- system package manager ------------------------------------------------
function funcApplication_package_manager() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="package manager"
	declare       FILE_PATH=""
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	declare       SYSD_NAME=""
	declare       DIST_URLS=""
	declare       DIST_DIRS=""
	declare       BACK_PORT=""
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	case "${DIST_NAME}" in
		debian       | \
		ubuntu       )
			# --- stopping unattended-upgrades.service ------------------------
			SYSD_NAME="unattended-upgrades.service"
			# shellcheck disable=SC2312,SC2310
			if [[ "$(funcServiceStatus "${SYSD_NAME}")" != "not-found" ]]; then
				funcPrintf "      ${MSGS_TITL}: stopping ${SYSD_NAME}"
				systemctl --quiet --no-reload stop "${SYSD_NAME}"
			fi
			# --- updating sources.list ---------------------------------------
			funcPrintf "      ${MSGS_TITL}: updating sources.list"
			FILE_PATH="/etc/apt/sources.list"
			FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
			FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
			if [[ -e "${FILE_PATH}" ]]; then
				if [[ ! -e "${FILE_ORIG}" ]]; then
					mkdir -p "${FILE_ORIG%/*}"
					cp --archive "${FILE_PATH}" "${FILE_ORIG}"
				else
					mkdir -p "${FILE_BACK%/*}"
					cp --archive "${FILE_PATH}" "${FILE_BACK}"
				fi
			fi
			funcPrintf "      ${MSGS_TITL}: create file"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			sed -e '/^deb cdrom.*$/ s/^/#/g' \
			    "${FILE_ORIG}"               \
			>   "${FILE_PATH}"
			# --- create backports.list ---------------------------------------
			BACK_PORT="$(awk '$1=="deb"&&$3=='\""${DIST_CODE}-backports"\"'  {print $0;}' "${FILE_PATH}")"
			DIST_URLS="$(awk '$1=="deb"&&$3=='\""${DIST_CODE}"\"'&&$0~/main/ {print $2;}' "${FILE_PATH}")"
			DIST_DIRS="$(awk '$1=="deb"&&$3=='\""${DIST_CODE}"\"'&&$0~/main/ {printf("%s %s %s %s", $4, $5, $6, $7);}' "${FILE_PATH}")"
			if [[ -z "${BACK_PORT}" ]] && [[ -n "${DIST_URLS}" ]] && [[ -n "${DIST_DIRS}" ]]; then
				FILE_PATH="/etc/apt/sources.list.d/backports.list"
				FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
				FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
				if [[ -e "${FILE_PATH}" ]]; then
					if [[ ! -e "${FILE_ORIG}" ]]; then
						mkdir -p "${FILE_ORIG%/*}"
						cp --archive "${FILE_PATH}" "${FILE_ORIG}"
					else
						mkdir -p "${FILE_BACK%/*}"
						cp --archive "${FILE_PATH}" "${FILE_BACK}"
					fi
				fi
				funcPrintf "      ${MSGS_TITL}: create file"
				funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
					# Addition by user script
					deb ${DIST_URLS} ${DIST_CODE}-backports ${DIST_DIRS/% /}
					deb-src ${DIST_URLS} ${DIST_CODE}-backports ${DIST_DIRS/% /}
_EOT_
			fi
			# --- updating install pakages ------------------------------------
			funcPrintf "      ${MSGS_TITL}: updating install pakages"
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[1]} update"
			"${PKGS_MNGR}" "${PKGS_OPTN[1]}" update
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]} upgrade"
			"${PKGS_MNGR}" "${PKGS_OPTN[@]}" upgrade
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]} dist-upgrade"
			"${PKGS_MNGR}" "${PKGS_OPTN[@]}" dist-upgrade
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]} autoremove"
			"${PKGS_MNGR}" "${PKGS_OPTN[@]}" autoremove
			# --- bug fix -----------------------------------------------------
			# shellcheck disable=SC2312
			if [[ -n "$(command -v iptables 2> /dev/null)" ]]; then
				if [[ "$(iptables --version | awk '{print $2;}')" = "v1.8.2" ]]; then
					funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]} -t ${DIST_CODE}-backports install iptables"
					"${PKGS_MNGR}" "${PKGS_OPTN[@]}" -t "${DIST_CODE}-backports" install iptables
				fi
				SYSD_NAME="firewalld.service"
				# shellcheck disable=SC2312,SC2310
				if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
					funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
					systemctl --quiet restart "${SYSD_NAME}"
				fi
			fi
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		miraclelinux | \
		rocky        )
			# --- updating install pakages ------------------------------------
			funcPrintf "      ${MSGS_TITL}: updating install pakages"
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]} check-update"
			"${PKGS_MNGR}" "${PKGS_OPTN[@]}" check-update || true
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]} upgrade"
			"${PKGS_MNGR}" "${PKGS_OPTN[@]}" upgrade
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]} autoremove"
			"${PKGS_MNGR}" "${PKGS_OPTN[@]}" autoremove
			;;
		opensuse-*   )
			# --- updating install pakages ------------------------------------
			funcPrintf "      ${MSGS_TITL}: updating install pakages"
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]}update"
			"${PKGS_MNGR}" "${PKGS_OPTN[@]}" update
			funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR} ${PKGS_OPTN[*]}dist-upgrade"
			"${PKGS_MNGR}" "${PKGS_OPTN[@]}" dist-upgrade
			;;
		*            ) 
			funcPrintf "not supported on ${DIST_NAME}"
			exit 1
			;;
	esac
}

# ------ system firewall ------------------------------------------------------
function funcApplication_firewall() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="firewall"
	declare       FWAL_PORT=""
	declare       FWAL_NAME=""
	declare -a    WORK_ARRY=()
	declare       WORK_PARM=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v firewall-cmd 2> /dev/null)" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: change default zone"
	firewall-cmd --quiet --remove-service=ssh --permanent
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ "$(firewall-cmd --get-zone-of-interface="${ETHR_NAME[0]}" 2>&1)" != "${FWAL_ZONE}" ]] \
	&& [[ "$(firewall-cmd --get-default-zone 2>&1)" != "${FWAL_ZONE}" ]]; then
		funcPrintf "      ${MSGS_TITL}: change zone: ${FWAL_ZONE}"
		funcPrintf "      ${MSGS_TITL}: change interface: ${ETHR_NAME[0]}"
		firewall-cmd --quiet --zone="${FWAL_ZONE}" --add-interface="${ETHR_NAME[0]}" --permanent
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2207
	WORK_ARRY=($(firewall-cmd --list-ports --zone="${FWAL_ZONE}"))
	for FWAL_PORT in "${FWAL_PRTS[@]}"
	do
		for WORK_PARM in "${WORK_ARRY[@]}"
		do
			if [[ "${FWAL_PORT}" = "${WORK_PARM}" ]]; then
				continue 2
			fi
		done
		funcPrintf "      ${MSGS_TITL}: add port ${FWAL_PORT}"
		firewall-cmd --quiet --add-port="${FWAL_PORT}" --zone="${FWAL_ZONE}" --permanent
	done
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2207
	WORK_ARRY=($(firewall-cmd --list-services --zone="${FWAL_ZONE}"))
	for FWAL_NAME in "${FWAL_LIST[@]}"
	do
		for WORK_PARM in "${WORK_ARRY[@]}"
		do
			if [[ "${FWAL_NAME}" = "${WORK_PARM}" ]]; then
				continue 2
			fi
		done
		funcPrintf "      ${MSGS_TITL}: add service ${FWAL_NAME}"
		firewall-cmd --quiet --add-service="${FWAL_NAME}" --zone="${FWAL_ZONE}" --permanent
	done
	# -------------------------------------------------------------------------
#	funcPrintf "      ${MSGS_TITL}: firewall runtime to permanent"
#	firewall-cmd --quiet --runtime-to-permanent
	funcPrintf "      ${MSGS_TITL}: firewall change-interface"
	firewall-cmd --quiet --zone="${FWAL_ZONE}" --change-interface="${ETHR_NAME[0]}" --permanent
	funcPrintf "      ${MSGS_TITL}: firewall reload"
	firewall-cmd --quiet --reload
}

# ----- system kernel ---------------------------------------------------------
function funcApplication_system_kernel() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="kernel"
	declare -r    FILE_PATH="/etc/modprobe.d/blacklist-floppy.conf"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(lsmod | sed -ne '/floppy/p')" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	funcPrintf "      ${MSGS_TITL}: rmmod floppy"
	rmmod floppy
	funcPrintf "      ${MSGS_TITL}: create blacklist file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	echo 'blacklist floppy' > "${FILE_PATH}"
	# shellcheck disable=SC2312
	if [[ -n "$(command -v dpkg-reconfigure 2> /dev/null)" ]]; then
		funcPrintf "      ${MSGS_TITL}: dpkg-reconfigure initramfs-tools"
		dpkg-reconfigure initramfs-tools
	fi
}

# ----- system shared directory -----------------------------------------------
function funcApplication_system_shared_directory() {
	declare -r    MSGS_TITL="shared directory"
	# shellcheck disable=SC2155
	declare -r    LGIN_SHEL="$(command -v nologin)"			# login shell (disallow system login to samba user)
#	declare       WORK_DIRS=""
#	declare       WORK_TYPE=""
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# --- create system user id -----------------------------------------------
	if [[ -n "${SAMB_USER}" ]] && [[ -n "${SAMB_GRUP}" ]] && [[ -z "$(id "${SAMB_USER}" 2> /dev/null || true)" ]]; then
		# shellcheck disable=SC2312
		if [[ -z "$(awk -F ':' '$1=='\""${SAMB_GRUP}"\"' {print $1;}' /etc/group)" ]]; then
			funcPrintf "      ${MSGS_TITL}: create samba group"
			funcPrintf "      ${MSGS_TITL}: ${SAMB_GRUP}"
			groupadd --system "${SAMB_GRUP}"
		fi
		funcPrintf "      ${MSGS_TITL}: create samba user"
		funcPrintf "      ${MSGS_TITL}: ${SAMB_USER}:${SAMB_GRUP}"
		useradd --system --shell "${LGIN_SHEL}" --groups "${SAMB_GRUP}" "${SAMB_USER}"
		funcPrintf "      ${MSGS_TITL}: ${SAMB_GADM}"
		groupadd --system "${SAMB_GADM}"
	fi
	# --- create shared directory ---------------------------------------------
	funcPrintf "      ${MSGS_TITL}: create shared directory"
	funcPrintf "      ${MSGS_TITL}: ${DIRS_SHAR}"
	mkdir -p "${DIRS_SHAR}"/{cifs,data/{adm/{netlogon,profiles},arc,bak,pub,usr},dlna/{movies,others,photos,sounds}}
	if [[ -e /etc/selinux/config ]]; then
		funcPrintf "      ${MSGS_TITL}: setsebool"
		setsebool -P samba_enable_home_dirs 1
		setsebool -P samba_export_all_ro 1
		setsebool -P samba_export_all_rw 1
	fi
#	if [[ -e /etc/selinux/config ]]; then
#		WORK_DIRS="${DIRS_SHAR/\./\\.}(/.*)?"
#		WORK_TYPE="samba_share_t"
#		# shellcheck disable=SC2312
#		if [[ -z "$(semanage fcontext --list | awk 'index($1,"'"${WORK_DIRS//\\/\\\\}"'")&&index($4,"'"${WORK_TYPE}"'") {split($4,a,":"); print a[3];}')" ]]; then
#			funcPrintf "      ${MSGS_TITL}: semanage fcontext --add --type ${WORK_TYPE}"
#			funcPrintf "      ${MSGS_TITL}: ${WORK_DIRS}"
#			semanage fcontext --add --type "${WORK_TYPE}" "${WORK_DIRS}"
#		fi
#		restorecon -R -F "${DIRS_SHAR}"
#	fi
	# --- create cifs directory -----------------------------------------------
	funcPrintf "      ${MSGS_TITL}: create cifs directory"
	funcPrintf "      ${MSGS_TITL}: /mnt"
	mkdir -p /mnt/share.{nfs,win}
	# --- create logon.bat ----------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: create file"
	funcPrintf "      ${MSGS_TITL}: ${DIRS_SHAR}/data/adm/netlogon/logon.bat"
	touch -f "${DIRS_SHAR}/data/adm/netlogon/logon.bat"
	# --- attribute change ----------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: change attributes of shared directory"
	chown -R "${SAMB_USER}":"${SAMB_GRUP}" "${DIRS_SHAR}/"*
	chmod -R  770 "${DIRS_SHAR}/"*
	chmod    1777 "${DIRS_SHAR}/data/adm/profiles"
}
# ----- system user environment -----------------------------------------------
function funcApplication_system_user_environment() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="user environment"
	declare       LINK_PATH=""
	declare       FILE_PATH=""
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	declare       USER_NAME=""
	declare       USER_HOME=""
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	FILE_PATH="/etc/locale.gen"
	if [[ -e "${FILE_PATH}" ]]; then
		funcPrintf "      ${MSGS_TITL}: language setup"
		FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
		FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
		sed -i "${FILE_PATH}"                     \
		    -e '/^[^#][[:graph:]]/ s/^/# /g'      \
		    -e '0,/'"${LANG_BASE}"'/           {' \
		    -e '/'"${LANG_BASE}"'/ s/^#[ \t]*//}' \
		    -e '0,/en_US.UTF-8/                {' \
		    -e '/en_US.UTF-8/      s/^#[ \t]*//}'
		locale-gen
		update-locale LANG="${LANG_BASE}"
	fi
	# -------------------------------------------------------------------------
	for USER_NAME in root "$(logname)"	# only root and login user
	do
		funcPrintf "${TXT_RESET}      ${MSGS_TITL}: [${TXT_BGREEN}${USER_NAME}${TXT_RESET}] environment settings"
		if [[ "${USER_NAME}" = "root" ]]; then
			USER_HOME="/${USER_NAME}"
		else
			USER_HOME="$(awk -F ':' '$1=='\""${USER_NAME}"\"' {print $6;}' /etc/passwd)"
		fi
		# --- .bash_history ---------------------------------------------------
		funcPrintf "      ${MSGS_TITL}: bash_history"
		FILE_PATH="${USER_HOME}/.bash_history"
		FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
		FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
		if [[ -e "${FILE_PATH}" ]]; then
			if [[ ! -e "${FILE_ORIG}" ]]; then
				mkdir -p "${FILE_ORIG%/*}"
				cp --archive "${FILE_PATH}" "${FILE_ORIG}"
			else
				mkdir -p "${FILE_BACK%/*}"
				cp --archive "${FILE_PATH}" "${FILE_BACK}"
			fi
		fi
		funcPrintf "      ${MSGS_TITL}: create config file"
		funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
		touch "${FILE_PATH}"
		# shellcheck disable=SC2312
		if [[ -n "$(command -v apt-get 2> /dev/null)" ]]; then
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
				sudo bash -c 'apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade'
_EOT_
		fi
		chown "${USER_NAME}": "${FILE_PATH}"
		# --- vim -------------------------------------------------------------
		# shellcheck disable=SC2312
		if [[ -n "$(command -v vim 2> /dev/null)" ]]; then
			funcPrintf "      ${MSGS_TITL}: vim"
			LINK_PATH="${USER_HOME}/.virc"
			FILE_PATH="${USER_HOME}/.vimrc"
			FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
			FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
			# --- .vimrc ------------------------------------------------------
			if [[ -e "${FILE_PATH}" ]]; then
				if [[ ! -e "${FILE_ORIG}" ]]; then
					mkdir -p "${FILE_ORIG%/*}"
					cp --archive "${FILE_PATH}" "${FILE_ORIG}"
				else
					mkdir -p "${FILE_BACK%/*}"
					cp --archive "${FILE_PATH}" "${FILE_BACK}"
				fi
			fi
			funcPrintf "      ${MSGS_TITL}: create config file"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
				set number              " Print the line number in front of each line.
				set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
				set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
				set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
				set nowrap              " This option changes how text is displayed.
				set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
				set laststatus=2        " The value of this option influences when the last window will have a status line always.
				set mouse-=a            " Disable mouse usage
				syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
			chown "${USER_NAME}": "${FILE_PATH}"
			# --- vi ----------------------------------------------------------
			if [[ -e /etc/virc ]]; then
				# --- .virc -------------------------------------------------------
				if [[ ! -L "${LINK_PATH}" ]]; then
					funcPrintf "      ${MSGS_TITL}: create config link"
					funcPrintf "      ${MSGS_TITL}: ${LINK_PATH}"
					ln -sr "${FILE_PATH}" "${LINK_PATH}"
					chown "${USER_NAME}": "${LINK_PATH}"
				fi
				# --- .bashrc -----------------------------------------------------
				FILE_PATH="${USER_HOME}/.bashrc"
				# shellcheck disable=SC2312
#				if [[ -e "${FILE_PATH}" ]] && [[ -z "$(sed -n '/alias for vim/p' "${FILE_PATH}")" ]]; then
				if [[ -n "${FILE_PATH}" ]] && [[ -z "$(sed -n '/user custom/p' "${FILE_PATH}")" ]]; then
					funcPrintf "      ${MSGS_TITL}: alias for vim"
					FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
					FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
					if [[ -e "${FILE_PATH}" ]]; then
						if [[ ! -e "${FILE_ORIG}" ]]; then
							mkdir -p "${FILE_ORIG%/*}"
							cp --archive "${FILE_PATH}" "${FILE_ORIG}"
						else
							mkdir -p "${FILE_BACK%/*}"
							cp --archive "${FILE_PATH}" "${FILE_BACK}"
						fi
					fi
					funcPrintf "      ${MSGS_TITL}: setup config file"
					funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
					cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${FILE_PATH}"
						# --- user custom ---
						alias vi='vim'
						alias view='vim'
						alias diff='diff --color=auto'
						alias ip='ip -color=auto'
						alias ls='ls --color=auto'
_EOT_
					chown "${USER_NAME}": "${FILE_PATH}"
				fi
			fi
		fi
		# --- curl ------------------------------------------------------------
		# shellcheck disable=SC2312
		if [[ -n "$(command -v curl 2> /dev/null)" ]]; then
			funcPrintf "      ${MSGS_TITL}: curl"
			FILE_PATH="${USER_HOME}/.curlrc"
			FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
			FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
			if [[ -e "${FILE_PATH}" ]]; then
				if [[ ! -e "${FILE_ORIG}" ]]; then
					mkdir -p "${FILE_ORIG%/*}"
					cp --archive "${FILE_PATH}" "${FILE_ORIG}"
				else
					mkdir -p "${FILE_BACK%/*}"
					cp --archive "${FILE_PATH}" "${FILE_BACK}"
				fi
			fi
			funcPrintf "      ${MSGS_TITL}: create config file"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
				location
				progress-bar
				remote-time
				show-error
_EOT_
			chown "${USER_NAME}": "${FILE_PATH}"
		fi
		# --- measures against garbled characters -----------------------------
		if [[ -e "${USER_HOME}/.bashrc" ]]; then
			FILE_PATH="${USER_HOME}/.bashrc"
		elif [[ -e "${USER_HOME}/.i18n" ]]; then
			FILE_PATH="${USER_HOME}/.i18n"
		else
			FILE_PATH=""
		fi
		# shellcheck disable=SC2312
		if [[ -n "${FILE_PATH}" ]] && [[ -z "$(sed -n '/measures against garbled characters/p' "${FILE_PATH}")" ]]; then
			funcPrintf "      ${MSGS_TITL}: measures against garbled characters"
			FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
			FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
			if [[ -e "${FILE_PATH}" ]]; then
				if [[ ! -e "${FILE_ORIG}" ]]; then
					mkdir -p "${FILE_ORIG%/*}"
					cp --archive "${FILE_PATH}" "${FILE_ORIG}"
				else
					mkdir -p "${FILE_BACK%/*}"
					cp --archive "${FILE_PATH}" "${FILE_BACK}"
				fi
			fi
			funcPrintf "      ${MSGS_TITL}: setup config file"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${FILE_PATH}"
				# --- measures against garbled characters ---
				case "${TERM}" in
				    linux ) export LANG=C;;
				    *     )              ;;
				esac
_EOT_
			chown "${USER_NAME}": "${FILE_PATH}"
		fi
	done
}

# ----- user add --------------------------------------------------------------
function funcApplication_user_add() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="samba user add"
#	declare -a    USER_LIST=()
	declare -a    USER_LINE=()
	declare       STAT_FLAG=""								# status flag (a:add, s: skip, e: error, o: export)
	declare       USER_ADMN=""								# administrator flag (1: sambaadmin)
	declare       FULL_NAME=""								# full name
	declare       USER_NAME=""								# user name
	declare       USER_PWRD="unused"						# user password (unused)
	declare -i    USER_IDMO=0								# user id
	declare       USER_LNPW=""								# lanman password
	declare       USER_NTPW=""								# nt password
	declare       USER_ACNT=""								# account flags
	declare       USER_LCHT=""								# last change time
#	declare       USER_HOME=""								# home directory
	declare       DIRS_HOME="${DIRS_SHAR}/data/usr"			# root of home directory
	# shellcheck disable=SC2155
	declare -r    LGIN_SHEL="$(command -v nologin)"			# login shell (disallow system login to samba user)
	declare -r    PROG_PWDB="${DIRS_ARCH}/${FILE_USER##*/}.${DATE_TIME}"
	declare -r    SAMB_TEMP="${DIRS_TEMP}/smbpasswd.list.${DATE_TIME}"
	declare       SAMB_PWDB=""
	declare -i    I=0
	# shellcheck disable=SC2312
	if [[ -n "$(command -v pdbedit 2> /dev/null)" ]]; then
		pdbedit -L > /dev/null								# for creating passdb.tdb
		SAMB_PWDB="$(find /var/lib/samba/ -name 'passdb.tdb' \( -type f -o -type l \))"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ -e "${FILE_USER}" ]]; then
		funcPrintf "      ${MSGS_TITL}: ${FILE_USER}"
		mapfile USER_LIST < "${FILE_USER}"
	fi
	for ((I=0; I<"${#USER_LIST[@]}"; I++))
	do
		IFS=':'
		set -f
		# shellcheck disable=SC2206
		USER_LINE=(${USER_LIST[I]:-})
		set +f
		IFS=${OLD_IFS}
		STAT_FLAG="${USER_LINE[0]:-}"	# status flag (a:add, s: skip, e: error, o: export)
		USER_ADMN="${USER_LINE[1]:-}"	# administrator flag
		FULL_NAME="${USER_LINE[2]:-}"	# full name
		USER_NAME="${USER_LINE[3]:-}"	# user name
		USER_PWRD="${USER_LINE[4]:-}"	# user password (unused)
		USER_IDMO="${USER_LINE[5]:-}"	# user id
		USER_LNPW="${USER_LINE[6]:-}"	# lanman password
		USER_NTPW="${USER_LINE[7]:-}"	# nt password
		USER_ACNT="${USER_LINE[8]:-}"	# account flags
		USER_LCHT="${USER_LINE[9]:-}"	# last change time
#		USER_HOME=""					# home directory
		# --- add users -------------------------------------------------------
		if [[ "${STAT_FLAG}" = "s" ]]; then
			funcPrintf "      ${MSGS_TITL}: skip   [${USER_NAME}]"
			echo "s:${FULL_NAME}:${USER_NAME}:${USER_IDMO}:${USER_LNPW}:${USER_NTPW}:${USER_ACNT}:${USER_LCHT}:" >> "${PROG_PWDB}"
			continue
		fi
		if [[ "${STAT_FLAG}" != "r" ]]; then
			if [[ -n "$(id "${USER_NAME}" 2> /dev/null || true)" ]]; then
				funcPrintf "${TXT_RESET}      ${MSGS_TITL}: ${TXT_BRED}skip   [${USER_NAME}] already exists on the system${TXT_RESET}"
				echo "e:${FULL_NAME}:${USER_NAME}:${USER_IDMO}:${USER_LNPW}:${USER_NTPW}:${USER_ACNT}:${USER_LCHT}:" >> "${PROG_PWDB}"
				continue
			fi
			funcPrintf "      ${MSGS_TITL}: create [${USER_NAME}]"
			useradd --base-dir "${DIRS_HOME}" --create-home --comment "${FULL_NAME}" --groups "${SAMB_GRUP}" --uid "${USER_IDMO}" --shell "${LGIN_SHEL}" "${USER_NAME}"
			if [[ "${USER_ADMN}" = "1" ]]; then
				usermod --groups "${SAMB_GADM}" --append "${USER_NAME}"
			fi
		else
			usermod --groups "${SAMB_GRUP}" --append "${USER_NAME}"
			if [[ "${USER_ADMN}" = "1" ]]; then
				usermod --groups "${SAMB_GADM}" --append "${USER_NAME}"
			fi
		fi
		# --- create user dir -------------------------------------------------
		mkdir -p "${DIRS_HOME}/${USER_NAME}/"{app,dat,web/public_html}
		touch -f "${DIRS_HOME}/${USER_NAME}/web/public_html/index.html"
		# --- change user dir mode --------------------------------------------
		chmod -R 770 "${DIRS_HOME}/${USER_NAME}"
		chown -R "${SAMB_USER}":"${SAMB_GRUP}" "${DIRS_HOME}/${USER_NAME}"
		# --- create samba user file ------------------------------------------
		# shellcheck disable=SC2312
		USER_LCHT="LCT-$(printf "%X" "$(date "+%s")")"		# set current date and time
		echo "o:${USER_ADMN}:${FULL_NAME}:${USER_NAME}:${USER_PWRD}:${USER_IDMO}:${USER_LNPW}:${USER_NTPW}:${USER_ACNT}:${USER_LCHT}:" >> "${PROG_PWDB}"
		echo "${USER_NAME}:${USER_IDMO}:${USER_LNPW}:${USER_NTPW}:${USER_ACNT}:${USER_LCHT}:" >> "${SAMB_TEMP}"
	done
	# --- create samba user ---------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -n "$(command -v pdbedit 2> /dev/null)" ]] && [[ -s "${SAMB_TEMP}" ]]; then
		funcPrintf "      ${MSGS_TITL}: create samba user"
		funcPrintf "      ${MSGS_TITL}: import=smbpasswd: ${SAMB_TEMP/${PWD}\//}"
		funcPrintf "      ${MSGS_TITL}: export=tdbsam   : ${SAMB_PWDB}"
		pdbedit --import=smbpasswd:"${SAMB_TEMP}" --export=tdbsam:"${SAMB_PWDB}"
	fi
	rm -f "${SAMB_TEMP}"
}

# ----- user export -----------------------------------------------------------
function funcApplication_user_export() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="samba user export"
	declare -a    USER_LIST=""
	declare -a    USER_LINE=()
	declare       STAT_FLAG="o"								# status flag (a:add, s: skip, e: error, o: export)
	declare       USER_ADMN=""								# administrator flag (1: sambaadmin)
	declare       FULL_NAME=""								# full name
	declare       USER_NAME=""								# user name
	declare       USER_PWRD="unused"						# user password (unused)
	declare -i    USER_IDMO=0								# user id
	declare       USER_LNPW=""								# lanman password
	declare       USER_NTPW=""								# nt password
	declare       USER_ACNT=""								# account flags
	declare       USER_LCHT=""								# last change time
#	declare       USER_HOME=""								# home directory
	declare       DIRS_HOME="${DIRS_SHAR}/data/usr"			# root of home directory
	# shellcheck disable=SC2155
	declare -r    LGIN_SHEL="$(command -v nologin)"			# login shell (disallow system login to samba user)
	declare -r    SAMB_PWDB="$(find /var/lib/samba/ -name 'passdb.tdb' \( -type f -o -type l \))"
	declare -r    SAMB_TEMP="${DIRS_TEMP}/smbpasswd.list.${DATE_TIME}"
	declare -r    PROG_PWDB="${DIRS_ARCH}/${FILE_USER##*/}.${DATE_TIME}"
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	rm -f "${PROG_PWDB}"
	# shellcheck disable=SC2312
	while read -r USER_LIST
	do
		IFS=':'
		set -f
		# shellcheck disable=SC2206
		USER_LINE=(${USER_LIST:-})
		set +f
		IFS=${OLD_IFS}
		# --- splitting smbpasswd ---------------------------------------------
		USER_NAME="${USER_LINE[0]:-}"	# user name
		USER_IDMO="${USER_LINE[1]:-}"	# user id
		USER_LNPW="${USER_LINE[2]:-}"	# lanman password
		USER_NTPW="${USER_LINE[3]:-}"	# nt password
		USER_ACNT="${USER_LINE[4]:-}"	# account flags
		USER_LCHT="${USER_LINE[5]:-}"	# last change time
		# --- user details data -----------------------------------------------
		# shellcheck disable=SC2312
		FULL_NAME="$(pdbedit --user="${USER_NAME}" | awk -F ':' '{print $3;}')"
		# shellcheck disable=SC2312
		if [[ -z "$(id --groups --name "${USER_NAME}" | awk '/sambaadmin/')" ]]; then
			USER_ADMN=0
		else
			USER_ADMN=1
		fi
		echo "${STAT_FLAG}:${USER_ADMN}:${FULL_NAME}:${USER_NAME}:${USER_PWRD}:${USER_IDMO}:${USER_LNPW}:${USER_NTPW}:${USER_ACNT}:${USER_LCHT}:" >> "${PROG_PWDB}"
	done < <(pdbedit --list --smbpasswd-style)
}

# ----- clamav ----------------------------------------------------------------
function funcApplication_clamav() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="clamav"
	declare -r    FILE_PATH="/etc/clamav/freshclam.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare -r    FILE_CONF="${FILE_PATH%/*}/clamd.conf"
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
	if [[ ! -d "${FILE_PATH%/*}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_CONF}"
	touch "${FILE_CONF}"
	# -------------------------------------------------------------------------
	SYSD_NAME="clamav-freshclam.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ----- ntp: chrony -----------------------------------------------------------
function funcApplication_ntp_chrony() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="ntp"
	declare -r    CONF_PATH="$(find "/etc" -name 'chrony.conf' \( -type f -o -type l \))"
	if [[ -z "${CONF_PATH}" ]]; then
		return
	fi
	declare -r    INCL_PATH="$(awk '$1=="include" {print $2;}' "${CONF_PATH}")"
	declare -r    FILE_DIRS="${INCL_PATH%/*}"
	declare -r    FILE_PATH="${FILE_DIRS}/pool.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_PATH}" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL}: chrony ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		pool ${NTPS_NAME} iburst
_EOT_
	# -------------------------------------------------------------------------
	SYSD_NAME="chronyd.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
	funcPrintf "      ${MSGS_TITL}: hwclock --systohc"
	hwclock --systohc
}

# ----- ntp: timesyncd --------------------------------------------------------
function funcApplication_ntp_timesyncd() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="ntp"
#	declare -r    FILE_PATH="$(find "/etc/systemd" -name "timesyncd.conf" \( -type f -o -type l \))"
	declare -r    FILE_PATH="/etc/systemd/timesyncd.conf.d/local.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
#	if ! LANG=C apt list 'systemd-timesyncd' 2> /dev/null | grep -q 'installed'; then
	# shellcheck disable=SC2091,SC2310
	if ! $(funcIsPackage 'systemd-timesyncd'); then
		return
	fi
#	if [[ -z "${FILE_PATH}" ]]; then
#		return
#	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL}: timesyncd ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	mkdir -p "${FILE_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		# --- user settings ---
		[Time]
		NTP=${NTPS_NAME}
		FallbackNTP=ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp
		PollIntervalMinSec=1h
		PollIntervalMaxSec=1d
		SaveIntervalSec=infinity
_EOT_
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: set-timezone"
	timedatectl set-timezone Asia/Tokyo
	funcPrintf "      ${MSGS_TITL}: set-ntp"
	timedatectl set-ntp true
	SYSD_NAME="systemd-timesyncd.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ----- openssh-server --------------------------------------------------------
function funcApplication_openssh() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="openssh-server"
	declare -r    FILE_PATH="/etc/ssh/sshd_config.d/sshd.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
	if [[ ! -d "${FILE_PATH%/*}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		# --- user settings ---
		
		# port number to listen to ssh
		#Port 22
		
		# ip address to accept connections
		#ListenAddress 0.0.0.0
		#ListenAddress ::
		
		# ssh protocol
		Protocol 2
		
		# whether to allow root login
		PermitRootLogin no
		
		# configuring public key authentication
		#PubkeyAuthentication no
		
		# public key file location
		#AuthorizedKeysFile
		
		# setting password authentication
		#PasswordAuthentication yes
		
		# configuring challenge-response authentication
		#ChallengeResponseAuthentication no
		
		# sshd log is output to /var/log/secure
		#SyslogFacility AUTHPRIV
		
		# specify log output level
		#LogLevel INFO
_EOT_
	# -------------------------------------------------------------------------
	SYSD_NAME="sshd.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ----- dnsmasq ---------------------------------------------------------------
function funcApplication_dnsmasq() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="dnsmasq"
	declare -r    FILE_PATH="/etc/dnsmasq.d/pxe.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
	if [[ ! -d "${FILE_PATH%/*}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	# -------------------------------------------------------------------------
	SYSD_NAME="dnsmasq.service"
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ----- apache2 ---------------------------------------------------------------
function funcApplication_apache() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="apache2"
	# shellcheck disable=SC2207
	declare -r -a DIRS_PATH=($(find /etc/ \( -name "apache2" -o -name "httpd" \) -type d))
	declare -r    FILE_PATH="$(find "${DIRS_PATH[@]}" \( -name "apache2.conf" -o -name "httpd.conf" \) \( -type f -o -type l \))"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
	if [[ -z "${FILE_PATH}" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "apache2.service")" != "not-found" ]]; then
		SYSD_NAME="apache2.service"
	elif [[ "$(funcServiceStatus "httpd.service")" != "not-found" ]]; then
		SYSD_NAME="httpd.service"
	else
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
		systemctl --quiet restart "${SYSD_NAME}"
	fi
}

# ----- samba -----------------------------------------------------------------
function funcApplication_samba() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="samba"
	declare -r    FILE_PATH="/etc/samba/smb.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare -r    FILE_TEMP="${DIRS_TEMP}/${FILE_PATH##*/}.${DATE_TIME}"
	declare -a    SYSD_ARRY=()
	declare -r    COMD_UADD="$(command -v useradd)"
	declare -r    COMD_UDEL="$(command -v userdel)"
	declare -r    COMD_GADD="$(command -v groupadd)"
	declare -r    COMD_GDEL="$(command -v groupdel)"
	declare -r    COMD_GPWD="$(command -v gpasswd)"
	declare -r    COMD_FALS="$(command -v false)"
	# -------------------------------------------------------------------------
	if [[ ! -d "${FILE_PATH%/*}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	# --- orig -> verbose -> delete unseted line & edit parm ------------------
	testparm -s -v "${FILE_ORIG}"                                                                2> /dev/null | \
	sed -e "s~^\([ \t]*add group script[ \t]*=[ \t]*\).*$~\1${COMD_GADD} %g~"                                   \
	    -e "s~^\([ \t]*add machine script[ \t]*=[ \t]*\).*$~\1${COMD_UADD} -d /dev/null -s ${COMD_FALS} %u~"    \
	    -e "s~^\([ \t]*add user script[ \t]*=[ \t]*\).*$~\1${COMD_UADD} %u~"                                    \
	    -e "s~^\([ \t]*add user to group script[ \t]*=[ \t]*\).*$~\1${COMD_GPWD} -a %u %g~"                     \
	    -e "s~^\([ \t]*delete group script[ \t]*=[ \t]*\).*$~\1${COMD_GDEL} %g~"                                \
	    -e "s~^\([ \t]*delete user from group script[ \t]*=[ \t]*\).*$~\1${COMD_GPWD} -d %u %g~"                \
	    -e "s~^\([ \t]*delete user script[ \t]*=[ \t]*\).*$~\1${COMD_UDEL} %u~"                                 \
	    -e "s/^\([ \t]*netbios name[ \t]*=[ \t]*\).*$/\1${HOST_NAME^^}/"                                        \
	    -e "s/^\([ \t]*workgroup[ \t]*=[ \t]*\).*$/\1${HOST_DMAN^^}/"                                           \
	    -e 's/^\([ \t]*dos charset[ \t]*=[ \t]*\).*$/\1CP932/'                                                  \
	    -e 's~^\([ \t]*log file[ \t]*=[ \t]*\).*$~\1/var/log/samba/log\.%m~'                                    \
	    -e 's/^\([ \t]*logging[ \t]*=[ \t]*\).*$/\1file/'                                                       \
	    -e 's/^\([ \t]*security[ \t]*=[ \t]*\).*$/\1USER/'                                                      \
	    -e 's/^\([ \t]*server role[ \t]*=[ \t]*\).*$/\1AUTO/'                                                   \
	    -e 's/^\([ \t]*unix password sync[ \t]*=[ \t]*\).*$/\1No/'                                              \
	    -e 's/^\([ \t]*wins support[ \t]*=[ \t]*\).*$/\1No/'                                                    \
	    -e '/^[ \t]*\.*[ \t]*=/d'                                                                               \
	    -e '/^[ \t]*[[:print:]]\+[ \t]*=[ \t]*$/d'                                                              \
	    -e '/^[ \t]*acl check permissions[ \t]*=/d'                                                             \
	    -e '/^[ \t]*ad dc functional level[ \t]*=/d'                                                            \
	    -e '/^[ \t]*allocation roundup size[ \t]*=/d'                                                           \
	    -e '/^[ \t]*allow nt4 crypto[ \t]*=/d'                                                                  \
	    -e '/^[ \t]*blocking locks[ \t]*=/d'                                                                    \
	    -e '/^[ \t]*client NTLMv2 auth[ \t]*=/d'                                                                \
	    -e '/^[ \t]*client ipc min protocol[ \t]*=/d'                                                           \
	    -e '/^[ \t]*client lanman auth[ \t]*=/d'                                                                \
	    -e '/^[ \t]*client min protocol[ \t]*=/d'                                                               \
	    -e '/^[ \t]*client plaintext auth[ \t]*=/d'                                                             \
	    -e '/^[ \t]*client schannel[ \t]*=/d'                                                                   \
	    -e '/^[ \t]*client use spnego principal[ \t]*=/d'                                                       \
	    -e '/^[ \t]*client use spnego[ \t]*=/d'                                                                 \
	    -e '/^[ \t]*copy[ \t]*=/d'                                                                              \
	    -e '/^[ \t]*dns proxy[ \t]*=/d'                                                                         \
	    -e '/^[ \t]*domain logons[ \t]*=/d'                                                                     \
	    -e '/^[ \t]*domain master[ \t]*=/d'                                                                     \
	    -e '/^[ \t]*enable privileges[ \t]*=/d'                                                                 \
	    -e '/^[ \t]*encrypt passwords[ \t]*=/d'                                                                 \
	    -e '/^[ \t]*idmap backend[ \t]*=/d'                                                                     \
	    -e '/^[ \t]*idmap gid[ \t]*=/d'                                                                         \
	    -e '/^[ \t]*idmap uid[ \t]*=/d'                                                                         \
	    -e '/^[ \t]*lanman auth[ \t]*=/d'                                                                       \
	    -e '/^[ \t]*logon drive[ \t]*=/d'                                                                       \
	    -e '/^[ \t]*logon home[ \t]*=/d'                                                                        \
	    -e '/^[ \t]*logon path[ \t]*=/d'                                                                        \
	    -e '/^[ \t]*logon script[ \t]*=/d'                                                                      \
	    -e '/^[ \t]*lsa over netlogon[ \t]*=/d'                                                                 \
	    -e '/^[ \t]*map to guest[ \t]*=/d'                                                                      \
	    -e '/^[ \t]*nbt client socket address[ \t]*=/d'                                                         \
	    -e '/^[ \t]*null passwords[ \t]*=/d'                                                                    \
	    -e '/^[ \t]*obey pam restrictions[ \t]*=/d'                                                             \
	    -e '/^[ \t]*only user[ \t]*=/d'                                                                         \
	    -e '/^[ \t]*pam password change[ \t]*=/d'                                                               \
	    -e '/^[ \t]*paranoid server security[ \t]*=/d'                                                          \
	    -e '/^[ \t]*password level[ \t]*=/d'                                                                    \
	    -e '/^[ \t]*preferred master[ \t]*=/d'                                                                  \
	    -e '/^[ \t]*raw NTLMv2 auth[ \t]*=/d'                                                                   \
	    -e '/^[ \t]*reject md5 clients[ \t]*=/d'                                                                \
	    -e '/^[ \t]*server schannel require seal[ \t]*=/d'                                                      \
	    -e '/^[ \t]*server schannel[ \t]*=/d'                                                                   \
	    -e '/^[ \t]*share modes[ \t]*=/d'                                                                       \
	    -e '/^[ \t]*syslog only[ \t]*=/d'                                                                       \
	    -e '/^[ \t]*syslog[ \t]*=/d'                                                                            \
	    -e '/^[ \t]*time offset[ \t]*=/d'                                                                       \
	    -e '/^[ \t]*unicode[ \t]*=/d'                                                                           \
	    -e '/^[ \t]*use spnego[ \t]*=/d'                                                                        \
	    -e '/^[ \t]*usershare allow guests[ \t]*=/d'                                                            \
	    -e '/^[ \t]*winbind separator[ \t]*=/d'                                                                 \
	>   "${FILE_TEMP}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${FILE_TEMP}"
		[homes]
		        browseable = No
		        comment = Home Directories
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        valid users = %S
		        write list = @${SAMB_GRUP}
		
		
		[printers]
		        browseable = No
		        comment = All Printers
		        create mask = 0700
		        path = /var/tmp
		        printable = Yes
		
		
		[print$]
		        comment = Printer Drivers
		        path = /var/lib/samba/printers
		
		
		[netlogon]
		        browseable = No
		        comment = Network Logon Service
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        path = ${DIRS_SHAR}/data/adm/netlogon
		        valid users = @${SAMB_GRUP}
		        write list = @${SAMB_GADM}
		
		
		[profiles]
		        browseable = No
		        comment = User profiles
		        path = ${DIRS_SHAR}/data/adm/profiles
		        valid users = @${SAMB_GRUP}
		        write list = @${SAMB_GRUP}
		
		
		[share]
		        browseable = No
		        comment = Shared directories
		        path = ${DIRS_SHAR}
		        valid users = @${SAMB_GADM}
		
		
		[cifs]
		        browseable = No
		        comment = CIFS directories
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        path = ${DIRS_SHAR}/cifs
		        valid users = @${SAMB_GADM}
		        write list = @${SAMB_GADM}
		
		
		[data]
		        browseable = No
		        comment = Data directories
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        path = ${DIRS_SHAR}/data
		        valid users = @${SAMB_GADM}
		        write list = @${SAMB_GADM}
		
		
		[dlna]
		        browseable = No
		        comment = DLNA directories
		        create mask = 0770
		        directory mask = 0770
		        force group = ${SAMB_GRUP}
		        force user = ${SAMB_USER}
		        path = ${DIRS_SHAR}/dlna
		        valid users = @${SAMB_GRUP}
		        write list = @${SAMB_GRUP}
		
		
		[pub]
		        comment = Public directories
		        path = ${DIRS_SHAR}/data/pub
		        valid users = @${SAMB_GRUP}
		
		
		[lhome]
		        comment = Linux /home directories
		        path = /home
		        valid users = @${SAMB_GRUP}
		
		
		[pxe-share]
		        comment = Pxeboot shared directories
		        guest ok = Yes
		        path = /var/lib/tftpboot/imgs
		
		
		[pxe-conf]
		        comment = Pxeboot configuration files directory
		        guest ok = Yes
		        path = /var/lib/tftpboot/conf
		
		
_EOT_
	testparm -s "${FILE_TEMP}" 2> /dev/null > "${FILE_PATH}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "smbd.service")" != "not-found" ]]; then
		SYSD_ARRY=("smbd.service" "nmbd.service")
	elif [[ "$(funcServiceStatus "smb.service")" != "not-found" ]]; then
		SYSD_ARRY=("smb.service" "nmb.service")
	else
		return
	fi
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "winbind.service")" != "not-found" ]]; then
		SYSD_ARRY=("${SYSD_ARRY[@]}" "winbind.service")
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_ARRY[0]}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_ARRY[*]}"
		systemctl --quiet restart "${SYSD_ARRY[@]}"
	fi
	rm -f "${FILE_TEMP}"
	funcPrintf "      ${MSGS_TITL}: ${TXT_RESET}${TXT_BYELLOW}To access your home directory from a Windows PC,${TXT_RESET}"
	funcPrintf "      ${MSGS_TITL}: ${TXT_RESET}${TXT_BYELLOW} run the following command:${TXT_RESET}"
	funcPrintf "      ${MSGS_TITL}: chmod go=rx \${HOME}"
}

# ----- open-vm-tools ---------------------------------------------------------
function funcApplication_open_vm_tools() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="open-vm-tools"
	declare -r    FILE_PATH="/etc/fstab"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare -r -a INST_PAKG=("open-vm-tools" "open-vm-tools-desktop")
	declare       PKGS_SRCH="${PKGS_MNGR}"
	declare       HGFS_FSYS=""
	declare -i    RET_CD=0
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(lsmod | awk '$1~/vmwgfx|vmw_balloon|vmmouse_drv|vmware_drv|vmxnet3|vmw_pvscsi/ {print $1;}')" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	case "${DIST_NAME}" in
		debian       | \
		ubuntu       ) PKGS_SRCH="apt-cache";;
		fedora       | \
		centos       | \
		almalinux    | \
		miraclelinux | \
		rocky        ) ;;
		opensuse-*   ) ;;
		*            )
			funcPrintf "not supported on ${DIST_NAME}"
			exit 1
			;;
	esac
	# shellcheck disable=SC2312
	if [[ -z "$("${PKGS_SRCH}" search open-vm-tools 2> /dev/null | awk '$0~/open-vm-tools/ {print $0;}')" ]]; then
		funcPrintf "      ${MSGS_TITL}: ${TXT_RESET}${TXT_BYELLOW}unsupported package [${INST_PAKG[*]}]${TXT_RESET}"
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v vmware-checkvm 2> /dev/null)" ]]; then
		funcPrintf "      ${MSGS_TITL}: install open-vm-tools"
		funcPrintf "      ${MSGS_TITL}: package manager"
		funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR}"
		funcPrintf "      ${MSGS_TITL}: install package"
		funcPrintf "      ${MSGS_TITL}: ${INST_PAKG[*]}"
		"${PKGS_MNGR}" "${PKGS_OPTN[@]}" install "${INST_PAKG[@]}"
		RET_CD=$?
		if [[ "${RET_CD}" -ne 0 ]]; then
			funcPrintf "      ${MSGS_TITL}: ${TXT_RED}${TXT_REV}package install error[${RET_CD}]${TXT_RESET}"
			funcPrintf "      ${MSGS_TITL}: ${INST_PAKG[*]}"
			exit 1
		fi
	fi
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: create directory"
	funcPrintf "      ${MSGS_TITL}: ${HGFS_DIRS}"
	mkdir -p "${HGFS_DIRS}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -n "$(command -v vmhgfs-fuse 2> /dev/null)" ]]; then
		HGFS_FSYS="fuse.vmhgfs-fuse"
	else
		HGFS_FSYS="vmhgfs"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: setup config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	# shellcheck disable=SC2312
	if [[ -e "${FILE_PATH}" ]] && [[ -z "$(sed -n "/${HGFS_FSYS}/p" "${FILE_PATH}")" ]]; then
		# depending on the os, "nofail" can be added as an option
		# example: .host:/ /mnt/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,defaults,nofail 0 0
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${FILE_PATH}"
			.host:/         ${HGFS_DIRS}       ${HGFS_FSYS} allow_other,auto_unmount,defaults 0 0
_EOT_
	fi
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: daemon reload"
	systemctl --quiet daemon-reload
	# shellcheck disable=SC2312
	if [[ -n "$(LANG=C mountpoint /mnt/hgfs | sed -n '/not/!p')" ]]; then
		funcPrintf "      ${MSGS_TITL}: umount ${HGFS_DIRS}"
		umount "${HGFS_DIRS}"
	fi
	funcPrintf "      ${MSGS_TITL}: mount ${HGFS_DIRS}"
	mount "${HGFS_DIRS}"
#	funcPrintf "      ${MSGS_TITL}: mount check"
#	LANG=C df -h "${HGFS_DIRS}"
}

# ----- grub ------------------------------------------------------------------
function funcApplication_grub() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="grub"
	declare -r    FILE_PATH="/etc/default/grub"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare -r    TITL_TEXT="### User Custom ###"
	declare       GRUB_COMD=""
	declare       GRUB_CONF=""
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ ! -e "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(sed -ne "/${TITL_TEXT}/p" "${FILE_PATH}")" ]]; then
		funcPrintf "      ${MSGS_TITL}: add user parameters"
		sed -i "${FILE_PATH}"                           \
		    -e '/^GRUB_GFXMODE=/               s/^/#/g' \
		    -e '/^GRUB_GFXPAYLOAD_LINUX=/      s/^/#/g' \
		    -e '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/^/#/g' \
		    -e '/^GRUB_RECORDFAIL_TIMEOUT=/    s/^/#/g' \
		    -e '/^GRUB_TIMEOUT=/               s/^/#/g'
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${FILE_PATH}"
			
			${TITL_TEXT}
			GRUB_CMDLINE_LINUX_DEFAULT="quiet video=${SCRN_SIZE}"
			GRUB_GFXMODE=${SCRN_SIZE}
			GRUB_GFXPAYLOAD_LINUX=keep
			GRUB_RECORDFAIL_TIMEOUT=5
			GRUB_TIMEOUT=0
			
_EOT_
	else
		funcPrintf "      ${MSGS_TITL}: change screen size"
		sed -i "${FILE_PATH}"                                                           \
		    -e "/${TITL_TEXT}/,/^\$/                                                 {" \
		    -e "/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/=.*$/=\"quiet video=${SCRN_SIZE}\"/  " \
		    -e "/^GRUB_GFXMODE=/               s/=.*$/=${SCRN_SIZE}/                 }"
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -n "$(command -v grub-mkconfig 2> /dev/null)" ]]; then
		GRUB_COMD="grub-mkconfig"
	elif [[ -n "$(command -v grub2-mkconfig 2> /dev/null)" ]]; then
		GRUB_COMD="grub2-mkconfig"
	else
		funcPrintf "not supported on ${DIST_NAME}"
		exit 1
	fi
	GRUB_CONF="$(find /boot/efi/ -name 'grub.cfg' 2> /dev/null || true)"
	if [[ -z "${GRUB_CONF}" ]]; then
		GRUB_CONF="$(find /boot/ -name 'grub.cfg' 2> /dev/null || true)"
	fi
	if [[ -n "${GRUB_CONF}" ]]; then
		funcPrintf "      ${MSGS_TITL}: generating grub configuration file"
		funcPrintf "      ${MSGS_TITL}: ${GRUB_COMD} --output=${GRUB_CONF}"
		"${GRUB_COMD}" --output="${GRUB_CONF}"
	fi
}

# ----- root user -------------------------------------------------------------
function funcApplication_root_user() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="root user"
	# shellcheck disable=SC2312
	declare -r    GRUP_SUDO="$(awk -F ':' '$1=="sudo"||$1=="wheel" {print $1;}' /etc/group)"
	# shellcheck disable=SC2207
	declare -r -a USER_SUDO=($(awk -F ':' '$1=="sudo"||$1=="wheel" {gsub(","," ",$4); print $4;}' /etc/group))
	# shellcheck disable=SC2312
	declare -r    LGIN_SHEL="$(command -v nologin)"			# login shell (disallow system login to samba user)
	# shellcheck disable=SC2312
	declare -r    USER_SHEL="$(awk -F ':' '$1=="root" {print $7;}' /etc/passwd)"
	declare       INPT_STRS=""
	declare -i    RET_CD=0
	declare -i    I=0
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ "${#USER_SUDO[@]}" -le 0 ]]; then
		funcPrintf "      ${MSGS_TITL}: ${GRUP_SUDO} group has no users"
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: ${GRUP_SUDO} group user"
	for ((I=0; I<"${#USER_SUDO[@]}"; I++))
	do
		funcPrintf "      ${MSGS_TITL}: ${USER_SUDO[I]}"
	done
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: after 10 seconds, select [YES] to continue"
	while :
	do
		echo -n "disable root user login? (YES or no)"
		set +e
		read -r -t 10 INPT_STRS
		RET_CD=$?
		set -e
		if [[ ${RET_CD} -ne 0 ]] && [[ -z "${INPT_STRS:-}" ]]; then
			INPT_STRS="YES"
			echo "${INPT_STRS}"
		fi
		case "${INPT_STRS:-}" in
			YES)
				funcPrintf "      ${MSGS_TITL}: how to restore root login"
				funcPrintf "      ${MSGS_TITL}: sudo usermod -s \$(command -v bash) root"
				funcPrintf "      ${MSGS_TITL}: change login shell"
				funcPrintf "      ${MSGS_TITL}: before [${USER_SHEL}]"
				funcPrintf "      ${MSGS_TITL}: after  [${LGIN_SHEL}]"
				usermod -s "${LGIN_SHEL}" root
				RET_CD=$?
				if [[ "${RET_CD}" -eq 0 ]]; then
					funcPrintf "      ${MSGS_TITL}: success"
					break
				fi
				funcPrintf "      ${MSGS_TITL}: failed"
				;;
			no)
				funcPrintf "      ${MSGS_TITL}: cancel"
				break
				;;
			*)
				;;
		esac
	done
}

# --- sound -------------------------------------------------------------------
function funcApplication_sound_wireplumber() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="sound wireplumber"
	declare -r    FILE_PATH="/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if ! $(funcIsPackage 'wireplumber'); then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if [[ -e "${FILE_PATH}" ]]; then
		if [[ ! -e "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	mkdir -p "${FILE_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
		monitor.alsa.rules = [
		  {
		    matches = [
		      # This matches the value of the 'node.name' property of the node.
		      {
		        node.name = "~alsa_output.*"
		      }
		    ]
		    actions = {
		      # Apply all the desired node specific settings here.
		      update-props = {
		        api.alsa.period-size   = 1024
		        api.alsa.headroom      = 8192
		        session.suspend-timeout-seconds = 0
		      }
		    }
		  }
		]
_EOT_
}

# ==== restore ================================================================

# ------ restore file ---------------------------------------------------------
function funcRestore_settings() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="restore"
	declare       FILE_PATH=""
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	# -------------------------------------------------------------------------
	declare -r -a FILE_LIST=(                                          \
		"/etc/NetworkManager/conf.d/dns.conf"                          \
		"/etc/NetworkManager/conf.d/none-dns.conf"                     \
		"/etc/apache2/apache2.conf"                                    \
		"/etc/apt/sources.list"                                        \
		"/etc/chrony.conf"                                             \
		"/etc/clamav/freshclam.conf"                                   \
		"/etc/connman/main.conf"                                       \
		"/etc/default/grub"                                            \
		"/etc/dnsmasq.conf"                                            \
		"/etc/dnsmasq.d/pxe.conf"                                      \
		"/etc/fstab"                                                   \
		"/etc/hosts.allow"                                             \
		"/etc/hosts.deny"                                              \
		"/etc/httpd/conf/httpd.conf"                                   \
		"/etc/locale.gen"                                              \
		"/etc/netplan/99-network-manager-static.yaml"                  \
		"/etc/resolv.conf"                                             \
		"/etc/samba/smb.conf"                                          \
		"/etc/ssh/sshd_config.d/sshd.conf"                             \
		"/etc/systemd/system/connman.service.d/disable_dns_proxy.conf" \
		"/etc/systemd/timesyncd.conf"                                  \
		"/etc/systemd/timesyncd.conf.d/ntp.conf"                       \
		"${HOME}/.bashrc"                                              \
		"${HOME}/.curlrc"                                              \
		"${HOME}/.vimrc"                                               \
		"/root/.bashrc"                                                \
		"/root/.curlrc"                                                \
		"/root/.vimrc"                                                 \
	)
	# -------------------------------------------------------------------------
	declare       SYSD_NAME=""
	declare -r -a SYSD_LIST=(      \
		"connman.service"          \
		"dnsmasq.service"          \
		"systemd-resolved.service" \
	)
	declare -i    I=0
	# -------------------------------------------------------------------------
	funcPrintf "----- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	for ((I=0; I<"${#FILE_LIST[@]}"; I++))
	do
		FILE_PATH="${FILE_LIST[I]}"
		FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
		FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
		if [[ -e "${FILE_PATH}" ]]; then
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
			if [[ -e "${FILE_ORIG}" ]]; then
				cp --archive "${FILE_ORIG}" "${FILE_PATH}"
			fi
		fi
	done
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: daemon reload"
	systemctl --quiet daemon-reload
	for ((I=0; I<"${#SYSD_LIST[@]}"; I++))
	do
		SYSD_NAME="${SYSD_LIST[I]}"
		# shellcheck disable=SC2312,SC2310
		if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
			funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
			systemctl --quiet restart "${SYSD_NAME}"
		fi
	done
#	sleep 1
}

# ==== debug ==================================================================

# ----- system ----------------------------------------------------------------
function funcDebug_system() {
	# --- os information ------------------------------------------------------
	funcPrintf "----- os information ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	funcPrintf "DIST_NAME=${DIST_NAME}"
	funcPrintf "DIST_CODE=${DIST_CODE}"
	funcPrintf "DIST_VERS=${DIST_VERS}"
	funcPrintf "DIST_VRID=${DIST_VRID}"
}

# ----- network ---------------------------------------------------------------
function funcDebug_network() {
	declare -i    I=0
	# --- host name -----------------------------------------------------------
	funcPrintf "----- host name ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	funcPrintf "HOST_FQDN=${HOST_FQDN:-}"
	funcPrintf "HOST_NAME=${HOST_NAME:-}"
	funcPrintf "HOST_DMAN=${HOST_DMAN:-}"
	# --- network parameter ---------------------------------------------------
	funcPrintf "----- network parameter ${TEXT_GAP1}"
	for ((I=0; I<"${#ETHR_NAME[@]}"; I++))
	do
		funcPrintf "ETHR_NAME=${ETHR_NAME[I]:-}"
		funcPrintf "ETHR_MADR=${ETHR_MADR[I]:-}"
		funcPrintf "IPV4_ADDR=${IPV4_ADDR[I]:-}"
		funcPrintf "IPV4_CIDR=${IPV4_CIDR[I]:-}"
		funcPrintf "IPV4_MASK=${IPV4_MASK[I]:-}"
		funcPrintf "IPV4_GWAY=${IPV4_GWAY[I]:-}"
		funcPrintf "IPV4_NSVR=${IPV4_NSVR[I]:-}"
		funcPrintf "IPV4_WGRP=${IPV4_WGRP[I]:-}"
		funcPrintf "IPV4_DHCP=${IPV4_DHCP[I]:-}"
		funcPrintf "IPV4_UADR=${IPV4_UADR[I]:-}"
		funcPrintf "IPV4_LADR=${IPV4_LADR[I]:-}"
		funcPrintf "IPV4_NTWK=${IPV4_NTWK[I]:-}"
		funcPrintf "IPV4_BCST=${IPV4_BCST[I]:-}"
		funcPrintf "IPV4_LGWY=${IPV4_LGWY[I]:-}"
		funcPrintf "IPV4_RADR=${IPV4_RADR[I]:-}"
		funcPrintf "IPV6_ADDR=${IPV6_ADDR[I]:-}"
		funcPrintf "IPV6_CIDR=${IPV6_CIDR[I]:-}"
		funcPrintf "IPV6_MASK=${IPV6_MASK[I]:-}"
		funcPrintf "IPV6_GWAY=${IPV6_GWAY[I]:-}"
		funcPrintf "IPV6_NSVR=${IPV6_NSVR[I]:-}"
		funcPrintf "IPV6_WGRP=${IPV6_WGRP[I]:-}"
		funcPrintf "IPV6_DHCP=${IPV6_DHCP[I]:-}"
		funcPrintf "IPV6_FADR=${IPV6_FADR[I]:-}"
		funcPrintf "IPV6_RADR=${IPV6_RADR[I]:-}"
		funcPrintf "LINK_ADDR=${LINK_ADDR[I]:-}"
		funcPrintf "LINK_CIDR=${LINK_CIDR[I]:-}"
		funcPrintf "LINK_FADR=${LINK_FADR[I]:-}"
		funcPrintf "LINK_RADR=${LINK_RADR[I]:-}"
	done
	funcPrintf "DHCP_SADR=${DHCP_SADR:-}"
	funcPrintf "DHCP_EADR=${DHCP_EADR:-}"
	funcPrintf "DHCP_LEAS=${DHCP_LEAS:-}"
	funcPrintf "NTPS_NAME=${NTPS_NAME:-}"
	funcPrintf "NTPS_ADDR=${NTPS_ADDR:-}"
	funcPrintf "TFTP_ROOT=${TFTP_ROOT:-}"
}

# ----- dns -------------------------------------------------------------------
function funcDebug_dns() {
	declare -i    RET_CD=0
	set +e
	# -------------------------------------------------------------------------
	funcPrintf "----- ping check ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	if command -v ping4 > /dev/null 2>&1; then
		ping4 -c 4 www.google.com
	else
		if ping -4 -c 1 localhost > /dev/null 2>&1; then
			ping -4 -c 4 www.google.com
		else
			ping -c 4 www.google.com
		fi
	fi
	if command -v ping6 > /dev/null 2>&1; then
		# shellcheck disable=SC2312
		funcPrintf "$(funcString "${COLS_SIZE}" '+')"
		ping6 -c 4 www.google.com
	fi
	funcPrintf "----- ping check ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	funcPrintf "----- ss -tulpn | sed -n '/:53/p' ${TEXT_GAP1}"
	if ! ss -tulpn | sed -n '/:53/p'; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- nslookup ${HOST_FQDN} ${TEXT_GAP1}"
	if ! nslookup "${HOST_FQDN}"; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- nslookup ${HOST_FQDN%.*}.local ${TEXT_GAP1}"
	if ! nslookup "${HOST_FQDN%.*}.local"; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- nslookup ${IPV4_ADDR[0]} ${TEXT_GAP1}"
	if ! nslookup "${IPV4_ADDR[0]}"; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- nslookup ${IPV6_ADDR[0]} ${TEXT_GAP1}"
	if ! nslookup "${IPV6_ADDR[0]}"; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- nslookup ${LINK_ADDR[0]} ${TEXT_GAP1}"
	if ! nslookup "${LINK_ADDR[0]}"; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
#	funcPrintf "----- dns check ${TEXT_GAP1}"
#	dig @localhost "${IPV4_RADR[0]}.in-addr.arpa" DNSKEY +dnssec +multi
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '+')"
#	dig @localhost "${HOST_DMAN}" DNSKEY +dnssec +multi
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '+')"
#	dig @"${IPV4_ADDR[0]}" "${HOST_DMAN}" axfr
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '+')"
#	dig @"${IPV6_ADDR[0]}" "${HOST_DMAN}" axfr
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '+')"
#	dig @"${LINK_ADDR[0]}" "${HOST_DMAN}" axfr
	# -------------------------------------------------------------------------
	funcPrintf "----- dig ${HOST_FQDN} A +nostats +nocomments ${TEXT_GAP1}"
	if ! dig "${HOST_FQDN}" A +nostats +nocomments; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- dig ${HOST_FQDN} AAAA +nostats +nocomments ${TEXT_GAP1}"
	if ! dig "${HOST_FQDN}" AAAA +nostats +nocomments; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- dig ${HOST_FQDN%.*}.local A +nostats +nocomments ${TEXT_GAP1}"
	if ! dig "${HOST_FQDN%.*}.local" A +nostats +nocomments; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- dig ${HOST_FQDN%.*}.local AAAA +nostats +nocomments ${TEXT_GAP1}"
	if ! dig "${HOST_FQDN%.*}.local" AAAA +nostats +nocomments; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- dig -x ${IPV4_ADDR[0]} +nostats +nocomments ${TEXT_GAP1}"
	if ! dig -x "${IPV4_ADDR[0]}" +nostats +nocomments; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- dig -x ${IPV6_ADDR[0]} +nostats +nocomments ${TEXT_GAP1}"
	if ! dig -x "${IPV6_ADDR[0]}" +nostats +nocomments; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- dig -x ${LINK_ADDR[0]} +nostats +nocomments ${TEXT_GAP1}"
	if ! dig -x "${LINK_ADDR[0]}" +nostats +nocomments; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	# -------------------------------------------------------------------------
	if command -v getent > /dev/null 2>&1; then
		funcPrintf "----- getent hosts ${HOST_FQDN%.*} ${TEXT_GAP1}"
		if ! getent hosts "${HOST_FQDN%.*}"; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
	# -------------------------------------------------------------------------
	set -e
}

# ----- ntp -------------------------------------------------------------------
function funcDebug_ntp() {
	if command -v chronyc > /dev/null 2>&1; then
		funcPrintf "----- chronyc sources ${TEXT_GAP1}"
		if ! chronyc sources; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	elif command -v timedatectl > /dev/null 2>&1; then
		declare -r    FILE_NAME="/etc/systemd/timesyncd.conf"
		declare -r    FILE_ORIG="${FILE_NAME}/.orig"
		# ---------------------------------------------------------------------
		funcDiff "${FILE_ORIG}" "${FILE_NAME}" "----- diff ${FILE_NAME} ${TEXT_GAP1}"
		# ---------------------------------------------------------------------
		funcPrintf "----- timedatectl status ${TEXT_GAP1}"
		if ! timedatectl status; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
		funcPrintf "----- timedatectl timesync-status ${TEXT_GAP1}"
		if ! timedatectl timesync-status > /dev/null 2>&1; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
}

# ----- smb -------------------------------------------------------------------
function funcDebug_smb() {
	declare -r    BRWS_ADDR="$(nmblookup -M -- - | awk '{print $1;}')"
	declare -r    BRWS_NAME="$(nmblookup -A "${BRWS_ADDR}" | awk '$2=="<00>"&&$4!="<GROUP>" {print $1;}')"
	declare -r    BRWS_WGRP="$(nmblookup -A "${BRWS_ADDR}" | awk '$2=="<00>"&&$4=="<GROUP>" {print $1;}')"
	# -------------------------------------------------------------------------
	funcPrintf "----- nmblookup -M -- - (master browser) ${TEXT_GAP1}"
	funcPrintf "${BRWS_ADDR}"
	funcPrintf "----- nmblookup -A ${BRWS_ADDR} ${TEXT_GAP1}"
	funcPrintf "${BRWS_NAME}"
	funcPrintf "${BRWS_WGRP}"
	# -------------------------------------------------------------------------
	if command -v getent > /dev/null 2>&1; then
		funcPrintf "----- getent hosts ${BRWS_NAME,,} ${TEXT_GAP1}"
		if ! getent hosts "${BRWS_NAME,,}"; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
	# -------------------------------------------------------------------------
	if command -v traceroute > /dev/null 2>&1; then
		funcPrintf "----- traceroute ${BRWS_NAME} ${TEXT_GAP1}"
		if ! traceroute -4 "${BRWS_NAME,,}"; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
	# -------------------------------------------------------------------------
	if command -v pdbedit > /dev/null 2>&1; then
		funcPrintf "----- pdbedit -L ${TEXT_GAP1}"
		if ! pdbedit -L; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
	# -------------------------------------------------------------------------
	if command -v smbclient > /dev/null 2>&1; then
		funcPrintf "----- smbclient -N -L ${HOST_FQDN} ${TEXT_GAP1}"
		if ! smbclient -N -L "${HOST_FQDN}"; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
		funcPrintf "----- smbclient -N -L ${HOST_FQDN%.*}.local ${TEXT_GAP1}"
		if ! smbclient -N -L "${HOST_FQDN%.*}.local"; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
}

# ----- open-vm-tools ---------------------------------------------------------
function funcDebug_open_vm_tools() {
	if [[ ! -d "${HGFS_DIRS}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	funcPrintf "----- df -h ${HGFS_DIRS} ${TEXT_GAP1}"
	if ! LANG=C df -h "${HGFS_DIRS}"; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
}

# ----- lvm -------------------------------------------------------------------
function funcDebug_lvm() {
	funcPrintf "----- lsblk --nodeps --output NAME,TYPE,TRAN,SIZE,VENDOR,MODEL ${TEXT_GAP1}"
	lsblk --nodeps --output NAME,TYPE,TRAN,SIZE,VENDOR,MODEL
	if command -v pvdisplay > /dev/null 2>&1; then
		funcPrintf "----- pvdisplay ${TEXT_GAP1}"
		if ! pvdisplay; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
	if command -v vgdisplay > /dev/null 2>&1; then
		funcPrintf "----- vgdisplay ${TEXT_GAP1}"
		if ! vgdisplay; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
	if command -v lvdisplay > /dev/null 2>&1; then
		funcPrintf "----- lvdisplay ${TEXT_GAP1}"
		if ! lvdisplay; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
}

# ----- firewall --------------------------------------------------------------
function funcDebug_firewall() {
	funcPrintf "----- firewall ${TEXT_GAP1}"
	if ! command -v firewall-cmd > /dev/null 2>&1; then
		return
	fi
	if command -v iptables > /dev/null 2>&1; then
		funcPrintf "----- iptables --version ${TEXT_GAP1}"
		if ! iptables --version; then
			funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
		fi
	fi
	funcPrintf "----- firewall-cmd --get-active-zones ${TEXT_GAP1}"
	if ! firewall-cmd --get-active-zones; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	funcPrintf "----- firewall-cmd --list-all --zone=${FWAL_ZONE} ${TEXT_GAP1}"
	if ! firewall-cmd --list-all --zone="${FWAL_ZONE}"; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
	funcPrintf "----- firewall-cmd --list-all ${TEXT_GAP1}"
	if ! firewall-cmd --list-all; then
		funcPrintf "${TXT_RED}${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
	fi
}

# === cleaning ================================================================

function funcCleaning() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="cleaning"
	declare -r    FILE_ORIG="${DIRS_ARCH}/${PROG_NAME//./_}_orig_${DATE_TIME}.tar.gz"
	declare -r    FILE_BACK="${DIRS_ARCH}/${PROG_NAME//./_}_back_${DATE_TIME}.tar.gz"
	declare -a    LIST_ORIG=()
	declare -a    LIST_BACK=()
	declare       DIRS_LINE=()
	# -------------------------------------------------------------------------
	funcPrintf "     ${MSGS_TITL}: backup orig directory"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2207
	LIST_ORIG=($(find "${DIRS_ORIG/${PWD}\//}" | sort))
	funcPrintf "     ${MSGS_TITL}: list of files to backup"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '+')"
	printf '%s\n' "${LIST_ORIG[@]}"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '+')"
	funcPrintf "     ${MSGS_TITL}: compress files"
	funcPrintf "     ${MSGS_TITL}: ${FILE_ORIG/${PWD}\//}"
	tar -czf "${FILE_ORIG/${PWD}\//}" "${LIST_ORIG[@]}"
	# -------------------------------------------------------------------------
	funcPrintf "     ${MSGS_TITL}: backup back directory"
	# shellcheck disable=SC2207
	LIST_BACK=($(
		for DIRS_LINE in $(find "${DIRS_BACK}" -type d -printf "%P\n" | sort)
		do
			find "${DIRS_BACK/${PWD}\//}/${DIRS_LINE}" -maxdepth 1 \( -type f -o -type l \) | sort | tail -n+4
		done | sort
	))
	if [[ -z "${LIST_BACK[*]}" ]]; then
		funcPrintf "     ${MSGS_TITL}: terminating because there is no target file"
		return
	fi
	funcPrintf "     ${MSGS_TITL}: list of files to backup"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '+')"
	printf '%s\n' "${LIST_BACK[@]}"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '+')"
	funcPrintf "     ${MSGS_TITL}: compress files"
	funcPrintf "     ${MSGS_TITL}: ${FILE_BACK/${PWD}\//}"
	tar -czf "${FILE_BACK/${PWD}\//}" "${LIST_BACK[@]}"
	funcPrintf "     ${MSGS_TITL}: list of files to delete"
	rm -I "${LIST_BACK[@]}"
	funcPrintf "---- ${MSGS_TITL}: remaining files ${TEXT_GAP1}"
	find "${DIRS_BACK/${PWD}\//}" \( -type f -o -type l \) | sort
}

# === call function ===========================================================

# ---- function test ----------------------------------------------------------
function funcCall_function() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call function test"
	declare -r    FILE_WRK1="${DIRS_TEMP}/testfile1.txt"
	declare -r    FILE_WRK2="${DIRS_TEMP}/testfile2.txt"
	declare -r    TEST_ADDR="https://raw.githubusercontent.com/office-itou/Linux/master/Readme.md"
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
		"${TEST_ADDR}"                \
	)
	declare       TEST_PARM=""
	declare -i    I=0
	declare       H1=""
	declare       H2=""
	# -------------------------------------------------------------------------
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
	mkdir -p "${FILE_WRK1%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_WRK1}"
		line 00
		line 01
		line 02
		line 03
		line 04
		line 05
		line 06
		line 07
		line 08
		line 09
		line 10
_EOT_
	mkdir -p "${FILE_WRK2%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_WRK2}"
		line 00
		line 01
		line 02
		line 03
		line 04
		line_05
		line 06
		line 07
		line 08
		line 09
		line 10
_EOT_

	# --- text print test -----------------------------------------------------
	funcPrintf "---- text print test ${TEXT_GAP1}"
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
	# shellcheck disable=SC2312
	funcPrintf "_$(funcString "${COLS_SIZE}" '→')_"
	echo ""

	# --- text color test -----------------------------------------------------
	funcPrintf "---- text color test ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcColorTest"
	funcColorTest
	echo ""

	# --- printf --------------------------------------------------------------
	funcPrintf "---- printf ${TEXT_GAP1}"
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
	funcPrintf "---- diff ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcDiff \"${FILE_WRK1/${PWD}\//}\" \"${FILE_WRK2/${PWD}\//}\" \"function test\""
	funcDiff "${FILE_WRK1/${PWD}\//}" "${FILE_WRK2/${PWD}\//}" "function test"
	funcPrintf "--no-cutting" "diff -y -W \"${COLS_SIZE}\" --suppress-common-lines \"${FILE_WRK1/${PWD}\//}\" \"${FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${COLS_SIZE}" --suppress-common-lines "${FILE_WRK1/${PWD}\//}" "${FILE_WRK2/${PWD}\//}" || true
	funcPrintf "--no-cutting" "diff -y -W \"${COLS_SIZE}\" \"${FILE_WRK1/${PWD}\//}\" \"${FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${COLS_SIZE}" "${FILE_WRK1/${PWD}\//}" "${FILE_WRK2/${PWD}\//}" || true
	funcPrintf "--no-cutting" "diff --color=always -y -W \"${COLS_SIZE}\" \"${FILE_WRK1/${PWD}\//}\" \"${FILE_WRK2/${PWD}\//}\" \"function test\""
	diff --color=always -y -W "${COLS_SIZE}" "${FILE_WRK1/${PWD}\//}" "${FILE_WRK2/${PWD}\//}" || true
	echo ""

	# --- substr --------------------------------------------------------------
	funcPrintf "---- substr ${TEXT_GAP1}"
	TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcSubstr \"${TEST_PARM}\" 1 19"
	funcPrintf "--no-cutting" "         1         2         3         4"
	funcPrintf "--no-cutting" "1234567890123456789012345678901234567890"
	funcPrintf "--no-cutting" "${TEST_PARM}"
	funcSubstr "${TEST_PARM}" 1 19
	echo ""

	# --- service status ------------------------------------------------------
	funcPrintf "---- service status ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcServiceStatus \"sshd.service\""
	funcServiceStatus "sshd.service"
	echo ""

	# --- IPv6 full address ---------------------------------------------------
	funcPrintf "---- IPv6 full address ${TEXT_GAP1}"
	TEST_PARM="fe80::1"
	funcPrintf "--no-cutting" "funcIPv6GetFullAddr \"${TEST_PARM}\""
	funcIPv6GetFullAddr "${TEST_PARM}"
	echo ""

	# --- IPv6 reverse address ------------------------------------------------
	funcPrintf "---- IPv6 reverse address ${TEXT_GAP1}"
	TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcIPv6GetRevAddr \"${TEST_PARM}\""
	funcIPv6GetRevAddr "${TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 netmask conversion ---------------------------------------------
	funcPrintf "---- IPv4 netmask conversion ${TEXT_GAP1}"
	TEST_PARM="24"
	funcPrintf "--no-cutting" "funcIPv4GetNetmask \"${TEST_PARM}\""
	funcIPv4GetNetmask "${TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 cidr conversion ------------------------------------------------
	funcPrintf "---- IPv4 cidr conversion ${TEXT_GAP1}"
	TEST_PARM="255.255.255.0"
	funcPrintf "--no-cutting" "funcIPv4GetNetCIDR \"${TEST_PARM}\""
	funcIPv4GetNetCIDR "${TEST_PARM}"
	echo ""

	# --- is numeric ----------------------------------------------------------
	funcPrintf "---- is numeric ${TEXT_GAP1}"
	TEST_PARM="123.456"
	funcPrintf "--no-cutting" "funcIsNumeric \"${TEST_PARM}\""
	funcIsNumeric "${TEST_PARM}"
	echo ""
	TEST_PARM="abc.def"
	funcPrintf "--no-cutting" "funcIsNumeric \"${TEST_PARM}\""
	funcIsNumeric "${TEST_PARM}"
	echo ""

	# --- string output -------------------------------------------------------
	funcPrintf "---- string output ${TEXT_GAP1}"
	TEST_PARM="50"
	funcPrintf "--no-cutting" "funcString \"${TEST_PARM}\" \"#\""
	funcString "${TEST_PARM}" "#"
	echo ""

	# --- print with screen control -------------------------------------------
	funcPrintf "---- print with screen control ${TEXT_GAP1}"
	TEST_PARM="test"
	funcPrintf "--no-cutting" "funcPrintf \"${TEST_PARM}\""
	funcPrintf "${TEST_PARM}"
	echo ""

	# --- download ------------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'curl'); then
		funcPrintf "---- download ${TEXT_GAP1}"
		funcPrintf "--no-cutting" "funcCurl ${CURL_OPTN[*]}"
		funcCurl "${CURL_OPTN[@]}"
		echo ""
	fi

	# -------------------------------------------------------------------------
	rm -f "${FILE_WRK1}" "${FILE_WRK2}"
	ls -l "${DIRS_TEMP}"
}

# ---- debug parameter --------------------------------------------------------
function funcDbg_parameter() {
	echo "${!PROG_*}"
	echo "${!DIRS_*}"

	# --- working directory name ----------------------------------------------
	printf "%s=[%s]\n"	"PROG_PATH"		"${PROG_PATH:-}"
	printf "%s=[%s]\n"	"PROG_PARM"		"${PROG_PARM[@]:-}"
	printf "%s=[%s]\n"	"PROG_DIRS"		"${PROG_DIRS:-}"
	printf "%s=[%s]\n"	"PROG_NAME"		"${PROG_NAME:-}"
	printf "%s=[%s]\n"	"PROG_PROC"		"${PROG_PROC:-}"
	printf "%s=[%s]\n"	"DIRS_WORK"		"${DIRS_WORK:-}"
	printf "%s=[%s]\n"	"DIRS_BACK"		"${DIRS_BACK:-}"
	printf "%s=[%s]\n"	"DIRS_BLDR"		"${DIRS_BLDR:-}"
	printf "%s=[%s]\n"	"DIRS_CHRT"		"${DIRS_CHRT:-}"
	printf "%s=[%s]\n"	"DIRS_CONF"		"${DIRS_CONF:-}"
	printf "%s=[%s]\n"	"DIRS_HTML"		"${DIRS_HTML:-}"
	printf "%s=[%s]\n"	"DIRS_IMGS"		"${DIRS_IMGS:-}"
	printf "%s=[%s]\n"	"DIRS_ISOS"		"${DIRS_ISOS:-}"
	printf "%s=[%s]\n"	"DIRS_KEYS"		"${DIRS_KEYS:-}"
	printf "%s=[%s]\n"	"DIRS_LIVE"		"${DIRS_LIVE:-}"
	printf "%s=[%s]\n"	"DIRS_ORIG"		"${DIRS_ORIG:-}"
	printf "%s=[%s]\n"	"DIRS_PKGS"		"${DIRS_PKGS:-}"
	printf "%s=[%s]\n"	"DIRS_RMAK"		"${DIRS_RMAK:-}"
	printf "%s=[%s]\n"	"DIRS_TEMP"		"${DIRS_TEMP:-}"
	printf "%s=[%s]\n"	"DIRS_TFTP"		"${DIRS_TFTP:-}"

	# --- server service ------------------------------------------------------
	printf "%s=[%s]\n"	"HTML_ROOT"		"${HTML_ROOT:-}"
	printf "%s=[%s]\n"	"TFTP_ROOT"		"${TFTP_ROOT:-}"

	# --- work variables ------------------------------------------------------
	printf "%s=[%s]\n"	"OLD_IFS"		"${OLD_IFS:-}"

	# --- set minimum display size --------------------------------------------
	printf "%s=[%4d]\n"	"ROWS_SIZE"		"${ROWS_SIZE:-}"
	printf "%s=[%4d]\n"	"COLS_SIZE"		"${COLS_SIZE:-}"

	# --- text gap ------------------------------------------------------------
	printf "%s\n%s\n"	"TEXT_GAP1"		"${TEXT_GAP1:-}"
	printf "%s\n%s\n"	"TEXT_GAP2"		"${TEXT_GAP2:-}"
}

# ---- cleaning ---------------------------------------------------------------
function funcCall_cleaning() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call cleaning"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	COMD_LIST=("${@:-}")
	funcCleaning
	COMD_RETN="COMD_LIST[@]:-}"
}

# ---- debug ------------------------------------------------------------------
function funcCall_debug() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call debug"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("sys" "net" "ntp" "smb" "vm" "lvm" "fwall" "$@")
		IFS=' =,'
		set -f
		set -- "${COMD_LIST[@]:-}"
		set +f
		IFS=${OLD_IFS}
	fi
	while [[ -n "${1:-}" ]]
	do
		COMD_LIST=("${@:-}")
		case "${1:-}" in
			func )						# ===== function test =================
				funcCall_function
				;;
			text )						# ===== text color test ===============
				funcColorTest
				;;
			parm )						# ===== print parameter ===============
				funcDbg_parameter
				;;
			sys )						# ===== system ========================
				funcDebug_system
				;;
			net )						# ===== network =======================
				funcDebug_network
				funcDebug_dns
				;;
			ntp )						# ===== ntp ===========================
				funcDebug_ntp
				;;
			smb )						# ===== smb ===========================
				funcDebug_smb
				;;
			vm )						# ===== open-vm-tools =================
				funcDebug_open_vm_tools
				;;
			lvm )						# ===== lvm ===========================
				funcDebug_lvm
				;;
			fwall )						# ===== firewall ======================
				funcDebug_firewall
				;;
			-* )
				break
				;;
			* )
				;;
		esac
		shift
	done
	COMD_RETN="COMD_LIST[@]:-}"
}

# ---- restore ----------------------------------------------------------------
function funcCall_restore() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call restore"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	COMD_LIST=("${@:-}")
	funcRestore_settings	
	COMD_RETN="COMD_LIST[@]:-}"
}

# ---- network ----------------------------------------------------------------
function funcCall_network() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call network"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("nss" "host" "aldy" "svce" "nic" "resolv" "tftp" "pxe" "$@")
		IFS=' =,'
		set -f
		set -- "${COMD_LIST[@]:-}"
		set +f
		IFS=${OLD_IFS}
	fi
	while [[ -n "${1:-}" ]]
	do
		COMD_LIST=("${@:-}")
		case "${1:-}" in
			nss )						# ===== nsswitch ======================
				funcNetwork_nsswitch
				;;
			host )						# ===== hosts =========================
				funcNetwork_hosts
				;;
			aldy )						# ===== hosts.allow / hosts.deny ======
				funcNetwork_hosts_allow_deny
				;;
			svce )						# ===== service =======================
				funcNetwork_dnsmasq
				;;
			nic )						# ===== nic ===========================
				# ------ connman ----------------------------------
				# shellcheck disable=SC2312
				if [[ -n "$(command -v connmanctl 2> /dev/null)" ]]; then
					funcNetwork_connmanctl
				fi
				# ------ netplan ----------------------------------
				# shellcheck disable=SC2312
				if [[ -n "$(command -v netplan 2> /dev/null)" ]]; then
					funcNetwork_netplan
				fi
				# ------ networkmanager ---------------------------
				# shellcheck disable=SC2312
				if [[ -n "$(command -v nmcli 2> /dev/null)" ]]; then
					funcNetwork_networkmanager
				fi
				;;
			resolv )					# ===== resolv.conf ===================
				funcNetwork_resolv_conf
				;;
			tftp )						# ===== tftpd-hpa =====================
				funcNetwork_tftpd_hpa
				;;
			pxe )						# ===== pxe.conf ======================
				funcNetwork_pxe_conf
				;;
			-* )
				break
				;;
			* )
				;;
		esac
		shift
	done
	COMD_RETN="COMD_LIST[@]:-}"
}

# ---- package ----------------------------------------------------------------
function funcCall_package() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call package"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("pmn" "fwall" "ctl" "sys" "usr" "av" "ntp" "ssh" "dns" "web" "smb" "vm" "grub" "root" "sound" "$@")
		IFS=' =,'
		set -f
		set -- "${COMD_LIST[@]:-}"
		set +f
		IFS=${OLD_IFS}
	fi
	while [[ -n "${1:-}" ]]
	do
		COMD_LIST=("${@:-}")
		case "${1:-}" in
			pmn )						# ===== package manager ===============
				funcApplication_package_manager
				;;
			fwall )						# ===== firewall ======================
				funcApplication_firewall
				;;
			ctl )						# ===== system control ================
				funcSystem_control
				;;
			sys )						# ===== system ========================
				funcApplication_system_kernel
				funcApplication_system_shared_directory
				funcApplication_system_user_environment
				;;
			syskrn )					# ===== system kernel =================
				funcApplication_system_kernel
				;;
			sysenv )					# ===== system environment ============
				funcApplication_system_user_environment
				;;
			sysdir )					# ===== system shared directory =======
				funcApplication_system_shared_directory
				;;
			usr )						# ===== user add ======================
				funcApplication_user_add
				;;
			av  )						# ===== clamav ========================
				funcApplication_clamav
				;;
			ntp )						# ===== ntp ===========================
				funcApplication_ntp_chrony
				funcApplication_ntp_timesyncd
				;;
			ssh )						# ===== openssh-server ================
				funcApplication_openssh
				;;
			dns )						# ===== dnsmasq =======================
				funcApplication_dnsmasq
				;;
			web )						# ===== apache2 =======================
				funcApplication_apache
				;;
			smb )						# ===== samba =========================
				funcApplication_samba
				;;
			smbex )						# ===== samba user export =============
				funcApplication_user_export
				;;
			vm )						# ===== open-vm-tools =================
				funcApplication_open_vm_tools
				;;
			grub )						# ===== grub ==========================
				funcApplication_grub
				;;
			root )						# ===== root user =====================
				funcApplication_root_user
				;;
			sound )						# ==== sound ==========================
				funcApplication_sound_wireplumber
				;;
			-* )
				break
				;;
			* )
				;;
		esac
		shift
	done
	COMD_RETN="COMD_LIST[@]:-}"
}

# ---- all --------------------------------------------------------------------
function funcCall_all() {
#	declare -r    OLD_IFS="${IFS}"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	funcPrintf "---- call all process ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("--network" "--package" "$@")
		IFS=' =,'
		set -f
		set -- "${COMD_LIST[@]:-}"
		set +f
		IFS=${OLD_IFS}
	fi
	while [[ -n "${1:-}" ]]
	do
		COMD_LIST=("${@:-}")
		case "${1:-}" in
			-n | --network )			# ==== network ========================
				funcCall_network COMD_LINE "$@"
				;;
			-p | --package )			# ==== package ========================
				funcCall_package COMD_LINE "$@"
				;;
			* )
				break
				;;
		esac
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
	if command -v tput > /dev/null 2>&1; then
		ROWS_SIZE=$(tput lines)
		COLS_SIZE=$(tput cols)
	fi
	if [[ "${ROWS_SIZE}" -lt 25 ]]; then
		ROWS_SIZE=25
	fi
	if [[ "${COLS_SIZE}" -lt 80 ]]; then
		COLS_SIZE=80
	fi

	TEXT_GAP1="$(funcString "${COLS_SIZE}" '-')"
	TEXT_GAP2="$(funcString "${COLS_SIZE}" '=')"

	readonly TEXT_GAP1
	readonly TEXT_GAP2

	# --- main ----------------------------------------------------------------
	start_time=$(date +%s)
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"
	funcPrintf "--- start ${TEXT_GAP1}"
	funcPrintf "--- main ${TEXT_GAP1}"
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
		funcPrintf ""
		funcPrintf "all install process (same as --network and --package)"
		funcPrintf "  -a | --all"
		funcPrintf ""
		funcPrintf "network settings (empty is [ options ])"
		funcPrintf "  -n | --network [ nss host aldy svce nic resolv tftp pxe ]"
		funcPrintf "    nss     nsswitch"
		funcPrintf "    host    hosts"
		funcPrintf "    aldy    hosts.allow / hosts.deny"
		funcPrintf "    svce    service"
		funcPrintf "    nic     connman netplan networkmanager"
		funcPrintf "    resolv  resolv.conf"
		funcPrintf "    tftpd   tftp server"
		funcPrintf "    pxe     pxe boot (dnsmasq)"
		funcPrintf ""
		funcPrintf "package settings (empty is [ options ])"
		funcPrintf "  -p | --package [ pmn fwall ctl sys usr av ntp ssh dns web smb vm grub root ]"
		funcPrintf "    pmn     package manager"
		funcPrintf "    fwall   firewall"
		funcPrintf "    ctl     system control"
		funcPrintf "    sys     [ syskrn sysenv sysdir ]"
		funcPrintf "    syskrn  system kernel"
		funcPrintf "    sysenv  system environment"
		funcPrintf "    sysdir  system shared directory"
		funcPrintf "    usr     user add"
		funcPrintf "    av      clamav"
		funcPrintf "    ntp     ntp"
		funcPrintf "    ssh     ssh"
		funcPrintf "    dns     dnsmasq"
		funcPrintf "    web     apache2"
		funcPrintf "    smb     samba"
		funcPrintf "    smbex   samba user export"
		funcPrintf "    vm      open-vm-tools"
		funcPrintf "    grub    grub"
		funcPrintf "    root    disable root user login"
		funcPrintf ""
		funcPrintf "debug print and test (empty is [ options ])"
		funcPrintf "  -d | --debug [ sys net ntp smb vm lvm fwall ]"
		funcPrintf "    func    function test"
		funcPrintf "    text    text color test"
		funcPrintf "    sys     system"
		funcPrintf "    net     network"
		funcPrintf "    ntp     ntp"
		funcPrintf "    smb     smb"
		funcPrintf "    vm      open-vm-tools"
		funcPrintf "    lvm     lvm"
		funcPrintf "    fwall   firewall"
		funcPrintf ""
		funcPrintf "restoring original files"
		funcPrintf "  -r | --restore"
		funcPrintf ""
		funcPrintf "compressing backup files"
		funcPrintf "  -c | --cleaning"
	else
		mkdir -p "${DIRS_WORK}/"{arch,back,orig,temp}
		chown root: "${DIRS_WORK}"
		chmod 700   "${DIRS_WORK}"

		# --- setting default values ------------------------------------------
		funcPrintf "---- parameter ${TEXT_GAP1}"
		# ---------------------------------------------------------------------
		funcSystem_parameter				# system parameter
		# ---------------------------------------------------------------------
		funcNetwork_parameter				# network parameter
		# ---------------------------------------------------------------------
		funcPrintf "---- system information ${TEXT_GAP1}"
		funcPrintf "     distribution name  : ${DIST_NAME:-}"
		funcPrintf "     code name          : ${DIST_CODE:-}"
		funcPrintf "     version name       : ${DIST_VERS:-}"
		funcPrintf "     version number     : ${DIST_VRID:-}"
		funcPrintf "---- network information ${TEXT_GAP1}"
		funcPrintf "     network device name: ${ETHR_NAME[0]:-}"
		funcPrintf "     network mac address: ${ETHR_MADR[0]:-}"
		funcPrintf "     IPv4 address       : ${IPV4_ADDR[0]:-}"
		funcPrintf "     IPv4 cidr          : ${IPV4_CIDR[0]:-}"
		funcPrintf "     IPv4 subnetmask    : ${IPV4_MASK[0]:-}"
		funcPrintf "     IPv4 gateway       : ${IPV4_GWAY[0]:-}"
		funcPrintf "     IPv4 nameserver    : ${IPV4_NSVR[0]:-}"
		funcPrintf "     IPv4 domain        : ${IPV4_WGRP[0]:-}"
		funcPrintf "     IPv4 dhcp mode     : ${IPV4_DHCP[0]:-}"
		funcPrintf "     IPv6 address       : ${IPV6_ADDR[0]:-}"
		funcPrintf "     IPv6 cidr          : ${IPV6_CIDR[0]:-}"
		funcPrintf "     IPv6 subnetmask    : ${IPV6_MASK[0]:-}"
		funcPrintf "     IPv6 gateway       : ${IPV6_GWAY[0]:-}"
		funcPrintf "     IPv6 nameserver    : ${IPV6_NSVR[0]:-}"
		funcPrintf "     IPv6 domain        : ${IPV6_WGRP[0]:-}"
		funcPrintf "     IPv6 dhcp mode     : ${IPV6_DHCP[0]:-}"
		funcPrintf "     LINK address       : ${LINK_ADDR[0]:-}"
		funcPrintf "     LINK cidr          : ${LINK_CIDR[0]:-}"
		# ---------------------------------------------------------------------
		IFS=' =,'
		set -f
		set -- "${COMD_LINE[@]:-}"
		set +f
		IFS=${OLD_IFS}
		while [[ -n "${1:-}" ]]
		do
			case "${1:-}" in
				-a | --all       )			# ==== all ========================
					funcCall_all COMD_LINE "$@"
					;;
				-c | --cleaning )			# ==== cleaning ===================
					funcCall_cleaning COMD_LINE "$@"
					;;
				-d | --debug   )			# ==== debug ======================
					funcCall_debug COMD_LINE "$@"
					;;
				-r | --restore )			# ==== restore ====================
					funcCall_restore COMD_LINE "$@"
					;;
				-n | --network )			# ==== network ====================
					funcCall_network COMD_LINE "$@"
					;;
				-p | --package )			# ==== package ====================
					funcCall_package COMD_LINE "$@"
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
	funcPrintf "--- complete ${TEXT_GAP1}"
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
