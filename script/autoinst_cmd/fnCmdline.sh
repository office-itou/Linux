# shellcheck disable=SC2148

	# --- boot parameter selection --------------------------------------------
	for __LINE in ${_COMD_LINE:-} ${_PROG_PARM:-}
	do
		case "${__LINE}" in
			debug    | dbg                ) _DBGS_FLAG="true"; set -x;;
			debugout | dbgout             ) _DBGS_FLAG="true";;
			target=*                      ) _DIRS_TGET="${__LINE#*target=}";;
			iso-url=*.iso  | url=*.iso    ) _FILE_ISOS="${__LINE#*url=}";;
			preseed/url=*  | url=*        ) _FILE_SEED="${__LINE#*url=}";;
			preseed/file=* | file=*       ) _FILE_SEED="${__LINE#*file=}";;
			ds=nocloud*                   ) _FILE_SEED="${__LINE#*ds=nocloud*=}";_FILE_SEED="${_FILE_SEED%%/}/user-data";;
			inst.ks=*                     ) _FILE_SEED="${__LINE#*inst.ks=}";;
			autoyast=*                    ) _FILE_SEED="${__LINE#*autoyast=}";;
			inst.auto=*                   ) _FILE_SEED="${__LINE#*inst.auto=}";;
			netcfg/target_network_config=*) _NMAN_FLAG="${__LINE#*target_network_config=}";;
			netcfg/choose_interface=*     ) _NICS_NAME="${__LINE#*choose_interface=}";;
			netcfg/disable_dhcp=*         ) _IPV4_DHCP="$([ "${__LINE#*disable_dhcp=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/disable_autoconfig=*   ) _IPV4_DHCP="$([ "${__LINE#*disable_autoconfig=}" = "true" ] && echo "false" || echo "true")";;
			netcfg/get_ipaddress=*        ) _NICS_IPV4="${__LINE#*get_ipaddress=}";;
			netcfg/get_netmask=*          ) _NICS_MASK="${__LINE#*get_netmask=}";;
			netcfg/get_gateway=*          ) _NICS_GATE="${__LINE#*get_gateway=}";;
			netcfg/get_nameservers=*      ) _NICS_DNS4="${__LINE#*get_nameservers=}";;
			netcfg/get_hostname=*         ) _NICS_FQDN="${__LINE#*get_hostname=}";;
			netcfg/get_domain=*           ) _NICS_WGRP="${__LINE#*get_domain=}";;
			interface=*                   ) _NICS_NAME="${__LINE#*interface=}";;
			hostname=*                    ) _NICS_FQDN="${__LINE#*hostname=}";;
			domain=*                      ) _NICS_WGRP="${__LINE#*domain=}";;
			nameserver=*                  ) _NICS_DNS4="${__LINE#*nameserver=}";;
			ip=dhcp | ip4=dhcp | ipv4=dhcp) _IPV4_DHCP="true";;
			ip=* | ip4=* | ipv4=*         ) _IPV4_DHCP="false"
			                                _NICS_IPV4="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 1)"
			                                _NICS_GATE="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 3)"
			                                _NICS_MASK="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 4)"
			                                _NICS_FQDN="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 5)"
			                                _NICS_NAME="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 6)"
			                                _NICS_DNS4="$(echo "${__LINE#*ip*=}" | cut -d ':' -f 8)"
			                                ;;
			ifcfg=*                       ) _NICS_NAME="$(echo "${__LINE#*ifcfg*=}" | cut -d '=' -f 1)"
			                                _NICS_IPV4="$(echo "${__LINE#*=*=}" | cut -d ',' -f 1)"
			                                case "${_NICS_IPV4:-}" in
			                                     dhcp6)
			                                        _IPV4_DHCP=""
			                                        _NICS_IPV4=""
			                                        _NICS_GATE=""
			                                        _NICS_DNS4=""
			                                        _NICS_WGRP=""
			                                        ;;
			                                     dhcp|dhcp4)
			                                        _IPV4_DHCP="true"
			                                        _NICS_IPV4=""
			                                        _NICS_GATE=""
			                                        _NICS_DNS4=""
			                                        _NICS_WGRP=""
			                                        ;;
			                                     *)
			                                        _IPV4_DHCP="false"
			                                        _NICS_IPV4="$(echo "${__LINE#*=*=}," | cut -d ',' -f 1)"
			                                        _NICS_GATE="$(echo "${__LINE#*=*=}," | cut -d ',' -f 2)"
			                                        _NICS_DNS4="$(echo "${__LINE#*=*=}," | cut -d ',' -f 3)"
			                                        _NICS_WGRP="$(echo "${__LINE#*=*=}," | cut -d ',' -f 4)"
			                                        ;;
			                                esac
			                                ;;
			*) ;;
		esac
	done
