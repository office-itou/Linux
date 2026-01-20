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
	__ENTR='
'
	__PATH="${_DIRS_TGET:-}/etc/default/grub"
	__SLNX="$(fnFind_command "semanage")"	# selinux
	__APAR="$(fnFind_command "aa-enabled")"	# apparmor
	__BOPT=""
	case "${_DIST_NAME:-}" in
		debian|ubuntu)
			  if [ -n "${__APAR:-}" ]; then __BOPT="security=apparmor apparmor=1"
			elif [ -n "${__SLNX:-}" ]; then __BOPT="security=selinux selinux=1"
			fi
			;;
		fedora|centos|almalinux|rocky|miraclelinux)
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
	# --- create /etc/default/grub.d/grub.cfg ---------------------------------
	# https://www.gnu.org/software/grub/manual/grub/html_node/Simple-configuration.html
	fnMsgout "${_PROG_NAME:-}" "info" "_DIST_NAME=[${_DIST_NAME:-}]"
	fnMsgout "${_PROG_NAME:-}" "info" "    __BOPT=[${__BOPT:-}]"
#	fnMsgout "${_PROG_NAME:-}" "info" "    __SLNX=[${__SLNX:-}]"
#	fnMsgout "${_PROG_NAME:-}" "info" "    __APAR=[${__APAR:-}]"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
#	if command -v grubby > /dev/null 2>&1; then
#		grubby --update-kernel ALL --remove-args "security apparmor selinux vga" --args "${__BOPT}"
#	else
		__WORK="$(sed -ne 's/^GRUB_CMDLINE_LINUX=\(.*\)$/\1/p' "${__PATH}")"
		__WORK="${__WORK#\"}"
		__WORK="${__WORK%\"}"
		__WORK="$(
			echo "${__WORK:-}" | \
			sed -e 's/ *security=[^ ]* *//' \
			    -e 's/ *apparmor=[^ ]* *//' \
			    -e 's/ *selinux=[^ ]* *// ' \
			    -e 's/ *vga=[^ ]* *//'
		)"
		[ -n "${__WORK:-}" ] && __BOPT="${__WORK:+"${__WORK} ${__BOPT:-}"}"
		__BOPT="$(echo "${__BOPT:-}" | sed -e 's%/%\\/%g')"
		sed -i "${__PATH}"                                \
		    -e '/^GRUB_RECORDFAIL_TIMEOUT=.*$/    s/^/#/' \
		    -e '/^GRUB_TIMEOUT=.*$/               s/^/#/' \
		    -e '/^GRUB_CMDLINE_LINUX_DEFAULT=.*$/ s/^/#/' \
		    -e '/^GRUB_CMDLINE_LINUX=.*$/         s/^/#/' \
		    -e '/^GRUB_GFXMODE=.*$/               s/^/#/'
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
		
			### User Custom ###
			GRUB_RECORDFAIL_TIMEOUT="10"
			GRUB_TIMEOUT="3"
			GRUB_CMDLINE_LINUX="${__BOPT:-}"
			GRUB_GFXMODE="1920x1080,800x600,auto"
_EOT_
#	fi
	diff --suppress-common-lines --expand-tabs --side-by-side "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}" || true
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- grub.cfg --------------------------------------------------------
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
