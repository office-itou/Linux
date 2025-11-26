#!/bin/bash

set -eu

# shellcheck source=/dev/null
source ./custom_cmd/fnGlobal_variables.sh
# shellcheck source=/dev/null
source ./custom_cmd/fnGlobal_common.sh
# shellcheck source=/dev/null
source ./_common_bash/fnMsgout.sh
# shellcheck source=/dev/null
source ./custom_cmd/fnDbgparameters_all.sh
# shellcheck source=/dev/null
source ./custom_cmd/fnDbgparameters.sh
# shellcheck source=/dev/null
source ./custom_cmd/fnList_conf_Get.sh
# shellcheck source=/dev/null
source ./custom_cmd/fnList_conf_Dec.sh
# shellcheck source=/dev/null
source ./custom_cmd/fnList_mdia_Get.sh
# shellcheck source=/dev/null
source ./custom_cmd/fnList_mdia_Dec.sh
# shellcheck source=/dev/null
source ./custom_cmd/fnList_mdia_Enc.sh

_PATH_CONF="./common.cfg"
#_PATH_CONF="/srv/user/share/conf/_data/common.cfg"			# common configuration file
_PATH_DIST="/srv/user/share/conf/_data/distribution.dat"	# distribution data file
_PATH_MDIA="/srv/user/share/conf/_data/media.dat"			# media data file
_PATH_DSTP=""												# debstrap data file

fnList_conf_Get "${_PATH_CONF:?}"
fnList_conf_Dec
#printf "%s/n" "${_LIST_CONF[@]:-}" | cut -c -120
#fnDbgparameters_all

fnList_mdia_Get "${_PATH_MDIA:?}"
printf "%s\n" "${_LIST_MDIA[@]:-}" > ./_mdia_src.txt
fnList_mdia_Dec
printf "%s\n" "${_LIST_MDIA[@]:-}" > ./_mdia_dec.txt
fnList_mdia_Enc
printf "%s\n" "${_LIST_MDIA[@]:-}" > ./_mdia_enc.txt

#fnDbgparameters_all
