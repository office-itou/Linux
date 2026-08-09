# shellcheck disable=SC2148

function fnMk_ipxe_booting() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# taget file

	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Interactive form block --------------------------------------------------
		:menu
		clear openmenu
		#prompt --key e --timeout \${optn-timeout} Press 'e' to open edit menu ... && goto reset ||
		goto input
		:setting
		set openmenu 1
		# --- Interactive form block (network parameters) -----------------------------
		:input
		set hostname \${hnameopt}
		set ethrname \${enameopt}
		set ipv4addr ${_IPV4_ADDR:-}
		set ipv4mask ${_IPV4_MASK:-}
		set ipv4gway ${_IPV4_GWAY:-}
		set ipv4nsvr ${_IPV4_NSVR:-}
		$(printf "%-47s %s" "form"                                          "Configure Network Options")
		$(printf "%-47s %s" "item hostname"                                 "Hostname")
		$(printf "%-47s %s" "item ethrname"                                 "Interface")
		$(printf "%-47s %s" "item ipv4addr"                                 "IPv4 address")
		$(printf "%-47s %s" "item ipv4mask"                                 "IPv4 netmask (example: 24 or 255.255.255.0)")
		$(printf "%-47s %s" "item ipv4gway"                                 "IPv4 gateway")
		$(printf "%-47s %s" "item ipv4nsvr"                                 "Name servers")
		isset \${openmenu} && present ||
		# --- cidr -> netmask ---------------------------------------------------------
		isset \${ipv4mask} || goto reset
		#iseq \${ipv4mask}  0 && set ipv4mask 0.0.0.0 ||
		#iseq \${ipv4mask}  1 && set ipv4mask 128.0.0.0 ||
		#iseq \${ipv4mask}  2 && set ipv4mask 192.0.0.0 ||
		#iseq \${ipv4mask}  3 && set ipv4mask 224.0.0.0 ||
		#iseq \${ipv4mask}  4 && set ipv4mask 240.0.0.0 ||
		#iseq \${ipv4mask}  5 && set ipv4mask 248.0.0.0 ||
		#iseq \${ipv4mask}  6 && set ipv4mask 252.0.0.0 ||
		#iseq \${ipv4mask}  7 && set ipv4mask 254.0.0.0 ||
		iseq  \${ipv4mask}  8 && set ipv4mask 255.0.0.0 ||
		iseq  \${ipv4mask}  9 && set ipv4mask 255.128.0.0 ||
		iseq  \${ipv4mask} 10 && set ipv4mask 255.192.0.0 ||
		iseq  \${ipv4mask} 11 && set ipv4mask 255.224.0.0 ||
		iseq  \${ipv4mask} 12 && set ipv4mask 255.240.0.0 ||
		iseq  \${ipv4mask} 13 && set ipv4mask 255.248.0.0 ||
		iseq  \${ipv4mask} 14 && set ipv4mask 255.252.0.0 ||
		iseq  \${ipv4mask} 15 && set ipv4mask 255.254.0.0 ||
		iseq  \${ipv4mask} 16 && set ipv4mask 255.255.0.0 ||
		iseq  \${ipv4mask} 17 && set ipv4mask 255.255.128.0 ||
		iseq  \${ipv4mask} 18 && set ipv4mask 255.255.192.0 ||
		iseq  \${ipv4mask} 19 && set ipv4mask 255.255.224.0 ||
		iseq  \${ipv4mask} 20 && set ipv4mask 255.255.240.0 ||
		iseq  \${ipv4mask} 21 && set ipv4mask 255.255.248.0 ||
		iseq  \${ipv4mask} 22 && set ipv4mask 255.255.252.0 ||
		iseq  \${ipv4mask} 23 && set ipv4mask 255.255.254.0 ||
		iseq  \${ipv4mask} 24 && set ipv4mask 255.255.255.0 ||
		iseq  \${ipv4mask} 25 && set ipv4mask 255.255.255.128 ||
		iseq  \${ipv4mask} 26 && set ipv4mask 255.255.255.192 ||
		iseq  \${ipv4mask} 27 && set ipv4mask 255.255.255.224 ||
		iseq  \${ipv4mask} 28 && set ipv4mask 255.255.255.240 ||
		iseq  \${ipv4mask} 29 && set ipv4mask 255.255.255.248 ||
		iseq  \${ipv4mask} 30 && set ipv4mask 255.255.255.252 ||
		iseq  \${ipv4mask} 31 && set ipv4mask 255.255.255.254 ||
		iseq  \${ipv4mask} 32 && set ipv4mask 255.255.255.255 ||
		# --- netmask -> cidr ---------------------------------------------------------
		clear ipv4cidr
		iseq  \${ipv4mask}   0.0.0.0       && set ipv4cidr  0 ||
		iseq  \${ipv4mask} 128.0.0.0       && set ipv4cidr  1 ||
		iseq  \${ipv4mask} 192.0.0.0       && set ipv4cidr  2 ||
		iseq  \${ipv4mask} 224.0.0.0       && set ipv4cidr  3 ||
		iseq  \${ipv4mask} 240.0.0.0       && set ipv4cidr  4 ||
		iseq  \${ipv4mask} 248.0.0.0       && set ipv4cidr  5 ||
		iseq  \${ipv4mask} 252.0.0.0       && set ipv4cidr  6 ||
		iseq  \${ipv4mask} 254.0.0.0       && set ipv4cidr  7 ||
		iseq  \${ipv4mask} 255.0.0.0       && set ipv4cidr  8 ||
		iseq  \${ipv4mask} 255.128.0.0     && set ipv4cidr  9 ||
		iseq  \${ipv4mask} 255.192.0.0     && set ipv4cidr 10 ||
		iseq  \${ipv4mask} 255.224.0.0     && set ipv4cidr 11 ||
		iseq  \${ipv4mask} 255.240.0.0     && set ipv4cidr 12 ||
		iseq  \${ipv4mask} 255.248.0.0     && set ipv4cidr 13 ||
		iseq  \${ipv4mask} 255.252.0.0     && set ipv4cidr 14 ||
		iseq  \${ipv4mask} 255.254.0.0     && set ipv4cidr 15 ||
		iseq  \${ipv4mask} 255.255.0.0     && set ipv4cidr 16 ||
		iseq  \${ipv4mask} 255.255.128.0   && set ipv4cidr 17 ||
		iseq  \${ipv4mask} 255.255.192.0   && set ipv4cidr 18 ||
		iseq  \${ipv4mask} 255.255.224.0   && set ipv4cidr 19 ||
		iseq  \${ipv4mask} 255.255.240.0   && set ipv4cidr 20 ||
		iseq  \${ipv4mask} 255.255.248.0   && set ipv4cidr 21 ||
		iseq  \${ipv4mask} 255.255.252.0   && set ipv4cidr 22 ||
		iseq  \${ipv4mask} 255.255.254.0   && set ipv4cidr 23 ||
		iseq  \${ipv4mask} 255.255.255.0   && set ipv4cidr 24 ||
		iseq  \${ipv4mask} 255.255.255.128 && set ipv4cidr 25 ||
		iseq  \${ipv4mask} 255.255.255.192 && set ipv4cidr 26 ||
		iseq  \${ipv4mask} 255.255.255.224 && set ipv4cidr 27 ||
		iseq  \${ipv4mask} 255.255.255.240 && set ipv4cidr 28 ||
		iseq  \${ipv4mask} 255.255.255.248 && set ipv4cidr 29 ||
		iseq  \${ipv4mask} 255.255.255.252 && set ipv4cidr 30 ||
		iseq  \${ipv4mask} 255.255.255.254 && set ipv4cidr 31 ||
		iseq  \${ipv4mask} 255.255.255.255 && set ipv4cidr 32 ||
		isset \${ipv4cidr} || goto reset
		# --- network parameters ------------------------------------------------------
		iseq \${distribution} debian       && set nworkopt netcfg/disable_autoconfig=true netcfg/choose_interface=\${ethrname} netcfg/get_hostname=\${hostname} netcfg/get_ipaddress=\${ipv4addr}/\${ipv4cidr} netcfg/get_netmask=\${ipv4mask} netcfg/get_gateway=\${ipv4gway} netcfg/get_nameservers=\${ipv4nsvr} ||
		iseq \${distribution} ubuntu       && set nworkopt ip=\${ipv4addr}:\${rootserv}:\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:static:\${ipv4nsvr} ||
		iseq \${distribution} fedora       && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} centos       && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} almalinux    && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} rockylinux   && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} miraclelinux && set nworkopt ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr} ||
		iseq \${distribution} opensuse     && set nworkopt netsetup=dhcp hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr}/\${ipv4cidr},\${ipv4gway},\${ipv4nsvr},workgroup ||
		# --- Interactive form block (other parameters) -------------------------------
		set autoinst \${parmauto}
		set language \${languopt}
		set otherprm \${otheropt}
		set networks \${nworkopt}
		set debugprm \${debugopt}
		$(printf "%-47s %s" "form"                                          "Configure Autoinstall Options")
		$(printf "%-47s %s" "item autoinst"                                 "Auto install")
		$(printf "%-47s %s" "item language"                                 "Language")
		$(printf "%-47s %s" "item networks"                                 "Network")
		$(printf "%-47s %s" "item otherprm"                                 "Other options")
		$(printf "%-47s %s" "item debugprm"                                 "Debug options")
		isset \${openmenu} && present ||
		isset \${autoinst} && clear debugprm ||
		# --- check block -------------------------------------------------------------
		:check
		menu Select the next action
		$(printf "%-47s %s" "item --gap --"                                 "Hostname: ------> \${hostname}")
		$(printf "%-47s %s" "item --gap --"                                 "Interface: -----> \${ethrname}")
		$(printf "%-47s %s" "item --gap --"                                 "IPv4 address: --> \${ipv4addr}/\${ipv4cidr}")
		$(printf "%-47s %s" "item --gap --"                                 "IPv4 netmask: --> \${ipv4mask}")
		$(printf "%-47s %s" "item --gap --"                                 "IPv4 gateway: --> \${ipv4gway}")
		$(printf "%-47s %s" "item --gap --"                                 "Names ervers: --> \${ipv4nsvr}")
		$(printf "%-47s %s" "item --gap --"                                 "Auto instal: ---> \${autoinst}")
		$(printf "%-47s %s" "item --gap --"                                 "Language: ------> \${language}")
		$(printf "%-47s %s" "item --gap --"                                 "Network: -------> \${networks}")
		$(printf "%-47s %s" "item --gap --"                                 "Other options: -> \${otherprm}")
		$(printf "%-47s %s" "item --gap --"                                 "Debug options: -> \${debugprm}")
		item --gap --
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "item --gap --"                                 "[ Action ]")
		$(printf "%-47s %s" "item -- booting"                               "- OS booting")
		$(printf "%-47s %s" "item -- setting"                               "- Set parameters")
		choose --timeout \${menu-timeout} --default \${menu-default} selected && goto \${selected}
		goto check
		# --- booting block -----------------------------------------------------------
		:booting
		set options \${autoinst} \${language} \${networks} \${otherprm} \${debugprm}
		echo \${messages}
		echo Loading boot files ...
		kernel \${kernlopt} \${options} || goto error
		initrd \${inirdopt} || goto error
		boot || goto error
		exit

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
