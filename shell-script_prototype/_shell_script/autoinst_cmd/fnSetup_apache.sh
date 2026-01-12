# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: apache
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_apache() {
	__FUNC_NAME="fnSetup_apache"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check service -------------------------------------------------------
	__SRVC="$(fnFind_serivce 'apache2.service' 'httpd.service' | sort -V | head -n 1)"
	if [ -z "${__SRVC:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- apache2.conf / httpd.conf -------------------------------------------
	__FILE="${__SRVC##*/}"
	__PATH="${_DIRS_TGET:-}/etc/${__FILE%%.*}/sites-available/999-site.conf"
	if [ -e "${__PATH%/*}/." ]; then
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		sed -e 's%^\([ \t]\+DocumentRoot[ \t]\+\).*$%\1'"${_DIRS_HTML}"'%' \
		    "${__PATH%/*}/000-default.conf" \
		> "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			<Directory ${_DIRS_HTML}/>
			 	Options Indexes FollowSymLinks
			 	AllowOverride None
			 	Require all granted
			</Directory>
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
		# --- registration ----------------------------------------------------
		a2dissite 000-default
		a2ensite "${__PATH##*/}"
	else
		__PATH="${_DIRS_TGET:-}/etc/${__FILE%%.*}/conf.d/site.conf"
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
			<VirtualHost *:80>
			 	ServerAdmin webmaster@localhost
			 	DocumentRoot ${_DIRS_HTML}
			#	ErrorLog \${APACHE_LOG_DIR}/error.log
			#	CustomLog \${APACHE_LOG_DIR}/access.log combined
			</VirtualHost>

			<Directory ${_DIRS_HTML}/>
			 	Options Indexes FollowSymLinks
			 	AllowOverride None
			 	Require all granted
			</Directory>
_EOT_
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
