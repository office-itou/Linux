#!/bin/sh
# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: 
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_grub_menu() {
	__FUNC_NAME="fnSetup_grub_menu"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	# --- /etc/default/grub ---------------------------------------------------
#	__NAME="${_DIST_NAME%"${_DIST_NAME#"${_DIST_NAME%%-*}"}"}"
#	__VERS="${_DIST_VERS%"${_DIST_VERS#"${_DIST_VERS%%.*}"}"}"
	__BOPT=""
	__SLNX="$(fnFind_command "semanage")"
	__APAR="$(fnFind_command "aa-enabled")"
	case "${_DIST_NAME:-}" in
		debian|ubuntu)
			  if [ -n "${__APAR:-}" ]; then __BOPT="security=apparmor apparmor=1"
			elif [ -n "${__SLNX:-}" ]; then __BOPT="security=selinux selinux=1"
			fi
			;;
		fedora|centos|almalinux|rockylinux|miraclelinux)
			  if [ -n "${__SLNX:-}" ]; then __BOPT="security=selinux selinux=1"
			elif [ -n "${__APAR:-}" ]; then __BOPT="security=apparmor apparmor=1"
			fi
			;;
		opensuse-leap)
			if [ "${_DIST_VERS%%.*}" -lt 16 ]; then
				  if [ -n "${__APAR:-}" ]; then __BOPT="security=apparmor apparmor=1"
				elif [ -n "${__SLNX:-}" ]; then __BOPT="security=selinux selinux=1"
				fi
			else
				  if [ -n "${__SLNX:-}" ]; then __BOPT="security=selinux selinux=1"
				elif [ -n "${__APAR:-}" ]; then __BOPT="security=apparmor apparmor=1"
				fi
			fi
			;;
		opensuse-tumbleweed)
			  if [ -n "${__SLNX:-}" ]; then __BOPT="security=selinux selinux=1"
			elif [ -n "${__APAR:-}" ]; then __BOPT="security=apparmor apparmor=1"
			fi
			;;
		*) ;;
	esac
	__ENTR='
'
	__PATH="${_DIRS_TGET:-}/etc/default/grub"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	if ! grep -q 'GRUB_CMDLINE_LINUX_DEFAULT' "${__PATH}"; then
		sed -i "${__PATH}"                                                \
		    -e '/^GRUB_CMDLINE_LINUX=.*$/i GRUB_CMDLINE_LINUX_DEFAULT=""'
	fi
	sed -i "${__PATH}"                                       \
	    -e '/^GRUB_RECORDFAIL_TIMEOUT=.*$/                {' \
	    -e 'h; s/^/#/; p; g; s/[0-9]\+$/10/                ' \
	    -e '}                                              ' \
	    -e '/^GRUB_TIMEOUT=.*$/                           {' \
	    -e 'h; s/^/#/; p; g; s/[0-9]\+$/3/                 ' \
	    -e '}                                              ' \
	    -e '/^GRUB_CMDLINE_LINUX_DEFAULT=.*$/             {' \
	    -e 'h; s/^/#/; p; g                                ' \
	    -e 's/security=[^ "]\+//g                          ' \
	    -e 's/apparmor=[^ "]\+//g                          ' \
	    -e 's/selinux=[^ "]\+//g                           ' \
	    -e 's/"\(.*\) *"$/"\1'"${__BOPT:+" ${__BOPT}"}"'"/g' \
	    -e 's/ \+/ /g                                      ' \
	    -e 's/ *" */"/g                                    ' \
	    -e '}'
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- grub.cfg ------------------------------------------------------------
	__PATH="$(find "${_DIRS_TGET:-}"/boot/ -ipath '/*/efi' -prune -o -name 'grub.cfg' -print)"
	fnMsgout "${_PROG_NAME:-}" "create" "[${__PATH}]"
	  if command -v grub-mkconfig > /dev/null 2>&1; then
		grub-mkconfig --output "${__PATH:?}"
	elif command -v grub2-mkconfig > /dev/null 2>&1; then
		grub2-mkconfig --output "${__PATH:?}"
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __NAME __VERS __BOPT __SLNX __APAR __LINE __ENTR __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
