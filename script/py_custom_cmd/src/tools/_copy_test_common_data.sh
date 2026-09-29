#!/bin/bash

set -eu

SRCS_DIRS="/srv/user/share/conf/_data"
DEST_DIRS="${SUDO_HOME:-"${HOME:?}"}/my_document/_data"
mkdir -p "${DEST_DIRS:?}"
cp --preserve=timestamps "${SRCS_DIRS:?}"/common.cfg            "${DEST_DIRS:?}"
cp --preserve=timestamps "${SRCS_DIRS:?}"/distribution.dat      "${DEST_DIRS:?}"
cp --preserve=timestamps "${SRCS_DIRS:?}"/distribution.dat.json "${DEST_DIRS:?}"
cp --preserve=timestamps "${SRCS_DIRS:?}"/media.dat             "${DEST_DIRS:?}"
cp --preserve=timestamps "${SRCS_DIRS:?}"/media.dat.json        "${DEST_DIRS:?}"
