# -----------------------------------------------------------------------------
# descript: main
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var : _PROG_PARM : read
#   g-var : _DIRS_TEMP : read
#   g-var : _DBGS_FLAG : write
#   g-var : _DBGS_LOGS : write
#   g-var : _DBGS_PARM : write
#   g-var : _DBGS_SIMU : write
#   g-var : _DBGS_WRAP : write
# shellcheck disable=SC2148

	declare -a    __OPTN=()
	declare       __RSLT=""
	declare -r    __SOUT="${_DIRS_TEMP}/.stdout_pipe"
	declare -r    __SERR="${_DIRS_TEMP}/.stderr_pipe"

	# --- get options ---------------------------------------------------------
	set -f -- "${_PROG_PARM[@]:-}"
	set +f
	__OPTN=()
	while [[ -n "${1:-}" ]]
	do
		case "$1" in
			--debug     | --dbg       ) _DBGS_FLAG="true"; set -x;;
			--debugout  | --dbgout    ) _DBGS_FLAG="true";;
			--debuglog  | --dbglog    ) _DBGS_LOGS="/tmp/${_PROG_NAME}.log/$(date +"%Y%m%d%H%M%S" || true).log";;
			--debugparm | --dbgparm   ) _DBGS_PARM="true";;
			--simu                    ) _DBGS_SIMU="true";;
			--wrap                    ) _DBGS_WRAP="true";;
			*                         ) __OPTN+=("${1:-}");;
		esac
		shift
	done

	# --- help ----------------------------------------------------------------
	if [[ "${#__OPTN[@]}" -le 0 ]]; then
		fnHelp
		exit 0
	fi

	# --- debug settings ------------------------------------------------------
	if set -o | grep -qE "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	# --- debug log settings --------------------------------------------------
	if [[ -n "${_DBGS_LOGS:-}" ]] \
	&& command -v mkfifo > /dev/null 2>&1; then
		fnMsgout "debuglog" "[${_DBGS_LOGS}]"
		mkdir -p "${_DBGS_LOGS%/*}"
		mkfifo "${__SOUT}" "${__SERR}"
		tee -a "${_DBGS_LOGS}" < "${__SOUT}" &
		tee -a "${_DBGS_LOGS}" < "${__SERR}" >&2 &
		exec > "${__SOUT}" 2> "${__SERR}"
	fi

	# --- main execution ------------------------------------------------------
	fnMain "__RSLT" "${__OPTN[@]}"
	read -r -a __OPTN < <(echo "${__RSLT}")
	fnDebugout_parameters

	exit 0

# *** memo ********************************************************************

# text color: \033[xxm
#	|   color    | bright | reverse|  dark  |
#	| black      |   90   |   40   |   30   |
#	| red        |   91   |   41   |   31   |
#	| green      |   92   |   42   |   32   |
#	| yellow     |   93   |   43   |   33   |
#	| blue       |   94   |   44   |   34   |
#	| purple     |   95   |   45   |   35   |
#	| light blue |   96   |   46   |   36   |
#	| white      |   97   |   47   |   37   |
# text attribute
#	| reset            | \033[m   | reset all attributes  |
#	| bold             | \033[1m  |                       |
#	| faint            | \033[2m  |                       |
#	| italic           | \033[3m  |                       |
#	| underline        | \033[4m  | set underline         |
#	| blink            | \033[5m  |                       |
#	| fast blink       | \033[6m  |                       |
#	| reverse          | \033[7m  | set reverse display   |
#	| conceal          | \033[8m  |                       |
#	| strike           | \033[9m  |                       |
#	| gothic           | \033[20m |                       |
#	| double underline | \033[21m |                       |
#	| normal           | \033[22m |                       |
#	| no italic        | \033[23m | reset underline       |
#	| no underline     | \033[24m |                       |
#	| no blink         | \033[25m |                       |
#	| no reverse       | \033[27m | reset reverse display |
# source: https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233

### eof #######################################################################
