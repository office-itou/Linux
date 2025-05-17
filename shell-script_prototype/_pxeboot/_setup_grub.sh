#!/bin/bash

set -eu

declare -r _TFTP_ROOT="/srv/tftp"
declare -r _TFTP_ADDR="192.168.1.12"

# --- memdisk -----------------------------------------------------------------
cp -a /usr/lib/syslinux/memdisk "${_TFTP_ROOT:?}/"

# --- grub-mknetdir -----------------------------------------------------------
if [[ ! -d "${_TFTP_ROOT:?}/boot/grub/x86_64-efi" ]] \
|| [[ ! -d "${_TFTP_ROOT:?}/boot/grub/i386-pc"    ]]; then
  grub-mknetdir \
    --net-directory="${_TFTP_ROOT:?}"
fi

# --- x86_64-efi --------------------------------------------------------------
grub-mkimage \
  --format=x86_64-efi \
  --output="${_TFTP_ROOT:?}"/boot/grub/bootx64.efi \
  --prefix="(tftp,${_TFTP_ADDR:?})/boot/grub" \
  net http tftp \
  chain configfile \
  play cpuid all_video font gettext gfxmenu gfxterm gfxterm_background \
  test echo minicmd progress linux relocator mmap tpm

# --- i386-pc-pxe -------------------------------------------------------------
grub-mkimage \
  --format=i386-pc-pxe \
  --output="${_TFTP_ROOT:?}"/boot/grub/pxegrub.0 \
  --prefix="(tftp,${_TFTP_ADDR:?})/boot/grub" \
  net http tftp \
  chain configfile \
  play cpuid all_video font gettext gfxmenu gfxterm gfxterm_background \
  test echo minicmd progress linux relocator mmap pxe

# -----------------------------------------------------------------------------
