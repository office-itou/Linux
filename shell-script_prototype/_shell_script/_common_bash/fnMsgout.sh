# -----------------------------------------------------------------------------
# descript: message output
#   input :     $1     : section (start, complete, remove, umount, failed, ...)
#   input :     $2     : message
#   input :     $3     : log file name (optional)
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMsgout() {
	{
		case "${1:-}" in
			start    | complete)
				case "${2:-}" in
					*/*/*) printf "\033[m${_PROG_NAME:-}: \033[45m--- %-8.8s: %s ---\033[m\n" "${1:-}" "${2:-}";; # date
					*    ) printf "\033[m${_PROG_NAME:-}: \033[92m--- %-8.8s: %s ---\033[m\n" "${1:-}" "${2:-}";; # info
				esac
				;;
			remove   | umount  ) printf "\033[m${_PROG_NAME:-}:     \033[93m%-8.8s: %s\033[m\n"        "${1:-}" "${2:-}";; # warn
			archive            ) printf "\033[m${_PROG_NAME:-}:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${1:-}" "${2:-}";; # warn
			success            ) printf "\033[m${_PROG_NAME:-}:     \033[92m%-8.8s: %s\033[m\n"        "${1:-}" "${2:-}";; # info
			failed             ) printf "\033[m${_PROG_NAME:-}:     \033[41m%-8.8s: %s\033[m\n"        "${1:-}" "${2:-}";; # alert
			caution            ) printf "\033[m${_PROG_NAME:-}:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${1:-}" "${2:-}";; # warn
			-*                 ) printf "\033[m${_PROG_NAME:-}:     \033[36m%-8.8s: %s\033[m\n"        "${1#-}" "${2:-}";; # gap
			info               ) printf "\033[m${_PROG_NAME:-}: \033[92m%12.12s: %s\033[m\n"           "${1:-}" "${2:-}";; # info
			warn               ) printf "\033[m${_PROG_NAME:-}: \033[93m%12.12s: %s\033[m\n"           "${1:-}" "${2:-}";; # warn
			alert              ) printf "\033[m${_PROG_NAME:-}: \033[91m%12.12s: %s\033[m\n"           "${1:-}" "${2:-}";; # alert
			*                  ) printf "\033[m${_PROG_NAME:-}: \033[37m%12.12s: %s\033[m\n"           "${1:-}" "${2:-}";; # normal
		esac
	} | tee -a ${3:+"$3"} 1>&2
}
