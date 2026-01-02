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
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

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
				fnMsgout "${_PROG_NAME:-}" "download" "${__LINE}"
				__PATH="$(fnFind_command 'wget' | sort -V | head -n 1)"
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
						fnMsgout "${_PROG_NAME:-}" "failed" "${__LINE}"
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
						fnMsgout "${_PROG_NAME:-}" "failed" "${__LINE}"
						__PATH="${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
						rm -rf "${__PATH:?}"
						continue
					fi
				fi
				;;
			hd:sr0:*|cdrom|cdrom:*)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
				if ! cp -p "/mnt/install/repo/${__LINE#*:/}" "${_DIRS_TGET:-}${_DIRS_INST}/"; then
					fnMsgout "${_PROG_NAME:-}" "failed" "${__LINE}"
					__PATH="${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
					rm -rf "${__PATH:?}"
					continue
				fi
				;;
			hd:*|dvd:*|cd:*)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
				if [ -e /var/log/YaST2/y2start.log ]; then
					while read -r __READ
					do
						case "${__READ:-}" in
						*AutoYaST=*)
							__SEED="${__READ%%=*}"
							__SEED="${__READ#"${__SEED:-}="}"
							__SEED="${__SEED#\"}"
							__SEED="${__SEED%\"}"
							__SEED="${__SEED#*://}"
							;;
						*autoyast=*)
							__YAST="${__READ%%=*}"
							__YAST="${__READ#"${__YAST:-}="}"
							__YAST="${__YAST#\"}"
							__YAST="${__YAST%\"}"
							__YAST="${__YAST#*:/}"
							;;
						*) ;;
						esac
					done < /var/log/YaST2/y2start.log
					__DEVS="${__SEED%"/${__YAST:-}"}"
					if [ -n "${__DEVS:-}" ] && [ -e "/dev/${__DEVS}" ]; then
						mkdir -p /media
						mount -r "/dev/${__DEVS}" /media
						if ! cp -p "/media/${__LINE#*:/}" "${_DIRS_TGET:-}${_DIRS_INST}/"; then
							fnMsgout "${_PROG_NAME:-}" "failed" "${__LINE}"
							__PATH="${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
							rm -rf "${__PATH:?}"
#							continue
						fi
						umount /media
					fi
				fi
				;;
			device:*)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
#				_PATH_DEVS="${_PATH_SEED#device://}"
#				_PATH_DEVS="${_PATH_DEVS%/*}"
#				_PATH_SEED="${_PATH_SEED#*"${_PATH_DEVS}"}"
				;;
			label:*)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
				;;
			usb:*)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
				;;
			smb:*)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
				;;
			nfs:*)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
				;;
			hmc)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
				;;
			file:*|/*)
				fnMsgout "${_PROG_NAME:-}" "copy" "${__LINE}"
				if ! cp -p "${__LINE#*:*//}" "${_DIRS_TGET:-}${_DIRS_INST}/"; then
					fnMsgout "${_PROG_NAME:-}" "failed" "${__LINE}"
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
		fnMsgout "${_PROG_NAME:-}" "success" "${_DIRS_TGET:-}${_DIRS_INST}/${__LINE##*/}"
	done
	unset __LINE __PATH __DIRS

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
