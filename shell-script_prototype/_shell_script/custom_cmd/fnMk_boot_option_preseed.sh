# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make boot options for preseed
#   input :     $1     : target type (remake or pxeboot)
#   input :   $2..$@   : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _DIRS_CONF : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_LOAD : read
#   g-var : _DIRS_ISOS : read
#   g-var : _DIRS_RMAK : read
# shellcheck disable=SC2317,SC2329
function fnMk_boot_option_preseed() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
	__BOPT=("server=\$\{srvraddr\}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${26##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}auto=true preseed/file=/cdrom${26#"${_DIRS_CONF%/*}"}"
		[[ "${__TGET_TYPE:-}" = "pxeboot" ]] && __WORK="${__WORK/file=\/cdrom/url=\$\{srvraddr\}}"
		case "${4}" in
			ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}automatic-ubiquity noprompt ${__WORK}";;
			*-mini-*                        ) __WORK="${__WORK/\/cdrom/}";;
			*                               ) ;;
		esac
	fi
	case "${2}" in
		live) __WORK="boot=live";;
		*) ;;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	case "${4}" in
		live-debian-*   |live-ubuntu-*  ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp,us keyboard-model=pc105 keyboard-variants=,";;
		debian-live-*                   ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                               ) __WORK="${__WORK:+"${__WORK} "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${26##*-}" ]]; then
		case "${4}" in
			ubuntu-*) __WORK="${__WORK:+"${__WORK} "}netcfg/target_network_config=NetworkManager";;
			*       ) ;;
		esac
		__WORK="${__WORK:+"${__WORK} "}netcfg/disable_autoconfig=true"
		__WORK="${__WORK:+"${__WORK} "}netcfg/choose_interface=\${ethrname}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_hostname=\${hostname}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_ipaddress=\${ipv4addr}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_netmask=\${ipv4mask}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_gateway=\${ipv4gway}"
		__WORK="${__WORK:+"${__WORK} "}netcfg/get_nameservers=\${ipv4nsvr}"
	fi
	case "${2}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK:-}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}root=/dev/ram0"
	if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
		case "${4}" in
#			debian-mini-*                       ) ;;
			ubuntu-mini-*                       ) __WORK="${__WORK:+"${__WORK} "}initrd=\$\{srvraddr\}/${_DIRS_IMGS##*/}/${24#"${_DIRS_LOAD}"} iso-url=\$\{srvraddr\}/${_DIRS_ISOS##*/}${16#"${_DIRS_ISOS}"}";;
			ubuntu-desktop-18.*|ubuntu-live-18.*| \
			ubuntu-desktop-20.*|ubuntu-live-20.*| \
			ubuntu-desktop-22.*|ubuntu-live-22.*| \
			ubuntu-server-*    |ubuntu-legacy-* ) __WORK="${__WORK:+"${__WORK} "}boot=casper url=\$\{srvraddr\}/${_DIRS_ISOS##*/}${16#"${_DIRS_ISOS}"}";;
			ubuntu-*                            ) __WORK="${__WORK:+"${__WORK} "}boot=casper iso-url=\$\{srvraddr\}/${_DIRS_ISOS##*/}${16#"${_DIRS_ISOS}"}";;
			live-*                              ) __WORK="${__WORK:+"${__WORK} "}fetch=\$\{srvraddr\}/${_DIRS_RMAK##*/}/${16##*/}";;
			*                                   ) __WORK="${__WORK:+"${__WORK} "}fetch=\$\{srvraddr\}/${_DIRS_ISOS##*/}${16#"${_DIRS_ISOS}"}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
