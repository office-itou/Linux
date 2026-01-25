# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: samba
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_samba() {
	__FUNC_NAME="fnSetup_samba"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v pdbedit > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- check service -------------------------------------------------------
	__SMBD="$(fnFind_serivce 'smbd.service' 'smb.service' | sort -V | head -n 1)"
	__NMBD="$(fnFind_serivce 'nmbd.service' 'nmb.service' | sort -V | head -n 1)"
	if [ -z "${__SMBD:-}" ] || [ -z "${__NMBD:-}" ]; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- create passdb.tdb ---------------------------------------------------
	pdbedit -L > /dev/null 2>&1 || true
	# --- nsswitch.conf -------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/nsswitch.conf"
	if [ -e "${__PATH}" ]; then
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		if [ ! -h "${__PATH}" ]; then
			cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		fi
		sed -i "${__PATH}"                \
		    -e '/^hosts:[ \t]\+/       {' \
		    -e 's/\(files\).*$/\1/'       \
		    -e 's/$/ '"${_SAMB_NSSW}"'/}' \
			-e '/^\(passwd\|group\|shadow\|gshadow\):[ \t]\+/ s/[ \t]\+winbind//'
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- smb.conf ------------------------------------------------------------
	# https://www.samba.gr.jp/project/translation/current/htmldocs/manpages/smb.conf.5.html
	__PATH="${_DIRS_TGET:-}/etc/samba/smb.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	__CONF="${_DIRS_TGET:-}/tmp/${__PATH##*/}.work"
	__WORK="${_NICS_IPV4:+"${_NICS_IPV4%.*}.0\/${_NICS_BIT4:-"${_NICS_MASK:-"24"}"}"}"
	__WORK="${__WORK:-}${__WORK:+" "}fe80::\/10"
	# <-- global settings section -------------------------------------------->
	# allow insecure wide links = Yes
	testparm -s -v                                                                   | \
	sed -ne '/^\[global\]$/,/^[ \t]*$/                                              {' \
	    -e  '/^[ \t]*acl check permissions[ \t]*=/        s/^/#/'                      \
	    -e  '/^[ \t]*allocation roundup size[ \t]*=/      s/^/#/'                      \
	    -e  '/^[ \t]*allow nt4 crypto[ \t]*=/             s/^/#/'                      \
	    -e  '/^[ \t]*blocking locks[ \t]*=/               s/^/#/'                      \
	    -e  '/^[ \t]*client NTLMv2 auth[ \t]*=/           s/^/#/'                      \
	    -e  '/^[ \t]*client lanman auth[ \t]*=/           s/^/#/'                      \
	    -e  '/^[ \t]*client plaintext auth[ \t]*=/        s/^/#/'                      \
	    -e  '/^[ \t]*client schannel[ \t]*=/              s/^/#/'                      \
	    -e  '/^[ \t]*client use spnego principal[ \t]*=/  s/^/#/'                      \
	    -e  '/^[ \t]*client use spnego[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*copy[ \t]*=/                         s/^/#/'                      \
	    -e  '/^[ \t]*domain logons[ \t]*=/                s/^/#/'                      \
	    -e  '/^[ \t]*enable privileges[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*encrypt passwords[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*idmap backend[ \t]*=/                s/^/#/'                      \
	    -e  '/^[ \t]*idmap gid[ \t]*=/                    s/^/#/'                      \
	    -e  '/^[ \t]*idmap uid[ \t]*=/                    s/^/#/'                      \
	    -e  '/^[ \t]*lanman auth[ \t]*=/                  s/^/#/'                      \
	    -e  '/^[ \t]*lsa over netlogon[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*nbt client socket address[ \t]*=/    s/^/#/'                      \
	    -e  '/^[ \t]*null passwords[ \t]*=/               s/^/#/'                      \
	    -e  '/^[ \t]*raw NTLMv2 auth[ \t]*=/              s/^/#/'                      \
	    -e  '/^[ \t]*reject md5 clients[ \t]*=/           s/^/#/'                      \
	    -e  '/^[ \t]*server schannel require seal[ \t]*=/ s/^/#/'                      \
	    -e  '/^[ \t]*server schannel[ \t]*=/              s/^/#/'                      \
	    -e  '/^[ \t]*syslog only[ \t]*=/                  s/^/#/'                      \
	    -e  '/^[ \t]*syslog[ \t]*=/                       s/^/#/'                      \
	    -e  '/^[ \t]*unicode[ \t]*=/                      s/^/#/'                      \
	    -e  '/^[ \t]*winbind separator[ \t]*=/            s/^/#/'                      \
	    -e  '/^[ \t]*allow insecure wide links[ \t]*=/    s/=.*$/= Yes/'               \
	    -e  '/^[ \t]*dos charset[ \t]*=/                  s/=.*$/= CP932/'             \
	    -e  '/^[ \t]*unix password sync[ \t]*=/           s/=.*$/= No/'                \
	    -e  '/^[ \t]*netbios name[ \t]*=/                 s/=.*$/= '"${_NICS_HOST}"'/' \
	    -e  '/^[ \t]*workgroup[ \t]*=/                    s/=.*$/= '"${_NICS_WGRP}"'/' \
	    -e  '/^[ \t]*bind interfaces only[ \t]*=/                                   {' \
	    -e  '                                             s/^/#/'                      \
	    -e  '                                             s/=.*$/= yes/'               \
	    -e  '                                                                       }' \
	    -e  '/^[ \t]*interfaces[ \t]*=/                                             {' \
	    -e  '                                             s/^/#/'                      \
	    -e  '                                             s/=.*$/= '"${_NICS_NAME}"'/' \
	    -e  '                                                                       }' \
	    -e  '/^[ \t]*hosts allow[ \t]*=/                                            {' \
	    -e  '                                             s/^/#/'                      \
	    -e  '                                             s/=.*$/= '"${__WORK}"'/'     \
	    -e  '                                                                       }' \
	    -e  '/^[ \t]*hosts deny[ \t]*=/                                             {' \
	    -e  '                                             s/^/#/'                      \
	    -e  '                                             s/=.*$/= ALL/'               \
	    -e  '                                                                       }' \
	    -e  'p                                                                      }' \
	> "${__CONF}" 2> /dev/null
	[ -z "${_NICS_HOST##-}" ] && sed -i "${__CONF}" -e '/^[ \t]*netbios name[ \t]*=/d'
	[ -z "${_NICS_WGRP##-}" ] && sed -i "${__CONF}" -e '/^[ \t]*workgroup[ \t]*=/d'
	[ -z "${_NICS_NAME##-}" ] && sed -i "${__CONF}" -e '/^[ \t]*interfaces[ \t]*=/d'
	# <-- shared settings section -------------------------------------------->
	# wide links = Yes
	# tree
	#	/srv/samba/
	#	|-- adm
	#	|   |-- commands
	#	|   `-- profiles
	#	|-- pub
	#	|   |-- _license
	#	|   |-- contents
	#	|   |   |-- disc
	#	|   |   `-- dlna
	#	|   |       |-- movies
	#	|   |       |-- others
	#	|   |       |-- photos
	#	|   |       `-- sounds
	#	|   |-- hardware
	#	|   |-- resource
	#	|   |   |-- image
	#	|   |   |   |-- linux
	#	|   |   |   `-- windows
	#	|   |   `-- source
	#	|   |       `-- git
	#	|   `-- software
	#	`-- usr
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__CONF}"
		[homes]
		    browseable = No
		    comment = Home Directories
		    create mask = 0700
		    directory mask = 2700
		    valid users = %S
		    write list = @${_SAMB_GRUP}
		[printers]
		    browseable = No
		    comment = All Printers
		    create mask = 0700
		    path = /var/tmp
		    printable = Yes
		[print$]
		    comment = Printer Drivers
		    path = /var/lib/samba/printers
		[adm]
		    browseable = No
		    comment = Administrator directories
		    create mask = 0660
		    directory mask = 2770
		    force group = ${_SAMB_GRUP}
		    force user = ${_SAMB_USER}
		    path = ${_DIRS_SAMB}/adm
		    valid users = @${_SAMB_GRUP}
		    write list = @${_SAMB_GADM}
		[pub]
		    browseable = Yes
		    comment = Public directories
		    create mask = 0660
		    directory mask = 2770
		    force group = ${_SAMB_GRUP}
		    force user = ${_SAMB_USER}
		    path = ${_DIRS_SAMB}/pub
		    valid users = @${_SAMB_GRUP}
		    write list = @${_SAMB_GADM}
		[usr]
		    browseable = No
		    comment = User directories
		    create mask = 0660
		    directory mask = 2770
		    force group = ${_SAMB_GRUP}
		    force user = ${_SAMB_USER}
		    path = ${_DIRS_SAMB}/usr
		    valid users = @${_SAMB_GADM}
		    write list = @${_SAMB_GADM}
		[share]
		    browseable = No
		    comment = Shared directories
		    create mask = 0660
		    directory mask = 2770
		    force group = ${_SAMB_GRUP}
		    force user = ${_SAMB_USER}
		    path = ${_DIRS_SAMB}
		    valid users = @${_SAMB_GADM}
		    write list = @${_SAMB_GADM}
		[dlna]
		    browseable = No
		    comment = DLNA directories
		    create mask = 0660
		    directory mask = 2770
		    force group = ${_SAMB_GRUP}
		    force user = ${_SAMB_USER}
		    path = ${_DIRS_SAMB}/pub/contents/dlna
		    valid users = @${_SAMB_GRUP}
		    write list = @${_SAMB_GADM}
		[share-html]
		    browseable = No
		    comment = Shared directory for HTML
		    guest ok = Yes
		    path = ${_DIRS_HTML}
		    wide links = Yes
		[share-tftp]
		    browseable = No
		    comment = Shared directory for TFTP
		    guest ok = Yes
		    path = ${_DIRS_TFTP}
		    wide links = Yes
		[share-conf]
		    browseable = No
		    comment = Shared directory for configuration files
		    create mask = 0664
		    directory mask = 2775
		    force group = ${_SAMB_GRUP}
		    force user = ${_SAMB_USER}
		    path = ${_DIRS_CONF}
		    valid users = @${_SAMB_GRUP}
		    write list = @${_SAMB_GADM}
		[share-isos]
		    browseable = No
		    comment = Shared directory for iso image files
		    create mask = 0664
		    directory mask = 2775
		    force group = ${_SAMB_GRUP}
		    force user = ${_SAMB_USER}
		    path = ${_DIRS_ISOS}
		    valid users = @${_SAMB_GRUP}
		    write list = @${_SAMB_GADM}
		[share-rmak]
		    browseable = No
		    comment = Shared directory for remake files
		    create mask = 0664
		    directory mask = 2775
		    force group = ${_SAMB_GRUP}
		    force user = ${_SAMB_USER}
		    path = ${_DIRS_RMAK}
		    valid users = @${_SAMB_GRUP}
		    write list = @${_SAMB_GADM}
_EOT_
	# --- output --------------------------------------------------------------
	testparm -s "${__CONF}" > "${__PATH}"
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		__SRVC="${__SMBD##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
		__SRVC="${__NMBD##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi
	unset __SMBD __NMBD __PATH __CONF __SRVC __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
