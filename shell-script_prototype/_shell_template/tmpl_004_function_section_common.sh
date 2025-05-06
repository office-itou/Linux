# *** function section (sub functions) ****************************************

# === <common> ================================================================

# --- initialization ----------------------------------------------------------
function funcInitialization() {
	declare       _PATH=""				# file name
	declare       _WORK=""				# work variables
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
	_SHEL_ERLY="${_SHEL_ERLY:-:_DIRS_SHEL_:/autoinst_cmd_early.sh}"
	_SHEL_LATE="${_SHEL_LATE:-:_DIRS_SHEL_:/autoinst_cmd_late.sh}"
	_SHEL_PART="${_SHEL_PART:-:_DIRS_SHEL_:/autoinst_cmd_part.sh}"
	_SHEL_RUNS="${_SHEL_RUNS:-:_DIRS_SHEL_:/autoinst_cmd_run.sh}"
	_SRVR_PROT="${_SRVR_PROT:-http}"
	_SRVR_NICS="${_SRVR_NICS:-"$(LANG=C ip -0 -brief address show scope global | awk '$1!="lo" {print $1;}' || true)"}"
	_SRVR_MADR="${_SRVR_MADR:-"$(LANG=C ip -0 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {print $3;}' || true)"}"
	if [[ -z "${_SRVR_ADDR:-}" ]]; then
		_SRVR_ADDR="${_SRVR_ADDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[1];}' || true)"}"
		_WORK="$(ip -4 -oneline address show dev "${_SRVR_NICS}" 2> /dev/null)"
		if echo "${_WORK}" | grep -qE '[ \t]dynamic[ \t]'; then
			_SRVR_UADR="${_SRVR_UADR:-"${_SRVR_ADDR%.*}"}"
			_SRVR_ADDR=""
		fi
	fi
	_SRVR_CIDR="${_SRVR_CIDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[2];}' || true)"}"
	_SRVR_MASK="${_SRVR_MASK:-"$(funcIPv4GetNetmask "${_SRVR_CIDR}")"}"
	_SRVR_GWAY="${_SRVR_GWAY:-"$(LANG=C ip -4 -brief route list match default | awk '{print $3;}' || true)"}"
	if command -v resolvectl > /dev/null 2>&1; then
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns    | sed -ne '/^Global:/             s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' || true)"}"
		_SRVR_NSVR="${_SRVR_NSVR:-"$(resolvectl dns    | sed -ne '/('"${_SRVR_NICS}"'):/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' || true)"}"
	fi
	_SRVR_NSVR="${_SRVR_NSVR:-"$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' /etc/resolv.conf)"}"
	if [[ "${_SRVR_NSVR:-}" = "127.0.0.53" ]]; then
		_SRVR_NSVR="$(sed -ne '/^nameserver/ s/^.*[ \t]\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)[ \t]*.*$/\1/p' /run/systemd/resolve/resolv.conf)"
	fi
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
	_MENU_TOUT="${_MENU_TOUT:-5}"
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

	# --- directory list ------------------------------------------------------
	_LIST_DIRS=(                                                                                                        \
		"${_DIRS_TOPS:?}"                                                                                               \
		"${_DIRS_HGFS:?}"                                                                                               \
		"${_DIRS_HTML:?}"                                                                                               \
		"${_DIRS_SAMB:?}"/{cifs,data/{adm/{netlogon,profiles},arc,bak,pub,usr},dlna/{movies,others,photos,sounds}}      \
		"${_DIRS_TFTP:?}"/{boot/grub/{fonts,i386-{efi,pc},locale,x86_64-efi},ipxe,menu-{bios,efi64}/pxelinux.cfg}       \
		"${_DIRS_USER:?}"                                                                                               \
		"${_DIRS_SHAR:?}"                                                                                               \
		"${_DIRS_CONF:?}"/{autoyast,kickstart,nocloud,preseed,windows}                                                  \
		"${_DIRS_DATA:?}"                                                                                               \
		"${_DIRS_KEYS:?}"                                                                                               \
		"${_DIRS_TMPL:?}"                                                                                               \
		"${_DIRS_SHEL:?}"                                                                                               \
		"${_DIRS_IMGS:?}"                                                                                               \
		"${_DIRS_ISOS:?}"                                                                                               \
		"${_DIRS_LOAD:?}"                                                                                               \
		"${_DIRS_RMAK:?}"                                                                                               \
	)
	readonly      _LIST_DIRS

	# --- symbolic link list --------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	_LIST_LINK=(                                                                                                        \
		"a  ${_DIRS_CONF:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_IMGS:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_ISOS:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_LOAD:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_RMAK:?}                                     ${_DIRS_HTML:?}/"                                       \
		"a  ${_DIRS_IMGS:?}                                     ${_DIRS_TFTP:?}/"                                       \
		"a  ${_DIRS_ISOS:?}                                     ${_DIRS_TFTP:?}/"                                       \
		"a  ${_DIRS_LOAD:?}                                     ${_DIRS_TFTP:?}/"                                       \
		"r  ${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                             \
		"r  ${_DIRS_TFTP:?}/menu-bios/syslinux.cfg              ${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"         \
		"r  ${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                            \
		"r  ${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg             ${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"        \
	)
	readonly      _LIST_LINK

	# --- autoinstall configuration file --------------------------------------
	              _AUTO_INST="autoinst.cfg"
	readonly      _AUTO_INST

	# --- initial ram disk of mini.iso including preseed ----------------------
	              _MINI_IRAM="initps.gz"
	readonly      _MINI_IRAM

	# --- get media data ------------------------------------------------------
	funcGet_media_data
}

# --- create common configuration file ----------------------------------------
function funcCreate_conf() {
	declare -r    _TMPL="${_PATH_CONF:?}.template"
	declare       _RNAM=""				# rename path
	declare       _PATH=""				# file name

	# --- check file exists ---------------------------------------------------
	if [[ -f "${_TMPL:?}" ]]; then
		_RNAM="${_TMPL}.$(TZ=UTC find "${_TMPL}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		mv "${_TMPL}" "${_RNAM}"
	fi

	# --- delete old files ----------------------------------------------------
	for _PATH in $(find "${_TMPL%/*}" -name "${_TMPL##*/}"\* | sort -r | tail -n +3 || true)
	do
		rm -f "${_PATH:?}"
	done

	# --- exporting files -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_TMPL}" || true
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
		SHEL_ERLY="${_SHEL_ERLY//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run early
		SHEL_LATE="${_SHEL_LATE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run late
		SHEL_PART="${_SHEL_PART//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run after partition
		SHEL_RUNS="${_SHEL_RUNS//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run preseed/run
		
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
		MENU_TOUT="${_MENU_TOUT:-}"							# timeout [sec]
		
		# --- menu resolution ---------------------------------------------------------
		MENU_RESO="${_MENU_RESO:-}"					# resolution ([width]x[height])
		MENU_DPTH="${_MENU_DPTH:-}"							# colors
		
		# --- screen mode (vga=nnn) ---------------------------------------------------
		MENU_MODE="${_MENU_MODE:-}"							# mode (vga=nnn)
		
		### eof #######################################################################
_EOT_
}

# --- get media data ----------------------------------------------------------
function funcGet_media_data() {
	declare       _PATH=""				# file name
	declare       _LINE=""				# work variable

	# --- list data -----------------------------------------------------------
	_LIST_MDIA=()
	for _PATH in \
		"${PWD:+"${PWD}/${_PATH_MDIA##*/}"}" \
		"${_PATH_MDIA}"
	do
		if [[ -f "${_PATH}" ]]; then
			while IFS= read -r -d $'\n' _LINE
			do
				_LINE="${_LINE//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
				_LINE="${_LINE//:_DIRS_HGFS_:/"${_DIRS_HGFS}"}"
				_LINE="${_LINE//:_DIRS_HTML_:/"${_DIRS_HTML}"}"
				_LINE="${_LINE//:_DIRS_SAMB_:/"${_DIRS_SAMB}"}"
				_LINE="${_LINE//:_DIRS_TFTP_:/"${_DIRS_TFTP}"}"
				_LINE="${_LINE//:_DIRS_USER_:/"${_DIRS_USER}"}"
				_LINE="${_LINE//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
				_LINE="${_LINE//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
				_LINE="${_LINE//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
				_LINE="${_LINE//:_DIRS_KEYS_:/"${_DIRS_KEYS}"}"
				_LINE="${_LINE//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
				_LINE="${_LINE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
				_LINE="${_LINE//:_DIRS_IMGS_:/"${_DIRS_IMGS}"}"
				_LINE="${_LINE//:_DIRS_ISOS_:/"${_DIRS_ISOS}"}"
				_LINE="${_LINE//:_DIRS_LOAD_:/"${_DIRS_LOAD}"}"
				_LINE="${_LINE//:_DIRS_RMAK_:/"${_DIRS_RMAK}"}"
				_LIST_MDIA+=("${_LINE}")
			done < "${_PATH:?}"
			if [[ -n "${_DBGS_FLAG:-}" ]]; then
				printf "[%-$((${_SIZE_COLS:-80}-2)).$((${_SIZE_COLS:-80}-2))s]\n" "${_LIST_MDIA[@]}"
			fi
			break
		fi
	done
}

# --- put media data ----------------------------------------------------------
function funcPut_media_data() {
	declare       _RNAM=""				# rename path
	declare       _LINE=""				# work variable
	declare -a    _LIST=()				# work variable
	declare -i    I=0
	declare -i    J=0

	# --- check file exists ---------------------------------------------------
	if [[ -f "${_PATH_MDIA:?}" ]]; then
		_RNAM="${_PATH_MDIA}.$(TZ=UTC find "${_PATH_MDIA}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		mv "${_PATH_MDIA}" "${_RNAM}"
	fi

	# --- delete old files ----------------------------------------------------
	for _PATH in $(find "${_PATH_MDIA%/*}" -name "${_PATH_MDIA##*/}"\* | sort -r | tail -n +3 || true)
	do
		rm -f "${_PATH:?}"
	done

	# --- list data -----------------------------------------------------------
	for I in "${!_LIST_MDIA[@]}"
	do
		_LINE="${_LIST_MDIA[I]}"
		_LINE="${_LINE//"${_DIRS_RMAK}"/:_DIRS_RMAK_:}"
		_LINE="${_LINE//"${_DIRS_LOAD}"/:_DIRS_LOAD_:}"
		_LINE="${_LINE//"${_DIRS_ISOS}"/:_DIRS_ISOS_:}"
		_LINE="${_LINE//"${_DIRS_IMGS}"/:_DIRS_IMGS_:}"
		_LINE="${_LINE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"
		_LINE="${_LINE//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"
		_LINE="${_LINE//"${_DIRS_KEYS}"/:_DIRS_KEYS_:}"
		_LINE="${_LINE//"${_DIRS_DATA}"/:_DIRS_DATA_:}"
		_LINE="${_LINE//"${_DIRS_CONF}"/:_DIRS_CONF_:}"
		_LINE="${_LINE//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"
		_LINE="${_LINE//"${_DIRS_USER}"/:_DIRS_USER_:}"
		_LINE="${_LINE//"${_DIRS_TFTP}"/:_DIRS_TFTP_:}"
		_LINE="${_LINE//"${_DIRS_SAMB}"/:_DIRS_SAMB_:}"
		_LINE="${_LINE//"${_DIRS_HTML}"/:_DIRS_HTML_:}"
		_LINE="${_LINE//"${_DIRS_HGFS}"/:_DIRS_HGFS_:}"
		_LINE="${_LINE//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"
		read -r -a _LIST < <(echo "${_LINE}")
		for J in "${!_LIST[@]}"
		do
			_LIST[J]="${_LIST[J]:--}"						# null
			_LIST[J]="${_LIST[J]// /%20}"					# blank
		done
		printf "%-15s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-31s %-15s %-15s %-85s %-31s %-15s %-43s %-85s %-31s %-15s %-43s %-85s %-85s %-85s %-31s %-85s\n" \
			"${_LIST[@]}" \
		>> "${_PATH_MDIA:?}"
	done
}

# --- create_directory --------------------------------------------------------
function fncCreate_directory() {
	declare -n    _NAME_REFR="${1:-}"	# name reference
	shift
	declare -r    _DATE_TIME="$(date +"%Y%m%d%H%M%S")"
	declare       _FORC_PRAM=""			# force parameter
	declare       _RTIV_FLAG=""			# add/relative flag
	declare       _TGET_PATH=""			# taget path
	declare       _LINK_PATH=""			# symlink path
	declare       _BACK_PATH=""			# backup path
	declare       _LINE=""				# work variable
	declare -i    I=0

	# --- option parameter ----------------------------------------------------
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			-f | --force) shift; _NAME_REFR="${*:-}"; _FORC_PRAM="true";;
			*           )        _NAME_REFR="${*:-}"; break;;
		esac
	done

	# --- create directory ----------------------------------------------------
	mkdir -p "${_LIST_DIRS[@]:?}"

	# --- create symbolic link ------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	for I in "${!_LIST_LINK[@]}"
	do
		read -r -a _LINE < <(echo "${_LIST_LINK[I]}")
		case "${_LINE[0]}" in
			a) ;;
			r) ;;
			*) continue;;
		esac
		_RTIV_FLAG="${_LINE[0]}"
		_TGET_PATH="${_LINE[1]:-}"
		_LINK_PATH="${_LINE[2]:-}"
		# --- check target file path ------------------------------------------
		if [[ -z "${_LINK_PATH##*/}" ]]; then
			_LINK_PATH="${_LINK_PATH%/}/${_TGET_PATH##*/}"
#		else
#			if [[ ! -e "${_TGET_PATH}" ]]; then
#				touch "${_TGET_PATH}"
#			fi
		fi
		# --- force parameter -------------------------------------------------
		_BACK_PATH="${_LINK_PATH}.back.${_DATE_TIME}"
		if [[ -n "${_FORC_PRAM:-}" ]] && [[ -e "${_LINK_PATH}" ]] && [[ ! -e "${_BACK_PATH##*/}" ]]; then
			funcPrintf "%20.20s: %s" "move symlink" "${_LINK_PATH} -> ${_BACK_PATH##*/}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${_LINK_PATH}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${_LINK_PATH}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${_LINK_PATH}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${_LINK_PATH}"
			funcPrintf "%20.20s: %s" "move directory" "${_LINK_PATH} -> ${_BACK_PATH}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${_LINK_PATH%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${_TGET_PATH} -> ${_LINK_PATH}"
		case "${_RTIV_FLAG}" in
			r) ln -sr "${_TGET_PATH}" "${_LINK_PATH}";;
			*) ln -s  "${_TGET_PATH}" "${_LINK_PATH}";;
		esac
	done

	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a _LINE < <(echo "${_LIST_MDIA[I]}")
		case "${_LINE[1]}" in
			o) ;;
			*) continue;;
		esac
		case "${_LINE[13]}" in
			-) continue;;
			*) ;;
		esac
		case "${_LINE[25]}" in
			-) continue;;
			*) ;;
		esac
		_TGET_PATH="${_LINE[25]}/${_LINE[13]##*/}"
		_LINK_PATH="${_LINE[13]}"
		# --- check target file path ------------------------------------------
#		if [[ ! -e "${_TGET_PATH}" ]]; then
#			touch "${_TGET_PATH}"
#		fi
		# --- force parameter -------------------------------------------------
		_BACK_PATH="${_LINK_PATH}.back.${_DATE_TIME}"
		if [[ -n "${_FORC_PRAM:-}" ]] && [[ -e "${_LINK_PATH}" ]] && [[ ! -e "${_BACK_PATH##*/}" ]]; then
			funcPrintf "%20.20s: %s" "move symlink" "${_LINK_PATH} -> ${_BACK_PATH##*/}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${_LINK_PATH}" ]]; then
			funcPrintf "%20.20s: %s" "exist symlink" "${_LINK_PATH}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${_LINK_PATH}/." ]]; then
			funcPrintf "%20.20s: %s" "exist directory" "${_LINK_PATH}"
			funcPrintf "%20.20s: %s" "move directory" "${_LINK_PATH} -> ${_BACK_PATH}"
			mv "${_LINK_PATH}" "${_BACK_PATH}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${_LINK_PATH%/*}"
		# --- create symbolic link --------------------------------------------
		funcPrintf "%20.20s: %s" "create symlink" "${_TGET_PATH} -> ${_LINK_PATH}"
		ln -s "${_TGET_PATH}" "${_LINK_PATH}"
	done
}

# --- media information [new] -------------------------------------------------
#  0: type          ( 14)   TEXT           NOT NULL     media type
#  1: entry_flag    ( 15)   TEXT           NOT NULL     [m] menu, [o] output, [else] hidden
#  2: entry_name    ( 39)   TEXT           NOT NULL     entry name (unique)
#  3: entry_disp    ( 39)   TEXT           NOT NULL     entry name for display
#  4: version       ( 23)   TEXT                        version id
#  5: latest        ( 23)   TEXT                        latest version
#  6: release       ( 15)   TEXT                        release date
#  7: support       ( 15)   TEXT                        support end date
#  8: web_regexp    (143)   TEXT                        web file  regexp
#  9: web_path      (143)   TEXT                        "         path
# 10: web_tstamp    ( 31)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 11: web_size      ( 15)   BIGINT                      "         file size
# 12: web_status    ( 15)   TEXT                        "         download status
# 13: iso_path      ( 85)   TEXT                        iso image file path
# 14: iso_tstamp    ( 31)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 15: iso_size      ( 15)   BIGINT          "           file size
# 16: iso_volume    ( 43)   TEXT            "           volume id
# 17: rmk_path      ( 85)   TEXT            remaster    file path
# 18: rmk_tstamp    ( 31)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 19: rmk_size      ( 15)   BIGINT                      "         file size
# 20: rmk_volume    ( 43)   TEXT                        "         volume id
# 21: ldr_initrd    ( 85)   TEXT                        initrd    file path
# 22: ldr_kernel    ( 85)   TEXT                        kernel    file path
# 23: cfg_path      ( 85)   TEXT                        config    file path
# 24: cfg_tstamp    ( 31)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 25: lnk_path      ( 85)   TEXT                        symlink   directory or file path

# ----- create preseed.cfg ----------------------------------------------------
function funcCreate_preseed() {
	declare -r    _TGET_TGET_PATH="${1:?}"	# file name
	declare -r    _DIRS="${_TGET_PATH%/*}"	# directory name
	declare       _WORK=""				# work variables

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_TGET_PATH}"
	mkdir -p "${_DIRS}"
	cp --backup "${_CONF_SEDD}" "${_TGET_PATH}"

	# --- by generation -------------------------------------------------------
	case "${_TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${_TGET_PATH}"               \
			    -e '/packages:/a \    usrmerge '\\
			;;
		*)	;;
	esac
	case "${_TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${_TGET_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${_TGET_PATH}"               \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${_TGET_PATH}" in
		*_desktop*)
			sed -i "${_TGET_PATH}"                                              \
			    -e '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+%,\%^#.*[^\\]$% { ' \
			    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                  \
			    -e 's/^#/ /g                                                }'
			;;
		*)	;;
	esac
	# --- for ubiquity --------------------------------------------------------
	case "${_TGET_PATH}" in
		*_ubiquity_*)
			IFS= _WORK=$(
				sed -n '\%^[^#].*preseed/late_command%,\%[^\\]$%p' "${_TGET_PATH}" | \
				sed -e 's/\\/\\\\/g'                                                 \
				    -e 's/d-i/ubiquity/'                                             \
				    -e 's%preseed\/late_command%ubiquity\/success_command%'        | \
				sed -e ':l; N; s/\n/\\n/; b l;' || true
			)
			if [[ -n "${_WORK}" ]]; then
				sed -i "${_TGET_PATH}"                                   \
				    -e '\%^[^#].*preseed/late_command%,\%[^\\]$%     { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } ' \
				    -e '\%^[^#].*ubiquity/success_command%,\%[^\\]$% { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } '
				sed -i "${_TGET_PATH}"                                    \
				    -e "\%ubiquity/success_command%i \\${_WORK}"
			fi
			sed -i "${_TGET_PATH}"                        \
			    -e "\%ubiquity/download_updates% s/^#/ /" \
			    -e "\%ubiquity/use_nonfree%      s/^#/ /" \
			    -e "\%ubiquity/reboot%           s/^#/ /"
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	chmod ugo-x "${_TGET_PATH}"
}

# ----- create nocloud --------------------------------------------------------
function funcCreate_nocloud() {
	declare -r    _TGET_TGET_PATH="${1:?}"	# file name
	declare -r    _DIRS="${_TGET_PATH%/*}"	# directory name
#	declare       _WORK=""				# work variables

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_TGET_PATH}"
	mkdir -p "${_DIRS}"
	cp --backup "${_CONF_CLUD}" "${_TGET_PATH}"

	# --- by generation -------------------------------------------------------
	case "${_TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${_TGET_PATH}"               \
			    -e '/packages:/a \    usrmerge '\\
			;;
		*)	;;
	esac
	case "${_TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${_TGET_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${_TGET_PATH}"               \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${_TGET_PATH}" in
		*_desktop.*)
			sed -i "${_TGET_PATH}"                                             \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	touch -m "${_DIRS}/meta-data"      --reference "${_TGET_PATH}"
	touch -m "${_DIRS}/network-config" --reference "${_TGET_PATH}"
#	touch -m "${_DIRS}/user-data"      --reference "${_TGET_PATH}"
	touch -m "${_DIRS}/vendor-data"    --reference "${_TGET_PATH}"
	# -------------------------------------------------------------------------
	chmod --recursive ugo-x "${_DIRS}"
}

# ----- create kickstart.cfg --------------------------------------------------
function funcCreate_kickstart() {
	declare -r    _TGET_TGET_PATH="${1:?}"	# file name
	declare -r    _DIRS="${_TGET_PATH%/*}"	# directory name
#	declare       _WORK=""				# work variables
	declare       _DSTR_VERS=""			# distribution version
	declare       _DSTR_NUMS=""			# "            number
	declare       _DSTR_NAME=""			# "            name
	declare       _DSTR_SECT=""			# "            section
	declare -r    _BASE_ARCH="x86_64"	# base architecture
	declare -r    _WEBS_ADDR="${_SRVR_PROT:+"${_SRVR_PROT}:/"}/${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}"

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_TGET_PATH}"
	mkdir -p "${_DIRS}"
	cp --backup "${_CONF_KICK}" "${_TGET_PATH}"

	# -------------------------------------------------------------------------
#	_DSTR_NUMS="\$releasever"
	_DSTR_VERS="${_TGET_PATH#*_}"
	_DSTR_VERS="${_DSTR_VERS%%_*}"
	_DSTR_NUMS="${_DSTR_VERS##*-}"
	_DSTR_NAME="${_DSTR_VERS%-*}"
	_DSTR_SECT="${_DSTR_NAME/-/ }"

	# --- initializing the settings -------------------------------------------
	sed -i "${_TGET_PATH}"                              \
	    -e "/^cdrom$/      s/^/#/                     " \
	    -e "/^url[ \t]\+/  s/^/#/g                    " \
	    -e "/^repo[ \t]\+/ s/^/#/g                    " \
	    -e "s/:_HOST_NAME_:/${_DSTR_NAME}/            " \
	    -e "s%:_WEBS_ADDR_:%${_WEBS_ADDR}%g           " \
	    -e "s%:_DISTRO_:%${_DSTR_NAME}-${_DSTR_NUMS}%g"
	# --- cdrom, repository ---------------------------------------------------
	case "${_TGET_PATH}" in
		*_dvd*)		# --- cdrom install ---------------------------------------
			sed -i "${_TGET_PATH}"                              \
			    -e "/^#cdrom$/ s/^#//                         "
			;;
		*_net*)		# --- network install -------------------------------------
			sed -i "${_TGET_PATH}"                              \
			    -e "/^#.*(${_DSTR_SECT}).*$/,/^$/           { " \
			    -e "/^#url[ \t]\+/  s/^#//g                   " \
			    -e "/^#repo[ \t]\+/ s/^#//g                 } "
			;;
		*_web*)		# --- network install [ for pxeboot ] ---------------------
			sed -i "${_TGET_PATH}"                              \
			    -e "/^#.*(web address).*$/,/^$/             { " \
			    -e "/^#url[ \t]\+/  s/^#//g                   " \
			    -e "/^#repo[ \t]\+/ s/^#//g                   " \
			    -e "s/\$releasever/${_DSTR_NUMS}/g            " \
			    -e "s/\$basearch/${_BASE_ARCH}/g            } " \
			;;
		*)	;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e "/%packages/,/%end/ {"                       \
	    -e "/desktop/ s/^-//g  }"                       \
	    "${_TGET_PATH}"                                 \
	>   "${_TGET_PATH%.*}_desktop.${_TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${_TGET_PATH}" "${_TGET_PATH%.*}_desktop.${_TGET_PATH##*.}"
}

# ----- create autoyast.xml ---------------------------------------------------
function funcCreate_autoyast() {
	declare -r    _TGET_TGET_PATH="${1:?}"	# file name
	declare -r    _DIRS="${_TGET_PATH%/*}"	# directory name
#	declare       _WORK=""				# work variables
	declare       _DSTR_VERS=""			# distribution version
	declare       _DSTR_NUMS=""			# "            number

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create file" "${_TGET_PATH}"
	mkdir -p "${_DIRS}"
	cp --backup "${_CONF_YAST}" "${_TGET_PATH}"

	# -------------------------------------------------------------------------
	_DSTR_VERS="${_TGET_PATH#*_}"
	_DSTR_VERS="${_DSTR_VERS%%_*}"
	_DSTR_NUMS="${_DSTR_VERS##*-}"

	# --- by media ------------------------------------------------------------
	case "${_TGET_PATH}" in
		*_web*|\
		*_dvd*)
			sed -i "${_TGET_PATH}"                                    \
			    -e '/<image_installation t="boolean">/ s/false/true/'
			;;
		*)
			sed -i "${_TGET_PATH}"                                    \
			    -e '/<image_installation t="boolean">/ s/true/false/'
			;;
	esac
	# --- by version ----------------------------------------------------------
	case "${_TGET_PATH}" in
		*tumbleweed*)
			sed -i "${_TGET_PATH}"                                     \
			    -e '\%<add_on_products .*>%,\%<\/add_on_products>% { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/             { ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                  } ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                 } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1openSUSE\2%    '
			;;
		*           )
			sed -i "${_TGET_PATH}"                                               \
			    -e '\%<add_on_products .*>%,\%</add_on_products>%            { ' \
			    -e '/<!-- leap/,/leap -->/                                   { ' \
			    -e "/<media_url>/ s%/\(leap\)/[0-9.]\+/%/\1/${_DSTR_NUMS}/%g } " \
			    -e '/<!-- leap$/ s/$/ -->/g                                    ' \
			    -e '/^leap -->/  s/^/<!-- /g                                 } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1Leap\2%                  '
			;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e '/<!-- desktop lxde$/ s/$/ -->/g ' \
	    -e '/^desktop lxde -->/  s/^/<!-- /g' \
	    "${_TGET_PATH}"                            \
	>   "${_TGET_PATH%.*}_desktop.${_TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${_TGET_PATH}"
}

# ----- create pre-configuration file templates -------------------------------
function funcCreate_precon() {
	declare -n    _NAME_REFR="${1:-}"	# name reference
	shift
	declare -a    _OPTN_PRAM=()			# option parameter
	declare -a    _LIST=()				# data list
	declare       _PATH=""				# file name
	declare       _TYPE=""				# configuration type
#	declare       _WORK=""				# work variables
	declare -i    I=0					# work variables

	# --- option parameter ----------------------------------------------------
	_OPTN_PRAM=()
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			all      ) _OPTN_PRAM+=("preseed" "nocloud" "kickstart" "autoyast");;
			preseed  | \
			nocloud  | \
			kickstart| \
			autoyast ) _OPTN_PRAM+=("$1");;
			*        ) break;;
		esac
		shift
	done
	_NAME_REFR="${*:-}"
	if [[ -z "${_OPTN_PRAM[*]}" ]]; then
		return
	fi

	# -------------------------------------------------------------------------
	funcPrintf "%20.20s: %s" "create pre-conf file" ""

	# -------------------------------------------------------------------------
	_LIST=()
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a _LINE < <(echo "${_LIST_MDIA[I]}")
		case "${_LINE[1]}" in			# entry_flag
			o) ;;
			*) continue;;
		esac
		case "${_LINE[23]}" in			# cfg_path
			-) continue;;
			*) ;;
		esac
		_PATH="${_LINE[23]}"
		_TYPE="${_PATH%/*}"
		_TYPE="${_TYPE##*/}"
		if ! echo "${_OPTN_PRAM[*]}" | grep -q "${_TYPE}"; then
			continue
		fi
		_LIST+=("${_PATH}")
		case "${_PATH}" in
			*dvd.*) _LIST+=("${_PATH/_dvd/_web}");;
			*)	;;
		esac
	done
	mapfile -d $'\n' -t _LIST < <(IFS=  printf "%s\n" "${_LIST[@]}" | sort -Vu || true)
	# -------------------------------------------------------------------------
	for _PATH in "${_LIST[@]}"
	do
		_TYPE="${_PATH%/*}"
		_TYPE="${_TYPE##*/}"
		case "${_TYPE}" in
			preseed  ) funcCreate_preseed   "${_PATH}";;
			nocloud  ) funcCreate_nocloud   "${_PATH}/user-data";;
			kickstart) funcCreate_kickstart "${_PATH}";;
			autoyast ) funcCreate_autoyast  "${_PATH}";;
			*)	;;
		esac
	done

	# -------------------------------------------------------------------------
	# debian_*_oldold  : debian-10(buster)
	# debian_*_old     : debian-11(bullseye)
	# debian_*         : debian-12(bookworm)/13(trixie)/14(forky)/testing/sid/~
	# ubuntu_*_oldold  : ubuntu-14.04(trusty)/16.04(xenial)/18.04(bionic)
	# ubuntu_*_old     : ubuntu-20.04(focal)/22.04(jammy)
	# ubuntu_*         : ubuntu-23.04(lunar)/~
	# ubiquity_*_oldold: ubuntu-14.04(trusty)/16.04(xenial)/18.04(bionic)
	# ubiquity_*_old   : ubuntu-20.04(focal)/22.04(jammy)
	# ubiquity_*       : ubuntu-23.04(lunar)/~
	# -------------------------------------------------------------------------
}
