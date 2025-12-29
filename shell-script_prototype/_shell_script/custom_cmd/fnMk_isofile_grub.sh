# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make grub.cfg files
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   input :     $3     : iso file time stamp
#   input :     $4     : kernel path
#   input :     $5     : initrd path
#   input :     $6     : host name
#   input :     $7     : ipv4 cidr
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMk_isofile_grub() {
	declare -r    __TGET_DIRS="${1:?}"
	declare -r    __FILE_NAME="${2:?}"
	declare -r    __TIME_STMP="${3:?}"
	declare -r    __PATH_FKNL="${4:?}"
	declare -r    __PATH_FIRD="${5:?}"
	declare -r    __NWRK_HOST="${6:?}"
	declare -r    __IPV4_CIDR="${7:-}"
	declare -r -a __OPTN_BOOT=("${@:8}")
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __BASE=""				# base name
	declare       __FILE=""				# file name
	declare       __PAUT=""				# autoinst.cfg
	declare       __PTHM=""				# theme.txt
	__PATH="$(find "${__TGET_DIRS}" -name grub.cfg -exec grep -ilE 'menuentry .*install' {} \;)"
	[[ -z "${__PATH:-}" ]] && return
	__DIRS="$(fnDirname "${__PATH#"${__TGET_DIRS}"}")"
	__PAUT="${__DIRS%/}/${_AUTO_INST:-"autoinst.cfg"}"
	__PTHM="${__DIRS%/}/theme.txt"
	__DIRS="$(fnDirname  "${__PATH_FIRD}")"
	__BASE="$(fnBasename "${__PATH_FIRD}")"
	__GUIS=""
	if [[ -e "${__TGET_DIRS}/${__DIRS#/}/gtk/${__BASE:?}" ]]; then
		__GUIS="/${__DIRS#/}/gtk/${__BASE}"
	fi
	# --- create files --------------------------------------------------------
	fnMk_isofile_grub_theme "${__FILE_NAME:-}" "${__TIME_STMP:-}" > "${__TGET_DIRS}/${__PTHM}"
	fnMk_isofile_grub_autoinst "${__FILE_NAME:-}" "${__TIME_STMP:-}" "${__PTHM#"${__TGET_DIRS}"}" "${__PATH_FKNL:-}" "${__PATH_FIRD:-}" "${__GUIS}" "${__NWRK_HOST:-}" "${__IPV4_CIDR:-}" "${__OPTN_BOOT[@]:-}" > "${__TGET_DIRS}/${__PAUT}"
	# --- insert autoinst.cfg -------------------------------------------------
	sed -i "${__PATH}"                            \
	    -e '0,/^menuentry/ {'                     \
	    -e '/^menuentry/i source '"${__PAUT}"'\n' \
	    -e '}'
	# --- comment out ---------------------------------------------------------
	find "${__TGET_DIRS}/${__DIRS:-"/"}" \( -name '*.cfg' -a ! -name "${_AUTO_INST:-"autoinst.cfg"}" \) | while read -r __PATH
	do
		sed -i "${__PATH}"                                              \
		    -e '/^[ \t]*\(\|set[ \t]\+\)default=/              s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)timeout=/              s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)gfxmode=/              s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)theme=/                s/^/#/g' \
		    -e '/^[ \t]*if[ \t]\+background_image/,/^[ \t]*fi/ s/^/#/g' \
		    -e '/^[ \t]*play/ s/^/#/g'
	done
	# --- splash.png ----------------------------------------------------------
	__PATH="$(find "${__TGET_DIRS}" -name "${_MENU_SPLS:-}")"
	if [[ -n "${__PATH:-}" ]]; then
		__PATH="${__PATH#"${__TGET_DIRS}"}"
		sed -i "${__TGET_DIRS}/${__PTHM}"                              \
		    -e '/desktop-image:/ s/:_DTPIMG_:/'"${__PATH//\//\\\/}"'/'
	else
		sed -i "${__TGET_DIRS}/${__PTHM}" \
		    -e '/desktop-image:/d'
	fi
	unset __PATH __DIRS __BASE __FILE __PAUT __PTHM
}
