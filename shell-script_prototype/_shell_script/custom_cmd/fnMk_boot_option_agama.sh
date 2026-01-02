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
		__WORK="${__WORK:+"${__WORK} "}hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
		case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
			opensuse-*-15*) __WORK="${__WORK//"${_NICS_NAME:-ens160}"/"eth0"}";;
			*             ) ;;
		esac
	fi
	case "${__MDIA[$((_OSET_MDIA+0))]:-}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${__MDIA[$((_OSET_MDIA+24))]##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
				opensuse-leap*netinst*      ) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/distribution/leap/${__MDIA[$((_OSET_MDIA+2))]##*[^0-9]}/repo/oss/";;
				opensuse-tumbleweed*netinst*) __WORK="${__WORK:+"${__WORK} "}install=https://download.opensuse.org/tumbleweed/repo/oss/";;
				*                           ) __WORK="${__WORK:+"${__WORK} "}install=\${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]##*[^0-9]}";;
			esac
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
