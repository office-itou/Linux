# shellcheck disable=SC2148

	# === for creations =======================================================

	# --- common data file (prefer non-empty current file) --------------------
	declare       _PATH_CONF=":_DIRS_DATA_:/:_FILE_CONF_:"	# common configuration file
	declare       _PATH_DIST=":_DIRS_DATA_:/:_FILE_DIST_:"	# distribution data file
	declare       _PATH_MDIA=":_DIRS_DATA_:/:_FILE_MDIA_:"	# media data file
	declare       _PATH_DSTP=":_DIRS_DATA_:/:_FILE_DSTP_:"	# debstrap data file
	# --- pre-configuration file templates ------------------------------------
	declare       _PATH_KICK=":_DIRS_TMPL_:/:_FILE_KICK_:"	# for rhel
	declare       _PATH_CLUD=":_DIRS_TMPL_:/:_FILE_CLUD_:"	# for ubuntu cloud-init
	declare       _PATH_SEDD=":_DIRS_TMPL_:/:_FILE_SEDD_:"	# for debian
	declare       _PATH_SEDU=":_DIRS_TMPL_:/:_FILE_SEDU_:"	# for ubuntu
	declare       _PATH_YAST=":_DIRS_TMPL_:/:_FILE_YAST_:"	# for opensuse
	declare       _PATH_AGMA=":_DIRS_TMPL_:/:_FILE_AGMA_:"	# for opensuse
	# --- shell script --------------------------------------------------------
	declare       _PATH_ERLY=":_DIRS_SHEL_:/:_FILE_ERLY_:"	# shell commands to run early
	declare       _PATH_LATE=":_DIRS_SHEL_:/:_FILE_LATE_:"	# "              to run late
	declare       _PATH_PART=":_DIRS_SHEL_:/:_FILE_PART_:"	# "              to run after partition
	declare       _PATH_RUNS=":_DIRS_SHEL_:/:_FILE_RUNS_:"	# "              to run preseed/run
# --- tftp menu ---------------------------------------------------------------
	declare       _FILE_IPXE="autoexec.ipxe"				# ipxe
	declare       _FILE_GRUB="boot/grub/grub.cfg"			# grub
	declare       _FILE_SLNX="menu-bios/syslinux.cfg"		# syslinux (bios)
	declare       _FILE_UEFI="menu-efi64/syslinux.cfg"		# syslinux (efi64)
	declare       _PATH_IPXE=":_DIRS_TFTP_:/:_FILE_IPXE_:"	# ipxe
	declare       _PATH_GRUB=":_DIRS_TFTP_:/:_FILE_GRUB_:"	# grub
	declare       _PATH_SLNX=":_DIRS_TFTP_:/:_FILE_SLNX_:"	# syslinux (bios)
	declare       _PATH_UEFI=":_DIRS_TFTP_:/:_FILE_UEFI_:"	# syslinux (efi64)

	# --- tftp / web server network parameter ---------------------------------
	declare       _SRVR_HTTP="http"							# server connection protocol (http or https)
	declare       _SRVR_PROT="http"							# server connection protocol (http or tftp)
	declare       _SRVR_NICS="ens160"						# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
	declare       _SRVR_MADR="00:00:00:00:00:00"			#                mac    (ex. 00:00:00:00:00:00)
	declare       _SRVR_ADDR="192.168.1.11"					# IPv4 address          (ex. 192.168.1.11)
	declare       _SRVR_CIDR="24"							# IPv4 cidr             (ex. 24)
	declare       _SRVR_MASK="255.255.255.0"				# IPv4 subnetmask       (ex. 255.255.255.0)
	declare       _SRVR_GWAY="192.168.1.254"				# IPv4 gateway          (ex. 192.168.1.254)
	declare       _SRVR_NSVR="192.168.1.254"				# IPv4 nameserver       (ex. 192.168.1.254)
	declare       _SRVR_UADR="192.168.1"					# IPv4 address up       (ex. 192.168.1)

	# --- network parameter ---------------------------------------------------
	declare       _NWRK_HOST="sv-:_DISTRO_:"				# hostname              (ex. sv-server)
	declare       _NWRK_WGRP="workgroup"					# domain                (ex. workgroup)
	declare       _NICS_NAME="ens160"						# network device name   (ex. ens160)
	declare       _NICS_MADR=""								#                mac    (ex. 00:00:00:00:00:00)
	declare       _IPV4_ADDR="192.168.1.1"					# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)
	declare       _IPV4_CIDR="24"							# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)
	declare       _IPV4_MASK="255.255.255.0"				# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)
	declare       _IPV4_GWAY="192.168.1.254"				# IPv4 gateway          (ex. 192.168.1.254)
	declare       _IPV4_NSVR="192.168.1.254"				# IPv4 nameserver       (ex. 192.168.1.254)
	declare       _IPV4_UADR=""								# IPv4 address up       (ex. 192.168.1)
	declare       _NMAN_NAME=""								# network manager name  (nm_config, ifupdown, loopback)
	declare       _NTPS_ADDR="ntp.nict.jp"					# ntp server address    (ntp.nict.jp)
	declare       _NTPS_IPV4="61.205.120.130"				# ntp server ipv4 addr  (61.205.120.130)

	# --- menu parameter ------------------------------------------------------
	declare       _MENU_TOUT="5"							# timeout (sec)
	declare       _MENU_RESO="854x480"						# resolution (widht x hight)
	declare       _MENU_DPTH="16"							# colors
	declare       _MENU_MODE="864"							# screen mode (vga=nnn)
	declare       _MENU_SPLS="splash.png"					# splash file

	# --- auto install --------------------------------------------------------
	declare       _AUTO_INST="autoinst.cfg"					# autoinstall configuration file
	declare       _MINI_IRAM="initps.gz"					# initial ram disk of mini.iso including preseed

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
	declare -r -a _OPTN_WGET=("--tries=3" "--timeout=60" "--quiet")
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
