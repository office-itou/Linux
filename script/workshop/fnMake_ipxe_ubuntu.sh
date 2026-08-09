# shellcheck disable=SC2148

function fnMk_ipxe_ubuntu() {
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
		# https://ubuntu.com/project/docs/release-team/list-of-releases/
		set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Edition ]")
		$(printf "%-47s %s" "item -- server"                                "- Server")
		$(printf "%-47s %s" "item -- desktop"                               "- Desktop")
		$(printf "%-47s %s" "item --gap --"                                 "[ Development ]")
		$(printf "%-47s %s" "item -- stonking"                              "- Ubuntu \${edition} 26.10 Stonking Stingray")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- resolute"                              "- Ubuntu \${edition} 26.04 LTS Resolute Raccoon")
		$(printf "%-47s %s" "item -- noble"                                 "- Ubuntu \${edition} 24.04 LTS Noble Numbat")
		$(printf "%-47s %s" "#item -- jammy"                                "- Ubuntu \${edition} 22.04 LTS Jammy Jellyfish")
		$(printf "%-47s %s" "#item -- focal"                                "- Ubuntu \${edition} 20.04 LTS Focal Fossa")
		$(printf "%-47s %s" "#item -- bionic"                               "- Ubuntu \${edition} 18.04 LTS Bionic Beaver")
		$(printf "%-47s %s" "#item -- xenial"                               "- Ubuntu \${edition} 16.04 LTS Xenial Xerus")
		$(printf "%-47s %s" "#item -- trusty"                               "- Ubuntu \${edition} 14.04 LTS Trusty Tahr")
		$(printf "%-47s %s" "#item --gap --"                                "[ Expanded Security Maintenance ]")
		$(printf "%-47s %s" "#item -- focal"                                "- Ubuntu \${edition} 20.04 ESM Focal Fossa")
		$(printf "%-47s %s" "#item -- bionic"                               "- Ubuntu \${edition} 18.04 ESM Bionic Beaver")
		$(printf "%-47s %s" "#item -- xenial"                               "- Ubuntu \${edition} 16.04 ESM Xenial Xerus")
		$(printf "%-47s %s" "#item -- trusty"                               "- Ubuntu \${edition} 14.04 ESM Trusty Tahr")
		$(printf "%-47s %s" "#item -- precise"                              "- Ubuntu \${edition} 12.04 ESM Precise Pangolin")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")")
		$(printf "%-47s %s" "#item -- questing"                             "- Ubuntu \${edition} 25.10 Questing Quokka")
		$(printf "%-47s %s" "#item -- plucky"                               "- Ubuntu \${edition} 25.04 Plucky Puffin")
		$(printf "%-47s %s" "#item -- oracular"                             "- Ubuntu \${edition} 24.10 Oracular Oriole")
		$(printf "%-47s %s" "#item -- mantic"                               "- Ubuntu \${edition} 23.10 Mantic Minotaur")
		$(printf "%-47s %s" "#item -- lunar"                                "- Ubuntu \${edition} 23.04 Lunar Lobster")
		$(printf "%-47s %s" "#item -- kinetic"                              "- Ubuntu \${edition} 22.10 Kinetic Kudu")
		$(printf "%-47s %s" "#item -- impish"                               "- Ubuntu \${edition} 21.10 Impish Indri")
		$(printf "%-47s %s" "#item -- hirsute"                              "- Ubuntu \${edition} 21.04 Hirsute Hippo")
		$(printf "%-47s %s" "#item -- groovy"                               "- Ubuntu \${edition} 20.10 Groovy Gorilla")
		$(printf "%-47s %s" "#item -- eoan"                                 "- Ubuntu \${edition} 19.10 Eoan Ermine")
		$(printf "%-47s %s" "#item -- disco"                                "- Ubuntu \${edition} 19.04 Disco Dingo")
		$(printf "%-47s %s" "#item -- cosmic"                               "- Ubuntu \${edition} 18.10 Cosmic Cuttlefish")
		$(printf "%-47s %s" "#item -- artful"                               "- Ubuntu \${edition} 17.10 Artful Aardvark")
		$(printf "%-47s %s" "#item -- zesty"                                "- Ubuntu \${edition} 17.04 Zesty Zapus")
		$(printf "%-47s %s" "#item -- yakkety"                              "- Ubuntu \${edition} 16.10 Yakkety Yak")
		$(printf "%-47s %s" "#item -- wily"                                 "- Ubuntu \${edition} 15.10 Wily Werewolf")
		$(printf "%-47s %s" "#item -- vivid"                                "- Ubuntu \${edition} 15.04 Vivid Vervet")
		$(printf "%-47s %s" "#item -- utopic"                               "- Ubuntu \${edition} 14.10 Utopic Unicorn")
		$(printf "%-47s %s" "#item -- saucy"                                "- Ubuntu \${edition} 13.10 Saucy Salamander")
		$(printf "%-47s %s" "#item -- raring"                               "- Ubuntu \${edition} 13.04 Raring Ringtail")
		$(printf "%-47s %s" "#item -- quantal"                              "- Ubuntu \${edition} 12.10 Quantal Quetzal")
		$(printf "%-47s %s" "#item -- precise"                              "- Ubuntu \${edition} 12.04 LTS Precise Pangolin")
		$(printf "%-47s %s" "#item -- oneiric"                              "- Ubuntu \${edition} 11.10 Oneiric Ocelot")
		$(printf "%-47s %s" "#item -- natty"                                "- Ubuntu \${edition} 11.04 Natty Narwhal")
		$(printf "%-47s %s" "#item -- maverick"                             "- Ubuntu \${edition} 10.10 Maverick Meerkat")
		$(printf "%-47s %s" "#item -- lucid"                                "- Ubuntu \${edition} 10.04 LTS Lucid Lynx")
		$(printf "%-47s %s" "#item -- karmic"                               "- Ubuntu \${edition} 9.10 Karmic Koala")
		$(printf "%-47s %s" "#item -- jaunty"                               "- Ubuntu \${edition} 9.04 Jaunty Jackalope")
		$(printf "%-47s %s" "#item -- intrepid"                             "- Ubuntu \${edition} 8.10 Intrepid Ibex")
		$(printf "%-47s %s" "#item -- hardy"                                "- Ubuntu \${edition} 8.04 LTS Hardy Heron")
		$(printf "%-47s %s" "#item -- gutsy"                                "- Ubuntu \${edition} 7.10 Gutsy Gibbon")
		$(printf "%-47s %s" "#item -- feisty"                               "- Ubuntu \${edition} 7.04 Feisty Fawn")
		$(printf "%-47s %s" "#item -- edgy"                                 "- Ubuntu \${edition} 6.10 Edgy Eft")
		$(printf "%-47s %s" "#item -- dapper"                               "- Ubuntu \${edition} 6.06 LTS Dapper Drake")
		$(printf "%-47s %s" "#item -- breezy"                               "- Ubuntu \${edition} 5.10 Breezy Badger")
		$(printf "%-47s %s" "#item -- hoary"                                "- Ubuntu \${edition} 5.04 Hoary Hedgehog")
		$(printf "%-47s %s" "#item -- warty"                                "- Ubuntu \${edition} 4.10 Warty Warthog")
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

		:stonking
		:resolute
		#:questing
		#:plucky
		#:oracular
		:noble
		#:mantic
		#:lunar
		#:kinetic
		#:jammy
		#:impish
		#:hirsute
		#:groovy
		#:focal
		#:eoan
		#:disco
		#:cosmic
		#:bionic
		#:artful
		#:zesty
		#:yakkety
		#:xenial
		#:wily
		#:vivid
		#:utopic
		#:trusty
		#:saucy
		#:raring
		#:quantal
		#:precise
		#:precise
		#:oneiric
		#:natty
		#:maverick
		#:lucid
		#:karmic
		#:jaunty
		#:intrepid
		#:hardy
		#:gutsy
		#:feisty
		#:edgy
		#:dapper
		#:breezy
		#:hoary
		#:warty
		clear vers
		iseq \${selected} stonking && set vers 26.10 ||
		iseq \${selected} resolute && set vers 26.04 ||
		iseq \${selected} noble    && set vers 24.04 ||
		isset \${vers} || goto menu
		iseq \${edition} server  && goto ubuntu-server ||
		iseq \${edition} desktop && goto ubuntu-desktop ||
		goto menu

		:ubuntu-server
		set messages Loading Ubuntu \${vers} Server ...
		set parmauto automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=\${srvrhttp}/conf/nocloud/ubuntu_server
		set imgsdirs \${srvrhttp}/imgs/ubuntu-live-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/ubuntu-live-\${vers}
		goto ubuntu-common

		:ubuntu-desktop
		set messages Loading Ubuntu \${vers} Desktop ...
		set parmauto automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=\${srvrhttp}/conf/nocloud/ubuntu_desktop
		set imgsdirs \${srvrhttp}/imgs/ubuntu-desktop-\${vers}
		set exptdirs \${srvraddr}:/srv/exports/nfs/imgs/ubuntu-desktop-\${vers}
		goto ubuntu-common

		:ubuntu-common
		set kernlopt \${imgsdirs}/casper/vmlinuz
		set inirdopt \${imgsdirs}/casper/initrd
		set hnameopt ${__HNAME:?}
		set enameopt ${__ENAME:?}
		set languopt language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese
		set otheropt netboot=nfs nfsroot=\${exptdirs} network-config=disabled --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
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
