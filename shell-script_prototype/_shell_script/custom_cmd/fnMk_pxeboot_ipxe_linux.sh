# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make linux section for ipxe menu
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
function fnMk_pxeboot_ipxe_linux() {
	declare -a    __MDIA=("${@:-}")
	declare -a    __BOPT=()
	declare       __ENTR=""
	declare       __NICS="${_NICS_NAME:-"ens160"}"
	declare       __HOST=""
	declare       __CIDR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	case "${__MDIA[$((_OSET_MDIA+0))]}" in
#		mini    ) ;;
#		netinst ) ;;
#		dvd     ) ;;
#		liveinst) ;;
		live    ) __ENTR="live-";;		# original media live mode
#		tool    ) ;;					# tools
#		clive   ) ;;					# custom media live mode
#		cnetinst) ;;					# custom media install mode
#		system  ) ;;					# system command
		*       ) __ENTR="";;			# original media install mode
	esac
	__HOST="${__MDIA[$((_OSET_MDIA+2))]%%-*}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__HOST:-"localhost.localdomain"}"}"
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		opensuse-*-15.*) __NICS="eth0";;
		*              ) ;;
	esac
	case "${__MDIA[$((_OSET_MDIA+2))]:-}" in
		ubuntu*) __CIDR="";;
		*      ) __CIDR="/${_IPV4_CIDR:-}";;
	esac
	if [[ -z "${__ENTR:-}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			:${__MDIA[$((_OSET_MDIA+2))]}
			prompt --key e --timeout \${optn-timeout} Press 'e' to open edit menu ... && set openmenu 1 ||
			set hostname ${__HOST:-}
			set ethrname ${__NICS:-}
			set ipv4addr ${_IPV4_ADDR:-}${__CIDR:-}
			set ipv4mask ${_IPV4_MASK:-}
			set ipv4gway ${_IPV4_GWAY:-}
			set ipv4nsvr ${_IPV4_NSVR:-}
			form                                    Configure Network Options
			item hostname                           Hostname
			item ethrname                           Interface
			item ipv4addr                           IPv4 address/netmask
			item ipv4gway                           IPv4 gateway
			item ipv4nsvr                           IPv4 nameservers
			isset \${openmenu} && present ||
			set srvraddr ${_SRVR_PROT:?}://\${66}
			set autoinst ${__BOPT[0]:-}
			set language ${__BOPT[1]:-}
			set networks ${__BOPT[2]:-}
			set otheropt ${__BOPT[@]:3}
			form                                    Configure Autoinstall Options
			item autoinst                           Auto install
			item language                           Language
			item networks                           Network
			item otheropt                           Other options
			isset \${openmenu} && present ||
			echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
			set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
			set options \${autoinst} \${language} \${networks} \${otheropt}
			echo Loading boot files ...
			kernel \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} \${options} --- quiet || goto error
			initrd \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} || goto error
			boot || goto error
			exit
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			:${__ENTR:-}${__MDIA[$((_OSET_MDIA+2))]}
			set hostname ${__HOST:-}
			set ethrname ${__NICS:-}
			set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
			set ipv4gway ${_IPV4_GWAY:-}
			set ipv4nsvr ${_IPV4_NSVR:-}
			set srvraddr ${_SRVR_PROT:?}://\${66}
			set autoinst ${__BOPT[0]:-}
			set language ${__BOPT[1]:-}
			set networks ${__BOPT[2]:-}
			set otheropt ${__BOPT[@]:3}
			echo Loading ${__MDIA[$((_OSET_MDIA+3))]//%20/ } ...
			set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__MDIA[$((_OSET_MDIA+2))]}
			set options \${autoinst} \${language} \${networks} \${otheropt}
			echo Loading boot files ...
			kernel \${knladdr}/${__MDIA[$((_OSET_MDIA+23))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} \${options} --- quiet || goto error
			initrd \${knladdr}/${__MDIA[$((_OSET_MDIA+22))]#*/"${__MDIA[$((_OSET_MDIA+2))]}"/} || goto error
			boot || goto error
			exit
_EOT_
	fi
	unset __BOPT= __ENTR __CIDR __WORK
}
