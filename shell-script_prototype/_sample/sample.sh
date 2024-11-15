#!/bin/sh

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
#	set -o ignoreeof					# Do not exit with Ctrl+D
#	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	_DIRS_SKEL="./etc/skel"
	_DIRS_XDGS="/etc/xdg"

	_FILE_PATH="openbox/lxde-rc.xml"
	_XDGS_PATH="${_DIRS_XDGS}/openbox/LXDE/rc.xml"
	_CONF_PATH="${_DIRS_SKEL}/.config/${_FILE_PATH}"
	if [ -f "${_XDGS_PATH}" ]; then
		mkdir -p "${_CONF_PATH%/*}"
		cp "${_XDGS_PATH}" "${_CONF_PATH}"
		# --- edit xml file ---------------------------------------------------
		_NAME_SPCE="http://openbox.org/3.4/rc"
		_XMLS_PATH="//N:openbox_config/N:theme"
		# --- update ------------------------------------------------------------------
		COUNT="$(xmlstarlet sel -N N="${_NAME_SPCE}" -t -m "${_XMLS_PATH}" -v "count(N:font)" "${_CONF_PATH}")"
		: $((I=1))
		while [ $((I<=COUNT)) -ne 0 ]
		do
			_NAME="$(xmlstarlet sel   -N N="${_NAME_SPCE}" -t -m "${_XMLS_PATH}/N:font[${I}]"        -v "N:name"  "${_CONF_PATH}" |  sed -e 's/^\(.\)\(.*\)$/\U\1\L\2/g' || true)"
		#	_SIZE="$(xmlstarlet sel   -N N="${_NAME_SPCE}" -t -m "${_XMLS_PATH}/N:font[${I}]"        -v "N:size"  "${_CONF_PATH}" || true)"
			         xmlstarlet ed -L -N N="${_NAME_SPCE}"    -u "${_XMLS_PATH}/N:font[${I}]/N:name" -v "${_NAME}"                        \
			                                                  -u "${_XMLS_PATH}/N:font[${I}]/N:size" -v "9"       "${_CONF_PATH}" || true
			I=$((I+1))
		done
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -u "${_XMLS_PATH}/N:name" -v "Clearlooks-3.4" "${_CONF_PATH}" || true
		# --- append ------------------------------------------------------------------
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -s "${_XMLS_PATH}"                -t "elem" -n "font"                                "${_CONF_PATH}" || true
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -s "${_XMLS_PATH}/N:font[last()]" -t "attr" -n "place"  -v "ActiveOnScreenDisplay"   \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "name"   -v "Sans"                    \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "size"   -v "9"                       \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "weight" -v "Normal"                  \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "slant"  -v "Normal"                  "${_CONF_PATH}" || true
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -s "${_XMLS_PATH}"                -t "elem" -n "font"                                "${_CONF_PATH}" || true
		xmlstarlet ed -L -N N="${_NAME_SPCE}" -s "${_XMLS_PATH}/N:font[last()]" -t "attr" -n "place"  -v "InactiveOnScreenDisplay" \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "name"   -v "Sans"                    \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "size"   -v "9"                       \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "weight" -v "Normal"                  \
		                                      -s "${_XMLS_PATH}/N:font[last()]" -t "elem" -n "slant"  -v "Normal"                  "${_CONF_PATH}" || true
	fi

	if [ -f "${_CONF_PATH}" ]; then
		bash -c 'diff --color=auto <(xmlstarlet fo '"${_XDGS_PATH}"') <(xmlstarlet fo '"${_CONF_PATH}"')'
	fi

	exit 0
