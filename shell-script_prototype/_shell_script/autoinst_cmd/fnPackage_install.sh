# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: package install
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
#   g-var : _DIRS_ACMD : read
# shellcheck disable=SC2148,SC2317,SC2329
fnPackage_install() {
	__FUNC_NAME="fnPackage_install"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	__PATH="${_DIRS_ACMD:?}/${_FILE_SEED##*/}"
	if [ ! -e "${__PATH}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- get package list ----------------------------------------------------
	__LIST=""
	case "${__PATH##*/}" in
		yast*.xml|auto*.xml)	;;	#  autoyast
		agama*.json|auto*.json)	;;	#  agama
		kickstart*.cfg|ks*.cfg) ;;	#  kickstart
		user-data*)					# (nocloud)
			__LIST="$( \
				sed -ne '/^[^#]\+packages:/,/^[^#]\+[[:graph:]]\+:/ {' \
				    -e  '/^[^#]\+[ \t]*-[ \t]/                      {' \
				    -e  's/^[ \t]*-[ \t]*//g                         ' \
				    -e  's/[ \t]*#.*$//g                             ' \
				    -e  'p                                         }}' \
				    "${__PATH}"                                      | \
				sed -e ':l; N; s/[\r\n]\+/ /; b l                    ' \
			)"
			;;
		preseed*.cfg|ps*.cfg)		# (preseed)
			__LIST="$( \
				sed -ne '\%^[^#]\+d-i[ \t]\+pkgsel/include%,\%[^\\]$% {' \
				    -e  '\%pkgsel/include%!                           {' \
				    -e  's/[\\]\+$//g                                  ' \
				    -e  's/^[ \t]\+//g                                 ' \
				    -e  's/[ \t]\+$//g                                 ' \
				    -e  's/[ \t]\+/ /g                                 ' \
				    -e 'p                                            }}' \
				    "${__PATH}"                                        | \
				sed -e ':l; N; s/[\r\n]\+/ /; b l                      ' \
			)"
			;;
		*)	;;
	esac
	if [ -z "${__LIST:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "no package list"
	else
		if command -v apt-get > /dev/null 2>&1; then
			# --- sources.list ------------------------------------------------
#			__PATH="${_DIRS_TGET:-}/etc/apt/sources.list"
#			fnFile_backup "${__PATH}"			# backup original file
#			mkdir -p "${__PATH%/*}"
#			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
#			sed -i "${__PATH}"                         \
#			    -e '/^[ \t]*deb[ \t]\+cdrom:/ s/^/#/g'
#			fnDbgdump "${__PATH}"				# debugout
#			fnFile_backup "${__PATH}" "init"	# backup initial file
			# --- get missing packages ----------------------------------------
			set -f
			set -- ${__LIST:+${__LIST}}
			set +f
			__FIND="$( \
				LANG=C dpkg-query --no-pager --show --showformat='${Status}\t${Architecture}\t${binary:Package}\n' "$@" 2>&1 || true \
			)"
			__INST="$( \
				printf "%s\n" "${__FIND:-}" | \
					awk '/^install[ \t]+ok[ \t]+installed[ \t]+/ {gsub(/^.+[ \t]/,""); print}'
			)"
			__FIND="$( \
				printf "%s\n" "${__FIND:-}" | \
					awk '!/^install[ \t]+ok[ \t]+installed[ \t]+/ {gsub(/^.+[ \t]/,""); print}'
			)"
			# --- install missing packages ------------------------------------
			set -f
			set -- ${__INST:+${__INST}}
			set +f
			fnMsgout "${_PROG_NAME:-}" "info" "installed packages list"
			fnMsgout "${_PROG_NAME:-}" "info" "${*:-}"
			set -f
			set -- ${__FIND:+${__FIND}}
			set +f
			fnMsgout "${_PROG_NAME:-}" "info" "missing packages list"
			fnMsgout "${_PROG_NAME:-}" "info" "${*:-}"
			if [ -z "${*:-}" ]; then
				fnMsgout "${_PROG_NAME:-}" "skip" "no missing packages"
			else
				fnMsgout "${_PROG_NAME:-}" "info" "missing packages install"
				if ! apt-get --quiet              update      ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get update";       return; fi
#				if ! apt-get --quiet --assume-yes upgrade     ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get upgrade";      return; fi
#				if ! apt-get --quiet --assume-yes dist-upgrade; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get dist-upgrade"; return; fi
				if ! apt-get --quiet --assume-yes install "$@"; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get install $*";   return; fi
				if ! apt-get --quiet --assume-yes autoremove  ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get autoremove";   return; fi
				if ! apt-get --quiet --assume-yes autoclean   ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get autoclean";    return; fi
				if ! apt-get --quiet --assume-yes clean       ; then fnMsgout "${_PROG_NAME:-}" "failed" "apt-get clean";        return; fi
			fi
		fi
	fi
	unset __PATH __LIST __FIND __INST

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset __FUNC_NAME
}
