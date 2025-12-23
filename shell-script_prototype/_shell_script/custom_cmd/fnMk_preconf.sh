# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make preconfiguration files
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _LIST_MDIA : read
function fnMk_preconf() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare       __PTRN=""				# pattern
	declare -a    __TGET=()				# target
	declare       __LINE=""				# data line
	declare -a    __LIST=()				# data list
	declare       __PATH=""				# full path

	# --- get target ----------------------------------------------------------
	__PTRN=""
	set -f -- "${@:-}"
	set +f
	while [[ -n "${1:-}" ]]
	do
		case "$1" in
			a|all    ) __PTRN="agama|autoyast|kickstart|nocloud|preseed"; shift; break;;
			agama    ) ;;
			autoyast ) ;;
			kickstart) ;;
			nocloud  ) ;;
			preseed  ) ;;
			*) break;;
		esac
		__PTRN="${__PTRN:+"${__PTRN}|"}$1"
		shift
	done
	__NAME_REFR="${*:-}"

	# --- create a file  ------------------------------------------------------
	if [[ -n "${__PTRN:-}" ]]; then
		IFS= mapfile -d $'\n' -t __TGET < <(\
			printf "%s\n" "${_LIST_MDIA[@]}" | \
			awk -v ptrn="@/.*\/${__PTRN}\/.*/" '$2=="o" && $25!~/.*-$/ && $25~ptrn {
				print $25
				switch ($25) {
					case /.*\/agama\/.*/:
						sub("_leap-[0-9]+.[0-9]+", "_tumbleweed", $25)
						print $25
						break
					case /.*\/kickstart\/.*/:
						sub("_dvd", "_web", $25)
						print $25
						break
					default:
						break
				}
			}' | sort -uV || true \
		)
		for __PATH in "${__TGET[@]}"
		do
			case "${__PATH}" in
				*/preseed/*  ) fnMk_preconf_preseed   "${__PATH}";;
				*/nocloud/*  ) fnMk_preconf_nocloud   "${__PATH}/user-data";;
				*/kickstart/*) fnMk_preconf_kickstart "${__PATH}";;
				*/autoyast/* ) fnMk_preconf_autoyast  "${__PATH}";;
				*/agama/*    ) fnMk_preconf_agama     "${__PATH}";;
				*)	;;
			esac
		done
	fi
	unset __OPTN __PTRN __TGET __LINE __LIST __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
