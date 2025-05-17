#!/bin/bash

set -eu

declare -r _TFTP_ROOT="/srv/tftp"
declare -r _TFTP_ADDR="192.168.1.12"

# --- get ipxe module ---------------------------------------------------------
for _WEBS_ADDR in \
  https://boot.ipxe.org/undionly.kpxe \
  https://boot.ipxe.org/ipxe.efi \
  https://github.com/ipxe/wimboot/releases/latest/download/wimboot
do
  if ! wget --tries=3 --timeout=10 --quiet --output-document="${_TFTP_ROOT}/ipxe/${_WEBS_ADDR##*/}" "${_WEBS_ADDR}"; then
    printf "\033[41m%s\033[m\n" "failed to wget: ${_WEBS_ADDR}"
  fi
done

# -----------------------------------------------------------------------------
