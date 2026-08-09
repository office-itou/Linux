# shellcheck disable=SC2148

function fnMk_ipxe_autoexec() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"

	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Configure graphical console ---------------------------------------------

		console --x 1024 --y 768 ||
		# --- Define colour pair ------------------------------------------------------
		# Reset the default colour pair
		cpair 0 ||
		# Redefine the editable text pair as black on white
		cpair --foreground 7 --background 0 4 ||

		# --- Check x86 CPU feature ---------------------------------------------------
		# Check if CPU supports 64-bit operation ("long mode")
		clear arch
		cpuid --ext 29 && set arch x86_64 || set arch i386

		# --- Automatically configure interfaces --------------------------------------
		# Automatically configure the first available interface using DHCP
		ifconf --configurator dhcp ||
		# Automatically configure the first available interface using IPv6
		ifconf --configurator ipv6 ||

		# --- Set the IP address of the PXE boot server -------------------------------
		clear srvraddr
		isset \${66} && set srvraddr \${66} || set srvraddr ${_SRVR_ADDR:?}

		# --- Set the parameters. -----------------------------------------------------
		set srvrhttp http://\${srvraddr}
		set ipxebase \${srvrhttp}/tftp/ipxe
		set optn-timeout 1000
		set menu-timeout 0
		set esc:hex 1b

		# --- Preventing multiple instances -------------------------------------------
		isset \${menu-default} || set menu-default exit

		# --- chain -------------------------------------------------------------------
		chain \${ipxebase}/menu/menu.ipxe
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
