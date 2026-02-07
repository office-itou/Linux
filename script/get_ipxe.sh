#!/bin/bash

set -eu

# --- ipxe --------------------------------------------------------------------
mkdir ipxe
cd ipxe
wget https://github.com/ipxe/wimboot/releases/latest/download/wimboot
wget https://boot.ipxe.org/x86_64-efi/ipxe.efi
wget https://boot.ipxe.org/x86_64-efi/snponly.efi
wget https://boot.ipxe.org/x86_64-pcbios/ipxe.lkrn
wget https://boot.ipxe.org/x86_64-pcbios/ipxe.pxe
wget https://boot.ipxe.org/x86_64-pcbios/undionly.kpxe
sudo cp --preserve=timestamps * /srv/tftp/ipxe/
