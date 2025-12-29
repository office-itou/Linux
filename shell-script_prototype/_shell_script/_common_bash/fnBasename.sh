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

# -----------------------------------------------------------------------------
# descript: extension
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnExtension() {
	declare       __BASE=""				# basename
	declare       __WORK=""				# work
	__BASE="$(fnBasename "${1:-}")"
	__WORK="${__BASE#"${__BASE%.*}"}"
	__WORK="${__WORK#"${__WORK%%[^.]*}"}"
	echo -n "${__WORK:-}"
}

# -----------------------------------------------------------------------------
# descript: filename
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnFilename() {
	declare       __BASE=""				# basename
	declare       __EXTN=""				# extension
	declare       __WORK=""				# work
	__BASE="$(fnBasename "${1:-}")"
	__EXTN="$(fnExtension "${__BASE:-}")"
	__WORK="${__BASE%".${__EXTN:-}"}"
	echo -n "${__WORK:-}"
}
