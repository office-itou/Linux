# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make symlink
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _LIST_MDIA : read
function fnMk_symlink() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare       __FORC=""				# force parameter
	declare       __PTRN=""				# pattern
	declare       __LINE=""				# work
	declare -a    __LIST=()				# work
	declare -i    I=0

	# --- get target ----------------------------------------------------------
	__PTRN=""
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		case "$1" in
			create   ) __FORC="true"; shift; break;;
			update   ) __FORC=""    ; shift; break;;
			*) break;;
		esac
		shift
	done
	__NAME_REFR="${*:-}"

	# --- create directory ----------------------------------------------------
	[[ -n "${__FORC:-}" ]] && fnMk_symlink_dir

	# --- create symbolic link [iso files] ------------------------------------
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]:-}"
		read -r -a __LIST < <(echo "${__LINE:-}")
		case "${__LIST[1]##-}" in		# entry_flag
			'') continue;;
			o ) ;;
			* ) continue;;
		esac
		case "${__LIST[13]##-}" in		# iso_path
			'') continue;;
			- ) continue;;
			* ) ;;
		esac
		case "${__LIST[25]##-}" in		# lnk_path
			'') continue;;
			- ) continue;;
			* ) ;;
		esac
		[[ -h "${__LIST[13]}" ]] && continue
		fnMsgout "${_PROG_NAME:-}" "create" "${__LIST[13]}"
		mkdir -p "${__LIST[13]%/*}"
		ln -s "${__LIST[25]}/${__LIST[13]##*/}" "${__LIST[13]}"
	done
	unset __NAME_REFR __OPTN __FORC __PTRN __LINE __LIST I

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
