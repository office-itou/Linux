#!/bin/bash

set -eu

declare -r    _PROG_NAME="${0##*/}"
declare -r    _FUNC_NAME="main"
printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${_FUNC_NAME}] ---"

#if [ "${container:-}" != "mkosi" ]; then
#	exec mkosi-chroot "${CHROOT_SCRIPT:-}" "$@"
#fi

printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${_FUNC_NAME}] ---"
