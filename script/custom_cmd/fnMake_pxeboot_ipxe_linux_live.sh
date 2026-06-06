# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make linux live section for ipxe menu
#   input :     $@     : media info data
#   output:   stdout   : output
#   return:            : unused
#   g-var : _NWRK_HOST : read
#   g-var : _NWRK_WGRP : read
#   g-var : _NICS_NAME : read
#   g-var : _IPV4_ADDR : read
#   g-var : _IPV4_MASK : read
#   g-var : _IPV4_GWAY : read
#   g-var : _IPV4_NSVR : read
#   g-var : _SRVR_PROT : read
#   g-var : _DIRS_IMGS : read
function fnMk_pxeboot_ipxe_linux_live() {
	declare -a    __MDIA=("${@:-}")
	declare -a    __BOPT=()
	declare       __NICS=""
	declare       __HOST=""
	declare       __CIDR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__HOST:-"localhost.localdomain"}"}"
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		opensuse-*-15.*) __NICS="eth0";;
		*              ) __NICS="${_NICS_NAME:-"ens160"}";;
	esac
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		ubuntu*) __CIDR="";;
		*      ) __CIDR="/${_IPV4_CIDR:-}";;
	esac
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		:live-${__MDIA[$((_OSET_MDIA+2))]}
		prompt --key e --timeout \${optn-timeout} Press 'e' to open edit menu ... && set openmenu 1 ||
		set hostname ${__HOST:-}
		set ethrname ${__NICS:-}
		set ipv4addr ${_IPV4_ADDR:-}${__CIDR:-}
		set ipv4mask ${_IPV4_MASK:-}
		set ipv4gway ${_IPV4_GWAY:-}
		set ipv4nsvr ${_IPV4_NSVR:-}
		#form                                    Configure Network Options
		#item hostname                           Hostname
		#item ethrname                           Interface
		#item ipv4addr                           IPv4 address/netmask
		#item ipv4gway                           IPv4 gateway
		#item ipv4nsvr                           IPv4 nameservers
		#isset \${openmenu} && present ||
		#set srvrhttp ${_SRVR_PROT:?}://\${66}
		set autoinst ${__BOPT[0]:-}
		set language ${__BOPT[1]:-}
		set networks ${__BOPT[2]:-}
		set otheropt ${__BOPT[@]:3} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
		set consoles !console=tty0 !console=ttyS0,9600
		set sulogins !SYSTEMD_SULOGIN_FORCE=1 !init=/sbin/sulogin
		set debugopt \${consoles} \${sulogins}
		form                                    Configure Autoinstall Options
		item autoinst                           Auto install
		item language                           Language
		item networks                           Network
		item otheropt                           Other options
		item debugopt                           Debug options
		isset \${openmenu} && present ||
		echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
		set knladdr \${srvrhttp}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
		set options \${autoinst} \${language} \${networks} \${otheropt} \${debugopt}
		echo Loading boot files ...
		kernel \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} \${options} || goto error
		initrd \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} || goto error
		boot || goto error
		exit
_EOT_
	unset __MDIA __BOPT __NICS __HOST __CIDR __WORK
}
