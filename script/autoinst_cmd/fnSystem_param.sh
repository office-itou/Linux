# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get system parameter (includes dash support)
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
#   g-var : _DIST_NAME : write
#   g-var : _DIST_VERS : write
#   g-var : _DIST_CODE : write
# shellcheck disable=SC2148,SC2317,SC2329
fnSystem_param() {
	___PATH=""
	if [ -e "${_DIRS_TGET:-}"/etc/os-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/os-release"
	elif [ -e "${_DIRS_TGET:-}"/etc/lsb-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/lsb-release"
	fi
	if [ -n "${___PATH}" ]; then
		_DIST_NAME="$(awk -F= '/^(ID|DISTRIB_ID)=/ {gsub(/"/,"",$2); print tolower($2); exit}' "${___PATH}")"
		_DIST_VERS="$(awk -F= '/^(VERSION_ID|DISTRIB_RELEASE)=/ {gsub(/"/,"",$2); print tolower($2); exit}' "${___PATH}")"
		_DIST_CODE="$(awk -F= '/^(VERSION_CODENAME|DISTRIB_CODENAME)=/ {gsub(/"/,"",$2); print tolower($2); exit}' "${___PATH}")"
	fi
	readonly _DIST_NAME
	readonly _DIST_CODE
	readonly _DIST_VERS
	unset ___PATH
}
