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
	if [[ ! -e "/var/lib/apt/lists/deb.debian.org_debian_dists_${CODE_NAME:-}_InRelease"      ]] \
	&& [[ ! -e "/var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_${CODE_NAME:-}_InRelease" ]]; then
		echo "please execute apt-get update:"
		if [[ "${0:-}" = "${SUDO_COMMAND:-}" ]]; then
			echo -n "sudo "
		fi
		echo "apt-get update"
		exit 1
	fi
	# -------------------------------------------------------------------------
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
		 	if [ -e "${COMD_PARM}" ]; then
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
		 	if [ ! -e "${SEED_FILE}" ]; then
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
		 	if [ -e "${SEED_FILE}" ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	FILE_NAME="/etc/firewalld/firewalld.conf"
		 	if [ -d "${TGET_DIRS}/." ]; then
		 		FILE_NAME="${TGET_DIRS}${FILE_NAME}"
		 	fi
		 	if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ -e "${FILE_NAME}" ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ -e /lib/systemd/system/smbd.service ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ -e "${FILE_NAME}" ]; then
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
		 	if [ -e "${FILE_NAME}" ]; then
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
		#		if [ ! -e "${FILE_NAME}" ]; then
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
		 	if [ ! -e "${FILE_NAME}" ]; then
		 		echo "${PROG_NAME}: file does not exist ${FILE_NAME}"
		 		return
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	if [ ! -d "${BACK_DIRS}/system-connections/." ]; then
		 		mkdir -p "${BACK_DIRS}/system-connections"
		 	fi
		 	echo "${PROG_NAME}: ${CONF_FILE}"
		 	if [ -e "${CONF_FILE}" ]; then
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
		 		if [ -e "${FILE_NAME}" ]; then
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
		#	if [ -e "${TGET_DIRS}/etc/gdm3/custom.conf" ]; then
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
	cp -a "${DIRS_CONF}/${TGET_LINE[9]%/*}/nocloud-late-commands.sh" "${WORK_CONF}"
	cp -a "${DIRS_CONF}/${TGET_LINE[9]%%_*}_"{server,desktop}{,_old} "${WORK_CONF}"
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
