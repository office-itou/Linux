# -----------------------------------------------------------------------------
# descript: get common configuration data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_CONF : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnGet_conf_data() {
	declare       __TGET_PATH="${1:?}"	# target path
	if [[ -z "${__TGET_PATH}" ]]; then
		fnMsgout "failed" "not found: [${__TGET_PATH}]"
		exit 1
	fi
	_LIST_CONF=()
	IFS= mapfile -d $'\n' -t _LIST_CONF < <(expand -t 4 "${__TGET_PATH}" || true)
	if [[ "${#_LIST_CONF[@]}" -le 0 ]]; then
		fnMsgout "failed" "no data: [${__TGET_PATH}]"
		exit 1
	fi
	fnDebugout_list "${_LIST_CONF[@]}"
	fnDebugout_parameters
}
