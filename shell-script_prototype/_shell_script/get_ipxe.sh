#!/bin/bash

set -eu

wget https://boot.ipxe.org/undionly.kpxe
wget https://boot.ipxe.org/ipxe.efi
wget https://github.com/ipxe/wimboot/releases/latest/download/wimboot
