# shellcheck disable=SC2148

function fnMk_ipxe_menu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"

	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Distribution for automatic installation ]")
		$(printf "%-47s %s" "item -- debian"                                "- Debian")
		$(printf "%-47s %s" "item -- ubuntu"                                "- Ubuntu")
		$(printf "%-47s %s" "item -- fedora"                                "- Fedora")
		$(printf "%-47s %s" "item -- centos"                                "- CentOS Stream")
		$(printf "%-47s %s" "item -- almalinux"                             "- AlmaLinux")
		$(printf "%-47s %s" "item -- rockylinux"                            "- Rocky Linux")
		$(printf "%-47s %s" "item -- miraclelinux"                          "- MIRACLE LINUX")
		$(printf "%-47s %s" "item -- opensuse"                              "- openSUSE")
		$(printf "%-47s %s" "item -- windows"                               "- Windows")
		$(printf "%-47s %s" "item --gap --"                                 "[ Other ]")
		$(printf "%-47s %s" "item -- live"                                  "- Live Media")
		$(printf "%-47s %s" "item -- custom-live"                           "- Custom Live Media")
		$(printf "%-47s %s" "item --gap --"                                 "[ System command ]")
		$(printf "%-47s %s" "item -- shell"                                 "- iPXE shell")
		$(printf "%-47s %s" "item -- shutdown"                              "- System shutdown")
		$(printf "%-47s %s" "item -- restart"                               "- System reboot")
		choose --timeout \${menu-timeout} --default \${menu-default} selected && goto \${selected}
		goto menu

		# --- Interactive form block --------------------------------------------------
		:debian
		:ubuntu
		:fedora
		:centos
		:almalinux
		:rockylinux
		:miraclelinux
		:opensuse
		:windows
		:live
		:custom-live
		set distribution \${selected}
		echo "Loading menu/\${selected}.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/\${selected}.ipxe && exit ||
		goto menu

		:shell
		echo "Booting iPXE shell ..."
		shell
		goto menu

		:shutdown
		echo "System shutting down ..."
		poweroff
		exit

		:restart
		echo "System rebooting ..."
		reboot
		exit

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
