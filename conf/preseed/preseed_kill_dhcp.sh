#!/bin/sh

### initialization ############################################################
#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

	trap 'exit 1' 1 2 3 15

### Main ######################################################################
	/bin/kill-all-dhcp
	/bin/netcfg
### Termination ###############################################################
	exit 0
### EOF #######################################################################
