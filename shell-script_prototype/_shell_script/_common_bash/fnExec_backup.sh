# -----------------------------------------------------------------------------
# descript: executing the backup (3 generation)
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : status
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnExec_backup() {
	declare       __TGET_PATH="${1:?}"	# target path
	declare       __RNAM=""				# rename path
	declare       __PATH=""				# full path
	declare -i    __RTCD=0				# return code
	# --- check file exists ---------------------------------------------------
	if [[ -f "${__TGET_PATH:?}" ]]; then
		__RNAM="${__TGET_PATH}.$(TZ=UTC find "${__TGET_PATH}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		fnMsgout "backup" "${__RNAM}"
		mv "${__TGET_PATH}" "${__RNAM}"
	fi
	# --- delete old files ----------------------------------------------------
	if [[ -e "${__TGET_PATH%/*}/." ]]; then
		while read -r __PATH
		do
			fnMsgout "remove" "${__PATH}"
			rm -f "${__PATH:?}"
		done < <(find "${__TGET_PATH%/*}" -name "${__TGET_PATH##*/}.[0-9]*" | sort -r | tail -n +3 || true)
	fi
	# --- complete ------------------------------------------------------------
	return "${__RTCD}"
}
