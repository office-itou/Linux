#!/bin/bash

set -eu

SRCS_DIRS="/srv/tftp/ipxe"
DEST_DIRS="${SUDO_HOME:-"${HOME:?}"}/my_document/ipxe"
mkdir -p "${DEST_DIRS:?}"/menu
cp --preserve=timestamps "${SRCS_DIRS:?}"/autoexec.ipxe               "${DEST_DIRS:?}"
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/booting.ipxe           "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu.ipxe              "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_almalinux.ipxe    "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_centos.ipxe       "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_custom_live.ipxe  "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_debian.ipxe       "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_fedora.ipxe       "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_live.ipxe         "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_miraclelinux.ipxe "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_opensuse.ipxe     "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_rockylinux.ipxe   "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_ubuntu.ipxe       "${DEST_DIRS:?}"/menu/
cp --preserve=timestamps "${SRCS_DIRS:?}"/menu/menu_windows.ipxe      "${DEST_DIRS:?}"/menu/
