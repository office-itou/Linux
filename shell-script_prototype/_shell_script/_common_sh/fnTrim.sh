# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: ltrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnLtrim() {
	echo -n "${1#"${1%%[!"${IFS}"]*}"}"	# ltrim
}

# -----------------------------------------------------------------------------
# descript: rtrim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnRtrim() {
	echo -n "${1%"${1##*[!"${IFS}"]}"}"	# rtrim
}

# -----------------------------------------------------------------------------
# descript: trim
#   input :     $1     : input
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnTrim() {
	declare       ___WORK=""
	___WORK="$(fnLtrim "$1")"
	fnRtrim "${___WORK}"
}
