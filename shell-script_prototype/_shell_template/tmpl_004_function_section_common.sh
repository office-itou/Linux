# *** function section (sub functions) ****************************************

# --- initialization ----------------------------------------------------------
function funcInitialization() {
	declare       _PATH=""				# file name
	declare       _LINE=""				# work variable
	declare       _NAME=""				# variable name
	declare       _VALU=""				# value

	# --- common configuration file -------------------------------------------
	              _PATH_CONF="/srv/user/share/conf/_data/common.cfg"
	for _PATH in \
		"${PWD:+"${PWD}/${_PATH_CONF##*/}"}" \
		"${_PATH_CONF}"
	do
		if [[ -f "${_PATH}" ]]; then
			_PATH_CONF="${_PATH}"
			break
		fi
	done
	readonly      _PATH_CONF

	# --- default value when empty --------------------------------------------
	_DIRS_TOPS="${_DIRS_TOPS:-/srv}"
	_DIRS_HGFS="${_DIRS_HGFS:-:_DIRS_TOPS_:/hgfs}"
	_DIRS_HTML="${_DIRS_HTML:-:_DIRS_TOPS_:/http/html}"
	_DIRS_SAMB="${_DIRS_SAMB:-:_DIRS_TOPS_:/samba}"
	_DIRS_TFTP="${_DIRS_TFTP:-:_DIRS_TOPS_:/tftp}"
	_DIRS_USER="${_DIRS_USER:-:_DIRS_TOPS_:/user}"
	_DIRS_SHAR="${_DIRS_SHAR:-:_DIRS_USER_:/share}"
	_DIRS_CONF="${_DIRS_CONF:-:_DIRS_SHAR_:/conf}"
	_DIRS_DATA="${_DIRS_DATA:-:_DIRS_CONF_:/_data}"
	_DIRS_KEYS="${_DIRS_KEYS:-:_DIRS_CONF_:/_keyring}"
	_DIRS_TMPL="${_DIRS_TMPL:-:_DIRS_CONF_:/_template}"
	_DIRS_SHEL="${_DIRS_SHEL:-:_DIRS_CONF_:/script}"
	_DIRS_IMGS="${_DIRS_IMGS:-:_DIRS_SHAR_:/imgs}"
	_DIRS_ISOS="${_DIRS_ISOS:-:_DIRS_SHAR_:/isos}"
	_DIRS_LOAD="${_DIRS_LOAD:-:_DIRS_SHAR_:/load}"
	_DIRS_RMAK="${_DIRS_RMAK:-:_DIRS_SHAR_:/rmak}"
#	_PATH_CONF="${_PATH_CONF:-:_DIRS_DATA_:/common.cfg}"
	_PATH_MDIA="${_PATH_MDIA:-:_DIRS_DATA_:/media.dat}"
	_CONF_KICK="${_CONF_KICK:-:_DIRS_TMPL_:/kickstart_rhel.cfg}"
	_CONF_CLUD="${_CONF_CLUD:-:_DIRS_TMPL_:/user-data_ubuntu}"
	_CONF_SEDD="${_CONF_SEDD:-:_DIRS_TMPL_:/preseed_debian.cfg}"
	_CONF_SEDU="${_CONF_SEDU:-:_DIRS_TMPL_:/preseed_ubuntu.cfg}"
	_CONF_YAST="${_CONF_YAST:-:_DIRS_TMPL_:/yast_opensuse.xml}"
	_SHEL_ERLY="${_SHEL_ERLY:-:_DIRS_SHEL_:/cmd_early.sh}"
	_SHEL_LATE="${_SHEL_LATE:-:_DIRS_SHEL_:/cmd_late.sh}"
	_SHEL_PART="${_SHEL_PART:-:_DIRS_SHEL_:/cmd_partition.sh}"
	_SHEL_RUNS="${_SHEL_RUNS:-:_DIRS_SHEL_:/cmd_run.sh}"
	_SRVR_PROT="${_SRVR_PROT:-http}"
	_SRVR_NICS="${_SRVR_NICS:-"$(LANG=C ip -0 -brief address show scope global | awk '$1!="lo" {print $1;}')"}"
	_SRVR_MADR="${_SRVR_MADR:-"$(LANG=C ip -0 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {print $3;}')"}"
	if [[ -z "${_SRVR_ADDR:-}" ]]; then
		_SRVR_ADDR="${_SRVR_ADDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[1];}')"}"
		if ip -4 -oneline address show dev "${_SRVR_NICS}" 2> /dev/null | grep -qE '[ \t]dynamic[ \t]'; then
			_SRVR_UADR="${_SRVR_UADR:-"${_SRVR_ADDR%.*}"}"
			_SRVR_ADDR=""
		fi
	fi
	_SRVR_CIDR="${_SRVR_CIDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[2];}')"}"
	_SRVR_MASK="${_SRVR_MASK:-"$(funcIPv4GetNetmask "${_SRVR_CIDR}")"}"
	_SRVR_GWAY="${_SRVR_GWAY:-"$(LANG=C ip -4 -brief route list match default | awk '{print $3;}')"}"
	if command -v resolvectl > /dev/null 2>&1; then
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns    | sed -ne '/^Global:/             s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns    | sed -ne '/('"${_SRVR_NICS}"'):/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p')"}"
	fi
	_SRVR_NSVR="${_SRVR_NSVR:-"$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' /etc/resolv.conf)"}"
	_SRVR_UADR="${_SRVR_UADR:-"${_SRVR_ADDR%.*}"}"
	_NWRK_HOST="${_NWRK_HOST:-sv-:_DISTRO_:}"
	_NWRK_WGRP="${_NWRK_WGRP:-workgroup}"
	_NICS_NAME="${_NICS_NAME:-"${_SRVR_NICS}"}"
	_NICS_MADR="${_NICS_MADR:-"${_SRVR_MADR}"}"
	_IPV4_ADDR="${_IPV4_ADDR:-"${_SRVR_UADR}".1}"
	_IPV4_CIDR="${_IPV4_CIDR:-"${_SRVR_CIDR}"}"
	_IPV4_MASK="${_IPV4_MASK:-"$(funcIPv4GetNetmask "${_IPV4_CIDR}")"}"
	_IPV4_GWAY="${_IPV4_GWAY:-"${_SRVR_GWAY}"}"
	_IPV4_NSVR="${_IPV4_NSVR:-"${_SRVR_NSVR}"}"
	_IPV4_UADR="${_IPV4_UADR:-"${_SRVR_UADR}"}"
#	_NMAN_NAME="${_NMAN_NAME:-""}"
	_MENU_TOUT="${_MENU_TOUT:-50}"
	_MENU_RESO="${_MENU_RESO:-1024x768}"
	_MENU_DPTH="${_MENU_DPTH:-16}"
	_MENU_MODE="${_MENU_MODE:-791}"

	# --- gets the setting value ----------------------------------------------
	while read -r _LINE
	do
		_LINE="${_LINE%%#*}"
		_LINE="${_LINE//["${IFS}"]/ }"
		_LINE="${_LINE#"${_LINE%%[!"${IFS}"]*}"}"	# ltrim
		_LINE="${_LINE%"${_LINE##*[!"${IFS}"]}"}"	# rtrim
		_NAME="${_LINE%%=*}"
		_VALU="${_LINE#*=}"
		_VALU="${_VALU#\"}"
		_VALU="${_VALU%\"}"
		case "${_NAME:-}" in
			DIRS_TOPS) _DIRS_TOPS="${_VALU:-"${_DIRS_TOPS:-}"}";;
			DIRS_HGFS) _DIRS_HGFS="${_VALU:-"${_DIRS_HGFS:-}"}";;
			DIRS_HTML) _DIRS_HTML="${_VALU:-"${_DIRS_HTML:-}"}";;
			DIRS_SAMB) _DIRS_SAMB="${_VALU:-"${_DIRS_SAMB:-}"}";;
			DIRS_TFTP) _DIRS_TFTP="${_VALU:-"${_DIRS_TFTP:-}"}";;
			DIRS_USER) _DIRS_USER="${_VALU:-"${_DIRS_USER:-}"}";;
			DIRS_SHAR) _DIRS_SHAR="${_VALU:-"${_DIRS_SHAR:-}"}";;
			DIRS_CONF) _DIRS_CONF="${_VALU:-"${_DIRS_CONF:-}"}";;
			DIRS_DATA) _DIRS_DATA="${_VALU:-"${_DIRS_DATA:-}"}";;
			DIRS_KEYS) _DIRS_KEYS="${_VALU:-"${_DIRS_KEYS:-}"}";;
			DIRS_TMPL) _DIRS_TMPL="${_VALU:-"${_DIRS_TMPL:-}"}";;
			DIRS_SHEL) _DIRS_SHEL="${_VALU:-"${_DIRS_SHEL:-}"}";;
			DIRS_IMGS) _DIRS_IMGS="${_VALU:-"${_DIRS_IMGS:-}"}";;
			DIRS_ISOS) _DIRS_ISOS="${_VALU:-"${_DIRS_ISOS:-}"}";;
			DIRS_LOAD) _DIRS_LOAD="${_VALU:-"${_DIRS_LOAD:-}"}";;
			DIRS_RMAK) _DIRS_RMAK="${_VALU:-"${_DIRS_RMAK:-}"}";;
#			PATH_CONF) _PATH_CONF="${_VALU:-"${_PATH_CONF:-}"}";;
			PATH_MDIA) _PATH_MDIA="${_VALU:-"${_PATH_MDIA:-}"}";;
			CONF_KICK) _CONF_KICK="${_VALU:-"${_CONF_KICK:-}"}";;
			CONF_CLUD) _CONF_CLUD="${_VALU:-"${_CONF_CLUD:-}"}";;
			CONF_SEDD) _CONF_SEDD="${_VALU:-"${_CONF_SEDD:-}"}";;
			CONF_SEDU) _CONF_SEDU="${_VALU:-"${_CONF_SEDU:-}"}";;
			CONF_YAST) _CONF_YAST="${_VALU:-"${_CONF_YAST:-}"}";;
			SHEL_ERLY) _SHEL_ERLY="${_VALU:-"${_SHEL_ERLY:-}"}";;
			SHEL_LATE) _SHEL_LATE="${_VALU:-"${_SHEL_LATE:-}"}";;
			SHEL_PART) _SHEL_PART="${_VALU:-"${_SHEL_PART:-}"}";;
			SHEL_RUNS) _SHEL_RUNS="${_VALU:-"${_SHEL_RUNS:-}"}";;
			SRVR_PROT) _SRVR_PROT="${_VALU:-"${_SRVR_PROT:-}"}";;
			SRVR_NICS) _SRVR_NICS="${_VALU:-"${_SRVR_NICS:-}"}";;
			SRVR_MADR) _SRVR_MADR="${_VALU:-"${_SRVR_MADR:-}"}";;
			SRVR_ADDR) _SRVR_ADDR="${_VALU:-"${_SRVR_ADDR:-}"}";;
			SRVR_CIDR) _SRVR_CIDR="${_VALU:-"${_SRVR_CIDR:-}"}";;
			SRVR_MASK) _SRVR_MASK="${_VALU:-"${_SRVR_MASK:-}"}";;
			SRVR_GWAY) _SRVR_GWAY="${_VALU:-"${_SRVR_GWAY:-}"}";;
			SRVR_NSVR) _SRVR_NSVR="${_VALU:-"${_SRVR_NSVR:-}"}";;
			SRVR_UADR) _SRVR_UADR="${_VALU:-"${_SRVR_UADR:-}"}";;
			NWRK_HOST) _NWRK_HOST="${_VALU:-"${_NWRK_HOST:-}"}";;
			NWRK_WGRP) _NWRK_WGRP="${_VALU:-"${_NWRK_WGRP:-}"}";;
			NICS_NAME) _NICS_NAME="${_VALU:-"${_NICS_NAME:-}"}";;
#			NICS_MADR) _NICS_MADR="${_VALU:-"${_NICS_MADR:-}"}";;
			IPV4_ADDR) _IPV4_ADDR="${_VALU:-"${_IPV4_ADDR:-}"}";;
			IPV4_CIDR) _IPV4_CIDR="${_VALU:-"${_IPV4_CIDR:-}"}";;
			IPV4_MASK) _IPV4_MASK="${_VALU:-"${_IPV4_MASK:-}"}";;
			IPV4_GWAY) _IPV4_GWAY="${_VALU:-"${_IPV4_GWAY:-}"}";;
			IPV4_NSVR) _IPV4_NSVR="${_VALU:-"${_IPV4_NSVR:-}"}";;
#			IPV4_UADR) _IPV4_UADR="${_VALU:-"${_IPV4_UADR:-}"}";;
#			NMAN_NAME) _NMAN_NAME="${_VALU:-"${_NMAN_NAME:-}"}";;
			MENU_TOUT) _MENU_TOUT="${_VALU:-"${_MENU_TOUT:-}"}";;
			MENU_RESO) _MENU_RESO="${_VALU:-"${_MENU_RESO:-}"}";;
			MENU_DPTH) _MENU_DPTH="${_VALU:-"${_MENU_DPTH:-}"}";;
			MENU_MODE) _MENU_MODE="${_VALU:-"${_MENU_MODE:-}"}";;
			*        ) ;;
		esac
	done < <(cat "${_PATH_CONF:-}" 2> /dev/null || true)

	# --- variable substitution -----------------------------------------------
	_DIRS_TOPS="${_DIRS_TOPS:?}"
	_DIRS_HGFS="${_DIRS_HGFS//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_HTML="${_DIRS_HTML//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_SAMB="${_DIRS_SAMB//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_TFTP="${_DIRS_TFTP//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_USER="${_DIRS_USER//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
	_DIRS_SHAR="${_DIRS_SHAR//:_DIRS_USER_:/"${_DIRS_USER}"}"
	_DIRS_CONF="${_DIRS_CONF//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
	_DIRS_DATA="${_DIRS_DATA//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
	_DIRS_KEYS="${_DIRS_KEYS//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
	_DIRS_TMPL="${_DIRS_TMPL//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
	_DIRS_SHEL="${_DIRS_SHEL//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
	_DIRS_IMGS="${_DIRS_IMGS//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
	_DIRS_ISOS="${_DIRS_ISOS//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
	_DIRS_LOAD="${_DIRS_LOAD//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
	_DIRS_RMAK="${_DIRS_RMAK//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
#	_PATH_CONF="${_PATH_CONF//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_PATH_MDIA="${_PATH_MDIA//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_CONF_KICK="${_CONF_KICK//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_CLUD="${_CONF_CLUD//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_SEDD="${_CONF_SEDD//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_SEDU="${_CONF_SEDU//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_YAST="${_CONF_YAST//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_SHEL_ERLY="${_SHEL_ERLY//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_LATE="${_SHEL_LATE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_PART="${_SHEL_PART//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_RUNS="${_SHEL_RUNS//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
#	_SRVR_PROT="${_SRVR_PROT:-}"
#	_SRVR_NICS="${_SRVR_NICS:-}"
#	_SRVR_MADR="${_SRVR_MADR:-}"
#	_SRVR_ADDR="${_SRVR_ADDR:-}"
#	_SRVR_CIDR="${_SRVR_CIDR:-}"
#	_SRVR_MASK="${_SRVR_MASK:-}"
#	_SRVR_GWAY="${_SRVR_GWAY:-}"
#	_SRVR_NSVR="${_SRVR_NSVR:-}"
#	_SRVR_UADR="${_SRVR_UADR:-}"
#	_NWRK_HOST="${_NWRK_HOST:-}"
#	_NWRK_WGRP="${_NWRK_WGRP:-}"
#	_NICS_NAME="${_NICS_NAME:-}"
#	_NICS_MADR="${_NICS_MADR:-}"
	_IPV4_ADDR="${_IPV4_ADDR//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
#	_IPV4_CIDR="${_IPV4_CIDR:-}"
#	_IPV4_MASK="${_IPV4_MASK:-}"
	_IPV4_GWAY="${_IPV4_GWAY//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
	_IPV4_NSVR="${_IPV4_NSVR//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
#	_IPV4_UADR="${_IPV4_UADR:-}"
#	_NMAN_NAME="${_NMAN_NAME:-}"
#	_MENU_TOUT="${_MENU_TOUT:-}"
#	_MENU_RESO="${_MENU_RESO:-}"
#	_MENU_DPTH="${_MENU_DPTH:-}"
#	_MENU_MODE="${_MENU_MODE:-}"

	# --- making variables read-only ------------------------------------------
	readonly      _DIRS_TOPS
	readonly      _DIRS_HGFS
	readonly      _DIRS_HTML
	readonly      _DIRS_SAMB
	readonly      _DIRS_TFTP
	readonly      _DIRS_USER
	readonly      _DIRS_SHAR
	readonly      _DIRS_CONF
	readonly      _DIRS_DATA
	readonly      _DIRS_KEYS
	readonly      _DIRS_TMPL
	readonly      _DIRS_IMGS
	readonly      _DIRS_ISOS
	readonly      _DIRS_LOAD
	readonly      _DIRS_RMAK
#	readonly      _PATH_CONF
	readonly      _PATH_MDIA
	readonly      _CONF_KICK
	readonly      _CONF_CLUD
	readonly      _CONF_SEDD
	readonly      _CONF_SEDU
	readonly      _CONF_YAST
	readonly      _SRVR_PROT
	readonly      _SRVR_NICS
	readonly      _SRVR_MADR
	readonly      _SRVR_ADDR
	readonly      _SRVR_CIDR
	readonly      _SRVR_MASK
	readonly      _SRVR_GWAY
	readonly      _SRVR_NSVR
	readonly      _SRVR_UADR
	readonly      _NWRK_HOST
	readonly      _NWRK_WGRP
	readonly      _NICS_NAME
	readonly      _IPV4_ADDR
	readonly      _IPV4_CIDR
	readonly      _IPV4_MASK
	readonly      _IPV4_GWAY
	readonly      _IPV4_NSVR
	readonly      _MENU_TOUT
	readonly      _MENU_RESO
	readonly      _MENU_DPTH
	readonly      _MENU_MODE
}

# --- create common configuration file ----------------------------------------
function funcCreate_conf() {
	declare -r    _TMPL="${_PATH_CONF:?}.template"
	declare       _RNAM=""
	declare       _PATH=""

	# --- check file exists ---------------------------------------------------
	if [[ -f "${_TMPL:?}" ]]; then
		_RNAM="${_TMPL}.$(TZ=UTC find "${_TMPL}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		mv "${_TMPL}" "${_RNAM}"
	fi

	# --- delete old files ----------------------------------------------------
	for _PATH in $(find "${_TMPL%/*}" -name "${_TMPL##*/}"\* | sort -r | tail -n +3)
	do
		rm -f "${_PATH:?}"
	done

	# --- exporting files -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_TMPL}"
		###############################################################################
		##
		##	common configuration file
		##
		###############################################################################
		
		# === for server environments =================================================
		
		# --- shared directory parameter ----------------------------------------------
		DIRS_TOPS="${_DIRS_TOPS:?}"						# top of shared directory
		DIRS_HGFS="${_DIRS_HGFS//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"			# vmware shared
		DIRS_HTML="${_DIRS_HTML//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"		# html contents
		DIRS_SAMB="${_DIRS_SAMB//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"			# samba shared
		DIRS_TFTP="${_DIRS_TFTP//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"			# tftp contents
		DIRS_USER="${_DIRS_USER//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"			# user file
		
		# --- shared of user file -----------------------------------------------------
		DIRS_SHAR="${_DIRS_SHAR//"${_DIRS_USER}"/:_DIRS_USER_:}"			# shared of user file
		DIRS_CONF="${_DIRS_CONF//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# configuration file
		DIRS_DATA="${_DIRS_DATA//"${_DIRS_CONF}"/:_DIRS_CONF_:}"			# data file
		DIRS_KEYS="${_DIRS_KEYS//"${_DIRS_CONF}"/:_DIRS_CONF_:}"		# keyring file
		DIRS_TMPL="${_DIRS_TMPL//"${_DIRS_CONF}"/:_DIRS_CONF_:}"		# templates for various configuration files
		DIRS_SHEL="${_DIRS_SHEL//"${_DIRS_CONF}"/:_DIRS_CONF_:}"		# shell script file
		DIRS_IMGS="${_DIRS_IMGS//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# iso file extraction destination
		DIRS_ISOS="${_DIRS_ISOS//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# iso file
		DIRS_LOAD="${_DIRS_LOAD//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# load module
		DIRS_RMAK="${_DIRS_RMAK//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"			# remake file
		
		# --- common data file --------------------------------------------------------
		#PATH_CONF="${_PATH_CONF//"${_DIRS_DATA}"/:_DIRS_DATA_:}"	# common configuration file (this file)
		PATH_MDIA="${_PATH_MDIA//"${_DIRS_DATA}"/:_DIRS_DATA_:}"		# media data file
		
		# --- pre-configuration file templates ----------------------------------------
		CONF_KICK="${_CONF_KICK//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for rhel
		CONF_CLUD="${_CONF_CLUD//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"		# for ubuntu cloud-init
		CONF_SEDD="${_CONF_SEDD//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for debian
		CONF_SEDU="${_CONF_SEDU//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for ubuntu
		CONF_YAST="${_CONF_YAST//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"		# for opensuse
		
		# --- shell script ------------------------------------------------------------
		SHEL_ERLY="${_SHEL_ERLY//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"			# run early
		SHEL_LATE="${_SHEL_LATE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"			# run late
		SHEL_PART="${_SHEL_PART//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"		# run after partition
		SHEL_RUNS="${_SHEL_RUNS//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"			# run preseed/run
		
		# --- tftp / web server network parameter -------------------------------------
		SRVR_PROT="${_SRVR_PROT:-}"						# server connection protocol (http or tftp)
		SRVR_NICS="${_SRVR_NICS:-}"						# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
		SRVR_MADR="${_SRVR_MADR//[!:]/0}"			# "              mac    (ex. 00:00:00:00:00:00)
		SRVR_ADDR="${_SRVR_ADDR:-}"				# IPv4 address          (ex. 192.168.1.11)
		SRVR_CIDR="${_SRVR_CIDR:-}"							# IPv4 cidr             (ex. 24)
		SRVR_MASK="${_SRVR_MASK:-}"				# IPv4 subnetmask       (ex. 255.255.255.0)
		SRVR_GWAY="${_SRVR_GWAY:-}"				# IPv4 gateway          (ex. 192.168.1.254)
		SRVR_NSVR="${_SRVR_NSVR:-}"				# IPv4 nameserver       (ex. 192.168.1.254)
		
		# === for creations ===========================================================
		
		# --- network parameter -------------------------------------------------------
		NWRK_HOST="${_NWRK_HOST:-}"				# hostname
		NWRK_WGRP="${_NWRK_WGRP:-}"					# domain
		NICS_NAME="${_NICS_NAME:-}"						# network device name
		IPV4_ADDR="${_IPV4_ADDR:-}"					# IPv4 address
		IPV4_CIDR="${_IPV4_CIDR:-}"							# IPv4 cidr (empty to ipv4 subnetmask, if both to 24)
		IPV4_MASK="${_IPV4_MASK:-}"				# IPv4 subnetmask (empty to ipv4 cidr)
		IPV4_GWAY="${_IPV4_GWAY:-}"				# IPv4 gateway
		IPV4_NSVR="${_IPV4_NSVR:-}"				# IPv4 nameserver
		
		# --- menu timeout ------------------------------------------------------------
		MENU_TOUT="${_MENU_TOUT:-}"							# timeout [x100 m sec]
		
		# --- menu resolution ---------------------------------------------------------
		MENU_RESO="${_MENU_RESO:-}"					# resolution ([width]x[height])
		MENU_DPTH="${_MENU_DPTH:-}"							# colors
		
		# --- screen mode (vga=nnn) ---------------------------------------------------
		MENU_MODE="${_MENU_MODE:-}"							# mode (vga=nnn)
		
		### eof #######################################################################
_EOT_
}
