# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make grub.cfg files
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
function fnMk_isofile_grub() {
	declare -r    __TGET_DIRS="${1:?}"
	declare -r    __FILE_NAME="${2:?}"
	declare -r    __TIME_STMP="${3:?}"
	declare -r    __PATH_FKNL="${4:?}"
	declare -r    __PATH_FIRD="${5:?}"
	declare -r    __NICS_NAME="${6:?}"
	declare -r    __NWRK_HOST="${7:?}"
	declare -r    __IPV4_CIDR="${8:-}"
	declare -r -a __OPTN_BOOT=("${@:9}")
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __BASE=""				# base name
	declare       __FILE=""				# file name
	declare       __PAUT=""				# autoinst.cfg
	declare       __PTHM=""				# theme.txt
	declare       __SPLS=""				# splash.png
	declare       __CONF=""				# configuration files
	declare       __WORK=""
	__SPLS=""
	while read -r __CONF
	do
		__DIRS="$(fnDirname "${__CONF#"${__TGET_DIRS}"}")"
		__PAUT="${__DIRS%/}/${_AUTO_INST:-"autoinst.cfg"}"
		__PTHM="${__DIRS%/}/theme.txt"
		__DIRS="$(fnDirname  "${__PATH_FIRD}")"
		__BASE="$(fnBasename "${__PATH_FIRD}")"
		__GUIS=""
		if [[ -e "${__TGET_DIRS}/${__DIRS#/}/gtk/${__BASE:?}" ]]; then
			__GUIS="/${__DIRS#/}/gtk/${__BASE}"
		fi
		# --- create files ----------------------------------------------------
		fnMk_isofile_grub_theme "${__FILE_NAME:-}" "${__TIME_STMP:-}" > "${__TGET_DIRS}/${__PTHM}"
		fnMk_isofile_grub_autoinst "${__FILE_NAME:-}" "${__TIME_STMP:-}" "${__PTHM#"${__TGET_DIRS}"}" "${__PATH_FKNL:-}" "${__PATH_FIRD:-}" "${__GUIS:-}" "${__NICS_NAME:-}" "${__NWRK_HOST:-}" "${__IPV4_CIDR:-}" "${__OPTN_BOOT[@]:-}" > "${__TGET_DIRS}/${__PAUT}"
		# --- insert autoinst.cfg ---------------------------------------------
		sed -i "${__CONF}"                            \
		    -e '0,/^menuentry/ {'                     \
		    -e '/^menuentry/i source '"${__PAUT}"'\n' \
		    -e '}'
		# --- splash.png ------------------------------------------------------
		                          __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/boot/*'     -iname "${_MENU_SPLS:-}")"
		[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/isolinux/*' -iname "${_MENU_SPLS:-}")"
		[[ -z "${__PATH:-}" ]] && __PATH="$(find "${__TGET_DIRS}" -depth -type f -ipath '*/*'          -iname "${_MENU_SPLS:-}")"
		if [[ -n "${__PATH:-}" ]]; then
			__WORK="$(file "${__PATH:-}" | awk '{sub("[^0-9]+","",$8); print $8;}')"
			[[ "${__WORK:-"0"}" -ge 8 ]] && __SPLS="${__PATH}"
		fi
	done < <(find "${__TGET_DIRS}" -name grub.cfg -exec grep -ilE 'menuentry .*install' {} \;)
	if [[ -n "${__SPLS:-}" ]]; then
		__SPLS="${__SPLS#"${__TGET_DIRS}"}"
		sed -i "${__TGET_DIRS}/${__PTHM}"                              \
			-e '/desktop-image:/ s/:_DTPIMG_:/'"${__SPLS//\//\\\/}"'/'
	else
		sed -i "${__TGET_DIRS}/${__PTHM}" \
			-e '/desktop-image:/d'
	fi
	# --- comment out ---------------------------------------------------------
	find "${__TGET_DIRS}" \( -name '*.cfg' -a ! -name "${_AUTO_INST:-"autoinst.cfg"}" \) | while read -r __CONF
	do
		sed -i "${__CONF}"                                              \
		    -e '/^[ \t]*\(\|set[ \t]\+\)default=/              s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)timeout=/              s/^/#/g' \
		    -e '/^[ \t]*\(\|set[ \t]\+\)gfxmode=/              s/^/#/g'
#		    -e '/^[ \t]*\(\|set[ \t]\+\)theme=/                s/^/#/g' \
#		    -e '/^[ \t]*export theme/                          s/^/#/g' \
# 		    -e '/^[ \t]*if[ \t]\+sleep/,/^[ \t]*fi/            s/^/#/g' \
#		    -e '/^[ \t]*if[ \t]\+background_image/,/^[ \t]*fi/ s/^/#/g'
#		    -e '/^[ \t]*play/                                  s/^/#/g'
	done
	unset __PATH __DIRS __BASE __FILE __PAUT __PTHM
}
