# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make boot options for nocloud
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
function fnMk_boot_option_nocloud() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=/cdrom${__MDIA[$((_OSET_MDIA+24))]#"${_DIRS_CONF%/*}"}"
		[[ "${__TGET_TYPE:-}" = "pxeboot" ]] && __WORK="${__WORK/\/cdrom/url=\$\{srvraddr\}}"
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="boot=live";;
		*) ;;
	esac
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	case "${__MDIA[$((_OSET_MDIA+2))]}" in
		live-debian-*   |live-ubuntu-*  ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-layouts=jp,us keyboard-model=pc105 keyboard-variants=,";;
		debian-live-*                   ) __WORK="${__WORK:+"${__WORK} "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*|ubuntu-legacy-*) __WORK="${__WORK:+"${__WORK} "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                               ) __WORK="${__WORK:+"${__WORK} "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		case "${__MDIA[$((_OSET_MDIA+2))]}" in
			ubuntu-live-18.04   ) __WORK="${__WORK:+"${__WORK} "}ip=\${ethrname},\${ipv4addr},\${ipv4mask},\${ipv4gway} hostname=\${hostname}";;
			*                   ) __WORK="${__WORK:+"${__WORK} "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}::\${ethrname}:${_IPV4_ADDR:+static}:\${ipv4nsvr} hostname=\${hostname}";;
		esac
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="ip=dhcp";;
		*   ) __WORK="${__WORK:-"ip=dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}root=/dev/ram0"
	if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
		case "${__MDIA[$((_OSET_MDIA+2))]}" in
#			debian-mini-*                       ) ;;
			ubuntu-mini-*                       ) __WORK="${__WORK:+"${__WORK} "}initrd=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+22))]#"${_DIRS_LOAD}"} iso-url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			ubuntu-desktop-18.*|ubuntu-live-18.*| \
			ubuntu-desktop-20.*|ubuntu-live-20.*| \
			ubuntu-desktop-22.*|ubuntu-live-22.*| \
			ubuntu-server-*    |ubuntu-legacy-* ) __WORK="${__WORK:+"${__WORK} "}boot=casper url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			ubuntu-*                            ) __WORK="${__WORK:+"${__WORK} "}boot=casper iso-url=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
			live-*                              ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_RMAK##*/}/${__MDIA[$((_OSET_MDIA+14))]##*/}";;
			*                                   ) __WORK="${__WORK:+"${__WORK} "}fetch=\${srvraddr}/${_DIRS_ISOS##*/}${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
