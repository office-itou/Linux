# shellcheck disable=SC2148

function fnMk_ipxe_debian() {
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
		# https://wiki.debian.org/DebianReleases/
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "item --gap --"                                 "[ Development ]")
		$(printf "%-47s %s" "item -- sid"                                   "- Debian \${edition} sid (unstable)")
		$(printf "%-47s %s" "item -- testing"                               "- Debian \${edition} testing (testing)")
		$(printf "%-47s %s" "item -- duke"                                  "- Debian \${edition} 15.0 duke (unreleased)")
		$(printf "%-47s %s" "item -- forky"                                 "- Debian \${edition} 14.0 forky (unreleased)")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- trixie"                                "- Debian \${edition} 13.0 trixie (stable)")
		$(printf "%-47s %s" "item -- bookworm"                              "- Debian \${edition} 12.0 bookworm (oldstable)")
		$(printf "%-47s %s" "item -- bullseye"                              "- Debian \${edition} 11.0 bullseye (oldoldstable)")
		$(printf "%-47s %s" "#item --gap --"                                "[ Extended LTS support ]")
		$(printf "%-47s %s" "#item -- buster"                               "- Debian \${edition} 10.0 buster")
		$(printf "%-47s %s" "#item -- stretch"                              "- Debian \${edition} 9.0 stretch")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		$(printf "%-47s %s" "#item -- jessie"                               "- Debian \${edition} 8.0 jessie")
		$(printf "%-47s %s" "#item -- wheezy"                               "- Debian \${edition} 7.0 wheezy")
		$(printf "%-47s %s" "#item -- squeeze"                              "- Debian \${edition} 6.0 squeeze")
		$(printf "%-47s %s" "#item -- lenny"                                "- Debian \${edition} 5.0 lenny")
		$(printf "%-47s %s" "#item -- etch"                                 "- Debian \${edition} 4.0 etch")
		$(printf "%-47s %s" "#item -- sarge"                                "- Debian \${edition} 3.1 sarge")
		$(printf "%-47s %s" "#item -- woody"                                "- Debian \${edition} 3.0 woody")
		$(printf "%-47s %s" "#item -- potato"                               "- Debian \${edition} 2.2 potato")
		$(printf "%-47s %s" "#item -- slink"                                "- Debian \${edition} 2.1 slink")
		$(printf "%-47s %s" "#item -- hamm"                                 "- Debian \${edition} 2.0 hamm")
		$(printf "%-47s %s" "#item -- bo"                                   "- Debian \${edition} 1.3 bo")
		$(printf "%-47s %s" "#item -- rex"                                  "- Debian \${edition} 1.2 rex")
		$(printf "%-47s %s" "#item -- buzz"                                 "- Debian \${edition} 1.1 buzz")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		iseq \${selected} server  && goto edition ||
		iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto \${selected} ||
		goto menu

		:edition
		iseq \${selected} server  && set edition server ||
		iseq \${selected} desktop && set edition desktop ||
		goto menu

		:sid
		:testing
		:duke
		:forky
		:trixie
		:bookworm
		:bullseye
		#:buster
		#:stretch
		#:jessie
		#:wheezy
		#:squeeze
		#:lenny
		#:etch
		#:sarge
		#:woody
		#:potato
		#:slink
		#:hamm
		#:bo
		#:rex
		#:buzz
		clear vers
		iseq \${selected} sid      && set vers unstable ||
		iseq \${selected} testing  && set vers testing  ||
		iseq \${selected} duke     && set vers 15       ||
		iseq \${selected} forky    && set vers 14       ||
		iseq \${selected} trixie   && set vers 13       ||
		iseq \${selected} bookworm && set vers 12       ||
		iseq \${selected} bullseye && set vers 11       ||
		isset \${vers} || goto menu
		iseq \${edition} server  && goto debian-server ||
		iseq \${edition} desktop && goto debian-desktop ||
		goto menu

		:debian-server
		set messages Loading Debian \${vers} Server ...
		set parmauto auto=true preseed/url=\${srvrhttp}/conf/preseed/ps_debian_server.cfg
		set imgsdirs \${srvrhttp}/imgs/debian-mini-\${vers}
		#set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/debian-mini-\${vers}
		goto debian-common

		:debian-desktop
		set messages Loading Debian \${vers} Desktop ...
		set parmauto auto=true preseed/url=\${srvrhttp}/conf/preseed/ps_debian_desktop.cfg
		set imgsdirs \${srvrhttp}/imgs/debian-mini-\${vers}
		#set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/debian-mini-\${vers}
		goto debian-common

		:debian-common
		set kernlopt \${imgsdirs}/linux
		set inirdopt \${imgsdirs}/initrd.gz
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese
		set otheropt --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
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
