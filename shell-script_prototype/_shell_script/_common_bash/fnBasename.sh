# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: dirname
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnDirname() {
	declare       __WORK=""				# work
	__WORK="${1%"${1##*/}"}"
	[[ "${__WORK:-}" != "/" ]] && __WORK="${__WORK%"${__WORK##*[^/]}"}"
	echo -n "${__WORK:-}"
}

# -----------------------------------------------------------------------------
# descript: basename
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnBasename() {
	declare       __WORK=""				# work
	__WORK="${1#"${1%/*}"}"
	__WORK="${__WORK:-"${1:-}"}"
	__WORK="${__WORK#"${__WORK%%[^/]*}"}"
	echo -n "${__WORK:-}"
}
