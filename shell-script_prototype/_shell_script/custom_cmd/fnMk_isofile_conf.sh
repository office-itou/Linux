# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make iso files
#   input :     $1     : target directory
#   input :     $2     : configuration files
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_CONF : read
#   g-var : _PATH_ERLY : read
#   g-var : _PATH_LATE : read
#   g-var : _PATH_PART : read
#   g-var : _PATH_RUNS : read
function fnMk_isofile_conf() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __FILE_CONF="${2:?}"	# configuration files
	declare       __PATH=""				# target path
	declare       __SRCS=""				# source path
	declare       __DEST=""				# destination path
	declare       __FILE=""				# full path
	declare       __DIRS=""				# directory
	declare       __BASE=""				# base name
	declare       __FNAM=""				# file name
	declare       __EXTN=""				# extension
	declare       __WORK=""

	for __PATH in         \
		"${_PATH_ERLY:-}" \
		"${_PATH_LATE:-}" \
		"${_PATH_PART:-}" \
		"${_PATH_RUNS:-}" \
		"${__FILE_CONF}"
	do
		if [[ ! -e "${__PATH}" ]]; then
			continue
		fi
		__FILE="${__PATH#"${_DIRS_CONF%/*}/"}"
		__DIRS="$(fnDirname   "${__FILE:-}")"
		__BASE="$(fnBasename  "${__FILE:-}")"
		__FNAM="$(fnFilename  "${__FILE:-}")"
		__EXTN="$(fnExtension "${__FILE:-}")"
		__DEST="${__DIRS_TGET}/${__DIRS:?}"
		case "${__PATH}" in
			*/script/*   )
				printf "\033[m%-8s: %s\033[m\n" "copy" "${__FILE}"
				mkdir -p "${__DEST:?}"
				cp --preserve=timestamps "${__PATH}" "${__DEST}"
				chmod ugo+rx-w "${__DEST}/${__BASE}"
				;;
			*/agama/*    | \
			*/autoyast/* | \
			*/kickstart/*| \
			*/nocloud/*  | \
			*/preseed/*  )
				__WORK="${__FNAM#*_*_}"
				__WORK="${__FNAM%"${__WORK:-}"}"
				__WORK="${__WORK:+"${__WORK}*${__EXTN:+".${__EXTN}"}"}"
				if [[ -d "${__PATH}"/. ]]; then
					__WORK="${__WORK:-"${__BASE%"${__BASE##*_}"}*"}"
				else
					__WORK="${__WORK:-"${__BASE:-}"}"
				fi
				find "${__PATH%/*}" -maxdepth 1 -name "${__WORK:-}" | sort -uV | while read -r __SRCS
				do
					printf "\033[m%-8s: %s\033[m\n" "copy" "${__SRCS#"${_DIRS_CONF}/"}"
					mkdir -p "${__DEST:?}"
					if [[ -d "${__SRCS:?}"/. ]]; then
						cp -R --preserve=timestamps "${__SRCS}" "${__DEST}"
						find "${__DEST}/${__SRCS##*/}" -type f -exec chmod ugo+r-xw {} \;
					else
						cp --preserve=timestamps "${__SRCS}" "${__DEST}"
						chmod ugo+r-xw "${__DEST}/${__SRCS##*/}"
					fi
				done
				;;
			*) ;;
		esac
	done
}
