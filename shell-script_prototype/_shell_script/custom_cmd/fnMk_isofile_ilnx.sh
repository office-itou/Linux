# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make isolinux files
#   input :     $1     : target directory
#   input :     $2     : iso file name
#   input :     $3     : iso file time stamp
#   input :     $4     : kernel path
#   input :     $5     : initrd path
#   input :     $6     : nic name
#   input :     $7     : host name
#   input :     $8     : ipv4 cidr
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMk_isofile_ilnx() {
	declare -r    __TGET_DIRS="${1:?}"
	declare -r    __FILE_NAME="${2:?}"
	declare -r    __TIME_STMP="${3:?}"
	declare -r    __PATH_FKNL="${4:?}"
	declare -r    __PATH_FIRD="${5:?}"
	declare -r    __NICS_NAME="${6:?}"
	declare -r    __NWRK_HOST="${7:?}"
	declare -r    __IPV4_CIDR="${8:-}"
	declare -r -a __OPTN_BOOT=("${@:9}")
	__ILNX="$(find "${__TGET_DIRS}" -name isolinux.cfg)"
	[[ -z "${__ILNX:-}" ]] && return
	__DIRS="$(fnDirname "${__ILNX#"${__TGET_DIRS}"}")"
	__PAUT="${__DIRS%/}/${_AUTO_INST:-"autoinst.cfg"}"
	__PTHM="${__DIRS%/}/theme.txt"
	__DIRS="$(fnDirname  "${__PATH_FIRD}")"
	__BASE="$(fnBasename "${__PATH_FIRD}")"
	__GUIS=""
	if [[ -e "${__TGET_DIRS}/${__DIRS#/}/gtk/${__BASE:?}" ]]; then
		__GUIS="/${__DIRS#/}/gtk/${__BASE}"
	fi
	# --- create files --------------------------------------------------------
	fnMk_isofile_ilnx_theme "${__FILE_NAME:-}" "${__TIME_STMP:-}" > "${__TGET_DIRS}/${__PTHM}"
	fnMk_isofile_ilnx_autoinst "${__PATH_FKNL:-}" "${__PATH_FIRD:-}" "${__GUIS:-}" "${__NICS_NAME:-}" "${__NWRK_HOST:-}" "${__IPV4_CIDR:-}" "${__OPTN_BOOT[@]:-}" > "${__TGET_DIRS}/${__PAUT}"
	# --- insert autoinst.cfg -------------------------------------------------
	if grep -qEi '^include[ \t]+menu.cfg[ \t]*.*$' "${__ILNX}"; then
		sed -i "${__ILNX}"                                                                   \
		    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${__PAUT:?}"'' \
		    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/a include '"${__PTHM:?}"''
	else
		sed -i "${__ILNX}"                                      \
		    -e '0,/\([Ll]abel\|LABEL\)/ {'                      \
		    -e '/\([Ll]abel\|LABEL\)/i include '"${__PAUT}"'\n' \
		    -e '}'
	fi
	# --- comment out ---------------------------------------------------------
	__DIRS="$(fnDirname "${__ILNX}")"
	find "${__DIRS:-"/"}" \( -name '*.cfg' -a ! -name "${_AUTO_INST:-"autoinst.cfg"}" \) | while read -r __PATH
	do
		sed -i "${__PATH}"                                                                    \
		    -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]*/ {/.*\.c32/!                   s/^/#/}' \
		    -e '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]*/                               s/^/#/'  \
		    -e '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]*/                                 s/^/#/'  \
		    -e '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]*/                           s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[ \t]*/       s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]*/     s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]*/         s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]*/ s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Hh]shift\|HSHIFT\)[ \t]*/         s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Ww]idth\|WIDTH\)[ \t]*/           s/^/#/'  \
		    -e '/^[ \t]*\([Ii]nclude\|INCLUDE\)[ \t]\+stdmenu.cfg/                         s/^/#/'
	done
	unset __PATH __DIRS __FILE __PAUT __PTHM
}
