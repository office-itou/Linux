# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make autoinst.json
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
#   g-var : _PATH_AGMA : read
# shellcheck disable=SC2317,SC2329
function fnMk_preconf_agama() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
#	declare       __PDCT=""				# product name
	declare       __PDID=""				# "       id
	declare       __WORK=""				# work variables
	declare       __REAL=""
	declare       __DIRS=""
	declare       __OWNR=""
	declare       __URLS=""
	declare       __PROT=""
	declare       __DMIN=""
	declare -a    __ARRY=()

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_AGMA}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__WORK="${__TGET_PATH##*/}"			# file name (ex: autoinst_tumbleweed.json)
	__VERS="${__WORK#*_}"				# autoinst_(name)-(nums)_ ...: (ex: autoinst_leap-16.0_desktop.json)
	__VERS="${__VERS%.*}"				# ...json
	__VERS="${__VERS%%_*}"				# vers="(name)-(nums)"
	__VERS="${__VERS,,}"
	__NUMS="${__VERS##*-}"
#	__PDCT="${__VERS%%-*}"
#	__PDID="${__VERS//-/_}"
#	__PDID="${__PDID^}"
	# --- by product id -------------------------------------------------------
	case "${__TGET_PATH}" in
		*_tumbleweed*) __PDID="Tumbleweed";;
		*            ) __PDID="openSUSE_Leap";;
	esac
	# --- by media ------------------------------------------------------------
	# --- by version ----------------------------------------------------------
#	"url": "https://download.opensuse.org/distribution/leap/:_RELEASE_:/repo/oss/",
#	"url": "https://download.opensuse.org/tumbleweed/repo/oss/",
	__ARRY=(
		-ne '/"extraRepositories": \[/,/\]/ {'
		-e  '/"url":/{'
		-e  's/^.*:[ \t]\+"*//'
		-e  's/",*$//'
		-e  's/:_RELEASE_:/'"${__NUMS}"'/'
		-e 'p}}'
	)
	__URLS="$(sed "${__TGET_PATH}" "${__ARRY[@]}")"
	__PROT="${__URLS%%://*}"
	__DMIN="${__URLS#"${__PROT}://"}"
	__DMIN="${__DMIN%%/*}"
	case "${__TGET_PATH}" in
		*_tumbleweed*) __URLS="${__PROT}://${__DMIN}/tumbleweed/repo/oss/";;
		*            ) ;;
	esac
	__ARRY=(
		-e '/"product": {/,/}/{/"id":/ s/"[^ ]\+"$/"'"${__PDID}"'"/}'
		-e '/"extraRepositories": \[/,/\]/{/"url":/ s%"[^"]\+",*$%"'"${__URLS}"'"%}'
		-e '/"__comment_fixed_parameter_start":/,/"__comment_fixed_parameter_end":/d'
	)
	if ! sed -i "${__TGET_PATH}" "${__ARRY[@]}"; then
		__RTCD="$?"
		printf "%s\n" "sed -i \"${__TGET_PATH}\" ${__ARRY[*]}"
		exit "${__RTCD:-}"
	fi
	# --- desktop -------------------------------------------------------------
	__WORK="${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	cp "${__TGET_PATH}" "${__WORK}"
	__ARRY=(
		-e '/"patterns": \[/,/\]/ {/"__comment_desktop_start"/,/"__comment_desktop_end"/d}'
		-e '/"patterns": {/,/}/   {/"__comment_desktop_start"/,/"__comment_desktop_end"/d}'
		-e '/"packages": \[/,/\]/ {/"__comment_desktop_start"/,/"__comment_desktop_end"/d}'
	)
	if ! sed -i "${__TGET_PATH}" "${__ARRY[@]}"; then
		__RTCD="$?"
		printf "%s\n" "sed -i \"${__TGET_PATH}\" ${__ARRY[*]}"
		exit "${__RTCD:-}"
	fi
	__ARRY=(
		-e '/"__comment_desktop_start"/d'
		-e '/"__comment_desktop_end"/d'
	)
	if ! sed -i "${__WORK}" "${__ARRY[@]}"; then
		__RTCD="$?"
		printf "%s\n" "sed -i \"${__WORK}\" ${__ARRY[*]}"
		exit "${__RTCD:-}"
	fi

#	sed -i "${__TGET_PATH}"                                                                   \
#	    -e '/"product": {/,/}/                                                             {' \
#	    -e '/"id":/ s/"[^ ]\+"$/"'"${__PDID}"'"/                                           }' \
#	    -e '/"extraRepositories": \[/,/\]/                                                 {' \
#	    -e 's/:_RELEASE_:/'"${__NUMS}"'/                                                    ' \
#	    -e '\%^// '"${__WORK}"'%,\%^// '"${__WORK}"'%d                                      ' \
#	    -e '\%^//.*$%d                                                                     }' \
#	    -e '\%^// fixed parameter%,\%^// fixed parameter%d                                  ' \
#	    -e '/"__comment_fixed_parameter_start":/,/"__comment_fixed_parameter_end":/d'
	# --- desktop -------------------------------------------------------------
#	__WORK="${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
#	cp "${__TGET_PATH}" "${__WORK}"
#	sed -i "${__TGET_PATH}"                                                                   \
#	    -e '/"patterns": \[/,/\]/ {\%^// desktop%,\%^// desktop%d}                          ' \
#	    -e '/"patterns": {/,/}/   {\%^// desktop%,\%^// desktop%d}                          ' \
#	    -e '/"packages": \[/,/\]/ {\%^// desktop%,\%^// desktop%d}                          ' \
#	    -e '/"patterns": \[/,/\]/ {/"__comment_desktop_start":/,/"__comment_desktop_end":/d}' \
#	    -e '/"patterns": {/,/}/   {/"__comment_desktop_start":/,/"__comment_desktop_end":/d}' \
#	    -e '/"packages": \[/,/\]/ {/"__comment_desktop_start":/,/"__comment_desktop_end":/d}'
#	sed -i "${__WORK}"                                                                        \
#	    -e '/"patterns": \[/,/\]/ \%^//.*$%d                                                ' \
#	    -e '/"patterns": {/,/}/   \%^//.*$%d                                                ' \
#	    -e '/"packages": \[/,/\]/ \%^//.*$%d                                                ' \
#	    -e '/"__comment_desktop_start"/gd                                                   ' \
#	    -e '/"__comment_desktop_end"/gd'
	# -------------------------------------------------------------------------
	__REAL="$(realpath "${__TGET_PATH}")"
	__DIRS="$(fnDirname "${__TGET_PATH}")"
	__OWNR="${__DIRS:+"$(stat -c '%U' "${__DIRS}")"}"
	chown "${__OWNR:-"${_SAMB_USER}"}" "${__TGET_PATH}"
	chmod ugo+r-x,ug+w "${__TGET_PATH}" "${__WORK}"
	unset __VERS __NUMS __PDCT __PDID __WORK __REAL __DIRS __OWNR
}
