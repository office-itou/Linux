# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: main routine
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMain() {
	declare -r    _FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${_FUNC_NAME}]"

	declare       __PROC=""
	declare -a    __OPTN=()
	declare       __RSLT=""

	# --- initial setup -------------------------------------------------------
	fnInitialize						# initialize

	# --- main processing -----------------------------------------------------
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		__PROC="${1:-}"
		shift
		__OPTN=("${@:-}")
		case "${__PROC:-}" in
			-h|--help) fnHelp;;
			-l|--link) fnMk_symlink "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			-c|--conf) fnMk_preconf "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			-p|--pxe ) fnMk_pxeboot "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			-m|--make) fnMk_isofile "__RSLT" "${__OPTN[@]:-}"; read -r -a __OPTN < <(echo "${__RSLT}");;
			-P|--DBGP) fnDbgparameters_all; break;;
			-T|--TREE) tree --charset C -x -a --filesfirst "${_DIRS_TOPS:-}"; break;;
			*        ) ;;
		esac
		set -f -- "${__OPTN[@]}"
		set +f
	done

	# --- debug output --------------------------------------------------------

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${_FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
