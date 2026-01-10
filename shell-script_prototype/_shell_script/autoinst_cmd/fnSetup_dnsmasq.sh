# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: dnsmasq
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_dnsmasq() {
	__FUNC_NAME="fnSetup_dnsmasq"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- check command -------------------------------------------------------
	if ! command -v dnsmasq > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "skip" "[${__FUNC_NAME}]"
		return
	fi
	# --- dnsmasq.service -----------------------------------------------------
	__SRVC="$(fnFind_serivce 'dnsmasq.service' | sort -V | head -n 1)"
	fnFile_backup "${__SRVC}"			# backup original file
	mkdir -p "${__SRVC%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__SRVC#*"${_DIRS_TGET:-}/"}" "${__SRVC}"
	sed -i "${__SRVC}" \
	    -e '/^\[Unit\]$/,/^\[.\+\]/                       {' \
	    -e '/^Requires=/                            s/^/#/g' \
	    -e '/^After=/                               s/^/#/g' \
	    -e '/^Description=/a Requires=network-online.target' \
	    -e '/^Description=/a After=network-online.target'    \
	    -e '                                              }'
	fnDbgdump "${__SRVC}"				# debugout
	fnFile_backup "${__SRVC}" "init"	# backup initial file
	# --- dnsmasq -------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/default/dnsmasq"
	if [ -e "${__PATH}" ]; then
		fnFile_backup "${__PATH}"			# backup original file
		mkdir -p "${__PATH%/*}"
		cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
		sed -i "${__PATH}" \
		    -e 's/^#\(IGNORE_RESOLVCONF\)=.*$/\1=yes/' \
		    -e 's/^#\(DNSMASQ_EXCEPT\)=.*$/\1="lo"/'
		fnDbgdump "${__PATH}"				# debugout
		fnFile_backup "${__PATH}" "init"	# backup initial file
	fi
	# --- default.conf --------------------------------------------------------
	__CONF="$(find "${_DIRS_TGET:-}"/etc/dnsmasq.d "${_DIRS_TGET:-}/usr/share" -name 'trust-anchors.conf' -type f)"
	__CONF="${__CONF#"${_DIRS_TGET:-}"}"
	__PATH="${_DIRS_TGET:-}/etc/dnsmasq.d/default.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		# --- log ---------------------------------------------------------------------
		#log-queries                                                # dns query log output
		#log-dhcp                                                   # dhcp transaction log output
		#log-facility=                                              # log output file name

		# --- dns ---------------------------------------------------------------------
		#port=0                                                     # listening port
		#bogus-priv                                                 # do not perform reverse lookup of private ip address on upstream server
		#domain-needed                                              # do not forward plain names
		$(printf "%-60s" "#domain=${_NICS_WGRP:-}")# local domain name
		#expand-hosts                                               # add domain name to host
		#filterwin2k                                                # filter for windows
		$(printf "%-60s" "#interface=${_NICS_NAME##-:-}")# listen to interface
		$(printf "%-60s" "#listen-address=${_IPV4_LHST:-}")# listen to ip address
		$(printf "%-60s" "#listen-address=${_IPV6_LHST:-}")# listen to ip address
		$(printf "%-60s" "#listen-address=${_NICS_IPV4:-}")# listen to ip address
		$(printf "%-60s" "#listen-address=${_LINK_ADDR:-}")# listen to ip address
		$(printf "%-60s" "#server=${_NICS_DNS4:-}")# directly specify upstream server
		#server=8.8.8.8                                             # directly specify upstream server
		#server=8.8.4.4                                             # directly specify upstream server
		#no-hosts                                                   # don't read the hostnames in /etc/hosts
		#no-poll                                                    # don't poll /etc/resolv.conf for changes
		#no-resolv                                                  # don't read /etc/resolv.conf
		#strict-order                                               # try in the registration order of /etc/resolv.conf
		#bind-dynamic                                               # enable bind-interfaces and the default hybrid network mode
		bind-interfaces                                             # enable multiple instances of dnsmasq
		$(printf "%-60s" "#conf-file=${_CONF:-}")# enable dnssec validation and caching
		#dnssec                                                     # "

		# --- dhcp --------------------------------------------------------------------
		$(printf "%-60s" "dhcp-range=${_IPV4_UADR:-}.0,proxy,24")# proxy dhcp
		$(printf "%-60s" "#dhcp-range=${_IPV4_UADR:-}.64,${_IPV4_UADR:-}.79,12h")# dhcp range
		#dhcp-option=option:netmask,255.255.255.0                   #  1 netmask
		$(printf "%-60s" "#dhcp-option=option:router,${_NICS_GATE:-}")#  3 router
		$(printf "%-60s" "#dhcp-option=option:dns-server,${_NICS_IPV4:-},${_NICS_GATE:-}")#  6 dns-server
		$(printf "%-60s" "#dhcp-option=option:domain-name,${_NICS_WGRP:-}")# 15 domain-name
		$(printf "%-60s" "#dhcp-option=option:28,${_IPV4_UADR:-}.255")# 28 broadcast
		$(printf "%-60s" "#dhcp-option=option:ntp-server,${_NTPS_IPV4:-}")# 42 ntp-server
		$(printf "%-60s" "#dhcp-option=option:tftp-server,${_NICS_IPV4:-}")# 66 tftp-server
		#dhcp-option=option:bootfile-name,                          # 67 bootfile-name
		dhcp-no-override                                            # disable re-use of the dhcp servername and filename fields as extra option space
		dhcp-reply-delay=1                                          # 

		# --- dnsmasq manual page -----------------------------------------------------
		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html

		# --- eof ---------------------------------------------------------------------
_EOT_
	if [ -n "${_NICS_AUTO##-}" ]; then
		sed -i "${__PATH}" \
		    -e '/^interface=/ s/^/#/g'
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- pxeboot.conf --------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}"
		#log-queries                                                # dns query log output
		#log-dhcp                                                   # dhcp transaction log output
		#log-facility=                                              # log output file name

		# --- tftp --------------------------------------------------------------------
		$(printf "%-60s" "#enable-tftp=${_NICS_NAME:-}")# enable tftp server
		$(printf "%-60s" "#tftp-root=${_DIRS_TFTP:-}")# tftp root directory
		#tftp-lowercase                                             # convert tftp request path to all lowercase
		#tftp-no-blocksize                                          # stop negotiating "block size" option
		#tftp-no-fail                                               # do not abort startup even if tftp directory is not accessible
		#tftp-secure                                                # enable tftp secure mode

		# --- syslinux block ----------------------------------------------------------
		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		#pxe-service=x86PC            , "PXEBoot-x86PC"            , menu-bios/lpxelinux.0       #  0 Intel x86PC
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , menu-efi64/syslinux.efi     #  7 EFI BC
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , menu-efi64/syslinux.efi     #  9 EFI x86-64

		# --- grub block --------------------------------------------------------------
		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		#pxe-service=x86PC            , "PXEBoot-x86PC"            , boot/grub/pxelinux.0        #  0 Intel x86PC
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , boot/grub/bootnetx64.efi    #  7 EFI BC
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , boot/grub/bootnetx64.efi    #  9 EFI x86-64

		# --- ipxe block --------------------------------------------------------------
		#dhcp-match=set:iPXE,175                                                                 #
		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		#pxe-service=tag:iPXE ,x86PC  , "PXEBoot-x86PC"            , /autoexec.ipxe              #  0 Intel x86PC (iPXE)
		#pxe-service=tag:!iPXE,x86PC  , "PXEBoot-x86PC"            , ipxe/undionly.kpxe          #  0 Intel x86PC
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , ipxe/ipxe.efi               #  7 EFI BC
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , ipxe/ipxe.efi               #  9 EFI x86-64

		# --- pxe boot ----------------------------------------------------------------
		#pxe-prompt="Press F8 for boot menu", 0                                                  # pxe boot prompt
		#pxe-service=x86PC            , "PXEBoot-x86PC"            ,                             #  0 Intel x86PC
		#pxe-service=PC98             , "PXEBoot-PC98"             ,                             #  1 NEC/PC98
		#pxe-service=IA64_EFI         , "PXEBoot-IA64_EFI"         ,                             #  2 EFI Itanium
		#pxe-service=Alpha            , "PXEBoot-Alpha"            ,                             #  3 DEC Alpha
		#pxe-service=Arc_x86          , "PXEBoot-Arc_x86"          ,                             #  4 Arc x86
		#pxe-service=Intel_Lean_Client, "PXEBoot-Intel_Lean_Client",                             #  5 Intel Lean Client
		#pxe-service=IA32_EFI         , "PXEBoot-IA32_EFI"         ,                             #  6 EFI IA32
		#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           ,                             #  7 EFI BC
		#pxe-service=Xscale_EFI       , "PXEBoot-Xscale_EFI"       ,                             #  8 EFI Xscale
		#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       ,                             #  9 EFI x86-64
		#pxe-service=ARM32_EFI        , "PXEBoot-ARM32_EFI"        ,                             # 10 ARM 32bit
		#pxe-service=ARM64_EFI        , "PXEBoot-ARM64_EFI"        ,                             # 11 ARM 64bit

		# --- dnsmasq manual page -----------------------------------------------------
		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html

		# --- eof ---------------------------------------------------------------------
_EOT_
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file
	# --- create sample file --------------------------------------------------
	for __WORK in "syslinux block" "grub block" "ipxe block"
	do
		__PATH="${_DIRS_TGET:+"${_DIRS_TGET}/"}${_DIRS_SAMP}/etc/dnsmasq.d/pxeboot_${__WORK%% *}.conf"
		mkdir -p "${__PATH%/*}"
		sed -ne '/^# --- tftp ---/,/^$/               {' \
		    -ne '/^# ---/p'                              \
		    -ne '/enable-tftp=/               s/^#//p'   \
		    -ne '/tftp-root=/                 s/^#//p }' \
		    -ne '/^# --- '"${__WORK}"' ---/,/^$/      {' \
		    -ne '/^# ---/p'                              \
		    -ne '/^# ---/!                    s/^#//gp}' \
		    "${_DIRS_TGET:-}/etc/dnsmasq.d/pxeboot.conf" \
		> "${__PATH}"
		fnDbgdump "${__PATH}"				# debugout
	done
	# --- service restart -----------------------------------------------------
	if [ -z "${_TGET_CNTR:-}" ]; then
		__SRVC="${__SRVC##*/}"
		if systemctl --quiet is-active "${__SRVC}"; then
			fnMsgout "${_PROG_NAME:-}" "restart" "${__SRVC}"
			systemctl --quiet daemon-reload
			if systemctl --quiet restart "${__SRVC}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "${__SRVC}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "${__SRVC}"
			fi
		fi
	fi
	unset __SRVC __PATH __CONF __WORK

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
