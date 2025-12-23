# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make boot options for kickstart
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
function fnMk_boot_option_kickstart() {
	declare -r    __TGET_TYPE="${1:?}"
	shift
	declare -a    __BOPT=()
	declare       __WORK=""
	# --- 0: server -----------------------------------------------------------
	__BOPT=("server=\$\{srvraddr\}")
	# --- 1: autoinst ---------------------------------------------------------
	__WORK=""
	if [[ -n "${26##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}inst.ks=hd:sr0:${26#"${_DIRS_CONF%/*}"}"
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK/hd:sr0:/\$\{srvraddr\}}"
			__WORK="${__WORK/_dvd/_web}"
		fi
	fi
	__BOPT+=("${__WORK}")
	# --- 2: language ---------------------------------------------------------
	__WORK=""
	__WORK="${__WORK:+"${__WORK} "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__WORK="${__WORK:+"${__WORK} "}language=ja_JP"
	__BOPT+=("${__WORK}")
	# --- 3: network ----------------------------------------------------------
	__WORK=""
	if [[ -n "${26##*-}" ]]; then
		__WORK="${__WORK:+"${__WORK} "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr}"
	fi
	case "${2}" in
		live) __WORK="dhcp";;
		*   ) __WORK="${__WORK:-"dhcp"}";;
	esac
	__BOPT+=("${__WORK}")
	# --- 4: otheropt ---------------------------------------------------------
	__WORK=""
	if [[ -n "${26##*-}" ]]; then
		if [[ "${__TGET_TYPE:-}" = "pxeboot" ]]; then
			__WORK="${__WORK:+"${__WORK} "}inst.repo=\$\{srvraddr\}/${_DIRS_IMGS##*/}/${4}"
		else
			__WORK="${__WORK:+"${__WORK} "}inst.stage2=hd:LABEL=${19}"
		fi
	else
		case "${2}" in
			clive) __WORK="${__WORK:+"${__WORK} "}root=live:\$\{srvraddr\}/${_DIRS_RMAK##*/}/${16##*/}";;
			*    ) __WORK="${__WORK:+"${__WORK} "}root=live:\$\{srvraddr\}/${_DIRS_ISOS##*/}${16#"${_DIRS_ISOS}"}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# --- output --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}
