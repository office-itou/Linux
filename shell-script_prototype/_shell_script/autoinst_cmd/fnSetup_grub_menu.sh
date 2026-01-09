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

#	__NAME="${_DIST_NAME%"${_DIST_NAME#"${_DIST_NAME%%-*}"}"}"
#	__VERS="${_DIST_VERS%"${_DIST_VERS#"${_DIST_VERS%%.*}"}"}"
	__BOPT=""
	case "${_DIST_NAME:-}" in
		debian|ubuntu)
			  if command -v aa-enabled > /dev/null 2>&1; then __BOPT="apparmor=1 security=apparmor"
			elif command -v semanage   > /dev/null 2>&1; then __BOPT="selinux=1 security=selinux"
			fi
			;;
		fedora|centos|almalinux|rockylinux|miraclelinux)
			  if command -v semanage   > /dev/null 2>&1; then __BOPT="selinux=1 security=selinux"
			elif command -v aa-enabled > /dev/null 2>&1; then __BOPT="apparmor=1 security=apparmor"
			fi
			;;
		opensuse-leap)
			if [ "${_DIST_VERS%%.*}" -lt 16 ]; then
				  if command -v aa-enabled > /dev/null 2>&1; then __BOPT="apparmor=1 security=apparmor"
				elif command -v semanage   > /dev/null 2>&1; then __BOPT="selinux=1 security=selinux"
				fi
			else
				  if command -v semanage   > /dev/null 2>&1; then __BOPT="selinux=1 security=selinux"
				elif command -v aa-enabled > /dev/null 2>&1; then __BOPT="apparmor=1 security=apparmor"
				fi
			fi
			;;
		opensuse-tumbleweed)
			  if command -v semanage   > /dev/null 2>&1; then __BOPT="selinux=1 security=selinux"
			elif command -v aa-enabled > /dev/null 2>&1; then __BOPT="apparmor=1 security=apparmor"
			fi
			;;
		*) ;;
	esac
	__ENTR='
'
	__PATH="${_DIRS_TGET:-}/etc/default/grub"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
#	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	: > "${__PATH}"
	cat "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" | while read -r __LINE
	do
		case "${__LINE:-}" in
			GRUB_RECORDFAIL_TIMEOUT=*   ) __LINE="#${__LINE}${__ENTR}${__LINE%%=*}=10";;
			GRUB_TIMEOUT=*              ) __LINE="#${__LINE}${__ENTR}${__LINE%%=*}=3";;
			GRUB_CMDLINE_LINUX_DEFAULT=*) 
			__WORK="$(echo "${__LINE:-}" |     \
				sed -e 's/^.*="//'             \
				    -e 's/"$//'                \
				    -e 's/security=[^ ]\+//g'  \
				    -e 's/apparmor=[^ ]\+//g'  \
				    -e 's/selinux=[^ ]\+//g'   \
				    -e 's/ \+/ /g'             \
				    -e 's/^ \+//g'             \
				    -e 's/ \+$//g'             \
			)"
			__LINE="#${__LINE}${__ENTR}${__LINE%%=*}=${__WORK:+"\"${__WORK}${__BOPT:+" ${__BOPT}"}"\"}"
			;;
#			GRUB_CMDLINE_LINUX=*        ) __LINE="#${__LINE}${__ENTR}";;
			*                           ) ;;
		esac
		printf "%s\n" "${__LINE:-}" >> "${__PATH}"
	done
	__PATH="$(find /boot/ -ipath '/*/efi' -prune -o -name grub.cfg -print)"
	  if command -v grub-mkconfig > /dev/null 2>&1; then
		grub-mkconfig --output "${__PATH:?}"
	elif command -v grub2-mkconfig > /dev/null 2>&1; then
		grub2-mkconfig --output "${__PATH:?}"
	fi
	unset __NAME __VERS __BOPT __LINE __ENTR __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
