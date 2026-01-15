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
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __PROC=""
	declare -a    __OPTN=()
	declare       __RSLT=""

	# --- initial setup -------------------------------------------------------
	fnInitialize						# initialize
	fnSystem_param						# get system parameter
	fnNetwork_param						# get network parameter

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
			-P|--DBGP) fnDbgparameters_all; break;;
			-T|--TREE) tree --charset C -x -a --filesfirst "${_DIRS_TOPS:-}"; break;;
			*        )
				echo "${_TEXT_GAP2:-}"
				fnTest_cmdline			# test cmdline
				echo "${_TEXT_GAP2:-}"
				fnTest_param			# test parameter
				echo "${_TEXT_GAP2:-}"
				fnTest_dns_port			# test dns port
				echo "${_TEXT_GAP2:-}"
				fnTest_nslookup			# test nslookup
				echo "${_TEXT_GAP2:-}"
				fnTest_dig				# test dig
				echo "${_TEXT_GAP2:-}"
				fnTest_getent			# test getent
				echo "${_TEXT_GAP2:-}"
				fnTest_ping				# test ping
				echo "${_TEXT_GAP2:-}"
				fnTest_timedatectl		# test timedatectl
				echo "${_TEXT_GAP2:-}"
				fnTest_chronyc			# test chronyc
				echo "${_TEXT_GAP2:-}"
				fnTest_nmblookup		# test nmblookup
				echo "${_TEXT_GAP2:-}"
				fnTest_smbclient		# test smbclient
				echo "${_TEXT_GAP2:-}"
				fnTest_pdbedit			# test pdbedit
				echo "${_TEXT_GAP2:-}"
				fnTest_httpd			# test httpd
				echo "${_TEXT_GAP2:-}"
				fnTest_service			# test service
				echo "${_TEXT_GAP2:-}"
				fnTest_apparmor			# test apparmor
				echo "${_TEXT_GAP2:-}"
				fnTest_selinux			# test selinux
				echo "${_TEXT_GAP2:-}"
				fnTest_vmware			# test vmware
				echo "${_TEXT_GAP2:-}"
				;;
		esac
		set -f -- "${__OPTN[@]}"
		set +f
	done
	unset __PROC __OPTN __RSLT

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
