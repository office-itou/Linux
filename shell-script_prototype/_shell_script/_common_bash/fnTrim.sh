# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: ltrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnLtrim() {
	echo -n "${1#"${1%%[!"${IFS}"]*}"}"	# ltrim
}

# -----------------------------------------------------------------------------
# descript: rtrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnRtrim() {
	echo -n "${1%"${1##*[!"${IFS}"]}"}"	# rtrim
}

# -----------------------------------------------------------------------------
# descript: trim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnTrim() {
	declare       __WORK=""
	__WORK="$(fnLtrim "$1")"
	fnRtrim "${__WORK}"
}
