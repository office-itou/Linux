#!/bin/bash

	declare -r    _SHEL_TOPS="${0%/*}"

	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnGlobal_early.sh

# *** function section (common functions) *************************************

	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnDebugout.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnDebugout_parameters.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnDebugout_list.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnDebugout_allparameters.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnMsgout.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnTrap.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnExec_backup.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnGet_conf_data.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnSet_conf_data.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnGet_media_data.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnPut_media_data.sh
	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnSet_media_data.sh

	# === main ================================================================

function fnMain() {
#	for __NAME in "${!_DIRS_@}" "${!_FILE_@}"
#	do
#		__NAME="${__NAME#\'}"
#		__NAME="${__NAME%\'}"
#		__VALU="${!__NAME:-}"
#		printf "%s=[%s]\n" "${__NAME:-}" "${__VALU:-}"
#	done

#	echo "-----------------------------------------------------------------------------------------------------------------------"

#	fnDebug_allparameters

	echo "-----------------------------------------------------------------------------------------------------------------------"

#	_DBGS_PARM="true"
#	_DBGS_FLAG="true"
	_DBGS_WRAP="true"

	fnGet_conf_data "${_PATH_CONF}"
	fnSet_conf_data
#	fnDebugout_parameters
#	fnDebug_allparameters
	echo "-----------------------------------------------------------------------------------------------------------------------"
	fnGet_media_data "${_PATH_MDIA}"
	fnDebugout_list "${_LIST_MDIA[@]}"
	fnSet_media_data
	echo "-----------------------------------------------------------------------------------------------------------------------"
	fnDebugout_list "${_LIST_MDIA[@]}" 2> a.txt
	fnPut_media_data "${PWD}/test.dat"
	fnDebugout_list "${_LIST_MDIA[@]}" 2> b.txt
	echo "-----------------------------------------------------------------------------------------------------------------------"
}

	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/template/fnHelp.sh

	# shellcheck source=/dev/null
	source "${_SHEL_TOPS:?}"/common/fnGlobal_late.sh
