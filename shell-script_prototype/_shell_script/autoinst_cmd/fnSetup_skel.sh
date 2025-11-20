# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: skeleton
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_skel() {
	__FUNC_NAME="fnSetup_skel"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- .bashrc -------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/skel/.bashrc"
	__CONF="${_DIRS_TGET:-}/usr/etc/skel/.bashrc"
	if [ ! -e "${__PATH}" ] && [ -e "${__CONF}" ]; then
		cp --preserve=timestamps "${__CONF}" "${__PATH}"
	fi
	if [ -e "${__PATH}" ]; then
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			# --- measures against garbled characters ---
			case "${TERM}" in
			    linux ) export LANG=C;;
			    *     )              ;;
			esac
			# --- user custom ---
			alias vi='vim'
			alias view='vim'
			alias diff='diff --color=auto'
			alias ip='ip -color=auto'
			alias ls='ls --color=auto'
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- .bash_history -------------------------------------------------------
	__PATH="$(fnFind_command 'apt-get' | sort | head -n 1)"
	if [ -n "${__PATH:-}" ]; then
		__PATH="${_DIRS_TGET:-}/etc/skel/.bash_history"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			sudo bash -c 'apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade'
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- .vimrc --------------------------------------------------------------
	__PATH="$(fnFind_command 'vim' | sort | head -n 1)"
	if [ -n "${__PATH:-}" ]; then
		__PATH="${_DIRS_TGET:-}/etc/skel/.vimrc"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			set number              " Print the line number in front of each line.
			set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
			set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
			set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
			set nowrap              " This option changes how text is displayed.
			set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
			set laststatus=2        " The value of this option influences when the last window will have a status line always.
			set mouse-=a            " Disable mouse usage
			syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- .curlrc -------------------------------------------------------------
	__PATH="$(fnFind_command 'curl' | sort | head -n 1)"
	if [ -n "${__PATH:-}" ]; then
		__PATH="${_DIRS_TGET:-}/etc/skel/.curlrc"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			location
			progress-bar
			remote-time
			show-error
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- distribute to existing users ----------------------------------------
	for __DIRS in "${_DIRS_TGET:-}"/root \
	              "${_DIRS_TGET:-}"/home/*
	do
		if [ ! -e "${__DIRS}/." ]; then
			continue
		fi
		for __FILE in "${_DIRS_TGET:-}/etc/skel/.bashrc"       \
		              "${_DIRS_TGET:-}/etc/skel/.bash_history" \
		              "${_DIRS_TGET:-}/etc/skel/.vimrc"        \
		              "${_DIRS_TGET:-}/etc/skel/.curlrc"
		do
			if [ ! -e "${__FILE}" ]; then
				continue
			fi
			__PATH="${__DIRS}/${__FILE#*/etc/skel/}"
			mkdir -p "${__PATH%/*}"
			cp --preserve=timestamps "${__FILE}" "${__PATH}"
			chown "${__DIRS##*/}": "${__PATH}"
			fnDbgdump "${__PATH}"				# debugout
			fnFile_backup "${__PATH}" "init"	# backup initial file
		done
	done

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
