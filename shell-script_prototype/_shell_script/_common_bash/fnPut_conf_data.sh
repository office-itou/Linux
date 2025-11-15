# -----------------------------------------------------------------------------
# descript: put common configuration data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TOPS : read
#   g-var : _DIRS_HGFS : read
#   g-var : _DIRS_HTML : read
#   g-var : _DIRS_SAMB : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_USER : read
#   g-var : _DIRS_SHAR : read
#   g-var : _DIRS_CONF : read
#   g-var : _DIRS_DATA : read
#   g-var : _DIRS_KEYS : read
#   g-var : _DIRS_MKOS : read
#   g-var : _DIRS_TMPL : read
#   g-var : _DIRS_SHEL : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_ISOS : read
#   g-var : _DIRS_LOAD : read
#   g-var : _DIRS_RMAK : read
#   g-var : _DIRS_CACH : read
#   g-var : _DIRS_CTNR : read
#   g-var : _DIRS_CHRT : read
#   g-var : _FILE_CONF : read
#   g-var : _FILE_DIST : read
#   g-var : _FILE_MDIA : read
#   g-var : _FILE_DSTP : read
#   g-var : _PATH_CONF : read
#   g-var : _PATH_DIST : read
#   g-var : _PATH_MDIA : read
#   g-var : _PATH_DSTP : read
#   g-var : _FILE_KICK : read
#   g-var : _FILE_CLUD : read
#   g-var : _FILE_SEDD : read
#   g-var : _FILE_SEDU : read
#   g-var : _FILE_YAST : read
#   g-var : _FILE_AGMA : read
#   g-var : _CONF_KICK : read
#   g-var : _CONF_CLUD : read
#   g-var : _CONF_SEDD : read
#   g-var : _CONF_SEDU : read
#   g-var : _CONF_YAST : read
#   g-var : _CONF_AGMA : read
#   g-var : _FILE_ERLY : read
#   g-var : _FILE_LATE : read
#   g-var : _FILE_PART : read
#   g-var : _FILE_RUNS : read
#   g-var : _SHEL_ERLY : read
#   g-var : _SHEL_LATE : read
#   g-var : _SHEL_PART : read
#   g-var : _SHEL_RUNS : read
#   g-var : _SRVR_HTTP : read
#   g-var : _SRVR_PROT : read
#   g-var : _SRVR_NICS : read
#   g-var : _SRVR_MADR : read
#   g-var : _SRVR_ADDR : read
#   g-var : _SRVR_CIDR : read
#   g-var : _SRVR_MASK : read
#   g-var : _SRVR_GWAY : read
#   g-var : _SRVR_NSVR : read
#   g-var : _SRVR_UADR : read
#   g-var : _NWRK_HOST : read
#   g-var : _NWRK_WGRP : read
#   g-var : _NICS_NAME : read
#   g-var : _NICS_MADR : read
#   g-var : _IPV4_ADDR : read
#   g-var : _IPV4_CIDR : read
#   g-var : _IPV4_MASK : read
#   g-var : _IPV4_GWAY : read
#   g-var : _IPV4_NSVR : read
#   g-var : _IPV4_UADR : read
#   g-var : _NMAN_NAME : read
#   g-var : _NTPS_ADDR : read
#   g-var : _NTPS_IPV4 : read
#   g-var : _MENU_TOUT : read
#   g-var : _MENU_RESO : read
#   g-var : _MENU_DPTH : read
#   g-var : _MENU_MODE : read
#   g-var : _MENU_SPLS : read
#   g-var : _TGET_MDIA : read
#   g-var : _DIRS_LIVE : read
#   g-var : _FILE_LIVE : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnPut_conf_data() {
	declare       __TGET_PATH="${1:?}"	# target path
	declare -r    __DATE="$(date +"%Y/%m/%d" || true)"
	# --- exporting files -----------------------------------------------------
	fnExec_backup "${__TGET_PATH:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		###############################################################################
		#
		#	common configuration file
		#
		#	developer   : J.Itou
		#	release     : 2025/11/01
		#
		#	history     :
		#	   data    version    developer    point
		#	---------- -------- -------------- ----------------------------------------
		#	2025/11/01 000.0000 J.Itou         first release
		#	${__DATE:-yyyy/mm/dd} 000.0000 J.Itou         application output
		#
		###############################################################################

		# === for server environments =================================================

		# --- shared directory parameter ----------------------------------------------
		DIRS_TOPS="${_DIRS_TOPS:?}"						# top of shared directory
		DIRS_HGFS="${_DIRS_HGFS/${_DIRS_TOPS}/:_DIRS_TOPS_:}"			# vmware shared
		DIRS_HTML="${_DIRS_HTML/${_DIRS_TOPS}/:_DIRS_TOPS_:}"		# html contents#
		DIRS_SAMB="${_DIRS_SAMB/${_DIRS_TOPS}/:_DIRS_TOPS_:}"			# samba shared
		DIRS_TFTP="${_DIRS_TFTP/${_DIRS_TOPS}/:_DIRS_TOPS_:}"			# tftp contents
		DIRS_USER="${_DIRS_USER/${_DIRS_TOPS}/:_DIRS_TOPS_:}"			# user file

		# --- shared of user file -----------------------------------------------------
		DIRS_SHAR="${_DIRS_SHAR/${_DIRS_USER}/:_DIRS_USER_:}"			# shared of user file
		DIRS_CONF="${_DIRS_CONF/${_DIRS_SHAR}/:_DIRS_SHAR_:}"			# configuration file
		DIRS_DATA="${_DIRS_DATA/${_DIRS_CONF}/:_DIRS_CONF_:}"			# data file
		DIRS_KEYS="${_DIRS_KEYS/${_DIRS_CONF}/:_DIRS_CONF_:}"		# keyring file
		DIRS_MKOS="${_DIRS_MKOS/${_DIRS_CONF}/:_DIRS_CONF_:}"		# mkosi configuration files
		DIRS_TMPL="${_DIRS_TMPL/${_DIRS_CONF}/:_DIRS_CONF_:}"		# templates for various configuration files
		DIRS_SHEL="${_DIRS_SHEL/${_DIRS_CONF}/:_DIRS_CONF_:}"		# shell script file
		DIRS_IMGS="${_DIRS_IMGS/${_DIRS_SHAR}/:_DIRS_SHAR_:}"			# iso file extraction destination
		DIRS_ISOS="${_DIRS_ISOS/${_DIRS_SHAR}/:_DIRS_SHAR_:}"			# iso file
		DIRS_LOAD="${_DIRS_LOAD/${_DIRS_SHAR}/:_DIRS_SHAR_:}"			# load module
		DIRS_RMAK="${_DIRS_RMAK/${_DIRS_SHAR}/:_DIRS_SHAR_:}"			# remake file
		DIRS_CACH="${_DIRS_CACH/${_DIRS_SHAR}/:_DIRS_SHAR_:}"			# cache file
		DIRS_CTNR="${_DIRS_CTNR/${_DIRS_SHAR}/:_DIRS_SHAR_:}"	# container file
		DIRS_CHRT="${_DIRS_CHRT/${_DIRS_SHAR}/:_DIRS_SHAR_:}"		# container file (chroot)

		# --- common data file (prefer non-empty current file) ------------------------
		FILE_CONF="${_PATH_CONF##*/}"					# common configuration file
		FILE_DIST="${_PATH_DIST##*/}"			# distribution data file
		FILE_MDIA="${_PATH_MDIA##*/}"					# media data file
		FILE_DSTP="${_PATH_DSTP##*/}"				# debstrap data file
		PATH_CONF="${_PATH_CONF/${_DIRS_DATA}\/*/:_DIRS_DATA_:\/:_FILE_CONF_:}"	# common configuration file
		PATH_DIST="${_PATH_DIST/${_DIRS_DATA}\/*/:_DIRS_DATA_:\/:_FILE_DIST_:}"	# distribution data file
		PATH_MDIA="${_PATH_MDIA/${_DIRS_DATA}\/*/:_DIRS_DATA_:\/:_FILE_MDIA_:}"	# media data file
		PATH_DSTP="${_PATH_DSTP/${_DIRS_DATA}\/*/:_DIRS_DATA_:\/:_FILE_DSTP_:}"	# debstrap data file

		# --- pre-configuration file templates ----------------------------------------
		FILE_KICK="${_CONF_KICK##*/}"			# for rhel
		FILE_CLUD="${_CONF_CLUD##*/}"			# for ubuntu cloud-init
		FILE_SEDD="${_CONF_SEDD##*/}"			# for debian
		FILE_SEDU="${_CONF_SEDU##*/}"			# for ubuntu
		FILE_YAST="${_CONF_YAST##*/}"			# for opensuse
		FILE_AGMA="${_CONF_AGMA##*/}"			# for opensuse
		CONF_KICK="${_CONF_KICK/${_DIRS_TMPL}\/*/:_DIRS_TMPL_:\/:_FILE_KICK_:}"	# for rhel
		CONF_CLUD="${_CONF_CLUD/${_DIRS_TMPL}\/*/:_DIRS_TMPL_:\/:_FILE_CLUD_:}"	# for ubuntu cloud-init
		CONF_SEDD="${_CONF_SEDD/${_DIRS_TMPL}\/*/:_DIRS_TMPL_:\/:_FILE_SEDD_:}"	# for debian
		CONF_SEDU="${_CONF_SEDU/${_DIRS_TMPL}\/*/:_DIRS_TMPL_:\/:_FILE_SEDU_:}"	# for ubuntu
		CONF_YAST="${_CONF_YAST/${_DIRS_TMPL}\/*/:_DIRS_TMPL_:\/:_FILE_YAST_:}"	# for opensuse
		CONF_AGMA="${_CONF_AGMA/${_DIRS_TMPL}\/*/:_DIRS_TMPL_:\/:_FILE_AGMA_:}"	# for opensuse

		# --- shell script ------------------------------------------------------------
		FILE_ERLY="${_SHEL_ERLY##*/}"		# shell commands to run early
		FILE_LATE="${_SHEL_LATE##*/}"		# "              to run late
		FILE_PART="${_SHEL_PART##*/}"		# "              to run after partition
		FILE_RUNS="${_SHEL_RUNS##*/}"			# "              to run preseed/run
		SHEL_ERLY="${_SHEL_ERLY/${_DIRS_SHEL}\/*/:_DIRS_SHEL_:\/:_FILE_ERLY_:}"	# shell commands to run early
		SHEL_LATE="${_SHEL_LATE/${_DIRS_SHEL}\/*/:_DIRS_SHEL_:\/:_FILE_LATE_:}"	# "              to run late
		SHEL_PART="${_SHEL_PART/${_DIRS_SHEL}\/*/:_DIRS_SHEL_:\/:_FILE_PART_:}"	# "              to run after partition
		SHEL_RUNS="${_SHEL_RUNS/${_DIRS_SHEL}\/*/:_DIRS_SHEL_:\/:_FILE_RUNS_:}"	# "              to run preseed/run

		# --- tftp / web server network parameter -------------------------------------
		SRVR_HTTP="${_SRVR_HTTP:-}"						# server connection protocol (http or https)
		SRVR_PROT="${_SRVR_PROT:-}"						# server connection protocol (http or tftp)
		SRVR_NICS="${_SRVR_NICS:-}"						# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
		SRVR_MADR="${_SRVR_MADR//[!:]/0}"			#                mac    (ex. 00:00:00:00:00:00)
		SRVR_ADDR="${_SRVR_ADDR:-}"				# IPv4 address          (ex. 192.168.1.11)
		SRVR_CIDR="${_SRVR_CIDR:-}"							# IPv4 cidr             (ex. 24)
		SRVR_MASK="${_SRVR_MASK:-}"				# IPv4 subnetmask       (ex. 255.255.255.0)
		SRVR_GWAY="${_SRVR_GWAY:-}"				# IPv4 gateway          (ex. 192.168.1.254)
		SRVR_NSVR="${_SRVR_NSVR:-}"				# IPv4 nameserver       (ex. 192.168.1.254)
		SRVR_UADR="${_SRVR_UADR:-}"					# IPv4 address up       (ex. 192.168.1)

		# === for creations ===========================================================

		# --- network parameter -------------------------------------------------------
		NWRK_HOST="${_NWRK_HOST:-"sv-:_DISTRO_:"}"				# hostname              (ex. sv-server)
		NWRK_WGRP="${_NWRK_WGRP:-"workgroup"}"					# domain                (ex. workgroup)
		NICS_NAME="${_NICS_NAME:-"ens160"}"						# network device name   (ex. ens160)
		NICS_MADR="${_NICS_MADR:-}"							#                mac    (ex. 00:00:00:00:00:00)
		IPV4_ADDR="${_IPV4_ADDR:-"192.168.1.1"}"					# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)
		IPV4_CIDR="${_IPV4_CIDR:-"24"}"							# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)
		IPV4_MASK="${_IPV4_MASK:-"255.255.255.0"}"				# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)
		IPV4_GWAY="${_IPV4_GWAY:-"192.168.1.254"}"				# IPv4 gateway          (ex. 192.168.1.254)
		IPV4_NSVR="${_IPV4_NSVR:-"192.168.1.254"}"				# IPv4 nameserver       (ex. 192.168.1.254)
		IPV4_UADR="${_IPV4_UADR:-}"							# IPv4 address up       (ex. 192.168.1)
		NMAN_NAME="${_NMAN_NAME:-}"							# network manager name  (nm_config, ifupdown, loopback)
		NTPS_ADDR="${_NTPS_ADDR:-"ntp.nict.jp"}"					# ntp server address    (ntp.nict.jp)
		NTPS_IPV4="${_NTPS_IPV4:-"61.205.120.130"}"				# ntp server ipv4 addr  (61.205.120.130)

		# --- menu parameter ----------------------------------------------------------
		MENU_TOUT="${_MENU_TOUT:-}"							# timeout (sec)
		MENU_RESO="${_MENU_RESO:-}"						# resolution (widht x hight)
		MENU_DPTH="${_MENU_DPTH:-}"							# colors
		MENU_MODE="${_MENU_MODE:-}"							# screen mode (vga=nnn)
		MENU_SPLS="${_MENU_SPLS##*/}"					# splash file
		#MENU_RESO="1280x720"					# resolution (widht x hight): 16:9
		#MENU_RESO="854x480"					# "                         : 16:9 (for vmware)
		#MENU_RESO="1024x768"					# "                         :  4:3
		#MENU_DPTH="16"							# colors
		#MENU_MODE="864"						# screen mode (vga=nnn)

		# === for mkosi ===============================================================

		# --- mkosi output image format type --------------------------------------
		TGET_MDIA="${_TGET_MDIA:-}"					# format type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)

		# --- live media parameter ------------------------------------------------
		DIRS_LIVE="${_DIRS_LIVE:-}"						# live / LiveOS
		FILE_LIVE="${_FILE_LIVE##*/}"				# filesystem.squashfs / squashfs.img

		### eof #######################################################################
_EOT_
}
