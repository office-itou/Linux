# shellcheck disable=SC2148

function fnMk_ipxe_opensuse() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution
	declare       __HNAM=""				# hostname
	declare       __ENAM=""				# network interface card name

	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST

	__HNAM="$(fnMk_hostname "${__DIST:?}")"
	__ENAM="$(fnMk_nic_name "${__DIST:?}")"
	readonly __HNAM
	readonly __ENAM

	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# https://en.opensuse.org/openSUSE:Roadmap
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "item --gap --"                                 "[ Development ]")
		$(printf "%-47s %s" "item -- 16.1"                                  "- openSUSE \${edition} 16.1")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- 16.0"                                  "- openSUSE \${edition} 16.0")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto opensuse-leap-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:opensuse-leap-16.1
		:opensuse-leap-16.0
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto opensuse-leap-server ||
		iseq \${edition} desktop && goto opensuse-leap-desktop ||
		goto menu

		:opensuse-leap-server
		set messages Loading openSUSE \${vers} Server ...
		set parmauto live.password=install inst.auto=\${srvrhttp}/conf/agama/autoinst_leap-\${vers}.json
		set imgsdirs \${srvrhttp}/imgs/opensuse-leap-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/opensuse-leap-netinst-\${vers}
		goto opensuse-leap-common

		:opensuse-leap-desktop
		set messages Loading openSUSE \${vers} Desktop ...
		set parmauto live.password=install inst.auto=\${srvrhttp}/conf/agama/autoinst_leap-\${vers}_desktop.json
		set imgsdirs \${srvrhttp}/imgs/opensuse-leap-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/opensuse-leap-netinst-\${vers}
		goto opensuse-leap-common

		:opensuse-leap-common
		set kernlopt \${imgsdirs}/boot/x86_64/loader/linux
		set inirdopt \${imgsdirs}/boot/x86_64/loader/initrd
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt language=ja_JP
		set otheropt root=live:\${srvrhttp}/isos/linux/opensuse/Leap-\${vers}-online-installer-x86_64.install.iso --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles dummy_console=tty0 dummy_console=ttyS0,9600
		set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		echo "Loading menu/booting.ipxe ..."
		chain --autofree --replace \${ipxebase}/menu/booting.ipxe && exit ||
		goto menu

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

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
