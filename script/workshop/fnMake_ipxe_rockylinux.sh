# shellcheck disable=SC2148

function fnMk_ipxe_rockylinux() {
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
		# https://wiki.rockylinux.org/rocky/version/
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "#item --gap --"                                "[ Development ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- 10"                                    "- Rocky Linux \${edition} 10")
		$(printf "%-47s %s" "item --  9"                                    "- Rocky Linux \${edition} 9")
		$(printf "%-47s %s" "item --  8"                                    "- Rocky Linux \${edition} 8")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto rockylinux-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:rockylinux-10
		:rockylinux-9
		:rockylinux-8
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto rockylinux-server ||
		iseq \${edition} desktop && goto rockylinux-desktop ||
		goto menu

		:rockylinux-server
		set messages Loading Rocky Linux \${vers} Server ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_rockylinux-\${vers}_net.cfg
		set imgsdirs \${srvrhttp}/imgs/rockylinux-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/rockylinux-netinst-\${vers}
		goto rockylinux-common

		:rockylinux-desktop
		set messages Loading Rocky Linux \${vers} Desktop ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_rockylinux-\${vers}_net_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/rockylinux-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/rockylinux-netinst-\${vers}
		goto rockylinux-common

		:rockylinux-common
		set kernlopt \${imgsdirs}/images/pxeboot/vmlinuz
		set inirdopt \${imgsdirs}/images/pxeboot/initrd.img
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106 language=ja_JP
		set otheropt inst.repo=nfs:\${exptdirs} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
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
