# *** function section (sub functions) ****************************************

# --- initialization ----------------------------------------------------------
function funcInitialization() {
	declare       _LINE=""				# work variable
	declare       _NAME=""				# variable name
	declare       _VALU=""				# value

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
			DIRS_TOPS) _DIRS_TOPS="${_VALU:-}";;
			DIRS_HGFS) _DIRS_HGFS="${_VALU:-}";;
			DIRS_HTML) _DIRS_HTML="${_VALU:-}";;
			DIRS_SAMB) _DIRS_SAMB="${_VALU:-}";;
			DIRS_TFTP) _DIRS_TFTP="${_VALU:-}";;
			DIRS_USER) _DIRS_USER="${_VALU:-}";;
			DIRS_SHAR) _DIRS_SHAR="${_VALU:-}";;
			DIRS_CONF) _DIRS_CONF="${_VALU:-}";;
			DIRS_DATA) _DIRS_DATA="${_VALU:-}";;
			DIRS_KEYS) _DIRS_KEYS="${_VALU:-}";;
			DIRS_TMPL) _DIRS_TMPL="${_VALU:-}";;
			DIRS_SHEL) _DIRS_SHEL="${_VALU:-}";;
			DIRS_IMGS) _DIRS_IMGS="${_VALU:-}";;
			DIRS_ISOS) _DIRS_ISOS="${_VALU:-}";;
			DIRS_LOAD) _DIRS_LOAD="${_VALU:-}";;
			DIRS_RMAK) _DIRS_RMAK="${_VALU:-}";;
			PATH_CONF) _PATH_CONF="${_VALU:-}";;
			PATH_MDIA) _PATH_MDIA="${_VALU:-}";;
			CONF_KICK) _CONF_KICK="${_VALU:-}";;
			CONF_CLUD) _CONF_CLUD="${_VALU:-}";;
			CONF_SEDD) _CONF_SEDD="${_VALU:-}";;
			CONF_SEDU) _CONF_SEDU="${_VALU:-}";;
			CONF_YAST) _CONF_YAST="${_VALU:-}";;
			SHEL_ERLY) _SHEL_ERLY="${_VALU:-}";;
			SHEL_LATE) _SHEL_LATE="${_VALU:-}";;
			SHEL_PART) _SHEL_PART="${_VALU:-}";;
			SHEL_RUNS) _SHEL_RUNS="${_VALU:-}";;
			SRVR_PROT) _SRVR_PROT="${_VALU:-}";;
			SRVR_ADDR) _SRVR_ADDR="${_VALU:-}";;
			SRVR_UADR) _SRVR_UADR="${_VALU:-}";;
			HOST_NAME) _HOST_NAME="${_VALU:-}";;
			WGRP_NAME) _WGRP_NAME="${_VALU:-}";;
			ETHR_NAME) _ETHR_NAME="${_VALU:-}";;
			IPV4_ADDR) _IPV4_ADDR="${_VALU:-}";;
			IPV4_CIDR) _IPV4_CIDR="${_VALU:-}";;
			IPV4_MASK) _IPV4_MASK="${_VALU:-}";;
			IPV4_GWAY) _IPV4_GWAY="${_VALU:-}";;
			IPV4_NSVR) _IPV4_NSVR="${_VALU:-}";;
			MENU_TOUT) _MENU_TOUT="${_VALU:-}";;
			MENU_RESO) _MENU_RESO="${_VALU:-}";;
			MENU_DPTH) _MENU_DPTH="${_VALU:-}";;
			SCRN_MODE) _SCRN_MODE="${_VALU:-}";;
			*        ) ;;
		esac
	done < <(cat /srv/user/share/conf/_data/common.cfg || true)

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
	_PATH_CONF="${_PATH_CONF:-:_DIRS_DATA_:/common.cfg}"
	_PATH_MDIA="${_PATH_MDIA:-:_DIRS_DATA_:/media.dat}"
	_CONF_KICK="${_CONF_KICK:-:_DIRS_TMPL_:/kickstart_common.cfg}"
	_CONF_CLUD="${_CONF_CLUD:-:_DIRS_TMPL_:/nocloud-ubuntu-user-data}"
	_CONF_SEDD="${_CONF_SEDD:-:_DIRS_TMPL_:/preseed_debian.cfg}"
	_CONF_SEDU="${_CONF_SEDU:-:_DIRS_TMPL_:/preseed_ubuntu.cfg}"
	_CONF_YAST="${_CONF_YAST:-:_DIRS_TMPL_:/yast_opensuse.xml}"
	_SHEL_ERLY="${_SHEL_ERLY:-:_DIRS_SHEL_:/cmd_early.sh}"
	_SHEL_LATE="${_SHEL_LATE:-:_DIRS_SHEL_:/cmd_late.sh}"
	_SHEL_PART="${_SHEL_PART:-:_DIRS_SHEL_:/cmd_partition.sh}"
	_SHEL_RUNS="${_SHEL_RUNS:-:_DIRS_SHEL_:/cmd_run.sh}"
	_SRVR_PROT="${_SRVR_PROT:-http}"
	_SRVR_ADDR="${_SRVR_ADDR:-"$(LANG=C ip -4 -oneline address show scope global | awk '{split($4,s,"/"); print s[1];}')"}"
	_SRVR_UADR="${_SRVR_UADR:-:_SRVR_ADDR_:}"
	_HOST_NAME="${_HOST_NAME:-sv-:_DISTRO_:}"
	_WGRP_NAME="${_WGRP_NAME:-workgroup}"
	_ETHR_NAME="${_ETHR_NAME:-ens160}"
	_IPV4_ADDR="${_IPV4_ADDR:-:_SRVR_UADR_:.1}"
	_IPV4_CIDR="${_IPV4_CIDR:-24}"
	_IPV4_MASK="${_IPV4_MASK:-"$(funcIPv4GetNetmask "${_IPV4_CIDR}")"}"
	_IPV4_GWAY="${_IPV4_GWAY:-:_SRVR_UADR_:.254}"
	_IPV4_NSVR="${_IPV4_NSVR:-:_SRVR_UADR_:.254}"
	_MENU_TOUT="${_MENU_TOUT:-50}"
	_MENU_RESO="${_MENU_RESO:-1024x768}"
	_MENU_DPTH="${_MENU_DPTH:-16}"
	_SCRN_MODE="${_SCRN_MODE:-791}"

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
	_PATH_CONF="${_PATH_CONF//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
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
#	_SRVR_ADDR="${_SRVR_ADDR:-}"
	_SRVR_UADR="${_SRVR_UADR//:_SRVR_ADDR_:/"${_SRVR_ADDR%.*}"}"
#	_HOST_NAME="${_HOST_NAME:-}"
#	_WGRP_NAME="${_WGRP_NAME:-}"
#	_ETHR_NAME="${_ETHR_NAME:-}"
	_IPV4_ADDR="${_IPV4_ADDR//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
#	_IPV4_CIDR="${_IPV4_CIDR:-}"
#	_IPV4_MASK="${_IPV4_MASK:-}"
	_IPV4_GWAY="${_IPV4_GWAY//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
	_IPV4_NSVR="${_IPV4_NSVR//:_SRVR_UADR_:/"${_SRVR_UADR}"}"
#	_MENU_TOUT="${_MENU_TOUT:-}"
#	_MENU_RESO="${_MENU_RESO:-}"
#	_MENU_DPTH="${_MENU_DPTH:-}"
#	_SCRN_MODE="${_SCRN_MODE:-}"

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
	readonly      _PATH_CONF
	readonly      _PATH_MDIA
	readonly      _CONF_KICK
	readonly      _CONF_CLUD
	readonly      _CONF_SEDD
	readonly      _CONF_SEDU
	readonly      _CONF_YAST
	readonly      _SRVR_PROT
	readonly      _SRVR_ADDR
	readonly      _SRVR_UADR
	readonly      _HOST_NAME
	readonly      _WGRP_NAME
	readonly      _ETHR_NAME
	readonly      _IPV4_ADDR
	readonly      _IPV4_CIDR
	readonly      _IPV4_MASK
	readonly      _IPV4_GWAY
	readonly      _IPV4_NSVR
	readonly      _MENU_TOUT
	readonly      _MENU_RESO
	readonly      _MENU_DPTH
	readonly      _SCRN_MODE
}

# --- debug out parameter -----------------------------------------------------
funcDebugout_parameter() {
	if [[ -z "${_DBGS_FLAG:-}" ]]; then
		return
	fi

	printf "%s=[%s]\n" "_PROG_PATH" "${_PROG_PATH:-}"
	printf "%s=[%s]\n" "_PROG_PARM" "${_PROG_PARM[*]:-}"
	printf "%s=[%s]\n" "_PROG_DIRS" "${_PROG_DIRS:-}"
	printf "%s=[%s]\n" "_PROG_NAME" "${_PROG_NAME:-}"
	printf "%s=[%s]\n" "_PROG_PROC" "${_PROG_PROC:-}"
	printf "%s=[%s]\n" "_DIRS_TEMP" "${_DIRS_TEMP:-}"
	printf "%s=[%s]\n" "_LIST_RMOV" "${_LIST_RMOV[*]:-}"

	printf "%s=[%s]\n" "_DIRS_TOPS" "${_DIRS_TOPS:-}"
	printf "%s=[%s]\n" "_DIRS_HGFS" "${_DIRS_HGFS:-}"
	printf "%s=[%s]\n" "_DIRS_HTML" "${_DIRS_HTML:-}"
	printf "%s=[%s]\n" "_DIRS_SAMB" "${_DIRS_SAMB:-}"
	printf "%s=[%s]\n" "_DIRS_TFTP" "${_DIRS_TFTP:-}"
	printf "%s=[%s]\n" "_DIRS_USER" "${_DIRS_USER:-}"
	printf "%s=[%s]\n" "_DIRS_SHAR" "${_DIRS_SHAR:-}"
	printf "%s=[%s]\n" "_DIRS_CONF" "${_DIRS_CONF:-}"
	printf "%s=[%s]\n" "_DIRS_DATA" "${_DIRS_DATA:-}"
	printf "%s=[%s]\n" "_DIRS_KEYS" "${_DIRS_KEYS:-}"
	printf "%s=[%s]\n" "_DIRS_TMPL" "${_DIRS_TMPL:-}"
	printf "%s=[%s]\n" "_DIRS_SHEL" "${_DIRS_SHEL:-}"
	printf "%s=[%s]\n" "_DIRS_IMGS" "${_DIRS_IMGS:-}"
	printf "%s=[%s]\n" "_DIRS_ISOS" "${_DIRS_ISOS:-}"
	printf "%s=[%s]\n" "_DIRS_LOAD" "${_DIRS_LOAD:-}"
	printf "%s=[%s]\n" "_DIRS_RMAK" "${_DIRS_RMAK:-}"
	printf "%s=[%s]\n" "_PATH_CONF" "${_PATH_CONF:-}"
	printf "%s=[%s]\n" "_PATH_MDIA" "${_PATH_MDIA:-}"
	printf "%s=[%s]\n" "_CONF_KICK" "${_CONF_KICK:-}"
	printf "%s=[%s]\n" "_CONF_CLUD" "${_CONF_CLUD:-}"
	printf "%s=[%s]\n" "_CONF_SEDD" "${_CONF_SEDD:-}"
	printf "%s=[%s]\n" "_CONF_SEDU" "${_CONF_SEDU:-}"
	printf "%s=[%s]\n" "_CONF_YAST" "${_CONF_YAST:-}"
	printf "%s=[%s]\n" "_SHEL_ERLY" "${_SHEL_ERLY:-}"
	printf "%s=[%s]\n" "_SHEL_LATE" "${_SHEL_LATE:-}"
	printf "%s=[%s]\n" "_SHEL_PART" "${_SHEL_PART:-}"
	printf "%s=[%s]\n" "_SHEL_RUNS" "${_SHEL_RUNS:-}"
	printf "%s=[%s]\n" "_SRVR_PROT" "${_SRVR_PROT:-}"
	printf "%s=[%s]\n" "_SRVR_ADDR" "${_SRVR_ADDR:-}"
	printf "%s=[%s]\n" "_SRVR_UADR" "${_SRVR_UADR:-}"
	printf "%s=[%s]\n" "_HOST_NAME" "${_HOST_NAME:-}"
	printf "%s=[%s]\n" "_WGRP_NAME" "${_WGRP_NAME:-}"
	printf "%s=[%s]\n" "_ETHR_NAME" "${_ETHR_NAME:-}"
	printf "%s=[%s]\n" "_IPV4_ADDR" "${_IPV4_ADDR:-}"
	printf "%s=[%s]\n" "_IPV4_CIDR" "${_IPV4_CIDR:-}"
	printf "%s=[%s]\n" "_IPV4_MASK" "${_IPV4_MASK:-}"
	printf "%s=[%s]\n" "_IPV4_GWAY" "${_IPV4_GWAY:-}"
	printf "%s=[%s]\n" "_IPV4_NSVR" "${_IPV4_NSVR:-}"
	printf "%s=[%s]\n" "_MENU_TOUT" "${_MENU_TOUT:-}"
	printf "%s=[%s]\n" "_MENU_RESO" "${_MENU_RESO:-}"
	printf "%s=[%s]\n" "_MENU_DPTH" "${_MENU_DPTH:-}"
	printf "%s=[%s]\n" "_SCRN_MODE" "${_SCRN_MODE:-}"
}
