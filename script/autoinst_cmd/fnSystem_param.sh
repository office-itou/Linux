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
	if [ -e "${_DIRS_TGET:-}"/etc/os-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/os-release"
		_DIST_NAME="$(sed -ne '/^ID=/      s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
		_DIST_VERS="$(sed -ne '/^VERSION=/ s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
		_DIST_CODE="$(sed -ne '/^VERSION=/ s/^[^=]\+="*.*(\(.\+\)).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
	elif [ -e "${_DIRS_TGET:-}"/etc/lsb-release ]; then
		___PATH="${_DIRS_TGET:-}/etc/lsb-release"
		_DIST_NAME="$(sed -ne '/^DISTRIB_ID=/      s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
		_DIST_VERS="$(sed -ne '/^DISTRIB_RELEASE=/ s/^[^=]\+="*\([^ "]\+\).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
		_DIST_CODE="$(sed -ne '/^DISTRIB_RELEASE=/ s/^[^=]\+="*.*(\(.\+\)).*"*/\1/p' "${___PATH:-}" | awk '{print tolower($0);}')"
	fi
	readonly _DIST_NAME
	readonly _DIST_CODE
	readonly _DIST_VERS
	unset ___PATH
}
