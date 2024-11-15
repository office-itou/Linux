#!/bin/sh

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
#	set -o ignoreeof					# Do not exit with Ctrl+D
#	set +m								# Disable job control
#	set -e								# End with status other than 0
#	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error
#	set -o allexport					# Enable export

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

#	readonly    _PROG_PATH="$0"
	readonly    _PROG_PATH="0000-user-hook.sh"
#	readonly    _PROG_DIRS="${_PROG_PATH%/*}"
	readonly    _PROG_NAME="${_PROG_PATH##*/}"

# *****************************************************************************
# start
# *****************************************************************************

	# --- start ---------------------------------------------------------------
	printf "\n" | tee /dev/console 2>&1
	if [ -f "/var/lib/live/config/${_PROG_NAME%.*}" ]; then
		printf "\033[m\033[41malready runned: %s\033[m\n" "${_PROG_PATH}" | tee /dev/console 2>&1
		return
	fi

	printf "\033[m\033[45mstart: %s\033[m\n" "${_PROG_PATH}" | tee /dev/console 2>&1

# *****************************************************************************
# common parameter
# *****************************************************************************

	# --- set system parameter ------------------------------------------------
	_DEBUGOUT=""
	_DISTRIBUTION="$(lsb_release -is | tr '[:upper:]' '[:lower:]' | sed -e 's| |-|g')"
	_RELEASE="$(lsb_release -rs | tr '[:upper:]' '[:lower:]')"
	_CODENAME="$(lsb_release -cs | tr '[:upper:]' '[:lower:]')"

	# --- set network parameter -----------------------------------------------
	_NETWORK="dhcp"
	_DNSSRCH=""
	_UTC="yes"
	_NTP="ntp.nict.jp"
	_FBACK_NTP="ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp"
	_HOSTNAME="${_DISTRIBUTION:+live-${_DISTRIBUTION}}"

	# --- set user parameter --------------------------------------------------
	_USERNAME="user"					# default user id
	_PASSWORD="live"					# default user password
	_FULLNAME="${_DISTRIBUTION} Live user}"
	_USER_DEFAULT_GROUPS="audio cdrom dip floppy video plugdev netdev powerdev scanner bluetooth debian-tor"
	_USER_DEFAULT_GROUPS="${_USER_DEFAULT_GROUPS:+"${_USER_DEFAULT_GROUPS} "}lp pulse pipewire"
	_LOCALES="ja_JP.UTF-8"
	_TIMEZONE="Asia/Tokyo"
	_KEYBOARD_MODEL="pc105"
	_KEYBOARD_LAYOUTS="jp"
	_KEYBOARD_VARIANTS="OADG109A"
	_KEYBOARD_OPTIONS=""
	_XORG_RESOLUTION="1680x1050"

	# --- set vmware parameter ------------------------------------------------
	_HGFS="/mnt/hgfs"

# *****************************************************************************
# common functions
# *****************************************************************************

# --- function is package -----------------------------------------------------
funcIsPackage () {
	LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed'
}

# --- function IPv4 cidr conversion -------------------------------------------
funcIPv4GetNetCIDR() {
	__NIFC_MASK="$1"
	__NIFC_BIT4=0
	for __OCTETS in $(echo "${__NIFC_MASK}" | sed -e 's/\./ /g')
	do
		case "${__OCTETS}" in
			  0) __NIFC_BIT4=$((__NIFC_BIT4+0));;
			128) __NIFC_BIT4=$((__NIFC_BIT4+1));;
			192) __NIFC_BIT4=$((__NIFC_BIT4+2));;
			224) __NIFC_BIT4=$((__NIFC_BIT4+3));;
			240) __NIFC_BIT4=$((__NIFC_BIT4+4));;
			248) __NIFC_BIT4=$((__NIFC_BIT4+5));;
			252) __NIFC_BIT4=$((__NIFC_BIT4+6));;
			254) __NIFC_BIT4=$((__NIFC_BIT4+7));;
			255) __NIFC_BIT4=$((__NIFC_BIT4+8));;
			*  ) ;;
		esac
	done
	echo "${__NIFC_BIT4}"
}

# --- function systemctl ------------------------------------------------------
#funcSystemctl () {
#	__OPTIONS="$1"
#	__COMMAND="$2"
#	__UNITS="$3"
#	__PARM="$(echo "${__UNITS}" | sed -e 's/ /|/g')"
#	# shellcheck disable=SC2086
#	__RETURN_VALUE="$(systemctl ${__OPTIONS} list-unit-files ${__UNITS} | awk '$0~/'"${__PARM}"'/ {print $1;}')"
#	if [ -n "${__RETURN_VALUE:-}" ]; then
#		# shellcheck disable=SC2086
#		systemctl ${__OPTIONS} "${__COMMAND}" ${__RETURN_VALUE}
#	fi
#}

# *****************************************************************************
# set parameter
# *****************************************************************************

funcSetParameter () {
	# --- set boot parameter --------------------------------------------------
	_CMDLINE="$(cat /proc/cmdline)"
	for _PARAMETER in ${_CMDLINE:-}
	do
		case "${_PARAMETER}" in
#			live-config.components=*          | components=*          ) _CONFIG_COMPONENTS="${_PARAMETER#*components=}";;
#			live-config.debconf-preseed=*     | debconf-preseed=*     ) _DEBCONF_PRESEED="${_PARAMETER#*debconf-preseed=}";;
			live-config.debug                 | debug                 ) _DEBUGOUT="true";;
			live-config.debugchk              | debugchk              ) _DEBUGOUT="true";;
			live-config.debugout              | debugout              ) _DEBUGOUT="true";;
			live-config.debugout=*            | debugout=*            ) _DEBUGOUT="${_PARAMETER#*debugout=}";;
			live-config.emptypwd              | emptypwd              ) _PASSWORD="";;
#			live-config.hooks=*               | hooks=*               ) _HOOKS="${_PARAMETER#*hooks=}";;
			live-config.hostname=*            | hostname=*            ) _HOSTNAME="${_PARAMETER#*hostname=}";;
			live-config.key_layouts=*         | key_layouts=*         ) _KEYBOARD_LAYOUTS="${_PARAMETER#*key_layouts=}";;
			live-config.keyboard-layouts=*    | keyboard-layouts=*    ) _KEYBOARD_LAYOUTS="${_PARAMETER#*keyboard-layouts=}";;
			live-config.key_model=*           | key_model=*           ) _KEYBOARD_MODEL="${_PARAMETER#*key_model=}";;
			live-config.keyboard-model=*      | keyboard-model=*      ) _KEYBOARD_MODEL="${_PARAMETER#*keyboard-model=}";;
			live-config.key_options=*         | key_options=*         ) _KEYBOARD_OPTIONS="${_PARAMETER#*key_options=}";;
			live-config.keyboard-options=*    | keyboard-options=*    ) _KEYBOARD_OPTIONS="${_PARAMETER#*keyboard-options=}";;
			live-config.key_variants=*        | key_variants=*        ) _KEYBOARD_VARIANTS="${_PARAMETER#*key_variants=}";;
			live-config.keyboard-variants=*   | keyboard-variants=*   ) _KEYBOARD_VARIANTS="${_PARAMETER#*keyboard-variants=}";;
			live-config.locales=*             | locales=*             ) _LOCALES="${_PARAMETER#*locales=}";;
#			live-config.noautologin           | noautologin           ) _CONFIG_NOAUTOLOGIN="true";;
#			live-config.nocomponents=*        | nocomponents=*        ) _CONFIG_NOCOMPONENTS="${_PARAMETER#*nocomponents=}";;
#			live-config.noroot                | noroot                ) _CONFIG_NOROOT="true";;
#			live-config.nox11autologin        | nox11autologin        ) _CONFIG_NOX11AUTOLOGIN="true";;
			live-config.password=*            | password=*            ) _PASSWORD="${_PARAMETER#*password=}";;
#			live-config.sysv-rc=*             | sysv-rc=*             ) _SYSV_RC="${_PARAMETER#*sysv-rc=}";;
			live-config.timezone=*            | timezone=*            ) _TIMEZONE="${_PARAMETER#*timezone=}";;
			live-config.user-default-groups=* | user-default-groups=* ) _USER_DEFAULT_GROUPS="${_PARAMETER#*user-default-groups=}";;
			live-config.user-fullname=*       | user-fullname=*       ) _USER_FULLNAME="${_PARAMETER#*user-fullname=}";;
			live-config.username=*            | username=*            ) _USERNAME="${_PARAMETER#*username=}";;
			live-config.utc=*                 | utc=*                 ) _UTC="${_PARAMETER#*utc=}";;
#			live-config.wlan-driver=*         | wlan-driver=*         ) _WLAN_DRIVER="${_PARAMETER#*wlan-driver=}";;
#			live-config.x-session-manager=*   | x-session-manager=*   ) _X_SESSION_MANAGER="${_PARAMETER#*x-session-manager=}";;
#			live-config.xorg-driver=*         | xorg-driver=*         ) _XORG_DRIVER="${_PARAMETER#*xorg-driver=}";;
			live-config.xorg-resolution=*     | xorg-resolution=*     ) _XORG_RESOLUTION="${_PARAMETER#*xorg-resolution=}";;
			live-config.xresolution=*         | xresolution=*         ) _XORG_RESOLUTION="${_PARAMETER#*xresolution=}";;
			live-config.ip=*                  | ip=*                  ) _NETWORK="${_PARAMETER#*ip=}";;
			live-config.dns-search=*          | dns-search=*          ) _DNSSRCH="${_PARAMETER#*dns-search=}";;
			live-config.ntp=*                 | ntp=*                 ) _NTP="${_PARAMETER#*ntp=}";;
			live-config.fallback-ntp=*        | fallback-ntp=*        ) _FBACK_NTP="${_PARAMETER#*fallback-ntp=}";;
			live-config.hgfs=*                | hgfs=*                ) _HGFS="${_PARAMETER#*hgfs=}";;
			*) ;;
		esac
	done
}

# *****************************************************************************
# debug out
# *****************************************************************************

funcDebugOut () {
	if [ -n "${_DEBUGOUT}" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | tee /dev/console 2>&1
			# *** the default value for this script ************************************* #
			# --- the parameters of this script ----------------------------------------- #
			\$0                                      = [${0:-}]
			_PROG_PATH                              = [${_PROG_PATH:-}]
			_PROG_DIRS                              = [${_PROG_DIRS:-}]
			_PROG_NAME                              = [${_PROG_NAME:-}]
			# --- set system parameter -------------------------------------------------- #
			_DEBUGOUT                               = [${_DEBUGOUT:-}]
			_DISTRIBUTION                           = [${_DISTRIBUTION:-}]
			_RELEASE                                = [${_RELEASE:-}]
			_CODENAME                               = [${_CODENAME:-}]
			# --- set boot parameter ---------------------------------------------------- #
			_CMDLINE                                = [${_CMDLINE:-}]
			# --- set network parameter ------------------------------------------------- #
			_NETWORK                                = [${_NETWORK:-}]
			_DNSSRCH                                = [${_DNSSRCH:-}]
			_UTC                                    = [${_UTC:-}]
			_NTP                                    = [${_NTP:-}]
			_FBACK_NTP                              = [${_FBACK_NTP:-}]
			_HOSTNAME                               = [${_HOSTNAME:-}]
			# --- set user parameter ---------------------------------------------------- #
			_USERNAME                               = [${_USERNAME:-}]
			_PASSWORD                               = [${_PASSWORD:-}]
			_FULLNAME                               = [${_FULLNAME:-}]
			_USER_DEFAULT_GROUPS                    = [${_USER_DEFAULT_GROUPS:-}]
			_LOCALES                                = [${_LOCALES:-}]
			_TIMEZONE                               = [${_TIMEZONE:-}]
			_KEYBOARD_MODEL                         = [${_KEYBOARD_MODEL:-}]
			_KEYBOARD_LAYOUTS                       = [${_KEYBOARD_LAYOUTS:-}]
			_KEYBOARD_VARIANTS                      = [${_KEYBOARD_VARIANTS:-}]
			_KEYBOARD_OPTIONS                       = [${_KEYBOARD_OPTIONS:-}]
			_XORG_RESOLUTION                        = [${_XORG_RESOLUTION:-}]
			# --- set vmware parameter -------------------------------------------------- #
			_HGFS                                   = [${_HGFS:-}]
			# *** exported live values ************************************************** #
			# --- live-boot - System Boot Components ------------------------------------ #
			# https://manpages.debian.org/bookworm/live-boot-doc/index.html
			# /etc/live/boot.conf
			# /etc/live/boot/*
			# (media)/live/boot.conf
			# (media)/live/boot/*
			DISABLE_CDROM                            = [${DISABLE_CDROM:-}]
			DISABLE_DM_VERITY                        = [${DISABLE_DM_VERITY:-}]
			DISABLE_FAT                              = [${DISABLE_FAT:-}]
			DISABLE_FUSE                             = [${DISABLE_FUSE:-}]
			DISABLE_NTFS                             = [${DISABLE_NTFS:-}]
			DISABLE_USB                              = [${DISABLE_USB:-}]
			MINIMAL                                  = [${MINIMAL:-}]
			PERSISTENCE_FSCK                         = [${PERSISTENCE_FSCK:-}]
			FSCKFIX                                  = [${FSCKFIX:-}]
			LIVE_BOOT_CMDLINE                        = [${LIVE_BOOT_CMDLINE:-}]
			LIVE_BOOT_DEBUG                          = [${LIVE_BOOT_DEBUG:-}]
			LIVE_MEDIA                               = [${LIVE_MEDIA:-}]
			LIVE_MEDIA_OFFSET                        = [${LIVE_MEDIA_OFFSET:-}]
			LIVE_MEDIA_PATH                          = [${LIVE_MEDIA_PATH:-}]
			LIVE_MEDIA_TIMEOUT                       = [${LIVE_MEDIA_TIMEOUT:-}]
			LIVE_PERSISTENCE_REMOVE                  = [${LIVE_PERSISTENCE_REMOVE:-}]
			LIVE_READ_ONLY                           = [${LIVE_READ_ONLY:-}]
			LIVE_READ_ONLY_DEVICES                   = [${LIVE_READ_ONLY_DEVICES:-}]
			LIVE_SWAP                                = [${LIVE_SWAP:-}]
			LIVE_SWAP_DEVICES                        = [${LIVE_SWAP_DEVICES:-}]
			LIVE_VERIFY_CHECKSUMS                    = [${LIVE_VERIFY_CHECKSUMS:-}]
			LIVE_VERIFY_CHECKSUMS_DIGESTS            = [${LIVE_VERIFY_CHECKSUMS_DIGESTS:-}]
			# --- live-config - System Configuration Components ------------------------- #
			# https://manpages.debian.org/bookworm/live-config-doc/live-config.7.en.html
			# open-infrastructure-system-boot & open-infrastructure-system-config
			#   /etc/live/config.conf
			#   /etc/live/config.conf.d/*.conf
			#   (media)live/config.conf
			#   (media)live/config.conf.d/*.conf
			# live-boot & live-config
			#   (media)live/config-preseed/*     : /usr/lib/live/config/0010-debconf
			#   (media)live/config-hooks/*       : /usr/lib/live/config/9990-hooks
			#   (media)live/config.conf          : /usr/lib/live/init-config.sh
			#   (media)live/config.conf.d/*.conf : 
			LIVE_CONFIG_CMDLINE                     = [${LIVE_CONFIG_CMDLINE:-}]
			LIVE_CONFIG_COMPONENTS                  = [${LIVE_CONFIG_COMPONENTS:-}]
			LIVE_CONFIG_NOCOMPONENTS                = [${LIVE_CONFIG_NOCOMPONENTS:-}]
			LIVE_DEBCONF_PRESEED                    = [${LIVE_DEBCONF_PRESEED:-}]
			LIVE_HOSTNAME                           = [${LIVE_HOSTNAME:-}]
			LIVE_USERNAME                           = [${LIVE_USERNAME:-}]
			LIVE_USER_DEFAULT_GROUPS                = [${LIVE_USER_DEFAULT_GROUPS:-}]
			LIVE_USER_FULLNAME                      = [${LIVE_USER_FULLNAME:-}]
			LIVE_LOCALES                            = [${LIVE_LOCALES:-}]
			LIVE_TIMEZONE                           = [${LIVE_TIMEZONE:-}]
			LIVE_KEYBOARD_MODEL                     = [${LIVE_KEYBOARD_MODEL:-}]
			LIVE_KEYBOARD_LAYOUTS                   = [${LIVE_KEYBOARD_LAYOUTS:-}]
			LIVE_KEYBOARD_VARIANTS                  = [${LIVE_KEYBOARD_VARIANTS:-}]
			LIVE_KEYBOARD_OPTIONS                   = [${LIVE_KEYBOARD_OPTIONS:-}]
			LIVE_SYSV_RC                            = [${LIVE_SYSV_RC:-}]
			LIVE_UTC                                = [${LIVE_UTC:-}]
			LIVE_X_SESSION_MANAGER                  = [${LIVE_X_SESSION_MANAGER:-}]
			LIVE_XORG_DRIVER                        = [${LIVE_XORG_DRIVER:-}]
			LIVE_XORG_RESOLUTION                    = [${LIVE_XORG_RESOLUTION:-}]
			LIVE_WLAN_DRIVER                        = [${LIVE_WLAN_DRIVER:-}]
			LIVE_HOOKS                              = [${LIVE_HOOKS:-}]
			LIVE_CONFIG_DEBUG                       = [${LIVE_CONFIG_DEBUG:-}]
			LIVE_CONFIG_NOROOT                      = [${LIVE_CONFIG_NOROOT:-}]
			LIVE_CONFIG_NOAUTOLOGIN                 = [${LIVE_CONFIG_NOAUTOLOGIN:-}]
			LIVE_CONFIG_NOX11AUTOLOGIN              = [${LIVE_CONFIG_NOX11AUTOLOGIN:-}]
			# *** end of list *********************************************************** #
_EOT_
	fi
}

# *****************************************************************************
# hook processing
# *****************************************************************************

# --- function set network interfaces -----------------------------------------
# https://wiki.archlinux.org/title/Systemd-networkd
# https://wiki.archlinux.jp/index.php/Systemd-networkd
funcSetNIFfile () {
	___NIFC_NAME="$1"
	___NIFC_IPV4="${2%%/*}"
	___NIFC_BIT4="${2#*/}"
	___NIFC_MASK="$3"
	___NIFC_GATE="$4"
	___NIFC_DNS4="$5"
	___NIFC_WGRP="$6"
	___FLAG_NMAN="$7"
	# -------------------------------------------------------------------------
	___FILE_PATH="/etc/network/interfaces"
	mkdir -p "${___FILE_PATH%/*}"
	# -------------------------------------------------------------------------
	if [ "${___NIFC_NAME}" = "lo" ] \
	|| [ ! -s "${___FILE_PATH}" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___FILE_PATH}"
			source /etc/network/interfaces.d/*
			
_EOT_
	fi
	if [ -n "${___FLAG_NMAN}" ]; then
		return
	fi
	case "${___NIFC_NAME}" in
		lo)
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
				# The loopback network interface
				auto lo
				iface lo inet loopback
				
_EOT_
			;;
		*)
			if ! grep -E '^iface +(eth|en.|wlan|ath)[0-9]+ +.*$' /etc/network/interfaces; then
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
					# The primary network interface
_EOT_
			fi
			if [ "${___NIFC_IPV4}" = "dhcp" ]; then
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
					allow-hotplug ${___NIFC_NAME}
					iface ${___NIFC_NAME} inet dhcp
					
_EOT_
			else
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
					allow-hotplug ${___NIFC_NAME}
					iface ${___NIFC_NAME} inet static
					    address ${___NIFC_IPV4}/${___NIFC_BIT4}
_EOT_
				if [ -n "${___NIFC_GATE}" ]; then
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
					    gateway ${___NIFC_GATE}
_EOT_
				fi
				if [ -n "${___NIFC_DNS4}" ] || [ -n "${___NIFC_WGRP}" ]; then
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
						    # dns-* options are implemented by the resolvconf package, if installed
_EOT_
				fi
				if [ -n "${___NIFC_DNS4}" ]; then
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
						    dns-nameservers ${___NIFC_DNS4}
_EOT_
				fi
				if [ -n "${___NIFC_WGRP}" ]; then
					cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
						    dns-search ${___NIFC_WGRP}
_EOT_
				fi
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
					
_EOT_
			fi
#			ifdown -f "${___NIFC_NAME}" || true
#			ifup   -f "${___NIFC_NAME}" || true
			;;
	esac
#	chmod 600 "${___FILE_PATH}"
#	chmod 700 "${___FILE_PATH%/*}"
}

# --- function set connection manager -----------------------------------------
funcSetConnman () {
	___NIFC_NAME="$1"
	___NIFC_IPV4="${2%%/*}"
	___NIFC_BIT4="${2#*/}"
	___NIFC_MASK="$3"
	___NIFC_GATE="$4"
	___NIFC_DNS4="$5"
	___NIFC_WGRP="$6"
	___NIFC_MADR="$7"
	___NIFC_NTPA="$8"
	___NIFC_MAID="$(echo "${___NIFC_MADR}" | sed -e 's/://g')"
	___NIFC_TECH=""
	case "${___NIFC_NAME}" in
		lo   ) ;;
		eth* ) ___NIFC_TECH="ethernet_${___NIFC_MAID}_cable";;
		ath* ) ;;
		wlan*) ;;
		en*  ) ___NIFC_TECH="ethernet_${___NIFC_MAID}_cable";;
		*    ) ;;
	esac
	# -------------------------------------------------------------------------
	___FILE_PATH="/var/lib/connman/${___NIFC_TECH}/settings"
	mkdir -p "${___FILE_PATH%/*}"
	# -------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___FILE_PATH}"
		[${___NIFC_TECH}]
		Name=Wired
		AutoConnect=true
		Modified=
_EOT_
	if [ "${___NIFC_IPV4}" = "dhcp" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
			IPv4.method=dhcp
			IPv4.DHCP.LastAddress=
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
			IPv4.method=manual
			IPv4.netmask_prefixlen=${___NIFC_BIT4}
			IPv4.local_address=${___NIFC_IPV4}
			IPv4.gateway=${___NIFC_GATE}
_EOT_
	fi
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
		IPv6.method=auto
		IPv6.privacy=preferred
		Nameservers=${___NIFC_DNS4};
		Timeservers=${___NIFC_NTPA};
		mDNS=true
		Domains=${___NIFC_WGRP};
		IPv6.DHCP.DUID=
_EOT_
	chmod 600 "${___FILE_PATH}"
	chmod 700 "${___FILE_PATH%/*}"
}

# --- function set YAML network configuration ---------------------------------
funcSetNetplan () {
	___NIFC_NAME="$1"
	___NIFC_IPV4="${2%%/*}"
	___NIFC_BIT4="${2#*/}"
	___NIFC_MASK="$3"
	___NIFC_GATE="$4"
	___NIFC_DNS4="$5"
	___NIFC_WGRP="$6"
	___FLAG_NMAN="$7"
	___NIFC_IPV6="$8"
	# -------------------------------------------------------------------------
	if [ "${___NIFC_IPV4}" = "dhcp" ]; then
		___FILE_PATH="/etc/netplan/50-dhcp.yaml"
	else
		___FILE_PATH="/etc/netplan/50-static.yaml"
	fi
#	if [ -n "${___FLAG_NMAN}" ]; then
#		___FILE_PATH="/etc/netplan/00-network-manager.yaml"
#	else
#		___FILE_PATH="/etc/netplan/00-networkd.yaml"
#	fi
	mkdir -p "${___FILE_PATH%/*}"
	# -------------------------------------------------------------------------
	if [ -n "${___FLAG_NMAN}" ]; then
		___NIFC_NMAN="NetworkManager"
	else
		___NIFC_NMAN="networkd"
	fi
	# -------------------------------------------------------------------------
	if [ ! -s "${___FILE_PATH}" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___FILE_PATH}"
			network:
			  version: 2
			  ethernets:
_EOT_
	fi
	if [ "${___NIFC_NAME}" = "lo" ]; then
		return
	fi
	if [ "${___NIFC_IPV4}" = "dhcp" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
			    ${___NIFC_NAME}:
			      match:
			        name: ${___NIFC_NAME}
			      dhcp4: true
			      dhcp6: true
			      ipv6-privacy: true
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
			    ${___NIFC_NAME}:
			      match:
			        name: ${___NIFC_NAME}
			      addresses:
			      - "${___NIFC_IPV4}/${___NIFC_BIT4}${___NIFC_GATE:+,${___NIFC_GATE}}"
_EOT_
		if [ -n "${___NIFC_DNS4}" ] || [ -n "${___NIFC_WGRP}" ]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
				      nameservers:
_EOT_
		fi
		if [ -n "${___NIFC_WGRP}" ]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
				        search:
_EOT_
			for ___LINE in $(echo "${___NIFC_WGRP}" | sed -e 's/[;,|]/ /g')
			do
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
					        - ${___LINE}
_EOT_
			done
		fi
		if [ -n "${___NIFC_DNS4}" ]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
				        addresses:
_EOT_
			for ___LINE in $(echo "${___NIFC_DNS4}" | sed -e 's/[;,|]/ /g')
			do
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
					        - ${___LINE}
_EOT_
			done
		fi
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
			      dhcp6: true
			      ipv6-privacy: true
_EOT_
	fi
	chmod 600 "${___FILE_PATH}"
	chmod 700 "${___FILE_PATH%/*}"
}

# --- function set network manager --------------------------------------------
funcSetNetmana () {
	___NIFC_NAME="$1"
	___NIFC_IPV4="${2%%/*}"
	___NIFC_BIT4="${2#*/}"
	___NIFC_MASK="$3"
	___NIFC_GATE="$4"
	___NIFC_DNS4="$5"
	___NIFC_WGRP="$6"
	___NIFC_MADR="$7"
	___NIFC_MAID="$(echo "${___NIFC_MADR}" | sed -e 's/://g')"
	# -------------------------------------------------------------------------
	___NIFC_NMID="${___NIFC_NAME}.nmconnection"
	___FILE_PATH="/etc/NetworkManager/system-connections/${___NIFC_NMID}"
	mkdir -p "${___FILE_PATH%/*}"
	# -------------------------------------------------------------------------
	if [ -d /etc/netplan/. ]; then
		if ! grep -q 'NetworkManager' /etc/netplan/*; then
			___FILE_PATH="/etc/netplan/00-network-manager.yaml"
			if [ ! -s "${___FILE_PATH}" ]; then
				mkdir -p "${___FILE_PATH%/*}"
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___FILE_PATH}"
					network:
					  version: 2
					  renderer: NetworkManager
_EOT_
			fi
			# -----------------------------------------------------------------
			chmod 600 "${___FILE_PATH}"
			chmod 700 "${___FILE_PATH%/*}"
			# -----------------------------------------------------------------
		fi
		return
#		if grep -q "${___NIFC_NAME}" /etc/netplan/*; then
#			___FILE_PATH="/run/NetworkManager/system-connections/netplan-${___NIFC_NAME}.nmconnection"
#		fi
	fi
	# -------------------------------------------------------------------------
	if [ "${___NIFC_NAME}" = "lo" ]; then
		return
	fi
	# -------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___FILE_PATH}"
		[connection]
		id=${___NIFC_NMID%%.*}
		uuid=
		type=ethernet
		interface-name=${___NIFC_NAME}
		timestamp=
		autoconnect=true
		zone=home
		
		[ethernet]
		mac-address=${___NIFC_MADR}
		
_EOT_
	# -------------------------------------------------------------------------
	if [ "${___NIFC_IPV4}" = "dhcp" ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
			[ipv4]
			method=auto
			
_EOT_
	else
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
			[ipv4]
			address1=${___NIFC_IPV4}/${___NIFC_BIT4},${___NIFC_GATE}
			dns=${___NIFC_DNS4};
			dns-search=${___NIFC_WGRP};
			method=manual
			
_EOT_
	fi
	# -------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
		[ipv6]
		addr-gen-mode=stable-privacy
		method=auto
		
		[proxy]
		
_EOT_
	chmod 600 "${___FILE_PATH}"
	chmod 700 "${___FILE_PATH%/*}"
}

# --- function set /etc/resolv.conf -------------------------------------------
funcSetResolv () {
	___NIFC_DNS4="$1"
	___NIFC_WGRP="$2"
	___FILE_PATH="/etc/resolv.conf"
	# -------------------------------------------------------------------------
	: > "${___FILE_PATH}"
	# -------------------------------------------------------------------------
	___LIST=""
	I=0
	for ___LINE in $(echo "${___NIFC_WGRP}" | sed -e 's/[;,|]/ /g')
	do
		if echo "${___LIST}" | grep -Eqs 'search.*[[:space:]]'"${___LINE%%.}"'\.*[[:space:]]*'; then
			continue
		fi
		___LIST="${___LIST:+${___LIST} }${___LINE%%.}."
		I=$((I+1))
		if [ "${I}" -ge 6 ]; then
			break
		fi
	done
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
		search ${___LIST:-.}
_EOT_
	# -------------------------------------------------------------------------
	I=0
	for ___LINE in $(echo "${___NIFC_DNS4}" | sed -e 's/[;,|]/ /g')
	do
		if grep -Eqs 'nameserver[ \t]+'"${___LINE}"'' "${___FILE_PATH}"; then
			continue
		fi
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___FILE_PATH}"
			nameserver ${___LINE}
_EOT_
		I=$((I+1))
		if [ "${I}" -ge 3 ]; then
			break
		fi
	done
}

# --- function set network parameter ------------------------------------------
funcSetNetworkParameter () {
	__MEGS_TITL="set network parameter"
	__FLAG_CMAN=""; if funcIsPackage 'connman'        ; then __FLAG_CMAN="true"; fi
	__FLAG_NPLN=""; if funcIsPackage 'netplan.io'     ; then __FLAG_NPLN="true"; fi
	__FLAG_NMAN=""; if funcIsPackage 'network-manager'; then __FLAG_NMAN="true"; fi
	# -------------------------------------------------------------------------
	if [ -n "${__FLAG_CMAN}" ] \
	|| [ -n "${__FLAG_NPLN}" ] \
	|| [ -n "${__FLAG_NMAN}" ]; then
		echo "${__MEGS_TITL}"                | tee /dev/console 2>&1
		echo "${__MEGS_TITL}: [${_NETWORK}]" | tee /dev/console 2>&1
		# ---------------------------------------------------------------------
		# ip=[ifname:address:netmask:gateway:dns-nameserver:dns-search]
		__IF_LIST="${_NETWORK}"
		if [ "${__IF_LIST}" = "dhcp" ]; then
			__IF_LIST=""
			for __IF_PATH in /sys/class/net/*
			do
				__IF_NAME="${__IF_PATH##*/}"
				case "${__IF_NAME}" in
					lo    ) continue;;
					eth*  | \
					ath*  | \
					wlan* | \
					en*   ) __IF_LIST="${__IF_LIST:+${__IF_LIST},}${__IF_NAME}:dhcp";;
					*     ) continue;;
				esac
			done
		fi
		echo "${__MEGS_TITL}: [${__IF_LIST}]" | tee /dev/console 2>&1
		__LIST_DNS4=""
#		__LIST_WGRP=""
		__NIFC_WGRP="$(echo "${_HOSTNAME}." | cut -d '.' -f2-)"
		__NIFC_WGRP="${__NIFC_WGRP%%.}"
		__NIFC_WGRP="${__NIFC_WGRP:+${__NIFC_WGRP};}$(echo "${_DNSSRCH}" | sed -e 's/[,|]/;/g')"
		__NIFC_WGRP="${__NIFC_WGRP%%;}"
		__FILE_PATH="/run/systemd/resolve/resolv.conf"
		if [ -e "${__FILE_PATH}" ]; then
			__NIFC_RESV="$(awk '$1=="search" {p=index($0, " ")+1; s=substr($0, p); gsub(" ", ";", s); print s;}' "${__FILE_PATH}")"
			__NIFC_WGRP="${__NIFC_WGRP:+${__NIFC_WGRP};}${__NIFC_RESV%%.}"
		fi
		__NIFC_WGRP="${__NIFC_WGRP%%;}"
		__NIFC_WGRP="${__NIFC_WGRP%%.}"
#		__NIFC_WGRP="${__NIFC_WGRP:-.}"
		for __IFLINE in $(echo "lo:${__IF_LIST:+,${__IF_LIST}}" | sed -e 's/[,|]/ /g')
		do
			echo "${__MEGS_TITL}: [${__IFLINE}]" | tee /dev/console 2>&1
			__NIFC_NAME="$(echo "${__IFLINE}" | cut -d ':' -f 1)"
			__NIFC_IPV4="$(echo "${__IFLINE}" | cut -d ':' -f 2)"
			__NIFC_MASK="$(echo "${__IFLINE}" | cut -d ':' -f 3)"
			__NIFC_GATE="$(echo "${__IFLINE}" | cut -d ':' -f 4)"
			__NIFC_DNS4="$(echo "${__IFLINE}" | cut -d ':' -f 5)"
			__NIFC_PATH="/sys/class/net/${__NIFC_NAME}"
			# -----------------------------------------------------------------
			if [ ! -e "${__NIFC_PATH}" ]; then
				continue
			fi
			# -----------------------------------------------------------------
			__NIFC_MADR="$(cat "${__NIFC_PATH}/address")"
#			__NIFC_WGRP="${__NIFC_WGRP:-$(echo "${_HOSTNAME}." | cut -d '.' -f2-)}"
#			__NIFC_WGRP="${__NIFC_WGRP%.}"
#			__NIFC_WGRP="${__NIFC_WGRP:-.}"
			__NIFC_BIT4="$(funcIPv4GetNetCIDR "${__NIFC_MASK}")"
			if echo "${__NIFC_IPV4}" | grep -qs '/' ; then
				__NIFC_BIT4="${__NIFC_IPV4#*/}"
				__NIFC_IPV4="${__NIFC_IPV4%%/*}"
			fi
			if [ -z "${__NIFC_GATE}" ]; then
				__NIFC_GATE="$(LANG=C ip -o -4 route list | awk '$1=="default" {print $3;}')"
			fi
			if [ -z "${__NIFC_DNS4}" ]; then
				__NIFC_DNS4="${__NIFC_GATE}"
				if [ -z "${__NIFC_DNS4}" ]; then
					__NIFC_DNS4="8.8.8.8;8.8.4.4"
				fi
			fi
			__LIST_DNS4="${__LIST_DNS4:+${__LIST_DNS4};}${__NIFC_DNS4}"
#			__LIST_WGRP="${__LIST_WGRP:+${__LIST_WGRP};}${__NIFC_WGRP}"
			# --- debug out ---------------------------------------------------
			if [ -n "${_DEBUGOUT}" ]; then
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | tee /dev/console 2>&1
					# --- debug out ------------------------------------------------------------- #
					__MEGS_TITL=[${__MEGS_TITL}]
					__NIFC_NAME=[${__NIFC_NAME}]
					__NIFC_IPV4=[${__NIFC_IPV4}]
					__NIFC_BIT4=[${__NIFC_BIT4}]
					__NIFC_MASK=[${__NIFC_MASK}]
					__NIFC_GATE=[${__NIFC_GATE}]
					__NIFC_DNS4=[${__NIFC_DNS4}]
					__NIFC_WGRP=[${__NIFC_WGRP}]
					__NIFC_PATH=[${__NIFC_PATH}]
					__NIFC_MADR=[${__NIFC_MADR}]
					__LIST_DNS4=[${__LIST_DNS4}]
					# --- end of list ----------------------------------------------------------- #
_EOT_
			fi
			# -----------------------------------------------------------------
			echo "${__MEGS_TITL}: [${__NIFC_NAME}]" | tee /dev/console 2>&1
#			if [ "${__NIFC_NAME}" = "lo" ] || { [ -z "${__FLAG_CMAN}" ] && [ -z "${__FLAG_NPLN}" ] && [ -z "${__FLAG_NMAN}" ]; }; then
#			if [ -z "${__FLAG_CMAN}" ] && [ -z "${__FLAG_NPLN}" ] && [ -z "${__FLAG_NMAN}" ]; then
				echo "${__MEGS_TITL}: funcSetNIFfile" | tee /dev/console 2>&1
				funcSetNIFfile "${__NIFC_NAME}" "${__NIFC_IPV4}/${__NIFC_BIT4}" "${__NIFC_MASK}" "${__NIFC_GATE}" "${__NIFC_DNS4}" "${__NIFC_WGRP}" "${__FLAG_CMAN}${__FLAG_NPLN}${__FLAG_NMAN}"
#			fi
			if [ -n "${__FLAG_CMAN}" ]; then
				echo "${__MEGS_TITL}: funcSetConnman" | tee /dev/console 2>&1
				funcSetConnman "${__NIFC_NAME}" "${__NIFC_IPV4}/${__NIFC_BIT4}" "${__NIFC_MASK}" "${__NIFC_GATE}" "${__NIFC_DNS4}" "${__NIFC_WGRP}" "${__NIFC_MADR}" "${_NTP}"
			fi
			if [ -n "${__FLAG_NPLN}" ]; then
				echo "${__MEGS_TITL}: funcSetNetplan" | tee /dev/console 2>&1
				funcSetNetplan "${__NIFC_NAME}" "${__NIFC_IPV4}/${__NIFC_BIT4}" "${__NIFC_MASK}" "${__NIFC_GATE}" "${__NIFC_DNS4}" "${__NIFC_WGRP}" "${__FLAG_NMAN}"
			fi
			if [ -n "${__FLAG_NMAN}" ]; then
				echo "${__MEGS_TITL}: funcSetNetmana" | tee /dev/console 2>&1
				funcSetNetmana "${__NIFC_NAME}" "${__NIFC_IPV4}/${__NIFC_BIT4}" "${__NIFC_MASK}" "${__NIFC_GATE}" "${__NIFC_DNS4}" "${__NIFC_WGRP}" "${__NIFC_MADR}"
			fi
		done
		funcSetResolv "${__LIST_DNS4}" "${__NIFC_WGRP}"
		# --- debug out -------------------------------------------------------
		if [ -n "${_DEBUGOUT}" ]; then
			echo "# --- debug out ------------------------------------------------------------- #"
			echo "${__MEGS_TITL}" | tee /dev/console 2>&1
			LANG=C ifconfig       | tee /dev/console 2>&1
			LANG=C ip route list  | tee /dev/console 2>&1
			# --- /etc/resolv.conf --------------------------------------------
			__FILE_PATH="/etc/resolv.conf"
			if [ -e "${__FILE_PATH}" ]; then
				echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
				< "${__FILE_PATH}" tee /dev/console 2>&1
			fi
			# --- network interfaces ------------------------------------------
			__FILE_PATH="/etc/network/interfaces"
			if [ -e "${__FILE_PATH}" ]; then
				echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
				< "${__FILE_PATH}" tee /dev/console 2>&1
			fi
			# --- network connection manager ----------------------------------
			if [ -n "${__FLAG_CMAN}" ]; then
				for __FILE_PATH in /var/lib/connman/*/settings
				do
					if [ ! -e "${__FILE_PATH}" ]; then
						continue
					fi
					echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
					< "${__FILE_PATH}" tee /dev/console 2>&1
				done
			fi
			# --- network YAML network configuration --------------------------
			if [ -n "${__FLAG_NPLN}" ]; then
				for __FILE_PATH in /etc/netplan/*
				do
					if [ ! -e "${__FILE_PATH}" ]; then
						continue
					fi
					echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
					< "${__FILE_PATH}" tee /dev/console 2>&1
				done
			fi
			# --- network network manager -------------------------------------
			if [ -n "${__FLAG_NMAN}" ]; then
				for __FILE_PATH in /etc/NetworkManager/system-connections/*
				do
					if [ ! -e "${__FILE_PATH}" ]; then
						continue
					fi
					echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
					< "${__FILE_PATH}" tee /dev/console 2>&1
				done
			fi
			echo "# --- debug out ------------------------------------------------------------- #"
		fi
		# --- systemctl daemon-reload -----------------------------------------
		echo "${__MEGS_TITL}: systemctl daemon-reload" | tee /dev/console 2>&1
		systemctl daemon-reload
		# --- network interfaces ----------------------------------------------
		__NIFC_STAT="$(ifquery --state)"
		echo "${__MEGS_TITL}: ifquery --state: [${__NIFC_STAT}]" | tee /dev/console 2>&1
		if [ -n "${__NIFC_STAT}" ]; then
			echo "${__MEGS_TITL}: ifdown --exclude=lo ${__NIFC_STAT} -v" | tee /dev/console 2>&1
			# shellcheck disable=SC2086
			ifdown --exclude=lo ${__NIFC_STAT} -v || true
			echo "${__MEGS_TITL}: ifup -a --exclude=lo -v" | tee /dev/console 2>&1
			ifup -a --exclude=lo -v || true
		fi
		# --- network connection manager --------------------------------------
#		if [ -n "${__FLAG_CMAN}" ]; then
#			if systemctl is-active connman.service > /dev/null 2>&1; then
#				echo "${__MEGS_TITL}: connman.service active" | tee /dev/console 2>&1
#				if ls /sys/class/net/e* > /dev/null 2>&1; then
#					echo "${__MEGS_TITL}: connmanctl disable ethernet" | tee /dev/console 2>&1
#					connmanctl disable ethernet
#					echo "${__MEGS_TITL}: connmanctl enable ethernet" | tee /dev/console 2>&1
#					connmanctl enable ethernet
#				fi
#			fi
#		fi
		# --- network YAML network configuration ------------------------------
		if [ -n "${__FLAG_NPLN}" ]; then
			rm -f /run/netplan/*
			rm -f /run/NetworkManager/system-connections/*
			{
				echo "${__MEGS_TITL}: nm-online -s -q -t 600" | tee /dev/console 2>&1
				nm-online -s -q -t 600 || true
				echo "${__MEGS_TITL}: netplan apply" | tee /dev/console 2>&1
				netplan apply || true
				mkdir -p /var/lib/live/config
				touch "/var/lib/live/config/${_PROG_NAME%.*}.bg"
				echo "${__MEGS_TITL}: bg complete" | tee /dev/console 2>&1
			} &
		fi
		# --- network network manager -----------------------------------------
#		if [ -n "${__FLAG_NMAN}" ]; then
#			:
#		fi
		# --- Check whether network manager are active ------------------------
		echo "${__MEGS_TITL}: Check whether network manager are active" | tee /dev/console 2>&1
		for __UNIT in connman.service systemd-networkd.service NetworkManager.service
		do
			__RETURN_VALUE="$(systemctl is-active "${__UNIT}")"
			echo "${__MEGS_TITL}: [${__UNIT}=${__RETURN_VALUE}]" | tee /dev/console 2>&1
		done
		# ---------------------------------------------------------------------
		ip -oneline address | tee /dev/console 2>&1
		# ---------------------------------------------------------------------
		echo "${__MEGS_TITL}: complete" | tee /dev/console 2>&1
	fi
}

# --- function set hostname ---------------------------------------------------
funcSetHostname () {
	__MEGS_TITL="set hostname"
	__HOSTNAME="$1"
	# -------------------------------------------------------------------------
	if [ -z "${__HOSTNAME}" ]; then
		return
	fi
	# --- /etc/hosts ----------------------------------------------------------
	echo "${__MEGS_TITL}: [${__HOSTNAME}]" | tee /dev/console 2>&1
	__FILE_PATH="/etc/hosts"
	echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${__FILE_PATH%/*}"
	sed -i "${__FILE_PATH}"                                                         \
	    -e '/127.0.0.1/ s/\([ \t]\+\)[[:graph:]].*$/\1localhost '"${__HOSTNAME}"'/'
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
		< "${__FILE_PATH}" tee /dev/console 2>&1
	fi
	# --- /ets/hostname -------------------------------------------------------
	__FILE_PATH="/etc/hostname"
	echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${__FILE_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__FILE_PATH}"
		${__HOSTNAME}
_EOT_
	hostname "${__HOSTNAME}" || true
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
		< "${__FILE_PATH}" tee /dev/console 2>&1
	fi
}

# --- function set ssh parameter ----------------------------------------------
funcSetSSH () {
	__MEGS_TITL="set ssh parameter"
	__USERNAME="$1"
	__PASSWORD="$2"
	if ! funcIsPackage 'openssh-server'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${__MEGS_TITL}" | tee /dev/console 2>&1
	__CONF_ROOT="yes"
	__CONF_PSWD="no"
	if [ -n "${__USERNAME}" ]; then
		__CONF_ROOT="no"
	fi
	if [ -n "${__PASSWORD}" ]; then
		__CONF_PSWD="yes"
	fi
	# -------------------------------------------------------------------------
	__FILE_PATH="/etc/ssh/sshd_config.d/sshd.conf"
	mkdir -p "${__FILE_PATH%/*}"
	# -------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | tee /dev/console 2>&1
		${__MEGS_TITL}: [${__FILE_PATH}]
		${__MEGS_TITL}: PermitRootLogin=[${__CONF_ROOT}]
		${__MEGS_TITL}: PasswordAuthentication=[${__CONF_PSWD}]
_EOT_
	# -------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__FILE_PATH}"
		PasswordAuthentication ${__CONF_PSWD}
		PermitRootLogin ${__CONF_ROOT}
		
_EOT_
	chmod 600 "${__FILE_PATH}"
#	chmod 700 "${__FILE_PATH%/*}"
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
		< "${__FILE_PATH}" tee /dev/console 2>&1
	fi
}

# --- function set auto login parameter ---------------------------------------
funcSetAutoLogin () {
	__MEGS_TITL="set auto login parameter"
	__USERNAME="$1"
	# -------------------------------------------------------------------------
	if [ -z "${__USERNAME}" ]; then
		return
	fi
	echo "${__MEGS_TITL}" | tee /dev/console 2>&1
	# --- set auto login parameter [ console ] --------------------------------
	echo "${__MEGS_TITL}: console" | tee /dev/console 2>&1
	for __NUMBER in $(seq 1 6)
	do
		__FILE_PATH="/etc/systemd/system/getty@tty${__NUMBER}.service.d/live-config_autologin.conf"
		echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
		mkdir -p "${__FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__FILE_PATH}"
			[Service]
			Type=idle
			ExecStart=
			ExecStart=-/sbin/agetty --autologin ${__USERNAME} --noclear %I \$TERM
_EOT_
	done
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		for __NUMBER in $(seq 1 6)
		do
			__FILE_PATH="/etc/systemd/system/getty@tty${__NUMBER}.service.d/live-config_autologin.conf"
			echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
			< "${__FILE_PATH}" tee /dev/console 2>&1
		done
	fi
	# --- set auto login parameter [ lightdm ] --------------------------------
	if funcIsPackage 'lightdm'; then
		echo "${__MEGS_TITL}: lightdm" | tee /dev/console 2>&1
		__FILE_PATH="/etc/lightdm/lightdm.conf.d/autologin.conf"
		echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
		mkdir -p "${__FILE_PATH%/*}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__FILE_PATH}"
			[Seat:*]
			autologin-user=${__USERNAME}
			autologin-user-timeout=0
_EOT_
		# --- debug out -------------------------------------------------------
		if [ -n "${_DEBUGOUT}" ]; then
			echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
			< "${__FILE_PATH}" tee /dev/console 2>&1
		fi
	fi

	# --- set auto login parameter [ gdm3 ] -----------------------------------
	if funcIsPackage 'gdm3'; then
		echo "${__MEGS_TITL}: gdm3" | tee /dev/console 2>&1
		__GDM3_OPTIONS="$(
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
				AutomaticLoginEnable=true
				AutomaticLogin=${__USERNAME}
				#TimedLoginEnable=true
				#TimedLogin=${__USERNAME}
				#TimedLoginDelay=5
				
_EOT_
		)"
		__CONF_FLAG=""
		grep -l 'AutomaticLoginEnable[ \t]*=[ \t]*true' /etc/gdm3/*.conf | while IFS= read -r __FILE_PATH
		do
			sed -i "${__FILE_PATH}"            \
			    -e '/^\[daemon\]/,/^\[.*\]/ {' \
			    -e '/^[^#\[]\+/ s/^/#/}'
			if [ -z "${__CONF_FLAG:-}" ]; then
				sed -i "${__FILE_PATH}"                              \
				    -e "s%^\(\[daemon\].*\)$%\1\n${__GDM3_OPTIONS}%"
				__CONF_FLAG="true"
			fi
			# --- debug out ---------------------------------------------------
			if [ -n "${_DEBUGOUT}" ]; then
				echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
				< "${__FILE_PATH}" tee /dev/console 2>&1
			fi
		done
	fi
}

# --- function set vmware parameter -------------------------------------------
funcSetVMware () {
	__MEGS_TITL="set vmware parameter"
	__HGFS="$1"
	# -------------------------------------------------------------------------
	if [ -z "${__HGFS}" ] \
	|| ! funcIsPackage 'open-vm-tools'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${__MEGS_TITL}"              | tee /dev/console 2>&1
	echo "${__MEGS_TITL}: [${__HGFS}]" | tee /dev/console 2>&1
	mkdir -p "${__HGFS}"
	chmod a+w "${__HGFS}"
	# -------------------------------------------------------------------------
	__FILE_FTAB="/etc/fstab"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__FILE_FTAB}"
		.host:/ ${__HGFS} fuse.vmhgfs-fuse allow_other,auto_unmount,defaults,users 0 0
_EOT_
	__FILE_FUSE="/etc/fuse.conf"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__FILE_FUSE}"
		user_allow_other
_EOT_
	systemctl daemon-reload
	mount "${__HGFS}"
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${__FILE_FTAB}]" | tee /dev/console 2>&1
		< "${__FILE_FTAB}" tee /dev/console 2>&1
		__FILE_PATH="/etc/fuse.conf"
		echo "${__MEGS_TITL}: [${__FILE_FUSE}]" | tee /dev/console 2>&1
		< "${__FILE_FUSE}" tee /dev/console 2>&1
	fi
}

# --- function set samba parameter --------------------------------------------
funcSetSamba () {
	__MEGS_TITL="set samba parameter"
	__USERNAME="$1"
	__HGFS="$2"
	# -------------------------------------------------------------------------
	if ! funcIsPackage 'samba'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${__MEGS_TITL}"              | tee /dev/console 2>&1
	echo "${__MEGS_TITL}: [${__USERNAME}]" | tee /dev/console 2>&1
	echo "${__MEGS_TITL}: [${__HGFS}]" | tee /dev/console 2>&1
	# --- set smb.conf parameter ----------------------------------------------
	__FILE_PATH="/etc/samba/smb.conf"
	mkdir -p "${__FILE_PATH%/*}"
	echo "${__MEGS_TITL}: [${__FILE_FTAB}]" | tee /dev/console 2>&1
	# -------------------------------------------------------------------------
	sed -i "${__FILE_PATH}"                                    \
	    -e '/^;*\[homes\]$/                                 {' \
	    -e ':l;                                             {' \
	    -e 's/^;//;                   s/^ \t/\t/'              \
	    -e '/^[ \t]*read only[ \t]*=/ s/^/;/'                  \
	    -e '/^;*[ \t]*valid users[ \t]*=/a\   write list = %S' \
	    -e '                                                }' \
	    -e 'n; /^;*\[.*\]$/!b l;                            }'
	# -------------------------------------------------------------------------
	__GROUP="$(id "${__USERNAME}" 2> /dev/null | awk '{print substr($2,index($2,"(")+1,index($2,")")-index($2,"(")-1);}' || true)"
	__GROUP="${__GROUP:+"@${__GROUP}"}"
	# -------------------------------------------------------------------------
	if [ -n "${__HGFS}"   ] \
	&& [ -d "${__HGFS}/." ]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__FILE_PATH}"
			[hgfs]
			;  browseable = No
			   comment = VMware shared directories
			   path = ${__HGFS}
			${__GROUP+"   valid users = ${__GROUP}"}
			${__GROUP+"   write list = ${__GROUP}"}
			
_EOT_
	fi
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: testparm" | tee /dev/console 2>&1
		testparm -s | tee /dev/console 2>&1
	fi
}

# --- function set gnome parameter with dconf and gsettings -------------------
funcSetGnome () {
	__MEGS_TITL="set gnome parameter"
	# -------------------------------------------------------------------------
	if ! funcIsPackage 'dconf-cli' \
	|| ! funcIsPackage 'libglib2.0-bin'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${__MEGS_TITL}" | tee /dev/console 2>&1
	# --- create dconf profile ------------------------------------------------
	__PROF_PATH="/etc/dconf/profile/user"
	echo "${__MEGS_TITL}: [${__PROF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${__PROF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PROF_PATH}"
		user-db:user
		system-db:local
_EOT_
	# --- create dconf db -----------------------------------------------------
	__FILE_PATH="/etc/dconf/db/local.d/00-user-settings"
	echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${__FILE_PATH%/*}"
	: > "${__FILE_PATH}"
	echo "${__MEGS_TITL}: dconf compile" | tee /dev/console 2>&1
	dconf compile "${__FILE_PATH%.*}" "${__FILE_PATH%/*}"
#	echo "${__MEGS_TITL}: dconf update" | tee /dev/console 2>&1
#	dconf update
	# --- session [ screensaver wait time ] -----------------------------------
	echo "${__MEGS_TITL}: session" | tee /dev/console 2>&1
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__FILE_PATH}"
		[org/gnome/desktop/session]
		idle-delay=uint32 0
		
_EOT_
	# --- gnome terminal ------------------------------------------------------
	if funcIsPackage 'gnome-terminal'; then
		echo "${__MEGS_TITL}: gnome-terminal" | tee /dev/console 2>&1
		__UUID="$(gsettings get org.gnome.Terminal.ProfilesList default | sed -e 's/'\''//g')"
		if [ -n "${__UUID}" ]; then
			echo "${__MEGS_TITL}: [${__UUID}]" | tee /dev/console 2>&1
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__FILE_PATH}"
				[org/gnome/terminal/legacy/profiles:/:${__UUID}]
				default-size-columns=120
				default-size-rows=30
				font='Monospace 9'
				palette=['rgb(46,52,54)', 'rgb(204,0,0)', 'rgb(78,154,6)', 'rgb(196,160,0)', 'rgb(52,101,164)', 'rgb(117,80,123)', 'rgb(6,152,154)', 'rgb(211,215,207)', 'rgb(85,87,83)', 'rgb(239,41,41)', 'rgb(138,226,52)', 'rgb(252,233,79)', 'rgb(114,159,207)', 'rgb(173,127,168)', 'rgb(52,226,226)', 'rgb(238,238,236)']
				use-system-font=false
				
_EOT_
		fi
	fi
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${__PROF_PATH}]" | tee /dev/console 2>&1
		< "${__PROF_PATH}" tee /dev/console 2>&1
		echo "${__MEGS_TITL}: [${__FILE_PATH}]" | tee /dev/console 2>&1
		< "${__FILE_PATH}" tee /dev/console 2>&1
	fi
	# --- dconf update --------------------------------------------------------
	echo "${__MEGS_TITL}: dconf compile" | tee /dev/console 2>&1
	dconf compile "${__FILE_PATH%.*}" "${__FILE_PATH%/*}"
}

# --- set lxde panel ----------------------------------------------------------
funcSetSkeleton_LxdePanel () {
	___MEGS_TITL="set lxde panel"
	___FILE_PATH="lxpanel/LXDE/panels/panel"
	___XDGS_PATH="$1/${___FILE_PATH}"
	___CONF_PATH="$2/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if [ ! -f "${___XDGS_PATH}" ]; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	___ADD_OPTIONS="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e 's/=["'\'']/ /g' -e 's/["'\'']$//g' | sed -e ':l; N; s/\n/\\n/; b l;'
		  usefontsize=1
		  fontsize=9
		  monitor=-1
_EOT_
	)"
	mkdir -p "${___CONF_PATH%/*}"
	sed -e '/^Global \+{$/,/^}$/{'                   \
	    -e '/^[ #] \+widthtype *=/ s/=.*$/=request/' \
	    -e "/^}\$/ i\\${___ADD_OPTIONS}"             \
	    -e '}'                                       \
	       "${___XDGS_PATH}"                         \
	>      "${___CONF_PATH}"
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set lxde desktop.conf ---------------------------------------------------
funcSetSkeleton_LxdeDesktopConf () {
	___MEGS_TITL="set lxde desktop.conf"
	___FILE_PATH="lxsession/LXDE/desktop.conf"
	___XDGS_PATH="$1/${___FILE_PATH}"
	___CONF_PATH="$2/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if [ ! -f "${___XDGS_PATH}" ]; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	sed -e '/^\[GTK\]$/,/^\[.*\]$/{'                         \
	    -e ':l;'                                             \
	    -e '/^#* *sNet\/ThemeName/     s/=.*$/=Raleigh/'     \
	    -e '/^#* *sNet\/IconThemeName/ s/=.*$/=gnome-brave/' \
	    -e '/^#* *sGtk\/FontName=/     s/=.*$/=Sans 9/'      \
	    -e 'n'                                               \
	    -e '/^\(\[.*\]\|\)$/!b l'                            \
	    -e 'i sGtk/CursorThemeName=Adwaita'                  \
	    -e '}'                                               \
	       "${___XDGS_PATH}"                                 \
	>      "${___CONF_PATH}"
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set lxde desktop-items-0.conf -------------------------------------------
funcSetSkeleton_LxdeDesktopItems0Conf () {
	___MEGS_TITL="set lxde desktop-items-0.conf"
	___FILE_PATH="pcmanfm/LXDE/desktop-items-0.conf"
	___CONF_PATH="$1/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if ! funcIsPackage 'pcmanfm'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		[*]
		wallpaper_mode=crop
		wallpaper_common=1
		wallpaper=/etc/alternatives/desktop-background
		desktop_bg=#000000
		desktop_fg=#ffffff
		desktop_shadow=#000000
		desktop_font=Sans 9
		show_wm_menu=0
		sort=mtime;ascending;
		show_documents=1
		show_trash=1
		show_mounts=1
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set lxterminal.conf -----------------------------------------------------
funcSetSkeleton_LxterminalConf () {
	___MEGS_TITL="set lxterminal.conf"
	___FILE_PATH="lxterminal/lxterminal.conf"
	___CONF_PATH="$1/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if ! funcIsPackage 'lxterminal'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		[general]
		fontname=Monospace 9
		selchars=-A-Za-z0-9,./?%&#:_
		scrollback=1000
		bgcolor=rgb(0,0,0)
		fgcolor=rgb(211,215,207)
		palette_color_0=rgb(0,0,0)
		palette_color_1=rgb(205,0,0)
		palette_color_2=rgb(78,154,6)
		palette_color_3=rgb(196,160,0)
		palette_color_4=rgb(52,101,164)
		palette_color_5=rgb(117,80,123)
		palette_color_6=rgb(6,152,154)
		palette_color_7=rgb(211,215,207)
		palette_color_8=rgb(85,87,83)
		palette_color_9=rgb(239,41,41)
		palette_color_10=rgb(138,226,52)
		palette_color_11=rgb(252,233,79)
		palette_color_12=rgb(114,159,207)
		palette_color_13=rgb(173,127,168)
		palette_color_14=rgb(52,226,226)
		palette_color_15=rgb(238,238,236)
		color_preset=Tango
		disallowbold=false
		boldbright=false
		cursorblinks=false
		cursorunderline=false
		audiblebell=false
		visualbell=false
		tabpos=top
		geometry_columns=120
		geometry_rows=30
		hidescrollbar=false
		hidemenubar=false
		hideclosebutton=false
		hidepointer=false
		disablef10=false
		disablealt=false
		disableconfirm=false
		
		[shortcut]
		new_window_accel=<Primary><Shift>n
		new_tab_accel=<Primary><Shift>t
		close_tab_accel=<Primary><Shift>w
		close_window_accel=<Primary><Shift>q
		copy_accel=<Primary><Shift>c
		paste_accel=<Primary><Shift>v
		name_tab_accel=<Primary><Shift>i
		previous_tab_accel=<Primary>Page_Up
		next_tab_accel=<Primary>Page_Down
		move_tab_left_accel=<Primary><Shift>Page_Up
		move_tab_right_accel=<Primary><Shift>Page_Down
		zoom_in_accel=<Primary><Shift>plus
		zoom_out_accel=<Primary><Shift>underscore
		zoom_reset_accel=<Primary><Shift>parenright
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set libfm.conf ----------------------------------------------------------
funcSetSkeleton_LibfmConf () {
	___MEGS_TITL="set libfm.conf"
	___FILE_PATH="libfm/libfm.conf"
	___XDGS_PATH="$1/${___FILE_PATH}"
	___CONF_PATH="$2/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if [ ! -f "${___XDGS_PATH}" ]; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	sed -e '/^\[GTK\]$/,/^\[.*\]$/{'                         \
	    -e '/^#* *sNet\/ThemeName/     s/=.*$/=Raleigh/'     \
	    -e '/^#* *sNet\/IconThemeName/ s/=.*$/=gnome-brave/' \
	    -e '/^#* *sGtk\/FontName=/     s/=.*$/=Sans 9/'      \
	    -e '}'                                               \
	       "${___XDGS_PATH}"                                 \
	>      "${___CONF_PATH}"
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set lxde-rc.xml ---------------------------------------------------------
funcSetSkeleton_LxdeRcXml () {
	___MEGS_TITL="set lxde-rc.xml"
	___FILE_PATH="openbox/lxde-rc.xml"
	___XDGS_PATH="$1/openbox/LXDE/rc.xml"
	___CONF_PATH="$2/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if [ ! -f "${___XDGS_PATH}" ]; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cp "${___XDGS_PATH}" "${___CONF_PATH}"
	# --- edit xml file -------------------------------------------------------
	___NAME_SPCE="http://openbox.org/3.4/rc"
	___XMLS_PATH="//N:openbox_config/N:theme"
	# --- update --------------------------------------------------------------
	___COUNT="$(xmlstarlet sel -N N="${___NAME_SPCE}" -t -m "${___XMLS_PATH}" -v "count(N:font)" "${___CONF_PATH}")"
	: $((I=1))
	while [ $((I<=___COUNT)) -ne 0 ]
	do
		_NAME="$(xmlstarlet sel   -N N="${___NAME_SPCE}" -t -m "${___XMLS_PATH}/N:font[${I}]"        -v "N:name"  "${___CONF_PATH}" |  sed -e 's/^\(.\)\(.*\)$/\U\1\L\2/g' || true)"
	#	_SIZE="$(xmlstarlet sel   -N N="${___NAME_SPCE}" -t -m "${___XMLS_PATH}/N:font[${I}]"        -v "N:size"  "${___CONF_PATH}" || true)"
		         xmlstarlet ed -L -N N="${___NAME_SPCE}"    -u "${___XMLS_PATH}/N:font[${I}]/N:name" -v "${_NAME}"                        \
		                                                    -u "${___XMLS_PATH}/N:font[${I}]/N:size" -v "9"       "${___CONF_PATH}" || true
		I=$((I+1))
	done
	xmlstarlet ed -L -N N="${___NAME_SPCE}" -u "${___XMLS_PATH}/N:name" -v "Clearlooks-3.4" "${___CONF_PATH}" || true
	# --- append --------------------------------------------------------------
	xmlstarlet ed -L -N N="${___NAME_SPCE}" -s "${___XMLS_PATH}"                -t "elem" -n "font"                                "${___CONF_PATH}" || true
	xmlstarlet ed -L -N N="${___NAME_SPCE}" -s "${___XMLS_PATH}/N:font[last()]" -t "attr" -n "place"  -v "ActiveOnScreenDisplay"   \
	                                        -s "${___XMLS_PATH}/N:font[last()]" -t "elem" -n "name"   -v "Sans"                    \
	                                        -s "${___XMLS_PATH}/N:font[last()]" -t "elem" -n "size"   -v "9"                       \
	                                        -s "${___XMLS_PATH}/N:font[last()]" -t "elem" -n "weight" -v "Normal"                  \
	                                        -s "${___XMLS_PATH}/N:font[last()]" -t "elem" -n "slant"  -v "Normal"                  "${___CONF_PATH}" || true
	xmlstarlet ed -L -N N="${___NAME_SPCE}" -s "${___XMLS_PATH}"                -t "elem" -n "font"                                "${___CONF_PATH}" || true
	xmlstarlet ed -L -N N="${___NAME_SPCE}" -s "${___XMLS_PATH}/N:font[last()]" -t "attr" -n "place"  -v "InactiveOnScreenDisplay" \
	                                        -s "${___XMLS_PATH}/N:font[last()]" -t "elem" -n "name"   -v "Sans"                    \
	                                        -s "${___XMLS_PATH}/N:font[last()]" -t "elem" -n "size"   -v "9"                       \
	                                        -s "${___XMLS_PATH}/N:font[last()]" -t "elem" -n "weight" -v "Normal"                  \
	                                        -s "${___XMLS_PATH}/N:font[last()]" -t "elem" -n "slant"  -v "Normal"                  "${___CONF_PATH}" || true
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set gtk-2.0 -------------------------------------------------------------
funcSetSkeleton_Gtk20 () {
	___MEGS_TITL="set gtk-2.0"
	___FILE_PATH=".gtkrc-2.0"
	___CONF_PATH="$1/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if [ ! -d /etc/gtk-2.0/. ]; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		# DO NOT EDIT! This file will be overwritten by LXAppearance.
		# Any customization should be done in ~/.gtkrc-2.0.mine instead.
		
		include "${HOME}/.gtkrc-2.0.mine"
		gtk-theme-name="Raleigh"
		gtk-icon-theme-name="gnome-brave"
		gtk-font-name="Sans 9"
		gtk-cursor-theme-name="Adwaita"
		gtk-cursor-theme-size=18
		gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
		gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
		gtk-button-images=1
		gtk-menu-images=1
		gtk-enable-event-sounds=1
		gtk-enable-input-feedback-sounds=1
		gtk-xft-antialias=1
		gtk-xft-hinting=1
		gtk-xft-hintstyle="hintslight"
		gtk-xft-rgba="rgb"
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set gtk-3.0 -------------------------------------------------------------
funcSetSkeleton_Gtk30 () {
	___MEGS_TITL="set gtk-3.0"
	___FILE_PATH="gtk-3.0/settings.ini"
	___CONF_PATH="$1/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if [ ! -d /etc/gtk-3.0/. ]; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		[Settings]
		gtk-theme-name=Raleigh
		gtk-icon-theme-name=gnome-brave
		gtk-font-name=Sans 9
		gtk-cursor-theme-size=18
		gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
		gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
		gtk-button-images=1
		gtk-menu-images=1
		gtk-enable-event-sounds=1
		gtk-enable-input-feedback-sounds=1
		gtk-xft-antialias=1
		gtk-xft-hinting=1
		gtk-xft-hintstyle=hintslight
		gtk-xft-rgba=rgb
		gtk-cursor-theme-name=Adwaita
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set .bashrc -------------------------------------------------------------
funcSetSkeleton_Bashrc () {
	___MEGS_TITL="set .bashrc"
	___FILE_PATH=".bashrc"
	___CONF_PATH="$1/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if [ ! -f "${___CONF_PATH}" ]; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${___CONF_PATH}"
		# --- user custom ---
		alias vi='vim'
		alias view='vim'
		alias diff='diff --color=auto'
		alias ip='ip -color=auto'
		alias ls='ls --color=auto'
		# --- measures against garbled characters ---
		case "${TERM}" in
		    linux ) export LANG=C;;
		    *     )              ;;
		esac
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set .vimrc --------------------------------------------------------------
funcSetSkeleton_Vimrc () {
	___MEGS_TITL="set .vimrc"
	___FILE_PATH=".vimrc"
	___CONF_PATH="$1/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if ! funcIsPackage 'vim'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		set number              " Print the line number in front of each line.
		set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
		set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
		set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
		set nowrap              " This option changes how text is displayed.
		set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
		set laststatus=2        " The value of this option influences when the last window will have a status line always.
		set mouse-=a            " Disable mouse usage
		syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set .curlrc -------------------------------------------------------------
funcSetSkeleton_Curlrc () {
	___MEGS_TITL="set .curlrc"
	___FILE_PATH=".curlrc"
	___CONF_PATH="$1/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if ! funcIsPackage 'curl'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		location
		progress-bar
		remote-time
		show-error
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set .xscreensaver -------------------------------------------------------
funcSetSkeleton_Xscreensaver () {
	___MEGS_TITL="set .xscreensaver"
	___FILE_PATH=".xscreensaver"
	___CONF_PATH="$1/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if ! funcIsPackage 'xscreensaver'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		mode:		off
		selected:	-1
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set fcitx5 --------------------------------------------------------------
funcSetSkeleton_Fcitx5 () {
	___MEGS_TITL="set fcitx5"
	___FILE_PATH="fcitx5/profile"
	___CONF_PATH="$1/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if ! funcIsPackage 'fcitx5'; then
		return
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		[Groups/0]
		# Group Name
		Name=デフォルト
		# Layout
		Default Layout=${_KEYBOARD_LAYOUTS:-us}${_KEYBOARD_VARIANTS+"-${_KEYBOARD_VARIANTS}"}
		# Default Input Method
		DefaultIM=mozc
		
		[Groups/0/Items/0]
		# Name
		Name=keyboard-${_KEYBOARD_LAYOUTS:-us}${_KEYBOARD_VARIANTS+"-${_KEYBOARD_VARIANTS}"}
		# Layout
		Layout=
		
		[Groups/0/Items/1]
		# Name
		Name=mozc
		# Layout
		Layout=
		
		[GroupOrder]
		0=デフォルト
		
_EOT_
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set monitors.xml --------------------------------------------------------
funcSetSkeleton_MonitorsXml () {
	___MEGS_TITL="set monitors.xml"
	___FILE_PATH="monitors.xml"
	___CONF_PATH="$1/.config/${___FILE_PATH}"
	# -------------------------------------------------------------------------
	if [ -z "${_XORG_RESOLUTION}" ] \
	|| ! funcIsPackage 'open-vm-tools'  \
	|| ! funcIsPackage 'gdm3';          then
		return
	fi
	# -------------------------------------------------------------------------
	___WIDTH="${_XORG_RESOLUTION%%x*}"
	___HEIGHT="${_XORG_RESOLUTION#*x}"
	___CONNECTOR="$(grep -HE '^connected$' /sys/class/drm/*Virtual*/status | sed -ne 's/^.*\(Virtual[0-9-]\+\).*$/\1/gp')"
#	___RATE="$(edid-decode --list-dmts 2> /dev/null | awk '$3=='\""${___WIDTH:?}"x"${___HEIGHT:?}"\"' {printf("%.3f", $4); exit;}' || true)"
	___RATE="$(
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | awk '$3=='\""${___WIDTH}"'x'"${___HEIGHT}"\"'&&$0!~/RB/ {printf("%.3f",$4); exit;}'
			DMT 0x01:   640x350    85.079948 Hz  64:35    37.861 kHz     31.500000 MHz
			DMT 0x02:   640x400    85.079948 Hz  16:10    37.861 kHz     31.500000 MHz (STD: 0x31 0x19)
			DMT 0x03:   720x400    85.038902 Hz   9:5     37.927 kHz     35.500000 MHz
			DMT 0x04:   640x480    59.940476 Hz   4:3     31.469 kHz     25.175000 MHz (STD: 0x31 0x40)
			DMT 0x05:   640x480    72.808802 Hz   4:3     37.861 kHz     31.500000 MHz (STD: 0x31 0x4c)
			DMT 0x06:   640x480    75.000000 Hz   4:3     37.500 kHz     31.500000 MHz (STD: 0x31 0x4f)
			DMT 0x07:   640x480    85.008312 Hz   4:3     43.269 kHz     36.000000 MHz (STD: 0x31 0x59)
			DMT 0x08:   800x600    56.250000 Hz   4:3     35.156 kHz     36.000000 MHz
			DMT 0x09:   800x600    60.316541 Hz   4:3     37.879 kHz     40.000000 MHz (STD: 0x45 0x40)
			DMT 0x0a:   800x600    72.187572 Hz   4:3     48.077 kHz     50.000000 MHz (STD: 0x45 0x4c)
			DMT 0x0b:   800x600    75.000000 Hz   4:3     46.875 kHz     49.500000 MHz (STD: 0x45 0x4f)
			DMT 0x0c:   800x600    85.061274 Hz   4:3     53.674 kHz     56.250000 MHz (STD: 0x45 0x59)
			DMT 0x0d:   800x600   119.971829 Hz   4:3     76.302 kHz     73.250000 MHz (RB)
			DMT 0x0e:   848x480    60.000427 Hz  16:9     31.020 kHz     33.750000 MHz
			DMT 0x0f:  1024x768i   86.957532 Hz   4:3     35.522 kHz     44.900000 MHz
			DMT 0x10:  1024x768    60.003840 Hz   4:3     48.363 kHz     65.000000 MHz (STD: 0x61 0x40)
			DMT 0x11:  1024x768    70.069359 Hz   4:3     56.476 kHz     75.000000 MHz (STD: 0x61 0x4c)
			DMT 0x12:  1024x768    75.028582 Hz   4:3     60.023 kHz     78.750000 MHz (STD: 0x61 0x4f)
			DMT 0x13:  1024x768    84.996690 Hz   4:3     68.677 kHz     94.500000 MHz (STD: 0x61 0x59)
			DMT 0x14:  1024x768   119.988531 Hz   4:3     97.551 kHz    115.500000 MHz (RB)
			DMT 0x15:  1152x864    75.000000 Hz   4:3     67.500 kHz    108.000000 MHz (STD: 0x71 0x4f)
			DMT 0x55:  1280x720    60.000000 Hz  16:9     45.000 kHz     74.250000 MHz (STD: 0x81 0xc0)
			DMT 0x16:  1280x768    59.994726 Hz   5:3     47.396 kHz     68.250000 MHz (RB, CVT: 0x7f 0x1c 0x21)
			DMT 0x17:  1280x768    59.870228 Hz   5:3     47.776 kHz     79.500000 MHz (CVT: 0x7f 0x1c 0x28)
			DMT 0x18:  1280x768    74.893062 Hz   5:3     60.289 kHz    102.250000 MHz (CVT: 0x7f 0x1c 0x44)
			DMT 0x19:  1280x768    84.837055 Hz   5:3     68.633 kHz    117.500000 MHz (CVT: 0x7f 0x1c 0x62)
			DMT 0x1a:  1280x768   119.798073 Hz   5:3     97.396 kHz    140.250000 MHz
			DMT 0x1b:  1280x800    59.909545 Hz  16:10    49.306 kHz     71.000000 MHz (RB, CVT: 0x8f 0x18 0x21)
			DMT 0x1c:  1280x800    59.810326 Hz  16:10    49.702 kHz     83.500000 MHz (STD: 0x81 0x00, CVT: 0x8f 0x18 0x28)
			DMT 0x1d:  1280x800    74.934142 Hz  16:10    62.795 kHz    106.500000 MHz (STD: 0x81 0x0f, CVT: 0x8f 0x18 0x44)
			DMT 0x1e:  1280x800    84.879879 Hz  16:10    71.554 kHz    122.500000 MHz (STD: 0x81 0x19, CVT: 0x8f 0x18 0x62)
			DMT 0x1f:  1280x800   119.908501 Hz  16:10   101.562 kHz    146.250000 MHz (RB)
			DMT 0x20:  1280x960    60.000000 Hz   4:3     60.000 kHz    108.000000 MHz (STD: 0x81 0x40)
			DMT 0x21:  1280x960    85.002473 Hz   4:3     85.938 kHz    148.500000 MHz (STD: 0x81 0x59)
			DMT 0x22:  1280x960   119.837758 Hz   4:3    121.875 kHz    175.500000 MHz (RB)
			DMT 0x23:  1280x1024   60.019740 Hz   5:4     63.981 kHz    108.000000 MHz (STD: 0x81 0x80)
			DMT 0x24:  1280x1024   75.024675 Hz   5:4     79.976 kHz    135.000000 MHz (STD: 0x81 0x8f)
			DMT 0x25:  1280x1024   85.024098 Hz   5:4     91.146 kHz    157.500000 MHz (STD: 0x81 0x99)
			DMT 0x26:  1280x1024  119.958231 Hz   5:4    130.035 kHz    187.250000 MHz (RB)
			DMT 0x27:  1360x768    60.015162 Hz  85:48    47.712 kHz     85.500000 MHz
			DMT 0x28:  1360x768   119.966660 Hz  85:48    97.533 kHz    148.250000 MHz (RB)
			DMT 0x51:  1366x768    59.789541 Hz  85:48    47.712 kHz     85.500000 MHz
			DMT 0x56:  1366x768    60.000000 Hz  85:48    48.000 kHz     72.000000 MHz (RB)
			DMT 0x29:  1400x1050   59.947768 Hz   4:3     64.744 kHz    101.000000 MHz (RB, CVT: 0x0c 0x20 0x21)
			DMT 0x2a:  1400x1050   59.978442 Hz   4:3     65.317 kHz    121.750000 MHz (STD: 0x90 0x40, CVT: 0x0c 0x20 0x28)
			DMT 0x2b:  1400x1050   74.866680 Hz   4:3     82.278 kHz    156.000000 MHz (STD: 0x90 0x4f, CVT: 0x0c 0x20 0x44)
			DMT 0x2c:  1400x1050   84.959958 Hz   4:3     93.881 kHz    179.500000 MHz (STD: 0x90 0x59, CVT: 0x0c 0x20 0x62)
			DMT 0x2d:  1400x1050  119.904077 Hz   4:3    133.333 kHz    208.000000 MHz (RB)
			DMT 0x2e:  1440x900    59.901458 Hz  16:10    55.469 kHz     88.750000 MHz (RB, CVT: 0xc1 0x18 0x21)
			DMT 0x2f:  1440x900    59.887445 Hz  16:10    55.935 kHz    106.500000 MHz (STD: 0x95 0x00, CVT: 0xc1 0x18 0x28)
			DMT 0x30:  1440x900    74.984427 Hz  16:10    70.635 kHz    136.750000 MHz (STD: 0x95 0x0f, CVT: 0xc1 0x18 0x44)
			DMT 0x31:  1440x900    84.842118 Hz  16:10    80.430 kHz    157.000000 MHz (STD: 0x95 0x19, CVT: 0xc1 0x18 0x68)
			DMT 0x32:  1440x900   119.851784 Hz  16:10   114.219 kHz    182.750000 MHz (RB)
			DMT 0x53:  1600x900    60.000000 Hz  16:9     60.000 kHz    108.000000 MHz (RB, STD: 0xa9 0xc0)
			DMT 0x33:  1600x1200   60.000000 Hz   4:3     75.000 kHz    162.000000 MHz (STD: 0xa9 0x40)
			DMT 0x34:  1600x1200   65.000000 Hz   4:3     81.250 kHz    175.500000 MHz (STD: 0xa9 0x45)
			DMT 0x35:  1600x1200   70.000000 Hz   4:3     87.500 kHz    189.000000 MHz (STD: 0xa9 0x4a)
			DMT 0x36:  1600x1200   75.000000 Hz   4:3     93.750 kHz    202.500000 MHz (STD: 0xa9 0x4f)
			DMT 0x37:  1600x1200   85.000000 Hz   4:3    106.250 kHz    229.500000 MHz (STD: 0xa9 0x59)
			DMT 0x38:  1600x1200  119.917209 Hz   4:3    152.415 kHz    268.250000 MHz (RB)
			DMT 0x39:  1680x1050   59.883253 Hz  16:10    64.674 kHz    119.000000 MHz (RB, CVT: 0x0c 0x28 0x21)
			DMT 0x3a:  1680x1050   59.954250 Hz  16:10    65.290 kHz    146.250000 MHz (STD: 0xb3 0x00, CVT: 0x0c 0x28 0x28)
			DMT 0x3b:  1680x1050   74.892027 Hz  16:10    82.306 kHz    187.000000 MHz (STD: 0xb3 0x0f, CVT: 0x0c 0x28 0x44)
			DMT 0x3c:  1680x1050   84.940512 Hz  16:10    93.859 kHz    214.750000 MHz (STD: 0xb3 0x19, CVT: 0x0c 0x28 0x68)
			DMT 0x3d:  1680x1050  119.985533 Hz  16:10   133.424 kHz    245.500000 MHz (RB)
			DMT 0x3e:  1792x1344   59.999789 Hz   4:3     83.640 kHz    204.750000 MHz (STD: 0xc1 0x40)
			DMT 0x3f:  1792x1344   74.996724 Hz   4:3    106.270 kHz    261.000000 MHz (STD: 0xc1 0x4f)
			DMT 0x40:  1792x1344  119.973532 Hz   4:3    170.722 kHz    333.250000 MHz (RB)
			DMT 0x41:  1856x1392   59.995184 Hz   4:3     86.333 kHz    218.250000 MHz (STD: 0xc9 0x40)
			DMT 0x42:  1856x1392   75.000000 Hz   4:3    112.500 kHz    288.000000 MHz (STD: 0xc9 0x4f)
			DMT 0x43:  1856x1392  120.051132 Hz   4:3    176.835 kHz    356.500000 MHz (RB)
			DMT 0x52:  1920x1080   60.000000 Hz  16:9     67.500 kHz    148.500000 MHz (STD: 0xd1 0xc0)
			DMT 0x44:  1920x1200   59.950171 Hz  16:10    74.038 kHz    154.000000 MHz (RB, CVT: 0x57 0x28 0x21)
			DMT 0x45:  1920x1200   59.884600 Hz  16:10    74.556 kHz    193.250000 MHz (STD: 0xd1 0x00, CVT: 0x57 0x28 0x28)
			DMT 0x46:  1920x1200   74.930340 Hz  16:10    94.038 kHz    245.250000 MHz (STD: 0xd1 0x0f, CVT: 0x57 0x28 0x44)
			DMT 0x47:  1920x1200   84.931608 Hz  16:10   107.184 kHz    281.250000 MHz (STD: 0xd1 0x19, CVT: 0x57 0x28 0x62)
			DMT 0x48:  1920x1200  119.908612 Hz  16:10   152.404 kHz    317.000000 MHz (RB)
			DMT 0x49:  1920x1440   60.000000 Hz   4:3     90.000 kHz    234.000000 MHz (STD: 0xd1 0x40)
			DMT 0x4a:  1920x1440   75.000000 Hz   4:3    112.500 kHz    297.000000 MHz (STD: 0xd1 0x4f)
			DMT 0x4b:  1920x1440  120.113390 Hz   4:3    182.933 kHz    380.500000 MHz (RB)
			DMT 0x54:  2048x1152   60.000000 Hz  16:9     72.000 kHz    162.000000 MHz (RB, STD: 0xe1 0xc0)
			DMT 0x4c:  2560x1600   59.971589 Hz  16:10    98.713 kHz    268.500000 MHz (RB, CVT: 0x1f 0x38 0x21)
			DMT 0x4d:  2560x1600   59.986588 Hz  16:10    99.458 kHz    348.500000 MHz (CVT: 0x1f 0x38 0x28)
			DMT 0x4e:  2560x1600   74.972193 Hz  16:10   125.354 kHz    443.250000 MHz (CVT: 0x1f 0x38 0x44)
			DMT 0x4f:  2560x1600   84.950918 Hz  16:10   142.887 kHz    505.250000 MHz (CVT: 0x1f 0x38 0x62)
			DMT 0x50:  2560x1600  119.962758 Hz  16:10   203.217 kHz    552.750000 MHz (RB)
			DMT 0x57:  4096x2160   59.999966 Hz 256:135  133.320 kHz    556.744000 MHz (RB)
			DMT 0x58:  4096x2160   59.940046 Hz 256:135  133.187 kHz    556.188000 MHz (RB)
_EOT_
	)"
	# -------------------------------------------------------------------------
	if [ -z "${___CONNECTOR:-}" ] \
	|| [ -z "${___RATE:-}"      ]; then
		return
	fi
	if funcIsPackage 'xserver-xorg-video-vmware'; then
		___CONNECTOR="$(echo "${___CONNECTOR}" | sed -e 's/-//')"
	fi
	# -------------------------------------------------------------------------
	echo "${___MEGS_TITL}" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
	echo "${___MEGS_TITL}: [${___CONNECTOR:?}:${___WIDTH:?}x${___HEIGHT:?}:${___RATE:?}Hz" | tee /dev/console 2>&1
	mkdir -p "${___CONF_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${___CONF_PATH}"
		<monitors version="2">
		  <configuration>
		    <logicalmonitor>
		      <x>0</x>
		      <y>0</y>
		      <scale>1</scale>
		      <primary>yes</primary>
		      <monitor>
		        <monitorspec>
		          <connector>${___CONNECTOR:?}</connector>
		          <vendor>unknown</vendor>
		          <product>unknown</product>
		          <serial>unknown</serial>
		        </monitorspec>
		        <mode>
		          <width>${___WIDTH:?}</width>
		          <height>${___HEIGHT:?}</height>
		          <rate>${___RATE:?}</rate>
		        </mode>
		      </monitor>
		    </logicalmonitor>
		  </configuration>
		</monitors>
_EOT_
	# -------------------------------------------------------------------------
	if grep -q 'gdm' /etc/passwd; then
		___FILE_PATH="/var/lib/gdm3/.config/${___CONF_PATH##*/}"
		sudo --user=gdm mkdir -p "${___FILE_PATH%/*}"
		cp -p "${___CONF_PATH}" "${___FILE_PATH}"
		chown gdm: "${___FILE_PATH}" 2> /dev/null || /bin/true
	fi
	# --- debug out -----------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ]; then
		echo "${__MEGS_TITL}: [${___CONF_PATH}]" | tee /dev/console 2>&1
		< "${___CONF_PATH}" tee /dev/console 2>&1
	fi
}

# --- set skeleton ------------------------------------------------------------
funcSetSkeleton () {
	__MEGS_TITL="set skeleton"
	__DIRS_SKEL="/etc/skel"
	__DIRS_XDGS="/etc/xdg"
	# -------------------------------------------------------------------------
	funcSetSkeleton_LxdePanel             "${__DIRS_XDGS}" "${__DIRS_SKEL}"
	funcSetSkeleton_LxdeDesktopConf       "${__DIRS_XDGS}" "${__DIRS_SKEL}"
	funcSetSkeleton_LxdeDesktopItems0Conf                  "${__DIRS_SKEL}"
	funcSetSkeleton_LxterminalConf                         "${__DIRS_SKEL}"
	funcSetSkeleton_LibfmConf             "${__DIRS_XDGS}" "${__DIRS_SKEL}"
	funcSetSkeleton_LxdeRcXml             "${__DIRS_XDGS}" "${__DIRS_SKEL}"
	funcSetSkeleton_Gtk20                                  "${__DIRS_SKEL}"
	funcSetSkeleton_Gtk30                                  "${__DIRS_SKEL}"
	funcSetSkeleton_Bashrc                                 "${__DIRS_SKEL}"
	funcSetSkeleton_Vimrc                                  "${__DIRS_SKEL}"
	funcSetSkeleton_Curlrc                                 "${__DIRS_SKEL}"
	funcSetSkeleton_Xscreensaver                           "${__DIRS_SKEL}"
	funcSetSkeleton_Fcitx5                                 "${__DIRS_SKEL}"
	funcSetSkeleton_MonitorsXml                            "${__DIRS_SKEL}"
	
}

# --- function set root password ----------------------------------------------
funcSetRootUser () {
	__MEGS_TITL="set root password"
	__USERNAME="$1"
	__PASSWORD="$2"
	# -------------------------------------------------------------------------
	if [ -z "${__USERNAME}" ] \
	&& [ -n "${__PASSWORD}" ]; then
		echo "${__MEGS_TITL}: [${__PASSWORD}]" | tee /dev/console 2>&1
		__RETURN_VALUE="$(echo "${__PASSWORD}" | openssl passwd -6 -stdin)"
		usermod --password "${__RETURN_VALUE}" root
	else
		echo "${__MEGS_TITL}: no password" | tee /dev/console 2>&1
		passwd --delete root
	fi
}

# --- function add user -------------------------------------------------------
funcAddUser () {
	__MEGS_TITL="set add user"
	__USERNAME="$1"
	__PASSWORD="$2"
	__USER_FULLNAME="$3"
	__USER_DEFAULT_GROUPS="$4"
	# -------------------------------------------------------------------------
	if [ -z "${__USERNAME}" ]; then
		return
	fi
	# -------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | tee /dev/console 2>&1
		${__MEGS_TITL}: [${__USERNAME}]
		${__MEGS_TITL}: [${__PASSWORD}]
		${__MEGS_TITL}: [${__USER_FULLNAME}]
		${__MEGS_TITL}: [${__USER_DEFAULT_GROUPS}]
_EOT_
	# --- linux user ----------------------------------------------------------
	__RETURN_VALUE="$(id "${__USERNAME}" 2> /dev/null)"
	if [ -z "${__RETURN_VALUE}" ]; then
		echo "${__MEGS_TITL}: create user" | tee /dev/console 2>&1
		useradd --create-home --shell /bin/bash "${__USERNAME}"
	fi
	if [ -z "${__PASSWORD}" ]; then
		echo "${__MEGS_TITL}: no password" | tee /dev/console 2>&1
		passwd --delete "${__USERNAME}"
	else
		echo "${__MEGS_TITL}: set password" | tee /dev/console 2>&1
		__RETURN_VALUE="$(echo "${__PASSWORD}" | openssl passwd -6 -stdin)"
		usermod --password "${__RETURN_VALUE}" "${__USERNAME}"
	fi
	if [ -n "${__USER_FULLNAME}" ]; then
		echo "${__MEGS_TITL}: set full name" | tee /dev/console 2>&1
		usermod --comment "${__USER_FULLNAME}" "${__USERNAME}"
	fi
	if [ -n "${__USER_DEFAULT_GROUPS}" ]; then
		echo "${__MEGS_TITL}: add grups" | tee /dev/console 2>&1
		__GROUPS="$(echo "${__USER_DEFAULT_GROUPS}" | sed -e 's/ /|/g')"
		__GROUPS="$(awk -F ':' '$1~/'"${__GROUPS}"'/ {print $1;}' /etc/group | sed -e ':l; N; s/\n/,/; b l;')"
		if [ -n "${__GROUPS}" ]; then
			echo "${__MEGS_TITL}: [${__GROUPS}]" | tee /dev/console 2>&1
			usermod --append --groups "${__GROUPS}" "${__USERNAME}"
		fi
	fi
	# --- samba user ----------------------------------------------------------
	if funcIsPackage 'samba-common-bin'; then
		echo "${__MEGS_TITL}: create samba user" | tee /dev/console 2>&1
		smbpasswd -a "${__USERNAME}" -n
		if [ -n "${__PASSWORD}" ]; then
			printf "%s\n%s" "${__PASSWORD}" "${__PASSWORD}" | smbpasswd "${__USERNAME}"
		fi
	fi
}

# --- function set overlay ----------------------------------------------------
funcOverlay () {
	__MEGS_TITL="set overlay"
	echo "${__MEGS_TITL}" | tee /dev/console 2>&1
	# -------------------------------------------------------------------------
	__DIRS_PATH="/run/live/rootfs/filesystem.squashfs/etc/wireplumber"
	if [ -d "${__DIRS_PATH}/." ]; then
		echo "${__MEGS_TITL}: [${__DIRS_PATH}]" | tee /dev/console 2>&1
		ln -s "${__DIRS_PATH}" /run/live/overlay/rw/etc/
	fi
}

# --- function hook processing ------------------------------------------------
funcHookProcessing () {
	_MEGS_TITL="hook processing"
	echo "${_MEGS_TITL}" | tee /dev/console 2>&1
	# -------------------------------------------------------------------------
	printf "\033[m\033[42m%s\033[m\n" "${_MEGS_TITL}: [${_DISTRIBUTION}-${_RELEASE} (${_CODENAME})]" | tee /dev/console 2>&1
	# -------------------------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ] && [ "${_DEBUGOUT}" = "script" ]; then
		set -x							# Show command and argument expansion
	fi
	# -------------------------------------------------------------------------
	funcSetNetworkParameter
	funcSetHostname "${_HOSTNAME}"
	funcSetSSH "${_USERNAME}" "${_PASSWORD}"
	funcSetAutoLogin "${_USERNAME}"
	funcSetVMware "${_HGFS}"
	funcSetSamba "${_USERNAME}" "${_HGFS}"
	funcSetGnome
	funcSetSkeleton
	funcSetRootUser "${_USERNAME}" "${_PASSWORD}"
	funcAddUser "${_USERNAME}" "${_PASSWORD}" "${_FULLNAME}" "${_USER_DEFAULT_GROUPS}"
	funcOverlay
	# -------------------------------------------------------------------------
	echo "${_MEGS_TITL}: systemctl daemon-reload" | tee /dev/console 2>&1
	systemctl daemon-reload
	# -------------------------------------------------------------------------
	if [ -n "${_DEBUGOUT}" ] && [ "${_DEBUGOUT}" = "script" ]; then
		set +x							# End command and argument expansion
	fi
	# -------------------------------------------------------------------------
	echo "${_MEGS_TITL}: complete" | tee /dev/console 2>&1
}

# *****************************************************************************
# main
# *****************************************************************************

	_START_TIME=$(date +%s)
	_TIME="$(date +"%Y/%m/%d %H:%M:%S")"
	printf "\033[m\033[45m%s processing start\033[m\n" "${_TIME}" | tee /dev/console 2>&1

	funcSetParameter
	funcDebugOut
	funcHookProcessing

	_TIME="$(date +"%Y/%m/%d %H:%M:%S")"
	printf "\033[m\033[45m%s processing end\033[m\n" "${_TIME}" | tee /dev/console 2>&1
	_END_TIME=$(date +%s)

	_ELAPSED_TIME=$((_END_TIME-_START_TIME))
	printf "elapsed time: %dd%02dh%02dm%02ds\n" \
		$((_ELAPSED_TIME/86400))                \
		$((_ELAPSED_TIME%86400/3600))           \
		$((_ELAPSED_TIME%3600/60))              \
		$((_ELAPSED_TIME%60))                   \
		| tee /dev/console 2>&1

# *****************************************************************************
# exit
# *****************************************************************************

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${_PROG_NAME%.*}"
	printf "\033[m\033[45mcomplete: %s\033[m\n" "${_PROG_PATH}" | tee /dev/console 2>&1

#	set +o allexport					# Disable export

### eof #######################################################################
