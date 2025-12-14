#!/bin/bash

set -eu

source ./_common_bash/fnGetWebdata.sh

for _URLS in \
	"https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso" \
	"https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/minis.iso" \
	"https://releases.ubuntu.com/25.10/ubuntu-25.10[0-9.]*-live-server-amd64.iso" \
	"https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso"
do
	fnGetWebdata "${_URLS}"
	echo ""
done
