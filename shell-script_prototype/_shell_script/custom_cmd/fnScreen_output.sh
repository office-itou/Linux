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
	set -f -- "${@:-}"
	set +f
	if [[ "$#" -gt 0 ]] && [[ -n "${*:-}" ]]; then
		printf "%c${__FMTG}%c\n" "#" "${_TEXT_GAP2}" "#"
		printf "%c${__FMTT}%c\n" "#" "ID" "Target file name" "ReleaseDay" "SupportEnd" "Memo" "#"
		printf "%s\n" "${@:-}" | awk '
		{
			split($0, _arry, "\n")
			for (i in _arry) {
				split(_arry[i], _list)
				for (j in _list) {
					gsub("%20", " ", _list[j])
				}
				sub("^.*/", "", _list[16])
				sub("^.*/", "", _list[26])
				sub("^-+$", "", _list[16])
				sub("^-+$", "", _list[26])
				_list[17]=substr(_list[17], 1, 10)
				_list[10]=substr(_list[10], 1, 10)
				_list[26]=substr(_list[26], 1, 44)
				sub("^-+$", "\033[m\033[90m----------\033[m", _list[17])
				sub("^-+$", "\033[m\033[90m----------\033[m", _list[10])
				sub("^$", "\033[m\033[37m"_list[6]"\033[m", _list[26])
				printf("\033[m%c%2d:%-48.48s:%-10s:%-10s:%-44s%c\033[m\n", "#", _list[2], _list[16], _list[17], _list[10], _list[26], "#")
			}
		}'
#		while [[ -n "${1:-}" ]]
#		do
#			read -r -a __LIST < <(echo "${1:-}")
#			shift
#			__LIST=("${__LIST[@]//%20/ }")
#			__LIST[15]="${__LIST[15]##*/}"
#			__LIST[25]="${__LIST[25]##*/}"
#			__LIST=("${__LIST[@]##-}")
#			printf "%c${__FMTT}%c\n" "#" "${__LIST[1]:-}" "${__LIST[15]:-}" "${__LIST[16]:-}" "${__LIST[9]:-}" "${__LIST[25]:-}" "#"
#		done
		printf "%c${__FMTG}%c\n" "#" "${_TEXT_GAP2}" "#"
	fi
	unset __FMTG __FMTT __LIST
}
