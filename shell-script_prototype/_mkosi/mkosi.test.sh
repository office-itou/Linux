#!/bin/bash

set -eu

declare -r    _PROG_NAME="${0##*/}"
declare -r    _FUNC_NAME="main"
printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- start   : [${_FUNC_NAME}] ---"
printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "distribution: ${DISTRIBUTION:-}"

if command -v systemd-detect-virt > /dev/null 2>&1; then
	__VERT="$(systemd-detect-virt || true)"
	printf "\033[m${_PROG_NAME}: \033[43m%s\033[m\n" " virtualized: ${__VERT:-}"
fi

printf "%s=[%s]\n" "ARCHITECTURE             " "${ARCHITECTURE-}"
printf "%s=[%s]\n" "ARTIFACTDIR              " "${ARTIFACTDIR-}"
printf "%s=[%s]\n" "BUILDDIR                 " "${BUILDDIR-}"
printf "%s=[%s]\n" "BUILDROOT                " "${BUILDROOT-}"
printf "%s=[%s]\n" "CACHED                   " "${CACHED-}"
printf "%s=[%s]\n" "CHROOT_BUILDDIR          " "${CHROOT_BUILDDIR-}"
printf "%s=[%s]\n" "CHROOT_DESTDIR           " "${CHROOT_DESTDIR-}"
printf "%s=[%s]\n" "CHROOT_OUTPUTDIR         " "${CHROOT_OUTPUTDIR-}"
printf "%s=[%s]\n" "CHROOT_SCRIPT            " "${CHROOT_SCRIPT-}"
printf "%s=[%s]\n" "CHROOT_SRCDIR            " "${CHROOT_SRCDIR-}"
printf "%s=[%s]\n" "DESTDIR                  " "${DESTDIR-}"
printf "%s=[%s]\n" "DISTRIBUTION             " "${DISTRIBUTION-}"
printf "%s=[%s]\n" "DISTRIBUTION_ARCHITECTURE" "${DISTRIBUTION_ARCHITECTURE:-}"
printf "%s=[%s]\n" "IMAGE_ID                 " "${IMAGE_ID-}"
printf "%s=[%s]\n" "IMAGE_VERSION            " "${IMAGE_VERSION-}"
printf "%s=[%s]\n" "MKOSI_CONFIG             " "${MKOSI_CONFIG-}"
printf "%s=[%s]\n" "MKOSI_GID                " "${MKOSI_GID-}"
printf "%s=[%s]\n" "MKOSI_UID                " "${MKOSI_UID-}"
printf "%s=[%s]\n" "OUTPUTDIR                " "${OUTPUTDIR-}"
printf "%s=[%s]\n" "PACKAGEDIR               " "${PACKAGEDIR-}"
printf "%s=[%s]\n" "PROFILES                 " "${PROFILES-}"
printf "%s=[%s]\n" "QEMU_ARCHITECTURE        " "${QEMU_ARCHITECTURE-}"
printf "%s=[%s]\n" "RELEASE                  " "${RELEASE-}"
printf "%s=[%s]\n" "SOURCE_DATE_EPOCH        " "${SOURCE_DATE_EPOCH-}"
printf "%s=[%s]\n" "SRCDIR                   " "${SRCDIR-}"
printf "%s=[%s]\n" "WITH_DOCS                " "${WITH_DOCS-}"
printf "%s=[%s]\n" "WITH_NETWORK             " "${WITH_NETWORK-}"
printf "%s=[%s]\n" "WITH_TESTS               " "${WITH_TESTS-}"

export -p

if [ "${container:-}" != "mkosi" ] && command -v mkosi-chroot > /dev/null 2>&1; then
	mkosi-chroot "${CHROOT_SCRIPT:-}" "$@"
fi

/bin/bash

printf "\033[m${_PROG_NAME}: \033[92m%s\033[m\n" "--- complete: [${_FUNC_NAME}] ---"

#read -r -p "Press any key to exit..."

exit 0
