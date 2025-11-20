# -----------------------------------------------------------------------------
# descript: get media data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_MDIA : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnGet_media_data() {
	declare       __TGET_PATH="${1:?}"	# target path
	# --- file import ---------------------------------------------------------
	if [[ -z "${__TGET_PATH}" ]]; then
		fnMsgout "failed" "not found: [${__TGET_PATH}]"
		exit 1
	fi
	_LIST_MDIA=()
	IFS= mapfile -d $'\n' -t _LIST_MDIA < <(expand -t 4 "${__TGET_PATH}" || true)
	if [[ "${#_LIST_MDIA[@]}" -le 0 ]]; then
		fnMsgout "failed" "no data: [${__TGET_PATH}]"
		exit 1
	fi
	fnDebugout_list "${_LIST_MDIA[@]}"
	fnDbgparameters
}
