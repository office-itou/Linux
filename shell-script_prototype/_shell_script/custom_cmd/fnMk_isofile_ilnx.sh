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
		    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${__PTHM:?}"'' \
		    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${__PAUT:?}"''
	else
		sed -i "${__ILNX}"                                        \
		    -e '0,/\([Ll]abel\|LABEL\)/ {'                        \
		    -e '/\([Ll]abel\|LABEL\)/i include '"${__PTHM:?}"     \
		    -e '/\([Ll]abel\|LABEL\)/i include '"${__PAUT:?}"'\n' \
		    -e '}'
	fi
	# --- splash.png ----------------------------------------------------------
	__SPLS=""
	                          __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/boot/*'     -iname "${_MENU_SPLS:-}")"
	[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/isolinux/*' -iname "${_MENU_SPLS:-}")"
	[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/*'          -iname "${_MENU_SPLS:-}")"
	if [[ -n "${__PATH:-}" ]]; then
		__WORK="$(file "${__PATH:-}" | awk '{sub("[^0-9]+","",$8); print $8;}')"
		[[ "${__WORK:-"0"}" -ge 8 ]] && __SPLS="${__PATH}"
	fi
	if [[ -n "${__SPLS:-}" ]]; then
		__SPLS="${__SPLS#"${__TGET_DIRS}"}"
		sed -i "${__TGET_DIRS}/${__PTHM}"                              \
		    -e '/menu[ \t]\+background/ s/:_DTPIMG_:/'"${__SPLS//\//\\\/}"'/'
	else
		sed -i "${__TGET_DIRS}/${__PTHM}" \
		    -e '/menu[ \t]\+background/d'
	fi
	# --- vesamenu.c32 / gfxboot.c32 ------------------------------------------
	                          __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/boot/*'     -iname 'vesamenu.c32')"
	[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/isolinux/*' -iname 'vesamenu.c32')"
	[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/*'          -iname 'vesamenu.c32')"
	[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/boot/*'     -iname 'gfxboot.c32')"
	[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/isolinux/*' -iname 'gfxboot.c32')"
	[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/*'          -iname 'gfxboot.c32')"
	if [[ -n "${__PATH:-}" ]]; then
		__PATH="${__PATH#"${__TGET_DIRS}"}"
		[[ "${__PATH##*/}" = gfxboot.c32 ]] && __PATH+=" bootlogo message"
		sed -i "${__TGET_DIRS}/${__PTHM}"                                   \
		    -e '/default[ \t]\+:_VESA32_:/ s/:_VESA32_:/'"${__PATH##*/}"'/'
	else
		sed -i "${__TGET_DIRS}/${__PTHM}"    \
		    -e '/default[ \t]\+:_VESA32_:/d'
	fi
	# --- comment out ---------------------------------------------------------
	__DIRS="$(fnDirname "${__ILNX}")"
	find "${__DIRS:-"/"}" \( -name '*.cfg' -a ! -name "${_AUTO_INST:-"autoinst.cfg"}" \) | while read -r __PATH
	do
		sed -i "${__PATH}"                                                                    \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]*/ s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Cc]lear\|CLEAR\)[ \t]*/           s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Bb]ackground\|BACKGROUND\)[ \t]*/ s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]itle\|TITLE\)[ \t]*/           s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Vv]shift\|VSHIFT\)[ \t]*/         s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]ows\|ROWS\)[ \t]*/             s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Mm]argin\|MARGIN\)[ \t]*/         s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Hh]elpmsgrow\|HELPMSGROW\)[ \t]*/ s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsgrow\|TABMSGROW\)[ \t]*/   s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Cc]olor\|COLOR\)[ \t]*/           s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]*/         s/^/#/'  \
 		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[ \t]*/       s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]*/     s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]*/ s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Hh]shift\|HSHIFT\)[ \t]*/         s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Ww]idth\|WIDTH\)[ \t]*/           s/^/#/'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Ss]eparator\|SEPARATOR\)[ \t]*/   s/^/#/'  \
		    -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]*/ {/.*\.c32/!                   s/^/#/}' \
		    -e '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]*/                               s/^/#/'  \
		    -e '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]*/                                 s/^/#/'  \
		    -e '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]*/                           s/^/#/'  \
		    -e '/^[ \t]*\([Ii]nclude\|INCLUDE\)[ \t]\+stdmenu.cfg/                   s/^/#/'  \
		    -e '/^[ \t]*\([Dd]isplay\|DISPLAY\)[ \t]*/                               s/^/#/'  \
		    -e '/^[ \t]*\([Uu]i\|UI\)[ \t]*/                                         s/^/#/'  \
		    -e '/^[ \t]*\([Ii]mplicit\|IMPLICIT\)[ \t]*/                             s/^/#/'
 	done
	unset __PATH __DIRS __FILE __PAUT __PTHM
}
