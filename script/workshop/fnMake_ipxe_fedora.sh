# shellcheck disable=SC2148

function fnMk_ipxe_fedora() {
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
		# https://en.wikipedia.org/wiki/Fedora_Linux_release_history
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "item --gap --"                                 "[ Development ]")
		$(printf "%-47s %s" "item -- 46"                                    "- Fedora \${edition} 46")
		$(printf "%-47s %s" "item -- 45"                                    "- Fedora \${edition} 45")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- 44"                                    "- Fedora \${edition} 44")
		$(printf "%-47s %s" "item -- 43"                                    "- Fedora \${edition} 43")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		$(printf "%-47s %s" "#item -- 42"                                   "- Fedora Linux \${edition} 42 (Adams)")
		$(printf "%-47s %s" "#item -- 41"                                   "- Fedora Linux \${edition} 41")
		$(printf "%-47s %s" "#item -- 40"                                   "- Fedora Linux \${edition} 40")
		$(printf "%-47s %s" "#item -- 39"                                   "- Fedora Linux \${edition} 39")
		$(printf "%-47s %s" "#item -- 38"                                   "- Fedora Linux \${edition} 38")
		$(printf "%-47s %s" "#item -- 37"                                   "- Fedora Linux \${edition} 37")
		$(printf "%-47s %s" "#item -- 36"                                   "- Fedora Linux \${edition} 36")
		$(printf "%-47s %s" "#item -- 35"                                   "- Fedora Linux \${edition} 35")
		$(printf "%-47s %s" "#item -- 34"                                   "- Fedora Linux \${edition} 34")
		$(printf "%-47s %s" "#item -- 33"                                   "- Fedora Linux \${edition} 33")
		$(printf "%-47s %s" "#item -- 32"                                   "- Fedora Linux \${edition} 32")
		$(printf "%-47s %s" "#item -- 31"                                   "- Fedora Linux \${edition} 31")
		$(printf "%-47s %s" "#item -- 30"                                   "- Fedora Linux \${edition} 30")
		$(printf "%-47s %s" "#item -- 29"                                   "- Fedora Linux \${edition} 29")
		$(printf "%-47s %s" "#item -- 28"                                   "- Fedora Linux \${edition} 28")
		$(printf "%-47s %s" "#item -- 27"                                   "- Fedora Linux \${edition} 27")
		$(printf "%-47s %s" "#item -- 26"                                   "- Fedora Linux \${edition} 26")
		$(printf "%-47s %s" "#item -- 25"                                   "- Fedora Linux \${edition} 25")
		$(printf "%-47s %s" "#item -- 24"                                   "- Fedora Linux \${edition} 24")
		$(printf "%-47s %s" "#item -- 23"                                   "- Fedora Linux \${edition} 23")
		$(printf "%-47s %s" "#item -- 22"                                   "- Fedora Linux \${edition} 22")
		$(printf "%-47s %s" "#item -- 21"                                   "- Fedora Linux \${edition} 21 (Twenty One)")
		$(printf "%-47s %s" "#item -- 20"                                   "- Fedora Linux \${edition} 20 (Heisenbug)")
		$(printf "%-47s %s" "#item -- 19"                                   "- Fedora Linux \${edition} 19 (Schrödinger’s Cat)")
		$(printf "%-47s %s" "#item -- 18"                                   "- Fedora Linux \${edition} 18 (Spherical Cow)")
		$(printf "%-47s %s" "#item -- 17"                                   "- Fedora Linux \${edition} 17 (Beefy Miracle)")
		$(printf "%-47s %s" "#item -- 16"                                   "- Fedora Linux \${edition} 16 (Verne)")
		$(printf "%-47s %s" "#item -- 15"                                   "- Fedora Linux \${edition} 15 (Lovelock)")
		$(printf "%-47s %s" "#item -- 14"                                   "- Fedora Linux \${edition} 14 (Laughlin)")
		$(printf "%-47s %s" "#item -- 13"                                   "- Fedora Linux \${edition} 13 (Goddard)")
		$(printf "%-47s %s" "#item -- 12"                                   "- Fedora Linux \${edition} 12 (Constantine)")
		$(printf "%-47s %s" "#item -- 11"                                   "- Fedora Linux \${edition} 11 (Leonidas)")
		$(printf "%-47s %s" "#item -- 10"                                   "- Fedora Linux \${edition} 10 (Cambridge)")
		$(printf "%-47s %s" "#item --  9"                                   "- Fedora Linux \${edition} 9 (Sulphur)")
		$(printf "%-47s %s" "#item --  8"                                   "- Fedora Linux \${edition} 8 (Werewolf)")
		$(printf "%-47s %s" "#item --  7"                                   "- Fedora Linux \${edition} 7 (Moonshine)")
		$(printf "%-47s %s" "#item --  6"                                   "- Fedora Core \${edition} 6 (Zod)")
		$(printf "%-47s %s" "#item --  5"                                   "- Fedora Core \${edition} 5 (Bordeaux)")
		$(printf "%-47s %s" "#item --  4"                                   "- Fedora Core \${edition} 4 (Stentz)")
		$(printf "%-47s %s" "#item --  3"                                   "- Fedora Core \${edition} 3 (Heidelberg)")
		$(printf "%-47s %s" "#item --  2"                                   "- Fedora Core \${edition} 2 (Tettnang)")
		$(printf "%-47s %s" "#item --  1"                                   "- Fedora Core \${edition} 1 (Yarrow)")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto fedora-\${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:fedora-46
		:fedora-45
		:fedora-44
		:fedora-43
		clear vers
		set vers \${selected}
		isset \${vers} || goto menu
		iseq \${edition} server  && goto fedora-server ||
		iseq \${edition} desktop && goto fedora-desktop ||
		goto menu

		:fedora-server
		set messages Loading Fedora \${vers} Server ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_fedora-\${vers}_net.cfg
		set imgsdirs \${srvrhttp}/imgs/fedora-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/fedora-netinst-\${vers}
		goto fedora-common

		:fedora-desktop
		set messages Loading Fedora \${vers} Desktop ...
		set parmauto inst.ks=\${srvrhttp}/conf/kickstart/ks_fedora-\${vers}_net_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/fedora-netinst-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/fedora-netinst-\${vers}
		goto fedora-common

		:fedora-common
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
