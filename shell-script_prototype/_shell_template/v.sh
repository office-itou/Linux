#!/bin/bash

set -eu
#set -x

	declare       _VLID=""				# volume id
	declare       _WORK=""				# work variables

	if [[ -e "${1:?}" ]]; then
		_VLID="$(LANG=C file -L "$1")"
		_VLID="${_VLID#*: }"
		_WORK="${_VLID%%\'*}"
		_VLID="${_VLID#"${_WORK}"}"
		_WORK="${_VLID##*\'}"
		_VLID="${_VLID%"${_WORK}"}"
	fi
	echo -n "${_VLID}"

