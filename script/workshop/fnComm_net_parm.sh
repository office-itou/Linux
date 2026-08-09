# shellcheck disable=SC2148

function fnMk_net_parm() {
	declare -r    __TGET_DIST="${1:?}"		# distribution
	declare       __NWRK=""				# network parameters

	# --- network parameters --------------------------------------------------
	case "${__TGET_DIST:-}" in
		debian*      ) __NWRK="netcfg/disable_autoconfig=true netcfg/choose_interface=\${ethrname} netcfg/get_hostname=\${hostname} netcfg/get_ipaddress=\${ipv4addr}/\${ipv4cidr} netcfg/get_netmask=\${ipv4mask} netcfg/get_gateway=\${ipv4gway} netcfg/get_nameservers=\${ipv4nsvr}";;
		ubuntu*      ) __NWRK="ip=\${ipv4addr}:\${rootserv}:\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:static:\${ipv4nsvr}";;
		fedora*      | \
		centos*      | \
		almalinux*   | \
		rockylinux*  | \
		miraclelinux*) __NWRK="ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr}";;
		opensuse*    ) __NWRK="netsetup=dhcp hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr}/\${ipv4cidr},\${ipv4gway},\${ipv4nsvr},workgroup";;
		*) ;;
	esac
	echo "${__NWRK:?}"
}
