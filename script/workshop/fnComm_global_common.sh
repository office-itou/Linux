# shellcheck disable=SC2148

	# --- command line parameter ----------------------------------------------
	declare       _COMD_LINE=""								# command line parameter
	              _COMD_LINE="$(cat /proc/cmdline || true)"
	readonly      _COMD_LINE
	declare       _NICS_NAME=""								# nic if name   (ex. ens160)
	declare       _NICS_MADR=""								# nic if mac    (ex. 00:00:00:00:00:00)
	declare       _NICS_AUTO=""								# ipv4 dhcp     (ex. empty or dhcp)
	declare       _NICS_IPV4=""								# ipv4 address  (ex. 192.168.1.1)
	declare       _NICS_MASK=""								# ipv4 netmask  (ex. 255.255.255.0)
	declare       _NICS_BIT4=""								# ipv4 cidr     (ex. 24)
	declare       _NICS_DNS4=""								# ipv4 dns      (ex. 192.168.1.254)
	declare       _NICS_GATE=""								# ipv4 gateway  (ex. 192.168.1.254)
	declare       _NICS_FQDN=""								# hostname fqdn (ex. sv-server.workgroup)
	declare       _NICS_HOST=""								# hostname      (ex. sv-server)
	declare       _NICS_WGRP=""								# domain        (ex. workgroup)
	declare       _NMAN_FLAG=""								# nm_config, ifupdown, loopback
	declare       _DIRS_TGET=""								# target directory
	declare       _FILE_ISOS=""								# iso file name
	declare       _FILE_SEED=""								# preseed file name

	# --- target --------------------------------------------------------------
	declare       _TGET_VIRT=""								# virtualization (ex. vmware)
	declare       _TGET_CHRT=""								# is chgroot     (empty: none, else: chroot)
	declare       _TGET_CNTR=""								# is container   (empty: none, else: container)

	# --- set system parameter ------------------------------------------------
	declare       _DIST_NAME=""								# distribution name (ex. debian)
	declare       _DIST_VERS=""								# release version   (ex. 13)
	declare       _DIST_CODE=""								# code name         (ex. trixie)
	declare       _ROWS_SIZE="25"							# screen size: rows
	declare       _COLS_SIZE="80"							# screen size: columns
	declare       _TEXT_SPCE=""								# space
	declare       _TEXT_GAP1=""								# gap1
	declare       _TEXT_GAP2=""								# gap2
	declare       _COMD_BBOX=""								# busybox (empty: inactive, else: active )
	declare       _OPTN_COPY="--preserve=timestamps"		# copy option

	# --- network parameter ---------------------------------------------------
	declare       _NTPS_ADDR="ntp.nict.jp"					# ntp server address
	declare       _NTPS_IPV4="61.205.120.130"				# ntp server ipv4 address
	declare -r    _NTPS_FBAK="ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp"
	declare -r    _IPV6_LHST="::1"							# ipv6 local host address
	declare -r    _IPV4_LHST="127.0.0.1"					# ipv4 local host address
	declare -r    _IPV4_DUMY="127.0.1.1"					# ipv4 dummy address
	declare       _IPV4_UADR=""								# IPv4 address up   (ex. 192.168.1)
	declare       _IPV4_LADR=""								# IPv4 address low  (ex. 1)
	declare       _IPV6_ADDR=""								# IPv6 address      (ex. ::1)
	declare       _IPV6_CIDR=""								# IPv6 cidr         (ex. 64)
	declare       _IPV6_FADR=""								# IPv6 full address (ex. 0000:0000:0000:0000:0000:0000:0000:0001)
	declare       _IPV6_UADR=""								# IPv6 address up   (ex. 0000:0000:0000:0000)
	declare       _IPV6_LADR=""								# IPv6 address low  (ex. 0000:0000:0000:0001)
	declare       _IPV6_RADR=""								# IPv6 reverse addr (ex. ...)
	declare       _LINK_ADDR=""								# LINK address      (ex. fe80::1)
	declare       _LINK_CIDR=""								# LINK cidr         (ex. 64)
	declare       _LINK_FADR=""								# LINK full address (ex. fe80:0000:0000:0000:0000:0000:0000:0001)
	declare       _LINK_UADR=""								# LINK address up   (ex. fe80:0000:0000:0000)
	declare       _LINK_LADR=""								# LINK address low  (ex. 0000:0000:0000:0001)
	declare       _LINK_RADR=""								# LINK reverse addr (ex. ...)

	# --- firewalld -----------------------------------------------------------
	declare -r    _FWAL_ZONE="home_use"						# firewalld default zone
															# firewalld service name
	declare -r    _FWAL_NAME="dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp"
	declare -r    _FWAL_PORT="0-65535/tcp 0-65535/udp"		# firewalld port

	# --- samba parameter -----------------------------------------------------
	declare -r    _SAMB_USER="sambauser"					# force user
	declare -r    _SAMB_GRUP="sambashare"					# force group
	declare -r    _SAMB_GADM="sambaadmin"					# admin group
															# nsswitch.conf
	declare -r    _SAMB_NSSW="wins mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns6"
	declare       _SHEL_NLIN=""								# login shell (disallow system login to samba user)

	# --- working directory parameter -----------------------------------------
	declare -r    _DIRS_VADM="/var/admin"					# top of admin working directory
	declare       _DIRS_INST=""								# auto-install working directory
	declare       _DIRS_BACK=""								# top of backup directory
	declare       _DIRS_ORIG=""								# original file directory
	declare       _DIRS_INIT=""								# initial file directory
	declare       _DIRS_SAMP=""								# sample file directory
	declare       _DIRS_LOGS=""								# log file directory

	# --- list data -----------------------------------------------------------
	declare -a    _LIST_PARM=()								# PARAMETER LIST
	declare -a    _LIST_CONF=()								# common configuration data
	declare -a    _LIST_DIST=()								# distribution information
	declare -a    _LIST_MDIA=()								# media information
	declare -a    _LIST_DSTP=()								# debstrap information
															# media type
	declare -a    _LIST_TYPE=("mini" "netinst" "dvd" "liveinst" "live" "tool" "clive" "cnetinst" "system")
	declare -r -i _OSET_MDIA=2								# media information data offset

	# --- wget / curl options -------------------------------------------------
	declare -r -a _OPTN_CURL=("--location" "--http1.1" "--no-progress-bar" "--remote-time" "--show-error" "--fail" "--retry-max-time" "3" "--retry" "3" "--connect-timeout" "60")
	declare -r -a _OPTN_WGET=("--retry-on-http-error" "--tries=3" "--dns-timeout=60" "--connect-timeout=120" "--read-timeout=120" "--quiet")
	declare       _COMD_WGET=""
	if command -v wget2 > /dev/null 2>&1; then
		_COMD_WGET="curl"
	elif command -v wget > /dev/null 2>&1; then
		_COMD_WGET="wget"
	elif command -v curl > /dev/null 2>&1; then
		_COMD_WGET="curl"
	fi
	readonly      _COMD_WGET

	# --- rsync options -------------------------------------------------------
	declare -r -a _OPTN_RSYC=("--recursive" "--links" "--perms" "--times" "--group" "--owner" "--devices" "--specials" "--hard-links" "--acls" "--xattrs" "--human-readable" "--delete")
