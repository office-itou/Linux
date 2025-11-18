# shellcheck disable=SC2148

	# --- command line parameter ----------------------------------------------
									  	# command line parameter
	_COMD_LINE="$(cat /proc/cmdline || true)"
	readonly _COMD_LINE
	_NICS_NAME=""						# nic if name   (ex. ens160)
	_NICS_MADR=""						# nic if mac    (ex. 00:00:00:00:00:00)
	_NICS_AUTO=""						# ipv4 dhcp     (ex. empty or dhcp)
	_NICS_IPV4=""						# ipv4 address  (ex. 192.168.1.1)
	_NICS_MASK=""						# ipv4 netmask  (ex. 255.255.255.0)
	_NICS_BIT4=""						# ipv4 cidr     (ex. 24)
	_NICS_DNS4=""						# ipv4 dns      (ex. 192.168.1.254)
	_NICS_GATE=""						# ipv4 gateway  (ex. 192.168.1.254)
	_NICS_FQDN=""						# hostname fqdn (ex. sv-server.workgroup)
	_NICS_HOST=""						# hostname      (ex. sv-server)
	_NICS_WGRP=""						# domain        (ex. workgroup)
	_NMAN_FLAG=""						# nm_config, ifupdown, loopback
	_DIRS_TGET=""						# target directory
	_FILE_ISOS=""						# iso file name
	_FILE_SEED=""						# preseed file name
	# --- target --------------------------------------------------------------
	_TGET_VIRT=""						# virtualization (ex. vmware)
	_TGET_CNTR=""						# is container   (empty: none, else: container)
	# --- set system parameter ------------------------------------------------
	_DIST_NAME=""						# distribution name (ex. debian)
	_DIST_VERS=""						# release version   (ex. 13)
	_DIST_CODE=""						# code name         (ex. trixie)
	_ROWS_SIZE="25"						# screen size: rows
	_COLS_SIZE="80"						# screen size: columns
	_TEXT_GAP1=""						# gap1
	_TEXT_GAP2=""						# gap2
	_COMD_BBOX=""						# busybox (empty: inactive, else: active )
	_OPTN_COPY="--preserve=timestamps"	# copy option
	# --- network parameter ---------------------------------------------------
	readonly _NTPS_ADDR="ntp.nict.jp"	# ntp server address
	readonly _NTPS_IPV4="61.205.120.130" # ntp server ipv4 address
	readonly _NTPS_FBAK="ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp"
	readonly _IPV6_LHST="::1"			# ipv6 local host address
	readonly _IPV4_LHST="127.0.0.1"		# ipv4 local host address
	readonly _IPV4_DUMY="127.0.1.1"		# ipv4 dummy address
	_IPV4_UADR=""						# IPv4 address up   (ex. 192.168.1)
	_IPV4_LADR=""						# IPv4 address low  (ex. 1)
	_IPV6_ADDR=""						# IPv6 address      (ex. ::1)
	_IPV6_CIDR=""						# IPv6 cidr         (ex. 64)
	_IPV6_FADR=""						# IPv6 full address (ex. 0000:0000:0000:0000:0000:0000:0000:0001)
	_IPV6_UADR=""						# IPv6 address up   (ex. 0000:0000:0000:0000)
	_IPV6_LADR=""						# IPv6 address low  (ex. 0000:0000:0000:0001)
	_IPV6_RADR=""						# IPv6 reverse addr (ex. ...)
	_LINK_ADDR=""						# LINK address      (ex. fe80::1)
	_LINK_CIDR=""						# LINK cidr         (ex. 64)
	_LINK_FADR=""						# LINK full address (ex. fe80:0000:0000:0000:0000:0000:0000:0001)
	_LINK_UADR=""						# LINK address up   (ex. fe80:0000:0000:0000)
	_LINK_LADR=""						# LINK address low  (ex. 0000:0000:0000:0001)
	_LINK_RADR=""						# LINK reverse addr (ex. ...)
	# --- firewalld -----------------------------------------------------------
	readonly _FWAL_ZONE="home_use"		# firewalld default zone
										# firewalld service name
	readonly _FWAL_NAME="dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp"
										# firewalld port
	readonly _FWAL_PORT="0-65535/tcp 0-65535/udp"
	# --- samba parameter -----------------------------------------------------
	readonly _SAMB_USER="sambauser"		# force user
	readonly _SAMB_GRUP="sambashare"	# force group
	readonly _SAMB_GADM="sambaadmin"	# admin group
										# nsswitch.conf
	readonly _SAMB_NSSW="wins mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns6"
	_SHEL_NLIN=""						# login shell (disallow system login to samba user)
	# --- shared directory parameter ------------------------------------------
	_DIRS_TOPS=""						# top of shared directory
	_DIRS_HGFS=""						# vmware shared
	_DIRS_HTML=""						# html contents#
	_DIRS_SAMB=""						# samba shared
	_DIRS_TFTP=""						# tftp contents
	_DIRS_USER=""						# user file
	# --- shared of user file -------------------------------------------------
	_DIRS_PVAT=""						# private contents directory
	_DIRS_SHAR=""						# shared contents directory
	_DIRS_CONF=""						# configuration file
	_DIRS_DATA=""						# data file
	_DIRS_KEYS=""						# keyring file
	_DIRS_MKOS=""						# mkosi configuration files
	_DIRS_TMPL=""						# templates for various configuration files
	_DIRS_SHEL=""						# shell script file
	_DIRS_IMGS=""						# iso file extraction destination
	_DIRS_ISOS=""						# iso file
	_DIRS_LOAD=""						# load module
	_DIRS_RMAK=""						# remake file
	_DIRS_CACH=""						# cache file
	_DIRS_CTNR=""						# container file
	_DIRS_CHRT=""						# container file (chroot)
	# --- working directory parameter -----------------------------------------
	readonly _DIRS_VADM="/var/admin"	# top of admin working directory
	_DIRS_INST=""						# auto-install working directory
	_DIRS_BACK=""						# top of backup directory
	_DIRS_ORIG=""						# original file directory
	_DIRS_INIT=""						# initial file directory
	_DIRS_SAMP=""						# sample file directory
	_DIRS_LOGS=""						# log file directory
	# --- auto install --------------------------------------------------------
	readonly _FILE_ERLY="autoinst_cmd_early.sh"	# shell commands to run early
	readonly _FILE_LATE="autoinst_cmd_late.sh"	# "              to run late
	readonly _FILE_PART="autoinst_cmd_part.sh"	# "              to run after partition
	readonly _FILE_RUNS="autoinst_cmd_run.sh"	# "              to run preseed/run
