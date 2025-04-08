#!/bin/bash

###############################################################################
##
##	:_PROG_TITL_:
##	  developed for debian
##
##	developer   : :_PROG_USER_:
##	release     : :_PROG_RELS_:
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	yyyy/mm/dd 000.0000 xxxxxxxxxxxxxx first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# *** initialization **********************************************************
	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	# === data section ========================================================

	# --- debug parameter -----------------------------------------------------
	declare       _DBGS_FLAG=""			# debug flag (empty: normal, else: debug)

	# --- working directory name ----------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	declare       _DIRS_TEMP=""
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")

# shellcheck disable=SC2317
function funcTrap() {
	declare -i    I=0

	for I in "${!_LIST_RMOV[@]}"
	do
		rm -rf "${_LIST_RMOV[I]:?}"
	done
}

	trap funcTrap EXIT
