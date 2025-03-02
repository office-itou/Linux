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

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# -------------------------------------------------------------------------
	CODE_NAME="$(sed -ne '/VERSION_CODENAME/ s/^.*=//p' /etc/os-release)"
	readonly      CODE_NAME

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
		MAIN_ARHC="$(dpkg --print-architecture)"
		readonly      MAIN_ARHC
		OTHR_ARCH="$(dpkg --print-foreign-architectures)"
		readonly      OTHR_ARCH
		declare -r -a PAKG_LIST=(\
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
		PAKG_FIND="$(LANG=C apt list "${PAKG_LIST[@]}" 2> /dev/null | sed -ne '/[ \t]'"${OTHR_ARCH:-"i386"}"'[ \t]*/!{' -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g')"
		readonly      PAKG_FIND
		if [[ -n "${PAKG_FIND% *}" ]]; then
			echo "please install these:"
			if [[ "${0:-}" = "${SUDO_COMMAND:-}" ]]; then
				echo -n "sudo "
			fi
			echo "apt-get install ${PAKG_FIND% *}"
			exit 1
		fi
	fi

# *** data section ************************************************************

	# --- main server tree diagram (developed for debian) ---------------------
	#
	#	[tree --charset C -n --filesfirst -d /srv/]
	#
	#	/srv/
	#	|-- hgfs ------------------------------------------- vmware shared directory
	#	|-- http
	#	|   `-- html---------------------------------------- html contents
	#	|       |-- index.html
	#	|       |-- conf -> /srv/user/share/conf
	#	|       |-- imgs -> /srv/user/share/imgs
	#	|       |-- isos -> /srv/user/share/isos
	#	|       |-- load -> /srv/user/share/load
	#	|       `-- rmak -> /srv/user/share/rmak
	#	|-- samba ------------------------------------------ samba shared directory
	#	|   |-- cifs
	#	|   |-- data
	#	|   |   |-- adm
	#	|   |   |   |-- netlogon
	#	|   |   |   |   `-- logon.bat
	#	|   |   |   `-- profiles
	#	|   |   |-- arc
	#	|   |   |-- bak
	#	|   |   |-- pub
	#	|   |   `-- usr
	#	|   `-- dlna
	#	|       |-- movies
	#	|       |-- others
	#	|       |-- photos
	#	|       `-- sounds
	#	|-- tftp ------------------------------------------- tftp contents
	#	|   |-- autoexec.ipxe ------------------------------ ipxe script file (menu file)
	#	|   |-- boot
	#	|   |   `-- grub
	#	|   |       |-- bootnetx64.efi --------------------- bootloader (x86_64-efi)
	#	|   |       |-- grub.cfg --------------------------- menu base
	#	|   |       |-- pxelinux.0 ------------------------- bootloader (i386-pc-pxe)
	#	|   |       |-- fonts
	#	|   |       |   `-- unicode.pf2
	#	|   |       |-- i386-efi
	#	|   |       |-- i386-pc
	#	|   |       |-- locale
	#	|   |       `-- x86_64-efi
	#	|   |-- conf -> /srv/user/share/conf
	#	|   |-- imgs -> /srv/user/share/imgs
	#	|   |-- ipxe --------------------------------------- ipxe module
	#	|   |-- isos -> /srv/user/share/isos
	#	|   |-- load -> /srv/user/share/load
	#	|   |-- menu-bios
	#	|   |   |-- lpxelinux.0 ---------------------------- bootloader (i386-pc)
	#	|   |   |-- syslinux.cfg --------------------------- syslinux configuration for mbr environment
	#	|   |   |-- conf -> ../conf
	#	|   |   |-- imgs -> ../imgs
	#	|   |   |-- isos -> ../isos
	#	|   |   |-- load -> ../load
	#	|   |   |-- pxelinux.cfg
	#	|   |   |   `-- default -> ../syslinux.cfg
	#	|   |   `-- rmak -> ../rmak
	#	|   |-- menu-efi64
	#	|   |   |-- syslinux.cfg --------------------------- syslinux configuration for uefi(x86_64) environment
	#	|   |   |-- syslinux.efi --------------------------- bootloader (x86_64-efi)
	#	|   |   |-- conf -> ../conf
	#	|   |   |-- imgs -> ../imgs
	#	|   |   |-- isos -> ../isos
	#	|   |   |-- load -> ../load
	#	|   |   |-- pxelinux.cfg
	#	|   |   |   `-- default -> ../syslinux.cfg
	#	|   |   `-- rmak -> ../rmak
	#	|   `-- rmak -> /srv/user/share/rmak
	#	`-- user ------------------------------------------- user file
	#	    |-- private ------------------------------------ personal use
	#	    `-- share -------------------------------------- shared
	#	        |-- conf ----------------------------------- configuration file
	#	        |   |-- _keyring --------------------------- keyring file
	#	        |   |-- _template -------------------------- templates for various configuration files
	#	        |   |   |-- kickstart_common.cfg ----------- template for auto-installation configuration file for rhel
	#	        |   |   |-- nocloud-ubuntu-user-data ------- "                                                 for ubuntu cloud-init
	#	        |   |   |-- preseed_debian.cfg ------------- "                                                 for debian
	#	        |   |   |-- preseed_ubuntu.cfg ------------- "                                                 for ubuntu
	#	        |   |   `-- yast_opensuse.xml -------------- "                                                 for opensuse
	#	        |   |-- autoyast --------------------------- configuration files for opensuse
	#	        |   |-- kickstart -------------------------- "                   for rhel
	#	        |   |-- nocloud ---------------------------- "                   for ubuntu cloud-init
	#	        |   |-- preseed ---------------------------- "                   for debian/ubuntu preseed
	#	        |   |-- script ----------------------------- script files
	#	        |   |   |-- late_command.sh ---------------- post-installation automatic configuration script file for linux (debian/ubuntu/rhel/opensuse)
	#	        |   |   `-- live_0000-user-conf-hook.sh ---- live media script files
	#	        |   `-- windows ---------------------------- configuration files for windows
	#	        |       |-- WinREexpand.cmd ---------------- hotfix for windows 10
	#	        |       |-- WinREexpand_bios.sub ----------- "
	#	        |       |-- WinREexpand_uefi.sub ----------- "
	#	        |       |-- bypass.cmd --------------------- installation restriction bypass command for windows 11
	#	        |       |-- inst_w10.cmd ------------------- installation batch file for windows 10
	#	        |       |-- inst_w11.cmd ------------------- "                       for windows 11
	#	        |       |-- shutdown.cmd ------------------- shutdown command for winpe
	#	        |       |-- startnet.cmd ------------------- startup command for winpe
	#	        |       |-- unattend.xml ------------------- auto-installation configuration file for windows 10/11
	#	        |       `-- winpeshl.ini
	#	        |-- imgs ----------------------------------- iso file extraction destination
	#	        |-- isos ----------------------------------- iso file
	#	        |-- load ----------------------------------- load module
	#	        `-- rmak ----------------------------------- remake file
	#
	#	/etc/
	#	|-- fstab
	#	|-- hostname
	#	|-- hosts
	#	|-- nsswitch.conf
	#	|-- resolv.conf -> ../run/systemd/resolve/stub-resolv.conf
	#	|-- sudoers
	#	|-- apache2
	#	|   `-- sites-available
	#	|       `-- 999-site.conf -------------------------- virtual host configuration file for users
	#	|-- connman
	#	|   `-- main.conf
	#	|-- default
	#	|   |-- dnsmasq
	#	|   `-- grub
	#	|-- dnsmasq.d
	#	|   |-- default.conf ------------------------------- dnsmasq configuration file
	#	|   `-- pxeboot.conf ------------------------------- pxeboot configuration file
	#	|-- firewalld
	#	|   `-- zones
	#	|       `-- home_use.xml
	#	|-- samba
	#	|   `-- smb.conf ----------------------------------- samba configuration file
	#	|-- skel
	#	|   |-- .bash_history
	#	|   |-- .bashrc
	#	|   |-- .curlrc
	#	|   `-- .vimrc
	#	|-- ssh
	#	|   `-- sshd_config.d
	#	|       `-- default.conf --------------------------- ssh configuration file
	#	`-- systemd
	#	    |-- resolved.conf.d
	#	    |   `-- default.conf
	#	    |-- system
	#	    |   `-- connman.service.d
	#	    |       `-- disable_dns_proxy.conf
	#	    `-- timesyncd.conf.d
	#	        `-- local.conf
	#	

	# --- working directory name ----------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
	              DIRS_TEMP="$(mktemp -qtd "${PROG_PROC}.XXXXXX")"
	readonly      DIRS_TEMP

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

	# --- shared of user file -------------------------------------------------
	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	# --- open-vm-tools -------------------------------------------------------
	declare -r    HGFS_DIRS="${DIRS_HGFS}/workspace/Image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
	declare -r    CONF_DIRS="${DIRS_CONF}/_template"
	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	# --- directory list ------------------------------------------------------
	declare -r -a LIST_DIRS=(                                                                                           \
		"${DIRS_TOPS}"                                                                                                  \
		"${DIRS_HGFS}"                                                                                                  \
		"${DIRS_HTML}"                                                                                                  \
		"${DIRS_SAMB}"/{cifs,data/{adm/{netlogon,profiles},arc,bak,pub,usr},dlna/{movies,others,photos,sounds}}         \
		"${DIRS_TFTP}"/{boot/grub/{fonts,i386-{efi,pc},locale,x86_64-efi},ipxe,load,menu-{bios,efi64}/pxelinux.cfg}     \
		"${DIRS_USER}"                                                                                                  \
		"${DIRS_SHAR}"/{conf,imgs,isos,load,rmak}                                                                       \
		"${DIRS_CONF}"/{_keyring,_template,autoyast,kickstart,nocloud,preseed,script,windows}                           \
		"${DIRS_KEYS}"                                                                                                  \
		"${DIRS_TMPL}"                                                                                                  \
		"${DIRS_IMGS}"                                                                                                  \
		"${DIRS_ISOS}"                                                                                                  \
		"${DIRS_LOAD}"                                                                                                  \
		"${DIRS_RMAK}"                                                                                                  \
	)

	# --- symbolic link list --------------------------------------------------
	declare -r -a LIST_LINK=(                                                                                           \
		"a  ${DIRS_CONF}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_IMGS}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_ISOS}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_LOAD}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_RMAK}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_IMGS}                                    ${DIRS_TFTP}/"                                              \
		"a  ${DIRS_ISOS}                                    ${DIRS_TFTP}/"                                              \
		"a  ${DIRS_LOAD}                                    ${DIRS_TFTP}/"                                              \
		"r  ${DIRS_TFTP}/${DIRS_IMGS##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
		"r  ${DIRS_TFTP}/${DIRS_ISOS##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
		"r  ${DIRS_TFTP}/${DIRS_LOAD##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
		"r  ${DIRS_TFTP}/menu-bios/syslinux.cfg             ${DIRS_TFTP}/menu-bios/pxelinux.cfg/default"                \
		"r  ${DIRS_TFTP}/${DIRS_IMGS##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
		"r  ${DIRS_TFTP}/${DIRS_ISOS##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
		"r  ${DIRS_TFTP}/${DIRS_LOAD##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
		"r  ${DIRS_TFTP}/menu-efi64/syslinux.cfg            ${DIRS_TFTP}/menu-efi64/pxelinux.cfg/default"               \
		"a  ${HGFS_DIRS}/linux/bin/conf                     ${DIRS_CONF}"                                               \
		"a  ${HGFS_DIRS}/linux/bin/rmak                     ${DIRS_RMAK}"                                               \
	) #	0:r	1:target										2:symlink

	# --- autoinstall configuration file --------------------------------------
	declare -r    AUTO_INST="autoinst.cfg"

	# --- initial ram disk of mini.iso including preseed ----------------------
	declare -r    MINI_IRAM="initps.gz"

	# --- tftp / web server address -------------------------------------------
	              SRVR_ADDR="$(LANG=C ip -4 -oneline address show scope global | awk '{split($4,s,"/"); print s[1];}')"
	readonly      SRVR_ADDR
	declare -r    SRVR_PROT="http"							# server connection protocol (http)
#	declare -r    SRVR_PROT="tftp"							# "                          (tftp)

	# --- network parameter ---------------------------------------------------
#	declare -r    HOST_NAME="sv-${TGET_LINE[1]%%-*}"		# hostname
	declare -r    WGRP_NAME="workgroup"						# domain
	declare -r    ETHR_NAME="ens160"						# network device name
	declare -r    IPV4_ADDR="${SRVR_ADDR%.*}.1"				# IPv4 address
	declare -r    IPV4_CIDR="24"							# IPv4 cidr
	declare -r    IPV4_MASK="255.255.255.0"					# IPv4 subnetmask
	declare -r    IPV4_GWAY="${SRVR_ADDR%.*}.254"			# IPv4 gateway
	declare -r    IPV4_NSVR="${SRVR_ADDR%.*}.254"			# IPv4 nameserver

	# --- curl / wget parameter -----------------------------------------------
	declare -r -a CURL_OPTN=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -r -a WGET_OPTN=("--tries=3" "--timeout=10" "--no-verbose")

	# --- work variables ------------------------------------------------------
	declare -r    OLD_IFS="${IFS}"

	# --- set minimum display size --------------------------------------------
	declare -i    ROWS_SIZE=80
	declare -i    COLS_SIZE=25
	declare       TEXT_GAP1=""
	declare       TEXT_GAP2=""

	# --- niceness values -----------------------------------------------------
	declare -r -i NICE_VALU=19								# -20: favorable to the process
															#  19: least favorable to the process
	declare -r -i IONICE_CLAS=3								#   1: Realtime
															#   2: Best-effort
															#   3: Idle
#	declare -r -i IONICE_VALU=7								#   0: favorable to the process
															#   7: least favorable to the process

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

	# === system ==============================================================

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
	declare -r -a DATA_LIST_MINI=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            \
		"m  menu-entry                      Auto%20install%20mini.iso               -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-mini-10                  Debian%2010                             debian              ${DIRS_ISOS}    mini-buster-amd64.iso                           .                                       initrd.gz                   linux                   preseed/ps_debian_server_oldold.cfg     ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/buster/main/installer-amd64/current/images/netboot/mini.iso                                                " \
		"o  debian-mini-11                  Debian%2011                             debian              ${DIRS_ISOS}    mini-bullseye-amd64.iso                         .                                       initrd.gz                   linux                   preseed/ps_debian_server_old.cfg        ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso                                              " \
		"o  debian-mini-12                  Debian%2012                             debian              ${DIRS_ISOS}    mini-bookworm-amd64.iso                         .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso                                              " \
		"o  debian-mini-13                  Debian%2013                             debian              ${DIRS_ISOS}    mini-trixie-amd64.iso                           .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso                                                " \
		"-  debian-mini-14                  Debian%2014                             debian              ${DIRS_ISOS}    mini-forky-amd64.iso                            .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso                                                 " \
		"o  debian-mini-testing             Debian%20testing                        debian              ${DIRS_ISOS}    mini-testing-amd64.iso                          .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.debian.org/debian/dists/testing/main/installer-amd64/current/images/netboot/mini.iso                                               " \
		"o  debian-mini-testing-daily       Debian%20testing%20daily                debian              ${DIRS_ISOS}    mini-testing-daily-amd64.iso                    .                                       initrd.gz                   linux                   preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso                                                                               " \
		"x  ubuntu-mini-18.04               Ubuntu%2018.04                          ubuntu              ${DIRS_ISOS}    mini-bionic-amd64.iso                           .                                       initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso                                     " \
		"o  ubuntu-mini-20.04               Ubuntu%2020.04                          ubuntu              ${DIRS_ISOS}    mini-focal-amd64.iso                            .                                       initrd.gz                   linux                   preseed/ps_ubuntu_server_old.cfg        ${HGFS_DIRS}/linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-amd64/current/legacy-images/netboot/mini.iso                               " \
		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                               2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- netinst -------------------------------------------------------------
	declare -r -a DATA_LIST_NET=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             \
		"m  menu-entry                      Auto%20install%20Net%20install          -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-netinst-10               Debian%2010                             debian              ${DIRS_ISOS}    debian-10.13.0-amd64-netinst.iso                install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_oldold.cfg     ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-10.[0-9.]*-amd64-netinst.iso                                " \
		"o  debian-netinst-11               Debian%2011                             debian              ${DIRS_ISOS}    debian-11.11.0-amd64-netinst.iso                install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_old.cfg        ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-11.[0-9.]*-amd64-netinst.iso                                   " \
		"o  debian-netinst-12               Debian%2012                             debian              ${DIRS_ISOS}    debian-12.9.0-amd64-netinst.iso                 install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso                                            " \
		"o  debian-netinst-13               Debian%2013                             debian              ${DIRS_ISOS}    debian-13.0.0-amd64-netinst.iso                 install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"-  debian-netinst-14               Debian%2014                             debian              ${DIRS_ISOS}    debian-14.0.0-amd64-netinst.iso                 install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  debian-netinst-testing          Debian%20testing                        debian              ${DIRS_ISOS}    debian-testing-amd64-netinst.iso                install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso                                " \
		"x  fedora-netinst-38               Fedora%20Server%2038                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-38-1.6.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-38_net.cfg          ${HGFS_DIRS}/linux/fedora        2023-04-18  2024-05-14  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-netinst-x86_64-38-[0-9.]*.iso                  " \
		"x  fedora-netinst-39               Fedora%20Server%2039                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-39-1.5.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-39_net.cfg          ${HGFS_DIRS}/linux/fedora        2023-11-07  2024-11-12  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-netinst-x86_64-39-[0-9.]*.iso                  " \
		"o  fedora-netinst-40               Fedora%20Server%2040                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-40-1.14.iso        images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-40_net.cfg          ${HGFS_DIRS}/linux/fedora        2024-04-16  2025-05-13  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-netinst-x86_64-40-[0-9.]*.iso                  " \
		"o  fedora-netinst-41               Fedora%20Server%2041                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-41-1.4.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-41_net.cfg          ${HGFS_DIRS}/linux/fedora        202x-xx-xx  202x-xx-xx  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41-[0-9.]*.iso                  " \
		"x  fedora-netinst-41               Fedora%20Server%2041                    fedora              ${DIRS_ISOS}    Fedora-Server-netinst-x86_64-41_Beta-1.2.iso    images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-41_net.cfg          ${HGFS_DIRS}/linux/fedora        202x-xx-xx  202x-xx-xx  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/test/41_Beta/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41_Beta-[0-9.]*.iso   " \
		"x  centos-stream-netinst-8         CentOS%20Stream%208                     centos              ${DIRS_ISOS}    CentOS-Stream-8-x86_64-latest-boot.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-8_net.cfg    ${HGFS_DIRS}/linux/centos        20xx-xx-xx  2024-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-boot.iso                                             " \
		"o  centos-stream-netinst-9         CentOS%20Stream%209                     centos              ${DIRS_ISOS}    CentOS-Stream-9-latest-x86_64-boot.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-9_net.cfg    ${HGFS_DIRS}/linux/centos        2021-xx-xx  2027-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                                " \
		"o  centos-stream-netinst-10        CentOS%20Stream%2010                    centos              ${DIRS_ISOS}    CentOS-Stream-10-latest-x86_64-boot.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-10_net.cfg   ${HGFS_DIRS}/linux/centos        2024-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso                              " \
		"o  almalinux-netinst-9             Alma%20Linux%209                        almalinux           ${DIRS_ISOS}    AlmaLinux-9-latest-x86_64-boot.iso              images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_almalinux-9_net.cfg        ${HGFS_DIRS}/linux/almalinux     2022-05-26  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso                                                          " \
		"x  rockylinux-netinst-8            Rocky%20Linux%208                       Rocky               ${DIRS_ISOS}    Rocky-8.10-x86_64-boot.iso                      images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-8_net.cfg       ${HGFS_DIRS}/linux/Rocky         2022-11-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-boot.iso                                                         " \
		"o  rockylinux-netinst-9            Rocky%20Linux%209                       Rocky               ${DIRS_ISOS}    Rocky-9-latest-x86_64-boot.iso                  images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-9_net.cfg       ${HGFS_DIRS}/linux/Rocky         2022-07-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-boot.iso                                                         " \
		"x  miraclelinux-netinst-8          Miracle%20Linux%208                     miraclelinux        ${DIRS_ISOS}    MIRACLELINUX-8.10-rtm-minimal-x86_64.iso        images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-8_net.cfg     ${HGFS_DIRS}/linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-minimal-x86_64.iso                   " \
		"o  miraclelinux-netinst-9          Miracle%20Linux%209                     miraclelinux        ${DIRS_ISOS}    MIRACLELINUX-9.4-rtm-minimal-x86_64.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-9_net.cfg     ${HGFS_DIRS}/linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-minimal-x86_64.iso                   " \
		"x  opensuse-leap-netinst-15.5      openSUSE%20Leap%2015.5                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-15.5-NET-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.5_net.xml     ${HGFS_DIRS}/linux/openSUSE      2023-06-07  2024-12-31  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.5/iso/openSUSE-Leap-15.5-NET-x86_64-Media.iso                                         " \
		"o  opensuse-leap-netinst-15.6      openSUSE%20Leap%2015.6                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-15.6-NET-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.6_net.xml     ${HGFS_DIRS}/linux/openSUSE      2024-06-xx  2025-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Media.iso                                         " \
		"-  opensuse-leap-netinst-16.0      openSUSE%20Leap%2016.0                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-16.0-NET-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-16.0_net.xml     ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-NET-x86_64-Media.iso                                         " \
		"o  opensuse-leap-netinst-16.0      openSUSE%20Leap%2016.0                  openSUSE            ${DIRS_ISOS}    agama-installer-Leap.x86_64-Leap.iso            boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-16.0_net.xml     ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/installer/iso/agama-installer-Leap.x86_64-Leap.iso                                  " \
		"o  opensuse-leap-netinst-pxe-16.0  openSUSE%20Leap%2016.0%20PXE            openSUSE            ${DIRS_ISOS}    agama-installer-Leap.x86_64-Leap-PXE.iso        boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-16.0_net.xml     ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/installer/iso/agama-installer-Leap.x86_64-Leap-PXE.iso                              " \
		"o  opensuse-tumbleweed-netinst     openSUSE%20Tumbleweed                   openSUSE            ${DIRS_ISOS}    openSUSE-Tumbleweed-NET-x86_64-Current.iso      boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_tumbleweed_net.xml    ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                                  " \
		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                               2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- dvd image -----------------------------------------------------------
	declare -r -a DATA_LIST_DVD=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             \
		"m  menu-entry                      Auto%20install%20DVD%20media            -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-10                       Debian%2010                             debian              ${DIRS_ISOS}    debian-10.13.0-amd64-DVD-1.iso                  install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_oldold.cfg     ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-10.[0-9.]*-amd64-DVD-1.iso                                 " \
		"o  debian-11                       Debian%2011                             debian              ${DIRS_ISOS}    debian-11.11.0-amd64-DVD-1.iso                  install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server_old.cfg        ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.[0-9.]*-amd64-DVD-1.iso                                    " \
		"o  debian-12                       Debian%2012                             debian              ${DIRS_ISOS}    debian-12.9.0-amd64-DVD-1.iso                   install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-12.[0-9.]*-amd64-DVD-1.iso                                             " \
		"o  debian-13                       Debian%2013                             debian              ${DIRS_ISOS}    debian-13.0.0-amd64-DVD-1.iso                   install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"-  debian-14                       Debian%2014                             debian              ${DIRS_ISOS}    debian-14.0.0-amd64-DVD-1.iso                   install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  debian-testing                  Debian%20testing                        debian              ${DIRS_ISOS}    debian-testing-amd64-DVD-1.iso                  install.amd                             initrd.gz                   vmlinuz                 preseed/ps_debian_server.cfg            ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                                                  " \
		"x  ubuntu-server-14.04             Ubuntu%2014.04%20Server                 ubuntu              ${DIRS_ISOS}    ubuntu-14.04.6-server-amd64.iso                 install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"-  ubuntu-server-16.04             Ubuntu%2016.04%20Server                 ubuntu              ${DIRS_ISOS}    ubuntu-16.04.6-server-amd64.iso                 install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-server-18.04             Ubuntu%2018.04%20Server                 ubuntu              ${DIRS_ISOS}    ubuntu-18.04.6-server-amd64.iso                 install/netboot/ubuntu-installer/amd64  initrd.gz                   linux                   preseed/ps_ubuntu_server_oldold.cfg     ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/bionic/release/ubuntu-18.04[0-9.]*-server-amd64.iso                                                        " \
		"x  ubuntu-live-18.04               Ubuntu%2018.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-18.04.6-live-server-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server_oldold            ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-live-server-amd64.iso                                                                   " \
		"o  ubuntu-live-20.04               Ubuntu%2020.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-20.04.6-live-server-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server_old               ${HGFS_DIRS}/linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-live-server-amd64.iso                                                                    " \
		"o  ubuntu-live-22.04               Ubuntu%2022.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-22.04.5-live-server-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server_old               ${HGFS_DIRS}/linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-live-server-amd64.iso                                                                    " \
		"x  ubuntu-live-23.04               Ubuntu%2023.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-23.04-live-server-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-live-server-amd64.iso                                                                    " \
		"x  ubuntu-live-23.10               Ubuntu%2023.10%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-23.10-live-server-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-live-server-amd64.iso                                                                   " \
		"o  ubuntu-live-24.04               Ubuntu%2024.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-24.04.2-live-server-amd64.iso            casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-live-server-amd64.iso                                                                    " \
		"o  ubuntu-live-24.10               Ubuntu%2024.10%20Live%20Server          ubuntu              ${DIRS_ISOS}    ubuntu-24.10-live-server-amd64.iso              casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-live-server-amd64.iso                                                                 " \
		"o  ubuntu-live-25.04               Ubuntu%2025.04%20Live%20Server          ubuntu              ${DIRS_ISOS}    plucky-live-server-amd64.iso                    casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2025-04-17  2026-01-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/plucky-live-server-amd64.iso                                                       " \
		"-  ubuntu-live-24.10               Ubuntu%2024.10%20Live%20Server%20Beta   ubuntu              ${DIRS_ISOS}    ubuntu-24.10-beta-live-server-amd64.iso         casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10-beta-live-server-amd64.iso                                                                   " \
		"-  ubuntu-live-oracular            Ubuntu%20oracular%20Live%20Server       ubuntu              ${DIRS_ISOS}    oracular-live-server-amd64.iso                  casper                                  initrd                      vmlinuz                 nocloud/ubuntu_server                   ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/ubuntu-server/daily-live/current/oracular-live-server-amd64.iso                                                     " \
		"x  fedora-38                       Fedora%20Server%2038                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-38-1.6.iso             images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-38_dvd.cfg          ${HGFS_DIRS}/linux/fedora        2023-04-18  2024-05-14  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/38/Server/x86_64/iso/Fedora-Server-dvd-x86_64-38-[0-9.]*.iso                      " \
		"x  fedora-39                       Fedora%20Server%2039                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-39-1.5.iso             images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-39_dvd.cfg          ${HGFS_DIRS}/linux/fedora        2023-11-07  2024-11-12  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/iso/Fedora-Server-dvd-x86_64-39-[0-9.]*.iso                      " \
		"o  fedora-40                       Fedora%20Server%2040                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-40-1.14.iso            images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-40_dvd.cfg          ${HGFS_DIRS}/linux/fedora        2024-04-16  2025-05-13  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-dvd-x86_64-40-[0-9.]*.iso                      " \
		"o  fedora-41                       Fedora%20Server%2041                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-41-1.4.iso             images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-41_dvd.cfg          ${HGFS_DIRS}/linux/fedora        202x-xx-xx  202x-xx-xx  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-[0-9.]*.iso                      " \
		"x  fedora-41                       Fedora%20Server%2041                    fedora              ${DIRS_ISOS}    Fedora-Server-dvd-x86_64-41_Beta-1.2.iso        images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_fedora-41_dvd.cfg          ${HGFS_DIRS}/linux/fedora        202x-xx-xx  202x-xx-xx  xx:xx:xx    0   -   -   https://download.fedoraproject.org/pub/fedora/linux/releases/test/41_Beta/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41_Beta-[0-9.]*.iso       " \
		"x  centos-stream-8                 CentOS%20Stream%208                     centos              ${DIRS_ISOS}    CentOS-Stream-8-x86_64-latest-dvd1.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-8_dvd.cfg    ${HGFS_DIRS}/linux/centos        2019-xx-xx  2024-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-dvd1.iso                                             " \
		"o  centos-stream-9                 CentOS%20Stream%209                     centos              ${DIRS_ISOS}    CentOS-Stream-9-latest-x86_64-dvd1.iso          images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-9_dvd.cfg    ${HGFS_DIRS}/linux/centos        2021-xx-xx  2027-05-31  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                                " \
		"o  centos-stream-10                CentOS%20Stream%2010                    centos              ${DIRS_ISOS}    CentOS-Stream-10-latest-x86_64-dvd1.iso         images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_centos-stream-10_dvd.cfg   ${HGFS_DIRS}/linux/centos        2024-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso                              " \
		"o  almalinux-9                     Alma%20Linux%209                        almalinux           ${DIRS_ISOS}    AlmaLinux-9-latest-x86_64-dvd.iso               images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_almalinux-9_dvd.cfg        ${HGFS_DIRS}/linux/almalinux     2022-05-26  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso                                                           " \
		"x  rockylinux-8                    Rocky%20Linux%208                       Rocky               ${DIRS_ISOS}    Rocky-8.10-x86_64-dvd1.iso                      images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-8_dvd.cfg       ${HGFS_DIRS}/linux/Rocky         2022-11-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8[0-9.]*-x86_64-dvd1.iso                                                         " \
		"o  rockylinux-9                    Rocky%20Linux%209                       Rocky               ${DIRS_ISOS}    Rocky-9-latest-x86_64-dvd.iso                   images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_rockylinux-9_dvd.cfg       ${HGFS_DIRS}/linux/Rocky         2022-07-14  20xx-xx-xx  xx:xx:xx    0   -   -   https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-dvd.iso                                                          " \
		"x  miraclelinux-8                  Miracle%20Linux%208                     miraclelinux        ${DIRS_ISOS}    MIRACLELINUX-8.10-rtm-x86_64.iso                images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-8_dvd.cfg     ${HGFS_DIRS}/linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.[0-9.]*-released/x86_64/MIRACLELINUX-8.[0-9.]*-rtm-x86_64.iso                           " \
		"o  miraclelinux-9                  Miracle%20Linux%209                     miraclelinux        ${DIRS_ISOS}    MIRACLELINUX-9.4-rtm-x86_64.iso                 images/pxeboot                          initrd.img                  vmlinuz                 kickstart/ks_miraclelinux-9_dvd.cfg     ${HGFS_DIRS}/linux/miraclelinux  2021-10-04  20xx-xx-xx  xx:xx:xx    0   -   -   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso                           " \
		"x  opensuse-leap-15.5              openSUSE%20Leap%2015.5                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-15.5-DVD-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.5_dvd.xml     ${HGFS_DIRS}/linux/openSUSE      2023-06-07  2024-12-31  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.5/iso/openSUSE-Leap-15.5-DVD-x86_64-Media.iso                                         " \
		"o  opensuse-leap-15.6              openSUSE%20Leap%2015.6                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-15.6-DVD-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-15.6_dvd.xml     ${HGFS_DIRS}/linux/openSUSE      2024-06-xx  2025-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso                                         " \
		"o  opensuse-leap-16.0              openSUSE%20Leap%2016.0                  openSUSE            ${DIRS_ISOS}    openSUSE-Leap-16.0-DVD-x86_64-Media.iso         boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_leap-16.0_dvd.xml     ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-DVD-x86_64-Media.iso                                         " \
		"o  opensuse-tumbleweed             openSUSE%20Tumbleweed                   openSUSE            ${DIRS_ISOS}    openSUSE-Tumbleweed-DVD-x86_64-Current.iso      boot/x86_64/loader                      initrd                      linux                   autoyast/autoinst_tumbleweed_dvd.xml    ${HGFS_DIRS}/linux/openSUSE      20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                                  " \
		"o  windows-10                      Windows%2010                            windows             ${DIRS_ISOS}    Win10_22H2_Japanese_x64.iso                     -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/Windows10   -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  windows-11                      Windows%2011                            windows             ${DIRS_ISOS}    Win11_24H2_Japanese_x64.iso                     -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/Windows11   -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"-  windows-11                      Windows%2011%20custom                   windows             ${DIRS_ISOS}    Win11_24H2_Japanese_x64_custom.iso              -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/Windows11   -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                               2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- live media install mode ---------------------------------------------
	declare -r -a DATA_LIST_INST=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            \
		"m  menu-entry                      Live%20media%20Install%20mode           -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-live-10                  Debian%2010%20Live                      debian              ${DIRS_ISOS}    debian-live-10.13.0-amd64-lxde.iso              d-i                                     initrd.gz                   vmlinuz                 preseed/ps_debian_desktop_oldold.cfg    ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-10.[0-9.]*-amd64-lxde.iso                     " \
		"o  debian-live-11                  Debian%2011%20Live                      debian              ${DIRS_ISOS}    debian-live-11.11.0-amd64-lxde.iso              d-i                                     initrd.gz                   vmlinuz                 preseed/ps_debian_desktop_old.cfg       ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso                        " \
		"o  debian-live-12                  Debian%2012%20Live                      debian              ${DIRS_ISOS}    debian-live-12.9.0-amd64-lxde.iso               install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                                 " \
		"o  debian-live-13                  Debian%2013%20Live                      debian              ${DIRS_ISOS}    debian-live-13.0.0-amd64-lxde.iso               install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  debian-live-testing             Debian%20testing%20Live                 debian              ${DIRS_ISOS}    debian-live-testing-amd64-lxde.iso              install                                 initrd.gz                   vmlinuz                 preseed/ps_debian_desktop.cfg           ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                      " \
		"x  ubuntu-desktop-14.04            Ubuntu%2014.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-14.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_oldold.cfg  ${HGFS_DIRS}/linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-desktop-16.04            Ubuntu%2016.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-16.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_oldold.cfg  ${HGFS_DIRS}/linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-desktop-18.04            Ubuntu%2018.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-18.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_oldold.cfg  ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-20.04            Ubuntu%2020.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-20.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_old.cfg     ${HGFS_DIRS}/linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"o  ubuntu-desktop-22.04            Ubuntu%2022.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-22.04.5-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_old.cfg     ${HGFS_DIRS}/linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"x  ubuntu-desktop-23.04            Ubuntu%2023.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-23.04-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"x  ubuntu-desktop-23.10            Ubuntu%2023.10%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-23.10.1-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-24.04            Ubuntu%2024.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.04.2-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"o  ubuntu-desktop-24.10            Ubuntu%2024.10%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.10-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-desktop-amd64.iso                                                                     " \
		"-  ubuntu-desktop-24.10            Ubuntu%2024.10%20Desktop%20Beta         ubuntu              ${DIRS_ISOS}    ubuntu-24.10-beta-desktop-amd64.iso             casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10-beta-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-25.04            Ubuntu%2025.04%20Desktop                ubuntu              ${DIRS_ISOS}    plucky-desktop-amd64.iso                        casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2025-04-17  2026-01-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/plucky-desktop-amd64.iso                                                                         " \
		"x  ubuntu-desktop-24.04            Ubuntu%2024.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.04-beta-desktop-amd64.iso             casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-beta-desktop-amd64.iso                                                                   " \
		"-  ubuntu-desktop-oracular         Ubuntu%20oracular%20Desktop             ubuntu              ${DIRS_ISOS}    oracular-desktop-amd64.iso                      casper                                  initrd                      vmlinuz                 nocloud/ubuntu_desktop                  ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/oracular-desktop-amd64.iso                                                                       " \
		"x  ubuntu-legacy-23.04             Ubuntu%2023.04%20Legacy%20Desktop       ubuntu              ${DIRS_ISOS}    ubuntu-23.04-desktop-legacy-amd64.iso           casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop_oldold.cfg  ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/lunar/release/ubuntu-23.04[0-9.]*-desktop-legacy-amd64.iso                                                 " \
		"x  ubuntu-legacy-23.10             Ubuntu%2023.10%20Legacy%20Desktop       ubuntu              ${DIRS_ISOS}    ubuntu-23.10-desktop-legacy-amd64.iso           casper                                  initrd                      vmlinuz                 preseed/ps_ubiquity_desktop.cfg         ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/mantic/release/ubuntu-23.10[0-9.]*-desktop-legacy-amd64.iso                                                " \
		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                               2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- live media live mode ------------------------------------------------
	declare -r -a DATA_LIST_LIVE=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            \
		"m  menu-entry                      Live%20media%20Live%20mode              -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  debian-live-10                  Debian%2010%20Live                      debian              ${DIRS_ISOS}    debian-live-10.13.0-amd64-lxde.iso              live                                    initrd.img-4.19.0-21-amd64  vmlinuz-4.19.0-21-amd64 preseed/-                               ${HGFS_DIRS}/linux/debian        2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-10.[0-9.]*-amd64-lxde.iso                     " \
		"o  debian-live-11                  Debian%2011%20Live                      debian              ${DIRS_ISOS}    debian-live-11.11.0-amd64-lxde.iso              live                                    initrd.img-5.10.0-32-amd64  vmlinuz-5.10.0-32-amd64 preseed/-                               ${HGFS_DIRS}/linux/debian        2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso                        " \
		"o  debian-live-12                  Debian%2012%20Live                      debian              ${DIRS_ISOS}    debian-live-12.9.0-amd64-lxde.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/debian        2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso                                 " \
		"o  debian-live-13                  Debian%2013%20Live                      debian              ${DIRS_ISOS}    debian-live-13.0.0-amd64-lxde.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/debian        202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  debian-live-testing             Debian%20testing%20Live                 debian              ${DIRS_ISOS}    debian-live-testing-amd64-lxde.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/debian        20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                      " \
		"x  ubuntu-desktop-14.04            Ubuntu%2014.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-14.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2014-04-17  2024-04-25  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-desktop-16.04            Ubuntu%2016.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-16.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2016-04-21  2026-04-23  xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"x  ubuntu-desktop-18.04            Ubuntu%2018.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-18.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2018-04-26  2028-04-26  xx:xx:xx    0   -   -   https://releases.ubuntu.com/bionic/ubuntu-18.04[0-9.]*-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-20.04            Ubuntu%2020.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-20.04.6-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2020-04-23  2030-04-23  xx:xx:xx    0   -   -   https://releases.ubuntu.com/focal/ubuntu-20.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"o  ubuntu-desktop-22.04            Ubuntu%2022.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-22.04.5-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2022-04-21  2032-04-21  xx:xx:xx    0   -   -   https://releases.ubuntu.com/jammy/ubuntu-22.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"x  ubuntu-desktop-23.04            Ubuntu%2023.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-23.04-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/lunar/ubuntu-23.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"x  ubuntu-desktop-23.10            Ubuntu%2023.10%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-23.10.1-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://releases.ubuntu.com/mantic/ubuntu-23.10[0-9.]*-desktop-amd64.iso                                                                       " \
		"o  ubuntu-desktop-24.04            Ubuntu%2024.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.04.2-desktop-amd64.iso                casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2034-04-25  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-desktop-amd64.iso                                                                        " \
		"o  ubuntu-desktop-24.10            Ubuntu%2024.10%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.10-desktop-amd64.iso                  casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10[0-9.]*-desktop-amd64.iso                                                                     " \
		"-  ubuntu-desktop-24.10            Ubuntu%2024.10%20Desktop%20Beta         ubuntu              ${DIRS_ISOS}    ubuntu-24.10-beta-desktop-amd64.iso             casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://releases.ubuntu.com/oracular/ubuntu-24.10-beta-desktop-amd64.iso                                                                       " \
		"x  ubuntu-desktop-24.04            Ubuntu%2024.04%20Desktop                ubuntu              ${DIRS_ISOS}    ubuntu-24.04-beta-desktop-amd64.iso             casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-04-25  2029-05-31  xx:xx:xx    0   -   -   https://releases.ubuntu.com/noble/ubuntu-24.04[0-9.]*-beta-desktop-amd64.iso                                                                   " \
		"o  ubuntu-desktop-25.04            Ubuntu%2025.04%20Desktop                ubuntu              ${DIRS_ISOS}    plucky-desktop-amd64.iso                        casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2025-04-17  2026-01-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/plucky-desktop-amd64.iso                                                                         " \
		"-  ubuntu-desktop-oracular         Ubuntu%20oracular%20Desktop             ubuntu              ${DIRS_ISOS}    oracular-desktop-amd64.iso                      casper                                  initrd                      vmlinuz                 nocloud/-                               ${HGFS_DIRS}/linux/ubuntu        2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/daily-live/current/oracular-desktop-amd64.iso                                                                       " \
		"x  ubuntu-legacy-23.04             Ubuntu%2023.04%20Legacy%20Desktop       ubuntu              ${DIRS_ISOS}    ubuntu-23.04-desktop-legacy-amd64.iso           casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2023-04-20  2024-01-25  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/lunar/release/ubuntu-23.04[0-9.]*-desktop-legacy-amd64.iso                                                 " \
		"x  ubuntu-legacy-23.10             Ubuntu%2023.10%20Legacy%20Desktop       ubuntu              ${DIRS_ISOS}    ubuntu-23.10-desktop-legacy-amd64.iso           casper                                  initrd                      vmlinuz                 preseed/-                               ${HGFS_DIRS}/linux/ubuntu        2023-10-12  2024-07-11  xx:xx:xx    0   -   -   https://cdimage.ubuntu.com/releases/mantic/release/ubuntu-23.10[0-9.]*-desktop-legacy-amd64.iso                                                " \
		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                               2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- tool ----------------------------------------------------------------
	declare -r -a DATA_LIST_TOOL=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            \
		"m  menu-entry                      System%20tools                          -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  memtest86plus                   Memtest86+%207.00                       memtest86+          ${DIRS_ISOS}    mt86plus_7.00_64.grub.iso                       -                                       EFI/BOOT/memtest            boot/memtest            -                                       ${HGFS_DIRS}/linux/memtest86+    -           -           xx:xx:xx    0   -   -   https://www.memtest.org/download/v7.00/mt86plus_7.00_64.grub.iso.zip                                                                           " \
		"o  memtest86plus                   Memtest86+%207.20                       memtest86+          ${DIRS_ISOS}    mt86plus_7.20_64.grub.iso                       -                                       EFI/BOOT/memtest            boot/memtest            -                                       ${HGFS_DIRS}/linux/memtest86+    -           -           xx:xx:xx    0   -   -   https://www.memtest.org/download/v7.20/mt86plus_7.20_64.grub.iso.zip                                                                           " \
		"o  winpe-x64                       WinPE%20x64                             windows             ${DIRS_ISOS}    WinPEx64.iso                                    -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/WinPE       -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  winpe-x86                       WinPE%20x86                             windows             ${DIRS_ISOS}    WinPEx86.iso                                    -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/WinPE       -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  ati2020x64                      ATI2020x64                              windows             ${DIRS_ISOS}    WinPE_ATI2020x64.iso                            -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/ati         -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"o  ati2020x86                      ATI2020x86                              windows             ${DIRS_ISOS}    WinPE_ATI2020x86.iso                            -                                       -                           -                       -                                       ${HGFS_DIRS}/windows/ati         -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                               2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- custom iso image ----------------------------------------------------
	declare -r -a DATA_LIST_CSTM=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            \
		"m  menu-entry                      Custom%20Live%20Media                   -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"x  live-debian-10-buster           Live%20Debian%2010                      debian              ${DIRS_ISOS}    live-debian-10-buster-amd64.iso                 live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-11-bullseye         Live%20Debian%2011                      debian              ${DIRS_ISOS}    live-debian-11-bullseye-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-12-bookworm         Live%20Debian%2012                      debian              ${DIRS_ISOS}    live-debian-12-bookworm-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-13-trixie           Live%20Debian%2013                      debian              ${DIRS_ISOS}    live-debian-13-trixie-amd64.iso                 live                                    initrd.img                  vmlinuz                 preseed/-                               -                                202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  live-debian-xx-unstable         Live%20Debian%20xx                      debian              ${DIRS_ISOS}    live-debian-xx-unstable-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"x  live-ubuntu-14.04-trusty        Live%20Ubuntu%2014.04                   ubuntu              ${DIRS_ISOS}    live-ubuntu-14.04-trusty-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2014-04-17  2024-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"L  live-ubuntu-16.04-xenial        Live%20Ubuntu%2016.04                   ubuntu              ${DIRS_ISOS}    live-ubuntu-16.04-xenial-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2016-04-21  2026-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"L  live-ubuntu-18.04-bionic        Live%20Ubuntu%2018.04                   ubuntu              ${DIRS_ISOS}    live-ubuntu-18.04-bionic-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2018-04-26  2028-04-26  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"s  live-ubuntu-20.04-focal         Live%20Ubuntu%2020.04                   ubuntu              ${DIRS_ISOS}    live-ubuntu-20.04-focal-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2020-04-23  2030-04-23  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-22.04-jammy         Live%20Ubuntu%2022.04                   ubuntu              ${DIRS_ISOS}    live-ubuntu-22.04-jammy-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2022-04-21  2032-04-21  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"x  live-ubuntu-23.04-lunar         Live%20Ubuntu%2023.04                   ubuntu              ${DIRS_ISOS}    live-ubuntu-23.04-lunar-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2023-04-20  2024-01-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"x  live-ubuntu-23.10-mantic        Live%20Ubuntu%2023.10                   ubuntu              ${DIRS_ISOS}    live-ubuntu-23.10-mantic-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2023-10-12  2024-07-11  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-24.04-noble         Live%20Ubuntu%2024.04                   ubuntu              ${DIRS_ISOS}    live-ubuntu-24.04-noble-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2024-04-25  2034-04-25  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-24.10-oracular      Live%20Ubuntu%2024.10                   ubuntu              ${DIRS_ISOS}    live-ubuntu-24.10-oracular-amd64.iso            live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2024-10-10  2025-07-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"o  live-ubuntu-25.04-plucky        Live%20Ubuntu%2025.04                   ubuntu              ${DIRS_ISOS}    live-ubuntu-25.04-plucky-amd64.iso              live                                    initrd.img                  vmlinuz                 preseed/-                               -                                2025-04-17  2026-01-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"s  live-ubuntu-xx.xx-devel         Live%20Ubuntu%20xx.xx                   ubuntu              ${DIRS_ISOS}    live-ubuntu-xx.xx-devel-amd64.iso               live                                    initrd.img                  vmlinuz                 preseed/-                               -                                20xx-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   http://archive.ubuntu.com/ubuntu                                                                                                               " \
		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"m  menu-entry                      Custom%20Initramfs%20boot               -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
		"o  netinst-debian-10               Net%20Installer%20Debian%2010           debian              ${DIRS_LOAD}    -                                               .                                       initrd.gz_debian-10         linux_debian-10         preseed/ps_debian_server_oldold.cfg     -                                2019-07-06  2024-06-30  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  netinst-debian-11               Net%20Installer%20Debian%2011           debian              ${DIRS_LOAD}    -                                               .                                       initrd.gz_debian-11         linux_debian-11         preseed/ps_debian_server_old.cfg        -                                2021-08-14  2026-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  netinst-debian-12               Net%20Installer%20Debian%2012           debian              ${DIRS_LOAD}    -                                               .                                       initrd.gz_debian-12         linux_debian-12         preseed/ps_debian_server.cfg            -                                2023-06-10  2028-06-01  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  netinst-debian-13               Net%20Installer%20Debian%2013           debian              ${DIRS_LOAD}    -                                               .                                       initrd.gz_debian-13         linux_debian-13         preseed/ps_debian_server.cfg            -                                202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"o  netinst-debian-sid              Net%20Installer%20Debian%20sid          debian              ${DIRS_LOAD}    -                                               .                                       initrd.gz_debian-sid        linux_debian-sid        preseed/ps_debian_server.cfg            -                                202x-xx-xx  20xx-xx-xx  xx:xx:xx    0   -   -   https://deb.debian.org/debian                                                                                                                  " \
		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
	) #  0  1                               2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

	# --- system command ------------------------------------------------------
#	declare -r -a DATA_LIST_SCMD=(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            \
#		"m  menu-entry                      System%20command                        -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
#		"o  hdt                             Hardware%20info                         system              -               -                                               -                                       hdt.c32                     -                       -                                       -                                -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
#		"o  shutdown                        System%20shutdown                       system              -               -                                               -                                       poweroff.c32                -                       -                                       -                                -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
#		"o  restart                         System%20restart                        system              -               -                                               -                                       reboot.c32                  -                       -                                       -                                -           -           xx:xx:xx    0   -   -   -                                                                                                                                              " \
#		"m  menu-entry                      -                                       -                   -               -                                               -                                       -                           -                       -                                       -                                -           -           -           -   -   -   -                                                                                                                                              " \
#	) #  0  1                               2                                       3                   4               5                                               6                                       7                           8                       9                                       10                               11          12          13          14  15  16  17

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
	declare -r    TXT_DBLACK="${ESC}[30m"					# text dark black
	declare -r    TXT_DRED="${ESC}[31m"						# text dark red
	declare -r    TXT_DGREEN="${ESC}[32m"					# text dark green
	declare -r    TXT_DYELLOW="${ESC}[33m"					# text dark yellow
	declare -r    TXT_DBLUE="${ESC}[34m"					# text dark blue
	declare -r    TXT_DMAGENTA="${ESC}[35m"					# text dark purple
	declare -r    TXT_DCYAN="${ESC}[36m"					# text dark light blue
	declare -r    TXT_DWHITE="${ESC}[37m"					# text dark white

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
	printf "%s : %-12.12s : %s\n" "${TXT_DBLACK}"   "TXT_DBLACK"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DRED}"     "TXT_DRED"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DGREEN}"   "TXT_DGREEN"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DYELLOW}"  "TXT_DYELLOW"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DBLUE}"    "TXT_DBLUE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DMAGENTA}" "TXT_DMAGENTA" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DCYAN}"    "TXT_DCYAN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DWHITE}"   "TXT_DWHITE"   "${TXT_RESET}"
}

# --- diff --------------------------------------------------------------------
function funcDiff() {
	if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
		return
	fi
	printf "%s\n" "$3"
	diff -y -W "${COLS_SIZE}" --suppress-common-lines "$1" "$2" || true
}

# --- substr ------------------------------------------------------------------
function funcSubstr() {
	echo "$1" | awk '{print substr($0,'"$2"','"$3"');}'
}

# --- IPv6 full address -------------------------------------------------------
function funcIPv6GetFullAddr() {
#	declare -r    _OLD_IFS="${IFS}"
	declare       _INP_ADDR="$1"
	declare -r    _STR_FSEP="${_INP_ADDR//[^:]}"
	declare -r -i _CNT_FSEP=$((7-${#_STR_FSEP}))
	declare -a    _OUT_ARRY=()
	declare       _OUT_TEMP=""
	if [[ "${_CNT_FSEP}" -gt 0 ]]; then
		_OUT_TEMP="$(eval printf ':%.s' "{1..$((_CNT_FSEP+2))}")"
		_INP_ADDR="${_INP_ADDR/::/${_OUT_TEMP}}"
	fi
	IFS= mapfile -d ':' -t _OUT_ARRY < <(echo -n "${_INP_ADDR/%:/::}")
	_OUT_TEMP="$(printf ':%04x' "${_OUT_ARRY[@]/#/0x0}")"
	echo "${_OUT_TEMP:1}"
}

# --- IPv6 reverse address ----------------------------------------------------
function funcIPv6GetRevAddr() {
	declare -r    _INP_ADDR="$1"
	echo "${_INP_ADDR//:/}"                  | \
	    awk '{for(i=length();i>1;i--)          \
	        printf("%c.", substr($0,i,1));     \
	        printf("%c" , substr($0,1,1));}'
}

# --- IPv4 netmask conversion -------------------------------------------------
function funcIPv4GetNetmask() {
	declare -r    _INP_ADDR="$1"
#	declare       _DEC_ADDR="$((0xFFFFFFFF ^ (2**(32-_INP_ADDR)-1)))"
	declare -i    _LOOP=$((32-_INP_ADDR))
	declare -i    _WORK=1
	declare       _DEC_ADDR=""
	while [[ "${_LOOP}" -gt 0 ]]
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
}

# --- IPv4 cidr conversion ----------------------------------------------------
function funcIPv4GetNetCIDR() {
	declare -r    _INP_ADDR="$1"
	declare -a    _OCTETS=()
	declare -i    _MASK=0
	echo "${_INP_ADDR}" | \
	    awk -F '.' '{
	        split($0, _OCTETS);
	        for (I in _OCTETS) {
	            _MASK += 8 - log(2^8 - _OCTETS[I])/log(2);
	        }
	        print _MASK
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
	declare -r    _OLD_IFS="${IFS}"
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
	IFS="${_OLD_IFS}"
}

# --- print with screen control -----------------------------------------------
function funcPrintf() {
#	declare -r    _SET_ENV_E="$(set -o | awk '$1=="errexit" {print $2;}')"
	declare -r    _SET_ENV_X="$(set -o | awk '$1=="xtrace"  {print $2;}')"
	set +x
	# https://www.tohoho-web.com/ex/dash-tilde.html
	declare -r    _OLD_IFS="${IFS}"
#	declare -i    _RET_CD=0
	declare       _FLAG_CUT=""
	declare       _TEXT_FMAT=""
	declare -r    _CTRL_ESCP=$'\033['
	declare       _PRNT_STR=""
	declare       _SJIS_STR=""
	declare       _TEMP_STR=""
	declare       _WORK_STR=""
	declare -i    _CTRL_CNT=0
	declare -i    _MAX_COLS="${COLS_SIZE:-80}"
	# -------------------------------------------------------------------------
	IFS=$'\n'
	if [[ "$1" = "--no-cutting" ]]; then					# no cutting print
		_FLAG_CUT="true"
		shift
	fi
	if [[ "$1" =~ %[0-9.-]*[diouxXfeEgGcs]+ ]]; then
		# shellcheck disable=SC2001
		_TEXT_FMAT="$(echo "$1" | sed -e 's/%\([0-9.-]*\)s/%\1b/g')"
		shift
	fi
	# shellcheck disable=SC2059
	_PRNT_STR="$(printf "${_TEXT_FMAT:-%b}" "${@:-}")"
	if [[ -z "${_FLAG_CUT}" ]]; then
		_SJIS_STR="$(echo -n "${_PRNT_STR:-}" | iconv -f UTF-8 -t CP932)"
		_TEMP_STR="$(echo -n "${_SJIS_STR}" | sed -e "s/${_CTRL_ESCP}[0-9]*m//g")"
		if [[ "${#_TEMP_STR}" -gt "${_MAX_COLS}" ]]; then
			_CTRL_CNT=$((${#_SJIS_STR}-${#_TEMP_STR}))
			_WORK_STR="$(echo -n "${_SJIS_STR}" | cut -b $((_MAX_COLS+_CTRL_CNT))-)"
			_TEMP_STR="$(echo -n "${_WORK_STR}" | sed -e "s/${_CTRL_ESCP}[0-9]*m//g")"
			_MAX_COLS+=$((_CTRL_CNT-(${#_WORK_STR}-${#_TEMP_STR})))
			# shellcheck disable=SC2312
			if ! _PRNT_STR="$(echo -n "${_SJIS_STR:-}" | cut -b -"${_MAX_COLS}"   | iconv -f CP932 -t UTF-8 2> /dev/null)"; then
				 _PRNT_STR="$(echo -n "${_SJIS_STR:-}" | cut -b -$((_MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
			fi
		fi
	fi
	printf "%b\n" "${_PRNT_STR:-}"
	IFS="${_OLD_IFS}"
	# -------------------------------------------------------------------------
	if [[ "${_SET_ENV_X}" = "on" ]]; then
		set -x
	else
		set +x
	fi
#	if [[ "${_SET_ENV_E}" = "on" ]]; then
#		set -e
#	else
#		set +e
#	fi
}

# --- unit conversion ---------------------------------------------------------
function funcUnit_conversion() {
#	declare -r    _OLD_IFS="${IFS}"
	declare -r -a _TEXT_UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    _CALC_UNIT=0
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
		_CALC_UNIT=$((1024**I))
		if [[ "$1" -ge "${_CALC_UNIT}" ]]; then
			# shellcheck disable=SC2312
			printf "%s %s" "$(echo "$1" "${_CALC_UNIT}" | awk '{printf("%.1f", $1/$2)}')" "${_TEXT_UNIT[${I}]}"
			return
		fi
	done
	echo -n "$1"
}

# --- download ----------------------------------------------------------------
function funcCurl() {
#	declare -r    _OLD_IFS="${IFS}"
	declare -i    _RET_CD=0
	declare -i    I
	declare       _INP_URL=""
	declare       _OUT_DIR=""
	declare       _OUT_FILE=""
	declare       _MSG_FLG=""
	declare -a    _OPT_PRM=()
	declare -a    _ARY_HED=()
	declare       _ERR_MSG=""
	declare       _WEB_SIZ=""
	declare       _WEB_TIM=""
	declare       _WEB_FIL=""
	declare       _LOC_INF=""
	declare       _LOC_SIZ=""
	declare       _LOC_TIM=""
	declare       _TXT_SIZ=""

	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			http://* | https://* )
				_OPT_PRM+=("${1}")
				_INP_URL="${1}"
				;;
			--output-dir )
				_OPT_PRM+=("${1}")
				shift
				_OPT_PRM+=("${1}")
				_OUT_DIR="${1}"
				;;
			--output )
				_OPT_PRM+=("${1}")
				shift
				_OPT_PRM+=("${1}")
				_OUT_FILE="${1}"
				;;
			--quiet )
				_MSG_FLG="true"
				;;
			* )
				_OPT_PRM+=("${1}")
				;;
		esac
		shift
	done
	if [[ -z "${_OUT_FILE}" ]]; then
		_OUT_FILE="${_INP_URL##*/}"
	fi
	if ! _ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${_INP_URL}" 2> /dev/null)"); then
		_RET_CD="$?"
		_ERR_MSG=$(echo "${_ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -e 's/\r\n*/\n/g' -ze 's/\n//g')
#		echo -e "${_ERR_MSG} [${_RET_CD}]: ${_INP_URL}"
		if [[ -z "${_MSG_FLG}" ]]; then
			printf "%s\n" "${_ERR_MSG} [${_RET_CD}]: ${_INP_URL}"
		fi
		return "${_RET_CD}"
	fi
	_WEB_SIZ=$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/content-length:/ s/.*: //p')
	# shellcheck disable=SC2312
	_WEB_TIM=$(TZ=UTC date -d "$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
	_WEB_FIL="${_OUT_DIR:-.}/${_INP_URL##*/}"
	if [[ -n "${_OUT_DIR}" ]] && [[ ! -d "${_OUT_DIR}/." ]]; then
		mkdir -p "${_OUT_DIR}"
	fi
	if [[ -n "${_OUT_FILE}" ]] && [[ -e "${_OUT_FILE}" ]]; then
		_WEB_FIL="${_OUT_FILE}"
	fi
	if [[ -n "${_WEB_FIL}" ]] && [[ -e "${_WEB_FIL}" ]]; then
		_LOC_INF=$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${_WEB_FIL}")
		_LOC_TIM=$(echo "${_LOC_INF}" | awk '{print $6;}')
		_LOC_SIZ=$(echo "${_LOC_INF}" | awk '{print $5;}')
		if [[ "${_WEB_TIM:-0}" -eq "${_LOC_TIM:-0}" ]] && [[ "${_WEB_SIZ:-0}" -eq "${_LOC_SIZ:-0}" ]]; then
			if [[ -z "${_MSG_FLG}" ]]; then
				printf "%s\n" "same    file: ${_WEB_FIL}"
			fi
			return
		fi
	fi

	_TXT_SIZ="$(funcUnit_conversion "${_WEB_SIZ}")"

	if [[ -z "${_MSG_FLG}" ]]; then
		printf "%s\n" "get     file: ${_WEB_FIL} (${_TXT_SIZ})"
	fi
	if curl "${_OPT_PRM[@]}"; then
		return $?
	fi

	for ((I=0; I<3; I++))
	do
		if [[ -z "${_MSG_FLG}" ]]; then
			printf "%s\n" "retry  count: ${I}"
		fi
		if curl --continue-at "${_OPT_PRM[@]}"; then
			return "$?"
		else
			_RET_CD="$?"
		fi
	done
	if [[ "${_RET_CD}" -ne 0 ]]; then
		rm -f "${:?}"
	fi
	return "${_RET_CD}"
}

# --- service status ----------------------------------------------------------
function funcServiceStatus() {
	declare -i    _RET_CD=0
	declare       _SRVC_STAT=""
	_SRVC_STAT="$(systemctl "$@" 2> /dev/null || true)"
	_RET_CD="$?"
	case "${_RET_CD}" in
		4) _SRVC_STAT="not-found";;		# no such unit
		*) _SRVC_STAT="${_SRVC_STAT%-*}";;
	esac
	echo "${_SRVC_STAT:-"undefined"}: ${_RET_CD}"

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

# --- function is package -----------------------------------------------------
function funcIsPackage () {
	LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed'
}

# *** function section (sub functions) ****************************************

# === create ==================================================================

# ----- create directory ------------------------------------------------------
function funcCreate_directory() {
	declare -r    _DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -a    _DATA_LINE=()
	declare -a    _LINK_LINE=()
	declare       _RTIV_FLAG=""
	declare       _TGET_PATH=""
	declare       _LINK_PATH=""
	declare       _BACK_PATH=""
	declare -i    I=0
	# --- create directory ----------------------------------------------------
	mkdir -p "${LIST_DIRS[@]}"

	# --- create symbolic link ------------------------------------------------
	for I in "${!LIST_LINK[@]}"
	do
		read -r -a _LINK_LINE < <(echo "${LIST_LINK[I]}")
		_RTIV_FLAG="${_LINK_LINE[0]}"
		_TGET_PATH="${_LINK_LINE[1]}"
		_LINK_PATH="${_LINK_LINE[2]}"
		# --- check target file path ------------------------------------------
		if [[ -z "${_LINK_PATH##*/}" ]]; then
			_LINK_PATH="${_LINK_PATH%/}/${_TGET_PATH##*/}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${_LINK_PATH}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${_LINK_PATH/${PWD}\//}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${_LINK_PATH}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${_LINK_PATH}"
			_BACK_PATH="${_LINK_PATH}.back.${_DATE_TIME}"
			funcPrintf "%20.20s: %s" "move directory" "${_LINK_PATH/${PWD}\//} -> ${_BACK_PATH/${PWD}\//}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- create destination directory ------------------------------------
#		funcPrintf "%20.20s: %s" "create dest dir" "${_LINK_PATH%/*}"
		mkdir -p "${_LINK_PATH%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${_TGET_PATH/${PWD}\//} -> ${_LINK_PATH/${PWD}\//}"
		case "${_RTIV_FLAG}" in
			r) ln -sr "${_TGET_PATH}" "${_LINK_PATH}";;
			*) ln -s  "${_TGET_PATH}" "${_LINK_PATH}";;
		esac
	done

	# --- create symbolic link of data list -----------------------------------
	for I in "${!DATA_LIST[@]}"
	do
		read -r -a _DATA_LINE < <(echo "${DATA_LIST[I]}")
		_TGET_PATH="${_DATA_LINE[10]}/${_DATA_LINE[5]}"
		_LINK_PATH="${_DATA_LINE[4]}/${_TGET_PATH##*/}"
		if [[ "${_DATA_LINE[0]}" != "o" ]] \
		|| [[ "${_DATA_LINE[10]}" = "-" ]]; then
			continue
		fi
		# --- check target file path ------------------------------------------
		if [[ -z "${_LINK_PATH##*/}" ]]; then
			_LINK_PATH="${_LINK_PATH%/}/${_TGET_PATH##*/}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${_LINK_PATH}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${_LINK_PATH/${PWD}\//}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${_LINK_PATH}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${_LINK_PATH}"
			_BACK_PATH="${_LINK_PATH}.back.${_DATE_TIME}"
			funcPrintf "%20.20s: %s" "move directory" "${_LINK_PATH/${PWD}\//} -> ${_BACK_PATH/${PWD}\//}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- create destination directory ------------------------------------
#		funcPrintf "%20.20s: %s" "create dest dir" "${_LINK_PATH%/*}"
		mkdir -p "${_LINK_PATH%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${_TGET_PATH/${PWD}\//} -> ${_LINK_PATH/${PWD}\//}"
		ln -s "${_TGET_PATH}" "${_LINK_PATH}"
	done
}

# ----- create preseed kill dhcp ----------------------------------------------
function funcCreate_preseed_kill_dhcp() {
	declare -r    _DIRS_NAME="${DIRS_CONF}/preseed"
	declare -r    _FILE_NAME="${_DIRS_NAME}/preseed_kill_dhcp.sh"
	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_FILE_NAME/${PWD}\/}"
	mkdir -p "${_DIRS_NAME}"
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_NAME}"
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
		
		 	if set -o | grep "^xtrace\s*on$"; then
		 		exec 2>&1
		 	fi
		
		# *** main processing section *************************************************
		 	# --- start ---------------------------------------------------------------
		#	_start_time=$(date +%s)
		#	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
		#	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing start"
		 	# --- main ----------------------------------------------------------------
		 	/bin/kill-all-dhcp
		 	/bin/netcfg
		 	# --- complete ------------------------------------------------------------
		#	_end_time=$(date +%s)
		#	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
		#	printf "\033[m${PROG_NAME}: elapsed time: %dd%02dh%02dm%02ds\033[m\n" "$(((_end_time-_start_time)/86400))" "$(((_end_time-_start_time)%86400/3600))" "$(((_end_time-_start_time)%3600/60))" "$(((_end_time-_start_time)%60))"
		#	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing complete"
		 	exit 0
		
		### eof #######################################################################
_EOT_SH_
	chmod ugo+x "${_FILE_NAME}"
}

# ----- create late command ---------------------------------------------------
function funcCreate_late_command() {
	declare -r    _DIRS_NAME="${DIRS_CONF}/script"
	declare -r    _FILE_NAME="${_DIRS_NAME}/late_command.sh"
	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_FILE_NAME/${PWD}\/}"
	mkdir -p "${_DIRS_NAME}"
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_NAME}"
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
		
		 	if set -o | grep "^xtrace\s*on$"; then
		 		exec 2>&1
		 	fi
		
		 	# --- working directory name ----------------------------------------------
		 	readonly PROG_PATH="$0"
		 	readonly PROG_PRAM="$*"
		 	readonly PROG_DIRS="${PROG_PATH%/*}"
		 	readonly PROG_NAME="${PROG_PATH##*/}"
		 	readonly PROG_PROC="${PROG_NAME}.$$"
		 	#--- initial settings  ----------------------------------------------------
		 	NTPS_ADDR="ntp.nict.jp"				# ntp server address
		 	NTPS_IPV4="61.205.120.130"			# ntp server ipv4 address
		 	IPV6_LHST="::1"						# ipv6 local host address
		 	IPV4_LHST="127.0.0.1"				# ipv4 local host address
		 	IPV4_DUMY="127.0.1.1"				# ipv4 dummy address
		 	OLDS_FQDN="$(cat /etc/hostname)"	# old hostname (fqdn)
		 	OLDS_HOST="$(echo "${OLDS_FQDN}." | cut -d '.' -f 1)"	# old hostname (host name)
		 	OLDS_WGRP="$(echo "${OLDS_FQDN}." | cut -d '.' -f 2)"	# old hostname (domain)
		 	# --- firewalld -----------------------------------------------------------
		 	FWAL_ZONE="home_use"				# firewalld zone
		 										# firewalld service name
		 	FWAL_NAME="dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp"
		 	FWAL_PORT="0-65535/tcp 0-65535/udp"	# firewalld port
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
		 	DIRS_TGET=""						# target directory
		 	if command -v systemd-detect-virt > /dev/null 2>&1 \
		 	&& systemd-detect-virt --chroot; then
		 		CHGE_ROOT="true"
		 	fi
		 	if [ -d /target/. ]; then
		 		DIRS_TGET="/target"
		 	elif [ -d /mnt/sysimage/. ]; then
		 		DIRS_TGET="/mnt/sysimage"
		 	fi
		 	readonly DIRS_TGET
		 	if [ -n "${DIRS_TGET:-}" ] \
		 	&& [ "${CHGE_ROOT:-}" = "true" ]; then
		 		printf "\033[m${PROG_NAME}: \033[43m%s\033[m\n" "chroot start"
		 		mount --rbind /dev  "${DIRS_TGET:-}"/dev
		 		mount --rbind /proc "${DIRS_TGET:-}"/proc
		 		mount --rbind /run  "${DIRS_TGET:-}"/run
		 		mount --rbind /sys  "${DIRS_TGET:-}"/sys
		 		mount --rbind /tmp  "${DIRS_TGET:-}"/tmp
		 		mount --make-rslave "${DIRS_TGET:-}"/dev
		 		mount --make-rslave "${DIRS_TGET:-}"/sys
		 		systemctl daemon-reload
		 		mkdir -p "${DIRS_TGET:?}${PROG_DIRS}"
		 		cp -a "${PROG_PATH:?}" "${DIRS_TGET:?}${PROG_DIRS}"
		 		chroot "${DIRS_TGET:-}"/ sh -c "${PROG_DIRS}/${PROG_NAME}"
		 		# shellcheck disable=SC2046
		 		umount $(awk '{print $2;}' /proc/mounts | grep "${DIRS_TGET:-}" | sort -r || true)
		 		printf "\033[m${PROG_NAME}: \033[43m%s\033[m\n" "chroot complete"
		 	fi
		 	ROWS_SIZE="25"						# screen size: rows
		 	COLS_SIZE="80"						# screen size: columns
		 	TEXT_GAP1=""						# gap1
		 	TEXT_GAP2=""						# gap2
		 	# --- network parameter ---------------------------------------------------
		 	IPV4_UADR=""						# IPv4 address up   (ex. 192.168.1)
		 	IPV4_LADR=""						# IPv4 address low  (ex. 1)
		 	IPV6_ADDR=""						# IPv6 address      (ex. ::1)
		 	IPV6_CIDR=""						# IPv6 cidr         (ex. 64)
		 	IPV6_FADR=""						# IPv6 full address (ex. 0000:0000:0000:0000:0000:0000:0000:0001)
		 	IPV6_UADR=""						# IPv6 address up   (ex. 0000:0000:0000:0000)
		 	IPV6_LADR=""						# IPv6 address low  (ex. 0000:0000:0000:0001)
		 	IPV6_RADR=""						# IPv6 reverse addr (ex. ...)
		 	LINK_ADDR=""						# LINK address      (ex. fe80::1)
		 	LINK_CIDR=""						# LINK cidr         (ex. 64)
		 	LINK_FADR=""						# LINK full address (ex. fe80:0000:0000:0000:0000:0000:0000:0001)
		 	LINK_UADR=""						# LINK address up   (ex. fe80:0000:0000:0000)
		 	LINK_LADR=""						# LINK address low  (ex. 0000:0000:0000:0001)
		 	LINK_RADR=""						# LINK reverse addr (ex. ...)
		 	# --- samba parameter -----------------------------------------------------
		 	readonly SAMB_USER="sambauser"							# force user
		 	readonly SAMB_GRUP="sambashare"							# force group
		 	readonly SAMB_GADM="sambaadmin"							# admin group
		 	LGIN_SHEL="$(command -v nologin)"						# login shell (disallow system login to samba user)
		 	readonly LGIN_SHEL
		 	# --- directory parameter -------------------------------------------------
		 	readonly DIRS_SRVR="${DIRS_TGET:-}/srv"					# root of shared directory
		 	readonly DIRS_HGFS="${DIRS_TGET:-}${DIRS_SRVR}/hgfs"	# root of hgfs shared directory
		 	readonly DIRS_HTML="${DIRS_TGET:-}${DIRS_SRVR}/http"	# root of html shared directory
		 	readonly DIRS_TFTP="${DIRS_TGET:-}${DIRS_SRVR}/tftp"	# root of tftp shared directory
		 	readonly DIRS_SAMB="${DIRS_TGET:-}${DIRS_SRVR}/samba"	# root of samba shared directory
		 	readonly DIRS_USER="${DIRS_TGET:-}${DIRS_SRVR}/user"	# root of user shared directory
		
		 	# --- set command line parameter ------------------------------------------
		 	for LINE in ${COMD_LINE:-} ${PROG_PRAM:-}
		 	do
		 		case "${LINE}" in
		 			debug | debugout | dbg         ) DBGS_FLAG="true";;
		 			target=*                       ) DIRS_TGET="${LINE#*target=}";;
		 			iso-url=*.iso  | url=*.iso     ) ISOS_FILE="${LINE#*url=}";;
		 			preseed/url=*  | url=*         ) SEED_FILE="${LINE#*url=}";;
		 			preseed/file=* | file=*        ) SEED_FILE="${LINE#*file=}";;
		 			ds=nocloud*                    ) SEED_FILE="${LINE#*ds=nocloud*=}";SEED_FILE="${SEED_FILE%%/}/user-data";;
		 			inst.ks=*                      ) SEED_FILE="${LINE#*inst.ks=}";;
		 			autoyast=*                     ) SEED_FILE="${LINE#*autoyast=}";;
		 			netcfg/target_network_config=* ) NMAN_FLAG="${LINE#*target_network_config=}";;
		 			netcfg/choose_interface=*      ) NICS_NAME="${LINE#*choose_interface=}";;
		 			netcfg/disable_dhcp=*          ) IPV4_DHCP="$([ "${LINE#*disable_dhcp=}" = "true" ] && echo "false" || echo "true")";;
		 			netcfg/disable_autoconfig=*    ) IPV4_DHCP="$([ "${LINE#*disable_autoconfig=}" = "true" ] && echo "false" || echo "true")";;
		 			netcfg/get_ipaddress=*         ) NICS_IPV4="${LINE#*get_ipaddress=}";;
		 			netcfg/get_netmask=*           ) NICS_MASK="${LINE#*get_netmask=}";;
		 			netcfg/get_gateway=*           ) NICS_GATE="${LINE#*get_gateway=}";;
		 			netcfg/get_nameservers=*       ) NICS_DNS4="${LINE#*get_nameservers=}";;
		 			netcfg/get_hostname=*          ) NICS_FQDN="${LINE#*get_hostname=}";;
		 			netcfg/get_domain=*            ) NICS_WGRP="${LINE#*get_domain=}";;
		 			interface=*                    ) NICS_NAME="${LINE#*interface=}";;
		 			hostname=*                     ) NICS_FQDN="${LINE#*hostname=}";;
		 			domain=*                       ) NICS_WGRP="${LINE#*domain=}";;
		 			nameserver=*                   ) NICS_DNS4="${LINE#*nameserver=}";;
		 			ip=dhcp | ip4=dhcp | ipv4=dhcp ) IPV4_DHCP="true";;
		 			ip=* | ip4=* | ipv4=*          ) IPV4_DHCP="false"
		 			                                 NICS_IPV4="$(echo "${LINE#*ip*=}" | cut -d ':' -f 1)"
		 			                                 NICS_GATE="$(echo "${LINE#*ip*=}" | cut -d ':' -f 3)"
		 			                                 NICS_MASK="$(echo "${LINE#*ip*=}" | cut -d ':' -f 4)"
		 			                                 NICS_FQDN="$(echo "${LINE#*ip*=}" | cut -d ':' -f 5)"
		 			                                 NICS_NAME="$(echo "${LINE#*ip*=}" | cut -d ':' -f 6)"
		 			                                 NICS_DNS4="$(echo "${LINE#*ip*=}" | cut -d ':' -f 8)"
		 			                                 ;;
		 			ifcfg=*                        ) NICS_NAME="$(echo "${LINE#*ifcfg*=}"         | cut -d '=' -f 1)"
		 			                                 NICS_IPV4="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 1)"
		 			                                 case "${NICS_IPV4}" in
		 			                                     dhcp)
		 			                                         IPV4_DHCP="true"
		 			                                         NICS_IPV4=""
		 			                                         NICS_GATE=""
		 			                                         NICS_DNS4=""
		 			                                         NICS_WGRP=""
		 			                                         ;;
		 			                                     *)
		 			                                         IPV4_DHCP="false"
		 			                                         NICS_IPV4="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 1)"
		 			                                         NICS_GATE="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 2)"
		 			                                         NICS_DNS4="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 3)"
		 			                                         NICS_WGRP="$(echo "${LINE#*"${NICS_NAME}"=}" | cut -d ',' -f 4)"
		 			                                         ;;
		 			                                 esac
		 			                                 ;;
		 			*)  ;;
		 		esac
		 	done
		
		 	# --- working directory name ----------------------------------------------
		 	readonly DIRS_ORIG="${PROG_DIRS}/orig"			# original file directory
		 	readonly DIRS_INIT="${PROG_DIRS}/init"			# initial file directory
		 	readonly DIRS_SAMP="${PROG_DIRS}/samp"			# sample file directory
		 	readonly DIRS_LOGS="${PROG_DIRS}/logs"			# log file directory
		
		 	# --- log out -------------------------------------------------------------
		 	if [ -n "${DBGS_FLAG:-}" ] \
		 	&& command -v mkfifo > /dev/null 2>&1; then
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
		
		# --- IPv6 full address -------------------------------------------------------
		funcIPv6GetFullAddr() {
		 	_ADDRESS="${1:?}"
		 	if [ -z "${2:-}" ]; then
		 		_FORMAT="%x:%x:%x:%x:%x:%x:%x:%x"
		 	else
		 		_FORMAT="%04x:%04x:%04x:%04x:%04x:%04x:%04x:%04x"
		 	fi
		 	_SEPARATOR="$(echo "${_ADDRESS}" | sed -e 's/[^:]//g')"
		 	_LENGTH=$((7-${#_SEPARATOR}))
		 	if [ "${_LENGTH}" -gt 0 ]; then
		 		_SEPARATOR="$(printf ':%.s' $(seq 1 $((_LENGTH+2))) || true)"
		 		_ADDRESS="$(echo "${_ADDRESS}" | sed -e "s/::/${_SEPARATOR}/")"
		 	fi
		 	_OCTETS1="$(echo "${_ADDRESS}" | cut -d ':' -f 1)"
		 	_OCTETS2="$(echo "${_ADDRESS}" | cut -d ':' -f 2)"
		 	_OCTETS3="$(echo "${_ADDRESS}" | cut -d ':' -f 3)"
		 	_OCTETS4="$(echo "${_ADDRESS}" | cut -d ':' -f 4)"
		 	_OCTETS5="$(echo "${_ADDRESS}" | cut -d ':' -f 5)"
		 	_OCTETS6="$(echo "${_ADDRESS}" | cut -d ':' -f 6)"
		 	_OCTETS7="$(echo "${_ADDRESS}" | cut -d ':' -f 7)"
		 	_OCTETS8="$(echo "${_ADDRESS}" | cut -d ':' -f 8)"
		 	# shellcheck disable=SC2059
		 	printf "${_FORMAT}" \
		 	    "0x${_OCTETS1:-"0"}" \
		 	    "0x${_OCTETS2:-"0"}" \
		 	    "0x${_OCTETS3:-"0"}" \
		 	    "0x${_OCTETS4:-"0"}" \
		 	    "0x${_OCTETS5:-"0"}" \
		 	    "0x${_OCTETS6:-"0"}" \
		 	    "0x${_OCTETS7:-"0"}" \
		 	    "0x${_OCTETS8:-"0"}"
		}
		
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
		#funcInstallPackage() {
		#	if command -v apt > /dev/null 2>&1; then
		#		LANG=C apt list "${1:?}" 2> /dev/null | sed -ne '\%^'"$1"'/.*\[installed.*\]%p' || true
		#	elif command -v yum > /dev/null 2>&1; then
		#		LANG=C yum list --installed "${1:?}" 2> /dev/null | sed -ne '/^'"$1"'/p' || true
		#	elif command -v dnf > /dev/null 2>&1; then
		#		LANG=C dnf list --installed "${1:?}" 2> /dev/null | sed -ne '/^'"$1"'/p' || true
		#	elif command -v zypper > /dev/null 2>&1; then
		#		LANG=C zypper se -i "${1:?}" 2> /dev/null | sed -ne '/^[ \t]'"$1"'[ \t]/p' || true
		#	fi
		#}
		
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
		 	# --- change root ---------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "CHGE_ROOT" "${CHGE_ROOT:-}"
		 	# --- screen parameter ----------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "TERM"      "${TERM:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "ROWS_SIZE" "${ROWS_SIZE:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "COLS_SIZE" "${COLS_SIZE:-}"
		 	# --- working directory name ----------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PATH" "${PROG_PATH:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PRAM" "${PROG_PRAM:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_DIRS" "${PROG_DIRS:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_NAME" "${PROG_NAME:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "PROG_PROC" "${PROG_PROC:-}"
		 	# -------------------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_TGET" "${DIRS_TGET:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_ORIG" "${DIRS_ORIG:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_INIT" "${DIRS_INIT:-}"
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
		 	# --- firewalld -----------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "FWAL_ZONE" "${FWAL_ZONE:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "FWAL_NAME" "${FWAL_NAME:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "FWAL_PORT" "${FWAL_PORT:-}"
		 	# --- set system parameter ------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DBGS_FLAG" "${DBGS_FLAG:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_NAME" "${DIST_NAME:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_VERS" "${DIST_VERS:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIST_CODE" "${DIST_CODE:-}"
		 	# --- network parameter ---------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_UADR" "${IPV4_UADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV4_LADR" "${IPV4_LADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_ADDR" "${IPV6_ADDR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_CIDR" "${IPV6_CIDR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_FADR" "${IPV6_FADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_UADR" "${IPV6_UADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_LADR" "${IPV6_LADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "IPV6_RADR" "${IPV6_RADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_ADDR" "${LINK_ADDR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_CIDR" "${LINK_CIDR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_FADR" "${LINK_FADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_UADR" "${LINK_UADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_LADR" "${LINK_LADR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LINK_RADR" "${LINK_RADR:-}"
		 	# --- samba parameter -----------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "SAMB_USER" "${SAMB_USER:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "SAMB_GRUP" "${SAMB_GRUP:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "SAMB_GADM" "${SAMB_GADM:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "LGIN_SHEL" "${LGIN_SHEL:-}"
		 	# --- directory parameter -------------------------------------------------
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_SRVR" "${DIRS_SRVR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_HTML" "${DIRS_HTML:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_TFTP" "${DIRS_TFTP:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_SHAR" "${DIRS_SHAR:-}"
		 	printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "DIRS_USER" "${DIRS_USER:-}"
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
		 	if [ ! -e "${1:-}" ]; then
		 		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "not exist: [${1:-}]"
		 		return
		 	fi
		
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "debug out start: --- [${1:-}] ---"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	cat "${1:-}"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP1}"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "debug out end: --- [${1:-}] ---"
		 	printf "\033[m${PROG_NAME}: %s\033[m\n" "${TEXT_GAP2}"
		}
		
		# --- initialize --------------------------------------------------------------
		funcInitialize() {
		 	__FUNC_NAME="funcInitialize"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- set system parameter ------------------------------------------------
		 	if [ -n "${TERM:-}" ] \
		 	&& command -v tput > /dev/null 2>&1; then
		 		ROWS_SIZE=$(tput lines)
		 		COLS_SIZE=$(tput cols)
		 	fi
		 	if [ "${ROWS_SIZE}" -lt 25 ]; then
		 		ROWS_SIZE=25
		 	fi
		 	if [ "${COLS_SIZE}" -lt 80 ]; then
		 		COLS_SIZE=80
		 	fi
		
		 	readonly ROWS_SIZE
		 	readonly COLS_SIZE
		
		 	TEXT_GAPS="$((COLS_SIZE-${#PROG_NAME}-2))"		# work
		 	TEXT_GAP1="$(funcString "${TEXT_GAPS}" '-')"
		 	TEXT_GAP2="$(funcString "${TEXT_GAPS}" '=')"
		
		 	readonly TEXT_GAP1
		 	readonly TEXT_GAP2
		
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
		 		_FILE_PATH="${DIRS_TGET:-}/etc/network/interfaces"
		 		_WORK_TEXT=""
		 		if [ -e "${_FILE_PATH}" ]; then
		 			_WORK_TEXT="$(sed -ne '/iface[ \t]\+ens160[ \t]\+inet[ \t]\+/ s/^.*\(static\|dhcp\).*$/\1/p' "${_FILE_PATH}")"
		 		fi
		 		case "${_WORK_TEXT:-}" in
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
		#	if [ "${IPV4_DHCP}" = "true" ]; then
		#		NICS_IPV4=""
		#	fi
		 	NICS_IPV4="${NICS_IPV4:-"${IPV4_DUMY}"}"
		 	NICS_DNS4="${NICS_DNS4:-"$(sed -ne 's/^nameserver[ \]\+\([[:alnum:]:.]\+\)[ \t]*$/\1/p' /etc/resolv.conf | sed -e ':l; N; s/\n/,/; b l;')"}"
		 	NICS_GATE="${NICS_GATE:-"$(ip -4 -oneline route list match default | cut -d ' ' -f 3)"}"
		 	NICS_FQDN="${NICS_FQDN:-"$(cat "${DIRS_TGET:-}/etc/hostname")"}"
		 	NICS_HOST="${NICS_HOST:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 1)"}"
		 	NICS_WGRP="${NICS_WGRP:-"$(echo "${NICS_FQDN}." | cut -d '.' -f 2)"}"
		 	NICS_WGRP="${NICS_WGRP:-"$(awk '$1=="search" {print $2;}' "${DIRS_TGET:-}/etc/resolv.conf")"}"
		 	NICS_HOST="$(echo "${NICS_HOST}" | tr '[:upper:]' '[:lower:]')"
		 	NICS_WGRP="$(echo "${NICS_WGRP}" | tr '[:upper:]' '[:lower:]')"
		 	if [ "${NICS_FQDN}" = "${NICS_HOST}" ] && [ -n "${NICS_WGRP}" ]; then
		 		NICS_FQDN="${NICS_HOST}.${NICS_WGRP}"
		 	fi
		
		 	IPV4_UADR="${NICS_IPV4%.*}"
		 	IPV4_LADR="${NICS_IPV4##*.}"
		 	IPV6_ADDR="$(ip -6 -oneline address show primary dev ens160 | sed -ne '/fe80:/! s%^.*[ \t]inet6[ \t]\+\([[:alnum:]/:]\+\)\+[ \t].*$%\1%p')"
		 	IPV6_CIDR="${IPV6_ADDR#*/}"
		 	IPV6_ADDR="${IPV6_ADDR%%/*}"
		 	IPV6_FADR="$(funcIPv6GetFullAddr "${IPV6_ADDR}")"
		 	IPV6_UADR="$(echo "${IPV6_FADR}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
		 	IPV6_LADR="$(echo "${IPV6_FADR}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
		 	IPV6_RADR=""
		 	LINK_ADDR="$(ip -6 -oneline address show primary dev ens160 | sed -ne '/fe80:/ s%^.*[ \t]inet6[ \t]\+\([[:alnum:]/:]\+\)\+[ \t].*$%\1%p')"
		 	LINK_CIDR="${LINK_ADDR#*/}"
		 	LINK_ADDR="${LINK_ADDR%%/*}"
		 	LINK_FADR="$(funcIPv6GetFullAddr "${LINK_ADDR}")"
		 	LINK_UADR="$(echo "${LINK_FADR}" | cut -d ':' -f 1-4 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
		 	LINK_LADR="$(echo "${LINK_FADR}" | cut -d ':' -f 5-8 | sed -e 's/\(^\|:\)0\+/:/g' -e 's/::\+/::/g')"
		 	LINK_RADR=""
		
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
		 		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "** not exist: [$1] **"
		 		mkdir -p "${1%/*}"
		 		_REAL_PATH="$(realpath "${1}")"
		 		if [ ! -e "${_REAL_PATH}" ]; then
		 			mkdir -p "${_REAL_PATH%/*}"
		 		fi
		 		touch "$1"
		#		return
		 	fi
		 	# --- backup --------------------------------------------------------------
		 	___FILE_PATH="${1}"
		 	___BACK_PATH="${1#*"${DIRS_TGET:-}"}"
		 	case "${2:-}" in
		 		samp) ___BACK_PATH="${DIRS_TGET:+"${DIRS_TGET}/"}${DIRS_SAMP}/${___BACK_PATH#/}";;
		 		init) ___BACK_PATH="${DIRS_TGET:+"${DIRS_TGET}/"}${DIRS_INIT}/${___BACK_PATH#/}";;
		 		*   ) ___BACK_PATH="${DIRS_TGET:+"${DIRS_TGET}/"}${DIRS_ORIG}/${___BACK_PATH#/}";;
		 	esac
		 	mkdir -p "${___BACK_PATH%/*}"
		 	if [ -e "${___BACK_PATH}" ]; then
		 		___BACK_PATH="${___BACK_PATH}.$(date +"%Y%m%d%H%M%S")"
		 	fi
		 	if [ -n "${DBGS_FLAG:-}" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "backup: ${___FILE_PATH} -> ${___BACK_PATH}"
		 	fi
		#	if [ -f "$1" ]; then
		 		cp -a "$1" "${___BACK_PATH}"
		#	else
		#		mv "$1" "${___BACK_PATH}"
		#	fi
		
		 	# --- complete ------------------------------------------------------------
		 	if [ -n "${DBGS_FLAG:-}" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${____FUNC_NAME}] ---"
		 	fi
		}
		
		# --- installing missing packages ---------------------------------------------
		# only runs on debian and ubuntu on amd64
		funcInstall_package() {
		 	__FUNC_NAME="funcInstall_package"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v dpkg > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- sources.list --------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/apt/sources.list"
		 	if grep -q '^[ \t]*deb[ \t]\+cdrom:' "${_FILE_PATH}"; then
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		sed -i "${_FILE_PATH}"                     \
		 		    -e '/^[ \t]*deb[ \t]\+cdrom:/ s/^/#/g'
		
		 		# --- debug out -----------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- get architecture ----------------------------------------------------
		 	_MAIN_ARHC="$(dpkg --print-architecture)"
		 	_OTHR_ARCH="$(dpkg --print-foreign-architectures)"
		
		 	# --- preseed or cloud-init -----------------------------------------------
		 	_PAKG_LIST=""
		 	if [ -n "${SEED_FILE:-}" ]; then
		 		case "${SEED_FILE##*/}" in
		 			auto*.xml)		;;	# autoyast
		 			ks*.cfg) 		;;	# kickstart
		 			user-data)			# nocloud
		 				_FILE_PATH="${PROG_DIRS}/user-data"
		 				if [ -e "${_FILE_PATH}" ]; then
		 					_PAKG_LIST="$( \
		 						sed -ne '/^[ \t]*packages:$/,/^[ #]*[[:graph:]]\+:$/ {s/^[ \t]*-[ \t]\+//gp}' "${_FILE_PATH}" | \
		 						sed -e  ':l; N; s/[\r\n]/ /; b l;'                                                            | \
		 						sed -e  's/[ \t]\+/ /g')"
		 				fi
		 				;;
		 			ps*.cfg)			# preseed
		 				_FILE_PATH="${PROG_DIRS}/${SEED_FILE##*/}"
		 				if [ -e "${_FILE_PATH}" ]; then
		 					_PAKG_LIST="$( \
		 						sed -ne '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+.*$%,\%[^\\]$% {s/\\//gp}' "${_FILE_PATH}" | \
		 						sed -e  ':l; N; s/[\r\n]/ /; b l;'                                                          | \
		 						sed -e  's/[ \t]\+/ /g'                                                                     | \
		 						sed -e  's%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+[[:graph:]]\+[ \t]*%%')"
		 				fi
		 				;;
		 			*)	;;
		 		esac;
		 	fi
		
		 	# --- get missing packages ------------------------------------------------
		 	# shellcheck disable=SC2086
		 	_PAKG_FIND="$(LANG=C apt list ${_PAKG_LIST:-"apt"} 2> /dev/null                | \
		 		sed -ne '/[ \t]'"${_OTHR_ARCH:-"i386"}"'[ \t]*/!{'                           \
		 		    -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | \
		 		sed -z 's/[\r\n]\+/ /g')"
		
		 	# --- install missing packages --------------------------------------------
		 	apt-get -qq update
		 	if [ -n "${_PAKG_FIND:-}" ]; then
		 		# shellcheck disable=SC2086
		 		if ! apt-get -qq -y install ${_PAKG_FIND}; then
		 			printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "missing packages installation failure"
		 			printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "${_PAKG_FIND}"
		 		fi
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- creating a shared environment -------------------------------------------
		funcCreate_shared_env() {
		 	__FUNC_NAME="funcCreate_shared_env"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- create system user id -----------------------------------------------
		 	if id "${SAMB_USER}" > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[41m%s\033[m\n" "user exist: [${SAMB_USER}]"
		 	else
		 		printf "\033[m${PROG_NAME}: \033[42m%s\033[m\n" "user create: [${SAMB_USER}]"
		 		if ! grep -qE '^'"${SAMB_GADM}"':' /etc/group; then
		 			groupadd --system "${SAMB_GADM}"
		 		fi
		 		if ! grep -qE '^'"${SAMB_GRUP}"':' /etc/group; then
		 			groupadd --system "${SAMB_GRUP}"
		 		fi
		 		useradd --system --shell "${LGIN_SHEL}" --groups "${SAMB_GRUP}" "${SAMB_USER}"
		 	fi
		
		 	# --- create shared directory ---------------------------------------------
		 	mkdir -p "${DIRS_HGFS}"
		
		 	mkdir -p "${DIRS_HTML}"/html
		 	touch -f "${DIRS_HTML}"/html/index.html
		
		 	mkdir -p "${DIRS_TFTP}"/boot/grub
		 	mkdir -p "${DIRS_TFTP}"/ipxe
		 	mkdir -p "${DIRS_TFTP}"/menu-bios/pxelinux.cfg
		 	mkdir -p "${DIRS_TFTP}"/menu-efi64/pxelinux.cfg
		 	touch -f "${DIRS_TFTP}"/menu-bios/syslinux.cfg
		 	touch -f "${DIRS_TFTP}"/menu-efi64/syslinux.cfg
		 	ln -sf ../conf         "${DIRS_TFTP}"/menu-bios/
		 	ln -sf ../imgs         "${DIRS_TFTP}"/menu-bios/
		 	ln -sf ../isos         "${DIRS_TFTP}"/menu-bios/
		 	ln -sf ../load         "${DIRS_TFTP}"/menu-bios/
		 	ln -sf ../rmak         "${DIRS_TFTP}"/menu-bios/
		 	ln -sf ../syslinux.cfg "${DIRS_TFTP}"/menu-bios/pxelinux.cfg/default
		 	ln -sf ../conf         "${DIRS_TFTP}"/menu-efi64/
		 	ln -sf ../imgs         "${DIRS_TFTP}"/menu-efi64/
		 	ln -sf ../isos         "${DIRS_TFTP}"/menu-efi64/
		 	ln -sf ../load         "${DIRS_TFTP}"/menu-efi64/
		 	ln -sf ../rmak         "${DIRS_TFTP}"/menu-efi64/
		 	ln -sf ../syslinux.cfg "${DIRS_TFTP}"/menu-efi64/pxelinux.cfg/default
		
		 	mkdir -p "${DIRS_SAMB}"/cifs
		 	mkdir -p "${DIRS_SAMB}"/data/adm/netlogon
		 	mkdir -p "${DIRS_SAMB}"/data/adm/profiles
		 	mkdir -p "${DIRS_SAMB}"/data/arc
		 	mkdir -p "${DIRS_SAMB}"/data/bak
		 	mkdir -p "${DIRS_SAMB}"/data/pub
		 	mkdir -p "${DIRS_SAMB}"/data/usr
		 	mkdir -p "${DIRS_SAMB}"/dlna/movies
		 	mkdir -p "${DIRS_SAMB}"/dlna/others
		 	mkdir -p "${DIRS_SAMB}"/dlna/photos
		 	mkdir -p "${DIRS_SAMB}"/dlna/sounds
		
		 	mkdir -p "${DIRS_USER}"/private
		 	mkdir -p "${DIRS_USER}"/share/conf
		 	mkdir -p "${DIRS_USER}"/share/imgs
		 	mkdir -p "${DIRS_USER}"/share/isos
		 	mkdir -p "${DIRS_USER}"/share/load
		 	mkdir -p "${DIRS_USER}"/share/rmak
		
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/conf "${DIRS_HTML}"/html/
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/imgs "${DIRS_HTML}"/html/
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/isos "${DIRS_HTML}"/html/
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/load "${DIRS_HTML}"/html/
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/rmak "${DIRS_HTML}"/html/
		
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/conf "${DIRS_TFTP}"/
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/imgs "${DIRS_TFTP}"/
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/isos "${DIRS_TFTP}"/
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/load "${DIRS_TFTP}"/
		 	ln -sf "${DIRS_USER#"${DIRS_TGET:-}"}"/share/rmak "${DIRS_TFTP}"/
		
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${DIRS_TFTP}/autoexec.ipxe"
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
		
		#	if command -v setsebool > /dev/null 2>&1; then
		#		setsebool -P httpd_use_fusefs 1
		#		setsebool -P samba_enable_home_dirs 1
		#		setsebool -P samba_export_all_ro 1
		#		setsebool -P samba_export_all_rw 1
		#	fi
		
		 	touch -f "${DIRS_SAMB}"/data/adm/netlogon/logon.bat
		 	chown -R "${SAMB_USER}":"${SAMB_GRUP}" "${DIRS_SAMB}/"*
		 	chmod -R  770 "${DIRS_SAMB}/"*
		 	chmod    1777 "${DIRS_SAMB}/data/adm/profiles"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${DIRS_HTML}/html/index.html"
		 		"Hello, world!" from ${NICS_HOST}
		_EOT_
		
		 	# --- symlink for html ----------------------------------------------------
		#	_WORK_PATH="${DIRS_TGET:-}/var/www/html"
		#	funcFile_backup "${_WORK_PATH}"
		#	ln -sf "${DIRS_HTML#${DIRS_TGET:-}}" "${_WORK_PATH}"
		
		 	# --- symlink for tftp ----------------------------------------------------
		#	_WORK_PATH="${DIRS_TGET:-}/var/lib/tftpboot"
		#	funcFile_backup "${_WORK_PATH}"
		#	ln -sf "${DIRS_TFTP#${DIRS_TGET:-}}" "${_WORK_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcFile_backup "${DIRS_SRVR:?}" "init"
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- apparmor settings -------------------------------------------------------
		funcSetupConfig_apparmor() {
		 	__FUNC_NAME="funcSetupConfig_apparmor"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v aa-enabled > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_NAME="apparmor.service"
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- debug out -----------------------------------------------------------
		#	aa-enabled
		 	aa-status || true
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- selinux settings --------------------------------------------------------
		funcSetupConfig_selinux() {
		 	__FUNC_NAME="funcSetupConfig_selinux"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v semanage > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- httpd ---------------------------------------------------------------
		 	semanage fcontext -a -t httpd_sys_content_t "${DIRS_HTML}(/.*)?"
		 	restorecon -R -v "${DIRS_HTML}"
		
		 	# --- tftp ----------------------------------------------------------------
		 	semanage fcontext -a -t tftpdir_t "${DIRS_TFTP}(/.*)?"
		 	restorecon -R -v "${DIRS_TFTP}"
		
		 	# --- samba ---------------------------------------------------------------
		 	semanage fcontext -a -t samba_share_t "${DIRS_SAMB}(/.*)?"
		 	restorecon -R -v "${DIRS_SAMB}"
		
		 	# --- setsebool -----------------------------------------------------------
		 	if command -v setsebool > /dev/null 2>&1; then
		 		setsebool -P httpd_use_fusefs 1
		#		setsebool -P samba_enable_home_dirs 1
		 		setsebool -P samba_export_all_ro 1
		#		setsebool -P samba_export_all_rw 1
		 	fi
		
		 	# --- debug out -----------------------------------------------------------
		 	getenforce
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
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
		
		 	# --- main.conf -----------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/connman/main.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 		
		 		# Generated by user script
		 		AllowHostnameUpdates = false
		 		AllowDomainnameUpdates = false
		 		PreferredTechnologies = ethernet,wifi
		 		SingleConnectedTechnology = true
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- disable_dns_proxy.conf ----------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/systemd/system/connman.service.d/disable_dns_proxy.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	_WORK_TEXT="$(command -v connmand 2> /dev/null)"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		[Service]
		 		ExecStart=
		 		ExecStart=${_WORK_TEXT} -n --nodnsproxy
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- settings ------------------------------------------------------------
		#	_FILE_PATH="${DIRS_TGET:-}/var/lib/connman/settings"
		#	funcFile_backup "${_FILE_PATH}"
		#	mkdir -p "${_FILE_PATH%/*}"
		#	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		#		[global]
		#		OfflineMode=false
		#		
		#		[Wired]
		#		Enable=true
		#		Tethering=false
		#_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		#	funcDebugout_file "${_FILE_PATH}"
		#	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- configures ----------------------------------------------------------
		 	_WORK_TEXT="$(echo "${NICS_MADR}" | sed -e 's/://g')"
		 	_FILE_PATH="${DIRS_TGET:-}/var/lib/connman/ethernet_${_WORK_TEXT}_cable/settings"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
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
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_NAME="connman.service"
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NAME}"
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
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			network:
		 			  version: 2
		 			  renderer: NetworkManager
		_EOT_
		 		chmod 600 "${_FILE_PATH}"
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		
		 		# --- 99-disable-network-config.cfg -----------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
		 		if [ -d "${_FILE_PATH%/*}/." ]; then
		 			funcFile_backup "${_FILE_PATH}"
		 			mkdir -p "${_FILE_PATH%/*}"
		 			cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 				network: {config: disabled}
		_EOT_
		 			# --- debug out ---------------------------------------------------
		 			funcDebugout_file "${_FILE_PATH}"
		 			funcFile_backup   "${_FILE_PATH}" "init"
		 		fi
		 	else
		 		_FILE_PATH="${DIRS_TGET:-}/etc/netplan/99-network-config-${NICS_NAME}.yaml"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
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
		 		funcFile_backup   "${_FILE_PATH}" "init"
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
		 	case "${DIST_NAME:-}" in
		 		debian | ubuntu ) _FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/system-connections/Wired connection 1";;
		 		*               ) _FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/system-connections/${NICS_NAME}.nmconnection";;
		 	esac
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	if [ "${IPV4_DHCP}" = "true" ]; then
		 		if ! nmcli --offline connection add type ethernet \
		 			connection.id "${_FILE_PATH##*/}" \
		 			connection.interface-name "${NICS_NAME}" \
		 			connection.autoconnect true \
		 			connection.zone "${FWAL_ZONE}" \
		 			ethernet.wake-on-lan 0 \
		 			ethernet.mac-address "${NICS_MADR}" \
		 			ipv4.method auto \
		 			ipv6.method auto \
		 			ipv6.addr-gen-mode default \
		 		> "${_FILE_PATH}"; then
		 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 				[connection]
		 				id=${_FILE_PATH##*/}
		 				type=ethernet
		 				interface-name=${NICS_NAME}
		 				autoconnect=true
		 				zone=${FWAL_ZONE}
		 				
		 				[ethernet]
		 				wake-on-lan=0
		 				mac-address=${NICS_MADR}
		 				
		 				[ipv4]
		 				method=auto
		 				
		 				[ipv6]
		 				method=auto
		 				addr-gen-mode=default
		 				
		 				[proxy]
		_EOT_
		 		fi
		 	else
		 		if ! nmcli --offline connection add type ethernet \
		 			connection.id "${_FILE_PATH##*/}" \
		 			connection.interface-name "${NICS_NAME}" \
		 			connection.autoconnect true \
		 			connection.zone "${FWAL_ZONE}" \
		 			ethernet.wake-on-lan 0 \
		 			ethernet.mac-address "${NICS_MADR}" \
		 			ipv4.method manual \
		 			ipv4.address "${NICS_IPV4}/${NICS_BIT4}" \
		 			ipv4.gateway "${NICS_GATE}" \
		 			ipv4.dns "${NICS_DNS4}" \
		 			ipv6.method auto \
		 			ipv6.addr-gen-mode default \
		 		> "${_FILE_PATH}"; then
		 			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 				[connection]
		 				id=${_FILE_PATH##*/}
		 				type=ethernet
		 				interface-name=${NICS_NAME}
		 				autoconnect=true
		 				zone=${FWAL_ZONE}
		 				
		 				[ethernet]
		 				wake-on-lan=0
		 				mac-address=${NICS_MADR}
		 				
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
		 	fi
		 	chown root:root "${_FILE_PATH}"
		 	chmod 600 "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- dns.conf ------------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/NetworkManager/conf.d/dns.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	if command -v resolvectl > /dev/null 2>&1; then
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			[main]
		 			dns=systemd-resolved
		_EOT_
		 	elif command -v dnsmasq > /dev/null 2>&1; then
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			[main]
		 			dns=dnsmasq
		_EOT_
		 	fi
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_NAME="NetworkManager.service"
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "enabled" ]; then
		 		_SRVC_OTHR="systemd-networkd.service"
		 		_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_OTHR}")"
		 		if [ "${_SRVC_STAT}" = "enabled" ]; then
		 			printf "\033[m${PROG_NAME}: %s\033[m\n" "service mask   : ${_SRVC_OTHR}"
		 			systemctl --quiet mask "${_SRVC_OTHR}"
		 			systemctl --quiet mask "${_SRVC_OTHR%.*}.socket"
		 		fi
		 	fi
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NAME}"
		 		nmcli connection reload
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
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	echo "${NICS_FQDN:-}" > "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
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
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
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
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup hosts.allow/hosts.deny ------------------------------------
		#funcSetupNetwork_hosts_access() {
		#	__FUNC_NAME="funcSetupNetwork_hosts_access"
		#	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		#
		#	# --- hosts ---------------------------------------------------------------
		#	_FILE_PATH="${DIRS_TGET:-}/etc/hosts.allow"
		#	funcFile_backup "${_FILE_PATH}"
		#	mkdir -p "${_FILE_PATH%/*}"
		#	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		#		ALL : ${IPV4_LHST}
		#		ALL : [${IPV6_LHST}]
		#		ALL : ${IPV4_UADR}.0/${NICS_BIT4}
		#		ALL : [${LINK_UADR%%::}::%${NICS_NAME}]/10
		#		#ALL : [${IPV6_UADR%%::}::]/${IPV6_CIDR}
		#_EOT_
		#
		#	# --- debug out -----------------------------------------------------------
		#	funcDebugout_file "${_FILE_PATH}"
		#	funcFile_backup   "${_FILE_PATH}" "init"
		#
		#	# --- hosts ---------------------------------------------------------------
		#	_FILE_PATH="${DIRS_TGET:-}/etc/hosts.deny"
		#	funcFile_backup "${_FILE_PATH}"
		#	mkdir -p "${_FILE_PATH%/*}"
		#	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		#		ALL : ALL
		#_EOT_
		#
		#	# --- debug out -----------------------------------------------------------
		#	funcDebugout_file "${_FILE_PATH}"
		#	funcFile_backup   "${_FILE_PATH}" "init"
		#
		#	# --- complete ------------------------------------------------------------
		#	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		#}
		
		# --- network setup firewalld -------------------------------------------------
		funcSetupNetwork_firewalld() {
		 	__FUNC_NAME="funcSetupNetwork_firewalld"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		  
		 	# --- check command -------------------------------------------------------
		 	if ! command -v firewall-cmd > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- firewalld.service ---------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/lib/systemd/system/firewalld.service"
		 	if [ ! -e "${_FILE_PATH}" ]; then
		 		_FILE_PATH="${DIRS_TGET:-}/usr/lib/systemd/system/firewalld.service"
		 	fi
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	sed -i "${_FILE_PATH}" \
		 	    -e '/\[Unit\]/,/\[.*\]/                {' \
		 	    -e '/^Before=network-pre.target$/ s/^/#/' \
		 	    -e '/^Wants=network-pre.target$/  s/^/#/' \
		 	    -e '                                   }'
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- firewalld -----------------------------------------------------------
		 	# memo: log output settings : firewall-cmd --set-log-denied=all
		 	#       service name output ; firewall-cmd --get-services
		 	#       setting value output: firewall-cmd --list-all --zone=home_use
		 	_FILE_PATH="${DIRS_TGET:-}/etc/firewalld/zones/${FWAL_ZONE}.xml"
		 	_WORK_PATH="${DIRS_TGET:-}/lib/firewalld/zones/drop.xml"
		 	if [ ! -e "${_WORK_PATH}" ]; then
		 		_WORK_PATH="${DIRS_TGET:-}/usr/lib/firewalld/zones/drop.xml"
		 	fi
		 	cp -a "${_WORK_PATH}" "${_FILE_PATH}"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	_IPV4_ADDR="${IPV4_UADR}.0/${NICS_BIT4}"
		 	_IPV6_ADDR="${IPV6_UADR%%::}::/${IPV6_CIDR}"
		 	_LINK_ADDR="${LINK_UADR%%::}::/10"
		 	_SRVC_NAME="firewalld.service"
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service active: ${_SRVC_NAME}"
		 		firewall-cmd --quiet --set-default-zone="${FWAL_ZONE}" || true
		 		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --change-interface="${NICS_NAME}" || true
		 		for _FWAL_NAME in ${FWAL_NAME}
		 		do
		 			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
		#			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
		 			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
		 		done
		 		for _FWAL_PORT in ${FWAL_PORT}
		 		do
		 			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
		#			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
		 			firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
		 		done
		 		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" protocol value="icmp"      accept'
		#		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" protocol value="ipv6-icmp" accept'
		 		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" protocol value="ipv6-icmp" accept'
		 		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		 		firewall-cmd --quiet --permanent --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
		 		firewall-cmd --quiet --reload
		 		firewall-cmd --get-zone-of-interface="${NICS_NAME}"
		 		firewall-cmd --list-all --zone="${FWAL_ZONE}"
		 	else
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service inactive: ${_SRVC_NAME}"
		 		firewall-offline-cmd --quiet --set-default-zone="${FWAL_ZONE}" || true
		 		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --change-interface="${NICS_NAME}" || true
		 		for _FWAL_NAME in ${FWAL_NAME}
		 		do
		 			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
		#			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
		 			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" service name="'"${_FWAL_NAME}"'" accept' || true
		 		done
		 		for _FWAL_PORT in ${FWAL_PORT}
		 		do
		 			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
		#			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
		 			firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" port protocol="'"${_FWAL_PORT##*/}"'" port="'"${_FWAL_PORT%/*}"'" accept' || true
		 		done
		 		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="'"${_IPV4_ADDR}"'" protocol value="icmp"      accept'
		#		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_IPV6_ADDR}"'" protocol value="ipv6-icmp" accept'
		 		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv6" source address="'"${_LINK_ADDR}"'" protocol value="ipv6-icmp" accept'
		 		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" service name="tftp" accept' || true
		 		firewall-offline-cmd --quiet --zone="${FWAL_ZONE}" --add-rich-rule='rule family="ipv4" source address="0.0.0.0" port protocol="udp" port="67-68" accept' || true
		#		firewall-offline-cmd --quiet --reload
		 		firewall-offline-cmd --get-zone-of-interface="${NICS_NAME}"
		 		firewall-offline-cmd --list-all --zone="${FWAL_ZONE}"
		 	fi
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
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
		
		 	# --- dnsmasq.service -----------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/lib/systemd/system/dnsmasq.service"
		 	if [ ! -e "${_FILE_PATH}" ]; then
		 		_FILE_PATH="${DIRS_TGET:-}/usr/lib/systemd/system/dnsmasq.service"
		 	fi
		 	if [ -e "${_FILE_PATH}" ]; then
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		sed -i "${_FILE_PATH}"                    \
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
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- dnsmasq -------------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/default/dnsmasq"
		 	if [ -e "${_FILE_PATH}" ]; then
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		sed -i "${_FILE_PATH}"                         \
		 		    -e 's/^#\(IGNORE_RESOLVCONF\)=.*$/\1=yes/' \
		 		    -e 's/^#\(DNSMASQ_EXCEPT\)=.*$/\1="lo"/'
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- default.conf --------------------------------------------------------
		 	_CONF_FILE="$(find "${DIRS_TGET:-}/etc/dnsmasq.d" "${DIRS_TGET:-}/usr/share" -name 'trust-anchors.conf' -type f)"
		 	_CONF_FILE="${_CONF_FILE#"${DIRS_TGET:-}"}"
		 	_FILE_PATH="${DIRS_TGET:-}/etc/dnsmasq.d/default.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		# --- log ---------------------------------------------------------------------
		 		#log-queries                                                # dns query log output
		 		#log-dhcp                                                   # dhcp transaction log output
		 		#log-facility=                                              # log output file name
		 		
		 		# --- dns ---------------------------------------------------------------------
		 		#port=0                                                     # listening port
		 		#bogus-priv                                                 # do not perform reverse lookup of private ip address on upstream server
		 		#domain-needed                                              # do not forward plain names
		 		#domain=${NICS_WGRP}                                           # local domain name
		 		#expand-hosts                                               # add domain name to host
		 		#filterwin2k                                                # filter for windows
		 		interface=${NICS_NAME}                                            # listen to interface
		 		#listen-address=${IPV4_LHST}                                   # listen to ip address
		 		#listen-address=${IPV6_LHST}                                         # listen to ip address
		 		#listen-address=${NICS_IPV4}                                 # listen to ip address
		 		#listen-address=${LINK_ADDR}                    # listen to ip address
		 		#server=${NICS_DNS4}                                       # directly specify upstream server
		 		#server=8.8.8.8                                             # directly specify upstream server
		 		#server=8.8.4.4                                             # directly specify upstream server
		 		#no-hosts                                                   # don't read the hostnames in /etc/hosts
		 		#no-poll                                                    # don't poll /etc/resolv.conf for changes
		 		#no-resolv                                                  # don't read /etc/resolv.conf
		 		#strict-order                                               # try in the registration order of /etc/resolv.conf
		 		#bind-dynamic                                               # enable bind-interfaces and the default hybrid network mode
		 		bind-interfaces                                             # enable multiple instances of dnsmasq
		 		#conf-file=${_CONF_FILE}       # enable dnssec validation and caching
		 		#dnssec                                                     # "
		 		
		 		# --- dhcp --------------------------------------------------------------------
		 		dhcp-range=${NICS_IPV4%.*}.0,proxy,24                             # proxy dhcp
		 		#dhcp-range=${NICS_IPV4%.*}.64,${NICS_IPV4%.*}.79,12h                   # dhcp range
		 		#dhcp-option=option:netmask,255.255.255.0                   #  1 netmask
		 		#dhcp-option=option:router,${NICS_GATE}                    #  3 router
		 		#dhcp-option=option:dns-server,${NICS_IPV4},${NICS_GATE}    #  6 dns-server
		 		#dhcp-option=option:domain-name,${NICS_WGRP}                   # 15 domain-name
		 		#dhcp-option=option:28,${NICS_IPV4%.*}.255                        # 28 broadcast
		 		#dhcp-option=option:ntp-server,${NTPS_IPV4}               # 42 ntp-server
		 		#dhcp-option=option:tftp-server,${NICS_IPV4}                 # 66 tftp-server
		 		#dhcp-option=option:bootfile-name,                          # 67 bootfile-name
		 		dhcp-no-override                                            # disable re-use of the dhcp servername and filename fields as extra option space
		 		
		 		# --- dnsmasq manual page -----------------------------------------------------
		 		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
		 		
		 		# --- eof ---------------------------------------------------------------------
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- pxeboot.conf --------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		#log-queries                                                # dns query log output
		 		#log-dhcp                                                   # dhcp transaction log output
		 		#log-facility=                                              # log output file name
		 		
		 		# --- tftp --------------------------------------------------------------------
		 		#enable-tftp=${NICS_NAME}                                         # enable tftp server
		 		#tftp-root=${DIRS_TFTP}                                        # tftp root directory
		 		#tftp-lowercase                                             # convert tftp request path to all lowercase
		 		#tftp-no-blocksize                                          # stop negotiating "block size" option
		 		#tftp-no-fail                                               # do not abort startup even if tftp directory is not accessible
		 		#tftp-secure                                                # enable tftp secure mode
		 		
		 		# --- syslinux block ----------------------------------------------------------
		 		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		 		#pxe-service=x86PC            , "PXEBoot-x86PC"            , menu-bios/lpxelinux.0       #  0 Intel x86PC
		 		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , menu-efi64/syslinux.efi     #  7 EFI BC
		 		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , menu-efi64/syslinux.efi     #  9 EFI x86-64
		 		
		 		# --- grub block --------------------------------------------------------------
		 		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		 		#pxe-service=x86PC            , "PXEBoot-x86PC"            , boot/grub/pxelinux.0        #  0 Intel x86PC
		 		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , boot/grub/bootnetx64.efi    #  7 EFI BC
		 		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , boot/grub/bootnetx64.efi    #  9 EFI x86-64
		 		
		 		# --- ipxe block --------------------------------------------------------------
		 		#dhcp-match=set:iPXE,175                                                                 #
		 		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		 		#pxe-service=tag:iPXE ,x86PC  , "PXEBoot-x86PC"            , /autoexec.ipxe              #  0 Intel x86PC (iPXE)
		 		#pxe-service=tag:!iPXE,x86PC  , "PXEBoot-x86PC"            , ipxe/undionly.kpxe          #  0 Intel x86PC
		 		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , ipxe/ipxe.efi               #  7 EFI BC
		 		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , ipxe/ipxe.efi               #  9 EFI x86-64
		 		
		 		# --- pxe boot ----------------------------------------------------------------
		 		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		 		#pxe-service=x86PC            , "PXEBoot-x86PC"            ,                             #  0 Intel x86PC
		 		#pxe-service=PC98             , "PXEBoot-PC98"             ,                             #  1 NEC/PC98
		 		#pxe-service=IA64_EFI         , "PXEBoot-IA64_EFI"         ,                             #  2 EFI Itanium
		 		#pxe-service=Alpha            , "PXEBoot-Alpha"            ,                             #  3 DEC Alpha
		 		#pxe-service=Arc_x86          , "PXEBoot-Arc_x86"          ,                             #  4 Arc x86
		 		#pxe-service=Intel_Lean_Client, "PXEBoot-Intel_Lean_Client",                             #  5 Intel Lean Client
		 		#pxe-service=IA32_EFI         , "PXEBoot-IA32_EFI"         ,                             #  6 EFI IA32
		 		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           ,                             #  7 EFI BC
		 		#pxe-service=Xscale_EFI       , "PXEBoot-Xscale_EFI"       ,                             #  8 EFI Xscale
		 		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       ,                             #  9 EFI x86-64
		 		#pxe-service=ARM32_EFI        , "PXEBoot-ARM32_EFI"        ,                             # 10 ARM 32bit
		 		#pxe-service=ARM64_EFI        , "PXEBoot-ARM64_EFI"        ,                             # 11 ARM 64bit
		 		
		 		# --- dnsmasq manual page -----------------------------------------------------
		 		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
		 		
		 		# --- eof ---------------------------------------------------------------------
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- create sample file --------------------------------------------------
		 	for _WORK_TEXT in "syslinux block" "grub block" "ipxe block"
		 	do
		 		_FILE_PATH="${DIRS_TGET:+"${DIRS_TGET}/"}${DIRS_SAMP}/etc/dnsmasq.d/pxeboot_${_WORK_TEXT%% *}.conf"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		sed -ne '/^# --- tftp ---/,/^$/              {' \
		 		    -ne '/^# ---/p'                             \
		 		    -ne '/enable-tftp=/              s/^#//p'   \
		 		    -ne '/tftp-root=/                s/^#//p }' \
		 		    -ne '/^# --- '"${_WORK_TEXT}"' ---/,/^$/ {' \
		 		    -ne '/^# ---/p'                             \
		 		    -ne '/^# ---/!                   s/^#//gp}' \
		 		    "${DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf" \
		 		> "${_FILE_PATH}"
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 	done
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_NAME="dnsmasq.service"
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		 }
		
		# --- network setup resolv.conf -----------------------------------------------
		funcSetupNetwork_resolv() {
		 	__FUNC_NAME="funcSetupNetwork_resolv"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v resolvectl > /dev/null 2>&1; then
		 		# --- resolv.conf -----------------------------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/resolv.conf"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			# Generated by user script
		 			search ${NICS_WGRP}
		 			nameserver ${IPV6_LHST}
		 			nameserver ${IPV4_LHST}
		_EOT_
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	else
		 		# --- resolv.conf -> /run/systemd/resolve/stub-resolv.conf ------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/resolv.conf"
		 		funcFile_backup "${_FILE_PATH}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		rm -f "${_FILE_PATH}"
		 		_WORK_PATH="${DIRS_TGET:-}/run/systemd/resolve/stub-resolv.conf"
		 		ln -sfr "${_WORK_PATH}" "${_FILE_PATH}"
		 		if [ ! -e "${_WORK_PATH}" ]; then
		 			mkdir -p "${_WORK_PATH%/*}"
		 			touch "${_WORK_PATH}"
		 		fi
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 		funcFile_backup   "${_WORK_PATH}" "init"
		
		 		# --- default.conf ----------------------------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/systemd/resolved.conf.d/default.conf"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			[Resolve]
		 			DNS=${NICS_DNS4}
		 			Domains=${NICS_WGRP}
		_EOT_
		#		_FILE_PATH="${DIRS_TGET:-}/etc/systemd/resolved.conf"
		#		if ! grep -qE '^DNS=' "${_FILE_PATH}"; then
		#			sed -i "${_FILE_PATH}"                       \
		#			    -e '/^\[Resolve\]$/a DNS='"${IPV4_LHST}"
		#		fi
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		
		 		# --- systemctl avahi-daemon.service ----------------------------------
		 		_SRVC_NAME="avahi-daemon.service"
		 		_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 		if [ "${_SRVC_STAT}" = "enabled" ]; then
		 			systemctl --quiet mask "${_SRVC_NAME}"
		 			systemctl --quiet mask "${_SRVC_NAME%.*}.socket"
		 		fi
		
		 		# --- systemctl systemd-resolved.service ------------------------------
		 		_SRVC_NAME="systemd-resolved.service"
		 		_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 		case "${_SRVC_STAT}" in
		 			disabled) systemctl --quiet enable "${_SRVC_NAME}";;
		#			masked  ) systemctl --quiet unmask "${_SRVC_NAME}"; systemctl --quiet enable "${_SRVC_NAME}";;
		 			*) ;;
		 		esac
		 		_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 		if [ "${_SRVC_STAT}" = "active" ]; then
		 			printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 			systemctl --quiet daemon-reload
		 			systemctl --quiet restart "${_SRVC_NAME}"
		 		fi
		 		if [ -n "${DBGS_FLAG:-}" ]; then
		 			resolvectl status || true
		 		fi
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup apache ----------------------------------------------------
		funcSetupNetwork_apache() {
		 	__FUNC_NAME="funcSetupNetwork_apache"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check service -------------------------------------------------------
		 	if   [ -e "${DIRS_TGET:-}/lib/systemd/system/apache2.service"     ] \
		 	||   [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/apache2.service" ]; then
		 		_SRVC_NAME="apache2.service"
		 	elif [ -e "${DIRS_TGET:-}/lib/systemd/system/httpd.service"       ] \
		 	||   [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/httpd.service"   ]; then
		 		_SRVC_NAME="httpd.service"
		 	else
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "not-found" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- apache2.conf / httpd.conf -------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/${_SRVC_NAME%%.*}/sites-available/999-site.conf"
		 	if [ -d "${_FILE_PATH%/*}" ]; then
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		sed -e 's%^\([ \t]\+DocumentRoot[ \t]\+\).*$%\1'"${DIRS_HTML}"/html'%'      \
		 		    "${DIRS_TGET:-}/etc/${_SRVC_NAME%%.*}/sites-available/000-default.conf" \
		 		> "${_FILE_PATH}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			<Directory ${DIRS_HTML}/>
		 			 	Options Indexes FollowSymLinks
		 			 	AllowOverride None
		 			 	Require all granted
		 			</Directory>
		_EOT_
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		
		 		# --- registration ----------------------------------------------------
		 		a2dissite 000-default
		 		a2ensite "${_FILE_PATH##*/}"
		 	else
		 		_FILE_PATH="${DIRS_TGET:-}/etc/${_SRVC_NAME%%.*}/conf.d/site.conf"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			<VirtualHost *:80>
		 			 	ServerAdmin webmaster@localhost
		 			 	DocumentRoot ${DIRS_HTML}/html
		 			#	ErrorLog \${APACHE_LOG_DIR}/error.log
		 			#	CustomLog \${APACHE_LOG_DIR}/access.log combined
		 			</VirtualHost>
		 			
		 			<Directory ${DIRS_HTML}/>
		 			 	Options Indexes FollowSymLinks
		 			 	AllowOverride None
		 			 	Require all granted
		 			</Directory>
		_EOT_
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup samba -----------------------------------------------------
		funcSetupNetwork_samba() {
		 	__FUNC_NAME="funcSetupNetwork_samba"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check service -------------------------------------------------------
		 	if   { [ -e "${DIRS_TGET:-}/lib/systemd/system/smbd.service"     ]    \
		 	&&     [ -e "${DIRS_TGET:-}/lib/systemd/system/nmbd.service"     ]; } \
		 	||   { [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/smbd.service" ]    \
		 	&&     [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/nmbd.service" ]; }; then
		 		_SRVC_SMBD="smbd.service"
		 		_SRVC_NMBD="nmbd.service"
		 	elif { [ -e "${DIRS_TGET:-}/lib/systemd/system/smb.service"     ]    \
		 	&&     [ -e "${DIRS_TGET:-}/lib/systemd/system/nmb.service"     ]; } \
		 	||   { [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/smb.service" ]    \
		 	&&     [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/nmb.service" ]; }; then
		 		_SRVC_SMBD="smb.service"
		 		_SRVC_NMBD="nmb.service"
		 	else
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_SMBD}")"
		 	if [ "${_SRVC_STAT}" = "not-found" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NMBD}")"
		 	if [ "${_SRVC_STAT}" = "not-found" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v pdbedit > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- create passdb.tdb ---------------------------------------------------
		 	pdbedit -L > /dev/null
		#	_SAMB_PWDB="$(find /var/lib/samba/ -name 'passdb.tdb' \( -type f -o -type l \))"
		
		 	# --- nsswitch.conf -------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/nsswitch.conf"
		 	if [ -e "${_FILE_PATH}" ]; then
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		_WORK_TEXT="wins mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns6"
		 		sed -i "${_FILE_PATH}"            \
		 		    -e '/^hosts:[ \t]\+/       {' \
		 		    -e 's/\(files\).*$/\1/'       \
		 		    -e 's/$/ '"${_WORK_TEXT}"'/}'
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- smb.conf ------------------------------------------------------------
		 	# https://www.samba.gr.jp/project/translation/current/htmldocs/manpages/smb.conf.5.html
		 	_WORK_PATH="${DIRS_TGET:-}/tmp/smb.conf.work"
		 	_FILE_PATH="${DIRS_TGET:-}/etc/samba/smb.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		
		 	# --- global settings section ---------------------------------------------
		 	# allow insecure wide links = Yes
		 	testparm -s -v                                                                  | \
		 	sed -ne '/^\[global\]$/,/^[ \t]*$/                                             {' \
		 	    -e  '/^[ \t]*acl check permissions[ \t]*=/        s/^/#/'                     \
		 	    -e  '/^[ \t]*allocation roundup size[ \t]*=/      s/^/#/'                     \
		 	    -e  '/^[ \t]*allow nt4 crypto[ \t]*=/             s/^/#/'                     \
		 	    -e  '/^[ \t]*blocking locks[ \t]*=/               s/^/#/'                     \
		 	    -e  '/^[ \t]*client NTLMv2 auth[ \t]*=/           s/^/#/'                     \
		 	    -e  '/^[ \t]*client lanman auth[ \t]*=/           s/^/#/'                     \
		 	    -e  '/^[ \t]*client plaintext auth[ \t]*=/        s/^/#/'                     \
		 	    -e  '/^[ \t]*client schannel[ \t]*=/              s/^/#/'                     \
		 	    -e  '/^[ \t]*client use spnego principal[ \t]*=/  s/^/#/'                     \
		 	    -e  '/^[ \t]*client use spnego[ \t]*=/            s/^/#/'                     \
		 	    -e  '/^[ \t]*copy[ \t]*=/                         s/^/#/'                     \
		 	    -e  '/^[ \t]*domain logons[ \t]*=/                s/^/#/'                     \
		 	    -e  '/^[ \t]*enable privileges[ \t]*=/            s/^/#/'                     \
		 	    -e  '/^[ \t]*encrypt passwords[ \t]*=/            s/^/#/'                     \
		 	    -e  '/^[ \t]*idmap backend[ \t]*=/                s/^/#/'                     \
		 	    -e  '/^[ \t]*idmap gid[ \t]*=/                    s/^/#/'                     \
		 	    -e  '/^[ \t]*idmap uid[ \t]*=/                    s/^/#/'                     \
		 	    -e  '/^[ \t]*lanman auth[ \t]*=/                  s/^/#/'                     \
		 	    -e  '/^[ \t]*lsa over netlogon[ \t]*=/            s/^/#/'                     \
		 	    -e  '/^[ \t]*nbt client socket address[ \t]*=/    s/^/#/'                     \
		 	    -e  '/^[ \t]*null passwords[ \t]*=/               s/^/#/'                     \
		 	    -e  '/^[ \t]*raw NTLMv2 auth[ \t]*=/              s/^/#/'                     \
		 	    -e  '/^[ \t]*reject md5 clients[ \t]*=/           s/^/#/'                     \
		 	    -e  '/^[ \t]*server schannel require seal[ \t]*=/ s/^/#/'                     \
		 	    -e  '/^[ \t]*server schannel[ \t]*=/              s/^/#/'                     \
		 	    -e  '/^[ \t]*syslog only[ \t]*=/                  s/^/#/'                     \
		 	    -e  '/^[ \t]*syslog[ \t]*=/                       s/^/#/'                     \
		 	    -e  '/^[ \t]*unicode[ \t]*=/                      s/^/#/'                     \
		 	    -e  '/^[ \t]*winbind separator[ \t]*=/            s/^/#/'                     \
		 	    -e  '/^[ \t]*allow insecure wide links[ \t]*=/    s/=.*$/= Yes/'              \
		 	    -e  '/^[ \t]*dos charset[ \t]*=/                  s/=.*$/= CP932/'            \
		 	    -e  '/^[ \t]*unix password sync[ \t]*=/           s/=.*$/= No/'               \
		 	    -e  '/^[ \t]*netbios name[ \t]*=/                 s/=.*$/= '"${NICS_HOST}"'/' \
		 	    -e  '/^[ \t]*workgroup[ \t]*=/                    s/=.*$/= '"${NICS_WGRP}"'/' \
		 	    -e  '/^[ \t]*interfaces[ \t]*=/                   s/=.*$/= '"${NICS_NAME}"'/' \
		 	    -e  'p                                                                     }' \
		 	> "${_WORK_PATH}"
		
		 	# --- shared settings section ---------------------------------------------
		 	# wide links = Yes
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_WORK_PATH}"
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
		 		        path = ${DIRS_SAMB}/data/adm/netlogon
		 		        valid users = @${SAMB_GRUP}
		 		        write list = @${SAMB_GADM}
		 		[profiles]
		 		        browseable = No
		 		        comment = User profiles
		 		        path = ${DIRS_SAMB}/data/adm/profiles
		 		        valid users = @${SAMB_GRUP}
		 		        write list = @${SAMB_GRUP}
		 		[share]
		 		        browseable = No
		 		        comment = Shared directories
		 		        path = ${DIRS_SAMB}
		 		        valid users = @${SAMB_GADM}
		 		[cifs]
		 		        browseable = No
		 		        comment = CIFS directories
		 		        create mask = 0770
		 		        directory mask = 0770
		 		        force group = ${SAMB_GRUP}
		 		        force user = ${SAMB_USER}
		 		        path = ${DIRS_SAMB}/cifs
		 		        valid users = @${SAMB_GADM}
		 		        write list = @${SAMB_GADM}
		 		[data]
		 		        browseable = No
		 		        comment = Data directories
		 		        create mask = 0770
		 		        directory mask = 0770
		 		        force group = ${SAMB_GRUP}
		 		        force user = ${SAMB_USER}
		 		        path = ${DIRS_SAMB}/data
		 		        valid users = @${SAMB_GADM}
		 		        write list = @${SAMB_GADM}
		 		[dlna]
		 		        browseable = No
		 		        comment = DLNA directories
		 		        create mask = 0770
		 		        directory mask = 0770
		 		        force group = ${SAMB_GRUP}
		 		        force user = ${SAMB_USER}
		 		        path = ${DIRS_SAMB}/dlna
		 		        valid users = @${SAMB_GRUP}
		 		        write list = @${SAMB_GRUP}
		 		[pub]
		 		        comment = Public directories
		 		        path = ${DIRS_SAMB}/data/pub
		 		        valid users = @${SAMB_GRUP}
		 		[lhome]
		 		        comment = Linux /home directories
		 		        path = /home
		 		        valid users = @${SAMB_GRUP}
		 		[html-share]
		 		        comment = HTML shared directories
		 		        guest ok = Yes
		 		        path = ${DIRS_HTML}
		 		        wide links = Yes
		 		[tftp-share]
		 		        comment = TFTP shared directories
		 		        guest ok = Yes
		 		        path = ${DIRS_TFTP}
		 		        wide links = Yes
		_EOT_
		
		 	# --- output --------------------------------------------------------------
		 	testparm -s "${_WORK_PATH}" > "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_SMBD}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_SMBD}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_SMBD}"
		 	fi
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NMBD}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NMBD}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NMBD}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup timesyncd -------------------------------------------------
		funcSetupNetwork_timesyncd() {
		 	__FUNC_NAME="funcSetupNetwork_timesyncd"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check service -------------------------------------------------------
		 	_SRVC_NAME="systemd-timesyncd.service"
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "not-found" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- timesyncd.conf ------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/systemd/timesyncd.conf.d/local.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 		# --- user settings ---
		 		
		 		[Time]
		 		NTP=${NTPS_ADDR}
		 		FallbackNTP=ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp
		 		PollIntervalMinSec=1h
		 		PollIntervalMaxSec=1d
		 		SaveIntervalSec=infinity
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- network setup chronyd ---------------------------------------------------
		funcSetupNetwork_chronyd() {
		 	__FUNC_NAME="funcSetupNetwork_chronyd"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check service -------------------------------------------------------
		 	_SRVC_NAME="chronyd.service"
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "not-found" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v hwclock > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NAME}"
		 		hwclock --systohc
		 		hwclock --test
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- openssh-server settings -------------------------------------------------
		funcSetupConfig_ssh() {
		 	__FUNC_NAME="funcSetupConfig_ssh"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check service -------------------------------------------------------
		 	if   [ -e "${DIRS_TGET:-}/lib/systemd/system/ssh.service"      ] \
		 	||   [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/ssh.service"  ]; then
		 		_SRVC_NAME="ssh.service"
		 	elif [ -e "${DIRS_TGET:-}/lib/systemd/system/sshd.service"     ] \
		 	||   [ -e "${DIRS_TGET:-}/usr/lib/systemd/system/sshd.service" ]; then
		 		_SRVC_NAME="sshd.service"
		 	else
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		 	_SRVC_STAT="$(funcServiceStatus is-enabled "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "not-found" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- default.conf --------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/ssh/sshd_config.d/default.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
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
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- systemctl -----------------------------------------------------------
		 	_SRVC_STAT="$(funcServiceStatus is-active "${_SRVC_NAME}")"
		 	if [ "${_SRVC_STAT}" = "active" ]; then
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "service restart: ${_SRVC_NAME}"
		 		systemctl --quiet daemon-reload
		 		systemctl --quiet restart "${_SRVC_NAME}"
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- vmware shared directory settings ----------------------------------------
		funcSetupConfig_vmware() {
		 	__FUNC_NAME="funcSetupConfig_vmware"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v vmware-hgfsclient > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- check vmware shared directory ---------------------------------------
		 	if ! vmware-hgfsclient > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "not exist vmware shared directory"
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- check file system ---------------------------------------------------
		 	if command -v vmhgfs-fuse > /dev/null 2>&1; then
		 		_HGFS_FSYS="fuse.vmhgfs-fuse"
		 	else
		 		_HGFS_FSYS="vmhgfs"
		 	fi
		
		 	# --- fstab ---------------------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/fstab"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 		.host:/         ${DIRS_HGFS:?}       ${_HGFS_FSYS} allow_other,auto_unmount,defaults 0 0
		_EOT_
		
		 	# --- systemctl -----------------------------------------------------------
		 		printf "\033[m${PROG_NAME}: %s\033[m\n" "daemon reload"
		 		systemctl --quiet daemon-reload
		
		 	# --- check mount ---------------------------------------------------------
		 	if [ "${CHGE_ROOT:-}" = "true" ]; then
		 		printf "\033[m${PROG_NAME}: \033[43m%s\033[m\n" "skip vmware mounts for chroot"
		 	else
		 		if mount "${DIRS_HGFS}"; then
		 			printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "vmware shared directory was mounted successfully"
		 			LANG=C df -h "${DIRS_HGFS}"
		 		else
		 			printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "error while mounting vmware shared directory"
		 			sed -i "${_FILE_PATH}"      \
		 			    -e '\%^.host:/% s%^%#%'
		 		fi
		 	fi
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- wireplumber settings ----------------------------------------------------
		funcSetupConfig_wireplumber() {
		 	__FUNC_NAME="funcSetupConfig_wireplumber"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v wireplumber > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- 50-alsa-config.conf -------------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
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
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
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
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
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
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- .bash_history -------------------------------------------------------
		#	_WORK_TEXT="$(funcInstallPackage "apt")"
		#	if [ -n "${_WORK_TEXT}" ]; then
		 	if command -v apt-get > /dev/null 2>&1; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.bash_history"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 			sudo bash -c 'apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade'
		_EOT_
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- .vimrc --------------------------------------------------------------
		#	_WORK_TEXT="$(funcInstallPackage "vim-common")"
		#	if [ -z "${_WORK_TEXT}" ]; then
		#		_WORK_TEXT="$(funcInstallPackage "vim")"
		#	fi
		#	if [ -n "${_WORK_TEXT}" ]; then
		 	if command -v vim > /dev/null 2>&1; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.vimrc"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
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
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- .curlrc -------------------------------------------------------------
		#	_WORK_TEXT="$(funcInstallPackage "curl")"
		#	if [ -n "${_WORK_TEXT}" ]; then
		 	if command -v curl > /dev/null 2>&1; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/skel/.curlrc"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		 			location
		 			progress-bar
		 			remote-time
		 			show-error
		_EOT_
		
		 		# --- debug out -------------------------------------------------------
		 		funcDebugout_file "${_FILE_PATH}"
		 		funcFile_backup   "${_FILE_PATH}" "init"
		 	fi
		
		 	# --- distribute to existing users ----------------------------------------
		 	for _DIRS_USER in "${DIRS_TGET:-}"/root \
		 	                  "${DIRS_TGET:-}"/home/*
		 	do
		 		if [ ! -e "${_DIRS_USER}" ]; then
		 			continue
		 		fi
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
		
		 			# --- debug out ---------------------------------------------------
		 			funcDebugout_file "${_DIRS_DEST}/${_FILE_PATH##*/}"
		 			funcFile_backup   "${_DIRS_DEST}/${_FILE_PATH##*/}" "init"
		 		done
		 	done
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- sudoers settings --------------------------------------------------------
		funcSetupConfig_sudo() {
		 	__FUNC_NAME="funcSetupConfig_sudo"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if ! command -v sudo > /dev/null 2>&1; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- sudoers -------------------------------------------------------------
		 	_WORK_PATH="${DIRS_TGET:-}/tmp/sudoers-local.work"
		 	_WORK_TEXT="$(sed -ne 's/^.*\(sudo\|wheel\).*$/\1/p' "${DIRS_TGET:-}/etc/group")"
		 	_WORK_TEXT="${_WORK_TEXT:+"%${_WORK_TEXT}$(funcString "$((6-${#_WORK_TEXT}))" " ")ALL=(ALL:ALL) ALL"}"
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_WORK_PATH}"
		 		Defaults !targetpw
		 		Defaults authenticate
		 		root   ALL=(ALL:ALL) ALL
		 		${_WORK_TEXT:-}
		_EOT_
		
		 	# --- sudoers-local -------------------------------------------------------
		 	if visudo -q -c -f "${_WORK_PATH}"; then
		 		_FILE_PATH="${DIRS_TGET:-}/etc/sudoers.d/sudoers-local"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		cp -a "${_WORK_PATH}" "${_FILE_PATH}"
		 		chown -c root:root "${_FILE_PATH}"
		 		chmod -c 0440 "${_FILE_PATH}"
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "file creation successful"
		 		# --- sudoers ---------------------------------------------------------
		 		_FILE_PATH="${DIRS_TGET:-}/etc/sudoers"
		 		_WORK_PATH="${DIRS_TGET:-}/tmp/sudoers.work"
		 		funcFile_backup "${_FILE_PATH}"
		 		mkdir -p "${_FILE_PATH%/*}"
		 		sed "${_FILE_PATH}"                                              \
		 		    -e '/^Defaults[ \t]\+targetpw[ \t]*/ s/^/#/'                 \
		 		    -e '/^ALL[ \t]\+ALL=(ALL\(\|:ALL\))[ \t]\+ALL[ \t]*/ s/^/#/' \
		 		> "${_WORK_PATH}"
		 		if visudo -q -c -f "${_WORK_PATH}"; then
		 			cp -a "${_WORK_PATH}" "${_FILE_PATH}"
		 			chown -c root:root "${_FILE_PATH}"
		 			chmod -c 0440 "${_FILE_PATH}"
		 			printf "\033[m${PROG_NAME}: \033[93m%s\033[m\n" "sudo -ll: list user's privileges or check a specific command"
		
		 			# --- debug out ---------------------------------------------------
		 			funcDebugout_file "${_FILE_PATH}"
		 			funcFile_backup   "${_FILE_PATH}" "init"
		 		else
		 			printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "file creation failure"
		 			visudo -c -f "${_WORK_PATH}" || true
		 		fi
		 	else
		 		printf "\033[m${PROG_NAME}: \033[91m%s\033[m\n" "file creation failure"
		 		visudo -c -f "${_WORK_PATH}" || true
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- blacklist settings ------------------------------------------------------
		funcSetupConfig_blacklist() {
		 	__FUNC_NAME="funcSetupConfig_blacklist"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check load module ---------------------------------------------------
		 	if ! lsmod | grep -q 'floppy'; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- blacklist-floppy.conf -----------------------------------------------
		 	_FILE_PATH="${DIRS_TGET:-}/etc/modprobe.d/blacklist-floppy.conf"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cp -a "${DIRS_ORIG}/${_FILE_PATH#*"${DIRS_TGET:-}/"}" "${_FILE_PATH}"
		 	echo 'blacklist floppy' > "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- update initramfs ----------------------------------------------------
		#	if [ -z "${DIRS_TGET:-}" ]; then
		#		rmmod floppy || true
		#	fi
		 	if command -v update-initramfs > /dev/null 2>&1; then
		 		_REAL_PATH=""
		 		_KNEL_VERS=""
		 		_REAL_VLNZ=""
		 		_REAL_IRAM=""
		 		_WORK_TEXT="$(echo "${DIRS_TGET:-}" | sed -e 's%[^/]%%g')"
		
		 		# --- initramfs -------------------------------------------------------
		 		for _FILE_PATH in $(find "${DIRS_TGET:-}/" "${DIRS_TGET:-}/boot" -maxdepth 1 -name 'initrd*' | sort -uV -t '/' -k $((${#_WORK_TEXT}+3)) -k $((${#_WORK_TEXT}+2)))
		 		do
		 			_REAL_PATH="$(realpath "${_FILE_PATH}")"
		 			if [ -e "${_REAL_PATH}" ]; then
		 				_REAL_IRAM="${_REAL_PATH}"
		 				_KNEL_VERS="${_REAL_IRAM##*/}"
		 				_KNEL_VERS="${_KNEL_VERS#*-}"
		 				_KNEL_VERS="${_KNEL_VERS%.img}"
		 				break
		 			fi
		 		done
		
		 		# --- vmlinuz ---------------------------------------------------------
		 		if [ -z "${_KNEL_VERS:-}" ]; then
		 			for _FILE_PATH in $(find "${DIRS_TGET:-}/" "${DIRS_TGET:-}/boot" -maxdepth 1 \( -name 'vmlinuz*' -o -name 'linux*' \) | sort -uV -t '/' -k $((${#_WORK_TEXT}+3)) -k $((${#_WORK_TEXT}+2)))
		 			do
		 				_REAL_PATH="$(realpath "${_FILE_PATH}")"
		 				if [ -e "${_REAL_PATH}" ]; then
		 					_REAL_VLNZ="${_REAL_PATH}"
		 					_KNEL_VERS="$(file "${_REAL_VLNZ}")"
		 					_KNEL_VERS="${_KNEL_VERS#*version }"
		 					_KNEL_VERS="${_KNEL_VERS%% *}"
		 					break
		 				fi
		 			done
		 		fi
		
		 		# --- uname -r --------------------------------------------------------
		 		if [ -z "${_KNEL_VERS:-}" ]; then
		 			_KNEL_VERS="$(uname -r)"
		 		fi
		
		 		# --- debug out -------------------------------------------------------
		 		printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "version" "${_KNEL_VERS:-}"
		 		printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "vmlinuz" "${_REAL_VLNZ:-}"
		 		printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "initrd " "${_REAL_IRAM:-}"
		
		 		# --- create initramfs ------------------------------------------------
		 		if [ -n "${_KNEL_VERS:-}" ]; then
		 			update-initramfs -c -b "${PROG_DIRS}/" -k "${_KNEL_VERS}"
		 			for _FILE_PATH in $(find "${PROG_DIRS:-}/" -maxdepth 1 -name 'initrd*'"${_KNEL_VERS}"'*' | sort -uV -t '/' -k $((${#PROG_DIRS}+3)) -k $((${#PROG_DIRS}+2)))
		 			do
		 				printf "\033[m${PROG_NAME}: %s=[%s]\033[m\n" "create " "${_FILE_PATH:-}"
		 				funcFile_backup "${_REAL_IRAM}"
		 				cp --preserve=timestamps "${_FILE_PATH}" "${_REAL_IRAM}"
		 				break
		 			done
		#			funcFile_backup   "${_REAL_VLNZ}" "init"
		 			funcFile_backup   "${_REAL_IRAM}" "init"
		 		fi
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- grub menu settings ------------------------------------------------------
		funcSetupConfig_grub_menu() {
		 	__FUNC_NAME="funcSetupConfig_grub_menu"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check command -------------------------------------------------------
		 	if command -v grub-mkconfig > /dev/null 2>&1; then
		 		_WORK_COMD="grub-mkconfig"
		 	elif command -v grub2-mkconfig > /dev/null 2>&1; then
		 		_WORK_COMD="grub2-mkconfig"
		 	else
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- check setup ---------------------------------------------------------
		 	_TITL_TEXT="### User Custom ###"
		 	_FILE_PATH="${DIRS_TGET:-}/etc/default/grub"
		 	funcFile_backup "${_FILE_PATH}"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	if grep -q "${_TITL_TEXT}" "${_FILE_PATH}"; then
		 		printf "\033[m${PROG_NAME}: \033[93m%s\033[m\n" "already setup"
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- grub ----------------------------------------------------------------
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 		
		 		${_TITL_TEXT}
		 		GRUB_RECORDFAIL_TIMEOUT=10
		 		GRUB_TIMEOUT=3
		 		
		_EOT_
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
		 	# --- create grub.cfg -----------------------------------------------------
		 	_FILE_PATH="$(find "${DIRS_TGET:-}"/boot/ \( -path '/*/efi' -o -path '/*/EFI' \) -prune -o -type f -name 'grub.cfg' -print)"
		 	if [ -n "${_FILE_PATH}" ]; then
		 		_WORK_PATH="${DIRS_TGET:-}/tmp/grub.cfg.work"
		 		if "${_WORK_COMD}" --output="${_WORK_PATH}"; then
		 			if cp --preserve=timestamps "${_WORK_PATH}" "${_FILE_PATH}"; then
		 				printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "success to create ${_FILE_PATH}"
		
		 				# --- debug out -----------------------------------------------
		 				funcDebugout_file "${_FILE_PATH}"
		 				funcFile_backup   "${_FILE_PATH}" "init"
		 			else
		 				printf "\033[m${PROG_NAME}: \033[41m%s\033[m\n" "failed to copy ${_FILE_PATH}"
		 			fi
		 		else
		 			printf "\033[m${PROG_NAME}: \033[41m%s\033[m\n" "failed to create grub.cfg"
		 		fi
		 	fi
		
		 	# --- complete ------------------------------------------------------------
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${__FUNC_NAME}] ---"
		}
		
		# --- ipxe module settings ----------------------------------------------------
		funcSetupModule_ipxe() {
		 	__FUNC_NAME="funcSetupModule_ipxe"
		 	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${__FUNC_NAME}] ---"
		
		 	# --- check directory -----------------------------------------------------
		 	if [ ! -e "${DIRS_TFTP}" ]; then
		 		printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "--- exit    : [${__FUNC_NAME}] ---"
		 		return
		 	fi
		
		 	# --- get module ----------------------------------------------------------
		#	LANG=C wget --tries=3 --timeout=10 --no-verbose --output-document="${DIRS_TFTP}/ipxe/undionly.kpxe" "https://boot.ipxe.org/undionly.kpxe" || true
		#	LANG=C wget --tries=3 --timeout=10 --no-verbose --output-document="${DIRS_TFTP}/ipxe/ipxe.efi"      "https://boot.ipxe.org/ipxe.efi" || true
		#	LANG=C wget --tries=3 --timeout=10 --no-verbose --output-document="${DIRS_TFTP}/ipxe/wimboot"       "https://github.com/ipxe/wimboot/releases/latest/download/wimboot" || true
		 	_FILE_PATH="${PROG_DIRS:?}/get_module_ipxe.sh"
		 	mkdir -p "${_FILE_PATH%/*}"
		 	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
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
		 		
		 		 	if set -o | grep "^xtrace\s*on$"; then
		 		 		exec 2>&1
		 		 	fi
		 		
		 		 	# --- working directory name ----------------------------------------------
		 		 	readonly PROG_PATH="$0"
		 		#	readonly PROG_PRAM="$*"
		 		#	readonly PROG_DIRS="${PROG_PATH%/*}"
		 		 	readonly PROG_NAME="${PROG_PATH##*/}"
		 		#	readonly PROG_PROC="${PROG_NAME}.$$"
		 		
		 		# *** main processing section *************************************************
		 		 	# --- start ---------------------------------------------------------------
		 		#	_start_time=$(date +%s)
		 		#	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
		 		#	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing start"
		 		 	# --- main ----------------------------------------------------------------
		_EOT_
		 	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 		 	_DIRS_TFTP='${DIRS_TFTP}'
		_EOT_
		 	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FILE_PATH}"
		 		 	for _WEBS_ADDR in \
		 		 		https://boot.ipxe.org/undionly.kpxe \
		 		 		https://boot.ipxe.org/ipxe.efi \
		 		 		https://github.com/ipxe/wimboot/releases/latest/download/wimboot
		 		 	do
		 		 		if ! wget --tries=3 --timeout=10 --no-verbose --output-document="${_DIRS_TFTP}/ipxe/${_WEBS_ADDR##*/}" "${_WEBS_ADDR}"; then
		 		 			printf "\033[m${PROG_NAME}: \033[41m%s\033[m\n" "failed to wget: ${_WEBS_ADDR}"
		 		 		fi
		 		 	done
		 		 	# --- complete ------------------------------------------------------------
		 		#	_end_time=$(date +%s)
		 		#	_datetime="$(date +"%Y/%m/%d %H:%M:%S")"
		 		#	printf "\033[m${PROG_NAME}: elapsed time: %dd%02dh%02dm%02ds\033[m\n" "$(((_end_time-_start_time)/86400))" "$(((_end_time-_start_time)%86400/3600))" "$(((_end_time-_start_time)%3600/60))" "$(((_end_time-_start_time)%60))"
		 		#	printf "\033[m${PROG_NAME}: \033[45m%s\033[m\n" "${_datetime} processing complete"
		 		 	exit 0
		 		
		 		### eof #######################################################################
		_EOT_
		 	chown -c root:root "${_FILE_PATH}"
		 	chmod -c 0500 "${_FILE_PATH}"
		
		 	# --- debug out -----------------------------------------------------------
		 	funcDebugout_file "${_FILE_PATH}"
		 	funcFile_backup   "${_FILE_PATH}" "init"
		
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
		 	funcFile_backup "/proc/cmdline"
		 	funcFile_backup "/proc/mounts"
		 	funcFile_backup "/proc/self/mounts"
		
		 	# --- installing missing packages -----------------------------------------
		 	funcInstall_package
		
		 	# --- creating a shared environment ---------------------------------------
		 	funcCreate_shared_env
		
		 	# --- apparmor settings -------------------------------------------------------
		 	funcSetupConfig_apparmor
		
		 	# --- selinux settings ----------------------------------------------------
		 	funcSetupConfig_selinux
		
		 	# --- network manager -----------------------------------------------------
		 	funcSetupNetwork_connman			# network setup connman
		 	funcSetupNetwork_netplan			# network setup netplan
		 	funcSetupNetwork_nmanagr			# network setup network manager
		
		 	# --- network settings ----------------------------------------------------
		 	funcSetupNetwork_hostname			# network setup hostname
		 	funcSetupNetwork_hosts				# network setup hosts
		#	funcSetupNetwork_hosts_access		# network setup hosts.allow/hosts.deny
		 	funcSetupNetwork_firewalld			# network setup firewalld
		 	funcSetupNetwork_dnsmasq			# network setup dnsmasq
		 	funcSetupNetwork_resolv				# network setup resolv.conf
		 	funcSetupNetwork_apache				# network setup apache
		 	funcSetupNetwork_samba				# network setup samba
		 	funcSetupNetwork_timesyncd			# network setup timesyncd
		 	funcSetupNetwork_chronyd			# network setup chronyd
		
		 	# --- openssh-server settings ---------------------------------------------
		 	funcSetupConfig_ssh
		
		 	# --- vmware shared directory settings ------------------------------------
		 	funcSetupConfig_vmware
		
		 	# --- wireplumber settings ------------------------------------------------
		 	funcSetupConfig_wireplumber
		
		 	# --- skeleton settings ---------------------------------------------------
		 	funcSetupConfig_skel
		
		 	# --- sudoers settings ----------------------------------------------------
		 	funcSetupConfig_sudo
		
		 	# --- blacklist settings --------------------------------------------------
		 	funcSetupConfig_blacklist
		
		 	# --- grub menu settings --------------------------------------------------
		 	funcSetupConfig_grub_menu
		
		 	# --- ipxe module settings ------------------------------------------------
		 	funcSetupModule_ipxe
		
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
	chmod ugo+x "${_FILE_NAME}"
	cp -a "${_FILE_NAME}" "${DIRS_CONF}/preseed/preseed_late_command.sh"
	cp -a "${_FILE_NAME}" "${DIRS_CONF}/nocloud/nocloud_late_command.sh"
	cp -a "${_FILE_NAME}" "${DIRS_CONF}/kickstart/late_command.sh"
	cp -a "${_FILE_NAME}" "${DIRS_CONF}/autoyast/late_command.sh"
}

# ----- create preseed.cfg ----------------------------------------------------
function funcCreate_preseed_cfg() {
	declare -r    _DIRS_NAME="${DIRS_CONF}/preseed"
	declare       _FILE_PATH=""
	declare -r -a _FILE_LIST=(                       \
		"ps_debian_"{server,desktop}{,_old,_oldold}".cfg"   \
		"ps_ubuntu_"{server,desktop}{,_old,_oldold}".cfg"   \
		"ps_ubiquity_"{server,desktop}{,_old,_oldold}".cfg" \
	)
	declare       _FILE_TMPL=""
	declare       _INSR_STRS=""			# string to insert
	declare -i    I=0
	# -------------------------------------------------------------------------
	for I in "${!_FILE_LIST[@]}"
	do
		case "${_FILE_LIST[I]}" in
			*_debian_*   ) _FILE_TMPL="${CONF_SEDD}";;
			*_ubuntu_*   ) _FILE_TMPL="${CONF_SEDU}";;
			*_ubiquity_* ) _FILE_TMPL="${CONF_SEDU}";;
			* ) continue;;
		esac
		_FILE_PATH="${_DIRS_NAME}/${_FILE_LIST[I]}"
		funcPrintf "%20.20s: %s" "create file" "${_FILE_PATH/${PWD}\/}"
		mkdir -p "${_FILE_PATH%/*}"
		# ---------------------------------------------------------------------
#		case "${_FILE_PATH}" in
#			*_debian_desktop_oldold* | *_debian_server_oldold* ) ;;	# debian-10(buster)
#			*_debian_desktop_old*    | *_debian_server_old*    ) ;;	# debian-11(bullseye)
#			*_debian_desktop*        | *_debian_server*        ) ;;	# debian-12(bookworm)/13(trixie)/14(forky)
#			*_ubuntu_server_oldold*                            ) ;;	# ubuntu-server-14.04(trusty)/16.04(xenial)/18.04(bionic)/ubuntu-mini-18.04(bionic)
#			*_ubuntu_server_old*                               ) ;;	# ubuntu-mini-20.04(focal)
#			*_ubiquity_desktop_oldold*                         ) ;;	# ubuntu-desktop-14.04(trusty)/16.04(xenial)/18.04(bionic)
#			*_ubiquity_desktop_old*                            ) ;;	# ubuntu-desktop-20.04(focal)/22.04(jammy)
#			*_ubiquity_desktop*                                ) ;;	# ubuntu-desktop-23.04(lunar)
#			*                                                  ) ;;
#		esac
		cp --backup "${_FILE_TMPL}" "${_FILE_PATH}"
		case "${_FILE_PATH}" in
			*_oldold*)
				sed -i "${_FILE_PATH}"               \
				    -e 's/bind9-utils/bind9utils/'   \
				    -e 's/bind9-dnsutils/dnsutils/'  \
				    -e 's/systemd-resolved/systemd/' \
				    -e 's/fcitx5-mozc/fcitx-mozc/'
				;;
			*_old*)
				sed -i "${_FILE_PATH}"               \
				    -e 's/systemd-resolved/systemd/' \
				    -e 's/fcitx5-mozc/fcitx-mozc/'
				;;
			*)
				;;
		esac
		case "${_FILE_PATH}" in
			*_desktop*)
				sed -i "${_FILE_PATH}"                                              \
				    -e '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+%,\%^#.*[^\\]$% { ' \
				    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                  \
				    -e 's/^#/ /g                                                }'
				;;
			*)
				;;
		esac
		case "${_FILE_PATH}" in
			*_ubiquity_*)
				IFS= _INSR_STRS=$(
					sed -n '\%^[^#].*preseed/late_command%,\%[^\\]$%p' "${_FILE_PATH}" | \
					sed -e 's/\\/\\\\/g'                                                 \
					    -e 's/d-i/ubiquity/'                                             \
					    -e 's%preseed\/late_command%ubiquity\/success_command%'        | \
					sed -e ':l; N; s/\n/\\n/; b l;'
				)
				IFS=${OLD_IFS}
				if [[ -n "${_INSR_STRS}" ]]; then
					sed -i "${_FILE_PATH}"                                   \
					    -e '\%^[^#].*preseed/late_command%,\%[^\\]$%     { ' \
					    -e 's/^/#/g                                        ' \
					    -e 's/^#  /# /g                                  } ' \
					    -e '\%^[^#].*ubiquity/success_command%,\%[^\\]$% { ' \
					    -e 's/^/#/g                                        ' \
					    -e 's/^#  /# /g                                  } '
					sed -i "${_FILE_PATH}"                                    \
					    -e "\%ubiquity/success_command%i \\${_INSR_STRS}"
				fi
				sed -i "${_FILE_PATH}"                        \
				    -e "\%ubiquity/download_updates% s/^#/ /" \
				    -e "\%ubiquity/use_nonfree%      s/^#/ /" \
				    -e "\%ubiquity/reboot%           s/^#/ /"
				;;
			*)
				;;
		esac
		case "${_FILE_PATH}" in
			*_debian_desktop_oldold* | *_debian_server_oldold* ) ;;	# debian-10(buster)
			*_debian_desktop_old*    | *_debian_server_old*    ) ;;	# debian-11(bullseye)
			*_debian_desktop*        | *_debian_server*        ) ;;	# debian-12(bookworm)/13(trixie)/14(forky)
			*_ubuntu_server_oldold*                            )   	# ubuntu-server-14.04(trusty)/16.04(xenial)/18.04(bionic)/ubuntu-mini-18.04(bionic)
				sed -i "${_FILE_PATH}"            \
				    -e '/usr-is-merged/ s/^ /#/g' \
				    -e '/usrmerge/      s/^ /#/g'
				;;
			*_ubuntu_server_old*                               ) ;;	# ubuntu-mini-20.04(focal)
			*_ubiquity_desktop_oldold*                         )   	# ubuntu-desktop-14.04(trusty)/16.04(xenial)/18.04(bionic)
				sed -i "${_FILE_PATH}"            \
				    -e '/usr-is-merged/ s/^ /#/g' \
				    -e '/usrmerge/      s/^ /#/g'
				;;
			*_ubiquity_desktop_old*                            ) ;;	# ubuntu-desktop-20.04(focal)/22.04(jammy)
			*_ubiquity_desktop*                                )   	# ubuntu-desktop-23.04(lunar)
				sed -i "${_FILE_PATH}"            \
				    -e '/usr-is-merged/ s/^ /#/g' \
				    -e '/usrmerge/      s/^ /#/g'
				;;
			*)	;;
		esac
	done
	# --- expert --------------------------------------------------------------
	_FILE_TMPL="${_DIRS_NAME}/ps_debian_server.cfg"
	_FILE_PATH="${_FILE_TMPL/\.cfg/_expert\.cfg}"
	sed -e '\%^[ \t]*d-i[ \t]\+partman-auto/init_automatically_partition[ \t]\+%                        { ' \
	    -e 's/^/#/g                                                                                       ' \
	    -e 's/^#  /# /g                                                                                 } ' \
	    -e '\%^[ \t]*d-i[ \t]\+partman-auto/disk[ \t]\+%                                                { ' \
	    -e 's/^/#/g                                                                                       ' \
	    -e 's/^#  /# /g                                                                                 } ' \
	    -e '\%^[ \t]*d-i[ \t]\+partman-auto/choose_recipe[ \t]\+%                                       { ' \
	    -e 's/^/#/g                                                                                       ' \
	    -e 's/^#  /# /g                                                                                 } ' \
	    -e '\%^[ \t]*d-i[ \t]\+partman/early_command[ \t]\+%,\%[^\\]$%                                  { ' \
	    -e '0,/[^\\]$/                                                                                  { ' \
	    -e '/pvremove[ \t]\+/a \      pvremove /dev/sda*     -ff -y; '\\\\''                                \
	    -e '/dd[ \t]\+/a \      dd if=/dev/zero of=/dev/sda     bs=1M count=10; '\\\\''                     \
	    -e '                                                                                           }} ' \
	    -e '\%^#*[ \t]*d-i[ \t]\+partman-auto/expert_recipe[ \t]\+%,\%[^\\]$%                           { ' \
	    -e '0,/[^\\]$/                                                                                  { ' \
	    -e 's/^#/ /g                                                                                   }} ' \
	    -e '\%^#[ \t]*d-i[ \t]\+partman-auto/disk[ \t]\+string[ \t]\+/dev/nvme0n1[ \t]\+/dev/sda[ \t]*% { ' \
	    -e '0,/[^\\]$/                                                                                  { ' \
	    -e 's/^#/ /g                                                                                   }} ' \
	    "${_FILE_TMPL}"                                                                                     \
	>   "${_FILE_PATH}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${_DIRS_NAME}/"*
}

# ----- create nocloud --------------------------------------------------------
function funcCreate_nocloud() {
	declare -r -a _DIRS_LIST=("${DIRS_CONF}/nocloud/ubuntu_"{server,desktop}{,_old,_oldold})
	declare       _DIRS_NAME=""
	declare -i    I=0
	# -------------------------------------------------------------------------
	for I in "${!_DIRS_LIST[@]}"
	do
		_DIRS_NAME="${_DIRS_LIST[I]}"
		FILE_PATH="${_DIRS_NAME}/user-data"
		funcPrintf "%20.20s: %s" "create file" "${_DIRS_NAME/${PWD}\/}"
		mkdir -p "${_DIRS_NAME}"
		# ---------------------------------------------------------------------
#		case "${FILE_PATH}" in
#			*ubuntu_desktop/*      ) ;;	# ubuntu-desktop-23.10(mantic)/24.04(noble)/24.04(noble)/24.10(oracular)/25.04(plucky)
#			*ubuntu_server_oldold/*) ;;	# ubuntu-live-18.04(bionic)
#			*ubuntu_server_old/*   ) ;;	# ubuntu-live-20.04(focal)/22.04(jammy)
#			*ubuntu_server/*       ) ;;	# ubuntu-live-23.04(lunar)/23.10(mantic)/24.04(noble)/24.10(oracular)/25.04(plucky)
#		esac
		cp --backup "${CONF_CLUD}" "${FILE_PATH}"
		case "${FILE_PATH}" in
			*_oldold/*)
				sed -i "${FILE_PATH}"               \
				    -e 's/bind9-utils/bind9utils/'  \
				    -e 's/bind9-dnsutils/dnsutils/' \
				    -e 's/systemd-resolved/systemd/'
				;;
			*_old/*)
				sed -i "${FILE_PATH}"               \
				    -e 's/systemd-resolved/systemd/'
				;;
			*)
				;;
		esac
		case "${FILE_PATH}" in
			*_desktop/*)
				sed -i "${FILE_PATH}"                                              \
				    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
				    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
				;;
			*)
				;;
		esac
		case "${FILE_PATH}" in
			*ubuntu_desktop/*      )   	# ubuntu-desktop-23.10(mantic)/24.04(noble)/24.04(noble)/24.10(oracular)/25.04(plucky)
				sed -i "${FILE_PATH}"             \
				    -e '/usr-is-merged/ s/^ /#/g' \
				    -e '/usrmerge/      s/^ /#/g'
				;;
			*ubuntu_server_oldold/*)   	# ubuntu-live-18.04(bionic)
				sed -i "${FILE_PATH}"             \
				    -e '/usr-is-merged/ s/^ /#/g' \
				    -e '/usrmerge/      s/^ /#/g'
				;;
			*ubuntu_server_old/*   ) ;; # ubuntu-live-20.04(focal)/22.04(jammy)
			*ubuntu_server/*       )   	# ubuntu-live-23.04(lunar)/23.10(mantic)/24.04(noble)/24.10(oracular)/25.04(plucky)
				sed -i "${FILE_PATH}"             \
				    -e '/usr-is-merged/ s/^ /#/g' \
				    -e '/usrmerge/      s/^ /#/g'
				;;
			*)	;;
		esac
		touch "${_DIRS_NAME}/meta-data"      --reference "${_DIRS_NAME}/user-data"
		touch "${_DIRS_NAME}/network-config" --reference "${_DIRS_NAME}/user-data"
#		touch "${_DIRS_NAME}/user-data"      --reference "${_DIRS_NAME}/user-data"
		touch "${_DIRS_NAME}/vendor-data"    --reference "${_DIRS_NAME}/user-data"
		chmod ugo-x "${_DIRS_NAME}/"*
	done
}

# ----- create kickstart.cfg --------------------------------------------------
function funcCreate_kickstart() {
	declare -r    _IMGS_ADDR="http://${SRVR_ADDR}/imgs"
	declare -r    _DIRS_NAME="${DIRS_CONF}/kickstart"
	declare       _FILE_PATH=""
	declare       _DSTR_NAME=""
	declare       _DSTR_NUMS=""
	declare       _RLNX_NUMS=""
	declare -r    _BASE_ARCH="x86_64"
	declare       _DSTR_SECT=""
	declare -i    I=0
	declare    -a _FILE_LIST=()
	declare       _FILE_LINE=""
	# -------------------------------------------------------------------------
	_FILE_LIST=()
	for I in "${!DATA_LIST[@]}"
	do
		_FILE_LINE="$(echo "${DATA_LIST[I]}" | awk '$1=="o"&&$10~/kickstart/ {split($10,s,"/"); print s[2];}')"
		if [[ -z "${_FILE_LINE}" ]]; then
			continue
		fi
		_FILE_LIST+=("${_FILE_LINE}")
		case "${_FILE_LINE}" in
			*_dvd.cfg) _FILE_LIST+=("${_FILE_LINE/_dvd./_web.}");;
			*) ;;
		esac
	done
	# -------------------------------------------------------------------------
	for I in "${!_FILE_LIST[@]}"
	do
		_FILE_PATH="${_DIRS_NAME}/${_FILE_LIST[I]}"
		funcPrintf "%20.20s: %s" "create file" "${_FILE_PATH/${PWD}\/}"
		mkdir -p "${_FILE_PATH%/*}"
		# ---------------------------------------------------------------------
		_DSTR_NAME="$(echo "${_FILE_LIST[I]}" | sed -ne 's%^.*_\(almalinux\|centos-stream\|fedora\|miraclelinux\|rockylinux\)-.*$%\1%p')"
		_DSTR_NUMS="$(echo "${_FILE_LIST[I]}" | sed -ne 's%^.*'"${_DSTR_NAME}"'-\([0-9.]\+\)_.*$%\1%p')"
		_DSTR_SECT="${_DSTR_NAME/-/ }"
		_RLNX_NUMS="${_DSTR_NUMS}"
		if [[ "${_DSTR_NAME}" = "fedora" ]] && [[ ${_DSTR_NUMS} -ge 38 ]] && [[ ${_DSTR_NUMS} -le 40 ]]; then
			_RLNX_NUMS="9"
		fi
		# ---------------------------------------------------------------------
		cp --backup "${CONF_KICK}" "${_FILE_PATH}"
		if [[ "${_DSTR_NAME}" = "centos-stream" ]]; then
			case "${_DSTR_NUMS}" in
				8) _DSTR_SECT="${_DSTR_NAME/-/ }-${_DSTR_NUMS}";;
				*) _DSTR_SECT="${_DSTR_NAME/-/ }-9"           ;;
			esac
		fi
		# --- cdrom, hostname, install repository -----------------------------
		case "${_FILE_LIST[I]}" in
			*_dvd* )	# --- cdrom install -----------------------------------
				sed -i "${_FILE_PATH}"                         \
				    -e "/^#cdrom/ s/^#//                     " \
				    -e "s/_HOSTNAME_/${_DSTR_NAME%%-*}/      " \
				    -e "/^#.*(${_DSTR_SECT}).*$/,/^$/      { " \
				    -e '/_WEBADDR_/                        { ' \
				    -e '/^url[ \t]\+/   s/^/#/g              ' \
				    -e '/^repo[ \t]\+/  s/^/#/g            } ' \
				    -e "/_WEBADDR_/!                       { " \
				    -e "/^url[ \t]\+/   s/^/#/g              " \
				    -e "/^repo[ \t]\+/  s/^/#/g              " \
				    -e "s/\$releasever/${_DSTR_NUMS}/g       " \
				    -e "s/\$basearch/${_BASE_ARCH}/g      }} "
				;;
			*_web* )	# --- network install [ _WEBADDR_ ] -------------------
				sed -i "${_FILE_PATH}"                         \
				    -e "/^cdrom/ s/^/#/                      " \
				    -e "s/_HOSTNAME_/${_DSTR_NAME%%-*}/      " \
				    -e "/^#.*(${_DSTR_SECT}).*$/,/^$/      { " \
				    -e '/_WEBADDR_/                        { ' \
				    -e "/^#url[ \t]\+/  s/^#//g              " \
				    -e "/^#repo[ \t]\+/ s/^#//g              " \
				    -e "/_WEBADDR_/!                       { " \
				    -e '/^url[ \t]\+/   s/^/#/g              ' \
				    -e '/^repo[ \t]\+/  s/^/#/g            } ' \
				    -e "s/\$releasever/${_DSTR_NUMS}/g       " \
				    -e "s/\$basearch/${_BASE_ARCH}/g      }} "
				;;
			* )			# --- network install [ ! _WEBADDR_ ] -----------------
				sed -i "${_FILE_PATH}"                         \
				    -e "/^cdrom/ s/^/#/                      " \
				    -e "s/_HOSTNAME_/${_DSTR_NAME%%-*}/      " \
				    -e "/^#.*(${_DSTR_SECT}).*$/,/^$/      { " \
				    -e '/_WEBADDR_/                        { ' \
				    -e '/^url[ \t]\+/   s/^/#/g              ' \
				    -e '/^repo[ \t]\+/  s/^/#/g            } ' \
				    -e "/_WEBADDR_/!                       { " \
				    -e "/^#url[ \t]\+/  s/^#//g              " \
				    -e "/^#repo[ \t]\+/ s/^#//g              " \
				    -e "s/\$releasever/${_DSTR_NUMS}/g       " \
				    -e "s/\$basearch/${_BASE_ARCH}/g      }} "
				;;
		esac
		# --- post script -----------------------------------------------------
		sed -i "${_FILE_PATH}"                         \
		    -e "/%post/,/%end/                     { " \
		    -e "s/\$releasever/${_RLNX_NUMS}/g       " \
		    -e "s/\$basearch/${_BASE_ARCH}/g       } "
		case "${_DSTR_NAME}" in
			fedora        | \
			centos-stream )
				sed -i "${_FILE_PATH}"                         \
				    -e "/%post/,/%end/                     { " \
				    -e "/install repositories/ s/^/#/        " \
				    -e "/epel-release/         s/^/#/        " \
				    -e "/remi-release/         s/^/#/      } "
				;;
			* ) ;;
		esac
		# --- RHL ver <= 8, time zone & ntp server ----------------------------
		if [[ ${_RLNX_NUMS} -le 8 ]]; then
			sed -i "${_FILE_PATH}"                     \
			    -e "/^timesource/             s/^/#/g" \
			    -e "/^timezone/               s/^/#/g" \
			    -e "/timezone.* --ntpservers/ s/^#//g"
		fi
		# --- fedora ----------------------------------------------------------
		if [[ "${_DSTR_NAME}" = "fedora" ]]; then
			sed -i "${_FILE_PATH}"                     \
			    -e "/^#.*(${_DSTR_SECT}).*$/,/^$/  { " \
			    -e "/_WEBADDR_/                    { " \
			    -e "/^repo[ \t]\+/  s/^/#/g        } " \
			    -e "/_WEBADDR_/!                   { " \
			    -e "/^#repo[ \t]\+/ s/^#//g       }} "
		fi
		case "${_FILE_LIST[I]}" in
			*_web* )
				sed -i "${_FILE_PATH}"                         \
				    -e "/^#.*(${_DSTR_SECT}).*$/,/^$/      { " \
				    -e "s%_WEBADDR_%${_IMGS_ADDR}%g        } " \
				;;
			* )
				;;
		esac
#		sed -i "${_FILE_PATH}"                         \
#		    -e "/^#.*(${_DSTR_SECT}).*$/,/^$/      { " \
#		    -e "s%_WEBADDR_%${WEBS_ADDR}/imgs%g    } "
		sed -e "/%packages/,/%end/ {"                  \
		    -e "/desktop/ s/^-//g  }"                  \
		    "${_FILE_PATH}"                            \
		>   "${_FILE_PATH/\.cfg/_desktop\.cfg}"
	done
	chmod ugo-x "${_DIRS_NAME}/"*
}

# ----- get leap versions -----------------------------------------------------
function funcCreate_autoyast_version() {
	declare -a    _LINE=()

	for I in "${!DATA_LIST[@]}"
	do
		read -r -a _LINE < <(echo "${DATA_LIST[I]}")
		if [[ "${_LINE[0]}" != "o" ]]; then
			continue
		fi
		case "${_LINE[1]}" in
			opensuse-leap-*) echo "${_LINE[1]##*[^0-9.]}";;
			*              ) continue;;
		esac
	done | sort -uV
}

# ----- create autoyast.xml ---------------------------------------------------
function funcCreate_autoyast() {
	declare -r    _DIRS_NAME="${DIRS_CONF}/autoyast"
	declare       _FILE_PATH=""
	declare       _VERS_LIST=""
	declare       _VERS_LEAP=""
	declare -a    _FILE_LIST=()
	declare       _DSTR_NUMS=""
	declare -r    _BASE_ARCH="x86_64"
	declare -i    I=0
	# -------------------------------------------------------------------------
	_VERS_LIST="$(funcCreate_autoyast_version)"
	_VERS_LEAP="${_VERS_LIST//$'\n'/,}"
	read -r -a _FILE_LIST < <(eval "echo autoinst_{leap-{${_VERS_LEAP}},tumbleweed}_{net,dvd}{,_lxde}.xml" || true)
	# -------------------------------------------------------------------------
	for I in "${!_FILE_LIST[@]}"
	do
		_FILE_PATH="${_DIRS_NAME}/${_FILE_LIST[I]}"
		funcPrintf "%20.20s: %s" "create file" "${_FILE_PATH/${PWD}\/}"
		mkdir -p "${_FILE_PATH%/*}"
		# ---------------------------------------------------------------------
		_DSTR_NUMS="$(echo "${_FILE_LIST[I]}" | sed -ne 's%^.*_\(leap-[0-9.]\+\|tumbleweed\)_.*$%\1%p')"
		# ---------------------------------------------------------------------
		cp --backup "${CONF_YAST}" "${_FILE_PATH}"
		if [[ "${_DSTR_NUMS}" =~ leap ]]; then
			sed -i "${_FILE_PATH}"                                                 \
			    -e '\%<add_on_products .*>%,\%</add_on_products>%              { ' \
			    -e '/<!-- leap/,/leap -->/                                     { ' \
			    -e "/<media_url>/ s~/\(leap\)/[0-9.]*/~/\1/${_DSTR_NUMS#*-}/~g   " \
			    -e "/<media_url>/ s~/\(leap\)/[0-9.]*/~/\1/${_DSTR_NUMS#*-}/~g } " \
			    -e '/<!-- leap$/ s/$/ -->/g                                      ' \
			    -e '/^leap -->/  s/^/<!-- /g                                   } ' \
			    -e 's~\(<product>\).*\(</product>\)~\1Leap\2~                    '
		else
			sed -i "${_FILE_PATH}"                                                 \
			    -e '\%<add_on_products .*>%,\%<\/add_on_products>%             { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/                         { ' \
			    -e '/<media_url>/ s~/leap/[0-9.]*/~/tumbleweed/~g                ' \
			    -e '/<media_url>/ s~/leap/[0-9.]*/~/tumbleweed/~g              } ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                                ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                             } ' \
			    -e 's~\(<product>\).*\(</product>\)~\1openSUSE\2~                '
		fi
		if [[ "${_FILE_PATH}" =~ _lxde ]]; then
			sed -i "${_FILE_PATH}"                    \
			    -e '/<!-- desktop lxde$/ s/$/ -->/g ' \
			    -e '/^desktop lxde -->/  s/^/<!-- /g'
		fi
		if [[ "${_FILE_PATH}" =~ _dvd ]]; then
			sed -i "${_FILE_PATH}"                                    \
			    -e '/<image_installation t="boolean">/ s/false/true/'
		else
			sed -i "${_FILE_PATH}"                                    \
			    -e '/<image_installation t="boolean">/ s/true/false/'
		fi
	done
	chmod ugo-x "${_DIRS_NAME}/"*
}

# ----- create menu -----------------------------------------------------------
function funcCreate_menu() {
	declare -a    _DATA_ARRY=("$@")
	declare -a    _DATA_LINE=()
	declare       _FILE_PATH=""
	declare -a    _FILE_INFO=()
	declare       _WEBS_ADDR=""			# web url
	declare       _WEBS_PATN=""			# web iso file name pattern
	declare -a    _WEBS_PAGE=()			# web page data
	declare       _WEBS_STAT=""			# web status
	declare       _TEXT_COLR=""			# message text color
	declare       _MESG_TEXT=""			# message text
	declare       _WORK_LINE=""			# array -> line
	declare       _WORK_TEXT=""
	declare -a    _WORK_ARRY=()
	declare -i    _RET_CODE=0
	declare -i    I=0
	declare -i    J=0
	# -------------------------------------------------------------------------
	funcPrintf "# ${TEXT_GAP1:1:((${#TEXT_GAP1}-4))} #"
	funcPrintf "${TXT_RESET}#%-2.2s:%-42.42s:%-10.10s:%-10.10s:%-$((COLS_SIZE-70)).$((COLS_SIZE-70))s${TXT_RESET}#" "ID" "Version" "ReleaseDay" "SupportEnd" "Memo"
#	IFS= mapfile -d ' ' -t _WORK_ARRY < <(echo "${TGET_INDX}")
	TGET_LIST=()
	for I in "${!_DATA_ARRY[@]}"
	do
		_WORK_TEXT="$(echo -n "${_DATA_ARRY[I]}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
		IFS=$'\n' mapfile -d ' ' -t _DATA_LINE < <(echo -n "${_WORK_TEXT}")
		if [[ "${_DATA_LINE[0]}" != "o" ]] \
		|| { [[ "${_DATA_LINE[17]%%//*}" != "http:" ]] && [[ "${_DATA_LINE[17]%%//*}" != "https:" ]]; }; then
			continue
		fi
		_TEXT_COLR=""
		_MESG_TEXT=""
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
#		_DATA_LINE[11]="-"				# 11: release date
										# 12: support end
		_DATA_LINE[13]="-"				# 13: time stamp
		_DATA_LINE[14]="-"				# 14: file size
		_DATA_LINE[15]="-"				# 15: volume id
		_DATA_LINE[16]="-"				# 16: status
										# 17: download URL
										# 18: time stamp of remastered image file
		# --- URL completion [dir name] ---------------------------------------
		_WEBS_ADDR="${_DATA_LINE[17]}"
		while [[ -n "${_WEBS_ADDR//[^?*\[\]]}" ]]
		do
			_WEBS_ADDR="${_WEBS_ADDR%%[*}"
			_WEBS_ADDR="${_WEBS_ADDR%/*}"
			_WEBS_PATN="${_DATA_LINE[17]/"${_WEBS_ADDR}/"}"
			_WEBS_PATN="${_WEBS_PATN%%/*}"
			if ! _WORK_TEXT="$(LANG=C wget "${WGET_OPTN[@]}" --trust-server-names --output-document=- "${_WEBS_ADDR}" 2>&1)"; then
				_RET_CODE="$?"
				_WORK_TEXT="${_WORK_TEXT//["${IFS}"]/ }"
				_WORK_TEXT="${_WORK_TEXT#"${_WORK_TEXT%%[!"${IFS}"]*}"}"	# ltrim
				_WORK_TEXT="${_WORK_TEXT%"${_WORK_TEXT##*[!"${IFS}"]}"}"	# rtrim
				_MESG_TEXT="get pattern : error ${_RET_CODE}: ${_WORK_TEXT}"
#				printf "[%s]\n" "${_WORK_TEXT}"
				_TEXT_COLR="${TXT_RED}"
				break
			fi
			_WORK_ARRY=()
			IFS= mapfile -d $'\n' _WEBS_PAGE < <(echo -n "${_WORK_TEXT}")
			if ! _WORK_TEXT="$(echo "${_WEBS_PAGE[@]}" | grep "<a href=\"${_WEBS_PATN}/*\">")"; then
				continue
			fi
			IFS= mapfile -d $'\n' _WORK_ARRY < <(echo -n "${_WORK_TEXT}")
			_WORK_ARRY=("$(echo "${_WORK_ARRY[@]}" | sed -ne 's/^.*\('"${_WEBS_PATN}"'\).*$/\1/p')")
			_WORK_TEXT="$(printf "%s\n" "${_WORK_ARRY[@]}" | sort -rVu -t $'\n')"
			IFS= mapfile -d $'\n' -t _WORK_ARRY < <(echo -n "${_WORK_TEXT}")
			_WEBS_ADDR="${_DATA_LINE[17]/"${_WEBS_PATN}"/"${_WORK_ARRY[0]}"}"
			_DATA_LINE[17]="${_WEBS_ADDR}"
		done
		# --- get and set local image file information ------------------------
		_FILE_PATH="${_DATA_LINE[4]}/${_DATA_LINE[5]}"
		if [[ ! -e "${_FILE_PATH}" ]]; then
			_TEXT_COLR="${_TEXT_COLR:-"${TXT_CYAN}"}"
		else
			IFS= mapfile -d ' ' -t _FILE_INFO < <(LANG=C TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${_FILE_PATH}" || true)
			_DATA_LINE[11]="${_FILE_INFO[5]:0:4}-${_FILE_INFO[5]:4:2}-${_FILE_INFO[5]:6:2}"
			_DATA_LINE[13]="${_FILE_INFO[5]}"
			_DATA_LINE[14]="${_FILE_INFO[4]}"
			_DATA_LINE[15]="$(LANG=C file -L "${_FILE_PATH}")"
			_DATA_LINE[15]="${_DATA_LINE[15]#*\'}"
			_DATA_LINE[15]="${_DATA_LINE[15]%\'*}"
			_DATA_LINE[15]="${_DATA_LINE[15]// /%20}"
			_TEXT_COLR="${_TEXT_COLR:-""}"
		fi
		# --- get and set server-side image file information ------------------
		if [[ "${_TEXT_COLR}" != "${TXT_RED}" ]]; then
			if ! _WORK_TEXT="$(LANG=C wget "${WGET_OPTN[@]}" --trust-server-names --spider --server-response --output-document=- "${_WEBS_ADDR}" 2>&1)"; then
				_RET_CODE="$?"
				_WORK_TEXT="${_WORK_TEXT//["${IFS}"]/ }"
				_WORK_TEXT="${_WORK_TEXT#"${_WORK_TEXT%%[!"${IFS}"]*}"}"	# ltrim
				_WORK_TEXT="${_WORK_TEXT%"${_WORK_TEXT##*[!"${IFS}"]}"}"	# rtrim
				_MESG_TEXT="get response: error ${_RET_CODE}: ${_WORK_TEXT}"
#				printf "[%s]\n" "${_WORK_TEXT}"
				_TEXT_COLR="${TXT_RED}"
			fi
			_WORK_TEXT="$(echo -n "${_WORK_TEXT}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
			IFS= mapfile -d $'\n' -t _WEBS_PAGE < <(echo -n "${_WORK_TEXT}")
			_WEBS_STAT=""
			for J in "${!_WEBS_PAGE[@]}"
			do
				_WORK_LINE="${_WEBS_PAGE[J]}"
				_WORK_TEXT="${_WORK_LINE,,}"
				_WORK_TEXT="${_WORK_TEXT#"${_WORK_TEXT%%[!"${IFS}"]*}"}"	# ltrim
				_WORK_TEXT="${_WORK_TEXT%"${_WORK_TEXT##*[!"${IFS}"]}"}"	# rtrim
				_WORK_TEXT="${_WORK_TEXT%% *}"
				case "${_WORK_TEXT}" in
					http/*)
						_WORK_TEXT="${_WORK_LINE}"
						_WORK_TEXT="${_WORK_TEXT#"${_WORK_TEXT%%[!"${IFS}"]*}"}"	# ltrim
						_WORK_TEXT="${_WORK_TEXT%"${_WORK_TEXT##*[!"${IFS}"]}"}"	# rtrim
						_WORK_TEXT="${_WORK_TEXT#* }"
						_WEBS_STAT="${_WORK_TEXT%% *}"
						case "${_WEBS_STAT}" in			# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
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
								_WORK_TEXT="${_WORK_LINE}"
								_WORK_TEXT="${_WORK_TEXT#"${_WORK_TEXT%%[!"${IFS}"]*}"}"	# ltrim
								_WORK_TEXT="${_WORK_TEXT%"${_WORK_TEXT##*[!"${IFS}"]}"}"	# rtrim
								_MESG_TEXT="${_WORK_LINE}"
#								printf "[%s]\n" "${_WEBS_PAGE[@]}"
								_TEXT_COLR="${TXT_RED}"
								break
								;;
						esac
						;;
					content-length:)
						if [[ "${_WEBS_STAT}" != "200" ]]; then
							continue
						fi
						_WORK_TEXT="${_WORK_LINE#* }"
						if [[ "${_DATA_LINE[14]}" != "${_WORK_TEXT}" ]]; then
							_TEXT_COLR="${_TEXT_COLR:-"${TXT_GREEN}"}"
						fi
						_DATA_LINE[14]="${_WORK_TEXT}"
#						_DATA_LINE[16]+="${_DATA_LINE[16]:+","}${_WORK_LINE%%:*}=${_WORK_TEXT}"
						;;
					last-modified:)
						if [[ "${_WEBS_STAT}" != "200" ]]; then
							continue
						fi
						_WORK_TEXT="$(TZ=UTC date -d "${_WORK_LINE#* }" "+%Y%m%d%H%M%S")"
						if [[ "${_DATA_LINE[13]}" != "${_WORK_TEXT}" ]]; then
							_TEXT_COLR="${_TEXT_COLR:-"${TXT_GREEN}"}"
						fi
						_DATA_LINE[11]="${_WORK_TEXT:0:4}-${_WORK_TEXT:4:2}-${_WORK_TEXT:6:2}"
						_WORK_TEXT="$(TZ=UTC date -d "${_WORK_LINE#* }" "+%Y-%m-%d_%H:%M:%S")"
#						_DATA_LINE[16]+="${_DATA_LINE[16]:+","}${_WORK_LINE%%:*}=${_WORK_TEXT}"
						;;
					*)
						;;
				esac
			done
		fi
		# --- get remastered image file information ---------------------------
		_FILE_PATH="${DIRS_RMAK}/${_DATA_LINE[5]%.*}_${_DATA_LINE[9]%%/*}.${_DATA_LINE[5]##*.}"
		if [[ ! -e "${_FILE_PATH}" ]]; then
			_TEXT_COLR="${_TEXT_COLR:-"${TXT_YELLOW}"}${TXT_REV}"
		else
			IFS= mapfile -d ' ' -t _FILE_INFO < <(LANG=C TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${_FILE_PATH}" || true)
			_DATA_LINE+=("${_FILE_INFO[5]}")
			if [[ "${_DATA_LINE[13]}" != "-" ]] \
			&& [[ "${_DATA_LINE[18]}" != "-" ]] \
			&& [[ "${_DATA_LINE[13]}" -gt "${_DATA_LINE[18]}" ]]; then
				_TEXT_COLR="${_TEXT_COLR:-"${TXT_YELLOW}"}${TXT_REV}"
			else
				case "${_DATA_LINE[9]%%/*}" in
					nocloud) _FILE_PATH="${DIRS_CONF}/${_DATA_LINE[9]}/user-data";;
					*      ) _FILE_PATH="${DIRS_CONF}/${_DATA_LINE[9]}";;
				esac
				if [[ -e "${_FILE_PATH}" ]]; then
					IFS= mapfile -d ' ' -t _FILE_INFO < <(LANG=C TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${_FILE_PATH}" || true)
					if [[ "${_FILE_INFO[5]}" -gt "${_DATA_LINE[18]}" ]]; then
						_TEXT_COLR="${_TEXT_COLR:-"${TXT_YELLOW}"}${TXT_REV}"
					fi
				fi
			fi
		fi
		# --- set download status ---------------------------------------------
		_DATA_LINE[16]="${_TEXT_COLR}"
		_DATA_LINE[16]="${_DATA_LINE[16]// /%20}"
		_DATA_LINE[16]="${_DATA_LINE[16]:-"-"}"
		# --- set target data information -------------------------------------
		if [[ "${_DBGOUT:-}" = "true" ]]; then
			printf "${TXT_RESET}[%s]${TXT_RESET}\n" "${_DATA_LINE[@]//${ESC}/\\033}"
		fi
		_DATA_ARRY[I]="${_DATA_LINE[*]}"
#		TGET_LIST+=("${_DATA_LINE[*]}")
		# --- display of target data information ------------------------------
		_WORK_TEXT="${_DATA_LINE[2]//%20/ }"
		_WORK_TEXT="${_WORK_TEXT%_*}[${_DATA_LINE[9]##*/}]"
		_WORK_TEXT="${_MESG_TEXT:-"${_WORK_TEXT}"}"
		funcPrintf "${TXT_RESET}#${_TEXT_COLR}%2.2s:%-42.42s:%-10.10s:%-10.10s:%-$((COLS_SIZE-70)).$((COLS_SIZE-70))s${TXT_RESET}#" "${I}" "${_DATA_LINE[5]}" "${_DATA_LINE[11]}" "${_DATA_LINE[12]}" "${_WORK_TEXT}"
	done
	TGET_LIST=("${_DATA_ARRY[@]}")
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
	declare -r -a _TGET_LINE=("$@")
	declare -r    _FILE_PATH="${_TGET_LINE[4]}/${_TGET_LINE[5]}"
	declare       _WORK_TEXT=""
	# --- download ------------------------------------------------------------
	case "${_TGET_LINE[16]}" in
		*${TXT_CYAN}*  | \
		*${TXT_GREEN}* )
			_WORK_TEXT="$(funcUnit_conversion "${_TGET_LINE[14]}")"
			funcPrintf "%20.20s: %s" "download" "${_TGET_LINE[5]} ${_WORK_TEXT}"
			if ! LANG=C wget "${WGET_OPTN[@]}" --continue --show-progress --output-document="${_FILE_PATH}.tmp" "${_TGET_LINE[17]}" 2>&1; then
				funcPrintf "%20.20s: %s" "error" "${TXT_RED}Download was skipped because an ${TXT_REV}error${TXT_REVRST} occurred [$?]${TXT_RESET}"
			else
				if [[ ! -e "${_FILE_PATH}" ]]; then
					touch "${_FILE_PATH}"
				fi
				if cp --preserve=timestamps "${_FILE_PATH}.tmp" "${_FILE_PATH}"; then
					rm "${_FILE_PATH}.tmp"
					DATA_LINE[16]="$(LANG=C file -L "${_FILE_PATH}")"
				fi
			fi
			;;
		*)	;;
	esac
}

# ----- copy iso contents to hdd ----------------------------------------------
function funcCreate_copy_iso2hdd() {
	declare -r -a _TGET_LINE=("$@")
	declare -r    _FILE_PATH="${_TGET_LINE[4]}/${_TGET_LINE[5]}"
	declare -r    _WORK_DIRS="${DIRS_TEMP}/${_TGET_LINE[1]}"
	declare       _DIRS_IRAM=""								# initrd image directory
	declare       _FILE_IRAM=""								# initrd path
#	declare       _FILE_VLNZ=""								# kernel path
	# -------------------------------------------------------------------------
	WORK_TEXT="$(funcUnit_conversion "${_TGET_LINE[14]}")"
	funcPrintf "%20.20s: %s" "copy" "${_TGET_LINE[5]} ${WORK_TEXT}"
	# --- copy iso -> hdd -----------------------------------------------------
	rm -rf "${_WORK_DIRS:?}"
	mkdir -p "${_WORK_DIRS}/"{mnt,img,ram}
	mount -o ro,loop "${_FILE_PATH}" "${_WORK_DIRS}/mnt"
	ionice -c "${IONICE_CLAS}" cp -a "${_WORK_DIRS}/mnt/." "${_WORK_DIRS}/img/"
	umount "${_WORK_DIRS}/mnt"
	# --- copy initrd -> hdd --------------------------------------------------
	find "${_WORK_DIRS}/img" \( -type f -o -type l \) \( -name 'initrd' -o -name 'initrd.*' -o -name 'initrd-[0-9]*' \) | sort -V | \
	while read -r _FILE_IRAM
	do
		_DIRS_IRAM="${_WORK_DIRS}/ram/${_FILE_IRAM##*/}/"
		funcPrintf "%20.20s: %s" "copy" "${_FILE_IRAM##*/}"
		mkdir -p "${_DIRS_IRAM}"
		unmkinitramfs "${_FILE_IRAM}" "${_DIRS_IRAM}" 2>/dev/null
	done
}

# ----- create autoinst.cfg for syslinux --------------------------------------
function funcCreate_autoinst_cfg_syslinux() {
	declare -r    _AUTO_PATH="$1"							# autoinst.cfg path
	declare       _BOOT_OPTN="$2"							# boot option
	shift 2
	declare -r -a _TGET_LINE=("$@")
	declare       _FILE_PATH=""								# file path
	declare -a    _FILE_VLNZ=()								# kernel path
	declare -a    _FILE_IRAM=()								# initrd path (initrd)
	declare -a    _FILE_ARRY=()								# kernel/initrd path array
	declare       _PATH_VLNZ=""								# kernel path
	declare       _PATH_IRAM=""								# initrd path (initrd)
	declare -a    _WORK_ARRY=()								# work array
	declare -A    _WORK_AARY=()								# work associative arrays
	declare       _WORK_TEXT=""								# work text
	declare       _DIRS_NAME=""								# directory name
	declare       _BASE_NAME=""								# file name
	declare -i    I=0
	# -------------------------------------------------------------------------
	_FILE_VLNZ=()
	_FILE_IRAM=()
	_FILE_ARRY=()
	_WORK_ARRY=()
	while read -r _FILE_PATH
	do
		IFS= mapfile -d $'\n' -t _WORK_ARRY < <(sed -ne '/^[ \t]*\(label\|Label\|LABEL\)[ \t]\+\(install\(\|gui\|start\)\|linux\|live-install\|live\|[[:print:]]*Installer\|textinstall\|graphicalinstall\)[ \t'$'\r'']*$/,/^\(\|[ \t]*\(initrd\|append\)[[:print:]]*\)['$'\r'']*$/{s/^[ \t]*//g;s/[ \t]*$//g;/^$/d;p}' "${_FILE_PATH}" || true)
		if [[ -z "${_WORK_ARRY[*]:-}" ]]; then
			continue
		fi
		IFS= mapfile -d $'\n' -t                        _FILE_VLNZ < <(printf "%s\n" "${_WORK_ARRY[@]}" | sed -ne 's/^[ \t]*\([Kk]ernel\|[Ll]inux\|KERNEL\|LINUX\)[ \t]\+\([[:graph:]]\+\).*/\2/p' || true)
		IFS= mapfile -d $'\n' -t                        _FILE_IRAM < <(printf "%s\n" "${_WORK_ARRY[@]}" | sed -ne 's/^[ \t]*\([Ii]nitrd\|INITRD\)[ \t]\+\([[:graph:]]\+\).*/\2/p' || true)
		IFS= mapfile -d $'\n' -t -O "${#_FILE_IRAM[@]}" _FILE_IRAM < <(printf "%s\n" "${_WORK_ARRY[@]}" | sed -ne 's/^[ \t]*\([Aa]ppend\|APPEND\)[ \t]\+[[:print:]]*initrd=\([[:graph:]]\+\).*/\2/p' || true)
		case "${_FILE_PATH}" in
			*-mini-*)
				for I in "${!_FILE_IRAM[@]}"
				do
					if [[ "${_FILE_IRAM[I]%/*}" = "${_FILE_IRAM[I]}" ]]; then
						_FILE_IRAM[I]="${MINI_IRAM}"
					else
						_FILE_IRAM[I]="${_FILE_IRAM[I]%/*}/${MINI_IRAM}"
					fi
				done
				;;
			*)	;;
		esac
		for I in "${!_FILE_IRAM[@]}"
		do
			_FILE_ARRY+=("${_FILE_VLNZ[I]},${_FILE_IRAM[I]}")
		done
	done < <(find "${_AUTO_PATH%/*}/" \( -type f -o -type l \) \( -name 'isolinux.cfg' -o -name 'txt.cfg' -o -name 'gtk.cfg' -o -name 'install.cfg' -o -name 'menu.cfg' \) | sort -V || true)
	# --- sort -----------------------------------------------------------------
	_WORK_AARY=()
	for I in "${!_FILE_ARRY[@]}"
	do
		_PATH_VLNZ="${_FILE_ARRY[I]%,*}"
		_PATH_IRAM="${_FILE_ARRY[I]#*,}"
		_WORK_TEXT="${_PATH_VLNZ%/*}%${_PATH_IRAM%/*}"
		_WORK_TEXT="${_WORK_TEXT//\//_}"
		_WORK_AARY+=(["${_WORK_TEXT}"]="${_FILE_ARRY[I]}")
	done
	_FILE_ARRY=()
	for _WORK_TEXT in $(printf "%s\n" "${!_WORK_AARY[@]}" | sort -Vu)
	do
		_FILE_ARRY+=("${_WORK_AARY["${_WORK_TEXT}"]}")
	done
	# --- create autoinst.cfg ---------------------------------------------
	_BOOT_OPTN="${SCRN_MODE:+"vga=${SCRN_MODE}"}${_BOOT_OPTN:+" ${_BOOT_OPTN}"}"
	rm -f "${_AUTO_PATH}"
	for I in "${!_FILE_ARRY[@]}"
	do
		_PATH_VLNZ="${_FILE_ARRY[I]%,*}"
		_PATH_IRAM="${_FILE_ARRY[I]#*,}"
		if [[ ! -e "${_AUTO_PATH}" ]]; then
			# --- standard installation mode ------------------------------
			funcPrintf "%20.20s: %s" "create" "menu entry     ${I}: [${_PATH_IRAM}][${_PATH_VLNZ}]"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_AUTO_PATH}"
				${MENU_RESO:+"menu resolution ${MENU_RESO/x/ }"}
				menu title Boot Menu: ${_TGET_LINE[5]%.*}_${_TGET_LINE[9]%%/*}.${_TGET_LINE[5]##*.} ${_TGET_LINE[11]} ${_TGET_LINE[13]:0:2}:${_TGET_LINE[13]:2:2}:${_TGET_LINE[13]:4:2}
				menu tabmsg Press ENTER to boot or TAB to edit a menu entry
				menu background splash.png
				menu width 80
				menu margin 0
				menu hshift 0
				#menu vshift 0
				
				timeout ${MENU_TOUT}
				
				label auto_install
				 	menu label ^Automatic installation
				 	menu default
				 	kernel ${_PATH_VLNZ}
				 	append${_PATH_IRAM:+" initrd=${_PATH_IRAM}"}${_BOOT_OPTN:+" "}${_BOOT_OPTN} ---
				
_EOT_
		elif [[ "${_PATH_IRAM}" =~ /gtk/ ]]; then
			# --- graphical installation mode -----------------------------
			funcPrintf "%20.20s: %s" "create" "menu entry gui ${I}: [${_PATH_IRAM}][${_PATH_VLNZ}]"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_AUTO_PATH}"
				label auto_install_gui
				 	menu label ^Automatic installation of gui
				 	kernel ${_PATH_VLNZ}
				 	append${_PATH_IRAM:+" initrd=${_PATH_IRAM}"}${_BOOT_OPTN:+" "}${_BOOT_OPTN} ---
				
_EOT_
		fi
	done
}

# ----- create autoinst.cfg for grub ------------------------------------------
function funcCreate_autoinst_cfg_grub() {
	declare -r    _AUTO_PATH="$1"							# autoinst.cfg path
	declare       _BOOT_OPTN="$2"							# boot option
	shift 2
	declare -r -a _TGET_LINE=("$@")
	declare       _FILE_PATH=""								# file path
	declare -a    _FILE_VLNZ=()								# kernel path
	declare -a    _FILE_IRAM=()								# initrd path (initrd)
	declare -a    _FILE_ARRY=()								# kernel/initrd path array
	declare       _PATH_VLNZ=""								# kernel path
	declare       _PATH_IRAM=""								# initrd path (initrd)
	declare -a    _WORK_ARRY=()								# work array
	declare -A    _WORK_AARY=()								# work associative arrays
	declare       _WORK_TEXT=""								# work text
	declare       _DIRS_NAME=""								# directory name
	declare       _BASE_NAME=""								# file name
	declare -r    _WORK_IMGS="${DIRS_TEMP}/${_TGET_LINE[1]}/img"
	declare -r    _FILE_FONT="$(find "${_WORK_IMGS}" \( -name 'font.pf2' -o -name 'unicode.pf2' \) -type f)"
	declare       _CONF_WORK="${_AUTO_PATH%/*}/theme.txt"
	declare -i    I=0
	# -------------------------------------------------------------------------
	_FILE_VLNZ=()
	_FILE_IRAM=()
	_FILE_ARRY=()
	_WORK_ARRY=()
	while read -r _FILE_PATH
	do
		IFS= mapfile -d $'\n' -t _WORK_ARRY < <(sed -ne '/^[ \t]*\(menuentry\|Menuentry\|MENUENTRY\)[ \t]\+.*['\''"][[:print:]]*[Ii]nstall\(\|er\)[[:print:]]*['\''"][[:print:]]*{/,/^[ \t]*}$/{s/^[ \t]*//g;s/[ \t]*$//g;/^$/d;p}' "${_FILE_PATH}" || true)
		if [[ -z "${_WORK_ARRY[*]:-}" ]]; then
			continue
		fi
		IFS= mapfile -d $'\n' -t                       _FILE_VLNZ < <(printf "%s\n" "${_WORK_ARRY[@]}" | sed -ne 's%^[ \t]*\(linux\(\|efi\)\)[ \t]\+\([[:graph:]]*/\(vmlinuz\|linux\)\)[ \t]*.*$%\3%p' || true)
		IFS= mapfile -d $'\n' -t                       _FILE_IRAM < <(printf "%s\n" "${_WORK_ARRY[@]}" | sed -ne 's%^[ \t]*\(initrd\(\|efi\)\)[ \t]\+\([[:graph:]]*/\(initrd.*\)\)[ \t]*.*$%\3%p' || true)
		case "${_FILE_PATH}" in
			*-mini-*)
				for I in "${!_FILE_IRAM[@]}"
				do
					if [[ "${_FILE_IRAM[I]%/*}" = "${_FILE_IRAM[I]}" ]]; then
						_FILE_IRAM[I]="${MINI_IRAM}"
					else
						_FILE_IRAM[I]="${_FILE_IRAM[I]%/*}/${MINI_IRAM}"
					fi
				done
				;;
			*)	;;
		esac
		for I in "${!_FILE_IRAM[@]}"
		do
			_FILE_ARRY+=("${_FILE_VLNZ[I]},${_FILE_IRAM[I]}")
		done
	done < <(find "${_AUTO_PATH%/*}/" \( -type f -o -type l \) \( -name 'grub.cfg' -o -name 'install.cfg' \) | sort -V || true)
	# --- sort -----------------------------------------------------------------
	_WORK_AARY=()
	for I in "${!_FILE_ARRY[@]}"
	do
		_PATH_VLNZ="${_FILE_ARRY[I]%,*}"
		_PATH_IRAM="${_FILE_ARRY[I]#*,}"
		_WORK_TEXT="${_PATH_VLNZ%/*}%${_PATH_IRAM%/*}"
		_WORK_TEXT="${_WORK_TEXT//\//_}"
		_WORK_AARY+=(["${_WORK_TEXT}"]="${_FILE_ARRY[I]}")
	done
	_FILE_ARRY=()
	for _WORK_TEXT in $(printf "%s\n" "${!_WORK_AARY[@]}" | sort -Vu)
	do
		_FILE_ARRY+=("${_WORK_AARY["${_WORK_TEXT}"]}")
	done
	# --- create autoinst.cfg ---------------------------------------------
	_BOOT_OPTN="${SCRN_MODE:+"vga=${SCRN_MODE}"}${_BOOT_OPTN:+" ${_BOOT_OPTN}"}"
	rm -f "${_AUTO_PATH}"
	for I in "${!_FILE_ARRY[@]}"
	do
		_PATH_VLNZ="${_FILE_ARRY[I]%,*}"
		_PATH_IRAM="${_FILE_ARRY[I]#*,}"
		if [[ ! -e "${_AUTO_PATH}" ]]; then
			# --- standard installation mode ------------------------------
			funcPrintf "%20.20s: %s" "create" "menu entry     ${I}: [${_PATH_IRAM}][${_PATH_VLNZ}]"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_AUTO_PATH}"
				if [ -e ${_FILE_FONT/${_WORK_IMGS}/} ]; then
				 	font=${_FILE_FONT/${_WORK_IMGS}/}
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
				set theme=${_CONF_WORK#"${_WORK_IMGS}"}
				export theme
				
				menuentry 'Automatic installation' {
				 	set gfxpayload=keep
				 	set background_color=black
				 	echo 'Loading kernel ...'
				 	linux  ${_PATH_VLNZ}${_BOOT_OPTN:+" ${_BOOT_OPTN}"} ---
				 	echo 'Loading initial ramdisk ...'
				 	initrd ${_PATH_IRAM}
				}
				
_EOT_
		elif [[ "${_PATH_IRAM}" =~ /gtk/ ]]; then
			# --- graphical installation mode -----------------------------
			funcPrintf "%20.20s: %s" "create" "menu entry gui ${I}: [${_PATH_IRAM}][${_PATH_VLNZ}]"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_AUTO_PATH}"
				menuentry 'Automatic installation of gui' {
				 	set gfxpayload=keep
				 	set background_color=black
				 	echo 'Loading kernel ...'
				 	linux  ${_PATH_VLNZ}${_BOOT_OPTN:+" ${_BOOT_OPTN}"} ---
				 	echo 'Loading initial ramdisk ...'
				 	initrd ${_PATH_IRAM}
				}
				
_EOT_
		fi
	done
}

# ----- create theme.txt ------------------------------------------------------
# https://www.gnu.org/software/grub/manual/grub/html_node/Theme-file-format.html
function funcCreate_theme_txt() {
	declare -r    _WORK_IMGS="$1"							# cd-rom image working directory
	declare -r    _DIRS_MENU="$2"							# configuration file directory
	shift 2
	declare -r -a _TGET_LINE=("$@")
	declare -r    _CONF_FILE="${_DIRS_MENU}/theme.txt"		# configuration file path
	declare -r    _IMGS_NAME="splash.png"					# desktop image file name
	declare -a    _IMGS_FILE=()								# desktop image file path
	declare       _IMGS_PATH=""
	declare       _CONF_WORK=""
	declare -i    I=0

	funcPrintf "%20.20s: %s" "create" "${_CONF_FILE##*/}"
	rm -f "${_CONF_FILE}"
	while read -r _CONF_WORK
	do
		mapfile -t _IMGS_FILE < <(sed -ne '/'"${_IMGS_NAME}"'/ s%^.*[ \t]\+\([[:graph:]]*/*'"${_IMGS_NAME}"'\).*$%\1%p' "${_CONF_WORK}" || true)
		if [[ -z "${_IMGS_FILE[*]}" ]]; then
			mapfile -t _IMGS_FILE < <(find "${_WORK_IMGS}" \( -name "${_IMGS_NAME}" -o -name 'back.jpg' \) || true)
			if [[ -z "${_IMGS_FILE[*]}" ]]; then
				_IMGS_FILE=("${_DIRS_MENU}/${_IMGS_NAME}")
				pushd "${_DIRS_MENU}" > /dev/null
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
			for I in "${!_IMGS_FILE[@]}"
			do
				_IMGS_FILE[I]="${_IMGS_FILE[I]/${_WORK_IMGS}/}"
			done
		fi
		for I in "${!_IMGS_FILE[@]}"
		do
			_IMGS_PATH="${_WORK_IMGS}/${_IMGS_FILE[I]#/}"
			if [[ -e "${_IMGS_PATH}" ]] \
			&& { { [[ "${_IMGS_PATH##*.}" = "png" ]] && [[ "$(file "${_IMGS_PATH}" | awk '{sub("-bit.*", "", $8 ); print  $8;}' || true)" -ge 8 ]]; } \
			||   { [[ "${_IMGS_PATH##*.}" = "jpg" ]] && [[ "$(file "${_IMGS_PATH}" | awk '{sub(",.*",    "", $17); print $17;}' || true)" -ge 8 ]]; } }; then
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_CONF_FILE}"
					desktop-image: "${_IMGS_FILE[I]}"
_EOT_
				break 2
			fi
		done
	done < <(find "${_DIRS_MENU}" -name '*.cfg' -type f || true)
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_CONF_FILE}"
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		title-text: "Boot Menu: ${_TGET_LINE[5]%.*}_${_TGET_LINE[9]%%/*}.${_TGET_LINE[5]##*.} ${_TGET_LINE[11]} ${_TGET_LINE[13]:0:2}:${_TGET_LINE[13]:2:2}:${_TGET_LINE[13]:4:2}"
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
	declare -r    _BOOT_OPTN="$1"
	shift
	declare -r -a _TGET_LINE=("$@")
	declare -r    _WORK_DIRS="${DIRS_TEMP}/${_TGET_LINE[1]}"
	declare -r    _WORK_IMGS="${_WORK_DIRS}/img"
	declare -a    _WORK_ARRY=()
	declare -i    _AUTO_FLAG=0
	declare       _FILE_MENU=""			# syslinux or isolinux path
	declare       _DIRS_MENU=""			# configuration file directory
	declare       _FILE_CONF=""			# configuration file path
	declare       _INSR_STRS=""			# string to insert
	funcPrintf "%20.20s: %s" "edit" "add ${AUTO_INST} to syslinux.cfg"
	# shellcheck disable=SC2312
	while read -r _FILE_MENU
	do
		_DIRS_MENU="${_FILE_MENU%/*}"
		_AUTO_FLAG=0
		# --- editing the configuration file ----------------------------------
		for _FILE_CONF in "${_DIRS_MENU}/"*.cfg
		do
			# --- comment out "timeout","menu default","ontimeout","menu tabmsg" ---
			set +e
			read -r -a _WORK_ARRY < <(                                                                           \
				sed -ne '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]\+[0-9]\+[^[:graph:]]*$/p'                          \
				    -ne '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]\+[0-9]\+[^[:graph:]]*$/p'                            \
				    -ne '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[^[:graph:]]*$/p'                \
				    -ne '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]\+.*[^[:graph:]]*$/p'                           \
				    -ne '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]\+.*[^[:graph:]]*$/p'     \
				    -ne '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]\+.*[^[:graph:]]*$/p'         \
				    -ne '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]\+.*[^[:graph:]]*$/p' \
				    -e  '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]\+/ {' -ne '/.*\.c32/!p}'                           \
				    "${_FILE_CONF}"
			)
			set -e
			if [[ -n "${_WORK_ARRY[*]}" ]]; then
				sed -i "${_FILE_CONF}"                                                                                  \
				    -e '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]\+[0-9]\+[^[:graph:]]*$/                          s/^/#/g'  \
				    -e '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]\+[0-9]\+[^[:graph:]]*$/                            s/^/#/g'  \
				    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[^[:graph:]]*$/                s/^/#/g'  \
				    -e '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]\+.*[^[:graph:]]*$/                           s/^/#/g'  \
				    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]\+.*[^[:graph:]]*$/     s/^/#/g'  \
				    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]\+.*[^[:graph:]]*$/         s/^/#/g'  \
				    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]\+.*[^[:graph:]]*$/ s/^/#/g'  \
				    -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]\+/ {' -e '/.*\.c32/!                              s/^/#/g}'
			fi
			# --- comment out "default" ---------------------------------------
			set +e
			read -r -a _WORK_ARRY < <(                                                                  \
				sed -e  '/^\([Ll]abel\|LABEL\)[ \t]\+.*/,/\(^[ \t]*$\|^\([Ll]abel\|LABEL\)[ \t]\+\)/ {' \
				    -e  '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]\+/                 {' -ne '/.*\.c32/!p}}' \
				    "${_FILE_CONF}"
			)
			set -e
			if [[ -n "${_WORK_ARRY[*]}" ]]; then
				sed -i "${_FILE_CONF}"                                                                 \
				    -e '/^\([Ll]abel\|LABEL\)[ \t]\+.*/,/\(^[ \t]*$\|^\([Ll]abel\|LABEL\)[ \t]\+\)/ {' \
				    -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]\+/           {' -e '/.*\.c32/! s/^/#/g}}'
			fi
			sed -i "${_FILE_CONF}"                                                      \
			    -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]\+/ {' -e '/.*\.c32/! s/^/#/g}'
			# --- insert "autoinst.cfg" ---------------------------------------
			set +e
			read -r -a _WORK_ARRY < <(                                                  \
				sed -ne '/^\([Ii]nclude\|INCLUDE\)[ \t]\+.*stdmenu.cfg[^[:graph:]]*$/p' \
				    "${_FILE_CONF}"
			)
			set -e
			if [[ -n "${_WORK_ARRY[*]}" ]]; then
				_AUTO_FLAG=1
				_INSR_STRS="$(sed -ne '/^\([Ii]nclude\|INCLUDE\)[ \t]\+[^ \t]*stdmenu.cfg[^[:graph:]]*$/p' "${_FILE_CONF}")"
				sed -i "${_FILE_CONF}"                                                                                                      \
				    -e '/^\(\([Ii]nclude\|INCLUDE\)[ \t]\+\)[^ \t]*stdmenu.cfg[^[:graph:]]*$/ a '"${_INSR_STRS/stdmenu.cfg/${AUTO_INST}}"''
			elif [[ "${_FILE_CONF##*/}" = "isolinux.cfg" ]]; then
				_AUTO_FLAG=1
				sed -i "${_FILE_CONF}"                                     \
				    -e '0,/\([Ll]abel\|LABEL\)/ {'                         \
				    -e '/\([Ll]abel\|LABEL\)/i include '"${AUTO_INST}"'\n' \
				    -e '}'
			fi
		done
		if [[ "${_AUTO_FLAG}" -ne 0 ]]; then
			funcCreate_autoinst_cfg_syslinux "${_DIRS_MENU}/${AUTO_INST}" "${_BOOT_OPTN}" "${_TGET_LINE[@]}"
		fi
	done < <(find "${_WORK_IMGS}" \( -name 'syslinux.cfg' -o -name 'isolinux.cfg' \) -type f)
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	while read -r CONF_WORK
#	do
#		funcCreate_gfxboot_cfg "${_WORK_IMGS}" "${CONF_WORK%/*}"
##	done < <(find "${_WORK_IMGS}" -name 'gfxboot.c32' -type f)
}

# ----- create grub.cfg -------------------------------------------------------
function funcCreate_grub_cfg() {
	declare -r    _BOOT_OPTN="$1"
	shift
	declare -r -a _TGET_LINE=("$@")
	declare -r    _WORK_DIRS="${DIRS_TEMP}/${_TGET_LINE[1]}"
	declare -r    _WORK_IMGS="${_WORK_DIRS}/img"
	declare -a    _WORK_ARRY=()
	declare       _FILE_MENU=""			# syslinux or isolinux path
	declare       _DIRS_MENU=""			# configuration file directory
	declare       _FILE_CONF=""			# configuration file path
	funcPrintf "%20.20s: %s" "edit" "add ${AUTO_INST} to grub.cfg"
	# shellcheck disable=SC2312
	while read -r _FILE_MENU
	do
		# shellcheck disable=SC2312
		if [[ -z "$(sed -ne '/^menuentry/p' "${_FILE_MENU}")" ]]; then
			continue
		fi
		_DIRS_MENU="${_FILE_MENU%/*}"
		# --- comment out "timeout" and "menu default" --------------------
		sed -i "${_FILE_MENU}"                             \
		    -e '/^[ \t]*\(\|set[ \t]\+\)default=/ s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)timeout=/ s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)gfxmode=/ s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)theme=/   s/^/#/g'
		# --- insert "autoinst.cfg" ---------------------------------------
		sed -i "${_FILE_MENU}"                                                        \
		    -e '0,/^menuentry/ {'                                                     \
		    -e '/^menuentry/i source '"${_DIRS_MENU/${_WORK_IMGS}/}/${AUTO_INST}"'\n' \
		    -e '}'
		funcCreate_autoinst_cfg_grub "${_DIRS_MENU}/${AUTO_INST}" "${_BOOT_OPTN}" "${_TGET_LINE[@]}"
		funcCreate_theme_txt "${_WORK_IMGS}" "${_DIRS_MENU}" "${_TGET_LINE[@]}"
	done < <(find "${_WORK_IMGS}" -name 'grub.cfg' -type f)
}

# ----- create remaster preseed -----------------------------------------------
function funcCreate_remaster_preseed() {
	declare -r -a _TGET_LINE=("$@")
	declare       _BOOT_OPTN=""
	declare -r    _HOST_NAME="sv-${_TGET_LINE[1]%%-*}"
	declare -r    _CONF_PATH="auto=true preseed/file=/cdrom/${_TGET_LINE[9]}"
	declare -r    _WORK_DIRS="${DIRS_TEMP}/${_TGET_LINE[1]}"
	declare -r    _WORK_IMGS="${_WORK_DIRS}/img"
	declare -r    _WORK_RAMS="${_WORK_DIRS}/ram"
	declare -r    _WORK_CONF="${_WORK_IMGS}/preseed"
	declare       _WORK_TYPE=""
	declare       _DIRS_IRAM=""
	funcPrintf "%20.20s: %s" "create" "boot options for preseed"
	# --- boot option ---------------------------------------------------------
	_BOOT_OPTN=""
	case "${_TGET_LINE[1]}" in
		ubuntu-desktop-* | \
		ubuntu-legacy-*  ) _BOOT_OPTN+="${_BOOT_OPTN:+" "}automatic-ubiquity noprompt ${_CONF_PATH}";;
		*-mini-*         ) _BOOT_OPTN+="${_BOOT_OPTN:+" "}auto=true preseed/file=/${_TGET_LINE[9]##*/}";;
		*                ) _BOOT_OPTN+="${_BOOT_OPTN:+" "}${_CONF_PATH}";;
	esac
	case "${_TGET_LINE[1]}" in
		ubuntu-*         ) _BOOT_OPTN+="${_BOOT_OPTN:+" "}netcfg/target_network_config=NetworkManager";;
		*                ) ;;
	esac
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}netcfg/disable_autoconfig=true"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}netcfg/choose_interface=${ETHR_NAME}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}netcfg/get_hostname=${_HOST_NAME}.${WGRP_NAME}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}netcfg/get_ipaddress=${IPV4_ADDR}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}netcfg/get_netmask=${IPV4_MASK}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}netcfg/get_gateway=${IPV4_GWAY}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}netcfg/get_nameservers=${IPV4_NSVR}"
#	_BOOT_OPTN+="${_BOOT_OPTN:+" "}locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp keyboard-model=jp106"
	case "${_TGET_LINE[1]}" in
		ubuntu-desktop-* | \
		ubuntu-legacy-*  ) _BOOT_OPTN+="${_BOOT_OPTN:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                ) _BOOT_OPTN+="${_BOOT_OPTN:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${_BOOT_OPTN}" "${_TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${_BOOT_OPTN}" "${_TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	_WORK_TYPE="${_TGET_LINE[9]##*/}"
	_WORK_TYPE="${_WORK_TYPE#*_}"
	_WORK_TYPE="${_WORK_TYPE%%_*}"
	case "${_TGET_LINE[1]}" in
		*-mini-*         )
			# shellcheck disable=SC2312
			while read -r FILE_IRAM
			do
				_DIRS_IRAM="${_WORK_RAMS}/${FILE_IRAM##*/}"
				mkdir -p "${_DIRS_IRAM}"
				cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/preseed_kill_dhcp.sh"    "${_DIRS_IRAM}"
				cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/preseed_late_command.sh" "${_DIRS_IRAM}"
				cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/"*"${_WORK_TYPE}"*.cfg   "${_DIRS_IRAM}"
#				cp -a "${DIRS_CONF}/${_TGET_LINE[9]%_*}"*.cfg                    "${_DIRS_IRAM}"
				ln -s "${_TGET_LINE[9]##*/}"                                     "${_DIRS_IRAM}/preseed.cfg"
			done < <(find "${_WORK_IMGS}" -name 'initrd*' -type f)
			;;
		debian-*         | \
		ubuntu-server-*  )
			mkdir -p "${_WORK_CONF}"
			cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/preseed_kill_dhcp.sh"    "${_WORK_CONF}"
			cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/preseed_late_command.sh" "${_WORK_CONF}"
			cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/"*"${_WORK_TYPE}"*.cfg   "${_WORK_CONF}"
#			cp -a "${DIRS_CONF}/${_TGET_LINE[9]%_*}"*.cfg                    "${_WORK_CONF}"
			;;
		ubuntu-live-*    ) ;;
		ubuntu-desktop-* | \
		ubuntu-legacy-*  )
			mkdir -p "${_WORK_CONF}"
			cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/preseed_kill_dhcp.sh"    "${_WORK_CONF}"
			cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/preseed_late_command.sh" "${_WORK_CONF}"
			cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/"*"${_WORK_TYPE}"*.cfg   "${_WORK_CONF}"
#			cp -a "${DIRS_CONF}/${_TGET_LINE[9]%_*}"*.cfg                    "${_WORK_CONF}"
			;;
		*                ) ;;
	esac
}

# ----- create remaster nocloud -----------------------------------------------
function funcCreate_remaster_nocloud() {
	declare -r -a _TGET_LINE=("$@")
	declare       _BOOT_OPTN=""
	declare -r    _HOST_NAME="sv-${_TGET_LINE[1]%%-*}"
	declare -r    _CONF_PATH="autoinstall ds='nocloud;s=/cdrom/${_TGET_LINE[9]}'"
	declare -r    _WORK_DIRS="${DIRS_TEMP}/${_TGET_LINE[1]}"
	declare -r    _WORK_IMGS="${_WORK_DIRS}/img"
	declare -r    _WORK_CONF="${_WORK_IMGS}/${_TGET_LINE[9]%/*}"
	declare       _WORK_LINK=""
	funcPrintf "%20.20s: %s" "create" "boot options for nocloud"
	# --- boot option ---------------------------------------------------------
	_BOOT_OPTN=""
	case "${_TGET_LINE[1]}" in
		ubuntu-live-18.*      ) _BOOT_OPTN+="${_BOOT_OPTN:+" "}boot=casper";;
		*                     )                                            ;;
	esac
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}automatic-ubiquity noprompt ${_CONF_PATH}"
	case "${_TGET_LINE[1]}" in
		ubuntu-live-18.04)
			_BOOT_OPTN+="${_BOOT_OPTN:+" "}ip=${ETHR_NAME},${IPV4_ADDR},${IPV4_MASK},${IPV4_GWAY} hostname=${_HOST_NAME}.${WGRP_NAME}"
			;;
		*                )
			_BOOT_OPTN+="${_BOOT_OPTN:+" "}ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}::${ETHR_NAME}:static:${IPV4_NSVR} hostname=${_HOST_NAME}.${WGRP_NAME}"
#			_BOOT_OPTN+="${_BOOT_OPTN:+" "}ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:${_HOST_NAME}.${WGRP_NAME}:${ETHR_NAME}:static:${IPV4_NSVR}"
			;;
	esac
#	_BOOT_OPTN+="${_BOOT_OPTN:+" "}debian-installer/language=ja keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
#	_BOOT_OPTN+="${_BOOT_OPTN:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${_BOOT_OPTN## }" "${_TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${_BOOT_OPTN## }" "${_TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	mkdir -p "${_WORK_CONF}"
	cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/nocloud_late_command.sh"          "${_WORK_CONF}"
	cp -a "${DIRS_CONF}/${_TGET_LINE[9]%%_*}_"{server,desktop}{,_old,_oldold} "${_WORK_CONF}"
	for _WORK_LINK in "${_WORK_CONF%/*}/${_TGET_LINE[9]%%_*}_"{server,desktop}{,_old,_oldold}
	do
		ln -sr "${_WORK_CONF}/nocloud_late_command.sh" "${_WORK_LINK}/"
	done
	chmod ugo-x "${_WORK_CONF}"/*/*
}

# ----- create remaster kickstart ---------------------------------------------
function funcCreate_remaster_kickstart() {
	declare -r -a _TGET_LINE=("$@")
	declare       _BOOT_OPTN=""
	declare -r    _HOST_NAME="sv-${_TGET_LINE[1]%%-*}"
	declare -r    _CONF_PATH="inst.ks=hd:sr0:/${_TGET_LINE[9]}"
	declare -r    _WORK_DIRS="${DIRS_TEMP}/${_TGET_LINE[1]}"
	declare -r    _WORK_IMGS="${_WORK_DIRS}/img"
	declare -r    _WORK_CONF="${_WORK_IMGS}/kickstart"
	funcPrintf "%20.20s: %s" "create" "boot options for kickstart"
	# --- boot option ---------------------------------------------------------
	_BOOT_OPTN="${_CONF_PATH}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}ip=${IPV4_ADDR}::${IPV4_GWAY}:${IPV4_MASK}:${_HOST_NAME}.${WGRP_NAME}:${ETHR_NAME}:none,auto6 nameserver=${IPV4_NSVR}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}fsck.mode=skip"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}inst.stage2=hd:LABEL=${_TGET_LINE[15]}"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${_BOOT_OPTN}" "${_TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${_BOOT_OPTN}" "${_TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	mkdir -p "${_WORK_CONF}"
	cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/late_command.sh" "${_WORK_CONF}"
	cp -a "${DIRS_CONF}/${_TGET_LINE[9]%_*}"*.cfg            "${_WORK_CONF}"
}

# ----- create remaster autoyast ----------------------------------------------
function funcCreate_remaster_autoyast() {
	declare -r -a _TGET_LINE=("$@")
	declare       _BOOT_OPTN=""
	declare -r    _HOST_NAME="sv-${_TGET_LINE[1]%%-*}"
	declare -r    _CONF_PATH="autoyast=cd:/${_TGET_LINE[9]}"
	declare -r    _WORK_DIRS="${DIRS_TEMP}/${_TGET_LINE[1]}"
	declare -r    _WORK_IMGS="${_WORK_DIRS}/img"
	declare -r    _WORK_CONF="${_WORK_IMGS}/autoyast"
	declare       _WORK_ETHR="${ETHR_NAME}"
	funcPrintf "%20.20s: %s" "create" "boot options for autoyast"
	case "${_TGET_LINE[1]}" in
		opensuse-*-15* ) _WORK_ETHR="eth0";;
		*              ) ;;
	esac
	# --- boot option ---------------------------------------------------------
	_BOOT_OPTN="${_CONF_PATH}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}hostname=${_HOST_NAME}.${WGRP_NAME} ifcfg=${_WORK_ETHR}=${IPV4_ADDR}/${IPV4_CIDR},${IPV4_GWAY},${IPV4_NSVR},${WGRP_NAME}"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	_BOOT_OPTN+="${_BOOT_OPTN:+" "}fsck.mode=skip"
	# --- syslinux.cfg --------------------------------------------------------
	funcCreate_syslinux_cfg "${_BOOT_OPTN}" "${_TGET_LINE[@]}"
	# --- grub.cfg ------------------------------------------------------------
	funcCreate_grub_cfg "${_BOOT_OPTN}" "${_TGET_LINE[@]}"
	# --- copy the configuration file -----------------------------------------
	mkdir -p "${_WORK_CONF}"
	cp -a "${DIRS_CONF}/${_TGET_LINE[9]%/*}/late_command.sh" "${_WORK_CONF}"
	cp -a "${DIRS_CONF}/${_TGET_LINE[9]%_*}"*.xml            "${_WORK_CONF}"
}

# ----- create remaster iso file ----------------------------------------------
function funcCreate_remaster_iso_file() {
	declare -r -a _TGET_LINE=("$@")
	# shellcheck disable=SC2001
	declare -r    _DIRS_SECT="${_TGET_LINE[9]%%/*}"
	declare -r    _FILE_NAME="${_TGET_LINE[5]%.*}_${_DIRS_SECT}.${_TGET_LINE[5]##*.}"
	declare -r    _FILE_PATH="${DIRS_RMAK}/${_FILE_NAME}"
	declare -r    _WORK_DIRS="${DIRS_TEMP}/${_TGET_LINE[1]}"
#	declare -r    _WORK_MNTP="${_WORK_DIRS}/mnt"
	declare -r    _WORK_IMGS="${_WORK_DIRS}/img"
	declare -r    _WORK_RAMS="${_WORK_DIRS}/ram"
#	declare       _WORK_PATH=""
	declare       _DIRS_IRAM=""
#	declare       _FILE_IRAM=""
	declare       _FILE_HBRD=""
	declare       _FILE_BCAT=""
	declare       _FILE_IBIN=""
	declare -a    _DIRS_FIND=()
	declare       _DIRS_BOOT=""
	declare       _DIRS_UEFI=""
	declare       _FILE_UEFI=""
	declare       _ISOS_PATH=""
	declare -a    _ISOS_INFO=()
	declare -i    _ISOS_SKIP=0
	declare -i    _ISOS_CONT=0
	declare -i    _RET_CD=0
	# --- create initrd file --------------------------------------------------
	if [[ "${_TGET_LINE[1]}" =~ -mini- ]]; then
		find "${_WORK_RAMS}" -name 'initrd*' -type d | sort | sed -ne '\%\(initrd.*/initrd*\|/.*netboot/\)%!p' | while read -r _DIRS_IRAM
		do
			funcPrintf "%20.20s: %s" "create" "remaster ${MINI_IRAM}"
			pushd "${_DIRS_IRAM}" > /dev/null
				find . | cpio --format=newc --create --quiet | gzip > "${_WORK_IMGS}/${MINI_IRAM}"
			popd > /dev/null
		done
	fi
	# --- create iso file -----------------------------------------------------
	funcPrintf "%20.20s: %s" "create" "remaster iso file"
	funcPrintf "%20.20s: %s" "create" "${_FILE_NAME}"
	mkdir -p "${DIRS_RMAK}"
	pushd "${_WORK_IMGS}" > /dev/null
		_FILE_HBRD="$(find /usr/lib       -name 'isohdpfx.bin'                             -type f              || true)"
		_FILE_BCAT="$(find .          \( -iname 'boot.cat'     -o -iname 'boot.catalog' \) -type f -printf "%P" || true)"
		_FILE_IBIN="$(find .          \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \) -type f -printf "%P" || true)"
		_DIRS_BOOT="$(find . -maxdepth 1 -iname 'boot'                                     -type d -printf "%P" || true)"
		_DIRS_UEFI="$(find . -maxdepth 1 -iname 'efi'                                      -type d -printf "%P" || true)"
		if [[ -n "${_DIRS_UEFI}" ]]; then
			_DIRS_UEFI="$(find "${_DIRS_UEFI}" -iname 'boot' -type d || true)"
		fi
		if [[ -n "${_DIRS_BOOT}" ]] && [[ -n "${_DIRS_UEFI}" ]]; then
			_DIRS_FIND=("${_DIRS_BOOT}" "${_DIRS_UEFI}")
		elif [[ -n "${_DIRS_BOOT}" ]]; then
			_DIRS_FIND=("${_DIRS_BOOT}")
		elif [[ -n "${_DIRS_UEFI}" ]]; then
			_DIRS_FIND=("${_DIRS_UEFI}")
		else
			_DIRS_FIND=(".")
		fi
		_FILE_UEFI="$(find "${_DIRS_FIND[@]}" -iname 'efi*.img' -type f || true)"
		if [[ -z "${_FILE_UEFI}" ]]; then
			_FILE_UEFI="${_DIRS_UEFI/.\//}/efi.img"
			_ISOS_PATH="${DIRS_ISOS}/${_TGET_LINE[5]}"
			_ISOS_INFO=("$(fdisk -l "${_ISOS_PATH}")")
			_ISOS_SKIP="$(echo "${_ISOS_INFO[@]}" | awk '/EFI/ {print $2;}')"
			_ISOS_CONT="$(echo "${_ISOS_INFO[@]}" | awk '/EFI/ {print $4;}')"
			dd if="${_ISOS_PATH}" of="${_FILE_UEFI}" bs=512 skip="${_ISOS_SKIP}" count="${_ISOS_CONT}" status=none
		fi
		chmod ugo-w -R .
		rm -f md5sum.txt
		find . ! -name 'md5sum.txt' -type f -exec md5sum {} \; > md5sum.txt
		chmod ugo-w md5sum.txt
		ionice -c "${IONICE_CLAS}" xorriso -as mkisofs \
		    -quiet \
		    -volid "${_TGET_LINE[15]//%20/ }" \
		    -eltorito-boot "${_FILE_IBIN}" \
		    -eltorito-catalog "${_FILE_BCAT:-boot.catalog}" \
		    -no-emul-boot -boot-load-size 4 -boot-info-table \
		    -isohybrid-mbr "${_FILE_HBRD}" \
		    -eltorito-alt-boot -e "${_FILE_UEFI}" \
		    -no-emul-boot -isohybrid-gpt-basdat \
		    -output "${_WORK_DIRS}/${_FILE_PATH##*/}" \
		    . > /dev/null 2>&1
	popd > /dev/null
	# --- copy iso image ------------------------------------------------------
	ionice -c "${IONICE_CLAS}" cp -a "${_WORK_DIRS}/${_FILE_PATH##*/}" "${_FILE_PATH%/*}"
	# --- remove directory ----------------------------------------------------
	rm -rf "${_WORK_DIRS:?}"
}

# ----- create remaster -------------------------------------------------------
function funcCreate_remaster() {
#	declare -r    OLD_IFS="${IFS}"
#	declare -r    MSGS_TITL="create target list"
#	declare -r -a DATA_ARRY=("$@")
	declare -r    _COMD_TYPE="${1:-}"
	declare -a    _TGET_LINE=()
#	declare -i    RET_CD=0
	declare -i    I=0
#	declare -i    J=0
#	declare       FILE_VLID=""
	# -------------------------------------------------------------------------
	for I in "${!TGET_LIST[@]}"
	do
		WORK_TEXT="$(echo -n "${TGET_LIST[I]}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
		IFS=$'\n' mapfile -d ' ' -t _TGET_LINE < <(echo -n "${WORK_TEXT}")
		if [[ "${_TGET_LINE[0]}" != "o" ]]; then
			continue
		fi
		funcPrintf "%-3.3s%17.17s: %s %s" "===" "start" "${_TGET_LINE[5]}" "${TEXT_GAP2}"
		# --- download --------------------------------------------------------
		funcCreate_remaster_download "${_TGET_LINE[@]}"
#		if [[ -n "${FILE_VLID}" ]]; then
#			_TGET_LINE[14]="${FILE_VLID// /%20}"
#			TGET_LIST[I-1]="${_TGET_LINE[*]}"
#		fi
		# --- download only ---------------------------------------------------
		case "${_COMD_TYPE}" in
			--download ) continue;;
			--update   )
				case "${_TGET_LINE[16]}" in
					*${TXT_CYAN}*   | \
					*${TXT_GREEN}*  | \
					*${TXT_YELLOW}* ) ;;
					*               ) continue;;
				esac
				;;
			* ) ;;
		esac
		# --- skip check ------------------------------------------------------
		if [[ ! -e "${_TGET_LINE[4]}/${_TGET_LINE[5]}" ]]; then
			funcPrintf "%-3.3s${TXT_RESET}${TXT_BYELLOW}%17.17s: %s${TXT_RESET} %s" "===" "skip" "${_TGET_LINE[5]}" "${TEXT_GAP2}"
			continue
		fi
		# --- copy iso contents to hdd ----------------------------------------
		funcCreate_copy_iso2hdd "${_TGET_LINE[@]}"
		# --- rewriting syslinux.cfg and grub.cfg -----------------------------
		case "${_TGET_LINE[1]%%-*}" in
			debian       | \
			ubuntu       ) 
				case "${_TGET_LINE[9]%%/*}" in
					preseed* ) funcCreate_remaster_preseed "${_TGET_LINE[@]}";;
					nocloud* ) funcCreate_remaster_nocloud "${_TGET_LINE[@]}";;
					*        ) funcPrintf "not supported on ${_TGET_LINE[1]}"; exit 1;;
				esac
				;;
			fedora       | \
			centos       | \
			almalinux    | \
			miraclelinux | \
			rockylinux   )
				funcCreate_remaster_kickstart "${_TGET_LINE[@]}"
				;;
			opensuse     )
				funcCreate_remaster_autoyast "${_TGET_LINE[@]}"
				;;
			*            )				# --- not supported -------------------
				funcPrintf "not supported on ${_TGET_LINE[1]}"
				exit 1
				;;
		esac
		# --- create iso file -------------------------------------------------
		funcCreate_remaster_iso_file "${_TGET_LINE[@]}"
		funcPrintf "%-3.3s%17.17s: %s %s" "===" "complete" "${_TGET_LINE[5]}" "${TEXT_GAP2}"
	done
}

# === call function ===========================================================

# ---- function test ----------------------------------------------------------
function funcCall_function() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    _MSGS_TITL="call function test"
	declare -r    _FILE_WRK1="${DIRS_TEMP}/testfile1.txt"
	declare -r    _FILE_WRK2="${DIRS_TEMP}/testfile2.txt"
	declare -r    _TEST_ADDR="https://raw.githubusercontent.com/office-itou/Linux/master/Readme.md"
	declare -r -a _CURL_OPTN=(        \
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
		"${_TEST_ADDR}"               \
	)
	declare       _TEST_PARM=""
	declare -i    I=0
	declare       H1=""
	declare       H2=""
	# -------------------------------------------------------------------------
	funcPrintf "---- ${_MSGS_TITL} ${TEXT_GAP1}"
	mkdir -p "${_FILE_WRK1%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_WRK1}"
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
	mkdir -p "${_FILE_WRK2%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_WRK2}"
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
	funcPrintf "%s : %-12.12s : %s" "${TXT_DBLACK}"   "TXT_DBLACK"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DRED}"     "TXT_DRED"     "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DGREEN}"   "TXT_DGREEN"   "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DYELLOW}"  "TXT_DYELLOW"  "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DBLUE}"    "TXT_DBLUE"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DMAGENTA}" "TXT_DMAGENTA" "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DCYAN}"    "TXT_DCYAN"    "${TXT_RESET}"
	funcPrintf "%s : %-12.12s : %s" "${TXT_DWHITE}"   "TXT_DWHITE"   "${TXT_RESET}"
	echo ""

	# --- diff ----------------------------------------------------------------
	funcPrintf "---- diff ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcDiff \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	funcDiff "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" "function test"
	funcPrintf "--no-cutting" "diff -y -W \"${COLS_SIZE}\" --suppress-common-lines \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${COLS_SIZE}" --suppress-common-lines "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	funcPrintf "--no-cutting" "diff -y -W \"${COLS_SIZE}\" \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff -y -W "${COLS_SIZE}" "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	funcPrintf "--no-cutting" "diff --color=always -y -W \"${COLS_SIZE}\" \"${_FILE_WRK1/${PWD}\//}\" \"${_FILE_WRK2/${PWD}\//}\" \"function test\""
	diff --color=always -y -W "${COLS_SIZE}" "${_FILE_WRK1/${PWD}\//}" "${_FILE_WRK2/${PWD}\//}" || true
	echo ""

	# --- substr --------------------------------------------------------------
	funcPrintf "---- substr ${TEXT_GAP1}"
	_TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcSubstr \"${_TEST_PARM}\" 1 19"
	funcPrintf "--no-cutting" "         1         2         3         4"
	funcPrintf "--no-cutting" "1234567890123456789012345678901234567890"
	funcPrintf "--no-cutting" "${_TEST_PARM}"
	funcSubstr "${_TEST_PARM}" 1 19
	echo ""

	# --- service status ------------------------------------------------------
	funcPrintf "---- service status ${TEXT_GAP1}"
	funcPrintf "--no-cutting" "funcServiceStatus \"sshd.service\""
	funcServiceStatus "sshd.service"
	echo ""

	# --- IPv6 full address ---------------------------------------------------
	funcPrintf "---- IPv6 full address ${TEXT_GAP1}"
	_TEST_PARM="fe80::1"
	funcPrintf "--no-cutting" "funcIPv6GetFullAddr \"${_TEST_PARM}\""
	funcIPv6GetFullAddr "${_TEST_PARM}"
	echo ""

	# --- IPv6 reverse address ------------------------------------------------
	funcPrintf "---- IPv6 reverse address ${TEXT_GAP1}"
	_TEST_PARM="0001:0002:0003:0004:0005:0006:0007:0008"
	funcPrintf "--no-cutting" "funcIPv6GetRevAddr \"${_TEST_PARM}\""
	funcIPv6GetRevAddr "${_TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 netmask conversion ---------------------------------------------
	funcPrintf "---- IPv4 netmask conversion ${TEXT_GAP1}"
	_TEST_PARM="24"
	funcPrintf "--no-cutting" "funcIPv4GetNetmask \"${_TEST_PARM}\""
	funcIPv4GetNetmask "${_TEST_PARM}"
	echo ""
	echo ""

	# --- IPv4 cidr conversion ------------------------------------------------
	funcPrintf "---- IPv4 cidr conversion ${TEXT_GAP1}"
	_TEST_PARM="255.255.255.0"
	funcPrintf "--no-cutting" "funcIPv4GetNetCIDR \"${_TEST_PARM}\""
	funcIPv4GetNetCIDR "${_TEST_PARM}"
	echo ""

	# --- is numeric ----------------------------------------------------------
	funcPrintf "---- is numeric ${TEXT_GAP1}"
	_TEST_PARM="123.456"
	funcPrintf "--no-cutting" "funcIsNumeric \"${_TEST_PARM}\""
	funcIsNumeric "${_TEST_PARM}"
	echo ""
	_TEST_PARM="abc.def"
	funcPrintf "--no-cutting" "funcIsNumeric \"${_TEST_PARM}\""
	funcIsNumeric "${_TEST_PARM}"
	echo ""

	# --- string output -------------------------------------------------------
	funcPrintf "---- string output ${TEXT_GAP1}"
	_TEST_PARM="50"
	funcPrintf "--no-cutting" "funcString \"${_TEST_PARM}\" \"#\""
	funcString "${_TEST_PARM}" "#"
	echo ""

	# --- print with screen control -------------------------------------------
	funcPrintf "---- print with screen control ${TEXT_GAP1}"
	_TEST_PARM="test"
	funcPrintf "--no-cutting" "funcPrintf \"${_TEST_PARM}\""
	funcPrintf "${_TEST_PARM}"
	echo ""

	# --- download ------------------------------------------------------------
	# shellcheck disable=SC2091,SC2310
	if $(funcIsPackage 'curl'); then
		funcPrintf "---- download ${TEXT_GAP1}"
		funcPrintf "--no-cutting" "funcCurl ${_CURL_OPTN[*]}"
		funcCurl "${_CURL_OPTN[@]}"
		echo ""
	fi

	# -------------------------------------------------------------------------
	rm -f "${_FILE_WRK1}" "${_FILE_WRK2}"
	ls -l "${DIRS_TEMP}"
}

# ---- debug parameter --------------------------------------------------------
function funcDbg_parameter() {
#	echo "${!PROG_*}"
#	echo "${!DIRS_*}"

	# --- machine information -------------------------------------------------
	printf "%s=[%s]\n"	"CODE_NAME"		"${CODE_NAME:-}"
	printf "%s=[%s]\n"	"MAIN_ARHC"		"${MAIN_ARHC:-}"
	printf "%s=[%s]\n"	"OTHR_ARCH"		"${OTHR_ARCH:-}"

	# --- working directory name ----------------------------------------------
	printf "%s=[%s]\n"	"PROG_PATH"		"${PROG_PATH:-}"
	printf "%s=[%s]\n"	"PROG_PARM"		"${PROG_PARM[*]:-}"
	printf "%s=[%s]\n"	"PROG_DIRS"		"${PROG_DIRS:-}"
	printf "%s=[%s]\n"	"PROG_NAME"		"${PROG_NAME:-}"
	printf "%s=[%s]\n"	"PROG_PROC"		"${PROG_PROC:-}"
	printf "%s=[%s]\n"	"DIRS_TEMP"		"${DIRS_TEMP:-}"

	# --- shared directory parameter ------------------------------------------
	printf "%s=[%s]\n"	"DIRS_TOPS"		"${DIRS_TOPS:-}"
	printf "%s=[%s]\n"	"DIRS_HGFS"		"${DIRS_HGFS:-}"
	printf "%s=[%s]\n"	"DIRS_HTML"		"${DIRS_HTML:-}"
	printf "%s=[%s]\n"	"DIRS_SAMB"		"${DIRS_SAMB:-}"
	printf "%s=[%s]\n"	"DIRS_TFTP"		"${DIRS_TFTP:-}"
	printf "%s=[%s]\n"	"DIRS_USER"		"${DIRS_USER:-}"

	# --- shared of user file -------------------------------------------------
	printf "%s=[%s]\n"	"DIRS_SHAR"		"${DIRS_SHAR:-}"
	printf "%s=[%s]\n"	"DIRS_CONF"		"${DIRS_CONF:-}"
	printf "%s=[%s]\n"	"DIRS_KEYS"		"${DIRS_KEYS:-}"
	printf "%s=[%s]\n"	"DIRS_TMPL"		"${DIRS_TMPL:-}"
	printf "%s=[%s]\n"	"DIRS_IMGS"		"${DIRS_IMGS:-}"
	printf "%s=[%s]\n"	"DIRS_ISOS"		"${DIRS_ISOS:-}"
	printf "%s=[%s]\n"	"DIRS_LOAD"		"${DIRS_LOAD:-}"
	printf "%s=[%s]\n"	"DIRS_RMAK"		"${DIRS_RMAK:-}"

	# --- open-vm-tools -------------------------------------------------------
	printf "%s=[%s]\n"	"HGFS_DIRS"		"${HGFS_DIRS:-}"

	# --- configuration file template -----------------------------------------
	printf "%s=[%s]\n"	"CONF_DIRS"		"${CONF_DIRS:-}"
	printf "%s=[%s]\n"	"CONF_KICK"		"${CONF_KICK:-}"
	printf "%s=[%s]\n"	"CONF_CLUD"		"${CONF_CLUD:-}"
	printf "%s=[%s]\n"	"CONF_SEDD"		"${CONF_SEDD:-}"
	printf "%s=[%s]\n"	"CONF_SEDU"		"${CONF_SEDU:-}"
	printf "%s=[%s]\n"	"CONF_YAST"		"${CONF_YAST:-}"

	# --- directory list ------------------------------------------------------
#	printf "%s=[%s]\n"	"LIST_DIRS"		"${LIST_DIRS[*]:-}"

	# --- symbolic link list --------------------------------------------------
#	printf "%s=[%s]\n"	"LIST_LINK"		"${LIST_LINK[*]:-}"

	# --- autoinstall configuration file --------------------------------------
	printf "%s=[%s]\n"	"AUTO_INST"		"${AUTO_INST:-}"

	# --- initial ram disk of mini.iso including preseed ----------------------
	printf "%s=[%s]\n"	"MINI_IRAM"		"${MINI_IRAM:-}"

	# --- tftp / web server address -------------------------------------------
	printf "%s=[%s]\n"	"SRVR_ADDR"		"${SRVR_ADDR:-}"
	printf "%s=[%s]\n"	"SRVR_PROT"		"${SRVR_PROT:-}"

	# --- network parameter ---------------------------------------------------
#	printf "%s=[%s]\n"	"HOST_NAME"		"${HOST_NAME:-}"
	printf "%s=[%s]\n"	"WGRP_NAME"		"${WGRP_NAME:-}"
	printf "%s=[%s]\n"	"ETHR_NAME"		"${ETHR_NAME:-}"
	printf "%s=[%s]\n"	"IPV4_ADDR"		"${IPV4_ADDR:-}"
	printf "%s=[%s]\n"	"IPV4_CIDR"		"${IPV4_CIDR:-}"
	printf "%s=[%s]\n"	"IPV4_MASK"		"${IPV4_MASK:-}"
	printf "%s=[%s]\n"	"IPV4_GWAY"		"${IPV4_GWAY:-}"
	printf "%s=[%s]\n"	"IPV4_NSVR"		"${IPV4_NSVR:-}"

	# --- curl / wget parameter -----------------------------------------------
	printf "%s=[%s]\n"	"CURL_OPTN"		"${CURL_OPTN[*]:-}"
	printf "%s=[%s]\n"	"WGET_OPTN"		"${WGET_OPTN[*]:-}"

	# --- work variables ------------------------------------------------------
	printf "%s=[%s]\n"	"OLD_IFS"		"${OLD_IFS:-}"

	# --- set minimum display size --------------------------------------------
	printf "%s=[%s]\n"	"ROWS_SIZE"		"${ROWS_SIZE:-}"
	printf "%s=[%s]\n"	"COLS_SIZE"		"${COLS_SIZE:-}"
	printf "%s=[%s]\n"	"TEXT_GAP1"		"${TEXT_GAP1:-}"
	printf "%s=[%s]\n"	"TEXT_GAP2"		"${TEXT_GAP2:-}"

	# --- niceness values -----------------------------------------------------
	printf "%s=[%s]\n"	"NICE_VALU"		"${NICE_VALU:-}"
	printf "%s=[%s]\n"	"IONICE_CLAS"	"${IONICE_CLAS:-}"
	printf "%s=[%s]\n"	"IONICE_VALU"	"${IONICE_VALU:-}"

	# === menu ================================================================

	# --- menu timeout --------------------------------------------------------
	printf "%s=[%s]\n"	"MENU_TOUT"		"${MENU_TOUT:-}"

	# --- menu resolution -----------------------------------------------------
	printf "%s=[%s]\n"	"MENU_RESO"		"${MENU_RESO:-}"
	printf "%s=[%s]\n"	"MENU_DPTH"		"${MENU_DPTH:-}"

	# === screen mode (vga=nnn) ===============================================
	printf "%s=[%s]\n"	"SCRN_MODE"		"${SCRN_MODE:-}"
}

# ---- debug ------------------------------------------------------------------
function funcCall_debug() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    _MSGS_TITL="call debug"
	declare -n    _COMD_RETN="$1"
	declare -a    _COMD_LIST=()
	# -------------------------------------------------------------------------
	funcPrintf "---- ${_MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
#	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
#		_COMD_LIST=("" "" "$@")
#		IFS=' =,'
#		set -f
#		set -- "${_COMD_LIST[@]:-}"
#		set +f
#		IFS=${OLD_IFS}
#	fi
	while [[ -n "${1:-}" ]]
	do
		# shellcheck disable=SC2034
		_COMD_LIST=("${@:-}")
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
	_COMD_RETN="${_COMD_LIST[*]:-}"
}

# ---- config -----------------------------------------------------------------
function funcCall_config() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    _MSGS_TITL="call config"
	declare -n    _COMD_RETN="$1"
	declare -a    _COMD_LIST=()
	# -------------------------------------------------------------------------
	funcPrintf "---- ${_MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		_COMD_LIST=("cmd" "preseed" "nocloud" "kickstart" "autoyast" "$@")
		IFS=' =,'
		set -f
		set -- "${_COMD_LIST[@]:-}"
		set +f
		IFS=${OLD_IFS}
	fi
	while [[ -n "${1:-}" ]]
	do
		# shellcheck disable=SC2034
		_COMD_LIST=("${@:-}")
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
	_COMD_RETN="${_COMD_LIST[*]:-}"
}

# ---- create -----------------------------------------------------------------
function funcCall_create() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    _MSGS_TITL="call create"
	declare -n    _COMD_RETN="$1"
	declare -r -a _COMD_ENUM=("mini" "net" "dvd" "live")
	declare -a    _COMD_LIST=()
	declare -r    _COMD_TYPE="${2:-}"
	declare -a    _DATA_ARRY=()
	declare       _WORK_PARM=""
	declare       _WORK_ENUM=""
	declare -a    _WORK_ARRY=()
	declare       _WORK_TEXT=""
	declare       _MENU_HEAD=""
	declare       _MENU_TAIL=""
	declare -i    I=0
	declare -i    J=0
	# -------------------------------------------------------------------------
	funcPrintf "---- ${_MSGS_TITL} ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	shift 2
	if [[ "${1:-}" = "all" ]] || [[ "${1:-}" = "a" ]]; then
		_COMD_LIST=()
		for I in "${!_COMD_ENUM[@]}"
		do
			_COMD_LIST+=("${_COMD_ENUM[I]}" "all")
		done
	elif [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		_COMD_LIST=("${_COMD_ENUM[@]}" "$@")
	fi
	if [[ -n "${_COMD_LIST[*]}" ]]; then
		IFS=' =,'
		set -f
		set -- "${_COMD_LIST[@]:-}"
		set +f
		IFS=${OLD_IFS}
	fi
	while [[ -n "${1:-}" ]]
	do
		# shellcheck disable=SC2034
		_COMD_LIST=("${@:-}")
		unset _DATA_ARRY
		_DATA_ARRY=()
		case "${1:-}" in
			mini ) shift; _DATA_ARRY=("${DATA_LIST_MINI[@]}");;
			net  ) shift; _DATA_ARRY=("${DATA_LIST_NET[@]}") ;;
			dvd  ) shift; _DATA_ARRY=("${DATA_LIST_DVD[@]}") ;;
			live ) shift; _DATA_ARRY=("${DATA_LIST_INST[@]}");;
#			live ) shift; _DATA_ARRY=("${DATA_LIST_LIVE[@]}");;
#			tool ) shift; _DATA_ARRY=("${DATA_LIST_TOOL[@]}");;
#			comd ) shift; _DATA_ARRY=("${DATA_LIST_SCMD[@]}");;
#			cstm ) shift; _DATA_ARRY=("${DATA_LIST_CSTM[@]}");;
#			scmd ) shift; _DATA_ARRY=("${DATA_LIST_SCMD[@]}");;
			-*   ) break;;
			*    ) ;;
		esac
		if [[ "${#_DATA_ARRY[@]}" -le 0 ]]; then
			continue
		fi
		unset _WORK_ARRY
		_WORK_ARRY=()
		while [[ -n "${1:-}" ]]
		do
			case "${1:-}" in
				a | all )
					_WORK_ARRY=("*")
					shift
					break
					;;
				[0-9] | [0-9][0-9] | [0-9][0-9][0-9] )		# 1..999
					_WORK_ARRY+=("$1")
					shift
					;;
				* )	break;;
			esac
		done
		_MENU_HEAD=""
		_MENU_TAIL=""
		J=0
		for I in "${!_DATA_ARRY[@]}"
		do
			_WORK_TEXT="$(echo -n "${_DATA_ARRY[I]}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
			IFS=$'\n' mapfile -d ' ' -t DATA_LINE < <(echo -n "${_WORK_TEXT}")
			case "${DATA_LINE[0]}" in
				o)
					if [[ ! "${DATA_LINE[17]}" =~ ^http://.*$ ]] && [[ ! "${DATA_LINE[17]}" =~ ^https://.*$ ]]; then
						unset "_DATA_ARRY[I]"
						continue
					fi
					((J+=1))
					_WORK_TEXT="${_WORK_ARRY[*]/\*/\.\*}"
					_WORK_TEXT="${_WORK_TEXT// /\\|}"
					if [[ -n "${_WORK_TEXT:-}" ]] && [[ -z "$(echo "${J}" | sed -ne '/^\('"${_WORK_TEXT}"'\)$/p' || true)" ]]; then
						DATA_LINE[0]="s"
						_DATA_ARRY[I]="${DATA_LINE[*]}"
					fi
					;;
				m)
					if [[ -z "${_MENU_HEAD}" ]]; then
						_MENU_HEAD="${_DATA_ARRY[I]}"
						unset "_DATA_ARRY[I]"
					elif [[ -z "${_MENU_TAIL}" ]]; then
						_MENU_TAIL="${_DATA_ARRY[I]}"
						unset "_DATA_ARRY[I]"
					fi
					;;
				*)
					unset "_DATA_ARRY[I]"
					continue
					;;
			esac
		done
		_DATA_ARRY=("${_DATA_ARRY[@]}")
		TGET_INDX=""
		if [[ "${_WORK_ARRY[*]}" = "*" ]]; then
			TGET_INDX="{1..${#_DATA_ARRY[@]}}"
			TGET_INDX="$(eval echo "${TGET_INDX}")"
		elif [[ -n "${_WORK_ARRY[*]}" ]]; then
			TGET_INDX="${_WORK_ARRY[*]}"
		fi
		TGET_LIST=()
		funcCreate_menu "${_MENU_HEAD:-}" "${_DATA_ARRY[@]}" "${_MENU_TAIL:-}"
		if [[ -z "${TGET_INDX}" ]]; then
			funcCreate_target_list
		fi
		if [[ -n "${TGET_INDX}" ]]; then
			for I in "${!TGET_LIST[@]}"
			do
				_WORK_TEXT="$(echo -n "${TGET_LIST[I]}" | sed -e 's/\([ \t]\)\+/\1/g' -e 's/^[ \t]\+//g'  -e 's/[ \t]\+$//g')"
				IFS=$'\n' mapfile -d ' ' -t DATA_LINE < <(echo -n "${_WORK_TEXT}")
				case "${DATA_LINE[0]}" in
					o)
						_WORK_TEXT="${TGET_INDX[*]/\*/\.\*}"
						_WORK_TEXT="${_WORK_TEXT// /\\|}"
						if [[ -n "${_WORK_TEXT:-}" ]] && [[ -z "$(echo "${I}" | sed -ne '/^\('"${_WORK_TEXT}"'\)$/p' || true)" ]]; then
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
			funcCreate_remaster "${_COMD_TYPE}"
		fi
	done
	# -------------------------------------------------------------------------
	rm -rf "${DIRS_TEMP:?}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2034
	_COMD_RETN="${_COMD_LIST[*]:-}"
}

# ----- media download --------------------------------------------------------
#function funcMedia_download() {
##	declare -r    OLD_IFS="${IFS}"
#	declare -r    _MSGS_TITL="call create"
#	declare -n    _COMD_RETN="$1"
#	declare -r -a _COMD_ENUM=("mini" "net" "dvd" "live")
#	declare -a    _COMD_LIST=()
#	declare -a    _DATA_ARRY=()
#	declare       _WORK_PARM=""
#	declare       _WORK_ENUM=""
#	declare -i    I=0
#	declare -i    J=0
##	declare       FILE_VLID=""
#	# -------------------------------------------------------------------------
#	funcPrintf "---- ${_MSGS_TITL} ${TEXT_GAP1}"
#	# -------------------------------------------------------------------------
#	shift 2
#	if [[ "${1:-}" = "all" ]] || [[ "${1:-}" = "a" ]]; then
#		_COMD_LIST=()
##		for ((I=0; I<"${#_COMD_ENUM[@]}"; I++))
#		for I in "${!_COMD_ENUM[@]}"
#		do
#			_COMD_LIST+=("${_COMD_ENUM[I]}" "all")
#		done
#	elif [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
#		_COMD_LIST=("${_COMD_ENUM[@]}" "$@")
#	fi
#	if [[ -n "${_COMD_LIST[*]}" ]]; then
#		IFS=' =,'
#		set -f
#		set -- "${_COMD_LIST[@]:-}"
#		set +f
#		IFS=${OLD_IFS}
#	fi
#	while [[ -n "${1:-}" ]]
#	do
#		# shellcheck disable=SC2034
#		_COMD_LIST=("${@:-}")
#		_DATA_ARRY=()
#		case "${1:-}" in
#			mini ) _DATA_ARRY=("${DATA_LIST_MINI[@]}");;
#			net  ) _DATA_ARRY=("${DATA_LIST_NET[@]}") ;;
#			dvd  ) _DATA_ARRY=("${DATA_LIST_DVD[@]}") ;;
#			live ) _DATA_ARRY=("${DATA_LIST_INST[@]}");;
##			live ) _DATA_ARRY=("${DATA_LIST_LIVE[@]}");;
##			tool ) _DATA_ARRY=("${DATA_LIST_TOOL[@]}");;
##			comd ) _DATA_ARRY=("${DATA_LIST_SCMD[@]}");;
#			-* )
#				break
#				;;
#			* )
#				;;
#		esac
#		if [[ "${#_DATA_ARRY[@]}" -gt 0 ]]; then
##			for ((I=0, J=0; I<"${#_DATA_ARRY[@]}"; I++))
#			J=0
#			for I in "${!_DATA_ARRY[@]}"
#			do
#				read -r -a DATA_LINE < <(echo "${_DATA_ARRY[I]}")
#				if [[ "${DATA_LINE[0]}" != "o" ]] || { [[ ! "${DATA_LINE[17]}" =~ ^http://.*$ ]] && [[ ! "${DATA_LINE[17]}" =~ ^https://.*$ ]]; }; then
#					continue
#				fi
#				J+=1
#			done
#			TGET_INDX=""
#			case "${2:-}" in
#				a | all )
#					shift;
#					TGET_INDX="{1..${J}}"
#					;;
#				*       )
#					_WORK_ENUM="${_COMD_ENUM[*]}"
#					_WORK_ENUM="${_WORK_ENUM// /\\|}"
#					# shellcheck disable=SC2312
#					if [[ -n "${2:-}" ]] && [[ -z "$(echo "${2:-}" | sed -ne '/\('"${_WORK_ENUM}"'\)/p')" ]]; then
#						shift
#						_WORK_PARM="$*"
#						# shellcheck disable=SC2001
#						TGET_INDX="$(echo "${_WORK_PARM}" | sed -e 's/\('"${_WORK_ENUM}"'\).*//g')"
#					fi
#					;;
#			esac
#			TGET_INDX="$(eval echo "${TGET_INDX}")"
#			TGET_LIST=()
#			funcCreate_menu "${_DATA_ARRY[@]}"
#			if [[ -z "${TGET_INDX}" ]]; then
#				funcCreate_target_list
#			fi
##			for ((I=0; I<"${#TGET_LIST[@]}"; I++))
#			for I in "${!TGET_LIST[@]}"
#			do
#				read -r -a TGET_LINE < <(echo "${TGET_LIST[I]}")
#				funcPrintf "===    start: ${TGET_LINE[4]} ${TEXT_GAP2}"
#				# --- download ------------------------------------------------
#				funcCreate_remaster_download "${TGET_LINE[@]}"
#				funcPrintf "=== complete: ${TGET_LINE[4]} ${TEXT_GAP2}"
#			done
#		fi
#		shift
#	done
#	# -------------------------------------------------------------------------
#	rm -rf "${DIRS_TEMP:?}"
#	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2034
#	_COMD_RETN="${_COMD_LIST[*]:-}"
#}

# === main ====================================================================

function funcMain() {
#	declare -r    OLD_IFS="${IFS}"
	declare -i    _start_time=0
	declare -i    _end_time=0
	declare -i    I=0
	declare -a    _COMD_LINE=("${PROG_PARM[@]}")
	declare -a    _DIRS_LIST=()
	declare       _DIRS_NAME=""
	declare       _WORK_TEXT=""

	# ==== start ==============================================================

	# --- check the execution user --------------------------------------------
	# shellcheck disable=SC2312
	if [[ "$(whoami)" != "root" ]]; then
		funcPrintf "run as root user."
		exit 1
	fi

	# --- initialization ------------------------------------------------------
	trap 'rm -rf '"${DIRS_TEMP:?}"'' EXIT

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
	_start_time=$(date +%s)
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"
	funcPrintf "--- start ${TEXT_GAP1}"
	funcPrintf "--- main ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	renice -n "${NICE_VALU}"   -p "$$" > /dev/null
	ionice -c "${IONICE_CLAS}" -p "$$"
	# -------------------------------------------------------------------------
	_DIRS_LIST=()
	for _DIRS_NAME in "${DIRS_TEMP%.*.*}."*
	do
		if [[ ! -d "${_DIRS_NAME}/." ]]; then
			continue
		fi
		_WORK_TEXT="${_DIRS_NAME%.*}"
		_WORK_TEXT="${_WORK_TEXT##*.}"
		if ! ps --pid "${_WORK_TEXT}" > /dev/null 2>&1; then
			_DIRS_LIST+=("${_DIRS_NAME}")
		fi
	done
	if [[ "${#_DIRS_LIST[@]}" -gt 0 ]]; then
		for _DIRS_NAME in "${_DIRS_LIST[@]}"/*/mnt
		do
			set +e
			if mountpoint -q "${_DIRS_NAME}"; then
				funcPrintf "unmount unnecessary temporary directories"
				if [[ "${_DIRS_NAME##*/}" = "dev" ]]; then
					umount -q "${_DIRS_NAME}/pts" || umount -q -lf "${_DIRS_NAME}/pts"
				fi
				umount -q "${_DIRS_NAME}" || umount -q -lf "${_DIRS_NAME}"
			fi
			set -e
		done
		funcPrintf "remove unnecessary temporary directories"
		rm -rf "${_DIRS_LIST[@]}"
	fi
	# -------------------------------------------------------------------------
	if [[ -z "${PROG_PARM[*]}" ]]; then
		funcPrintf "sudo ./${PROG_NAME} [ options ]"
		funcPrintf "  create symbolic link"
		funcPrintf "    -l | --link"
		funcPrintf "  create config files"
		funcPrintf "    --conf [ options ]"
		funcPrintf "      cmd         preseed kill dhcp / sub command"
		funcPrintf "      preseed     preseed.cfg"
		funcPrintf "      nocloud     nocloud"
		funcPrintf "      kickstart   kickstart.cfg"
		funcPrintf "      autoyast    autoyast.xml"
		funcPrintf "  create / download / update iso image files"
		funcPrintf "    --create / --download / --update [ options ] [ empty | all | id number ]"
		funcPrintf "      mini / net / dvd / live"
		funcPrintf "                  mini.iso / netinst / dvd image / live image"
#		funcPrintf "      tool        tool"
		funcPrintf "      empty       waiting for input"
		funcPrintf "      a | all     create all targets"
		funcPrintf "      id number   create with selected target id"
		funcPrintf "  debug print and test"
		funcPrintf "    -d | --debug [ options ]"
		funcPrintf "      func    function test"
		funcPrintf "      text    text color test"
		funcPrintf "      parm    display of main internal parameters"
	else
		IFS=' =,'
		set -f
		set -- "${_COMD_LINE[@]:-}"
		set +f
		IFS=${OLD_IFS}
		while [[ -n "${1:-}" ]]
		do
			case "${1:-}" in
				-d | --debug   )			# ==== debug ======================
					funcCall_debug _COMD_LINE "$@"
					;;
				-l | --link )				# ==== create symbolic link =======
					funcCreate_directory
					shift
					_COMD_LINE=("${@:-}")
					;;
				--conf )
					funcCall_config _COMD_LINE "$@"
					;;
				--download | \
				--update   | \
				--create   )
					funcCall_create _COMD_LINE "$@"
					;;
#				--download )				# ==== media download =============
#					funcMedia_download _COMD_LINE "$@"
#					;;
				* )
					shift
					_COMD_LINE=("${@:-}")
					;;
			esac
			if [[ -z "${_COMD_LINE[*]:-}" ]]; then
				break
			fi
			IFS=' =,'
			set -f
			set -- "${_COMD_LINE[@]:-}"
			set +f
			IFS=${OLD_IFS}
		done
	fi

	rm -rf "${DIRS_TEMP:?}"
	# ==== complete ===========================================================
	funcPrintf "--- complete ${TEXT_GAP1}"
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing end${TXT_RESET}"
	_end_time=$(date +%s)
#	funcPrintf "elapsed time: $((_end_time-_start_time)) [sec]"
	funcPrintf "elapsed time: %dd%02dh%02dm%02ds\n" $(((_end_time-_start_time)/86400)) $(((_end_time-_start_time)%86400/3600)) $(((_end_time-_start_time)%3600/60)) $(((_end_time-_start_time)%60))
}

# *** main processing section *************************************************
	funcMain
	exit 0

### eof #######################################################################
