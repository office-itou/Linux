# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get auto-installation configuration file
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TGET : read
#   g-var : _DIRS_SAMP : read
#   g-var : _DIRS_INIT : read
#   g-var : _DIRS_ORIG : read
# shellcheck disable=SC2148,SC2317,SC2329
# --- file backup -------------------------------------------------------------
fnGet_conf_file() {
	__FUNC_NAME="fnGet_conf_file"
	fnMsgout "start" "[${__FUNC_NAME}]"

	__LINE=""
	__PATH=""
	__DIRS=""

	__DIRS="${_FILE_SEED%/user-data}"
	__DIRS="${__DIRS%/*/*}"
	__DIRS="${__DIRS%%/}"
	__DIRS="${__DIRS}/script"

	for __LINE in \
		"${__DIRS}/${_FILE_ERLY}" \
		"${__DIRS}/${_FILE_LATE}" \
		"${__DIRS}/${_FILE_PART}" \
		"${__DIRS}/${_FILE_RUNS}" \
		          "${_FILE_SEED}"
	do
		case "${__LINE}" in
			http:*|https:*|ftp:*|tftp:*)
				fnMsgout "download" "${__LINE}"
				__PATH="$(fnFind_command 'wget' | sort | head -n 1)"
				if [ -n "${__PATH:-}" ]; then
					if ! wget \
					  --tries=3 \
					  --timeout=10 \
					  --quiet \
					  --continue \
					  --show-progress \
					  --progress=bar \
					  --output-document "${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}" \
					  "${__LINE}" \
					; then
						fnMsgout "failed" "${__LINE}"
						__PATH="${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
						rm -rf "${__PATH:?}"
						continue
					fi
				else
					if ! curl \
					  --location \
					  --http1.1 \
					  --no-progress-bar \
					  --remote-time \
					  --show-error \
					  --fail \
					  --retry-max-time 3 \
					  --retry 3 \
					  --connect-timeout 60 \
					  --progress-bar \
					  --continue-at - \
					  --create-dirs \
					  --output-dir "${_DIRS_TGET:-}${_DIRS_INST}" \
					  --output "${__LINE##*/}" \
					  "${__LINE}" \
					; then
						fnMsgout "failed" "${__LINE}"
						__PATH="${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
						rm -rf "${__PATH:?}"
						continue
					fi
				fi
				;;
			file:*|/*)
				fnMsgout "copy" "${__LINE}"
				if ! cp --preserve=timestamps "${__LINE#*:*//}" "${_DIRS_TGET:-}${_DIRS_INST}/"; then
					fnMsgout "failed" "${__LINE}"
					__PATH="${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
					rm -rf "${__PATH:?}"
					continue
				fi
				;;
			*) continue;;
		esac
		mkdir -p "${_DIRS_TGET:-}${_DIRS_INST%.*}/"
		cp ${_OPTN_COPY:+${_OPTN_COPY}} "${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}" "${_DIRS_TGET:-}${_DIRS_INST%.*}/"
		if [ "${__LINE##*/}" != "${_FILE_SEED##*/}" ] && [ -e "${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}" ]; then
			chmod +x "${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
			chmod +x "${_DIRS_TGET:-}${_DIRS_INST%.*}/${__LINE##*/}"
		fi
		fnMsgout "success" "${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
	done

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
