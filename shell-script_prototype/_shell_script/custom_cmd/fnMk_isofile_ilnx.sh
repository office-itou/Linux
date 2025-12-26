# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make isolinux files
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
function fnMk_isofile_ilnx() {
	declare -r    __TGET_DIRS="${1:?}"
	declare -r    __FILE_NAME="${2:?}"
	declare -r    __TIME_STMP="${3:?}"
	declare -r    __PATH_FKNL="${4:?}"
	declare -r    __PATH_FIRD="${5:?}"
	declare -r    __NWRK_HOST="${6:?}"
	declare -r    __IPV4_CIDR="${7:?}"
	declare -a    __OPTN_BOOT=("${@:7}")
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FILE=""				# file name
	declare       __PAUT=""				# autoinst.cfg
	declare       __PTHM=""				# theme.txt
	__PATH="$(find "${__TGET_DIRS}" -name isolinux.cfg)"
	[[ -z "${__PATH:-}" ]] && return
	__DIRS="$(fnDirname "${__PATH#"${__TGET_DIRS}"}")"
	__PAUT="${__DIRS%/}/${_AUTO_INST:-"autoinst.cfg"}"
	__PTHM="${__DIRS%/}/theme.txt"
	# --- create files --------------------------------------------------------
	fnMk_isofile_ilnx_theme "${__FILE_NAME:-}" "${__TIME_STMP:-}" > "${__PTHM}"
	fnMk_isofile_ilnx_autoinst "${__PATH_FKNL:-}" "${__PATH_FIRD:-}" "${__NWRK_HOST:-}" "${__IPV4_CIDR:-}" "${__OPTN_BOOT[@]:-}" > "${__PAUT}"
	# --- insert autoinst.cfg -------------------------------------------------
	if grep -qEi '^include[ \t]+menu.cfg[ \t]*.*$' "${__PATH}"; then
		sed -i "${__PATH}"                                                                   \
		    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${__PAUT:?}"'' \
		    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/a include '"${__PTHM:?}"''
	else
		sed -i "${__PATH}"                                      \
		    -e '0,/\([Ll]abel\|LABEL\)/ {'                      \
		    -e '/\([Ll]abel\|LABEL\)/i include '"${__PAUT}"'\n' \
		    -e '}'
	fi
	# --- comment out ---------------------------------------------------------
	while read -r __PATH
	do
		sed -i "${__PATH}"                                                               \
		    -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]*/ {/.*\.c32/!                   d}' \
		    -e '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]*/                               d'  \
		    -e '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]*/                                 d'  \
		    -e '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]*/                           d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[ \t]*/       d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]*/     d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]*/ d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Hh]shift\|HSHIFT\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Ww]idth\|WIDTH\)[ \t]*/           d'
	done < <(find "${__DIRS:-"/"}" \( -name '*.cfg' -a ! -name "${_AUTO_INST:-"autoinst.cfg"}" \))
}
