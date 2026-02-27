#!/bin/bash

while read -r __PACK
do
	if ! LANG=C apt-cache --names-only search "${__PACK%:*}" | grep -E '^'"${__PACK%:*}"' '; then
		echo "failed: ${__PACK}"
	fi
done < <(cat "${1:?}" || true)

