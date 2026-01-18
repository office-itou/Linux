# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make boot options for agama
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
function fnMk_boot_option_agama() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __MDIA=("${@:-}")
	declare -a    __BOPT=()
#	declare       __VERS=""
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
#	__BOPT=("server=\${srvraddr}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}live.password=install inst.auto=dvd:${__MDIA[$((_OSET_MDIA+24))]#"${_DIRS_CONF%/*}"}"
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK/dvd:/\$\{srvraddr\}}"
			__WORK="${__WORK/_dvd/_web}"
		else
			__WORK="${__WORK:+"${__WORK}?devices=sr0"}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}language=ja_JP"
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}netsetup=dhcp hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
#	__WORK=""
#	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
#		__WORK="${__WORK:+"${__WORK} "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr}"
#		case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
#			opensuse-*-15*) __WORK="${__WORK//"${_NICS_NAME:-ens160}"/"eth0"}";;
#			*             ) ;;
#		esac
#	fi
#	case "${__MDIA[$((_OSET_MDIA+0))]:-}" in
#		live) __WORK="dhcp";;
#		*   ) __WORK="${__WORK:-"dhcp"}";;
#	esac
#	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK:+"${__WORK} "}root=live:\${srvraddr}/${_DIRS_ISOS##*/}/${__MDIA[$((_OSET_MDIA+14))]#"${_DIRS_ISOS}"/}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
