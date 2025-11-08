# -----------------------------------------------------------------------------
# descript: get common configuration data
#   input :            : unused
#   output:   stdout   : result
#   return:            : unused
#   g-var : PWD        : read
#   g-var : SUDO_HOME  : read
#   g-var : HOME       : read
#   g-var : _SUDO_HOME : read
#   g-var : _DIRS_CURR : read
#   g-var : _DIRS_CONF : read
#   g-var : _FILE_CONF : read
#   g-var : _FILE_DIST : read
#   g-var : _FILE_MDIA : read
#   g-var : _FILE_DSTP : read
#   g-var : _PATH_CONF : write
#   g-var : _PATH_DIST : write
#   g-var : _PATH_MDIA : write
#   g-var : _PATH_DSTP : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnFind_config() {
	declare -a    __DIRS=()				# directory
	declare       __CONF=""				# common configuration file
	declare       __DIST=""				# distribution data file
	declare       __MDIA=""				# media data file
	declare       __DSTP=""				# debstrap data file
	# --- set search directory ------------------------------------------------
	__DIRS=("${_DIRS_CURR:-"${PWD}"}" "${_SUDO_HOME:-"${SUDO_HOME:-"${HOME:-}"}"}")
	{ [[ -n "${_DIRS_CONF:-}" ]] && [[ -e "${_DIRS_CONF}/." ]]; } && __DIRS+=("${_DIRS_CONF}")
	# --- file search ---------------------------------------------------------
	__CONF="$(find "${__DIRS[@]}" -maxdepth 1 -name "${_FILE_CONF:-common.cfg}"       -size +0 -print -quit)"
	__DIST="$(find "${__DIRS[@]}" -maxdepth 1 -name "${_FILE_DIST:-distribution.dat}" -size +0 -print -quit)"
	__MDIA="$(find "${__DIRS[@]}" -maxdepth 1 -name "${_FILE_MDIA:-media.dat}"        -size +0 -print -quit)"
	__DSTP="$(find "${__DIRS[@]}" -maxdepth 1 -name "${_FILE_DSTP:-debstrap.dat}"     -size +0 -print -quit)"
	# --- result --------------------------------------------------------------
	printf "%s %s %s %s" "${__CONF:-"-"}" "${__DIST:-"-"}" "${__MDIA:-"-"}" "${__DSTP:-"-"}"
}
