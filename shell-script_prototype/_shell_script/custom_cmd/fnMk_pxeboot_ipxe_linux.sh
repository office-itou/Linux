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
	declare -a    __BOPT=()
	declare       __ENTR=""
	declare       __CIDR=""
	declare       __WORK=""
	__WORK="$(fnMk_boot_options "pxeboot" "${@}")"
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	case "${2}" in
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
	case "${4:-}" in
		ubuntu*) __CIDR="";;
		*      ) __CIDR="/${_IPV4_CIDR:-}";;
	esac
	if [[ -z "${__ENTR:-}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			:${4}
			prompt --key e --timeout \${optn-timeout} Press 'e' to open edit menu ... && set openmenu 1 ||
			set hostname ${_NWRK_HOST/:_DISTRO_:/${4%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
			set ethrname ${_NICS_NAME:-ens160}
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
			set autoinst ${__BOPT[0]:-} ${__BOPT[1]:-}
			set language ${__BOPT[2]:-}
			set networks ${__BOPT[3]:-}
			set otheropt ${__BOPT[@]:4}
			form                                    Configure Autoinstall Options
			item autoinst                           Auto install
			item language                           Language
			item networks                           Network
			item otheropt                           Other options
			isset \${openmenu} && present ||
			echo Loading ${5//%20/ } ...
			set srvraddr ${_SRVR_PROT:?}://\${66}
			set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${4}
			set options \${autoinst} \${language} \${networks} \${otheropt}
			echo Loading boot files ...
			kernel \${knladdr}/${25#*/"${4}"/} \${options} --- quiet || goto error
			initrd \${knladdr}/${24#*/"${4}"/} || goto error
			boot || goto error
			exit
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			:${__ENTR:-}${4}
			set hostname ${_NWRK_HOST/:_DISTRO_:/${4%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
			set ethrname ${_NICS_NAME:-ens160}
			set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
			set ipv4gway ${_IPV4_GWAY:-}
			set ipv4nsvr ${_IPV4_NSVR:-}
			set srvraddr ${_SRVR_PROT:?}://\${66}
			set autoinst ${__BOPT[0]:-} ${__BOPT[1]:-}
			set language ${__BOPT[2]:-}
			set networks ${__BOPT[3]:-}
			set otheropt ${__BOPT[@]:4}
			echo Loading ${5//%20/ } ...
			set srvraddr ${_SRVR_PROT:?}://\${66}
			set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${4}
			set options \${autoinst} \${language} \${networks} \${otheropt}
			echo Loading boot files ...
			kernel \${knladdr}/${25#*/"${4}"/} \${options} --- quiet || goto error
			initrd \${knladdr}/${24#*/"${4}"/} || goto error
			boot || goto error
			exit
_EOT_
	fi
	unset __BOPT= __ENTR __CIDR __WORK
}
