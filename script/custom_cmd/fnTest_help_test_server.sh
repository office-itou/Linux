# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: help
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' 1>&2 || true
		usage: [sudo] ${_PROG_PATH:-"$0"} (options) [command]
		  commands:
		    -h|--help   : this message output
		    -P|--DBGP   : debug output for internal global variables
		    -T|--TREE   : debug output in a directory tree-like format
		  options:
		    -D|--debug   |--dbg     : debug output with code
		    -O|--debugout|--dbgout  : debug output without code
_EOT_
	exit 0
}
