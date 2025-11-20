# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get system parameter
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
#   g-var : _DIST_NAME : write
#   g-var : _DIST_VERS : write
#   g-var : _DIST_CODE : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnSystem_param() {
	declare       ___PATH=""
	if [ -e "${_DIRS_TGET:-}"/etc/os-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/os-release"
		_DIST_NAME="$(sed -ne 's/^ID=//p'                                "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_VERS="$(sed -ne 's/^VERSION=\"\([[:graph:]]\+\).*\"$/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_CODE="$(sed -ne 's/^VERSION_CODENAME=//p'                  "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
	elif [ -e "${_DIRS_TGET:-}"/etc/lsb-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/lsb-release"
		_DIST_NAME="$(sed -ne 's/DISTRIB_ID=//p'                                     "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_VERS="$(sed -ne 's/DISTRIB_RELEASE=\"\([[:graph:]]\+\)[ \t].*\"$/\1/p' "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
		_DIST_CODE="$(sed -ne 's/^VERSION=\".*(\([[:graph:]]\+\)).*\"$/\1/p'         "${___PATH:-}" | tr '[:upper:]' '[:lower:]')"
	fi
	_DIST_NAME="${_DIST_NAME#\"}"
	_DIST_NAME="${_DIST_NAME%\"}"
	readonly _DIST_NAME
	readonly _DIST_CODE
	readonly _DIST_VERS
}
