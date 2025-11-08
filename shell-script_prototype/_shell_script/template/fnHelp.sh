# -----------------------------------------------------------------------------
# descript: help
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_PATH : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' 1>&2 || true

		usage: [sudo] ${_PROG_PATH:-"$0"} [command (options)]

		  options:
		    --debug     | --dbg     : debug output with code
		    --debugout  | --dbgout  : debug output without code
		    --debuglog  | --dbglog  : debug output to a log file
		    --debugparm | --dbgparm : debug output for variables in functions
		    --simu                  : (unused)
		    --wrap                  : debug output wrapping

		  commands:
		    help                    : this message output
		    testparm                : debug output of all variables in list format

_EOT_
}
