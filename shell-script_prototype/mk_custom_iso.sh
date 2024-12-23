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
			"curl" \
			"wget" \
			"fdisk" \
			"file" \
			"initramfs-tools-core" \
			"isolinux" \
			"isomd5sum" \
			"procps" \
			"xorriso" \
			"xxd" \
			"cpio" \
			"gzip" \
			"zstd" \
			"xz-utils" \
			"lz4" \
			"bzip2" \
			"lzop" \
		)
		declare -r -a APP_FIND=("$(LANG=C apt list "${APP_TGET[@]}" 2> /dev/null | sed -ne '/^[ \t]*$\|WARNING\|Listing\|installed/! s%/.*%%gp' | sed -z 's/[\r\n]\+/ /g')")
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

	# --- tftp server ---------------------------------------------------------
	# funcNetwork_pxe_conf creates directory
	#
	# tree diagram (developed for debian)
	#   [tree --charset C -n --filesfirst -d share/]
	#   
	#   ${HOME}/share
	#   |-- back ------------------------------------------ backup directory
	#   |-- bldr ------------------------------------------ custom boot loader
	#   |-- chrt ------------------------------------------ change root directory
	#   |   `-- srv
	#   |       `-- user
	#   |           |-- install.sh ------------------------ initial configuration shell
	#   |           |-- mk_custom_iso.sh ------------------ custom iso image creation shell
	#   |           |-- mk_pxeboot_conf.sh ---------------- pxeboot configuration shell
	#   |           |-- mk_live_media.sh ------------------ custom live iso image creation shell
	#   |           `-- share <- ${HOME}/share
	#   |-- conf ------------------------------------------ configuration file
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
	#   |   |   `-- live_0000-user-conf-hook.sh
	#   |   `-- windows
	#   |       |-- bypass.cmd
	#   |       |-- inst_w10.cmd
	#   |       |-- inst_w11.cmd
	#   |       |-- shutdown.cmd
	#   |       |-- startnet.cmd
	#   |       |-- unattend.xml
	#   |       `-- winpeshl.ini
	#   |-- html <- /var/www/html ------------------------- html contents
	#   |   |-- memdisk
	#   |   |-- conf -> ../conf
	#   |   |-- imgs -> ../imgs
	#   |   |-- isos -> ../isos
	#   |   |-- load -> ../tftp/load
	#   |   `-- rmak -> ../rmak
	#   |-- imgs ------------------------------------------ iso file extraction destination
	#   |-- isos ------------------------------------------ iso file
	#   |-- keys ------------------------------------------ keyring file
	#   |-- live ------------------------------------------ live media file
	#   |-- orig ------------------------------------------ backup directory (original file)
	#   |-- pkgs ------------------------------------------ package file's directory
	#   |   |-- debian
	#   |   `-- ubuntu
	#   |-- rmak ------------------------------------------ remake file
	#   |-- temp ------------------------------------------ temporary directory
	#   `-- tftp <- /var/lib/tftpboot --------------------- tftp contents
	#       |-- autoexec.ipxe ----------------------------- ipxe script file (menu file)
	#       |-- memdisk ----------------------------------- memdisk of syslinux
	#       |-- boot
	#       |   `-- grub
	#       |       |-- bootx64.efi ----------------------- bootloader (i386-pc-pxe)
	#       |       |-- grub.cfg -------------------------- menu base
	#       |       |-- menu.cfg -------------------------- menu file
	#       |       |-- pxelinux.0 ------------------------ bootloader (x86_64-efi)
	#       |       |-- fonts
	#       |       |   `-- unicode.pf2
	#       |       |-- i386-efi
	#       |       |-- i386-pc
	#       |       |-- locale
	#       |       `-- x86_64-efi
	#       |-- imgs -> ../imgs
	#       |-- ipxe -------------------------------------- ipxe module
	#       |   |-- ipxe.efi
	#       |   |-- undionly.kpxe
	#       |   `-- wimboot
	#       |-- isos -> ../isos
	#       |-- load -------------------------------------- load module
	#       |-- menu-bios
	#       |   |-- syslinux.cfg -------------------------- syslinux configuration for mbr environment
	#       |   |-- imgs -> ../../imgs
	#       |   |-- isos -> ../../isos
	#       |   |-- load -> ../load
	#       |   `-- pxelinux.cfg
	#       |       `-- default -> ../syslinux.cfg
	#       `-- menu-efi64
	#           |-- syslinux.cfg -------------------------- syslinux configuration for uefi(x86_64) environment
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
	#   `-- pxe.conf -------------------------------------- pxeboot dnsmasq configuration file
	#   

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

	declare -r    DIRS_BACK="${DIRS_WORK}/back"					# backup directory
	declare -r    DIRS_BLDR="${DIRS_WORK}/bldr"					# custom boot loader
	declare -r    DIRS_CHRT="${DIRS_WORK}/chrt"					# change root directory
	declare -r    DIRS_CONF="${DIRS_WORK}/conf"					# configuration file
	declare -r    DIRS_HTML="${DIRS_WORK}/html"					# html contents
	declare -r    DIRS_IMGS="${DIRS_WORK}/imgs"					# iso file extraction destination
	declare -r    DIRS_ISOS="${DIRS_WORK}/isos"					# iso file
	declare -r    DIRS_KEYS="${DIRS_WORK}/keys"					# keyring file
	declare -r    DIRS_LIVE="${DIRS_WORK}/live"					# live media file
	declare -r    DIRS_ORIG="${DIRS_WORK}/orig"					# backup directory (original file)
	declare -r    DIRS_PKGS="${DIRS_WORK}/pkgs"					# package file's directory
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
	declare       TEXT_GAP1=""
	declare       TEXT_GAP2=""

# --- niceness values ---------------------------------------------------------
	declare -r -i NICE_VALU=19								# -20: favorable to the process
															#  19: least favorable to the process
	declare -r -i IONICE_CLAS=3								#   1: Realtime
															#   2: Best-effort
															#   3: Idle
#	declare -r -i IONICE_VALU=7								#   0: favorable to the process
															#   7: least favorable to the process

# --- set parameters ----------------------------------------------------------

	# === menu ================================================================

	# --- menu timeout --------------------------------------------------------
	declare -r    MENU_TOUT="50"							# timeout [m sec]

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
	declare -r    MENU_DPTH="16"							# 65536
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
	declare -r    SCRN_MODE="791"							# e	317	1024x 768x16	VESA
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

	# === network =============================================================

#	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"		# hostname
	declare -r    WGRP_NAME="workgroup"						# domain
	declare -r    ETHR_NAME="ens160"						# network device name
	declare -r    IPV4_ADDR="192.168.1.1"					# IPv4 address
	declare -r    IPV4_CIDR="24"							# IPv4 cidr
	declare -r    IPV4_MASK="255.255.255.0"					# IPv4 subnetmask
	declare -r    IPV4_GWAY="192.168.1.254"					# IPv4 gateway
	declare -r    IPV4_NSVR="192.168.1.254"					# IPv4 nameserver

	declare -r -a CURL_OPTN=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -r -a WGET_OPTN=("--tries=3" "--timeout=10" "--no-verbose")

	# === system ==============================================================

	# --- tftp / web server address -------------------------------------------
	# shellcheck disable=SC2155
	declare -r    SRVR_ADDR="$(LANG=C ip -4 -oneline address show scope global | awk '{split($4,s,"/"); print s[1];}')"
#	declare -r    TFTP_PROT="http://"
#	declare -r    TFTP_ADDR="\${net_default_server}"
#	declare -r    HTTP_ADDR="http://\${svraddr}"

	# --- open-vm-tools -------------------------------------------------------
	declare -r    HGFS_DIRS="/mnt/hgfs/workspace/Image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
#	declare -r    CONF_LINK="${HGFS_DIRS}/linux/bin/conf/_template"
	declare -r    CONF_DIRS="${DIRS_CONF}/_template"
	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	# --- directory list ------------------------------------------------------
	declare -r -a LIST_DIRS=(                                                                                           \
		"${DIRS_WORK}"                                                                                                  \
		"${DIRS_BACK}"                                                                                                  \
		"${DIRS_BLDR}"                                                                                                  \
		"${DIRS_CHRT}"                                                                                                  \
		"${DIRS_CONF}"/{_template,autoyast,kickstart,nocloud,preseed,script,windows}                                    \
		"${DIRS_HTML}"                                                                                                  \
		"${DIRS_IMGS}"                                                                                                  \
		"${DIRS_ISOS}"                                                                                                  \
		"${DIRS_KEYS}"                                                                                                  \
		"${DIRS_LIVE}"                                                                                                  \
		"${DIRS_ORIG}"                                                                                                  \
		"${DIRS_PKGS}"                                                                                                  \
		"${DIRS_RMAK}"                                                                                                  \
		"${DIRS_TEMP}"                                                                                                  \
		"${DIRS_TFTP}"/{boot/grub/{fonts,i386-{efi,pc},locale,x86_64-efi},ipxe,load,menu-{bios,efi64}/pxelinux.cfg}     \
	)

	# --- symbolic link list --------------------------------------------------
	declare -r -a LIST_LINK=(                                                                                           \
		"${HGFS_DIRS}/linux/bin/conf                        ${DIRS_CONF}"                                               \
		"${HGFS_DIRS}/linux/bin/keyring                     ${DIRS_KEYS}"                                               \
		"${HGFS_DIRS}/linux/bin/pkgs                        ${DIRS_PKGS}"                                               \
		"${HGFS_DIRS}/linux/bin/rmak                        ${DIRS_RMAK}"                                               \
		"${DIRS_HTML}                                       ${HTML_ROOT}"                                               \
		"${DIRS_TFTP}                                       ${TFTP_ROOT}"                                               \
		"${DIRS_CONF}                                       ${DIRS_HTML}/"                                              \
		"${DIRS_IMGS}                                       ${DIRS_HTML}/"                                              \
		"${DIRS_ISOS}                                       ${DIRS_HTML}/"                                              \
		"${DIRS_TFTP}/load                                  ${DIRS_HTML}/"                                              \
		"${DIRS_RMAK}                                       ${DIRS_HTML}/"                                              \
		"${DIRS_IMGS}                                       ${DIRS_TFTP}/"                                              \
		"${DIRS_ISOS}                                       ${DIRS_TFTP}/"                                              \
		"${DIRS_BLDR}                                       ${DIRS_TFTP}/load/"                                         \
		"${DIRS_IMGS}                                       ${DIRS_TFTP}/menu-bios/"                                    \
		"${DIRS_ISOS}                                       ${DIRS_TFTP}/menu-bios/"                                    \
		"${DIRS_TFTP}/load                                  ${DIRS_TFTP}/menu-bios/"                                    \
		"${DIRS_TFTP}/menu-bios/syslinux.cfg                ${DIRS_TFTP}/menu-bios/pxelinux.cfg/default"                \
		"${DIRS_IMGS}                                       ${DIRS_TFTP}/menu-efi64/"                                   \
		"${DIRS_ISOS}                                       ${DIRS_TFTP}/menu-efi64/"                                   \
		"${DIRS_TFTP}/load                                  ${DIRS_TFTP}/menu-efi64/"                                   \
		"${DIRS_TFTP}/menu-efi64/syslinux.cfg               ${DIRS_TFTP}/menu-efi64/pxelinux.cfg/default"               \
	) #	0:target											1:symlink

	# --- autoinstall configuration file --------------------------------------
	declare -r    AUTO_INST="autoinst.cfg"

	# --- initial ram disk of mini.iso including preseed ----------------------
	declare -r    MINI_IRAM="initps.gz"

	# --- media information ---------------------------------------------------
	#  0: [m] menu / [o] output / [else] hidden
	#  1: iso image file copy destination directory
	#  2: entry name
	#  3: [unused]
	#  4: iso image file directory
	#  5: iso image file name
	#  6: boot loader's directory
	#  7: initial ramdisk
	#  8: kernel
	#  9: configuration file
	# 10: iso image file copy source directory
	# 11: release date
	# 12: support end
	# 13: time stamp
	# 14: file size
	# 15: volume id
	# 16: status
	# 17: download URL
	# 18: time stamp of remastered image file

#	declare -a    DATA_LIST=()

	# --- mini.iso ------------------------------------------------------------
	declare -r -a DATA_LIST_MINI=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        \
		"m  menu-entry                  Auto%20install%20mini.iso               -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-mini-10              Debian%2010                             debian              ${DIRS_ISOS}    mini-buster-amd64.iso                           .                                       initrd.gz                   linux                   preseed/ps_debian_server_oldold.cfg     ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/mini.iso                                                " \
		"o  debian-mini-11              Debian%2011                             debian              ${DIRS_ISOS}    mini-bullseye-amd64.iso                         .                                       initrd.gz                   linux                   preseed/ps_debian_server_old.cfg        ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso                                              " \
		"o  debian-mini-12              Debian%2012                             debian              ${DIRS_ISOS}    mini-bookworm-amd64.iso                         .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso                                              " \
		"o  debian-mini-13              Debian%2013                             debian              ${DIRS_ISOS}    mini-trixie-amd64.iso                           .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso                                                " \
		"-  debian-mini-14              Debian%2014                             debian              ${DIRS_ISOS}    mini-forky-amd64.iso                            .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso                                                 " \
		"o  debian-mini-testing         Debian%20testing                        debian              ${DIRS_ISOS}    mini-testing-amd64.iso                          .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso                                                                               " \
		"o  ubuntu-mini-18.04           Ubuntu%2018.04                          ubuntu              ${DIRS_ISOS}    mini-bionic-amd64.iso                           .                                       initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso                                     " \
		"o  ubuntu-mini-20.04           Ubuntu%2020.04                          ubuntu              ${DIRS_ISOS}    mini-focal-amd64.iso                            .                                       initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso                               " \
		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                           2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- netinst -------------------------------------------------------------
	declare -r -a DATA_LIST_NET=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         \
		"m  menu-entry                  Auto%20install%20Net%20install          -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-netinst-10           Debian%2010                             debian              ${DIRS_ISOS}    debian-10.13.0-amd64-netinst.iso                install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_oldold.cfg     ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-10.[0-9.]*-amd64-netinst.iso                                " \
		"o  debian-netinst-11           Debian%2011                             debian              ${DIRS_ISOS}    debian-11.11.0-amd64-netinst.iso                install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_old.cfg        ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-11.[0-9.]*-amd64-netinst.iso                                   " \
		"o  debian-netinst-12           Debian%2012                             debian              ${DIRS_ISOS}    debian-12.8.0-amd64-netinst.iso                 install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso                                            " \
		"o  debian-netinst-13           Debian%2013                             debian              ${DIRS_ISOS}    debian-13.0.0-amd64-netinst.iso                 install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"-  debian-netinst-14           Debian%2014                             debian              ${DIRS_ISOS}    debian-14.0.0-amd64-netinst.iso                 install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  debian-netinst-testing      Debian%20testing                        debian              ${DIRS_ISOS}    debian-testing-amd64-netinst.iso                install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso                                " \
		"x  fedora-netinst-38           Fedora%20Server%2038                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-38-1.6.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-38_net.cfg          ${HGFS_DIRS}/linux/fedora        2023-04-18  2024-05-14  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-netinst-x86_64-38-[0-9.]*.iso                  " \
		"x  fedora-netinst-39           Fedora%20Server%2039                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-39-1.5.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-39_net.cfg          ${HGFS_DIRS}/linux/fedora        2023-11-07  2024-11-12  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-netinst-x86_64-39-[0-9.]*.iso                  " \
		"o  fedora-netinst-40           Fedora%20Server%2040                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-40-1.14.iso        images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-40_net.cfg          ${HGFS_DIRS}/linux/fedora        2024-04-16  2025-05-13  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-netinst-x86_64-40-[0-9.]*.iso                  " \
		"o  fedora-netinst-41           Fedora%20Server%2041                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-41-1.4.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-41_net.cfg          ${HGFS_DIRS}/linux/fedora        202x-xx-xx  202x-xx-xx  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41-[0-9.]*.iso                  " \
		"x  fedora-netinst-41           Fedora%20Server%2041                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-41_Beta-1.2.iso    images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-41_net.cfg          ${HGFS_DIRS}/linux/fedora        202x-xx-xx  202x-xx-xx  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/test/41_Beta/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41_Beta-[0-9.]*.iso   " \
		"x  centos-stream-netinst-8     CentOS%20Stream%208                     centos              ${DIRS_ISOS}    CentOS-Stream-8-x86_64-latest-boot.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-8_net.cfg    ${HGFS_DIRS}/linux/centos        20xx-xx-xx  2024-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-boot.iso                                             " \
		"o  centos-stream-netinst-9     CentOS%20Stream%209                     centos              ${DIRS_ISOS}    CentOS-Stream-9-latest-x86_64-boot.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-9_net.cfg    ${HGFS_DIRS}/linux/centos        2021-xx-xx  2027-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                                " \
		"o  centos-stream-netinst-10    CentOS%20Stream%2010                    centos              ${DIRS_ISOS}    CentOS-Stream-10-latest-x86_64-boot.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-10_net.cfg   ${HGFS_DIRS}/linux/centos        2024-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso                              " \
		"o  almalinux-netinst-9         Alma%20Linux%209                        almalinux           ${DIRS_ISOS}    AlmaLinux-9-latest-x86_64-boot.iso              images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_almalinux-9_net.cfg        ${HGFS_DIRS}/linux/almalinux     2022-05-26  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9[0-9.]*-latest-x86_64-boot.iso                                                   " \
		"o  rockylinux-netinst-8        Rocky%20Linux%208                       Rocky               ${DIRS_ISOS}    Rocky-8.10-x86_64-boot.iso                      images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-8_net.cfg       ${HGFS_DIRS}/linux/Rocky         2022-11-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-boot.iso                                                         " \
		"o  rockylinux-netinst-9        Rocky%20Linux%209                       Rocky               ${DIRS_ISOS}    Rocky-9-latest-x86_64-boot.iso                  images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-9_net.cfg       ${HGFS_DIRS}/linux/Rocky         2022-07-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9[0-9.]*-latest-x86_64-boot.iso                                                  " \
		"o  miraclelinux-netinst-8      Miracle%20Linux%208                     miraclelinux        ${DIRS_ISOS}    MIRACLELINUX-8.10-rtm-minimal-x86_64.iso        images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-8_net.cfg     ${HGFS_DIRS}/linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-minimal-x86_64.iso                   " \
		"o  miraclelinux-netinst-9      Miracle%20Linux%209                     miraclelinux        ${DIRS_ISOS}    MIRACLELINUX-9.4-rtm-minimal-x86_64.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-9_net.cfg     ${HGFS_DIRS}/linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-minimal-x86_64.iso                   " \
		"o  opensuse-leap-netinst-15.5  openSUSE%20Leap%2015.5                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-15.5-NET-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.5_net.xml     ${HGFS_DIRS}/linux/openSUSE      2023-06-07  2024-12-31  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.5/iso/openSUSE-Leap-15.5-NET-x86_64-Media.iso                                         " \
		"o  opensuse-leap-netinst-15.6  openSUSE%20Leap%2015.6                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-15.6-NET-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.6_net.xml     ${HGFS_DIRS}/linux/openSUSE      2024-06-xx  2025-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Media.iso                                         " \
		"o  opensuse-leap-netinst-16.0  openSUSE%20Leap%2016.0                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-16.0-NET-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-16.0_net.xml     ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-NET-x86_64-Media.iso                                         " \
		"o  opensuse-tumbleweed-netinst openSUSE%20Tumbleweed                   openSUSE            ${DIRS_ISOS}    openSUSE-Tumbleweed-NET-x86_64-Current.iso      boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_tumbleweed_net.xml    ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                                  " \
		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                           2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- dvd image -----------------------------------------------------------
	declare -r -a DATA_LIST_DVD=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         \
		"m  menu-entry                  Auto%20install%20DVD%20media            -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-10                   Debian%2010                             debian              ${DIRS_ISOS}    debian-10.13.0-amd64-DVD-1.iso                  install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_oldold.cfg     ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-10.[0-9.]*-amd64-DVD-1.iso                                 " \
		"o  debian-11                   Debian%2011                             debian              ${DIRS_ISOS}    debian-11.11.0-amd64-DVD-1.iso                  install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_old.cfg        ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.[0-9.]*-amd64-DVD-1.iso                                    " \
		"o  debian-12                   Debian%2012                             debian              ${DIRS_ISOS}    debian-12.8.0-amd64-DVD-1.iso                   install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-12.[0-9.]*-amd64-DVD-1.iso                                             " \
		"o  debian-13                   Debian%2013                             debian              ${DIRS_ISOS}    debian-13.0.0-amd64-DVD-1.iso                   install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"-  debian-14                   Debian%2014                             debian              ${DIRS_ISOS}    debian-14.0.0-amd64-DVD-1.iso                   install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  debian-testing              Debian%20testing                        debian              ${DIRS_ISOS}    debian-testing-amd64-DVD-1.iso                  install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                                                  " \
		"x  ubuntu-server-14.04         Ubuntu%2014.04%20Server                 ubuntu              ${DIRS_ISOS}    ubuntu-14.04.6-server-amd64.iso                 install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"-  ubuntu-server-16.04         Ubuntu%2016.04%20Server                 ubuntu              ${DIRS_ISOS}    ubuntu-16.04.6-server-amd64.iso                 install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  ubuntu-server-18.04         Ubuntu%2018.04%20Server                 ubuntu              ${DIRS_ISOS}    ubuntu-18.04.6-server-amd64.iso                 install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04[0-9.]*-server-amd64.iso                                                        " \
		"o  ubuntu-live-18.04           Ubuntu%2018.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-18.04.6-live-server-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server_old               ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-live-server-amd64.iso                                                                   " \
		"o  ubuntu-live-20.04           Ubuntu%2020.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-20.04.6-live-server-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-live-server-amd64.iso                                                                    " \
		"o  ubuntu-live-22.04           Ubuntu%2022.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-22.04.5-live-server-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-live-server-amd64.iso                                                                    " \
		"x  ubuntu-live-23.04           Ubuntu%2023.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-23.04-live-server-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-live-server-amd64.iso                                                                    " \
		"x  ubuntu-live-23.10           Ubuntu%2023.10%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-23.10-live-server-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-live-server-amd64.iso                                                                   " \
		"o  ubuntu-live-24.04           Ubuntu%2024.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-24.04.1-live-server-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-live-server-amd64.iso                                                                    " \
		"o  ubuntu-live-24.10           Ubuntu%2024.10%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-24.10-live-server-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-live-server-amd64.iso                                                                 " \
		"o  ubuntu-live-25.04           Ubuntu%2025.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    plucky-live-server-amd64.iso                    casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2025-04-17  2026-01-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/plucky-live-server-amd64.iso                                                       " \
		"-  ubuntu-live-24.10           Ubuntu%2024.10%20Live%20Server%20Beta   ubuntu              ${DIRS_ISOS}    ubuntu-24.10-beta-live-server-amd64.iso         casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10-beta-live-server-amd64.iso                                                                   " \
		"-  ubuntu-live-oracular        Ubuntu%20oracular%20Live%20Server       ubuntu              ${DIRS_ISOS}    oracular-live-server-amd64.iso                  casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/oracular-live-server-amd64.iso                                                     " \
		"x  fedora-38                   Fedora%20Server%2038                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-38-1.6.iso             images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-38_dvd.cfg          ${HGFS_DIRS}/linux/fedora        2023-04-18  2024-05-14  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-dvd-x86_64-38-[0-9.]*.iso                      " \
		"x  fedora-39                   Fedora%20Server%2039                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-39-1.5.iso             images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-39_dvd.cfg          ${HGFS_DIRS}/linux/fedora        2023-11-07  2024-11-12  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-dvd-x86_64-39-[0-9.]*.iso                      " \
		"o  fedora-40                   Fedora%20Server%2040                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-40-1.14.iso            images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-40_dvd.cfg          ${HGFS_DIRS}/linux/fedora        2024-04-16  2025-05-13  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-dvd-x86_64-40-[0-9.]*.iso                      " \
		"o  fedora-41                   Fedora%20Server%2041                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-41-1.4.iso             images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-41_dvd.cfg          ${HGFS_DIRS}/linux/fedora        202x-xx-xx  202x-xx-xx  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-[0-9.]*.iso                      " \
		"x  fedora-41                   Fedora%20Server%2041                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-41_Beta-1.2.iso        images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-41_dvd.cfg          ${HGFS_DIRS}/linux/fedora        202x-xx-xx  202x-xx-xx  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/test/41_Beta/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41_Beta-[0-9.]*.iso       " \
		"x  centos-stream-8             CentOS%20Stream%208                     centos              ${DIRS_ISOS}    CentOS-Stream-8-x86_64-latest-dvd1.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-8_dvd.cfg    ${HGFS_DIRS}/linux/centos        2019-xx-xx  2024-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-dvd1.iso                                             " \
		"o  centos-stream-9             CentOS%20Stream%209                     centos              ${DIRS_ISOS}    CentOS-Stream-9-latest-x86_64-dvd1.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-9_dvd.cfg    ${HGFS_DIRS}/linux/centos        2021-xx-xx  2027-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                                " \
		"o  centos-stream-10            CentOS%20Stream%2010                    centos              ${DIRS_ISOS}    CentOS-Stream-10-latest-x86_64-dvd1.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-10_dvd.cfg   ${HGFS_DIRS}/linux/centos        2024-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso                              " \
		"o  almalinux-9                 Alma%20Linux%209                        almalinux           ${DIRS_ISOS}    AlmaLinux-9-latest-x86_64-dvd.iso               images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_almalinux-9_dvd.cfg        ${HGFS_DIRS}/linux/almalinux     2022-05-26  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9[0-9.]*-latest-x86_64-dvd.iso                                                    " \
		"o  rockylinux-8                Rocky%20Linux%208                       Rocky               ${DIRS_ISOS}    Rocky-8.10-x86_64-dvd1.iso                      images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-8_dvd.cfg       ${HGFS_DIRS}/linux/Rocky         2022-11-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-dvd1.iso                                                         " \
		"o  rockylinux-9                Rocky%20Linux%209                       Rocky               ${DIRS_ISOS}    Rocky-9-latest-x86_64-dvd.iso                   images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-9_dvd.cfg       ${HGFS_DIRS}/linux/Rocky         2022-07-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9[0-9.]*-latest-x86_64-dvd.iso                                                   " \
		"o  miraclelinux-8              Miracle%20Linux%208                     miraclelinux        ${DIRS_ISOS}    MIRACLELINUX-8.10-rtm-x86_64.iso                images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-8_dvd.cfg     ${HGFS_DIRS}/linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-x86_64.iso                           " \
		"o  miraclelinux-9              Miracle%20Linux%209                     miraclelinux        ${DIRS_ISOS}    MIRACLELINUX-9.4-rtm-x86_64.iso                 images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-9_dvd.cfg     ${HGFS_DIRS}/linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso                           " \
		"o  opensuse-leap-15.5          openSUSE%20Leap%2015.5                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-15.5-DVD-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.5_dvd.xml     ${HGFS_DIRS}/linux/openSUSE      2023-06-07  2024-12-31  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.5/iso/openSUSE-Leap-15.5-DVD-x86_64-Media.iso                                         " \
		"o  opensuse-leap-15.6          openSUSE%20Leap%2015.6                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-15.6-DVD-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.6_dvd.xml     ${HGFS_DIRS}/linux/openSUSE      2024-06-xx  2025-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso                                         " \
		"o  opensuse-leap-16.0          openSUSE%20Leap%2016.0                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-16.0-DVD-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-16.0_dvd.xml     ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-DVD-x86_64-Media.iso                                         " \
		"o  opensuse-tumbleweed         openSUSE%20Tumbleweed                   openSUSE            ${DIRS_ISOS}    openSUSE-Tumbleweed-DVD-x86_64-Current.iso      boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_tumbleweed_dvd.xml    ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                                  " \
		"o  windows-10                  Windows%2010                            windows             ${DIRS_ISOS}    Win10_22H2_Japanese_x64.iso                     -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/Windows10   -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  windows-11                  Windows%2011                            windows             ${DIRS_ISOS}    Win11_24H2_Japanese_x64.iso                     -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/Windows11   -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"-  windows-11                  Windows%2011%20custom                   windows             ${DIRS_ISOS}    Win11_24H2_Japanese_x64_custom.iso              -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/Windows11   -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                           2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- live media install mode ---------------------------------------------
	declare -r -a DATA_LIST_INST=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        \
		"m  menu-entry                  Live%20media%20Install%20mode           -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-live-10              Debian%2010%20Live                      debian              ${DIRS_ISOS}    debian-live-10.13.0-amd64-lxde.iso              d-i                                     initrd.gz                   vmlinuz                 preseed/ps_debian_desktop_oldold.cfg    ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-10.[0-9.]*-amd64-lxde.iso                     " \
		"o  debian-live-11              Debian%2011%20Live                      debian              ${DIRS_ISOS}    debian-live-11.11.0-amd64-lxde.iso              d-i                                     initrd.gz                   vmlinuz                 preseed/ps_debian_desktop_old.cfg       ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso                        " \
		"o  debian-live-12              Debian%2012%20Live                      debian              ${DIRS_ISOS}    debian-live-12.8.0-amd64-lxde.iso               install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                                 " \
		"o  debian-live-13              Debian%2013%20Live                      debian              ${DIRS_ISOS}    debian-live-13.0.0-amd64-lxde.iso               install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  debian-live-testing         Debian%20testing%20Live                 debian              ${DIRS_ISOS}    debian-live-testing-amd64-lxde.iso              install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                      " \
		"x  ubuntu-desktop-14.04        Ubuntu%2014.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-14.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_oldold.cfg  ${HGFS_DIRS}/linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-desktop-16.04        Ubuntu%2016.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-16.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_oldold.cfg  ${HGFS_DIRS}/linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-desktop-18.04        Ubuntu%2018.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-18.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_oldold.cfg  ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-20.04        Ubuntu%2020.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-20.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         ${HGFS_DIRS}/linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"o  ubuntu-desktop-22.04        Ubuntu%2022.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-22.04.5-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         ${HGFS_DIRS}/linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"x  ubuntu-desktop-23.04        Ubuntu%2023.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-23.04-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"x  ubuntu-desktop-23.10        Ubuntu%2023.10%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-23.10.1-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.04.1-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"o  ubuntu-desktop-24.10        Ubuntu%2024.10%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.10-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-desktop-amd64.iso                                                                     " \
		"-  ubuntu-desktop-24.10        Ubuntu%2024.10%20Desktop%20Beta         ubuntu              ${DIRS_ISOS}    ubuntu-24.10-beta-desktop-amd64.iso             casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10-beta-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-25.04        Ubuntu%2025.04%20Desktop                ubuntu              ${DIRS_ISOS}    plucky-desktop-amd64.iso                        casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2025-04-17  2026-01-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/plucky-desktop-amd64.iso                                                                         " \
		"x  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.04-beta-desktop-amd64.iso             casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-beta-desktop-amd64.iso                                                                   " \
		"-  ubuntu-desktop-oracular     Ubuntu%20oracular%20Desktop             ubuntu              ${DIRS_ISOS}    oracular-desktop-amd64.iso                      casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/oracular-desktop-amd64.iso                                                                       " \
		"x  ubuntu-legacy-23.04         Ubuntu%2023.04%20Legacy%20Desktop       ubuntu              ${DIRS_ISOS}    ubuntu-23.04-desktop-legacy-amd64.iso           casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_oldold.cfg  ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/lunar/release/ubuntu-23.04[0-9.]*-desktop-legacy-amd64.iso                                                 " \
		"x  ubuntu-legacy-23.10         Ubuntu%2023.10%20Legacy%20Desktop       ubuntu              ${DIRS_ISOS}    ubuntu-23.10-desktop-legacy-amd64.iso           casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/mantic/release/ubuntu-23.10[0-9.]*-desktop-legacy-amd64.iso                                                " \
		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                           2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- live media live mode ------------------------------------------------
	declare -r -a DATA_LIST_LIVE=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        \
		"m  menu-entry                  Live%20media%20Live%20mode              -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-live-10              Debian%2010%20Live                      debian              ${DIRS_ISOS}    debian-live-10.13.0-amd64-lxde.iso              live                                    initrd.img-4.19.0-21-amd64  vmlinuz-4.19.0-21-amd64 preseed/-                               ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-10.[0-9.]*-amd64-lxde.iso                     " \
		"o  debian-live-11              Debian%2011%20Live                      debian              ${DIRS_ISOS}    debian-live-11.11.0-amd64-lxde.iso              live                                    initrd.img-5.10.0-32-amd64  vmlinuz-5.10.0-32-amd64 preseed/-                               ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso                        " \
		"o  debian-live-12              Debian%2012%20Live                      debian              ${DIRS_ISOS}    debian-live-12.8.0-amd64-lxde.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                                 " \
		"o  debian-live-13              Debian%2013%20Live                      debian              ${DIRS_ISOS}    debian-live-13.0.0-amd64-lxde.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  debian-live-testing         Debian%20testing%20Live                 debian              ${DIRS_ISOS}    debian-live-testing-amd64-lxde.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                      " \
		"x  ubuntu-desktop-14.04        Ubuntu%2014.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-14.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-desktop-16.04        Ubuntu%2016.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-16.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-desktop-18.04        Ubuntu%2018.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-18.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-20.04        Ubuntu%2020.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-20.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"o  ubuntu-desktop-22.04        Ubuntu%2022.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-22.04.5-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"x  ubuntu-desktop-23.04        Ubuntu%2023.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-23.04-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"x  ubuntu-desktop-23.10        Ubuntu%2023.10%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-23.10.1-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.04.1-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"o  ubuntu-desktop-24.10        Ubuntu%2024.10%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.10-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-desktop-amd64.iso                                                                     " \
		"-  ubuntu-desktop-24.10        Ubuntu%2024.10%20Desktop%20Beta         ubuntu              ${DIRS_ISOS}    ubuntu-24.10-beta-desktop-amd64.iso             casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10-beta-desktop-amd64.iso                                                                       " \
		"x  ubuntu-desktop-24.04        Ubuntu%2024.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.04-beta-desktop-amd64.iso             casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-beta-desktop-amd64.iso                                                                   " \
		"o  ubuntu-desktop-25.04        Ubuntu%2025.04%20Desktop                ubuntu              ${DIRS_ISOS}    plucky-desktop-amd64.iso                        casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2025-04-17  2026-01-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/plucky-desktop-amd64.iso                                                                         " \
		"-  ubuntu-desktop-oracular     Ubuntu%20oracular%20Desktop             ubuntu              ${DIRS_ISOS}    oracular-desktop-amd64.iso                      casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/oracular-desktop-amd64.iso                                                                       " \
		"x  ubuntu-legacy-23.04         Ubuntu%2023.04%20Legacy%20Desktop       ubuntu              ${DIRS_ISOS}    ubuntu-23.04-desktop-legacy-amd64.iso           casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/lunar/release/ubuntu-23.04[0-9.]*-desktop-legacy-amd64.iso                                                 " \
		"x  ubuntu-legacy-23.10         Ubuntu%2023.10%20Legacy%20Desktop       ubuntu              ${DIRS_ISOS}    ubuntu-23.10-desktop-legacy-amd64.iso           casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/mantic/release/ubuntu-23.10[0-9.]*-desktop-legacy-amd64.iso                                                " \
		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                           2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- tool ----------------------------------------------------------------
	declare -r -a DATA_LIST_TOOL=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        \
		"m  menu-entry                  System%20tools                          -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  memtest86plus               Memtest86+%207.00                       memtest86+          ${DIRS_ISOS}    mt86plus_7.00_64.grub.iso                       .                                       EFI/BOOT/memtest            boot/memtest            -                                       ${HGFS_DIRS}/linux/memtest86+    -           -           xx:xx:xx    0   -   -   https://www.memtest.org/download/v7.00/mt86plus_7.00_64.grub.iso.zip                                                                           " \
		"o  memtest86plus               Memtest86+%207.20                       memtest86+          ${DIRS_ISOS}    mt86plus_7.20_64.grub.iso                       .                                       EFI/BOOT/memtest            boot/memtest            -                                       ${HGFS_DIRS}/linux/memtest86+    -           -           xx:xx:xx    0   -   -   https://www.memtest.org/download/v7.20/mt86plus_7.20_64.grub.iso.zip                                                                           " \
		"o  winpe-x64                   WinPE%20x64                             windows             ${DIRS_ISOS}    WinPEx64.iso                                    .                                       -                           -                       -                                       ${HGFS_DIRS}/windows/WinPE       -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  winpe-x86                   WinPE%20x86                             windows             ${DIRS_ISOS}    WinPEx86.iso                                    .                                       -                           -                       -                                       ${HGFS_DIRS}/windows/WinPE       -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  ati2020x64                  ATI2020x64                              windows             ${DIRS_ISOS}    WinPE_ATI2020x64.iso                            .                                       -                           -                       -                                       ${HGFS_DIRS}/windows/ati         -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  ati2020x86                  ATI2020x86                              windows             ${DIRS_ISOS}    WinPE_ATI2020x86.iso                            .                                       -                           -                       -                                       ${HGFS_DIRS}/windows/ati         -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                           2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- custom iso image ----------------------------------------------------
	declare -r -a DATA_LIST_CSTM=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        \
		"m  menu-entry                  Custom%20Live%20Media                   -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  live-debian-10-buster       Live%20Debian%2010                      debian              ${DIRS_LIVE}    live-debian-10-buster-amd64.iso                 live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-11-bullseye     Live%20Debian%2011                      debian              ${DIRS_LIVE}    live-debian-11-bullseye-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-12-bookworm     Live%20Debian%2012                      debian              ${DIRS_LIVE}    live-debian-12-bookworm-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-13-trixie       Live%20Debian%2013                      debian              ${DIRS_LIVE}    live-debian-13-trixie-amd64.iso                 live                                    initrd.img                  vmlinuz                 preseed/-                               -                                202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-xx-unstable     Live%20Debian%20xx                      debian              ${DIRS_LIVE}    live-debian-xx-unstable-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"x  live-ubuntu-14.04-trusty    Live%20Ubuntu%2014.04                   ubuntu              ${DIRS_LIVE}    live-ubuntu-14.04-trusty-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2014-04-17  2024-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"L  live-ubuntu-16.04-xenial    Live%20Ubuntu%2016.04                   ubuntu              ${DIRS_LIVE}    live-ubuntu-16.04-xenial-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2016-04-21  2026-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"L  live-ubuntu-18.04-bionic    Live%20Ubuntu%2018.04                   ubuntu              ${DIRS_LIVE}    live-ubuntu-18.04-bionic-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"s  live-ubuntu-20.04-focal     Live%20Ubuntu%2020.04                   ubuntu              ${DIRS_LIVE}    live-ubuntu-20.04-focal-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-22.04-jammy     Live%20Ubuntu%2022.04                   ubuntu              ${DIRS_LIVE}    live-ubuntu-22.04-jammy-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2022-04-21  2032-04-21  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"x  live-ubuntu-23.04-lunar     Live%20Ubuntu%2023.04                   ubuntu              ${DIRS_LIVE}    live-ubuntu-23.04-lunar-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2023-04-20  2024-01-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"x  live-ubuntu-23.10-mantic    Live%20Ubuntu%2023.10                   ubuntu              ${DIRS_LIVE}    live-ubuntu-23.10-mantic-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2023-10-12  2024-07-11  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-24.04-noble     Live%20Ubuntu%2024.04                   ubuntu              ${DIRS_LIVE}    live-ubuntu-24.04-noble-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2024-04-25  2034-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-24.10-oracular  Live%20Ubuntu%2024.10                   ubuntu              ${DIRS_LIVE}    live-ubuntu-24.10-oracular-amd64.iso            live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-25.04-plucky    Live%20Ubuntu%2025.04                   ubuntu              ${DIRS_LIVE}    live-ubuntu-25.04-plucky-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2025-04-17  2026-01-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"s  live-ubuntu-xx.xx-devel     Live%20Ubuntu%20xx.xx                   ubuntu              ${DIRS_LIVE}    live-ubuntu-xx.xx-devel-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"m  menu-entry                  Custom%20Initramfs%20boot               -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"o  netinst-debian-10           Net%20Installer%20Debian%2010           debian              ${DIRS_BLDR}    -                                               .                                       initrd.gz_debian-10         linux_debian-10         preseed/ps_debian_server_oldold.cfg     -                                2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  netinst-debian-11           Net%20Installer%20Debian%2011           debian              ${DIRS_BLDR}    -                                               .                                       initrd.gz_debian-11         linux_debian-11         preseed/ps_debian_server_old.cfg        -                                2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  netinst-debian-12           Net%20Installer%20Debian%2012           debian              ${DIRS_BLDR}    -                                               .                                       initrd.gz_debian-12         linux_debian-12         preseed/ps_debian_server.cfg            -                                2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  netinst-debian-13           Net%20Installer%20Debian%2013           debian              ${DIRS_BLDR}    -                                               .                                       initrd.gz_debian-13         linux_debian-13         preseed/ps_debian_server.cfg            -                                202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  netinst-debian-sid          Net%20Installer%20Debian%20sid          debian              ${DIRS_BLDR}    -                                               .                                       initrd.gz_debian-sid        linux_debian-sid        preseed/ps_debian_server.cfg            -                                202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                           2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- system command ------------------------------------------------------
#	declare -r -a DATA_LIST_SCMD=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        \
#		"m  menu-entry                  System%20command                        -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
#		"o  hdt                         Hardware%20info                         system              -               -                                               -                                       hdt.c32                     -                       -                                       -                                -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
#		"o  shutdown                    System%20shutdown                       system              -               -                                               -                                       poweroff.c32                -                       -                                       -                                -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
#		"o  restart                     System%20restart                        system              -               -                                               -                                       reboot.c32                  -                       -                                       -                                -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
#		"m  menu-entry                  -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
#	) #  0  1                           2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- data list -----------------------------------------------------------
	declare -a    DATA_LIST=(  \
		"${DATA_LIST_MINI[@]}" \
		"${DATA_LIST_NET[@]}"  \
		"${DATA_LIST_DVD[@]}"  \
		"${DATA_LIST_INST[@]}" \
		"${DATA_LIST_LIVE[@]}" \
		"${DATA_LIST_TOOL[@]}" \
		"${DATA_LIST_CSTM[@]}" \
	)

	# --- target of creation --------------------------------------------------
	declare -a    TGET_LIST=()
	declare       TGET_INDX=""

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

# === create ==================================================================

# ----- create directory ------------------------------------------------------
function funcCreate_directory() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -a    DATA_LINE=()
	declare -a    LINK_LINE=()
	declare       TGET_PATH=""
	declare       LINK_PATH=""
	declare       BACK_PATH=""
	declare -i    I=0

	# --- create directory ----------------------------------------------------
	mkdir -p "${LIST_DIRS[@]}"

	# --- create symbolic link ------------------------------------------------
	for I in "${!LIST_LINK[@]}"
	do
		read -r -a LINK_LINE < <(echo "${LIST_LINK[I]}")
		TGET_PATH="${LINK_LINE[0]}"
		LINK_PATH="${LINK_LINE[1]}"
		# --- check target file path ------------------------------------------
		if [[ -z "${LINK_PATH##*/}" ]]; then
			LINK_PATH="${LINK_PATH%/}/${TGET_PATH##*/}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${LINK_PATH}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${LINK_PATH/${PWD}\//}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${LINK_PATH}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${LINK_PATH}"
			BACK_PATH="${LINK_PATH}.back.${DATE_TIME}"
			funcPrintf "%20.20s: %s" "move directory" "${LINK_PATH/${PWD}\//} -> ${BACK_PATH/${PWD}\//}"
			mv "${LINK_PATH}" "${BACK_PATH}"
		fi
		# --- create destination directory ------------------------------------
#		funcPrintf "%20.20s: %s" "create dest dir" "${LINK_PATH%/*}"
		mkdir -p "${LINK_PATH%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${TGET_PATH/${PWD}\//} -> ${LINK_PATH/${PWD}\//}"
		if [[ "${LINK_PATH}" =~ ${DIRS_WORK} ]]; then
			ln -sr "${TGET_PATH}" "${LINK_PATH}"
		else
			ln -s "${TGET_PATH}" "${LINK_PATH}"
		fi
	done

	# --- create symbolic link of data list -----------------------------------
	for I in "${!DATA_LIST[@]}"
	do
		read -r -a DATA_LINE < <(echo "${DATA_LIST[I]}")
		TGET_PATH="${DATA_LINE[10]}/${DATA_LINE[5]}"
		LINK_PATH="${DATA_LINE[4]}/${TGET_PATH##*/}"
		if [[ "${DATA_LINE[0]}" != "o" ]] \
		|| [[ ! -e "${TGET_PATH}" ]]; then
			continue
		fi
		# --- check target file path ------------------------------------------
		if [[ -z "${LINK_PATH##*/}" ]]; then
			LINK_PATH="${LINK_PATH%/}/${TGET_PATH##*/}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${LINK_PATH}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${LINK_PATH/${PWD}\//}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${LINK_PATH}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${LINK_PATH}"
			BACK_PATH="${LINK_PATH}.back.${DATE_TIME}"
			funcPrintf "%20.20s: %s" "move directory" "${LINK_PATH/${PWD}\//} -> ${BACK_PATH/${PWD}\//}"
			mv "${LINK_PATH}" "${BACK_PATH}"
		fi
		# --- create destination directory ------------------------------------
#		funcPrintf "%20.20s: %s" "create dest dir" "${LINK_PATH%/*}"
		mkdir -p "${LINK_PATH%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${TGET_PATH/${PWD}\//} -> ${LINK_PATH/${PWD}\//}"
		if [[ "${LINK_PATH}" =~ ${DIRS_WORK} ]]; then
			ln -sr "${TGET_PATH}" "${LINK_PATH}"
		else
			ln -s "${TGET_PATH}" "${LINK_PATH}"
		fi
	done
}

# ----- create preseed kill dhcp ----------------------------------------------
function funcCreate_preseed_kill_dhcp() {
	declare -r    DIRS_NAME="${DIRS_CONF}/preseed"
	declare -r    FILE_NAME="${DIRS_NAME}/preseed_kill_dhcp.sh"
	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${FILE_NAME/${PWD}\/}"
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
	funcPrintf "%20.20s: %s" "create file" "${FILE_NAME/${PWD}\/}"
	mkdir -p "${DIRS_NAME}"
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_NAME}"
		#!/bin/sh
		
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
		#	set -o pipefail						# End with in pipe error
		
		#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
		 	trap 'exit 1' 1 2 3 15
		 	export LANG=C
		
		 	# --- working directory name ----------------------------------------------
		 	readonly      PROG_PATH="$0"
		 	readonly      PROG_PRAM="$*"
		 	readonly      PROG_DIRS="${PROG_PATH%/*}"
		 	readonly      PROG_NAME="${PROG_PATH##*/}"
		 	readonly      PROG_PROC="${PROG_NAME}.$$"
		 	readonly      DIRS_WORK="${PWD%/}/${PROG_NAME%.*}"
		 	#--- initial settings  ----------------------------------------------------
		 	NTPS_ADDR="ntp.nict.jp"				# ntp server address
		 	NTPS_IPV4="61.205.120.130"			# ntp server ipv4 address
		 	IPV6_LHST="::1"						# ipv6 local host address
		 	IPV4_LHST="127.0.0.1"				# ipv4 local host address
		 	IPV4_DUMY="127.0.1.1"				# ipv4 dummy address
		 	OLDS_FQDN="$(cat /etc/hostname)"	# old hostname (fqdn)
		 	OLDS_HOST="$(echo "${OLDS_FQDN}." | cut -d '.' -f 1)"	# old hostname (host name)
		 	OLDS_WGRP="$(echo "${OLDS_FQDN}." | cut -d '.' -f 2)"	# old hostname (domain)
		 	# --- command line parameter ----------------------------------------------
		 	COMD_LINE="$(cat /proc/cmdline)"	# command line parameter
		 	IPV4_DHCP=""						# true: dhcp, else: fixed address
		 	NICS_NAME=""						# nic if name   (ex. ens160)
		 	NICS_MADR=""						# nic if mac    (ex. 00:00:00:00:00:00)
		 	NICS_IPV4=""						# ipv4 address  (ex. 192.168.1.1)
		 	NICS_MASK=""						# ipv4 netmask  (ex. 255.255.255.0)
		 	NICS_BIT4=""						# ipv4 cidr     (ex. 24)
		 	NICS_DNS4=""						# ipv4 dns      (ex. 192.168.1.254)
		 	NICS_GATE=""						# ipv4 gateway  (ex. 192.168.1.254)
		 	NICS_FQDN=""						# hostname fqdn (ex. sv-server.workgroup)
		 	NICS_HOST=""						# hostname      (ex. sv-server)
		 	NICS_WGRP=""						# domain        (ex. workgroup)
		 	NMAN_FLAG=""						# nm_config, ifupdown, loopback
		 	ISOS_FILE=""						# iso file name
		 	SEED_FILE=""						# preseed file name
		 	# --- set system parameter ------------------------------------------------
		 	DBGS_FLAG="${_DBGOUT:-}"			# debug flag (true: debug, else: normal)
		 	DIST_NAME=""						# distribution name (ex. debian)
		 	DIST_VERS=""						# release version   (ex. 12)
		 	DIST_CODE=""						# code name         (ex. bookworm)
		 	DIRS_TGET=""
		 	if [ -d /target/. ]; then
		 		DIRS_TGET="/target"
		 	fi
		 	ROWS_SIZE="25"						# screen size: rows
		 	COLS_SIZE="80"						# screen size: columns
		 	TEXT_GAP1=""						# gap1
		 	TEXT_GAP2=""						# gap2
		
		 	# --- set command line parameter ------------------------------------------
		 	for LINE in ${COMD_LINE:-} ${PROG_PRAM:-}
		 	do
		 		case "${LINE}" in
		 			debug | debugout | dbg         ) DBGS_FLAG="true"      ;;
		 			target=*                       ) DIRS_TGET="${LINE#*=}";;
		 			iso-url=*.iso  | url=*.iso     ) ISOS_FILE="${LINE#*=}";;
		 			preseed/url=*  | url=*         ) SEED_FILE="${LINE#*=}";;
		 			preseed/file=* | file=*        ) SEED_FILE="${LINE#*=}";;
		 			ds=nocloud*                    ) SEED_FILE="${LINE#*=}";;
		 			netcfg/target_network_config=* ) NMAN_FLAG="${LINE#*=}";;
		 			netcfg/choose_interface=*      ) NICS_NAME="${LINE#*=}";;
		 			netcfg/disable_dhcp=*          ) IPV4_DHCP="$([ "${LINE#*=}" = "true" ] && echo "false" || echo "true")";;
		 			netcfg/disable_autoconfig=*    ) IPV4_DHCP="$([ "${LINE#*=}" = "true" ] && echo "false" || echo "true")";;
		 			netcfg/get_ipaddress=*         ) NICS_IPV4="${LINE#*=}";;
		 			netcfg/get_netmask=*           ) NICS_MASK="${LINE#*=}";;
		 			netcfg/get_gateway=*           ) NICS_GATE="${LINE#*=}";;
		 			netcfg/get_nameservers=*       ) NICS_DNS4="${LINE#*=}";;
		 			netcfg/get_hostname=*          ) NICS_FQDN="${LINE#*=}";;
		 			netcfg/get_domain=*            ) NICS_WGRP="${LINE#*=}";;
		 			interface=*                    ) NICS_NAME="${LINE#*=}";;
		 			hostname=*                     ) NICS_FQDN="${LINE#*=}";;
		 			domain=*                       ) NICS_WGRP="${LINE#*=}";;
		 			ip=dhcp | ip4=dhcp | ipv4=dhcp ) IPV4_DHCP="true"      ;;
		 			ip=* | ip4=* | ipv4=*          ) IPV4_DHCP="false"
		 			                                 NICS_IPV4="$(echo "${LINE#*=}" | cut -d ':' -f 1)"
		 			                                 NICS_GATE="$(echo "${LINE#*=}" | cut -d ':' -f 3)"
		 			                                 NICS_MASK="$(echo "${LINE#*=}" | cut -d ':' -f 4)"
		 			                                 NICS_FQDN="$(echo "${LINE#*=}" | cut -d ':' -f 5)"
		 			                                 NICS_NAME="$(echo "${LINE#*=}" | cut -d ':' -f 6)"
		 			                                 NICS_DNS4="$(echo "${LINE#*=}" | cut -d ':' -f 8)"
		 			                                 ;;
		 			*)  ;;
		 		esac
		 	done
		
		 	# --- working directory name ----------------------------------------------
		 	readonly      DIRS_ORIG="${DIRS_TGET:-}/var/log/installer/${PROG_NAME}/orig"
		 	readonly      DIRS_LOGS="${DIRS_TGET:-}/var/log/installer/${PROG_NAME}/logs"
		
		 	# --- log out -------------------------------------------------------------
		 	if [ -n "${DBGS_FLAG:-}" ] \
		 	&& command -v mkfifo; then
		 		LOGS_NAME="${DIRS_LOGS}/${PROG_NAME%.*}.$(date +"%Y%m%d%H%M%S").log"
		 		mkdir -p "${LOGS_NAME%/*}"
		 		SOUT_PIPE="/tmp/${PROG_PROC}.stdout_pipe"
		 		SERR_PIPE="/tmp/${PROG_PROC}.stderr_pipe"
		 		trap 'rm -f '"${SOUT_PIPE}"' '"${SERR_PIPE}"'' EXIT
		 		mkfifo "${SOUT_PIPE}" "${SERR_PIPE}"
		 		: > "${LOGS_NAME}"
		 		tee -a "${LOGS_NAME}" < "${SOUT_PIPE}" &
		 		tee -a "${LOGS_NAME}" < "${SERR_PIPE}" >&2 &
		 		exec > "${SOUT_PIPE}" 2> "${SERR_PIPE}"
		 	fi
		
		### common ####################################################################
		
		# --- ipv4 netmask conversion -------------------------------------------------
		funcIPv4GetNetmask() {
		 	_OCTETS1="$(echo "${1:?}." | cut -d '.' -f 1)"
		 	_OCTETS2="$(echo "${1:?}." | cut -d '.' -f 2)"
		 	_OCTETS3="$(echo "${1:?}." | cut -d '.' -f 3)"
		 	_OCTETS4="$(echo "${1:?}." | cut -d '.' -f 4)"
		 	if [ -n "${_OCTETS1:-}" ] && [ -n "${_OCTETS2:-}" ] && [ -n "${_OCTETS3:-}" ] && [ -n "${_OCTETS4:-}" ]; then
		 		# --- netmask -> cidr -------------------------------------------------
		 		_MASK=0
		 		for _OCTETS in "${_OCTETS1}" "${_OCTETS2}" "${_OCTETS3}" "${_OCTETS4}"
		 		do
		 			case "${_OCTETS}" in
		 				  0) _MASK=$((_MASK+0));;
		 				128) _MASK=$((_MASK+1));;
		 				192) _MASK=$((_MASK+2));;
		 				224) _MASK=$((_MASK+3));;
		 				240) _MASK=$((_MASK+4));;
		 				248) _MASK=$((_MASK+5));;
		 				252) _MASK=$((_MASK+6));;
		 				254) _MASK=$((_MASK+7));;
		 				255) _MASK=$((_MASK+8));;
		 				*  )                 ;;
		 			esac
		 		done
		 		printf '%d' "${_MASK}"
		 	else
		 		# --- cidr -> netmask -------------------------------------------------
		 		_LOOP=$((32-${1:?}))
		 		_WORK=1
		 		_DEC_ADDR=""
		 		while [ "${_LOOP}" -gt 0 ]
		 		do
		 			_LOOP=$((_LOOP-1))
		 			_WORK=$((_WORK*2))
		 		done
		 		_DEC_ADDR="$((0xFFFFFFFF ^ (_WORK-1)))"
		 		printf '%d.%d.%d.%d'              \
		 		    $(( _DEC_ADDR >> 24        )) \
		 		    $(((_DEC_ADDR >> 16) & 0xFF)) \
		 		    $(((_DEC_ADDR >>  8) & 0xFF)) \
		 		    $(( _DEC_ADDR        & 0xFF))
		 	fi
		# --- private ip address ------------------------------------------------------
		# class | ipv4 address range            | subnet mask range
		#   a   | 10.0.0.0    - 10.255.255.255  | 255.0.0.0     - 255.255.255.255 (up to 16,777,214 devices can be connected)
		#   b   | 172.16.0.0  - 172.31.255.255  | 255.255.0.0   - 255.255.255.255 (up to     65,534 devices can be connected)
		#   c   | 192.168.0.0 - 192.168.255.255 | 255.255.255.0 - 255.255.255.255 (up to        254 devices can be connected)
		}
		
		# --- string output -----------------------------------------------------------
		funcString() {
		 	echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); gsub(" ","'"$2"'",s); print s;}'
		}
		
		# --- service status ----------------------------------------------------------
		 funcServiceStatus() {
		 	_SRVC_STAT="$(systemctl "$@" 2> /dev/null || true)"
		 	case "$?" in
		 		4) _SRVC_STAT="not-found";;		# no such unit
		 		*) _SRVC_STAT="${_SRVC_STAT%-*}";;
		 	esac
		 	echo "${_SRVC_STAT:-"undefined"}"
		
		# systemctl return codes
		#-------+--------------------------------------------------+-------------------------------------#
		# Value | Description in LSB                               | Use in systemd                      #
		#    0  | "program is running or service is OK"            | unit is active                      #
		#    1  | "program is dead and /var/run pid file exists"   | unit not failed (used by is-failed) #
		#    2  | "program is dead and /var/lock lock file exists" | unused                              #
		#    3  | "program is not running"                         | unit is not active                  #
		#    4  | "program or service status is unknown"           | no such unit                        #
		#-------+--------------------------------------------------+-------------------------------------#
		}
		
		# --- install package ---------------------------------------------------------
		funcInstallPackage() {
			LANG=C apt list "$@" 2> /dev/null | sed -ne '/^[ \t]*$\|WARNING\|Listing\|installed/! s%/.*%%gp' | sed -z 's/[\r\n]\+/ /g'
		}
		
		### subroutine ################################################################
		
		# --- debug out parameter -----------------------------------------------------
		funcDebugout_parameter() {
		 	if [ -z "${DBGS_FLAG:-}" ]; then
		 		return
		 	fi
		
		 	__FUNC_NAME="funcDebugout_parameter"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
		 	printf "\033[m${PROG_NAME}: \033[42m%s\033[m\n" "--- debut out start ---"
		 	# --- working directory name ----------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PATH" "${PROG_PATH:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PRAM" "${PROG_PRAM:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_DIRS" "${PROG_DIRS:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_NAME" "${PROG_NAME:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PROC" "${PROG_PROC:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_WORK" "${DIRS_WORK:-}"
		 	# -------------------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_TGET" "${DIRS_TGET:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_ORIG" "${DIRS_ORIG:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_LOGS" "${DIRS_LOGS:-}"
		 	#--- initial settings  ----------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NTPS_ADDR" "${NTPS_ADDR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NTPS_IPV4" "${NTPS_IPV4:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_LHST" "${IPV6_LHST:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_LHST" "${IPV4_LHST:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_DUMY" "${IPV4_DUMY:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "OLDS_FQDN" "${OLDS_FQDN:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "OLDS_HOST" "${OLDS_HOST:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "OLDS_WGRP" "${OLDS_WGRP:-}"
		 	# --- command line parameter ----------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "COMD_LINE" "${COMD_LINE:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_DHCP" "${IPV4_DHCP:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_NAME" "${NICS_NAME:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_MADR" "${NICS_MADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_IPV4" "${NICS_IPV4:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_BIT4" "${NICS_BIT4:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_MASK" "${NICS_MASK:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_DNS4" "${NICS_DNS4:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_GATE" "${NICS_GATE:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_FQDN" "${NICS_FQDN:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_HOST" "${NICS_HOST:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NICS_WGRP" "${NICS_WGRP:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "NMAN_FLAG" "${NMAN_FLAG:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "ISOS_FILE" "${ISOS_FILE:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "SEED_FILE" "${SEED_FILE:-}"
		 	# --- set system parameter ------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DBGS_FLAG" "${DBGS_FLAG:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_NAME" "${DIST_NAME:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_VERS" "${DIST_VERS:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_CODE" "${DIST_CODE:-}"
		 	# -------------------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: \033[42m%s\033[m\n" "--- debut out complete ---"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- debug out file ----------------------------------------------------------
		funcDebugout_file() {
		 	if [ -z "${DBGS_FLAG:-}" ]; then
		 		return
		 	fi
		
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "debug out start: --- [$1] ---"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	cat "$1"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "debug out end: --- [$1] ---"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
		}
		
		# --- initialize --------------------------------------------------------------
		funcInitialize() {
		 	__FUNC_NAME="funcInitialize"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- set system parameter ------------------------------------------------
		 	if command -v tput > /dev/null 2>&1; then
		 		ROWS_SIZE=$(tput lines)
		 		COLS_SIZE=$(tput cols)
		 	fi
		 	if [ "${ROWS_SIZE}" -lt 25 ]; then
		 		ROWS_SIZE=25
		 	fi
		 	if [ "${COLS_SIZE}" -lt 80 ]; then
		 		COLS_SIZE=80
		 	fi
		
		 	readonly      ROWS_SIZE
		 	readonly      COLS_SIZE
		
		 	TEXT_GAPS="$((COLS_SIZE-${#PROG_NAME}-2))"
		 	TEXT_GAP1="$(funcString "${TEXT_GAPS}" '-')"
		 	TEXT_GAP2="$(funcString "${TEXT_GAPS}" '=')"
		
		 	readonly      TEXT_GAP1
		 	readonly      TEXT_GAP2
		
		 	# --- distribution information --------------------------------------------
		 	if [ -e "${DIRS_TGET:-}/etc/os-release" ]; then
		 		DIST_NAME="$(sed -ne 's/^ID=//p'                                "${DIRS_TGET:-}/etc/os-release" | tr '[:upper:]' '[:lower:]')"
		 		DIST_CODE="$(sed -ne 's/^VERSION_CODENAME=//p'                  "${DIRS_TGET:-}/etc/os-release" | tr '[:upper:]' '[:lower:]')"
		 		DIST_VERS="$(sed -ne 's/^VERSION=\"\([[:graph:]]\+\).*\"$/\1/p' "${DIRS_TGET:-}/etc/os-release" | tr '[:upper:]' '[:lower:]')"
		 	elif [ -e "${DIRS_TGET:-}/etc/lsb-release" ]; then
		 		DIST_NAME="$(sed -ne 's/DISTRIB_ID=//p'                                     "${DIRS_TGET:-}/etc/lsb-release" | tr '[:upper:]' '[:lower:]')"
		 		DIST_CODE="$(sed -ne 's/^VERSION=\".*(\([[:graph:]]\+\)).*\"$/\1/p'         "${DIRS_TGET:-}/etc/lsb-release" | tr '[:upper:]' '[:lower:]')"
		 		DIST_VERS="$(sed -ne 's/DISTRIB_RELEASE=\"\([[:graph:]]\+\)[ \t].*\"$/\1/p' "${DIRS_TGET:-}/etc/lsb-release" | tr '[:upper:]' '[:lower:]')"
		 	fi
		
		 	# --- ntp server ipv4 address ---------------------------------------------
		 	NTPS_IPV4="${NTPS_IPV4:-"$(dig "${NTPS_ADDR}" | awk '/^ntp.nict.jp./ {print $5;}' | sort -V | head -n 1)"}"
		
		 	# --- network information -------------------------------------------------
		 	NICS_NAME="${NICS_NAME:-"$(ip -4 -oneline address show primary | grep -E '^2:' | cut -d ' ' -f 2)"}"
		 	NICS_NAME="${NICS_NAME:-"ens160"}"
		 	if [ -z "${IPV4_DHCP:-}" ]; then
		 		_WORK_TEXT="$(sed -ne '/iface[ \t]\+ens160[ \t]\+inet[ \t]\+/ s/^.*\(static\|dhcp\).*$/\1/p' /etc/network/interfaces)"
		 		case "${_WORK_TEXT}" in
		 			static) IPV4_DHCP="false";;
		 			dhcp  ) IPV4_DHCP="true" ;;
		 			*     )
		 				if ip -4 -oneline address show dev "${NICS_NAME}" 2> /dev/null | grep -qE '[ \t]dynamic[ \t]'; then
		 					IPV4_DHCP="true"
		 				else
		 					IPV4_DHCP="false"
		 				fi
		 				;;
		 		esac
		 	fi
		 	NICS_MADR="${NICS_MADR:-"$(ip -4 -oneline link show dev "${NICS_NAME}" 2> /dev/null | sed -ne 's%^.*[ \t]link/ether[ \t]\+\([[:alnum:]:]\+\)[ \t].*$%\1%p')"}"
		 	NICS_IPV4="${NICS_IPV4:-"$(ip -4 -oneline address show dev "${NICS_NAME}"  2> /dev/null | sed -ne 's%^.*[ \t]inet[ \t]\+\([0-9/.]\+\)\+[ \t].*$%\1%p')"}"
		 	NICS_BIT4="$(echo "${NICS_IPV4}/" | cut -d '/' -f 2)"
		 	NICS_IPV4="$(echo "${NICS_IPV4}/" | cut -d '/' -f 1)"
		 	if [ -z "${NICS_BIT4}" ]; then
		 		NICS_BIT4="$(funcIPv4GetNetmask "${NICS_MASK:-"255.255.255.0"}")"
		 	else
		 		NICS_MASK="$(funcIPv4GetNetmask "${NICS_BIT4:-"24"}")"
		 	fi
		 	if [ "${IPV4_DHCP}" = "true" ]; then
		 		NICS_IPV4=""
		 	fi
		 	NICS_IPV4="${NICS_IPV4:-"${IPV4_DUMY}"}"
		 	NICS_DNS4="${NICS_DNS4:-"$(sed -ne 's/^nameserver[ \]\+\([[:alnum:]:.]\+\)[ \t]*$/\1/p' /etc/resolv.conf | sed -e ':l; N; s/\n/,/; b l;')"}"
		 	NICS_GATE="${NICS_GATE:-"$(ip -4 -oneline route list match default | cut -d ' ' -f 3)"}"
		 	NICS_FQDN="${NICS_FQDN:-"$(cat "${DIRS_TGET:-}/etc/hostname")"}"
		 	NICS_HOST="${NICS_WGRP:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 1)"}"
		 	NICS_WGRP="${NICS_WGRP:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 2)"}"
		 	NICS_WGRP="${NICS_WGRP:-"$(sed -ne 's/^search[ \t]\+\([[:alnum:]]\+\)[ \t]*/\1/p' "${DIRS_TGET:-}/etc/resolv.conf")"}"
		 	if [ "${NICS_FQDN}" = "${NICS_HOST}" ] && [ -n "${NICS_WGRP}" ]; then
		 		NICS_FQDN="${NICS_HOST}.${NICS_WGRP}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- file backup -------------------------------------------------------------
		funcFile_backup() {
		 	if [ -n "${DBGS_FLAG:-}" ]; then
		 		____FUNC_NAME="funcFile_backup"
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${____FUNC_NAME}] ---"
		 	fi
		
		 	# --- check ---------------------------------------------------------------
		 	if [ ! -e "${1:?}" ]; then
		 		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "not exist: [$1]"
		 		return
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	_FILE_PATH="${1}"
		 	_BACK_PATH="${1#*"${DIRS_TGET:-}"}"
		 	_BACK_PATH="${DIRS_ORIG}/${_BACK_PATH#/}"
		 	mkdir -p "${_BACK_PATH%/*}"
		 	if [ -e "${_BACK_PATH}" ]; then
		 		_BACK_PATH="${_BACK_PATH}.$(date +"%Y%m%d%H%M%S")"
		 	fi
		 	if [ -n "${DBGS_FLAG:-}" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "backup: ${_FILE_PATH} -> ${_BACK_PATH}"
		 	fi
		 	cp -a "$1" "${_BACK_PATH}"
		
		 	# --- complete ------------------------------------------------------------
		 	if [ -n "${DBGS_FLAG:-}" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${____FUNC_NAME}] ---"
		 	fi
		}
		
		# --- network setup connman ---------------------------------------------------
		funcSetupNetwork_connman() {
		 	__FUNC_NAME="funcSetupNetwork_connman"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v connmanctl > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- disable_dns_proxy.conf ----------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	_WORK_TEXT="$(command -v connmand 2> /dev/null)"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		[Service]
		 		ExecStart=
		 		ExecStart=${_WORK_TEXT} -n --nodnsproxy
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- settings ------------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/var/lib/connman/settings"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		[global]
		 		OfflineMode=false
		 		
		 		[Wired]
		 		Enable=true
		 		Tethering=false
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- configures ----------------------------------------------------------
		 	_WORK_TEXT="$(echo "${NICS_MADR}" | sed -e 's/://g')"
		 	_FILE_PATH="${DIRS_TGET:-}/var/lib/connman/ethernet_${_WORK_TEXT}_cable/settings"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		[ethernet_${_WORK_TEXT}_cable]
		 		Name=Wired
		 		AutoConnect=true
		 		Modified=
		_EOT_
		 	if [ "${IPV4_DHCP}" = "true" ]; then
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			IPv4.method=dhcp
		 			IPv4.DHCP.LastAddress=
		 			IPv6.method=auto
		 			IPv6.privacy=prefered
		_EOT_
		 	else
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			IPv4.method=manual
		 			IPv4.netmask_prefixlen=${NICS_BIT4}
		 			IPv4.local_address=${NICS_IPV4}
		 			IPv4.gateway=${NICS_GATE}
		 			IPv6.method=auto
		 			IPv6.privacy=prefered
		 			Nameservers=${IPV6_LHST};${IPV4_LHST};${NICS_DNS4};
		 			Timeservers=${NTPS_ADDR};
		 			Domains=${NICS_WGRP};
		 			IPv6.DHCP.DUID=
		_EOT_
		 	fi
		 	chmod 600 "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_NAME="connman.service"
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "enabled" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl daemon-reload
		 		systemctl restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup netplan ---------------------------------------------------
		funcSetupNetwork_netplan() {
		 	__FUNC_NAME="funcSetupNetwork_netplan"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v netplan > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- configures ----------------------------------------------------------
		 	if command -v nmcli > /dev/null 2>&1; then
		 		# --- 99-network-config-all.yaml --------------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/netplan/99-network-manager-all.yaml"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			network:
		 			  version: 2
		 			  renderer: NetworkManager
		_EOT_
		 		chmod 600 "${_FILE_PATH}"
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		
		 		# --- 99-disable-network-config.cfg -----------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
		 		if [ -d "${_FILE_PATH%/*}/." ]; then
		 			funcFile_backup "${_FILE_PATH}"
		 			mkdir -p "${_FILE_PATH%/*}"
		 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 				network: {config: disabled}
		_EOT_
		 			# --- debug out ---------------------------------------------------
		 			funcDebugout_file "${_FILE_PATH}"
		 		fi
		 	else
		 		_FILE_PATH="${DIRS_TGET:-}/etc/netplan/99-network-config-${NICS_NAME}.yaml"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			network:
		 			  version: 2
		 			  renderer: networkd
		 			  ethernets:
		 			    ${NICS_NAME}:
		_EOT_
		 		if [ "${IPV4_DHCP}" = "true" ]; then
		 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 				      dhcp4: true
		 				      dhcp6: true
		 				      ipv6-privacy: true
		_EOT_
		 		else
		 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 				      addresses:
		 				      - ${NICS_IPV4}/${NICS_BIT4}
		 				      routes:
		 				      - to: default
		 				        via: ${NICS_GATE}
		 				      nameservers:
		 				        search:
		 				        - ${NICS_WGRP}
		 				        addresses:
		 				        - ${NICS_DNS4}
		 				      dhcp4: false
		 				      dhcp6: true
		 				      ipv6-privacy: true
		_EOT_
		 		fi
		 		chmod 600 "${_FILE_PATH}"
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 	fi
		
		 	# --- netplan -------------------------------------------------------------
		 	netplan apply
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup network manager -------------------------------------------
		funcSetupNetwork_nmanagr() {
		 	__FUNC_NAME="funcSetupNetwork_nmanagr"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v nmcli > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- configures ----------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/system-connections/Wired connection 1"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		[connection]
		 		id=${_FILE_PATH##*/}
		 		type=ethernet
		 		uuid=
		 		interface-name=${NICS_NAME}
		 		
		 		[ethernet]
		 		wake-on-lan=0
		 		mac-address=${NICS_MADR}
		 		
		_EOT_
		 	if [ "${IPV4_DHCP}" = "true" ]; then
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			[ipv4]
		 			method=auto
		 			
		 			[ipv6]
		 			method=auto
		 			addr-gen-mode=default
		 			
		 			[proxy]
		_EOT_
		 	else
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			[ipv4]
		 			method=manual
		 			address1=${NICS_IPV4}/${NICS_BIT4},${NICS_GATE}
		 			dns=${NICS_DNS4};
		 			
		 			[ipv6]
		 			method=auto
		 			addr-gen-mode=default
		 			
		 			[proxy]
		_EOT_
		 	fi
		 	chmod 600 "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- dns.conf ------------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/conf.d/dns.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		[main]
		 		dns=dnsmasq
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_NAME="NetworkManager.service"
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "enabled" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl daemon-reload
		 		systemctl restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup hostname --------------------------------------------------
		funcSetupNetwork_hostname() {
		 	__FUNC_NAME="funcSetupNetwork_hostname"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- hostname ------------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/hostname"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	echo "${NICS_FQDN:-}" > "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup hosts -----------------------------------------------------
		funcSetupNetwork_hosts() {
		 	__FUNC_NAME="funcSetupNetwork_hosts"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- hosts ---------------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/hosts"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	TEXT_GAPS="$(funcString "$((16-${#NICS_IPV4}))" " ")"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		${IPV4_LHST:-"127.0.0.1"}       localhost
		 		${NICS_IPV4}${TEXT_GAPS}${NICS_FQDN} ${NICS_HOST}
		 		
		 		# The following lines are desirable for IPv6 capable hosts
		 		${IPV6_LHST:-"::1"}             localhost ip6-localhost ip6-loopback
		 		fe00::0         ip6-localnet
		 		ff00::0         ip6-mcastprefix
		 		ff02::1         ip6-allnodes
		 		ff02::2         ip6-allrouters
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup firewalld -------------------------------------------------
		funcSetupNetwork_firewalld() {
		 	__FUNC_NAME="funcSetupNetwork_firewalld"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		  
		 	# --- check command -------------------------------------------------------
		 	if ! command -v firewall-cmd > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- firewalld -----------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/firewalld/zones/home.xml"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	sed -e '/<\/zone>/i\  <interface name="'"${NICS_NAME}"'"/>' \
		 	    -e '/samba-client/i\  <service name="samba"/>'          \
		 	    "${DIRS_TGET:-}/usr/lib/firewalld/zones/home.xml"       \
		 	> "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_NAME="firewalld.service"
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "enabled" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl daemon-reload
		 		systemctl restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup resolv.conf -----------------------------------------------
		funcSetupNetwork_resolv() {
		 	__FUNC_NAME="funcSetupNetwork_resolv"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if command -v resolvectl > /dev/null 2>&1; then
		 		# --- resolved.conf ---------------------------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/systemd/resolved.conf"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		if ! grep -qE '^DNS=' "${_FILE_PATH}"; then
		 			sed -i "${_FILE_PATH}"                       \
		 			    -e '/^\[Resolve\]$/a DNS='"${IPV4_LHST}"
		 		fi
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		
		 		# --- systemctl -------------------------------------------------------
		 		_SRVC_NAME="systemd-resolved.service"
		 		_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 		if [ "${_SRVC_STAT}" = "enabled" ]; then
		 			printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 			systemctl daemon-reload
		 			systemctl restart "${_SRVC_NAME}"
		 		fi
		 	else
		 		# --- resolv.conf -----------------------------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/resolv.conf"
		 		if [ -h "${_FILE_PATH}" ]; then
		 			printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 			return
		 		fi
		
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			# Generated by user script
		 			search ${NICS_WGRP}
		 			nameserver ${IPV6_LHST}
		 			nameserver ${IPV4_LHST}
		 			nameserver ${NICS_DNS4}
		_EOT_
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup dnsmasq ---------------------------------------------------
		funcSetupNetwork_dnsmasq() {
		 	__FUNC_NAME="funcSetupNetwork_dnsmasq"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v dnsmasq > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- default.conf --------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/dnsmasq.d/default.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		# --- log ---------------------------------------------------------------------
		 		#log-queries												# dns query log output
		 		#log-dhcp													# dhcp transaction log output
		 		#log-facility=												# log output file name
		 		
		 		# --- dns ---------------------------------------------------------------------
		 		#port=5353													# listening port
		 		bogus-priv													# do not perform reverse lookup of private ip address on upstream server
		 		domain-needed												# do not forward plain names
		 		domain=${NICS_WGRP}											# local domain name
		 		expand-hosts												# add domain name to host
		 		filterwin2k													# filter for windows
		 		interface=lo,${NICS_NAME}											# listen to interface
		 		listen-address=${IPV6_LHST},${IPV4_LHST},${NICS_IPV4}					# listen to ip address
		 		#server=8.8.8.8												# directly specify upstream server
		 		#server=8.8.4.4												# directly specify upstream server
		 		#no-hosts													# don't read the hostnames in /etc/hosts
		 		#no-poll													# don't poll /etc/resolv.conf for changes
		 		#no-resolv													# don't read /etc/resolv.conf
		 		strict-order												# try in the registration order of /etc/resolv.conf
		 		bind-dynamic												# enable bind-interfaces and the default hybrid network mode
		 		
		 		# --- dhcp --------------------------------------------------------------------
		 		dhcp-range=${NICS_IPV4%.*}.0,proxy,24								# proxy dhcp
		 		#dhcp-range=${NICS_IPV4%.*}.64,${NICS_IPV4%.*}.79,12h					# dhcp range
		 		#dhcp-option=option:netmask,255.255.255.0					#  1 netmask
		 		dhcp-option=option:router,${NICS_GATE}						#  3 router
		 		dhcp-option=option:dns-server,${NICS_IPV4},${NICS_GATE}		#  6 dns-server
		 		dhcp-option=option:domain-name,${NICS_WGRP}					# 15 domain-name
		 		#dhcp-option=option:28,${NICS_IPV4%.*}.255						# 28 broadcast
		 		#dhcp-option=option:ntp-server,${NTPS_IPV4}				# 42 ntp-server
		 		#dhcp-option=option:tftp-server,${NICS_IPV4}					# 66 tftp-server
		 		#dhcp-option=option:bootfile-name,							# 67 bootfile-name
		 		dhcp-no-override											# disable re-use of the dhcp servername and filename fields as extra option space
		 		
		 		# --- dnsmasq manual page -----------------------------------------------------
		 		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
		 		
		 		# --- eof ---------------------------------------------------------------------
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- pxeboot.conf --------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		# --- tftp --------------------------------------------------------------------
		 		#enable-tftp=${NICS_NAME}                                         # enable tftp server
		 		#tftp-root=/var/lib/tftpboot                                # tftp root directory
		 		#tftp-lowercase                                             # convert tftp request path to all lowercase
		 		#tftp-no-blocksize                                          # stop negotiating "block size" option
		 		#tftp-no-fail                                               # do not abort startup even if tftp directory is not accessible
		 		#tftp-secure                                                # enable tftp secure mode
		 		
		 		# --- pxe boot ----------------------------------------------------------------
		 		#pxe-prompt="Press F8 for boot menu", 0                                             # pxe boot prompt
		 		#pxe-service=x86PC            , "PXEBoot-x86PC"            , boot/grub/pxelinux     #  0 Intel x86PC
		 		#pxe-service=PC98             , "PXEBoot-PC98"             ,                        #  1 NEC/PC98
		 		#pxe-service=IA64_EFI         , "PXEBoot-IA64_EFI"         ,                        #  2 EFI Itanium
		 		#pxe-service=Alpha            , "PXEBoot-Alpha"            ,                        #  3 DEC Alpha
		 		#pxe-service=Arc_x86          , "PXEBoot-Arc_x86"          ,                        #  4 Arc x86
		 		#pxe-service=Intel_Lean_Client, "PXEBoot-Intel_Lean_Client",                        #  5 Intel Lean Client
		 		#pxe-service=IA32_EFI         , "PXEBoot-IA32_EFI"         ,                        #  6 EFI IA32
		 		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , boot/grub/bootx64.efi  #  7 EFI BC
		 		#pxe-service=Xscale_EFI       , "PXEBoot-Xscale_EFI"       ,                        #  8 EFI Xscale
		 		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , boot/grub/bootx64.efi  #  9 EFI x86-64
		 		#pxe-service=ARM32_EFI        , "PXEBoot-ARM32_EFI"        ,                        # 10 ARM 32bit
		 		#pxe-service=ARM64_EFI        , "PXEBoot-ARM64_EFI"        ,                        # 11 ARM 64bit
		 		
		 		# --- ipxe block --------------------------------------------------------------
		 		#dhcp-match=set:iPXE,175                                                            #
		 		#pxe-prompt="Press F8 for boot menu", 0                                             # pxe boot prompt
		 		#pxe-service=tag:iPXE ,x86PC     , "PXEBoot-x86PC"     , /autoexec.ipxe             #  0 Intel x86PC (iPXE)
		 		#pxe-service=tag:!iPXE,x86PC     , "PXEBoot-x86PC"     , ipxe/undionly.kpxe         #  0 Intel x86PC
		 		#pxe-service=tag:!iPXE,BC_EFI    , "PXEBoot-BC_EFI"    , ipxe/ipxe.efi              #  7 EFI BC
		 		#pxe-service=tag:!iPXE,x86-64_EFI, "PXEBoot-x86-64_EFI", ipxe/ipxe.efi              #  9 EFI x86-64
		 		
		 		# --- dnsmasq manual page -----------------------------------------------------
		 		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
		 		
		 		# --- eof ---------------------------------------------------------------------
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- dns.conf ------------------------------------------------------------
		 	if command -v nmcli > /dev/null 2>&1; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/conf.d/dns.conf"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			[main]
		 			dns=dnsmasq
		_EOT_
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 	fi
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_NAME="dnsmasq.service"
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "enabled" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl daemon-reload
		 		systemctl restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		 }
		
		# --- skeleton settings -------------------------------------------------------
		funcSetupConfig_skel() {
		 	__FUNC_NAME="funcSetupConfig_skel"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- .bashrc -------------------------------------------------------------
		 	if [ -e "${DIRS_TGET:-}/etc/skel/.bashrc" ]; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.bashrc"
		 	elif [ -e "${DIRS_TGET:-}/etc/skel/.i18n" ]; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.i18n"
		 	else
		 		_FILE_PATH=""
		 	fi
		 	if [ -n "${_FILE_PATH}" ]; then
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			# --- measures against garbled characters ---
		 			case "${TERM}" in
		 			    linux ) export LANG=C;;
		 			    *     )              ;;
		 			esac
		 			# --- user custom ---
		 			alias vi='vim'
		 			alias view='vim'
		 			alias diff='diff --color=auto'
		 			alias ip='ip -color=auto'
		 			alias ls='ls --color=auto'
		_EOT_
		 	fi
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- .bash_history -------------------------------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.bash_history"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			sudo bash -c 'apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade'
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- .vimrc --------------------------------------------------------------
		 	_WORK_TEXT="$(funcInstallPackage "vim")"
		 	if [ -z "${_WORK_TEXT}" ]; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.vimrc"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
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
		 	fi
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- .curlrc -------------------------------------------------------------
		 	_WORK_TEXT="$(funcInstallPackage "curl")"
		 	if [ -z "${_WORK_TEXT}" ]; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.curlrc"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			location
		 			progress-bar
		 			remote-time
		 			show-error
		_EOT_
		 	fi
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		
		 	# --- distribute to existing users ----------------------------------------
		 	for _DIRS_USER in "${DIRS_TGET:-}"/root \
		 	                  "${DIRS_TGET:-}"/home/*
		 	do
		 		for _FILE_PATH in "${DIRS_TGET:-}/etc/skel/.bashrc"       \
		 		                  "${DIRS_TGET:-}/etc/skel/.bash_history" \
		 		                  "${DIRS_TGET:-}/etc/skel/.vimrc"        \
		 		                  "${DIRS_TGET:-}/etc/skel/.curlrc"
		 		do
		 			if [ ! -e "${_FILE_PATH}" ]; then
		 				continue
		 			fi
		 			_DIRS_DEST="${_DIRS_USER}/${_FILE_PATH#*/etc/skel/}"
		 			_DIRS_DEST="${_DIRS_DEST%/*}"
		 			mkdir -p "${_DIRS_DEST}"
		 			cp -a "${_FILE_PATH}" "${_DIRS_DEST}"
		 			chown "${_DIRS_USER##*/}": "${_DIRS_DEST}/${_FILE_PATH##*/}"
		 		done
		 	done
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- main --------------------------------------------------------------------
		funcMain() {
		 	_FUNC_NAME="funcMain"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${_FUNC_NAME}] ---"
		
		 	# --- initialize ----------------------------------------------------------
		 	funcInitialize						# initialize
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_parameter
		
		 	# --- network manager -----------------------------------------------------
		 	funcSetupNetwork_connman			# network setup connman
		 	funcSetupNetwork_netplan			# network setup netplan
		 	funcSetupNetwork_nmanagr			# network setup network manager
		
		 	# --- network settings ----------------------------------------------------
		 	funcSetupNetwork_hostname			# network setup hostname
		 	funcSetupNetwork_hosts				# network setup hosts
		 	funcSetupNetwork_firewalld			# network setup firewalld
		 	funcSetupNetwork_resolv				# network setup resolv.conf
		 	funcSetupNetwork_dnsmasq			# network setup dnsmasq
		
		 	# --- skeleton settings ---------------------------------------------------
		 	funcSetupConfig_skel
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${_FUNC_NAME}] ---"
		 }
		
		# *** main processing section *************************************************
		 	# --- start ---------------------------------------------------------------
		 	_start_time=$(date +%s)
		 	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
		 	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing start"
		 	# --- main ----------------------------------------------------------------
		 	funcMain
		 	# --- complete ------------------------------------------------------------
		 	_end_time=$(date +%s)
		 	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
		 	printf "\033[m${PROG_NAME}: elapsed time: %dd%02dh%02dm%02ds\033[m\n" "$(((_end_time-_start_time)/86400))" "$(((_end_time-_start_time)%86400/3600))" "$(((_end_time-_start_time)%3600/60))" "$(((_end_time-_start_time)%60))"
		 	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing complete"
		 	exit 0
		
		### eof #######################################################################
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
		"ps_debian_"{server,desktop}{,_old,_oldold}".cfg"   \
		"ps_ubuntu_"{server,desktop}{,_old,_oldold}".cfg"   \
		"ps_ubiquity_"{server,desktop}{,_old,_oldold}".cfg" \
	)
	declare       FILE_TMPL=""
	declare       INSR_STRS=""			# string to insert
	declare -i    I=0
	# -------------------------------------------------------------------------
	for I in "${!FILE_LIST[@]}"
	do
		case "${FILE_LIST[I]}" in
			*_debian_*   ) FILE_TMPL="${CONF_SEDD}";;
			*_ubuntu_*   ) FILE_TMPL="${CONF_SEDU}";;
			*_ubiquity_* ) FILE_TMPL="${CONF_SEDU}";;
			* ) continue;;
		esac
		FILE_PATH="${DIRS_NAME}/${FILE_LIST[I]}"
		funcPrintf "%20.20s: %s" "create file" "${FILE_PATH/${PWD}\/}"
		mkdir -p "${FILE_PATH%/*}"
		# ---------------------------------------------------------------------
		cp --backup "${FILE_TMPL}" "${FILE_PATH}"
		if [[ "${FILE_LIST[I]}" =~ _oldold ]]; then
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
		if [[ "${FILE_LIST[I]}" =~ _old ]]; then
			sed -i "${FILE_PATH}"             \
			    -e '/usr-is-merged/ s/^ /#/g'
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
	declare -r -a DIRS_LIST=("${DIRS_CONF}/nocloud/ubuntu_"{server,desktop}{,_old,_oldold})
	declare       DIRS_NAME=""
	declare -i    I=0
	# -------------------------------------------------------------------------
	for I in "${!DIRS_LIST[@]}"
	do
		DIRS_NAME="${DIRS_LIST[I]}"
		funcPrintf "%20.20s: %s" "create file" "${DIRS_NAME/${PWD}\/}"
		mkdir -p "${DIRS_NAME}"
		# ---------------------------------------------------------------------
		cp --backup "${CONF_CLUD}" "${DIRS_NAME}/user-data"
		if [[ "${DIRS_NAME}" =~ _oldold ]]; then
			sed -i "${DIRS_NAME}/user-data"     \
			    -e 's/bind9-utils/bind9utils/'  \
			    -e 's/bind9-dnsutils/dnsutils/'
		fi
		if [[ "${DIRS_NAME}" =~ _desktop ]]; then
			sed -i "${DIRS_NAME}/user-data"                                    \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
		fi
		if [[ "${DIRS_NAME}" =~ _old ]]; then
			sed -i "${DIRS_NAME}/user-data"     \
			    -e '/usr-is-merged/ s/^ /#/g'
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
	declare       DSTR_NAME=""
	declare       DSTR_NUMS=""
	declare       RLNX_NUMS=""
	declare -r    BASE_ARCH="x86_64"
	declare       DSTR_SECT=""
	declare -i    I=0
	declare    -a FILE_LIST=()
	declare       FILE_LINE=""
	# -------------------------------------------------------------------------
	FILE_LIST=()
	for I in "${!DATA_LIST[@]}"
	do
		FILE_LINE="$(echo "${DATA_LIST[I]}" | awk '$1=="o"&&$9~/kickstart/ {split($9,s,"/"); print s[2];}')"
		if [[ -z "${FILE_LINE}" ]]; then
			continue
		fi
		FILE_LIST+=("${FILE_LINE}")
		case "${FILE_LINE}" in
			*_dvd.cfg) FILE_LIST+=("${FILE_LINE/_dvd./_web.}");;
			*) ;;
		esac
	done
	# -------------------------------------------------------------------------
	for I in "${!FILE_LIST[@]}"
	do
		FILE_PATH="${DIRS_NAME}/${FILE_LIST[I]}"
		funcPrintf "%20.20s: %s" "create file" "${FILE_NAME/${PWD}\/}"
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
			case "${DSTR_NUMS}" in
				8) DSTR_SECT="${DSTR_NAME/-/ }-${DSTR_NUMS}";;
				*) DSTR_SECT="${DSTR_NAME/-/ }-9"           ;;
			esac
		fi
		# --- cdrom, hostname, install repository -----------------------------
		case "${FILE_LIST[I]}" in
			*_dvd* )	# --- cdrom install -----------------------------------
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
				    -e "s/\$basearch/${BASE_ARCH}/g       }} "
				;;
			*_web* )	# --- network install [ _WEBADDR_ ] -------------------
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
				    -e "s/\$basearch/${BASE_ARCH}/g       }} "
				;;
			* )			# --- network install [ ! _WEBADDR_ ] -----------------
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
				    -e "s/\$basearch/${BASE_ARCH}/g       }} "
				;;
		esac
		# --- post script -----------------------------------------------------
		sed -i "${FILE_PATH}"                          \
		    -e "/%post/,/%end/                     { " \
		    -e "s/\$releasever/${RLNX_NUMS}/g        " \
		    -e "s/\$basearch/${BASE_ARCH}/g        } "
		case "${DSTR_NAME}" in
			fedora        | \
			centos-stream )
				sed -i "${FILE_PATH}"                          \
				    -e "/%post/,/%end/                     { " \
				    -e "/install repositories/ s/^/#/        " \
				    -e "/epel-release/         s/^/#/        " \
				    -e "/remi-release/         s/^/#/      } "
				;;
			* ) ;;
		esac
		# --- RHL ver <= 8, time zone & ntp server ----------------------------
		if [[ ${RLNX_NUMS} -le 8 ]]; then
			sed -i "${FILE_PATH}"                      \
			    -e "/^timesource/             s/^/#/g" \
			    -e "/^timezone/               s/^/#/g" \
			    -e "/timezone.* --ntpservers/ s/^#//g"
		fi
		# --- fedora ----------------------------------------------------------
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
	for I in "${!FILE_LIST[@]}"
	do
		FILE_PATH="${DIRS_NAME}/${FILE_LIST[I]}"
		funcPrintf "%20.20s: %s" "create file" "${FILE_PATH/${PWD}\/}"
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

# ----- create menu -----------------------------------------------------------
function funcCreate_menu() {
	declare -a    DATA_ARRY=("$@")
	declare -a    DATA_LINE=()
	declare       FILE_PATH=""
	declare -a    FILE_INFO=()
	declare       WEBS_ADDR=""			# web url
	declare -a    WEBS_PAGE=()			# web page data
	declare       WEBS_STAT=""			# web status
	declare       MESG_TEXT=""			# message text
	declare       WORK_LINE=""			# array -> line
	declare       WORK_TEXT=""
	declare -a    WORK_ARRY=()
	declare -i    I=0
	declare -i    J=0
	# -------------------------------------------------------------------------
	funcPrintf "# ${TEXT_GAP1:1:((${#TEXT_GAP1}-4))} #"
	funcPrintf "${TXT_RESET}#%-2.2s:%-42.42s:%-10.10s:%-10.10s:%-$((COLS_SIZE-70)).$((COLS_SIZE-70))s${TXT_RESET}#" "ID" "Version" "ReleaseDay" "SupportEnd" "Memo"
#	IFS= mapfile -d ' ' -t WORK_ARRY < <(echo "${TGET_INDX}")
	TGET_LIST=()
	for I in "${!DATA_ARRY[@]}"
	do
		WORK_TEXT="$(echo -n "${DATA_ARRY[I]}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
		IFS=$'\n' mapfile -d ' ' -t DATA_LINE < <(echo -n "${WORK_TEXT}")
		if [[ "${DATA_LINE[0]}" != "o" ]] \
		|| { [[ "${DATA_LINE[17]%%//*}" != "http:" ]] && [[ "${DATA_LINE[17]%%//*}" != "https:" ]]; }; then
			continue
		fi
		TEXT_COLR=""
		MESG_TEXT=""
										# --- media information ---------------
										#  0: [m] menu / [o] output / [else] hidden
										#  1: iso image file copy destination directory
										#  2: entry name
										#  3: [unused]
										#  4: iso image file directory
										#  5: iso image file name
										#  6: boot loader's directory
										#  7: initial ramdisk
										#  8: kernel
										#  9: configuration file
										# 10: iso image file copy source directory
#		DATA_LINE[11]="-"				# 11: release date
										# 12: support end
		DATA_LINE[13]="-"				# 13: time stamp
		DATA_LINE[14]="-"				# 14: file size
		DATA_LINE[15]="-"				# 15: volume id
		DATA_LINE[16]="-"				# 16: status
										# 17: download URL
										# 18: time stamp of remastered image file
		# --- URL completion [dir name] ---------------------------------------
		WEBS_ADDR="${DATA_LINE[17]}"
		while [[ -n "${WEBS_ADDR//[^?*\[\]]}" ]]
		do
			WEBS_ADDR="${WEBS_ADDR%%[*}"
			WEBS_ADDR="${WEBS_ADDR%/*}"
			WEBS_PATN="${DATA_LINE[17]/"${WEBS_ADDR}/"}"
			WEBS_PATN="${WEBS_PATN%%/*}"
			if ! WORK_TEXT="$(LANG=C wget "${WGET_OPTN[@]}" --output-document=- "${WEBS_ADDR}" 2>&1)"; then
				MESG_TEXT="error $?: ${WORK_TEXT}"
#				printf "[%s]\n" "${WORK_TEXT}"
				TEXT_COLR="${TXT_RED}"
				break
			fi
			WORK_ARRY=()
			IFS= mapfile -d $'\n' WEBS_PAGE < <(echo -n "${WORK_TEXT}")
			if ! WORK_TEXT="$(echo "${WEBS_PAGE[@]}" | grep "<a href=\"${WEBS_PATN}/*\">")"; then
				continue
			fi
			IFS= mapfile -d $'\n' WORK_ARRY < <(echo -n "${WORK_TEXT}")
			WORK_ARRY=("$(echo "${WORK_ARRY[@]}" | sed -ne 's/^.*\('"${WEBS_PATN}"'\).*$/\1/p')")
			WORK_TEXT="$(printf "%s\n" "${WORK_ARRY[@]}" | sort -rVu -t $'\n')"
			IFS= mapfile -d $'\n' -t WORK_ARRY < <(echo -n "${WORK_TEXT}")
			WEBS_ADDR="${DATA_LINE[17]/"${WEBS_PATN}"/"${WORK_ARRY[0]}"}"
			DATA_LINE[17]="${WEBS_ADDR}"
		done
		# --- get and set local image file information ------------------------
		FILE_PATH="${DATA_LINE[4]}/${DATA_LINE[5]}"
		if [[ ! -e "${FILE_PATH}" ]]; then
			TEXT_COLR="${TEXT_COLR:-"${TXT_CYAN}"}"
		else
			IFS= mapfile -d ' ' -t FILE_INFO < <(LANG=C TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${FILE_PATH}" || true)
			DATA_LINE[11]="${FILE_INFO[5]:0:4}-${FILE_INFO[5]:4:2}-${FILE_INFO[5]:6:2}"
			DATA_LINE[13]="${FILE_INFO[5]}"
			DATA_LINE[14]="${FILE_INFO[4]}"
			DATA_LINE[15]="$(LANG=C file -L "${FILE_PATH}")"
			DATA_LINE[15]="${DATA_LINE[15]#*\'}"
			DATA_LINE[15]="${DATA_LINE[15]%\'*}"
			DATA_LINE[15]="${DATA_LINE[15]// /%20}"
			TEXT_COLR="${TEXT_COLR:-""}"
		fi
		# --- get and set server-side image file information ------------------
		if [[ "${TEXT_COLR}" != "${TXT_RED}" ]]; then
			if ! WORK_TEXT="$(LANG=C wget "${WGET_OPTN[@]}" --spider --server-response --output-document=- "${WEBS_ADDR}" 2>&1)"; then
				MESG_TEXT="error $?: ${WORK_TEXT}"
#				printf "[%s]\n" "${WORK_TEXT}"
				TEXT_COLR="${TXT_RED}"
			fi
			WORK_TEXT="$(echo -n "${WORK_TEXT}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
			IFS= mapfile -d $'\n' -t WEBS_PAGE < <(echo -n "${WORK_TEXT}")
			WEBS_STAT=""
			for J in "${!WEBS_PAGE[@]}"
			do
				WORK_LINE="${WEBS_PAGE[J]}"
				WEBS_TEXT="${WORK_LINE,,}"
				WEBS_TEXT="${WEBS_TEXT%% *}"
				case "${WEBS_TEXT}" in
					http/*)
						WEBS_STAT="${WORK_LINE#* }"
						WEBS_STAT="${WEBS_STAT%% *}"
						case "${WEBS_STAT}" in			# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
#							1??) ;;	# 1xx (Informational): The request was received, continuing process
							100) ;;	#   Continue
							101) ;;	#   Switching Protocols
#							2??) ;;	# 2xx (Successful): The request was successfully received, understood, and accepted
							200) ;;	#   OK
							201) ;;	#   Created
							202) ;;	#   Accepted
							203) ;;	#   Non-Authoritative Information
							204) ;;	#   No Content
							205) ;;	#   Reset Content
							206) ;;	#   Partial Content
#							3??) ;;	# 3xx (Redirection): Further action needs to be taken in order to complete the request
							300) ;;	#   Multiple Choices
							301) ;;	#   Moved Permanently
							302) ;;	#   Found
							303) ;;	#   See Other
							304) ;;	#   Not Modified
							305) ;;	#   Use Proxy
							306) ;;	#   (Unused)
							307) ;;	#   Temporary Redirect
							308) ;;	#   Permanent Redirect
#							4??) ;;	# 4xx (Client Error): The request contains bad syntax or cannot be fulfilled
#							400) ;;	#   Bad Request
#							401) ;;	#   Unauthorized
#							402) ;;	#   Payment Required
#							403) ;;	#   Forbidden
#							404) ;;	#   Not Found
#							405) ;;	#   Method Not Allowed
#							406) ;;	#   Not Acceptable
#							407) ;;	#   Proxy Authentication Required
#							408) ;;	#   Request Timeout
#							409) ;;	#   Conflict
#							410) ;;	#   Gone
#							411) ;;	#   Length Required
#							412) ;;	#   Precondition Failed
#							413) ;;	#   Content Too Large
#							414) ;;	#   URI Too Long
#							415) ;;	#   Unsupported Media Type
#							416) ;;	#   Range Not Satisfiable
#							417) ;;	#   Expectation Failed
#							418) ;;	#   (Unused)
#							421) ;;	#   Misdirected Request
#							422) ;;	#   Unprocessable Content
#							426) ;;	#   Upgrade Required
#							5??) ;;	# 5xx (Server Error): The server failed to fulfill an apparently valid request
#							500) ;;	#   Internal Server Error
#							501) ;;	#   Not Implemented
#							502) ;;	#   Bad Gateway
#							503) ;;	#   Service Unavailable
#							504) ;;	#   Gateway Timeout
#							505) ;;	#   HTTP Version Not Supported
							*)		# error
								MESG_TEXT="${WORK_LINE}"
								TEXT_COLR="${TXT_RED}"
#								printf "[%s]\n" "${WEBS_PAGE[@]}"
								break
								;;
						esac
						;;
					content-length:)
						if [[ "${WEBS_STAT}" != "200" ]]; then
							continue
						fi
						WORK_TEXT="${WORK_LINE#* }"
						if [[ "${DATA_LINE[14]}" != "${WORK_TEXT}" ]]; then
							TEXT_COLR="${TEXT_COLR:-"${TXT_GREEN}"}"
						fi
						DATA_LINE[14]="${WORK_TEXT}"
#						DATA_LINE[16]+="${DATA_LINE[16]:+","}${WORK_LINE%%:*}=${WORK_TEXT}"
						;;
					last-modified:)
						if [[ "${WEBS_STAT}" != "200" ]]; then
							continue
						fi
						WORK_TEXT="$(TZ=UTC date -d "${WORK_LINE#* }" "+%Y%m%d%H%M%S")"
						if [[ "${DATA_LINE[13]}" != "${WORK_TEXT}" ]]; then
							TEXT_COLR="${TEXT_COLR:-"${TXT_GREEN}"}"
						fi
						DATA_LINE[11]="${WORK_TEXT:0:4}-${WORK_TEXT:4:2}-${WORK_TEXT:6:2}"
						WORK_TEXT="$(TZ=UTC date -d "${WORK_LINE#* }" "+%Y-%m-%d_%H:%M:%S")"
#						DATA_LINE[16]+="${DATA_LINE[16]:+","}${WORK_LINE%%:*}=${WORK_TEXT}"
						;;
					*)
						;;
				esac
			done
		fi
		# --- get remastered image file information ---------------------------
		FILE_PATH="${DIRS_RMAK}/${DATA_LINE[5]%.*}_${DATA_LINE[9]%%/*}.${DATA_LINE[5]##*.}"
		if [[ ! -e "${FILE_PATH}" ]]; then
			TEXT_COLR="${TEXT_COLR:-"${TXT_YELLOW}"}${TXT_REV}"
		else
			IFS= mapfile -d ' ' -t FILE_INFO < <(LANG=C TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${FILE_PATH}" || true)
			DATA_LINE+=("${FILE_INFO[5]}")
			if [[ "${DATA_LINE[13]}" -gt "${DATA_LINE[18]}" ]]; then
				TEXT_COLR="${TEXT_COLR:-"${TXT_YELLOW}"}${TXT_REV}"
			else
				case "${DATA_LINE[9]%%/*}" in
					nocloud) FILE_PATH="${DIRS_CONF}/${DATA_LINE[9]}/user-data";;
					*      ) FILE_PATH="${DIRS_CONF}/${DATA_LINE[9]}";;
				esac
				if [[ -e "${FILE_PATH}" ]]; then
					IFS= mapfile -d ' ' -t FILE_INFO < <(LANG=C TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${FILE_PATH}" || true)
					if [[ "${FILE_INFO[5]}" -gt "${DATA_LINE[18]}" ]]; then
						TEXT_COLR="${TEXT_COLR:-"${TXT_YELLOW}"}${TXT_REV}"
					fi
				fi
			fi
		fi
		# --- set download status ---------------------------------------------
		DATA_LINE[16]="${TEXT_COLR}"
		DATA_LINE[16]="${DATA_LINE[16]// /%20}"
		DATA_LINE[16]="${DATA_LINE[16]:-"-"}"
		# --- set target data information -------------------------------------
		if [[ "${_DBGOUT:-}" = "true" ]]; then
			printf "${TXT_RESET}[%s]${TXT_RESET}\n" "${DATA_LINE[@]//${ESC}/\\033}"
		fi
		DATA_ARRY[I]="${DATA_LINE[*]}"
#		TGET_LIST+=("${DATA_LINE[*]}")
		# --- display of target data information ------------------------------
		WORK_TEXT="${DATA_LINE[2]//%20/ }"
		WORK_TEXT="${WORK_TEXT%_*}[${DATA_LINE[9]##*/}]"
		WORK_TEXT="${MESG_TEXT:-"${WORK_TEXT}"}"
		funcPrintf "${TXT_RESET}#${TEXT_COLR}%2.2s:%-42.42s:%-10.10s:%-10.10s:%-$((COLS_SIZE-70)).$((COLS_SIZE-70))s${TXT_RESET}#" "${I}" "${DATA_LINE[5]}" "${DATA_LINE[11]}" "${DATA_LINE[12]}" "${WORK_TEXT}"
	done
	TGET_LIST=("${DATA_ARRY[@]}")
	funcPrintf "# ${TEXT_GAP1:1:((${#TEXT_GAP1}-4))} #"
	# --- data display ----------------------------------------------------
	# TXT_RESET  local files are up to date
	# TXT_RED    failed to get web information
	# TXT_CYAN   local file does not exist
	# TXT_GREEN  local file is old
	# TXT_YELLOW custom file is old
	# TXT_REV    requires creation of custom file
}

# ----- create target list ----------------------------------------------------
function funcCreate_target_list() {
	read -r -p "enter the number to create:" TGET_INDX
	if [[ -z "${TGET_INDX:-}" ]]; then
		return
	fi
	case "${TGET_INDX,,}" in
		a | all ) TGET_INDX="{1..${#TGET_LIST[@]}}";;
		*       ) ;;
	esac
	TGET_INDX="$(eval echo "${TGET_INDX}")"
}

# ----- create remaster download-----------------------------------------------
function funcCreate_remaster_download() {
	declare -r -a TGET_LINE=("$@")
	declare -r    FILE_PATH="${TGET_LINE[4]}/${TGET_LINE[5]}"
	declare       WORK_TEXT=""
	# --- download ------------------------------------------------------------
	case "${TGET_LINE[16]}" in
		*${TXT_CYAN}*  | \
		*${TXT_GREEN}* )
			WORK_TEXT="$(funcUnit_conversion "${TGET_LINE[14]}")"
			funcPrintf "%20.20s: %s" "download" "${TGET_LINE[5]} ${WORK_TEXT}"
			if ! LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress --output-document="${FILE_PATH}.tmp" "${TGET_LINE[17]}" 2>&1; then
				funcPrintf "%20.20s: %s" "error" "${TXT_RED}Download was skipped because an ${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
			else
				mv --force "${FILE_PATH}.tmp" "${FILE_PATH}"
				DATA_LINE[16]="$(LANG=C file -L "${FILE_PATH}")"
			fi
			;;
		*)	;;
	esac
}

# ----- copy iso contents to hdd ----------------------------------------------
function funcCreate_copy_iso2hdd() {
	declare -r -a TGET_LINE=("$@")
	declare -r    FILE_PATH="${TGET_LINE[4]}/${TGET_LINE[5]}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare       DIRS_IRAM=""								# initrd image directory
	declare       FILE_IRAM=""								# initrd path
#	declare       FILE_VLNZ=""								# kernel path
	# -------------------------------------------------------------------------
	WORK_TEXT="$(funcUnit_conversion "${TGET_LINE[14]}")"
	funcPrintf "%20.20s: %s" "copy" "${TGET_LINE[5]} ${WORK_TEXT}"
	# --- copy iso -> hdd -----------------------------------------------------
	rm -rf "${WORK_DIRS:?}"
	mkdir -p "${WORK_DIRS}/"{mnt,img,ram}
	mount -o ro,loop "${FILE_PATH}" "${WORK_DIRS}/mnt"
	ionice -c "${IONICE_CLAS}" cp -a "${WORK_DIRS}/mnt/." "${WORK_DIRS}/img/"
	umount "${WORK_DIRS}/mnt"
	# --- copy initrd -> hdd --------------------------------------------------
	find "${WORK_DIRS}/img" \( -type f -o -type l \) \( -name 'initrd' -o -name 'initrd.*' -o -name 'initrd-[0-9]*' \) | sort -V | \
	while read -r FILE_IRAM
	do
		DIRS_IRAM="${WORK_DIRS}/ram/${FILE_IRAM##*/}/"
		funcPrintf "%20.20s: %s" "copy" "${FILE_IRAM##*/}"
		mkdir -p "${DIRS_IRAM}"
		unmkinitramfs "${FILE_IRAM}" "${DIRS_IRAM}" 2>/dev/null
	done
}

# ----- create autoinst.cfg for syslinux --------------------------------------
function funcCreate_autoinst_cfg_syslinux() {
	declare -r    AUTO_PATH="$1"							# autoinst.cfg path
	declare       BOOT_OPTN="$2"							# boot option
	shift 2
	declare -r -a TGET_LINE=("$@")
	declare       FILE_PATH=""								# file path
	declare       WORK_TEXT=""								# work text
	declare -a    WORK_ARRY=()								# work array
	declare -A    WORK_AARY=()								# work associative arrays
	declare -a    FILE_VLNZ=()								# kernel path
	declare -a    FILE_IRAM=()								# initrd path (initrd)
	# -------------------------------------------------------------------------
	BOOT_OPTN="${SCRN_MODE:+"vga=${SCRN_MODE}"}${BOOT_OPTN:+" ${BOOT_OPTN}"}"
	rm -f "${AUTO_PATH}"
	FILE_VLNZ=()
	FILE_IRAM=()
	while read -r FILE_PATH
	do
		IFS= mapfile -d $'\n' -t WORK_ARRY < <(sed -ne '/^[ \t]*\(label\|Label\|LABEL\)[ \t]\+\(install\(\|gui\|start\)\|linux\|live-install\|live\|[[:print:]]*Installer\|textinstall\|graphicalinstall\)[ \t'$'\r'']*$/,/^\(\|[ \t]*\(initrd\|append\)[[:print:]]*\)['$'\r'']*$/{s/^[ \t]*//g;s/[ \t]*$//g;/^$/d;p}' "${FILE_PATH}" || true)
		if [[ -z "${WORK_ARRY[*]:-}" ]]; then
			continue
		fi
		IFS= mapfile -d $'\n' -t -O "${#FILE_VLNZ[@]}" FILE_VLNZ < <(printf "%s\n" "${WORK_ARRY[@]}" | sed -ne 's/^[ \t]*\([Kk]ernel\|[Ll]inux\|KERNEL\|LINUX\)[ \t]\+\([[:graph:]]\+\).*/\2/p'         || true)
		IFS= mapfile -d $'\n' -t -O "${#FILE_IRAM[@]}" FILE_IRAM < <(printf "%s\n" "${WORK_ARRY[@]}" | sed -ne 's/^[ \t]*\([Ii]nitrd\|INITRD\)[ \t]\+\([[:graph:]]\+\).*/\1/p'                    || true)
		IFS= mapfile -d $'\n' -t -O "${#FILE_IRAM[@]}" FILE_IRAM < <(printf "%s\n" "${WORK_ARRY[@]}" | sed -ne 's/^[ \t]*\([Aa]ppend\|APPEND\)[ \t]\+[[:print:]]*initrd=\([[:graph:]]\+\).*/\2/p' || true)
		case "${FILE_PATH}" in
			*-mini-*)
				for I in "${!FILE_IRAM[@]}"
				do
					if [[ "${FILE_IRAM[I]%/*}" = "${FILE_IRAM[I]}" ]]; then
						FILE_IRAM[I]="${MINI_IRAM}"
					else
						FILE_IRAM[I]="${FILE_IRAM[0]%/*}/${MINI_IRAM}"
					fi
				done
				;;
			*)	;;
		esac
	done < <(find "${AUTO_PATH%/*}/" \( -type f -o -type l \) \( -name 'isolinux.cfg' -o -name 'txt.cfg' -o -name 'gtk.cfg' -o -name 'install.cfg' -o -name 'menu.cfg' \) | sort -V || true)
	# --- sort FILE_VLNZ ------------------------------------------------------
	IFS= mapfile -d $'\n' -t FILE_VLNZ < <(printf "%s\n" "${FILE_VLNZ[@]}" | sort -Vu -t $'\n' || true)
	WORK_AARY=()
	for I in "${!FILE_VLNZ[@]}"
	do
		WORK_TEXT="${FILE_VLNZ[I]%/*}"
		WORK_TEXT="${WORK_TEXT//\//_}"
		WORK_TEXT="${WORK_TEXT//\./_}"
		WORK_AARY+=(["${WORK_TEXT:-"_"}"]="${FILE_VLNZ[I]:-}")
	done
	FILE_VLNZ=()
	for WORK_TEXT in $(printf "%s\n" "${!WORK_AARY[@]}" | sort -Vu)
	do
		FILE_VLNZ+=("${WORK_AARY["${WORK_TEXT}"]}")
	done
	# --- sort FILE_IRAM ------------------------------------------------------
	IFS= mapfile -d $'\n' -t FILE_IRAM < <(printf "%s\n" "${FILE_IRAM[@]}" | sort -Vu -t $'\n' || true)
	WORK_AARY=()
	for I in "${!FILE_IRAM[@]}"
	do
		WORK_TEXT="${FILE_IRAM[I]%/*}"
		WORK_TEXT="${WORK_TEXT//\//_}"
		WORK_TEXT="${WORK_TEXT//\./_}"
		WORK_AARY+=(["${WORK_TEXT:-"_"}"]="${FILE_IRAM[I]:-}")
	done
	FILE_IRAM=()
	for WORK_TEXT in $(printf "%s\n" "${!WORK_AARY[@]}" | sort -Vu)
	do
		FILE_IRAM+=("${WORK_AARY["${WORK_TEXT}"]}")
	done
	# --- create autoinst.cfg ---------------------------------------------
	for I in "${!FILE_IRAM[@]}"
	do
		funcPrintf "%20.20s: %s" "create" "menu entry ${I}: [${FILE_IRAM[I]:-}][${FILE_VLNZ[I]:-}]"
		if [[ ! -e "${AUTO_PATH}" ]]; then
			# --- standard installation mode ------------------------------
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${AUTO_PATH}"
				${MENU_RESO:+"menu resolution ${MENU_RESO/x/ }"}
				menu title Boot Menu: ${TGET_LINE[5]} ${TGET_LINE[11]} ${TGET_LINE[13]}
				menu tabmsg Press ENTER to boot or TAB to edit a menu entry
				menu background splash.png
				
				timeout ${MENU_TOUT}
				
				label auto_install
				 	menu label ^Automatic installation
				 	menu default
				 	kernel ${FILE_VLNZ[I]:-"${FILE_VLNZ[0]:-}"}
				 	append${FILE_IRAM[I]:+" initrd=${FILE_IRAM[I]}"}${BOOT_OPTN:+" "}${BOOT_OPTN} ---
				
_EOT_
		else
			# --- graphical installation mode -----------------------------
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${AUTO_PATH}"
				label auto_install_gui
				 	menu label ^Automatic installation of gui
				 	kernel ${FILE_VLNZ[I]:-"${FILE_VLNZ[0]:-}"}
				 	append${FILE_IRAM[I]:+" initrd=${FILE_IRAM[I]}"}${BOOT_OPTN:+" "}${BOOT_OPTN} ---
				
_EOT_
		fi
	done
}

# ----- create autoinst.cfg for grub ------------------------------------------
function funcCreate_autoinst_cfg_grub() {
	declare -r    AUTO_PATH="$1"							# autoinst.cfg path
	declare       BOOT_OPTN="$2"							# boot option
	shift 2
	declare -r -a TGET_LINE=("$@")
	declare       FILE_PATH=""								# file path
	declare       WORK_TEXT=""								# work text
	declare -a    WORK_ARRY=()								# work array
	declare -A    WORK_AARY=()								# work associative arrays
	declare -a    FILE_VLNZ=()								# kernel path
	declare -a    FILE_IRAM=()								# initrd path (initrd)
	declare -r    FILE_FONT="$(find "${WORK_IMGS}" \( -name 'font.pf2' -o -name 'unicode.pf2' \) -type f)"
	# -------------------------------------------------------------------------
	BOOT_OPTN="${SCRN_MODE:+"vga=${SCRN_MODE}"}${BOOT_OPTN:+" ${BOOT_OPTN}"}"
	rm -f "${AUTO_PATH}"
	FILE_VLNZ=()
	FILE_IRAM=()
	while read -r FILE_PATH
	do
		IFS= mapfile -d $'\n' -t WORK_ARRY < <(sed -ne '/^[ \t]*\(menuentry\|Menuentry\|MENUENTRY\)[ \t]\+.*['\''"][[:print:]]*[Ii]nstall\(\|er\)[[:print:]]*['\''"].*{/,/^}/{s/^[ \t]*//g;s/[ \t]*$//g;/^$/d;p}' "${FILE_PATH}" || true)
		if [[ -z "${WORK_ARRY[*]:-}" ]]; then
			continue
		fi
		IFS= mapfile -d $'\n' -t -O "${#FILE_VLNZ[@]}" FILE_VLNZ < <(printf "%s\n" "${WORK_ARRY[@]}" | sed -ne 's%^[ \t]*\(linux\(\|efi\)\)[ \t]\+\([[:graph:]]*/\(vmlinuz\|linux\)\)[ \t]*.*$%\3%p'  || true)
		IFS= mapfile -d $'\n' -t -O "${#FILE_IRAM[@]}" FILE_IRAM < <(printf "%s\n" "${WORK_ARRY[@]}" | sed -ne 's%^[ \t]*\(initrd\(\|efi\)\)[ \t]\+\([[:graph:]]*/\(initrd.*\)\)[ \t]*.*$%\3%p' || true)
		case "${FILE_PATH}" in
			*-mini-*)
				for I in "${!FILE_IRAM[@]}"
				do
					if [[ "${FILE_IRAM[I]%/*}" = "${FILE_IRAM[I]}" ]]; then
						FILE_IRAM[I]="${MINI_IRAM}"
					else
						FILE_IRAM[I]="${FILE_IRAM[0]%/*}/${MINI_IRAM}"
					fi
				done
				;;
			*)	;;
		esac
	done < <(find "${AUTO_PATH%/*}/" \( -type f -o -type l \) \( -name 'grub.cfg' -o -name 'install.cfg' \) | sort -V || true)
	IFS= mapfile -d $'\n' -t FILE_VLNZ < <(printf "%s\n" "${FILE_VLNZ[@]}" | sort -Vu -t $'\n' || true)
	WORK_AARY=()
	for I in "${!FILE_VLNZ[@]}"
	do
		WORK_TEXT="${FILE_VLNZ[I]%/*}"
		WORK_TEXT="${WORK_TEXT//\//_}"
		WORK_TEXT="${WORK_TEXT//\./_}"
		WORK_AARY+=(["${WORK_TEXT:-"_"}"]="${FILE_VLNZ[I]:-}")
	done
	FILE_VLNZ=()
	for WORK_TEXT in $(printf "%s\n" "${!WORK_AARY[@]}" | sort -Vu)
	do
		FILE_VLNZ+=("${WORK_AARY["${WORK_TEXT}"]}")
	done
	IFS= mapfile -d $'\n' -t FILE_IRAM < <(printf "%s\n" "${FILE_IRAM[@]}" | sort -Vu -t $'\n' || true)
	WORK_AARY=()
	for I in "${!FILE_IRAM[@]}"
	do
		WORK_TEXT="${FILE_IRAM[I]%/*}"
		WORK_TEXT="${WORK_TEXT//\//_}"
		WORK_TEXT="${WORK_TEXT//\./_}"
		WORK_AARY+=(["${WORK_TEXT:-"_"}"]="${FILE_IRAM[I]:-}")
	done
	FILE_IRAM=()
	for WORK_TEXT in $(printf "%s\n" "${!WORK_AARY[@]}" | sort -Vu)
	do
		FILE_IRAM+=("${WORK_AARY["${WORK_TEXT}"]}")
	done
	# --- create autoinst.cfg ---------------------------------------------
	for I in "${!FILE_IRAM[@]}"
	do
		funcPrintf "%20.20s: %s" "create" "menu entry ${I}: [${FILE_IRAM[I]:-}][${FILE_VLNZ[I]:-}]"
		if [[ ! -e "${AUTO_PATH}" ]]; then
			# --- standard installation mode ------------------------------
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${AUTO_PATH}"
				if [ -e ${FILE_FONT/${WORK_IMGS}/} ]; then
				 	font=${FILE_FONT/${WORK_IMGS}/}
				elif [ x\$feature_default_font_path = xy ]; then
				 	font=unicode
				fi
				loadfont \$font
				insmod gfxterm
				insmod png
				insmod all_video
				insmod vga
				terminal_output gfxterm
				
				set gfxmode=${MENU_RESO:+"${MENU_RESO}x${MENU_DPTH},"}auto
				set default=0
				set timeout=${MENU_TOUT::-1}
				set timeout_style=menu
				set theme=${DIRS_MENU/${WORK_IMGS}/}/theme.txt
				export theme
				
				menuentry 'Automatic installation' {
				 	set gfxpayload=keep
				 	set background_color=black
				 	echo 'Loading kernel ...'
				 	linux  ${FILE_VLNZ[I]:-"${FILE_VLNZ[0]:-}"}${BOOT_OPTN:+" ${BOOT_OPTN}"} ---
				 	echo 'Loading initial ramdisk ...'
				 	initrd ${FILE_IRAM[I]}
				}
				
_EOT_
		elif [[ "${FILE_IRAM[I]}" =~ /gtk/ ]]; then
			# --- graphical installation mode -----------------------------
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${AUTO_PATH}"
				menuentry 'Automatic installation of gui' {
				 	set gfxpayload=keep
				 	set background_color=black
				 	echo 'Loading kernel ...'
				 	linux  ${FILE_VLNZ[I]:-"${FILE_VLNZ[0]:-}"}${BOOT_OPTN:+" ${BOOT_OPTN}"} ---
				 	echo 'Loading initial ramdisk ...'
				 	initrd ${FILE_IRAM[I]}
				}
				
_EOT_
		fi
	done
}

# ----- create theme.txt ------------------------------------------------------
# https://www.gnu.org/software/grub/manual/grub/html_node/Theme-file-format.html
function funcCreate_theme_txt() {
	declare -r    WORK_IMGS="$1"							# cd-rom image working directory
	declare -r    IMGS_NAME="splash.png"					# desktop image file name
	declare -a    IMGS_FILE=()								# desktop image file path
	declare       IMGS_PATH=""
	declare -r    DIRS_MENU="$2"							# configuration file directory
	declare -r    CONF_FILE="${DIRS_MENU}/theme.txt"		# configuration file path
	declare       CONF_WORK=""
	declare -i    I=0

	funcPrintf "%20.20s: %s" "create" "${CONF_FILE##*/}"
	rm -f "${CONF_FILE}"
	# shellcheck disable=SC2312
	while read -r CONF_WORK
	do
		# shellcheck disable=SC2312
		mapfile -t IMGS_FILE < <(sed -ne '/'"${IMGS_NAME}"'/ s/^.*[ \t]\+\([[:graph:]]*\/*'"${IMGS_NAME}"'\).*$/\1/p' "${CONF_WORK}")
		if [[ -z "${IMGS_FILE[*]}" ]]; then
			# shellcheck disable=SC2312
			mapfile -t IMGS_FILE < <(find "${WORK_IMGS}" \( -name "${IMGS_NAME}" -o -name 'back.jpg' \))
			if [[ -z "${IMGS_FILE[*]}" ]]; then
				IMGS_FILE=("${DIRS_MENU}/${IMGS_NAME}")
				pushd "${DIRS_MENU}" > /dev/null
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | xxd -r -p | tar -xz
						1f8b0800000000000003edcea16ec25014c6f103848490740a0caa0eb7b4
						70dbea9112a881652161920ac2c420844282243882e4057802241e1e02b1
						279899c64cec560d43a64843f6ff9973cf77aef8a2f17b18bd3d8e4703b9
						194b73958aa7ed39d6e58c553c4b89ad1ce53a55d776756e5794aa8a69dd
						aed2af59340d27a629c3309af627d7fffd75bf53abe756c3c897f2fa6904
						4dff4524638aa45f73699d140bc5b248761df84f9df9c7d72165e8f0b83d
						b7870fde36d1da00f0bf2cba99ef8da44efbe367bc06f596bfabf59649d7
						020000000000000000000000c9fa0111c9f07200280000
_EOT_
				popd > /dev/null
			fi
#			for ((I=0; I<"${#IMGS_FILE[@]}"; I++))
			for I in "${!IMGS_FILE[@]}"
			do
				IMGS_FILE[I]="${IMGS_FILE[I]/${WORK_IMGS}/}"
			done
		fi
#		for ((I=0; I<"${#IMGS_FILE[@]}"; I++))
		for I in "${!IMGS_FILE[@]}"
		do
			IMGS_PATH="${WORK_IMGS}/${IMGS_FILE[I]#/}"
			# shellcheck disable=SC2312
			if [[ -e "${IMGS_PATH}" ]] \
			&& { { [[ "${IMGS_PATH##*.}" = "png" ]] && [[ "$(file "${IMGS_PATH}" | awk '{sub("-bit.*", "", $8 ); print  $8;}')" -ge 8 ]]; } \
			||   { [[ "${IMGS_PATH##*.}" = "jpg" ]] && [[ "$(file "${IMGS_PATH}" | awk '{sub(",.*",    "", $17); print $17;}')" -ge 8 ]]; } }; then
				# shellcheck disable=SC2128
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${CONF_FILE}"
					desktop-image: "${IMGS_FILE[I]}"
_EOT_
				break 2
			fi
		done
	done < <(find "${DIRS_MENU}" -name '*.cfg' -type f)
	# shellcheck disable=SC2128
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${CONF_FILE}"
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		title-text: "Boot Menu: ${TGET_LINE[5]} ${TGET_LINE[11]} ${TGET_LINE[13]}"
		message-font: "Unifont Regular 16"
		terminal-font: "Unifont Regular 16"
		terminal-border: "0"
		
		#help bar at the bottom
		+ label {
		 	top = 100%-50
		 	left = 0
		 	width = 100%
		 	height = 20
		 	text = "@KEYMAP_SHORT@"
		 	align = "center"
		 	color = "#ffffff"
		 	font = "Unifont Regular 16"
		}
		
		#boot menu
		+ boot_menu {
		 	left = 10%
		 	width = 80%
		 	top = 52%
		 	height = 48%-80
		 	item_color = "#a8a8a8"
		 	item_font = "Unifont Regular 16"
		 	selected_item_color= "#ffffff"
		 	selected_item_font = "Unifont Regular 16"
		 	item_height = 16
		 	item_padding = 0
		 	item_spacing = 4
		 	icon_width = 0
		 	icon_heigh = 0
		 	item_icon_space = 0
		}
		
		#progress bar
		+ progress_bar {
		 	id = "__timeout__"
		 	left = 15%
		 	top = 100%-80
		 	height = 16
		 	width = 70%
		 	font = "Unifont Regular 16"
		 	text_color = "#000000"
		 	fg_color = "#ffffff"
		 	bg_color = "#a8a8a8"
		 	border_color = "#ffffff"
		 	text = "@TIMEOUT_NOTIFICATION_LONG@"
		}
_EOT_
}

# ----- create syslinux.cfg ---------------------------------------------------
function funcCreate_syslinux_cfg() {
	declare -r    BOOT_OPTN="$1"
	shift
	declare -r -a TGET_LINE=("$@")
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -a    WORK_ARRY=()
#	declare -r    AUTO_INST="autoinst.cfg"
	declare -i    AUTO_FLAG=0
	declare       FILE_MENU=""			# syslinux or isolinux path
	declare       DIRS_MENU=""			# configuration file directory
	declare       FILE_CONF=""			# configuration file path
	declare       INSR_STRS=""			# string to insert
#	declare       FILE_IRAM=""			# initrd path
#	declare       FILE_VLNZ=""			# kernel path
	funcPrintf "%20.20s: %s" "edit" "add ${AUTO_INST} to syslinux.cfg"
	# shellcheck disable=SC2312
	while read -r FILE_MENU
	do
		DIRS_MENU="${FILE_MENU%/*}"
		AUTO_FLAG=0
		# --- editing the configuration file ----------------------------------
		for FILE_CONF in "${DIRS_MENU}/"*.cfg
		do
			# --- comment out "timeout","menu default","ontimeout","menu tabmsg" ---
			set +e
			read -r -a WORK_ARRY < <(                                                   \
				sed -ne '/^[ \t]*timeout[ \t]\+[0-9]\+[^[:graph:]]*$/p'                 \
				    -ne '/^[ \t]*prompt[ \t]\+[0-9]\+[^[:graph:]]*$/p'                  \
				    -ne '/^[ \t]*menu[ \t]\+default[^[:graph:]]*$/p'                    \
				    -ne '/^[ \t]*ontimeout[ \t]\+.*[^[:graph:]]*$/p'                    \
				    -ne '/^[ \t]*menu[ \t]\+autoboot[ \t]\+.*[^[:graph:]]*$/p'          \
				    -ne '/^[ \t]*menu[ \t]\+tabmsg[ \t]\+.*[^[:graph:]]*$/p'            \
				    -ne '/^[ \t]*menu[ \t]\+resolution[ \t]\+.*[^[:graph:]]*$/p'        \
				    -e  '/^[ \t]*default[ \t]\t/ {' -ne '/.*\.c32/!p}'                  \
				    "${FILE_CONF}"
			)
			set -e
			if [[ -n "${WORK_ARRY[*]}" ]]; then
				sed -i "${FILE_CONF}"                                                   \
				    -e '/^[ \t]*timeout[ \t]\+[0-9]\+[^[:graph:]]*$/          s/^/#/g'  \
				    -e '/^[ \t]*prompt[ \t]\+[0-9]\+[^[:graph:]]*$/           s/^/#/g'  \
				    -e '/^[ \t]*menu[ \t]\+default[^[:graph:]]*$/             s/^/#/g'  \
				    -e '/^[ \t]*ontimeout[ \t]\+.*[^[:graph:]]*$/             s/^/#/g'  \
				    -e '/^[ \t]*menu[ \t]\+autoboot[ \t]\+.*[^[:graph:]]*$/   s/^/#/g'  \
				    -e '/^[ \t]*menu[ \t]\+tabmsg[ \t]\+.*[^[:graph:]]*$/     s/^/#/g'  \
				    -e '/^[ \t]*menu[ \t]\+resolution[ \t]\+.*[^[:graph:]]*$/ s/^/#/g'  \
				    -e '/^[ \t]*default[ \t]\t/ {' -e '/.*\.c32/!             s/^/#/g}'
			fi
			# --- comment out "default" ---------------------------------------
			set +e
			read -r -a WORK_ARRY < <(                                                   \
				sed -e  '/^label[ \t]\+.*/,/\(^[ \t]*$\|^label[ \t]\+\)/ {'             \
				    -ne '/^[ \t]*default[ \t]\+[[:graph:]]\+/p}'                        \
				    "${FILE_CONF}"
			)
			set -e
			if [[ -n "${WORK_ARRY[*]}" ]]; then
				sed -i "${FILE_CONF}"                                                   \
				    -e '/^label[ \t]\+.*/,/\(^[ \t]*$\|^label[ \t]\+\)/ {'              \
				    -e '/^[ \t]*default[ \t]\+[[:graph:]]\+/                  s/^/#/g}'
			fi
			# --- insert "autoinst.cfg" ---------------------------------------
			set +e
			read -r -a WORK_ARRY < <(                                   \
				sed -ne '/^include[ \t]\+.*stdmenu.cfg[^[:graph:]]*$/p' \
				    "${FILE_CONF}"
			)
			set -e
			if [[ -n "${WORK_ARRY[*]}" ]]; then
				AUTO_FLAG=1
				INSR_STRS="$(sed -ne '/^include[ \t]\+[^ \t]*stdmenu.cfg[^[:graph:]]*$/p' "${FILE_CONF}")"
				sed -i "${FILE_CONF}"                                                                                      \
				    -e '/^\(include[ \t]\+\)[^ \t]*stdmenu.cfg[^[:graph:]]*$/ a '"${INSR_STRS/stdmenu.cfg/${AUTO_INST}}"''
			elif [[ "${FILE_CONF##*/}" = "isolinux.cfg" ]]; then
				AUTO_FLAG=1
				sed -i "${FILE_CONF}"                        \
				    -e '0,/label/ {'                         \
				    -e '/label/i include '"${AUTO_INST}"'\n' \
				    -e '}'
			fi
		done
		if [[ "${AUTO_FLAG}" -ne 0 ]]; then
			funcCreate_autoinst_cfg_syslinux "${DIRS_MENU}/${AUTO_INST}" "${BOOT_OPTN}" "${TGET_LINE[@]}"
		fi
	done < <(find "${WORK_IMGS}" \( -name 'syslinux.cfg' -o -name 'isolinux.cfg' \) -type f)
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	while read -r CONF_WORK
#	do
#		funcCreate_gfxboot_cfg "${WORK_IMGS}" "${CONF_WORK%/*}"
##	done < <(find "${WORK_IMGS}" -name 'gfxboot.c32' -type f)
}

# ----- create grub.cfg -------------------------------------------------------
function funcCreate_grub_cfg() {
	declare -r    BOOT_OPTN="$1"
	shift
	declare -r -a TGET_LINE=("$@")
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -a    WORK_ARRY=()
#	declare -r    AUTO_INST="autoinst.cfg"
	declare       FILE_MENU=""			# syslinux or isolinux path
	declare       DIRS_MENU=""			# configuration file directory
	declare       FILE_CONF=""			# configuration file path
#	declare       INSR_STRS=""			# string to insert
#	declare       FILE_IRAM=""			# initrd path
#	declare       FILE_VLNZ=""			# kernel path
	funcPrintf "%20.20s: %s" "edit" "add ${AUTO_INST} to grub.cfg"
	# shellcheck disable=SC2312
	while read -r FILE_MENU
	do
		# shellcheck disable=SC2312
		if [[ -z "$(sed -ne '/^menuentry/p' "${FILE_MENU}")" ]]; then
			continue
		fi
		DIRS_MENU="${FILE_MENU%/*}"
		# --- comment out "timeout" and "menu default" --------------------
		sed -i "${FILE_MENU}"                        \
		    -e '/^[ \t]*set[ \t]\+default=/ s/^/#/g' \
		    -e '/^[ \t]*set[ \t]\+timeout=/ s/^/#/g' \
		    -e '/^[ \t]*set[ \t]\+gfxmode=/ s/^/#/g' \
		    -e '/^[ \t]*set[ \t]\+theme=/   s/^/#/g'
		# --- insert "autoinst.cfg" ---------------------------------------
		sed -i "${FILE_MENU}"                                                       \
		    -e '0,/^menuentry/ {'                                                   \
		    -e '/^menuentry/i source '"${DIRS_MENU/${WORK_IMGS}/}/${AUTO_INST}"'\n' \
		    -e '}'
		funcCreate_autoinst_cfg_grub "${DIRS_MENU}/${AUTO_INST}" "${BOOT_OPTN}" "${TGET_LINE[@]}"
		funcCreate_theme_txt "${WORK_IMGS}" "${DIRS_MENU}"
	done < <(find "${WORK_IMGS}" -name 'grub.cfg' -type f)
}

# ----- create remaster preseed -----------------------------------------------
function funcCreate_remaster_preseed() {
	declare -r -a TGET_LINE=("$@")
	declare       BOOT_OPTN=""
	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -r    WORK_RAMS="${WORK_DIRS}/ram"
	declare -r    WORK_CONF="${WORK_IMGS}/preseed"
	declare       DIRS_IRAM=""
	funcPrintf "%20.20s: %s" "create" "boot options for preseed"
	# --- boot option ---------------------------------------------------------
	case "${TGET_LINE[1]}" in
		ubuntu-desktop-* | \
		ubuntu-legacy-*  ) BOOT_OPTN="automatic-ubiquity noprompt ${BOOT_OPTN}";;
		*-mini-*         ) BOOT_OPTN="auto=true";;
		*                ) BOOT_OPTN="auto=true preseed/file=/cdrom/${TGET_LINE[9]}";;
	esac
	case "${TGET_LINE[1]}" in
		ubuntu-*         ) BOOT_OPTN+="${BOOT_OPTN:+" "}netcfg/target_network_config=NetworkManager";;
		*                ) ;;
	esac
	BOOT_OPTN+="${BOOT_OPTN:+" "}netcfg/disable_autoconfig=true"
	BOOT_OPTN+="${BOOT_OPTN:+" "}netcfg/choose_interface=${ETHR_NAME}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}netcfg/get_hostname=${HOST_NAME}.${WGRP_NAME}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}netcfg/get_ipaddress=${IPV4_ADDR}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}netcfg/get_netmask=${IPV4_MASK}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}netcfg/get_gateway=${IPV4_GWAY}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}netcfg/get_nameservers=${IPV4_NSVR}"
#	BOOT_OPTN+="${BOOT_OPTN:+" "}locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	BOOT_OPTN+="${BOOT_OPTN:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp"
	BOOT_OPTN+="${BOOT_OPTN:+" "}fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	case "${TGET_LINE[1]}" in
		*-mini-*         )
			# shellcheck disable=SC2312
			while read -r FILE_IRAM
			do
				DIRS_IRAM="${WORK_RAMS}/${FILE_IRAM##*/}"
				mkdir -p "${DIRS_IRAM}"
				cp -a "${DIRS_CONF}/${TGET_LINE[9]%/*}/preseed_kill_dhcp.sh"   "${DIRS_IRAM}"
				cp -a "${DIRS_CONF}/${TGET_LINE[9]%/*}/preseed_late_command.sh" "${DIRS_IRAM}"
				cp -a "${DIRS_CONF}/${TGET_LINE[9]%_*}"*.cfg                   "${DIRS_IRAM}"
				ln -s "${TGET_LINE[9]##*/}"                                    "${DIRS_IRAM}/preseed.cfg"
			done < <(find "${WORK_IMGS}" -name 'initrd*' -type f)
			;;
		debian-*         | \
		ubuntu-server-*  )
			mkdir -p "${WORK_CONF}"
			cp -a "${DIRS_CONF}/${TGET_LINE[9]%/*}/preseed_kill_dhcp.sh"   "${WORK_CONF}"
			cp -a "${DIRS_CONF}/${TGET_LINE[9]%/*}/preseed_late_command.sh" "${WORK_CONF}"
			cp -a "${DIRS_CONF}/${TGET_LINE[9]%_*}"*.cfg                   "${WORK_CONF}"
			;;
		ubuntu-live-*    ) ;;
		ubuntu-desktop-* | \
		ubuntu-legacy-*  )
			mkdir -p "${WORK_CONF}"
			cp -a "${DIRS_CONF}/${TGET_LINE[9]%/*}/preseed_kill_dhcp.sh"   "${WORK_CONF}"
			cp -a "${DIRS_CONF}/${TGET_LINE[9]%/*}/preseed_late_command.sh" "${WORK_CONF}"
			cp -a "${DIRS_CONF}/${TGET_LINE[9]%_*}"*.cfg                   "${WORK_CONF}"
			;;
		*                ) ;;
	esac
}

# ----- create remaster nocloud -----------------------------------------------
function funcCreate_remaster_nocloud() {
	declare -r -a TGET_LINE=("$@")
	declare       BOOT_OPTN=""
	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -r    WORK_CONF="${WORK_IMGS}/${TGET_LINE[9]%/*}"
	funcPrintf "%20.20s: %s" "create" "boot options for nocloud"
	# --- boot option ---------------------------------------------------------
	case "${TGET_LINE[1]}" in
		ubuntu-live-18.*      ) BOOT_OPTN="boot=casper";;
		*                     ) BOOT_OPTN=""           ;;
	esac
	BOOT_OPTN+="${BOOT_OPTN:+" "}automatic-ubiquity noprompt autoinstall ds=nocloud\\;s=/cdrom/${TGET_LINE[9]}"
	case "${TGET_LINE[1]}" in
		ubuntu-live-18.04)
			BOOT_OPTN+="${BOOT_OPTN:+" "}ip=${ETHR_NAME},${IPV4_ADDR},${IPV4_MASK},${IPV4_GWAY} hostname=${HOST_NAME}.${WGRP_NAME}"
			;;
		*                )
			BOOT_OPTN+="${BOOT_OPTN:+" "}ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}::${ETHR_NAME}:static:${IPV4_NSVR} hostname=${HOST_NAME}.${WGRP_NAME}"
#			BOOT_OPTN+="${BOOT_OPTN:+" "}ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:${HOST_NAME}.${WGRP_NAME}:${ETHR_NAME}:static:${IPV4_NSVR}"
			;;
	esac
#	BOOT_OPTN+="${BOOT_OPTN:+" "}debian-installer/language=ja keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
#	BOOT_OPTN+="${BOOT_OPTN:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	BOOT_OPTN+="${BOOT_OPTN:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	BOOT_OPTN+="${BOOT_OPTN:+" "}fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${BOOT_OPTN## }" "${TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${BOOT_OPTN## }" "${TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	mkdir -p "${WORK_CONF}"
	cp -a "${DIRS_CONF}/${TGET_LINE[9]%/*}/nocloud-late-commands.sh"         "${WORK_CONF}"
	cp -a "${DIRS_CONF}/${TGET_LINE[9]%%_*}_"{server,desktop}{,_old,_oldold} "${WORK_CONF}"
	chmod ugo-x "${WORK_CONF}"/*/*
}

# ----- create remaster kickstart ---------------------------------------------
function funcCreate_remaster_kickstart() {
	declare -r -a TGET_LINE=("$@")
	declare       BOOT_OPTN=""
	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -r    WORK_CONF="${WORK_IMGS}/kickstart"
	funcPrintf "%20.20s: %s" "create" "boot options for kickstart"
	# --- boot option ---------------------------------------------------------
	BOOT_OPTN="inst.ks=hd:sr0:/${TGET_LINE[9]}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:${HOST_NAME}.${WGRP_NAME}:${ETHR_NAME}:none,auto6 nameserver=${IPV4_NSVR}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	BOOT_OPTN+="${BOOT_OPTN:+" "}fsck.mode=skip"
	BOOT_OPTN+="${BOOT_OPTN:+" "}inst.stage2=hd:LABEL=${TGET_LINE[15]}"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	mkdir -p "${WORK_CONF}"
	cp -a "${DIRS_CONF}/${TGET_LINE[9]%_*}"*.cfg "${WORK_CONF}"
}

# ----- create remaster autoyast ----------------------------------------------
function funcCreate_remaster_autoyast() {
	declare -r -a TGET_LINE=("$@")
	declare       BOOT_OPTN=""
	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -r    WORK_CONF="${WORK_IMGS}/autoyast"
	declare       WORK_ETHR="${ETHR_NAME}"
	funcPrintf "%20.20s: %s" "create" "boot options for autoyast"
	case "${TGET_LINE[1]}" in
		opensuse-*-15* ) WORK_ETHR="eth0";;
		*              ) ;;
	esac
	# --- boot option ---------------------------------------------------------
	BOOT_OPTN="autoyast=cd:/${TGET_LINE[9]}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}hostname=${HOST_NAME}.${WGRP_NAME} ifcfg=${WORK_ETHR}=${IPV4_ADDR}/${IPV4_CIDR},${IPV4_GWAY},${IPV4_NSVR},${WGRP_NAME}"
	BOOT_OPTN+="${BOOT_OPTN:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	BOOT_OPTN+="${BOOT_OPTN:+" "}fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${BOOT_OPTN}" "${TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	mkdir -p "${WORK_CONF}"
	cp -a "${DIRS_CONF}/${TGET_LINE[9]%_*}"*.xml "${WORK_CONF}"
}

# ----- create remaster iso file ----------------------------------------------
function funcCreate_remaster_iso_file() {
	declare -r -a TGET_LINE=("$@")
	# shellcheck disable=SC2001
	declare -r    DIRS_SECT="${TGET_LINE[9]%%/*}"
	declare -r    FILE_NAME="${TGET_LINE[5]%.*}_${DIRS_SECT}.${TGET_LINE[5]##*.}"
	declare -r    FILE_PATH="${DIRS_RMAK}/${FILE_NAME}"
	declare -r    WORK_DIRS="${DIRS_TEMP}/${TGET_LINE[1]}"
#	declare -r    WORK_MNTP="${WORK_DIRS}/mnt"
	declare -r    WORK_IMGS="${WORK_DIRS}/img"
	declare -r    WORK_RAMS="${WORK_DIRS}/ram"
	declare       DIRS_IRAM=""
#	declare       FILE_IRAM=""
	declare       FILE_HBRD=""
	declare       FILE_BCAT=""
	declare       FILE_IBIN=""
	declare -a    DIRS_FIND=()
	declare       DIRS_BOOT=""
	declare       DIRS_UEFI=""
	declare       FILE_UEFI=""
	declare       ISOS_PATH=""
	declare -a    ISOS_INFO=()
	declare -i    ISOS_SKIP=0
	declare -i    ISOS_CONT=0
	declare -i    RET_CD=0
	# --- create initrd file --------------------------------------------------
	if [[ "${TGET_LINE[1]}" =~ -mini- ]]; then
		# shellcheck disable=SC2312
		while read -r DIRS_IRAM
		do
			funcPrintf "%20.20s: %s" "create" "remaster ${MINI_IRAM}"
#			FILE_IRAM="${WORK_IMGS}/${DIRS_IRAM/${WORK_RAMS}/}"
			pushd "${DIRS_IRAM}" > /dev/null
				find . | cpio --format=newc --create --quiet | gzip > "${WORK_IMGS}/${MINI_IRAM}"
			popd > /dev/null
		done < <(find "${WORK_RAMS}" -name 'initrd*' -type d | sort | sed -ne '/\(initrd.*\/initrd*\|\/.*netboot\/\)/!p')
	fi
	# --- create iso file -----------------------------------------------------
	funcPrintf "%20.20s: %s" "create" "remaster iso file"
	funcPrintf "%20.20s: %s" "create" "${FILE_NAME}"
	mkdir -p "${DIRS_RMAK}"
	pushd "${WORK_IMGS}" > /dev/null
		FILE_HBRD="$(find /usr/lib       -name 'isohdpfx.bin'                             -type f              || true)"
		FILE_BCAT="$(find .          \( -iname 'boot.cat'     -o -iname 'boot.catalog' \) -type f -printf "%P" || true)"
		FILE_IBIN="$(find .          \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \) -type f -printf "%P" || true)"
		DIRS_BOOT="$(find . -maxdepth 1 -iname 'boot'                                     -type d -printf "%P" || true)"
		DIRS_UEFI="$(find . -maxdepth 1 -iname 'efi'                                      -type d -printf "%P" || true)"
		if [[ -n "${DIRS_UEFI}" ]]; then
			DIRS_UEFI="$(find "${DIRS_UEFI}" -iname 'boot' -type d || true)"
		fi
		if [[ -n "${DIRS_BOOT}" ]] && [[ -n "${DIRS_UEFI}" ]]; then
			DIRS_FIND=("${DIRS_BOOT}" "${DIRS_UEFI}")
		elif [[ -n "${DIRS_BOOT}" ]]; then
			DIRS_FIND=("${DIRS_BOOT}")
		elif [[ -n "${DIRS_UEFI}" ]]; then
			DIRS_FIND=("${DIRS_UEFI}")
		else
			DIRS_FIND=(".")
		fi
		FILE_UEFI="$(find "${DIRS_FIND[@]}" -iname 'efi*.img' -type f || true)"
		if [[ -z "${FILE_UEFI}" ]]; then
			FILE_UEFI="${DIRS_UEFI/.\//}/efi.img"
			ISOS_PATH="${DIRS_ISOS}/${TGET_LINE[5]}"
			ISOS_INFO=("$(fdisk -l "${ISOS_PATH}")")
			ISOS_SKIP="$(echo "${ISOS_INFO[@]}" | awk '/EFI/ {print $2;}')"
			ISOS_CONT="$(echo "${ISOS_INFO[@]}" | awk '/EFI/ {print $4;}')"
			dd if="${ISOS_PATH}" of="${FILE_UEFI}" bs=512 skip="${ISOS_SKIP}" count="${ISOS_CONT}" status=none
		fi
		chmod ugo-w -R .
		rm -f md5sum.txt
		find . ! -name 'md5sum.txt' -type f -exec md5sum {} \; > md5sum.txt
		chmod ugo-w md5sum.txt
		ionice -c "${IONICE_CLAS}" xorriso -as mkisofs \
		    -quiet \
		    -volid "${TGET_LINE[15]//%20/ }" \
		    -eltorito-boot "${FILE_IBIN}" \
		    -eltorito-catalog "${FILE_BCAT:-boot.catalog}" \
		    -no-emul-boot -boot-load-size 4 -boot-info-table \
		    -isohybrid-mbr "${FILE_HBRD}" \
		    -eltorito-alt-boot -e "${FILE_UEFI}" \
		    -no-emul-boot -isohybrid-gpt-basdat \
		    -output "${WORK_DIRS}/${FILE_PATH##*/}" \
		    . > /dev/null 2>&1
	popd > /dev/null
	# --- copy iso image ------------------------------------------------------
	ionice -c "${IONICE_CLAS}" cp -a "${WORK_DIRS}/${FILE_PATH##*/}" "${FILE_PATH%/*}"
	# --- remove directory ----------------------------------------------------
	rm -rf "${WORK_DIRS:?}"
}

# ----- create remaster -------------------------------------------------------
function funcCreate_remaster() {
#	declare -r    OLD_IFS="${IFS}"
#	declare -r    MSGS_TITL="create target list"
#	declare -r -a DATA_ARRY=("$@")
	declare -a    TGET_LINE=()
#	declare -i    RET_CD=0
	declare -i    I=0
#	declare -i    J=0
#	declare       FILE_VLID=""
	# -------------------------------------------------------------------------
	for I in "${!TGET_LIST[@]}"
	do
		WORK_TEXT="$(echo -n "${TGET_LIST[I]}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
		IFS=$'\n' mapfile -d ' ' -t TGET_LINE < <(echo -n "${WORK_TEXT}")
		if [[ "${TGET_LINE[0]}" != "o" ]]; then
			continue
		fi
		funcPrintf "%-3.3s%17.17s: %s %s" "===" "start" "${TGET_LINE[5]}" "${TEXT_GAP2}"
		# --- download --------------------------------------------------------
		funcCreate_remaster_download "${TGET_LINE[@]}"
#		if [[ -n "${FILE_VLID}" ]]; then
#			TGET_LINE[14]="${FILE_VLID// /%20}"
#			TGET_LIST[I-1]="${TGET_LINE[*]}"
#		fi
		# --- skip check ------------------------------------------------------
		if [[ ! -e "${TGET_LINE[4]}/${TGET_LINE[5]}" ]]; then
			funcPrintf "%-3.3s${TXT_RESET}${TXT_BYELLOW}%17.17s: %s${TXT_RESET} %s" "===" "skip" "${TGET_LINE[5]}" "${TEXT_GAP2}"
			continue
		fi
		# --- copy iso contents to hdd ----------------------------------------
		funcCreate_copy_iso2hdd "${TGET_LINE[@]}"
		# --- rewriting syslinux.cfg and grub.cfg -----------------------------
		case "${TGET_LINE[1]%%-*}" in
			debian       | \
			ubuntu       ) 
				case "${TGET_LINE[9]%%/*}" in
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
		funcPrintf "%-3.3s%17.17s: %s %s" "===" "complete" "${TGET_LINE[5]}" "${TEXT_GAP2}"
	done
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
			parm )						# ===== print parameter ===============
				funcDbg_parameter
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
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
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
	declare -r -a COMD_ENUM=("mini" "net" "dvd" "live")
	declare -a    COMD_LIST=()
	declare -a    DATA_ARRY=()
	declare       WORK_PARM=""
	declare       WORK_ENUM=""
	declare -a    WORK_ARRY=()
	declare       WORK_TEXT=""
	declare       MENU_HEAD=""
	declare       MENU_TAIL=""
	declare -i    I=0
	declare -i    J=0
	# -------------------------------------------------------------------------
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	if [[ "${1:-}" = "all" ]] || [[ "${1:-}" = "a" ]]; then
		COMD_LIST=()
		for I in "${!COMD_ENUM[@]}"
		do
			COMD_LIST+=("${COMD_ENUM[I]}" "all")
		done
	elif [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("${COMD_ENUM[@]}" "$@")
	fi
	if [[ -n "${COMD_LIST[*]}" ]]; then
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
		unset DATA_ARRY
		DATA_ARRY=()
		case "${1:-}" in
			mini ) shift; DATA_ARRY=("${DATA_LIST_MINI[@]}");;
			net  ) shift; DATA_ARRY=("${DATA_LIST_NET[@]}") ;;
			dvd  ) shift; DATA_ARRY=("${DATA_LIST_DVD[@]}") ;;
			live ) shift; DATA_ARRY=("${DATA_LIST_INST[@]}");;
#			live ) shift; DATA_ARRY=("${DATA_LIST_LIVE[@]}");;
#			tool ) shift; DATA_ARRY=("${DATA_LIST_TOOL[@]}");;
#			comd ) shift; DATA_ARRY=("${DATA_LIST_SCMD[@]}");;
#			cstm ) shift; DATA_ARRY=("${DATA_LIST_CSTM[@]}");;
#			scmd ) shift; DATA_ARRY=("${DATA_LIST_SCMD[@]}");;
			-*   ) break;;
			*    ) ;;
		esac
		if [[ "${#DATA_ARRY[@]}" -le 0 ]]; then
			continue
		fi
		unset WORK_ARRY
		WORK_ARRY=()
		while [[ -n "${1:-}" ]]
		do
			case "${1:-}" in
				a | all )
					WORK_ARRY=("*")
					shift
					break
					;;
				[0-9] | [0-9][0-9] | [0-9][0-9][0-9] )		# 1..999
					WORK_ARRY+=("$1")
					shift
					;;
				* )	break;;
			esac
		done
		MENU_HEAD=""
		MENU_TAIL=""
		J=0
		for I in "${!DATA_ARRY[@]}"
		do
			WORK_TEXT="$(echo -n "${DATA_ARRY[I]}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
			IFS=$'\n' mapfile -d ' ' -t DATA_LINE < <(echo -n "${WORK_TEXT}")
			case "${DATA_LINE[0]}" in
				o)
					if [[ ! "${DATA_LINE[17]}" =~ ^http://.*$ ]] && [[ ! "${DATA_LINE[17]}" =~ ^https://.*$ ]]; then
						unset "DATA_ARRY[I]"
						continue
					fi
					((J+=1))
					WORK_TEXT="${WORK_ARRY[*]/\*/\.\*}"
					WORK_TEXT="${WORK_TEXT// /\\|}"
					if [[ -n "${WORK_TEXT:-}" ]] && [[ -z "$(echo "${J}" | sed -ne '/^\('"${WORK_TEXT}"'\)$/p' || true)" ]]; then
						DATA_LINE[0]="s"
						DATA_ARRY[I]="${DATA_LINE[*]}"
					fi
					;;
				m)
					if [[ -z "${MENU_HEAD}" ]]; then
						MENU_HEAD="${DATA_ARRY[I]}"
						unset "DATA_ARRY[I]"
					elif [[ -z "${MENU_TAIL}" ]]; then
						MENU_TAIL="${DATA_ARRY[I]}"
						unset "DATA_ARRY[I]"
					fi
					;;
				*)
					unset "DATA_ARRY[I]"
					continue
					;;
			esac
		done
		DATA_ARRY=("${DATA_ARRY[@]}")
		TGET_INDX=""
		if [[ "${WORK_ARRY[*]}" = "*" ]]; then
			TGET_INDX="{1..${#DATA_ARRY[@]}}"
			TGET_INDX="$(eval echo "${TGET_INDX}")"
		elif [[ -n "${WORK_ARRY[*]}" ]]; then
			TGET_INDX="${WORK_ARRY[*]}"
		fi
		TGET_LIST=()
		funcCreate_menu "${MENU_HEAD:-}" "${DATA_ARRY[@]}" "${MENU_TAIL:-}"
		if [[ -z "${TGET_INDX}" ]]; then
			funcCreate_target_list
		fi
		if [[ -n "${TGET_INDX}" ]]; then
			for I in "${!TGET_LIST[@]}"
			do
				WORK_TEXT="$(echo -n "${TGET_LIST[I]}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
				IFS=$'\n' mapfile -d ' ' -t DATA_LINE < <(echo -n "${WORK_TEXT}")
				case "${DATA_LINE[0]}" in
					o)
						WORK_TEXT="${TGET_INDX[*]/\*/\.\*}"
						WORK_TEXT="${WORK_TEXT// /\\|}"
						if [[ -n "${WORK_TEXT:-}" ]] && [[ -z "$(echo "${I}" | sed -ne '/^\('"${WORK_TEXT}"'\)$/p' || true)" ]]; then
							DATA_LINE[0]="s"
							TGET_LIST[I]="${DATA_LINE[*]}"
						fi
						;;
					*)
						continue
						;;
				esac
			done
			TGET_LIST=("${TGET_LIST[@]}")
			funcCreate_remaster
		fi
	done
	# -------------------------------------------------------------------------
	rm -rf "${DIRS_TEMP:?}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2034
	COMD_RETN="${COMD_LIST[*]:-}"
}

# ----- media download --------------------------------------------------------
function funcMedia_download() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call create"
	declare -n    COMD_RETN="$1"
	declare -r -a COMD_ENUM=("mini" "net" "dvd" "live")
	declare -a    COMD_LIST=()
	declare -a    DATA_ARRY=()
	declare       WORK_PARM=""
	declare       WORK_ENUM=""
	declare -i    I=0
	declare -i    J=0
#	declare       FILE_VLID=""
	# -------------------------------------------------------------------------
	funcPrintf "---- ${MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	if [[ "${1:-}" = "all" ]] || [[ "${1:-}" = "a" ]]; then
		COMD_LIST=()
#		for ((I=0; I<"${#COMD_ENUM[@]}"; I++))
		for I in "${!COMD_ENUM[@]}"
		do
			COMD_LIST+=("${COMD_ENUM[I]}" "all")
		done
	elif [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("${COMD_ENUM[@]}" "$@")
	fi
	if [[ -n "${COMD_LIST[*]}" ]]; then
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
		DATA_ARRY=()
		case "${1:-}" in
			mini ) DATA_ARRY=("${DATA_LIST_MINI[@]}");;
			net  ) DATA_ARRY=("${DATA_LIST_NET[@]}") ;;
			dvd  ) DATA_ARRY=("${DATA_LIST_DVD[@]}") ;;
			live ) DATA_ARRY=("${DATA_LIST_INST[@]}");;
#			live ) DATA_ARRY=("${DATA_LIST_LIVE[@]}");;
#			tool ) DATA_ARRY=("${DATA_LIST_TOOL[@]}");;
#			comd ) DATA_ARRY=("${DATA_LIST_SCMD[@]}");;
			-* )
				break
				;;
			* )
				;;
		esac
		if [[ "${#DATA_ARRY[@]}" -gt 0 ]]; then
#			for ((I=0, J=0; I<"${#DATA_ARRY[@]}"; I++))
			J=0
			for I in "${!DATA_ARRY[@]}"
			do
				read -r -a DATA_LINE < <(echo "${DATA_ARRY[I]}")
				if [[ "${DATA_LINE[0]}" != "o" ]] || { [[ ! "${DATA_LINE[17]}" =~ ^http://.*$ ]] && [[ ! "${DATA_LINE[17]}" =~ ^https://.*$ ]]; }; then
					continue
				fi
				J+=1
			done
			TGET_INDX=""
			case "${2:-}" in
				a | all )
					shift;
					TGET_INDX="{1..${J}}"
					;;
				*       )
					WORK_ENUM="${COMD_ENUM[*]}"
					WORK_ENUM="${WORK_ENUM// /\\|}"
					# shellcheck disable=SC2312
					if [[ -n "${2:-}" ]] && [[ -z "$(echo "${2:-}" | sed -ne '/\('"${WORK_ENUM}"'\)/p')" ]]; then
						shift
						WORK_PARM="$*"
						# shellcheck disable=SC2001
						TGET_INDX="$(echo "${WORK_PARM}" | sed -e 's/\('"${WORK_ENUM}"'\).*//g')"
					fi
					;;
			esac
			TGET_INDX="$(eval echo "${TGET_INDX}")"
			TGET_LIST=()
			funcCreate_menu "${DATA_ARRY[@]}"
			if [[ -z "${TGET_INDX}" ]]; then
				funcCreate_target_list
			fi
#			for ((I=0; I<"${#TGET_LIST[@]}"; I++))
			for I in "${!TGET_LIST[@]}"
			do
				read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
				funcPrintf "===    start: ${TGET_LINE[4]} ${TEXT_GAP2}"
				# --- download ------------------------------------------------
				funcCreate_remaster_download "${TGET_LINE[@]}"
				funcPrintf "=== complete: ${TGET_LINE[4]} ${TEXT_GAP2}"
			done
		fi
		shift
	done
	# -------------------------------------------------------------------------
	rm -rf "${DIRS_TEMP:?}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2034
	COMD_RETN="${COMD_LIST[*]:-}"
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

	readonly      TEXT_GAP1
	readonly      TEXT_GAP2

	# --- main ----------------------------------------------------------------
	start_time=$(date +%s)
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"
	funcPrintf "--- start ${TEXT_GAP1}"
	funcPrintf "--- main ${TEXT_GAP1}"
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
		for DIRS_NAME in "${DIRS_LIST[@]}"/*/mnt
		do
			set +e
			if mountpoint -q "${DIRS_NAME}"; then
				funcPrintf "unmount unnecessary temporary directories"
				if [[ "${DIRS_NAME##*/}" = "dev" ]]; then
					umount -q "${DIRS_NAME}/pts" || umount -q -lf "${DIRS_NAME}/pts"
				fi
				umount -q "${DIRS_NAME}" || umount -q -lf "${DIRS_NAME}"
			fi
			set -e
		done
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
		funcPrintf "create iso image files"
		funcPrintf "  --create [ options ] [ empty | all | id number ]"
		funcPrintf "    mini        mini.iso"
		funcPrintf "    net         netint"
		funcPrintf "    dvd         dvd image"
		funcPrintf "    live        live image"
#		funcPrintf "    tool        tool"
		funcPrintf "    empty       waiting for input"
		funcPrintf "    a | all     create all targets"
		funcPrintf "    id number   create with selected target id"
		funcPrintf "download iso image files"
		funcPrintf "  --download [ options ] [ empty | all | id number ]"
		funcPrintf "    mini        mini.iso"
		funcPrintf "    net         netint"
		funcPrintf "    dvd         dvd image"
		funcPrintf "    live        live image"
#		funcPrintf "    tool        tool"
		funcPrintf "    empty       waiting for input"
		funcPrintf "    a | all     create all targets"
		funcPrintf "    id number   create with selected target id"
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
					funcCall_create COMD_LINE "$@"
					;;
				--download )				# ==== media download =============
					funcMedia_download COMD_LINE "$@"
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
