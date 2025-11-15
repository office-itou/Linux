#!/bin/dash

set -eux

_NICS_NAME="ens160"
_NICS_MADR="00:00:00:00:00:00"
_NICS_AUTO="dhcp"
_NICS_IPV4="192.168.1.1"
_NICS_MASK="255.255.255.0"
_NICS_BIT4="24"
_NICS_DNS4="192.168.1.254"
_NICS_GATE="192.168.1.254"
_NICS_FQDN="sv-server.workgroup"
_NICS_HOST="sv-server"
_NICS_WGRP="workgroup"
_NTPS_ADDR="ntp.nict.jp"
_NTPS_IPV4="61.205.120.130"
_IPV6_LHST="::1"
_IPV4_LHST="127.0.0.1"
_IPV4_DUMY="127.0.1.1"
_IPV4_UADR="192.168.1"
_IPV4_LADR="1"
_IPV6_ADDR="::1"
_IPV6_CIDR="64"
_IPV6_FADR="0000:0000:0000:0000:0000:0000:0000:0001"
_IPV6_UADR="0000:0000:0000:0000"
_IPV6_LADR="0000:0000:0000:0001"
_IPV6_RADR=""
_LINK_ADDR="fe80::1"
_LINK_CIDR="64"
_LINK_FADR="fe80:0000:0000:0000:0000:0000:0000:0001"
_LINK_UADR="fe80:0000:0000:0000"
_LINK_LADR="0000:0000:0000:0001"
_LINK_RADR=""
_FWAL_ZONE="home_use"
_FWAL_NAME="dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp"
_FWAL_PORT="0-65535/tcp 0-65535/udp"
_SAMB_USER="sambauser"
_SAMB_GRUP="sambashare"
_SAMB_GADM="sambaadmin"

__PATH="${PWD:-}/dnsmasq.conf"
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

		# --- dnsmasq manual page -----------------------------------------------------
		# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html

		# --- eof ---------------------------------------------------------------------
_EOT_

__PATH="${PWD:-}/dnsmasq_pxeboot.conf"
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
