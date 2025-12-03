# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: screen output
#   input :     $@     : list
#   output:   stdout   : message
#   return:            : unused
#   g-var : _COLS_SIZE : read
#   g-var : _TEXT_GAP2 : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnScreen_output() {
	declare       __FMTG=""
	declare       __FMTT=""
	declare -a    __LIST=()
	__FMTG="%-$((_COLS_SIZE-2)).$((_COLS_SIZE-2))s"
	if [[ "${_COLS_SIZE}" -le 100 ]]; then
		__FMTT="%2.2s:%-42.42s:%-10.10s:%-10.10s:%-$((_COLS_SIZE-70)).$((_COLS_SIZE-70))s"
	else
		__FMTT="%2.2s:%-48.48s:%-10.10s:%-10.10s:%-$((_COLS_SIZE-76)).$((_COLS_SIZE-76))s"
	fi
	printf "%c${__FMTG}%c\n" "#" "${_TEXT_GAP2}" "#"
	set -f -- "${@:-}"
	set +f
	if [[ "$#" -gt 0 ]]; then
		printf "%c${__FMTT}%c\n" "#" "ID" "Target file name" "ReleaseDay" "SupportEnd" "Memo" "#"
		while [[ -n "${1:-}" ]]
		do
			read -r -a __LIST < <(echo "${1:-}")
			shift
			__LIST=("${__LIST[@]//%20/ }")
			__LIST[15]="${__LIST[15]##*/}"
			__LIST[25]="${__LIST[25]##*/}"
			__LIST=("${__LIST[@]##-}")
			printf "%c${__FMTT}%c\n" "#" "${__LIST[1]:-}" "${__LIST[15]:-}" "${__LIST[16]:-}" "${__LIST[9]:-}" "${__LIST[25]:-}" "#"
		done
	fi
	printf "%c${__FMTG}%c\n" "#" "${_TEXT_GAP2}" "#"
	unset __FMTG __FMTT __LIST
}
