#!/bin/bash

set -eu

declare -r _TFTP_ROOT="/srv/tftp"
declare -r _TFTP_ADDR="192.168.1.12"

# --- memdisk -----------------------------------------------------------------
cp -a /usr/lib/syslinux/memdisk "${_TFTP_ROOT:?}/menu-bios/"

# --- syslinux ----------------------------------------------------------------
if [[ ! -d "${_TFTP_ROOT:?}/menu-bios/."  ]] \
|| [[ ! -d "${_TFTP_ROOT:?}/menu-efi64/." ]]; then
  mkdir -p "${_TFTP_ROOT:?}"/{menu-bios,menu-efi64}
  cp -a /usr/lib/syslinux/modules/bios/.         "${_TFTP_ROOT:?}"/menu-bios/
  cp -a /usr/lib/syslinux/modules/efi64/.        "${_TFTP_ROOT:?}"/menu-efi64/
  cp -a /usr/lib/PXELINUX/lpxelinux.0            "${_TFTP_ROOT:?}"/menu-bios/
  cp -a /usr/lib/SYSLINUX.EFI/efi64/syslinux.efi "${_TFTP_ROOT:?}"/menu-efi64/
fi

# -----------------------------------------------------------------------------
