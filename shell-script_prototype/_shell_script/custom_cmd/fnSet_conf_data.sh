# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: set default common configuration data
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _DBGS_FAIL : write
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
#   g-var : _PATH_KICK : read
#   g-var : _PATH_CLUD : read
#   g-var : _PATH_SEDD : read
#   g-var : _PATH_SEDU : read
#   g-var : _PATH_YAST : read
#   g-var : _PATH_AGMA : read
#   g-var : _FILE_ERLY : read
#   g-var : _FILE_LATE : read
#   g-var : _FILE_PART : read
#   g-var : _FILE_RUNS : read
#   g-var : _PATH_ERLY : read
#   g-var : _PATH_LATE : read
#   g-var : _PATH_PART : read
#   g-var : _PATH_RUNS : read
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
#   g-var : _MENU_RESO : read
#   g-var : _MENU_RESO : read
#   g-var : _MENU_RESO : read
#   g-var : _MENU_DPTH : read
#   g-var : _MENU_MODE : read
#   g-var : _TGET_MDIA : read
#   g-var : _DIRS_LIVE : read
#   g-var : _FILE_LIVE : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnSet_conf_data() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	_LIST_CONF=("$(cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		###############################################################################
		#
		#   common configuration file
		#
		#   developer   : J.Itou
		#   release     : 2025/11/01
		#
		#   history     :
		#      data    version    developer     point
		#   ---------- -------- --------------- ---------------------------------------
		#   2025/11/01 000.0000 J.Itou          first release
		#   $(date +"%Y/%m/%d %H:%M:%S") J.Itou          application output
		#
		###############################################################################

		# === for server environments =================================================

		# --- shared directory parameter ----------------------------------------------
		$(printf "%-39s %s" "DIRS_TOPS=\"${_DIRS_TOPS:-"/srv"}\""                    "# top of shared directory")
		$(printf "%-39s %s" "DIRS_HGFS=\"${_DIRS_HGFS:-":_DIRS_TOPS_:/hgfs"}\""      "# vmware shared"          )
		$(printf "%-39s %s" "DIRS_HTML=\"${_DIRS_HTML:-":_DIRS_TOPS_:/http/html"}\"" "# html contents"          )
		$(printf "%-39s %s" "DIRS_SAMB=\"${_DIRS_SAMB:-":_DIRS_TOPS_:/samba"}\""     "# samba shared"           )
		$(printf "%-39s %s" "DIRS_TFTP=\"${_DIRS_TFTP:-":_DIRS_TOPS_:/tftp"}\""      "# tftp contents"          )
		$(printf "%-39s %s" "DIRS_USER=\"${_DIRS_USER:-":_DIRS_TOPS_:/user"}\""      "# user file"              )

		# --- shared of user file -----------------------------------------------------
		$(printf "%-39s %s" "DIRS_SHAR=\"${_DIRS_SHAR:-":_DIRS_USER_:/share"}\""      "# shared of user file"                      )
		$(printf "%-39s %s" "DIRS_CONF=\"${_DIRS_CONF:-":_DIRS_SHAR_:/conf"}\""       "# configuration file"                       )
		$(printf "%-39s %s" "DIRS_DATA=\"${_DIRS_DATA:-":_DIRS_CONF_:/_data"}\""      "# data file"                                )
		$(printf "%-39s %s" "DIRS_KEYS=\"${_DIRS_KEYS:-":_DIRS_CONF_:/_keyring"}\""   "# keyring file"                             )
		$(printf "%-39s %s" "DIRS_MKOS=\"${_DIRS_MKOS:-":_DIRS_CONF_:/_mkosi"}\""     "# mkosi configuration files"                )
		$(printf "%-39s %s" "DIRS_TMPL=\"${_DIRS_TMPL:-":_DIRS_CONF_:/_template"}\""  "# templates for various configuration files")
		$(printf "%-39s %s" "DIRS_SHEL=\"${_DIRS_SHEL:-":_DIRS_CONF_:/script"}\""     "# shell script file"                        )
		$(printf "%-39s %s" "DIRS_IMGS=\"${_DIRS_IMGS:-":_DIRS_SHAR_:/imgs"}\""       "# iso file extraction destination"          )
		$(printf "%-39s %s" "DIRS_ISOS=\"${_DIRS_ISOS:-":_DIRS_SHAR_:/isos"}\""       "# iso file"                                 )
		$(printf "%-39s %s" "DIRS_LOAD=\"${_DIRS_LOAD:-":_DIRS_SHAR_:/load"}\""       "# load module"                              )
		$(printf "%-39s %s" "DIRS_RMAK=\"${_DIRS_RMAK:-":_DIRS_SHAR_:/rmak"}\""       "# remake file"                              )
		$(printf "%-39s %s" "DIRS_CACH=\"${_DIRS_CACH:-":_DIRS_SHAR_:/cache"}\""      "# cache file"                               )
		$(printf "%-39s %s" "DIRS_CTNR=\"${_DIRS_CTNR:-":_DIRS_SHAR_:/containers"}\"" "# container file"                           )
		$(printf "%-39s %s" "DIRS_CHRT=\"${_DIRS_CHRT:-":_DIRS_SHAR_:/chroot"}\""     "# container file (chroot)"                  )

		# --- common data file (prefer non-empty current file) ------------------------
		$(printf "%-39s %s" "FILE_CONF=\"${_FILE_CONF:-"common.cfg"}\""                  "# common configuration file")
		$(printf "%-39s %s" "FILE_DIST=\"${_FILE_DIST:-"distribution.dat"}\""            "# distribution data file"   )
		$(printf "%-39s %s" "FILE_MDIA=\"${_FILE_MDIA:-"media.dat"}\""                   "# media data file"          )
		$(printf "%-39s %s" "FILE_DSTP=\"${_FILE_DSTP:-"debstrap.dat"}\""                "# debstrap data file"       )
		$(printf "%-39s %s" "PATH_CONF=\"${_PATH_CONF:-":_DIRS_DATA_:/:_FILE_CONF_:"}\"" "# common configuration file")
		$(printf "%-39s %s" "PATH_DIST=\"${_PATH_DIST:-":_DIRS_DATA_:/:_FILE_DIST_:"}\"" "# distribution data file"   )
		$(printf "%-39s %s" "PATH_MDIA=\"${_PATH_MDIA:-":_DIRS_DATA_:/:_FILE_MDIA_:"}\"" "# media data file"          )
		$(printf "%-39s %s" "PATH_DSTP=\"${_PATH_DSTP:-":_DIRS_DATA_:/:_FILE_DSTP_:"}\"" "# debstrap data file"       )

		# --- pre-configuration file templates ----------------------------------------
		$(printf "%-39s %s" "FILE_KICK=\"${_FILE_KICK:-"kickstart_rhel.cfg"}\""          "# for rhel"             )
		$(printf "%-39s %s" "FILE_CLUD=\"${_FILE_CLUD:-"user-data_ubuntu"}\""            "# for ubuntu cloud-init")
		$(printf "%-39s %s" "FILE_SEDD=\"${_FILE_SEDD:-"preseed_debian.cfg"}\""          "# for debian"           )
		$(printf "%-39s %s" "FILE_SEDU=\"${_FILE_SEDU:-"preseed_ubuntu.cfg"}\""          "# for ubuntu"           )
		$(printf "%-39s %s" "FILE_YAST=\"${_FILE_YAST:-"yast_opensuse.xml"}\""           "# for opensuse"         )
		$(printf "%-39s %s" "FILE_AGMA=\"${_FILE_AGMA:-"agama_opensuse.json"}\""         "# for opensuse"         )
		$(printf "%-39s %s" "PATH_KICK=\"${_PATH_KICK:-":_DIRS_TMPL_:/:_FILE_KICK_:"}\"" "# for rhel"             )
		$(printf "%-39s %s" "PATH_CLUD=\"${_PATH_CLUD:-":_DIRS_TMPL_:/:_FILE_CLUD_:"}\"" "# for ubuntu cloud-init")
		$(printf "%-39s %s" "PATH_SEDD=\"${_PATH_SEDD:-":_DIRS_TMPL_:/:_FILE_SEDD_:"}\"" "# for debian"           )
		$(printf "%-39s %s" "PATH_SEDU=\"${_PATH_SEDU:-":_DIRS_TMPL_:/:_FILE_SEDU_:"}\"" "# for ubuntu"           )
		$(printf "%-39s %s" "PATH_YAST=\"${_PATH_YAST:-":_DIRS_TMPL_:/:_FILE_YAST_:"}\"" "# for opensuse"         )
		$(printf "%-39s %s" "PATH_AGMA=\"${_PATH_AGMA:-":_DIRS_TMPL_:/:_FILE_AGMA_:"}\"" "# for opensuse"         )

		# --- shell script ------------------------------------------------------------
		$(printf "%-39s %s" "FILE_ERLY=\"${_FILE_ERLY:-"autoinst_cmd_early.sh"}\""       "# shell commands to run early"           )
		$(printf "%-39s %s" "FILE_LATE=\"${_FILE_LATE:-"autoinst_cmd_late.sh"}\""        "# \"              to run late"           )
		$(printf "%-39s %s" "FILE_PART=\"${_FILE_PART:-"autoinst_cmd_part.sh"}\""        "# \"              to run after partition")
		$(printf "%-39s %s" "FILE_RUNS=\"${_FILE_RUNS:-"autoinst_cmd_run.sh"}\""         "# \"              to run preseed/run"    )
		$(printf "%-39s %s" "PATH_ERLY=\"${_PATH_ERLY:-":_DIRS_SHEL_:/:_FILE_ERLY_:"}\"" "# shell commands to run early"           )
		$(printf "%-39s %s" "PATH_LATE=\"${_PATH_LATE:-":_DIRS_SHEL_:/:_FILE_LATE_:"}\"" "# \"              to run late"           )
		$(printf "%-39s %s" "PATH_PART=\"${_PATH_PART:-":_DIRS_SHEL_:/:_FILE_PART_:"}\"" "# \"              to run after partition")
		$(printf "%-39s %s" "PATH_RUNS=\"${_PATH_RUNS:-":_DIRS_SHEL_:/:_FILE_RUNS_:"}\"" "# \"              to run preseed/run"    )

		# --- tftp / web server network parameter -------------------------------------
		$(printf "%-39s %s" "SRVR_HTTP=\"${_SRVR_HTTP:-"http"}\""              "# server connection protocol (http or https)"                                                     )
		$(printf "%-39s %s" "SRVR_PROT=\"${_SRVR_PROT:-"http"}\""              "# server connection protocol (http or tftp)"                                                      )
		$(printf "%-39s %s" "SRVR_NICS=\"${_SRVR_NICS:-"ens160"}\""            "# network device name   (ex. ens160)            (Set execution server setting to empty variable.)")
		$(printf "%-39s %s" "SRVR_MADR=\"${_SRVR_MADR:-"00:00:00:00:00:00"}\"" "#                mac    (ex. 00:00:00:00:00:00)"                                                  )
		$(printf "%-39s %s" "SRVR_ADDR=\"${_SRVR_ADDR:-"192.168.1.14"}\""      "# IPv4 address          (ex. 192.168.1.11)"                                                       )
		$(printf "%-39s %s" "SRVR_CIDR=\"${_SRVR_CIDR:-"24"}\""                "# IPv4 cidr             (ex. 24)"                                                                 )
		$(printf "%-39s %s" "SRVR_MASK=\"${_SRVR_MASK:-"255.255.255.0"}\""     "# IPv4 subnetmask       (ex. 255.255.255.0)"                                                      )
		$(printf "%-39s %s" "SRVR_GWAY=\"${_SRVR_GWAY:-"192.168.1.254"}\""     "# IPv4 gateway          (ex. 192.168.1.254)"                                                      )
		$(printf "%-39s %s" "SRVR_NSVR=\"${_SRVR_NSVR:-"192.168.1.254"}\""     "# IPv4 nameserver       (ex. 192.168.1.254)"                                                      )
		$(printf "%-39s %s" "SRVR_UADR=\"${_SRVR_UADR:-"192.168.1"}\""         "# IPv4 address up       (ex. 192.168.1)"                                                          )

		# === for creations ===========================================================

		# --- network parameter -------------------------------------------------------
		$(printf "%-39s %s" "NWRK_HOST=\"${_NWRK_HOST:-"sv-:_DISTRO_:"}\""  "# hostname              (ex. sv-server)"                                              )
		$(printf "%-39s %s" "NWRK_WGRP=\"${_NWRK_WGRP:-"workgroup"}\""      "# domain                (ex. workgroup)"                                              )
		$(printf "%-39s %s" "NICS_NAME=\"${_NICS_NAME:-"ens160"}\""         "# network device name   (ex. ens160)"                                                 )
		$(printf "%-39s %s" "NICS_MADR=\"${_NICS_MADR:-""}\""               "#                mac    (ex. 00:00:00:00:00:00)"                                      )
		$(printf "%-39s %s" "IPV4_ADDR=\"${_IPV4_ADDR:-"192.168.1.1"}\""    "# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)"                          )
		$(printf "%-39s %s" "IPV4_CIDR=\"${_IPV4_CIDR:-"24"}\""             "# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)")
		$(printf "%-39s %s" "IPV4_MASK=\"${_IPV4_MASK:-"255.255.255.0"}\""  "# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)"                     )
		$(printf "%-39s %s" "IPV4_GWAY=\"${_IPV4_GWAY:-"192.168.1.254"}\""  "# IPv4 gateway          (ex. 192.168.1.254)"                                          )
		$(printf "%-39s %s" "IPV4_NSVR=\"${_IPV4_NSVR:-"192.168.1.254"}\""  "# IPv4 nameserver       (ex. 192.168.1.254)"                                          )
		$(printf "%-39s %s" "IPV4_UADR=\"${_IPV4_UADR:-""}\""               "# IPv4 address up       (ex. 192.168.1)"                                              )
		$(printf "%-39s %s" "NMAN_NAME=\"${_NMAN_NAME:-""}\""               "# network manager name  (nm_config, ifupdown, loopback)"                              )
		$(printf "%-39s %s" "NTPS_ADDR=\"${_NTPS_ADDR:-"ntp.nict.jp"}\""    "# ntp server address    (ntp.nict.jp)"                                                )
		$(printf "%-39s %s" "NTPS_IPV4=\"${_NTPS_IPV4:-"61.205.120.130"}\"" "# ntp server ipv4 addr  (61.205.120.130)"                                             )

		# --- menu parameter ----------------------------------------------------------
		$(printf "%-39s %s" "MENU_TOUT=\"${_MENU_TOUT:-"5"}\""          "# timeout (sec)"                                 )
		$(printf "%-39s %s" "MENU_RESO=\"${_MENU_RESO:-"854x480"}\""    "# resolution (widht x hight)"                    )
		$(printf "%-39s %s" "MENU_DPTH=\"${_MENU_DPTH:-"16"}\""         "# colors"                                        )
		$(printf "%-39s %s" "MENU_MODE=\"${_MENU_MODE:-"864"}\""        "# screen mode (vga=nnn)"                         )
		$(printf "%-39s %s" "MENU_SPLS=\"${_MENU_SPLS:-"splash.png"}\"" "# splash file"                                   )
		$(printf "%-39s %s" "#MENU_RESO=\"${_MENU_RESO:-"1280x720"}\""  "# resolution (widht x hight): 16:9"              )
		$(printf "%-39s %s" "#MENU_RESO=\"${_MENU_RESO:-"854x480"}\""   "# \"                         : 16:9 (for vmware)")
		$(printf "%-39s %s" "#MENU_RESO=\"${_MENU_RESO:-"1024x768"}\""  "# \"                         :  4:3"             )
		$(printf "%-39s %s" "#MENU_DPTH=\"${_MENU_DPTH:-"16"}\""        "# colors"                                        )
		$(printf "%-39s %s" "#MENU_MODE=\"${_MENU_MODE:-"864"}\""       "# screen mode (vga=nnn)"                         )

		# === for mkosi ===============================================================

		# --- mkosi output image format type ------------------------------------------
		$(printf "%-39s %s" "TGET_MDIA=\"${_TGET_MDIA:-"directory"}\"" "# format type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)")

		# --- live media parameter ----------------------------------------------------
		$(printf "%-39s %s" "DIRS_LIVE=\"${_DIRS_LIVE:-"LiveOS"}\""       "# live / LiveOS"                     )
		$(printf "%-39s %s" "FILE_LIVE=\"${_FILE_LIVE:-"squashfs.img"}\"" "# filesystem.squashfs / squashfs.img")

		### eof #######################################################################
_EOT_
	)")

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
