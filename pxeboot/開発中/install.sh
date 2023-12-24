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

# --- set parameters ----------------------------------------------------------

	# === system ==============================================================

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
#	declare -r    SCRN_SIZE="1680x1050"	# WSXGA+ (16:10)
#	declare -r    SCRN_SIZE="1600x1200"	# UXGA   (4:3)
#	declare -r    SCRN_SIZE="1400x1050"	#        (4:3)
#	declare -r    SCRN_SIZE="1440x900"	# WXGA+  (16:10)
#	declare -r    SCRN_SIZE="1360x768"	# HD     (16:9)
	declare -r    SCRN_SIZE="1280x1024"	# SXGA   (5:4)
#	declare -r    SCRN_SIZE="1280x960"	#        (4:3)
#	declare -r    SCRN_SIZE="1280x800"	#        (16:10)
#	declare -r    SCRN_SIZE="1280x768"	#        (4:3)
#	declare -r    SCRN_SIZE="1280x720"	# WXGA   (16:9)
#	declare -r    SCRN_SIZE="1152x864"	#        (4:3)
#	declare -r    SCRN_SIZE="1024x768"	# XGA    (4:3)
#	declare -r    SCRN_SIZE="800x600"	# SVGA   (4:3)
#	declare -r    SCRN_SIZE="640x480"	# VGA    (4:3)

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
	declare -r    HGFS_DIRS="/mnt/hgfs"		# vmware shared directory

	# --- tftp server ---------------------------------------------------------
	# funcNetwork_pxe_conf creates directory
	#
	# tree diagram
	#   /var/tftp/
	#   |-- boot
	#   |-- grub
	#   |-- menu-bios
	#   |   |-- boot -> /var/tftp/boot
	#   |   `-- pxelinux.cfg
	#   |-- menu-efi32
	#   |   |-- boot -> /var/tftp/boot
	#   |   `-- pxelinux.cfg
	#   `-- menu-efi64
	#       |-- boot -> /var/tftp/boot
	#       `-- pxelinux.cfg
	#   /var/www/
	#   `-- html
	#       `-- index.html

	declare -r    TFTP_ROOT="/var/tftp"

	# --- firewall ------------------------------------------------------------
	declare -r    FWAL_ZONE="home"			# firewall zone name
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
	declare -r    HOST_FQDN="$(hostname)"		# host fqdn
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

# ------ system control -------------------------------------------------------
function funcSystem_control() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="system control"
	declare -a    SRVC_LINE=()
	declare -a    SYSD_ARRY=()
	declare -a    SYSD_NAME=()
	declare -i    I=0
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: service"
	for ((I=0; I<"${#SRVC_LIST[@]}"; I++))
	do
		# shellcheck disable=SC2206
		SRVC_LINE=(${SRVC_LIST[I]})
		SYSD_ARRY=()
		SYSD_NAME=()
		#                    debian/ubuntu                   fedora/centos/...              opensuse
		case "${SRVC_LINE[0]}" in
			fwl ) SYSD_ARRY=(""                              "firewalld.service"            "firewalld.service"           );;
			sel ) SYSD_ARRY=(""                              "selinux-autorelabel.service"  ""                            );;
			ssh ) SYSD_ARRY=("ssh.service"                   "sshd.service"                 "sshd.service"                );;
			dns ) SYSD_ARRY=("dnsmasq.service"               "dnsmasq.service"              "dnsmasq.service"             );;
			web ) SYSD_ARRY=("apache2.service"               "httpd.service"                "apache2.service"             );;
			smb ) SYSD_ARRY=("smbd.service nmbd.service"     "smb.service nmb.service"      "smb.service nmb.service"     );;
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
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
	declare -i    I=0
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
		# shellcheck disable=SC2312
		if [[ -n "$(command -v connmanctl 2> /dev/null)" ]]; then
			WORK_PARM="$(find /var/lib/connman/ -name "ethernet_${ETHR_MADR[I]//:/}_*" -type d -printf "%P")"
			IPV4_NSVR+=("$(LANG=C connmanctl services "${WORK_PARM}"        \
			             | sed -ne '/^[ \t]*Nameservers[ \t]*=/ { '         \
			                    -e 's/^.*\[[ \t]*\(.*\)[ \t]*\]$/\1/'       \
			                    -e 's/,//g'                                 \
			                    -e "s/.*\(${IPV4_UADR[I]}\.[0-9]\+\).*/\1/" \
			                    -e 'p}'                                     \
			)")
		elif [[ -n "$(command -v nmcli 2> /dev/null)" ]]; then
			IPV4_NSVR+=("$(LANG=C nmcli device show "${ETHR_NAME[I]}"       \
			             | sed -ne '/IP4.DNS/ {'                            \
			                    -e "s/.*\(${IPV4_UADR[I]}\.[0-9]\+\).*/\1/" \
			                    -e 'p}'                                     \
			)")
		elif [[ -n "$(command -v netplan 2> /dev/null)" ]]; then
			IPV4_NSVR+=("$(awk '$1=="nameserver"&&$2~"'"${IPV4_ADDR[I]%.*}"'" {print $2;}' /etc/resolv.conf)")
		else
			IPV4_NSVR+=("$(awk '$1=="nameserver"&&$2~"'"${IPV4_ADDR[I]%.*}"'" {print $2;}' /etc/resolv.conf)")
		fi
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

# ------ hosts.allow / hosts.deny ---------------------------------------------
function funcNetwork_hosts_allow_deny() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="hosts.allow / hosts.deny"
	declare       FILE_PATH=""
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# --- hosts.allow ---------------------------------------------------------
	FILE_PATH="/etc/hosts.allow"
	FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	if [[ -f "${FILE_PATH}" ]]; then
		if [[ ! -f "${FILE_ORIG}" ]]; then
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
	if [[ -f "${FILE_PATH}" ]]; then
		if [[ ! -f "${FILE_ORIG}" ]]; then
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

# ------ connman --------------------------------------------------------------
function funcNetwork_connmanctl() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="connmanctl"
	declare       FILE_PATH=""
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v connmanctl 2> /dev/null)" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	FILE_PATH="/etc/connman/main.conf"
	FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	if [[ -f "${FILE_PATH}" ]]; then
		if [[ ! -f "${FILE_ORIG}" ]]; then
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
			    -e '/^#[ \t]*AllowHostnameUpdates[ \t]*=/a AllowHostnameUpdates = false'           \
			    -e '/^#[ \t]*PreferredTechnologies[ \t]*=/a PreferredTechnologies = ethernet,wifi' \
			    -e '/^#[ \t]*SingleConnectedTechnology[ \t]*=/a SingleConnectedTechnology = true'  \
			    -e '/^#[ \t]*EnableOnlineCheck[ \t]*=/a EnableOnlineCheck = false'                 \
			   "${FILE_ORIG}"                                                                      \
			>  "${FILE_PATH}"
		else
			funcPrintf "      ${MSGS_TITL}: create config file, because empty"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
				AllowHostnameUpdates = false
				PreferredTechnologies = ethernet,wifi
				SingleConnectedTechnology = true
				EnableOnlineCheck = false
_EOT_
		fi
		if [[ "${#ETHR_NAME[@]}" -gt 1 ]]; then
			sed -i "${FILE_PATH}"                              \
			    -e '/SingleConnectedTechnology/ s/true/false/'
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
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
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
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
	done < <(find "${FILE_PATH%/*}" \( -type f -o -type l \))
	# -------------------------------------------------------------------------
	if [[ -f "${FILE_PATH}" ]]; then
		if [[ ! -f "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
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
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v nmcli 2> /dev/null)" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
#	if [[ -f /etc/dnsmasq.conf ]]; then
#		SYSD_NAME="dnsmasq.service"
#		FILE_PATH+="/dnsmasq.conf"
#		CONF_PARM="[main]"$'\n'"dns=dnsmasq"
#	else
		SYSD_NAME="systemd-resolved.service"
		FILE_PATH+="/none-dns.conf"
		CONF_PARM="[main]"$'\n'"dns=none"
#	fi
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: stop ${SYSD_NAME}"
	systemctl --quiet stop "${SYSD_NAME}"
	funcPrintf "      ${MSGS_TITL}: disable ${SYSD_NAME}"
	systemctl --quiet disable "${SYSD_NAME}"
	# -------------------------------------------------------------------------
	FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	if [[ -f "${FILE_PATH}" ]]; then
		if [[ ! -f "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
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
	declare -r    SYSD_NAME="systemd-resolved.service"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ -h "${FILE_PATH}" ]]; then
		funcPrintf "      ${MSGS_TITL}: link file already exists"
		# shellcheck disable=SC2312,SC2310
		if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
			return
		fi
		funcPrintf "      ${MSGS_TITL}: rm -f ${FILE_PATH}"
		rm -f "${FILE_PATH}"
	fi
	if [[ -f "${FILE_PATH}" ]]; then
		if [[ ! -f "${FILE_ORIG}" ]]; then
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
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
		# Generated by User script
		search ${IPV4_WGRP[0]}
		nameserver ::1
		nameserver 127.0.0.1
		nameserver ${IPV4_NSVR[0]}
_EOT_
#	chattr -i "${FILE_PATH}"
}

# ------ pxe.conf -------------------------------------------------------------
function funcNetwork_pxe_conf() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="pxe.conf"
	declare -r    DIRS_PATH="/etc/dnsmasq.d"
	declare -r    FILE_PATH="${DIRS_PATH}/pxe.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       FILE_LINE=""
#	declare       WORK_DIRS=""
#	declare       WORK_TYPE=""
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: create directory"
	funcPrintf "      ${MSGS_TITL}: ${TFTP_ROOT}"
	mkdir -p "${TFTP_ROOT}"/{boot,grub,menu-{bios,efi{32,64}}/pxelinux.cfg}
	mkdir -p "${DIRS_PATH}"
	touch "${FILE_PATH}"
	if [[ -f /etc/selinux/config ]]; then
		WORK_DIRS="${TFTP_ROOT/\./\\.}(/.*)?"
		WORK_TYPE="tftpdir_t"
		# shellcheck disable=SC2312
		if [[ -z "$(semanage fcontext --list | awk 'index($1,"'"${WORK_DIRS//\\/\\\\}"'")&&index($4,"'"${WORK_TYPE}"'") {split($4,a,":"); print a[3];}')" ]]; then
			funcPrintf "      ${MSGS_TITL}: semanage fcontext --add --type ${WORK_TYPE}"
			funcPrintf "      ${MSGS_TITL}: ${WORK_DIRS}"
			semanage fcontext --add --type "${WORK_TYPE}" "${WORK_DIRS}"
		fi
		restorecon -R -F "${TFTP_ROOT}"
		# ---------------------------------------------------------------------
		WORK_DIRS="${DIRS_PATH/\./\\.}(/.*)?"
		WORK_TYPE="dnsmasq_etc_t"
		# shellcheck disable=SC2312
		if [[ -z "$(semanage fcontext --list | awk 'index($1,"'"${WORK_DIRS//\\/\\\\}"'")&&index($4,"'"${WORK_TYPE}"'") {split($4,a,":"); print a[3];}')" ]]; then
			funcPrintf "      ${MSGS_TITL}: semanage fcontext --add --type ${WORK_TYPE}"
			funcPrintf "      ${MSGS_TITL}: ${WORK_DIRS}"
			semanage fcontext --add --type "${WORK_TYPE}" "${WORK_DIRS}"
		fi
		restorecon -R -F "${DIRS_PATH}"
	fi
	for FILE_LINE in "${TFTP_ROOT}"/menu-{bios,efi{32,64}}
	do
		if [[ -d "${FILE_LINE}/boot" ]]; then
			continue
		fi
		ln -s "${TFTP_ROOT}/boot" "${FILE_LINE}"
	done
	# -------------------------------------------------------------------------
	if [[ -f "${FILE_PATH}" ]]; then
		if [[ ! -f "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
		# log
		#log-facility=/var/log/dnsmasq/dnsmasq.log
		#log-queries
		#log-dhcp
		
		# dns
		#port=0
		domain-needed
		bogus-priv
		expand-hosts
		domain=${HOST_DMAN}
		#domain=local
		#conf-file=/usr/share/dnsmasq-base/trust-anchors.conf
		#dnssec
		#server=/${IPV4_RADR[0]}.in-addr.arpa/${IPV4_ADDR[0]}
		#server=/${HOST_DMAN}/${IPV4_ADDR[0]}
		#server=/local/${IPV4_ADDR[0]}
		#local=/${HOST_DMAN}/
		#local=/local/
		#listen-address=${IPV6_LHST},${IPV4_LHST},${IPV4_NSVR[0]}
		
		# dhcp
		interface=${ETHR_NAME[0]}
		#no-dhcp-interface=
		#dhcp-leasefile=/var/log/dnsmasq/dnsmasq.leases             # lease file
		#dhcp-range=${IPV4_UADR[0]}.${DHCP_SADR},${IPV4_UADR[0]}.${DHCP_EADR},${DHCP_LEAS}                   # dhcp range
		dhcp-range=${IPV4_NTWK[0]},proxy                                # proxy dhcp
		dhcp-option=option:netmask,${IPV4_MASK[0]}                    # netmask
		dhcp-no-override
		#                                                           # dnsmasq --help dhcp
		#dhcp-option=option:domain-name,${HOST_DMAN}                   # 15 domain-name
		#dhcp-option=option:netmask,${IPV4_MASK[0]}                   #  1 netmask
		#dhcp-option=option:28,${IPV4_BCST[0]}                        # 28 broadcast
		dhcp-option=option:router,${IPV4_GWAY[0]}                     #  3 router
		dhcp-option=option:dns-server,${IPV4_ADDR[0]},${IPV4_NSVR[0]}     #  6 dns-server
		#dhcp-option=option:ntp-server,${NTPS_ADDR}              # 42 ntp-server
		#dhcp-option=option:tftp-server,${IPV4_ADDR[0]}                 # 66 tftp-server
		#dhcp-option=option:bootfile-name,                          # 67 bootfile-name
		
		# tftp
		enable-tftp
		tftp-root=${TFTP_ROOT}
		
		# pxe
		pxe-prompt="Press F8 for boot menu", 10
		dhcp-vendorclass=set:bios      , PXEClient:Arch:00000       #  0 Intel x86PC
		dhcp-vendorclass=set:pc98      , PXEClient:Arch:00001       #  1 NEC/PC98
		dhcp-vendorclass=set:efi-ia64  , PXEClient:Arch:00002       #  2 EFI Itanium
		dhcp-vendorclass=set:alpha     , PXEClient:Arch:00003       #  3 DEC Alpha
		dhcp-vendorclass=set:arc_x86   , PXEClient:Arch:00004       #  4 Arc x86
		dhcp-vendorclass=set:intel_lc  , PXEClient:Arch:00005       #  5 Intel Lean Client
		dhcp-vendorclass=set:efi-ia32  , PXEClient:Arch:00006       #  6 EFI IA32
		dhcp-vendorclass=set:efi-bc    , PXEClient:Arch:00007       #  7 EFI BC
		dhcp-vendorclass=set:efi-xscale, PXEClient:Arch:00008       #  8 EFI Xscale
		dhcp-vendorclass=set:efi-x86_64, PXEClient:Arch:00009       #  9 EFI x86-64
		dhcp-vendorclass=set:efi-arm32 , PXEClient:Arch:0000a       # 10 ARM 32bit
		dhcp-vendorclass=set:efi-arm64 , PXEClient:Arch:0000b       # 11 ARM 64bit
		dhcp-boot=tag:bios      , menu-bios/pxelinux.0              #  0 Intel x86PC
		#dhcp-boot=tag:pc98      ,                                  #  1 NEC/PC98
		#dhcp-boot=tag:efi-ia64  ,                                  #  2 EFI Itanium
		#dhcp-boot=tag:alpha     ,                                  #  3 DEC Alpha
		#dhcp-boot=tag:arc_x86   ,                                  #  4 Arc x86
		#dhcp-boot=tag:intel_lc  ,                                  #  5 Intel Lean Client
		#dhcp-boot=tag:efi-ia32  ,                                  #  6 EFI IA32
		dhcp-boot=tag:efi-bc    , menu-efi64/syslinux.efi           #  7 EFI BC
		#dhcp-boot=tag:efi-xscale,                                  #  8 EFI Xscale
		dhcp-boot=tag:efi-x86_64, menu-efi64/syslinux.efi           #  9 EFI x86-64
		#dhcp-boot=tag:efi-arm32 ,                                  # 10 ARM 32bit
		#dhcp-boot=tag:efi-arm64 ,                                  # 11 ARM 64bit
_EOT_
	# -------------------------------------------------------------------------
	SYSD_NAME="dnsmasq.service"
	# shellcheck disable=SC2312
#	if [[ -z "$(command -v nmcli 2> /dev/null)" ]]; then
		# shellcheck disable=SC2312,SC2310
		if [[ "$(funcServiceStatus "${SYSD_NAME}")" = "enabled" ]]; then
			funcPrintf "      ${MSGS_TITL}: restart ${SYSD_NAME}"
			systemctl --quiet restart "${SYSD_NAME}"
		fi
#	else
#		funcPrintf "      ${MSGS_TITL}: stop ${SYSD_NAME}"
#		systemctl --quiet stop    "${SYSD_NAME}"
#		funcPrintf "      ${MSGS_TITL}: disable ${SYSD_NAME}"
#		systemctl --quiet disable "${SYSD_NAME}"
#	fi
}

# ------ firewall -------------------------------------------------------------
function funcNetwork_firewall() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="firewall"
	declare       FWAL_NAME=""
	declare -a    WORK_ARRY=()
	declare       WORK_NAME=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v firewall-cmd 2> /dev/null)" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2207
	WORK_ARRY=($(firewall-cmd --list-services --zone="${FWAL_ZONE}"))
	for FWAL_NAME in "${FWAL_LIST[@]}"
	do
		for WORK_NAME in "${WORK_ARRY[@]}"
		do
			if [[ "${FWAL_NAME}" = "${WORK_NAME}" ]]; then
				continue 2
			fi
		done
		funcPrintf "      ${MSGS_TITL}: add service ${FWAL_NAME}"
		firewall-cmd --quiet --add-service="${FWAL_NAME}" --zone="${FWAL_ZONE}" --permanent
	done
	# -------------------------------------------------------------------------
	funcPrintf "      ${MSGS_TITL}: reload firewall"
	firewall-cmd --quiet --reload
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
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
			# --- updating sources.list  --------------------------------------
			funcPrintf "      ${MSGS_TITL}: updating sources.list"
			FILE_PATH="/etc/apt/sources.list"
			FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
			FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
			if [[ -f "${FILE_PATH}" ]]; then
				if [[ ! -f "${FILE_ORIG}" ]]; then
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

# ----- system shared directory -----------------------------------------------
function funcApplication_system_shared_directory() {
	declare -r    MSGS_TITL="shared directory"
	# shellcheck disable=SC2155
	declare -r    LGIN_SHEL="$(command -v nologin)"			# login shell (disallow system login to samba user)
#	declare       WORK_DIRS=""
#	declare       WORK_TYPE=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
	if [[ -f /etc/selinux/config ]]; then
		WORK_DIRS="${DIRS_SHAR/\./\\.}(/.*)?"
		WORK_TYPE="samba_share_t"
		# shellcheck disable=SC2312
		if [[ -z "$(semanage fcontext --list | awk 'index($1,"'"${WORK_DIRS//\\/\\\\}"'")&&index($4,"'"${WORK_TYPE}"'") {split($4,a,":"); print a[3];}')" ]]; then
			funcPrintf "      ${MSGS_TITL}: semanage fcontext --add --type ${WORK_TYPE}"
			funcPrintf "      ${MSGS_TITL}: ${WORK_DIRS}"
			semanage fcontext --add --type "${WORK_TYPE}" "${WORK_DIRS}"
		fi
		restorecon -R -F "${DIRS_SHAR}"
	fi
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
	declare       FILE_PATH=""
	declare       FILE_ORIG=""
	declare       FILE_BACK=""
	declare       USER_NAME=""
	declare       USER_HOME=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	for USER_NAME in root "$(logname)"	# only root and login user
	do
		funcPrintf "${TXT_RESET}      ${MSGS_TITL}: [${TXT_BGREEN}${USER_NAME}${TXT_RESET}] environment settings"
		if [[ "${USER_NAME}" = "root" ]]; then
			USER_HOME="/${USER_NAME}"
		else
			USER_HOME="$(awk -F ':' '$1=='\""${USER_NAME}"\"' {print $6;}' /etc/passwd)"
		fi
		# --- vim -------------------------------------------------------------
		# shellcheck disable=SC2312
		if [[ -n "$(command -v vim 2> /dev/null)" ]]; then
			funcPrintf "      ${MSGS_TITL}: vim"
			FILE_PATH="${USER_HOME}/.vimrc"
			FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
			FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
			if [[ -f "${FILE_PATH}" ]]; then
				if [[ ! -f "${FILE_ORIG}" ]]; then
					mkdir -p "${FILE_ORIG%/*}"
					cp --archive "${FILE_PATH}" "${FILE_ORIG}"
				else
					mkdir -p "${FILE_BACK%/*}"
					cp --archive "${FILE_PATH}" "${FILE_BACK}"
				fi
			fi
			funcPrintf "      ${MSGS_TITL}: create config file"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			cat <<- '_EOT_' | sed 's/^ *//g' > "${FILE_PATH}"
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
		fi
		# --- curl ------------------------------------------------------------
		# shellcheck disable=SC2312
		if [[ -n "$(command -v curl 2> /dev/null)" ]]; then
			funcPrintf "      ${MSGS_TITL}: curl"
			FILE_PATH="${USER_HOME}/.curlrc"
			FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
			FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
			if [[ -f "${FILE_PATH}" ]]; then
				if [[ ! -f "${FILE_ORIG}" ]]; then
					mkdir -p "${FILE_ORIG%/*}"
					cp --archive "${FILE_PATH}" "${FILE_ORIG}"
				else
					mkdir -p "${FILE_BACK%/*}"
					cp --archive "${FILE_PATH}" "${FILE_BACK}"
				fi
			fi
			funcPrintf "      ${MSGS_TITL}: create config file"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			cat <<- '_EOT_' | sed 's/^ *//g' > "${FILE_PATH}"
				location
				progress-bar
				remote-time
				show-error
_EOT_
			chown "${USER_NAME}": "${FILE_PATH}"
		fi
		# --- measures against garbled characters -----------------------------
		if [[ -f "${USER_HOME}/.bashrc" ]]; then
			FILE_PATH="${USER_HOME}/.bashrc"
		elif [[ -f "${USER_HOME}/.i18n" ]]; then
			FILE_PATH="${USER_HOME}/.i18n"
		else
			FILE_PATH=""
		fi
		# shellcheck disable=SC2312
		if [[ -n "${FILE_PATH}" ]] && [[ -z "$(sed -n '/measures against garbled characters/p' "${FILE_PATH}")" ]]; then
			funcPrintf "      ${MSGS_TITL}: measures against garbled characters"
			FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
			FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
			if [[ -f "${FILE_PATH}" ]]; then
				if [[ ! -f "${FILE_ORIG}" ]]; then
					mkdir -p "${FILE_ORIG%/*}"
					cp --archive "${FILE_PATH}" "${FILE_ORIG}"
				else
					mkdir -p "${FILE_BACK%/*}"
					cp --archive "${FILE_PATH}" "${FILE_BACK}"
				fi
			fi
			funcPrintf "      ${MSGS_TITL}: setup config file"
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			cat <<- '_EOT_' | sed 's/^ *//g' >> "${FILE_PATH}"
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
	pdbedit -L > /dev/null									# for creating passdb.tdb
	declare -r    SAMB_PWDB="$(find /var/lib/samba/ -name 'passdb.tdb' \( -type f -o -type l \))"
	declare -r    SAMB_TEMP="${DIRS_TEMP}/smbpasswd.list.${DATE_TIME}"
	declare -r    PROG_PWDB="${DIRS_ARCH}/${FILE_USER##*/}.${DATE_TIME}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ -f "${FILE_USER}" ]]; then
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
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_ORIG}" ]]; then
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
	declare -r    FILE_PATH="$(find "/etc" -name 'chrony.conf' \( -type f -o -type l \))"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_PATH}" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL}: chrony $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
#	funcPrintf "      ${MSGS_TITL}: create config file"
#	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	funcPrintf "      ${MSGS_TITL}: hwclock --systohc"
	hwclock --systohc
}

# ----- ntp: timesyncd --------------------------------------------------------
function funcApplication_ntp_timesyncd() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="ntp"
	declare -r    FILE_PATH="/etc/systemd/timesyncd.conf.d/ntp.conf"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare       SYSD_NAME=""
	# -------------------------------------------------------------------------
	if [[ ! -d "${FILE_PATH%/*}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL}: timesyncd $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
		# --- user settings ---
		[Time]
		NTP=${NTPS_NAME}
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
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ -f "${FILE_PATH}" ]]; then
		if [[ ! -f "${FILE_ORIG}" ]]; then
			mkdir -p "${FILE_ORIG%/*}"
			cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
		else
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
		fi
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	cat <<- _EOT_ | sed 's/^ *//g' > "${FILE_PATH}"
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
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_ORIG}" ]]; then
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
	if [[ ! -d "${FILE_PATH%/*}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_ORIG}" ]]; then
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
	# -------------------------------------------------------------------------
	if [[ ! -d "${FILE_PATH%/*}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_ORIG}" ]]; then
		mkdir -p "${FILE_ORIG%/*}"
		cp --archive "${FILE_PATH}" "${FILE_ORIG%/*}"
	else
		mkdir -p "${FILE_BACK%/*}"
		cp --archive "${FILE_PATH}" "${FILE_BACK}"
	fi
	funcPrintf "      ${MSGS_TITL}: create config file"
	funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
	# --- orig -> verbose -> delete unseted line & edit parm ------------------
	testparm -s -v "${FILE_ORIG}"                2> /dev/null | \
	sed -e '/^[ \t]*allow nt4 crypto[ \t]*=/d'                  \
	    -e '/^[ \t]*client lanman auth[ \t]*=/d'                \
	    -e '/^[ \t]*client NTLMv2 auth[ \t]*=/d'                \
	    -e '/^[ \t]*client plaintext auth[ \t]*=/d'             \
	    -e '/^[ \t]*client schannel[ \t]*=/d'                   \
	    -e '/^[ \t]*client use spnego principal[ \t]*=/d'       \
	    -e '/^[ \t]*client use spnego[ \t]*=/d'                 \
	    -e '/^[ \t]*domain logons[ \t]*=/d'                     \
	    -e '/^[ \t]*enable privileges[ \t]*=/d'                 \
	    -e '/^[ \t]*encrypt passwords[ \t]*=/d'                 \
	    -e '/^[ \t]*idmap backend[ \t]*=/d'                     \
	    -e '/^[ \t]*idmap gid[ \t]*=/d'                         \
	    -e '/^[ \t]*idmap uid[ \t]*=/d'                         \
	    -e '/^[ \t]*lanman auth[ \t]*=/d'                       \
	    -e '/^[ \t]*lsa over netlogon[ \t]*=/d'                 \
	    -e '/^[ \t]*nbt client socket address[ \t]*=/d'         \
	    -e '/^[ \t]*null passwords[ \t]*=/d'                    \
	    -e '/^[ \t]*raw NTLMv2 auth[ \t]*=/d'                   \
	    -e '/^[ \t]*reject md5 clients[ \t]*=/d'                \
	    -e '/^[ \t]*server schannel[ \t]*=/d'                   \
	    -e '/^[ \t]*server schannel require seal[ \t]*=/d'      \
	    -e '/^[ \t]*syslog[ \t]*=/d'                            \
	    -e '/^[ \t]*syslog only[ \t]*=/d'                       \
	    -e '/^[ \t]*unicode[ \t]*=/d'                           \
	    -e '/^[ \t]*acl check permissions[ \t]*=/d'             \
	    -e '/^[ \t]*allocation roundup size[ \t]*=/d'           \
	    -e '/^[ \t]*blocking locks[ \t]*=/d'                    \
	    -e '/^[ \t]*[[:print:]]\+[ \t]*=[ \t]*$/d'              \
	    -e '/^[ \t]*winbind separator[ \t]*=/d'                 \
	    -e 's/^\([ \t]*dos charset[ \t]*=[ \t]*\).*$/\1=CP932/' \
	>   "${FILE_TEMP}"
	cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_TEMP}"
		[homes]
		 	comment = Home Directories
		 	valid users = %S
		 	write list = @${SAMB_GRUP}
		 	force user = ${SAMB_USER}
		 	force group = ${SAMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No
		
		[netlogon]
		 	comment = Network Logon Service
		 	path = ${DIRS_SHAR}/data/adm/netlogon
		 	valid users = @${SAMB_GRUP}
		 	write list = @${SAMB_GADM}
		 	force user = ${SAMB_USER}
		 	force group = ${SAMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No
		
		[profiles]
		 	comment = User profiles
		 	path = ${DIRS_SHAR}/data/adm/profiles
		 	valid users = @${SAMB_GRUP}
		 	write list = @${SAMB_GRUP}
		#	profile acls = Yes
		 	browseable = No
		
		[share]
		 	comment = Shared directories
		 	path = ${DIRS_SHAR}
		 	valid users = @${SAMB_GADM}
		 	browseable = No
		
		[cifs]
		 	comment = CIFS directories
		 	path = ${DIRS_SHAR}/cifs
		 	valid users = @${SAMB_GADM}
		 	write list = @${SAMB_GADM}
		 	force user = ${SAMB_USER}
		 	force group = ${SAMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No
		
		[data]
		 	comment = Data directories
		 	path = ${DIRS_SHAR}/data
		 	valid users = @${SAMB_GADM}
		 	write list = @${SAMB_GADM}
		 	force user = ${SAMB_USER}
		 	force group = ${SAMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No
		
		[dlna]
		 	comment = DLNA directories
		 	valid users = @${SAMB_GRUP}
		 	path = ${DIRS_SHAR}/dlna
		 	write list = @${SAMB_GRUP}
		 	force user = ${SAMB_USER}
		 	force group = ${SAMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No
		
		[pub]
		 	comment = Public directories
		 	path = ${DIRS_SHAR}/data/pub
		 	valid users = @${SAMB_GRUP}
		
		#[lusr]
		#	comment = Linux /usr directories
		#	path = /usr
		#	valid users = @${SAMB_GRUP}
		 
		[lhome]
		 	comment = Linux /home directories
		 	path = /home
		 	valid users = @${SAMB_GRUP}
		
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
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312,SC2310
	if [[ "$(funcServiceStatus "${SYSD_ARRY[0]}")" = "enabled" ]]; then
		funcPrintf "      ${MSGS_TITL}: restart ${SYSD_ARRY[0]} ${SYSD_ARRY[1]}"
		systemctl --quiet restart "${SYSD_ARRY[0]}" "${SYSD_ARRY[1]}"
	fi
	rm -f "${FILE_TEMP}"
}

# ----- open-vm-tools ---------------------------------------------------------
function funcApplication_open_vm_tools() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="open-vm-tools"
	declare -r    FILE_PATH="/etc/fstab"
	declare -r    FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
	declare -r    FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
	declare -r -a INST_PAKG=("open-vm-tools" "open-vm-tools-desktop")
	declare       HGFS_FSYS=""
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(lsmod | awk '$1~/vmwgfx|vmw_balloon|vmmouse_drv|vmware_drv|vmxnet3|vmw_pvscsi/ {print $1;}')" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -z "$(command -v vmware-checkvm 2> /dev/null)" ]]; then
		funcPrintf "      ${MSGS_TITL}: install open-vm-tools"
		funcPrintf "      ${MSGS_TITL}: package manager"
		funcPrintf "      ${MSGS_TITL}: ${PKGS_MNGR}"
		funcPrintf "      ${MSGS_TITL}: install package"
		funcPrintf "      ${MSGS_TITL}: ${INST_PAKG[*]}"
		"${PKGS_MNGR}" "${PKGS_OPTN[@]}" install "${INST_PAKG[@]}"
	fi
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_ORIG}" ]]; then
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
	if [[ -f "${FILE_PATH}" ]] && [[ -z "$(sed -n "/${HGFS_FSYS}/p" "${FILE_PATH}")" ]]; then
		cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
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
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	if [[ ! -f "${FILE_ORIG}" ]]; then
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
		cat <<- _EOT_ | sed 's/^ *//g' >> "${FILE_PATH}"
			
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
	GRUB_CONF="$(find /boot/efi/ -name 'grub.cfg')"
	if [[ -z "${GRUB_CONF}" ]]; then
		GRUB_CONF="$(find /boot/ -name 'grub.cfg')"
	fi
	funcPrintf "      ${MSGS_TITL}: generating grub configuration file"
	funcPrintf "      ${MSGS_TITL}: ${GRUB_COMD} --output=${GRUB_CONF}"
	"${GRUB_COMD}" --output="${GRUB_CONF}"
}

# ----- root user -------------------------------------------------------------
function funcApplication_root_user() {
	declare -r    DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare -r    MSGS_TITL="root user"
	# shellcheck disable=SC2312
	declare -r    GRUP_SUDO="$(awk -F ':' '$1=="sudo"||$1=="wheel" {print $1;}' /etc/group)"
	# shellcheck disable=SC2312,SC2207
	declare -r -a USER_SUDO=($(groupmems --list --group "${GRUP_SUDO}"))
	# shellcheck disable=SC2312
	declare -r    LGIN_SHEL="$(command -v nologin)"			# login shell (disallow system login to samba user)
	# shellcheck disable=SC2312
	declare -r    USER_SHEL="$(awk -F ':' '$1=="root" {print $7;}' /etc/passwd)"
	declare       INPT_STRS=""
	declare -i    RET_CD=0
	declare -i    I=0
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
		"/etc/clamav/freshclam.conf"                                   \
		"/etc/connman/main.conf"                                       \
		"/etc/default/grub"                                            \
		"/etc/dnsmasq.conf"                                            \
		"/etc/dnsmasq.d/pxe.conf"                                      \
		"/etc/fstab"                                                   \
		"/etc/hosts.allow"                                             \
		"/etc/hosts.deny"                                              \
		"/etc/netplan/99-network-manager-static.yaml"                  \
		"/etc/resolv.conf"                                             \
		"/etc/samba/smb.conf"                                          \
		"/etc/ssh/sshd_config.d/sshd.conf"                             \
		"/etc/systemd/system/connman.service.d/disable_dns_proxy.conf" \
		"/etc/systemd/timesyncd.conf"                                  \
		"/etc/systemd/timesyncd.conf.d/ntp.conf"                       \
		"/home/master/.bashrc"                                         \
		"/home/master/.curlrc"                                         \
		"/home/master/.vimrc"                                          \
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
	# shellcheck disable=SC2312
	funcPrintf "----- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	for ((I=0; I<"${#FILE_LIST[@]}"; I++))
	do
		FILE_PATH="${FILE_LIST[I]}"
		FILE_ORIG="${DIRS_ORIG}/${FILE_PATH}"
		FILE_BACK="${DIRS_BACK}/${FILE_PATH}.${DATE_TIME}"
		if [[ -f "${FILE_PATH}" ]]; then
			funcPrintf "      ${MSGS_TITL}: ${FILE_PATH}"
			mkdir -p "${FILE_BACK%/*}"
			cp --archive "${FILE_PATH}" "${FILE_BACK}"
			if [[ -f "${FILE_ORIG}" ]]; then
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
	# shellcheck disable=SC2312
	funcPrintf "----- os information $(funcString "${COLS_SIZE}" '-')"
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
	# shellcheck disable=SC2312
	funcPrintf "----- host name $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	funcPrintf "HOST_FQDN=${HOST_FQDN:-}"
	funcPrintf "HOST_NAME=${HOST_NAME:-}"
	funcPrintf "HOST_DMAN=${HOST_DMAN:-}"
	# --- network parameter ---------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- network parameter $(funcString "${COLS_SIZE}" '-')"
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
	# shellcheck disable=SC2312
	funcPrintf "----- ping check $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -n "$(command -v ping4 2> /dev/null)" ]]; then
		ping4 -c 4 www.google.com
	else
		ping -4 -c 1 localhost &> /dev/null
		RET_CD=$?
		if [[ "${RET_CD}" -eq 0 ]]; then
			ping -4 -c 4 www.google.com
		else
			ping -c 4 www.google.com
		fi
	fi
	# shellcheck disable=SC2312
	if [[ -n "$(command -v ping6 2> /dev/null)" ]]; then
		# shellcheck disable=SC2312
		funcPrintf "$(funcString "${COLS_SIZE}" '･')"
		ping6 -c 4 www.google.com
	fi
	# shellcheck disable=SC2312
	funcPrintf "----- ping check $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- connman chk $(funcString "${COLS_SIZE}" '-')"
	ss -tulpn | sed -n '/:53/p'
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- nslookup $(funcString "${COLS_SIZE}" '-')"
	nslookup "${HOST_FQDN}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
	nslookup "${IPV4_ADDR[0]}"
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	nslookup "${IPV6_ADDR[0]}"
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	nslookup "${LINK_ADDR[0]}"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- dns check $(funcString "${COLS_SIZE}" '-')"
#	dig @localhost "${IPV4_RADR[0]}.in-addr.arpa" DNSKEY +dnssec +multi
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	dig @localhost "${HOST_DMAN}" DNSKEY +dnssec +multi
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	dig @"${IPV4_ADDR[0]}" "${HOST_DMAN}" axfr
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	dig @"${IPV6_ADDR[0]}" "${HOST_DMAN}" axfr
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	dig @"${LINK_ADDR[0]}" "${HOST_DMAN}" axfr
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
	dig "${HOST_FQDN}" A +nostats +nocomments
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	dig "${HOST_FQDN}" AAAA +nostats +nocomments
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
	dig -x "${IPV4_ADDR[0]}" +nostats +nocomments
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	dig -x "${IPV6_ADDR[0]}" +nostats +nocomments
	# -------------------------------------------------------------------------
#	# shellcheck disable=SC2312
#	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
#	dig -x "${LINK_ADDR[0]}" +nostats +nocomments
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- dns check $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	set -e
}

# ----- ntp -------------------------------------------------------------------
function funcDebug_ntp() {
	declare -r    FILE_NAME="/etc/systemd/timesyncd.conf"
	declare -r    FILE_ORIG="${FILE_NAME}/.orig"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcDiff "${FILE_ORIG}" "${FILE_NAME}" "----- diff ${FILE_NAME} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -n "$(command -v timedatectl 2> /dev/null)" ]]; then
		# shellcheck disable=SC2312
		funcPrintf "----- timedatectl status $(funcString "${COLS_SIZE}" '-')"
		timedatectl status
		# shellcheck disable=SC2312
		funcPrintf "----- timedatectl timesync-status $(funcString "${COLS_SIZE}" '-')"
		set +e
		timedatectl timesync-status 2> /dev/null
		set -e
	fi
}

# ----- smb -------------------------------------------------------------------
function funcDebug_smb() {
	# shellcheck disable=SC2312
	if [[ -n "$(command -v pdbedit 2> /dev/null)" ]]; then
		# shellcheck disable=SC2312
		funcPrintf "----- pdbedit -L $(funcString "${COLS_SIZE}" '-')"
		pdbedit -L
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	if [[ -n "$(command -v smbclient 2> /dev/null)" ]]; then
		# shellcheck disable=SC2312
		funcPrintf "----- smbclient -N -L ${HOST_FQDN} $(funcString "${COLS_SIZE}" '-')"
		smbclient -N -L "${HOST_FQDN}"
	fi
}

# ----- open-vm-tools ---------------------------------------------------------
function funcDebug_open_vm_tools() {
	if [[ ! -d "${HGFS_DIRS}/." ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "----- df -h ${HGFS_DIRS} $(funcString "${COLS_SIZE}" '-')"
	LANG=C df -h "${HGFS_DIRS}"
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
	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
	printf '%s\n' "${LIST_ORIG[@]}"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
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
	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
	printf '%s\n' "${LIST_BACK[@]}"
	# shellcheck disable=SC2312
	funcPrintf "$(funcString "${COLS_SIZE}" '･')"
	funcPrintf "     ${MSGS_TITL}: compress files"
	funcPrintf "     ${MSGS_TITL}: ${FILE_BACK/${PWD}\//}"
	tar -czf "${FILE_BACK/${PWD}\//}" "${LIST_BACK[@]}"
	funcPrintf "     ${MSGS_TITL}: list of files to delete"
	rm -I "${LIST_BACK[@]}"
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL}: remaining files $(funcString "${COLS_SIZE}" '-')"
	find "${DIRS_BACK/${PWD}\//}" \( -type f -o -type l \) | sort
}

# === call function ===========================================================

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

# ---- cleaning ---------------------------------------------------------------
function funcCall_cleaning() {
#	declare -r    OLD_IFS="${IFS}"
	declare -r    MSGS_TITL="call cleaning"
	declare -n    COMD_RETN="$1"
	declare -a    COMD_LIST=()
	# -------------------------------------------------------------------------
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("sys" "net" "ntp" "smb" "vm" "$@")
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
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
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
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("aldy" "nic" "resolv" "pxe" "fwall" "$@")
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
			aldy )						# ===== hosts.allow / hosts.deny ======
				funcNetwork_hosts_allow_deny
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
			pxe )						# ===== pxe.conf ======================
				funcNetwork_pxe_conf
				;;
			fwall )						# ===== firewall ======================
				funcNetwork_firewall
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
	# shellcheck disable=SC2312
	funcPrintf "---- ${MSGS_TITL} $(funcString "${COLS_SIZE}" '-')"
	# -------------------------------------------------------------------------
	shift 2
	if [[ -z "${1:-}" ]] || [[ "$1" =~ ^- ]]; then
		COMD_LIST=("pmn" "ctl" "sys" "usr" "av" "ntp" "ssh" "dns" "web" "smb" "vm" "grub" "root" "$@")
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
			ctl )						# ===== system control ================
				funcSystem_control
				;;
			sys )						# ===== system ========================
				funcApplication_system_shared_directory
				funcApplication_system_user_environment
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
	# shellcheck disable=SC2312
	funcPrintf "---- call all process $(funcString "${COLS_SIZE}" '-')"
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
		funcPrintf ""
		funcPrintf "all install process (same as --network and --package)"
		funcPrintf "  -a | -all"
		funcPrintf ""
		funcPrintf "network settings (empty is [ options ])"
		funcPrintf "  -n | --network [ aldy nic resolv pxe fwall ]"
		funcPrintf "    aldy    hosts.allow / hosts.deny"
		funcPrintf "    nic     connman netplan networkmanager"
		funcPrintf "    resolv  resolv.conf"
		funcPrintf "    pxe     pxe boot (dnsmasq)"
		funcPrintf "    fwall   firewall"
		funcPrintf ""
		funcPrintf "package settings (empty is [ options ])"
		funcPrintf "  -p | --package [ pmn ctl sys usr av ntp ssh dns web smb vm root ]"
		funcPrintf "    pmn     package manager"
		funcPrintf "    ctl     system control"
		funcPrintf "    sys     [ sysenv sysdir ]"
		funcPrintf "    sysenv  system environment"
		funcPrintf "    sysdir  system shared directory"
		funcPrintf "    usr     user add"
		funcPrintf "    av      clamav"
		funcPrintf "    dns     dnsmasq"
		funcPrintf "    web     apache2"
		funcPrintf "    smb     samba"
		funcPrintf "    smbex   samba user export"
		funcPrintf "    vm      open-vm-tools"
		funcPrintf "    grub    grub"
		funcPrintf "    root    disable root user login"
		funcPrintf ""
		funcPrintf "debug print and test (empty is [ options ])"
		funcPrintf "  -d | --debug [ sys net ntp smb vm ]"
		funcPrintf "    func    function test"
		funcPrintf "    text    text color test"
		funcPrintf "    sys     system"
		funcPrintf "    net     network"
		funcPrintf "    ntp     ntp"
		funcPrintf "    smb     smb"
		funcPrintf "    vm      open-vm-tools"
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
		# shellcheck disable=SC2312
		funcPrintf "---- parameter $(funcString "${COLS_SIZE}" '-')"
		# ---------------------------------------------------------------------
		funcSystem_parameter				# system parameter
		funcNetwork_parameter				# network parameter

		IFS=' =,'
		set -f
		set -- "${COMD_LINE[@]:-}"
		set +f
		IFS=${OLD_IFS}
		while [[ -n "${1:-}" ]]
		do
			case "${1:-}" in
				-a | -all       )			# ==== all ========================
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
