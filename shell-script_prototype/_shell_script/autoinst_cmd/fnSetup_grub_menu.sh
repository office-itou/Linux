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
	__SCRT=""
	case "${_DIST_NAME:-}" in
		debian|ubuntu)
			  if [ -n "${__APAR:-}" ]; then __SCRT="security=apparmor apparmor=1"
			elif [ -n "${__SLNX:-}" ]; then __SCRT="security=selinux selinux=1"
			fi
			;;
		fedora|centos|almalinux|rocky|miraclelinux)
			  if [ -n "${__SLNX:-}" ]; then __SCRT="security=selinux selinux=1"
			elif [ -n "${__APAR:-}" ]; then __SCRT="security=apparmor apparmor=1"
			fi
			;;
		opensuse-leap)
			if [ "${_DIST_VERS%%.*}" -lt 16 ]; then
				  if [ -n "${__APAR:-}" ]; then __SCRT="security=apparmor apparmor=1"
				elif [ -n "${__SLNX:-}" ]; then __SCRT="security=selinux selinux=1"
				fi
			else
				  if [ -n "${__SLNX:-}" ]; then __SCRT="security=selinux selinux=1"
				elif [ -n "${__APAR:-}" ]; then __SCRT="security=apparmor apparmor=1"
				fi
			fi
			;;
		opensuse-tumbleweed)
			  if [ -n "${__SLNX:-}" ]; then __SCRT="security=selinux selinux=1"
			elif [ -n "${__APAR:-}" ]; then __SCRT="security=apparmor apparmor=1"
			fi
			;;
		*) ;;
	esac
	# --- create /etc/default/grub.d/grub.cfg ---------------------------------
	# https://www.gnu.org/software/grub/manual/grub/html_node/Simple-configuration.html
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	# --- GRUB_TIMEOUT --------------------------------------------------------
	__WORK="$(sed -ne 's/^#*GRUB_TIMEOUT=\(.*\)$/\1/p' "${__PATH}")"
	[ -z "${__WORK:-}" ] && echo "GRUB_TIMEOUT=\"\"" >> "${__PATH}"
	# --- GRUB_GFXMODE --------------------------------------------------------
	__WORK="$(sed -ne 's/^#*GRUB_GFXMODE=\(.*\)$/\1/p' "${__PATH}")"
	[ -z "${__WORK:-}" ] && echo "GRUB_GFXMODE=\"\"" >> "${__PATH}"
	# --- GRUB_INIT_TUNE ------------------------------------------------------
	__WORK="$(sed -ne 's/^#*GRUB_INIT_TUNE=\(.*\)$/\1/p' "${__PATH}")"
	[ -z "${__WORK:-}" ] && echo "GRUB_INIT_TUNE=\"\"" >> "${__PATH}"
	# --- GRUB_CMDLINE_LINUX_DEFAULT ------------------------------------------
	__WORK="$(sed -ne 's/^#*GRUB_CMDLINE_LINUX_DEFAULT=\(.*\)$/\1/p' "${__PATH}")"
	[ -z "${__WORK:-}" ] && echo "GRUB_CMDLINE_LINUX_DEFAULT=\"\"" >> "${__PATH}"
	__WORK="${__WORK#\"}"
	__WORK="${__WORK%\"}"
	__DEFS=""
	for __LINE in ${__WORK:-}
	do
		case "${__LINE:-}" in
			security=*) ;;
			apparmor=*) ;;
			selinux=*) ;;
			quiet) ;;
			vga=*) ;;
			*) __DEFS="${__DEFS:+"${__DEFS} "}${__LINE:-}";;
		esac
	done
	# --- GRUB_CMDLINE_LINUX --------------------------------------------------
	__WORK="$(sed -ne 's/^#*GRUB_CMDLINE_LINUX=\(.*\)$/\1/p' "${__PATH}")"
	[ -z "${__WORK:-}" ] && echo "GRUB_CMDLINE_LINUX=\"\"" >> "${__PATH}"
	__WORK="${__WORK#\"}"
	__WORK="${__WORK%\"}"
	__BOPT=""
	for __LINE in ${__WORK:-}
	do
		case "${__LINE:-}" in
			security=*) ;;
			apparmor=*) ;;
			selinux=*) ;;
			quiet) ;;
			vga=*) ;;
			*) __BOPT="${__BOPT:+"${__BOPT} "}${__LINE:-}";;
		esac
	done
	__BOPT="${__BOPT:+"${__BOPT} "}${__SCRT:-}"
	__BOPT="$(echo "${__BOPT:-}" | sed -e 's%/%\\/%g')"
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "info" "_DIST_NAME=[${_DIST_NAME:-}]"
	fnMsgout "${_PROG_NAME:-}" "info" "    __BOPT=[${__BOPT:-}]"
	fnMsgout "${_PROG_NAME:-}" "info" "    __SLNX=[${__SLNX:-}]"
	fnMsgout "${_PROG_NAME:-}" "info" "    __APAR=[${__APAR:-}]"
	sed -i "${__PATH}" \
	    -e '/^#*GRUB_RECORDFAIL_TIMEOUT=.*$/    {s/^#//; h; s/^/#/; p; g; s/[0-9]\+$/10/}' \
	    -e '/^#*GRUB_TIMEOUT=.*$/               {s/^#//; h; s/^/#/; p; g; s/[0-9]\+$/3/ }' \
	    -e '/^#*GRUB_GFXMODE=.*$/               {s/^#//; h; s/^/#/; p; g; s/=.*$/="1920x1080,800x600,auto"/}' \
	    -e '/^#*GRUB_INIT_TUNE=.*$/             {s/^#//; h; s/^/#/; p; g; s/=.*$/="960 440 1 0 4 440 1"/}' \
	    -e '/^#*GRUB_CMDLINE_LINUX_DEFAULT=.*$/ {s/^#//; h; s/^/#/; p; g; s/=.*$/="'"${__DEFS:-}"'"/}' \
	    -e '/^#*GRUB_CMDLINE_LINUX=.*$/         {s/^#//; h; s/^/#/; p; g; s/=.*$/="'"${__BOPT:-}"'"/}'
	diff --suppress-common-lines --expand-tabs "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}" || true
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- grub.cfg --------------------------------------------------------
	__PATH="$(find "${_DIRS_TGET:-}"/boot/ -ipath '/*/efi' -prune -o -name 'grub.cfg' -print)"
	fnMsgout "${_PROG_NAME:-}" "create" "[${__PATH}]"
	if command -v grub-mkconfig > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "info" "grub-mkconfig"
		grub-mkconfig --output="${__PATH:?}"
	elif command -v grub2-mkconfig > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "info" "grub2-mkconfig"
		if ! grub2-mkconfig --output="${__PATH:?}" --update-bls-cmdline > /dev/null 2>&1; then
			fnMsgout "${_PROG_NAME:-}" "info" "grubby"
			grubby --update-kernel=ALL --remove-args="security apparmor selinux quiet vga" --args="${__BOPT:-}"
			grub2-mkconfig --output="${__PATH:?}"
		fi
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	unset __NAME __VERS __DEFS __BOPT __SLNX __APAR __LINE __ENTR __WORK __PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
	# --- memo ----------------------------------------------------------------
	# https://documentation.suse.com/ja-jp/sles/12-SP5/html/SLES-all/cha-grub2.html
	# GRUB_BACKGROUND
	# GRUB_BADRAM
	# GRUB_BUTTON_CMOS_ADDRESS
	# GRUB_BUTTON_CMOS_CLEAN
	# GRUB_CMDLINE_GNUMACH
	# GRUB_CMDLINE_LINUX
	# GRUB_CMDLINE_LINUX_DEFAULT
	# GRUB_CMDLINE_LINUX_RECOVERY
	# GRUB_CMDLINE_LINUX_XEN_REPLACE
	# GRUB_CMDLINE_LINUX_XEN_REPLACE_DEFAULT
	# GRUB_CMDLINE_NETBSD
	# GRUB_CMDLINE_NETBSD_DEFAULT
	# GRUB_CMDLINE_XEN
	# GRUB_CMDLINE_XEN_DEFAULT
	# GRUB_DEFAULT_BUTTON
	# GRUB_DEFAULT_DTB - grub2
	# GRUB_DISABLE_LINUX_PARTUUID
	# GRUB_DISABLE_LINUX_UUID
	# GRUB_DISABLE_OS_PROBER - grub2
	# GRUB_DISABLE_RECOVERY
	# GRUB_DISABLE_SUBMENU
	# GRUB_DISABLE_UUID
	# GRUB_DISTRIBUTOR
	# GRUB_EARLY_INITRD_LINUX_CUSTOM
	# GRUB_EARLY_INITRD_LINUX_STOCK
	# GRUB_ENABLE_BLSCFG - grub2
	# GRUB_ENABLE_CRYPTODISK
	# GRUB_GFXMODE
	# GRUB_GFXPAYLOAD_LINUX
	# GRUB_HIDDEN_TIMEOUT
	# GRUB_HIDDEN_TIMEOUT_BUTTON
	# GRUB_HIDDEN_TIMEOUT_QUIET
	# GRUB_INIT_TUNE
	# GRUB_OS_PROBER_SKIP_LIST
	# GRUB_RECORDFAIL_TIMEOUT - grub
	# GRUB_RECOVERY_TITLE - grub
	# GRUB_SAVEDEFAULT
	# GRUB_SERIAL_COMMAND
	# GRUB_TERMINAL_INPUT
	# GRUB_TERMINAL_OUTPUT
	# GRUB_THEME
	# GRUB_TIMEOUT
	# GRUB_TIMEOUT_BUTTON
	# GRUB_TIMEOUT_STYLE
	# GRUB_TIMEOUT_STYLE_BUTTON
	# GRUB_TOP_LEVEL
	# GRUB_TOP_LEVEL_OS_PROBER
	# GRUB_TOP_LEVEL_XEN
	# GRUB_VIDEO_BACKEND
}
