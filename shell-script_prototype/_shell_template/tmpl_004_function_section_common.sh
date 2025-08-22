# shellcheck disable=SC2148
# *** function section (sub functions) ****************************************

# === <common> ================================================================

# -----------------------------------------------------------------------------
# descript: initialization
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
function fnInitialization() {
	declare       __PATH=""				# full path
	declare       __WORK=""				# work variables
	declare       __LINE=""				# work variable
	declare       __NAME=""				# variable name
	declare       __VALU=""				# value
	declare       __DEVS=""				# device name
	# --- common configuration file -------------------------------------------
	              _PATH_CONF="/srv/user/share/conf/_data/common.cfg"
	for __PATH in \
		"${PWD:+"${PWD}/${_PATH_CONF##*/}"}" \
		"${_PATH_CONF}"
	do
		if [[ -f "${__PATH}" ]]; then
			_PATH_CONF="${__PATH}"
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
	_DIRS_CHRT="${_DIRS_CHRT:-:_DIRS_SHAR_:/chroot}"
#	_PATH_CONF="${_PATH_CONF:-:_DIRS_DATA_:/common.cfg}"
	_PATH_MDIA="${_PATH_MDIA:-:_DIRS_DATA_:/media.dat}"
	_PATH_DSTP="${_PATH_DSTP:-:_DIRS_DATA_:/debstrap.dat}"
	_CONF_KICK="${_CONF_KICK:-:_DIRS_TMPL_:/kickstart_rhel.cfg}"
	_CONF_CLUD="${_CONF_CLUD:-:_DIRS_TMPL_:/user-data_ubuntu}"
	_CONF_SEDD="${_CONF_SEDD:-:_DIRS_TMPL_:/preseed_debian.cfg}"
	_CONF_SEDU="${_CONF_SEDU:-:_DIRS_TMPL_:/preseed_ubuntu.cfg}"
	_CONF_YAST="${_CONF_YAST:-:_DIRS_TMPL_:/yast_opensuse.xml}"
	_CONF_AGMA="${_CONF_AGMA:-:_DIRS_TMPL_:/agama_opensuse.json}"
	_SHEL_ERLY="${_SHEL_ERLY:-:_DIRS_SHEL_:/autoinst_cmd_early.sh}"
	_SHEL_LATE="${_SHEL_LATE:-:_DIRS_SHEL_:/autoinst_cmd_late.sh}"
	_SHEL_PART="${_SHEL_PART:-:_DIRS_SHEL_:/autoinst_cmd_part.sh}"
	_SHEL_RUNS="${_SHEL_RUNS:-:_DIRS_SHEL_:/autoinst_cmd_run.sh}"
	_SRVR_HTTP="${_SRVR_HTTP:-http}"
	_SRVR_PROT="${_SRVR_PROT:-"${_SRVR_HTTP}"}"
	_SRVR_NICS=""
	while read -r __DEVS
	do
		__VALU="$(ip -4 -brief address show dev "${__DEVS}")"
		if [[ -n "${__VALU:-}" ]]; then
			_SRVR_NICS="${__DEVS}"
			_SRVR_ADDR="$(echo "${__VALU}" | awk '{print $3;}')"
			_SRVR_CIDR="${_SRVR_ADDR##*/}"
			_SRVR_ADDR="${_SRVR_ADDR%/*}"
			break
		fi
	done < <(ls /sys/class/net/ || true)
	_SRVR_NICS="${_SRVR_NICS:-"$(LANG=C ip -0 -brief address show scope global | awk '$1!="lo" {print $1;}' || true)"}"
	_SRVR_NICS="${_SRVR_NICS%@*}"
	_SRVR_MADR="${_SRVR_MADR:-"$(LANG=C ip -0 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {print $3;}' || true)"}"
	if [[ -z "${_SRVR_ADDR:-}" ]]; then
		_SRVR_ADDR="${_SRVR_ADDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[1];}' || true)"}"
		__WORK="$(ip -4 -oneline address show dev "${_SRVR_NICS}" 2> /dev/null)"
		if echo "${__WORK}" | grep -qE '[ \t]dynamic[ \t]'; then
			_SRVR_UADR="${_SRVR_UADR:-"${_SRVR_ADDR%.*}"}"
			_SRVR_ADDR=""
		fi
	fi
	_SRVR_CIDR="${_SRVR_CIDR:-"$(LANG=C ip -4 -brief address show dev "${_SRVR_NICS}" | awk '$1!="lo" {split($3,s,"/"); print s[2];}' || true)"}"
	_SRVR_MASK="${_SRVR_MASK:-"$(fnIPv4GetNetmask "${_SRVR_CIDR}")"}"
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
	_IPV4_MASK="${_IPV4_MASK:-"$(fnIPv4GetNetmask "${_IPV4_CIDR}")"}"
	_IPV4_GWAY="${_IPV4_GWAY:-"${_SRVR_GWAY}"}"
	_IPV4_NSVR="${_IPV4_NSVR:-"${_SRVR_NSVR}"}"
	_IPV4_UADR="${_IPV4_UADR:-"${_SRVR_UADR}"}"
#	_NMAN_NAME="${_NMAN_NAME:-""}"
	_MENU_TOUT="${_MENU_TOUT:-5}"
	_MENU_RESO="${_MENU_RESO:-1024x768}"
	_MENU_DPTH="${_MENU_DPTH:-16}"
	_MENU_MODE="${_MENU_MODE:-791}"
	# --- gets the setting value ----------------------------------------------
	while read -r __LINE
	do
		__LINE="${__LINE%%#*}"
		__LINE="${__LINE//["${IFS}"]/ }"
		__LINE="${__LINE#"${__LINE%%[!"${IFS}"]*}"}"	# ltrim
		__LINE="${__LINE%"${__LINE##*[!"${IFS}"]}"}"	# rtrim
		__NAME="${__LINE%%=*}"
		__VALU="${__LINE#*=}"
		__VALU="${__VALU#\"}"
		__VALU="${__VALU%\"}"
		case "${__NAME:-}" in
			DIRS_TOPS) _DIRS_TOPS="${__VALU:-"${_DIRS_TOPS:-}"}";;
			DIRS_HGFS) _DIRS_HGFS="${__VALU:-"${_DIRS_HGFS:-}"}";;
			DIRS_HTML) _DIRS_HTML="${__VALU:-"${_DIRS_HTML:-}"}";;
			DIRS_SAMB) _DIRS_SAMB="${__VALU:-"${_DIRS_SAMB:-}"}";;
			DIRS_TFTP) _DIRS_TFTP="${__VALU:-"${_DIRS_TFTP:-}"}";;
			DIRS_USER) _DIRS_USER="${__VALU:-"${_DIRS_USER:-}"}";;
			DIRS_SHAR) _DIRS_SHAR="${__VALU:-"${_DIRS_SHAR:-}"}";;
			DIRS_CONF) _DIRS_CONF="${__VALU:-"${_DIRS_CONF:-}"}";;
			DIRS_DATA) _DIRS_DATA="${__VALU:-"${_DIRS_DATA:-}"}";;
			DIRS_KEYS) _DIRS_KEYS="${__VALU:-"${_DIRS_KEYS:-}"}";;
			DIRS_TMPL) _DIRS_TMPL="${__VALU:-"${_DIRS_TMPL:-}"}";;
			DIRS_SHEL) _DIRS_SHEL="${__VALU:-"${_DIRS_SHEL:-}"}";;
			DIRS_IMGS) _DIRS_IMGS="${__VALU:-"${_DIRS_IMGS:-}"}";;
			DIRS_ISOS) _DIRS_ISOS="${__VALU:-"${_DIRS_ISOS:-}"}";;
			DIRS_LOAD) _DIRS_LOAD="${__VALU:-"${_DIRS_LOAD:-}"}";;
			DIRS_RMAK) _DIRS_RMAK="${__VALU:-"${_DIRS_RMAK:-}"}";;
			DIRS_CHRT) _DIRS_CHRT="${__VALU:-"${_DIRS_CHRT:-}"}";;
#			PATH_CONF) _PATH_CONF="${__VALU:-"${_PATH_CONF:-}"}";;
			PATH_MDIA) _PATH_MDIA="${__VALU:-"${_PATH_MDIA:-}"}";;
			PATH_DSTP) _PATH_DSTP="${__VALU:-"${_PATH_DSTP:-}"}";;
			CONF_KICK) _CONF_KICK="${__VALU:-"${_CONF_KICK:-}"}";;
			CONF_CLUD) _CONF_CLUD="${__VALU:-"${_CONF_CLUD:-}"}";;
			CONF_SEDD) _CONF_SEDD="${__VALU:-"${_CONF_SEDD:-}"}";;
			CONF_SEDU) _CONF_SEDU="${__VALU:-"${_CONF_SEDU:-}"}";;
			CONF_YAST) _CONF_YAST="${__VALU:-"${_CONF_YAST:-}"}";;
			CONF_AGMA) _CONF_AGMA="${__VALU:-"${_CONF_AGMA:-}"}";;
			SHEL_ERLY) _SHEL_ERLY="${__VALU:-"${_SHEL_ERLY:-}"}";;
			SHEL_LATE) _SHEL_LATE="${__VALU:-"${_SHEL_LATE:-}"}";;
			SHEL_PART) _SHEL_PART="${__VALU:-"${_SHEL_PART:-}"}";;
			SHEL_RUNS) _SHEL_RUNS="${__VALU:-"${_SHEL_RUNS:-}"}";;
			SRVR_HTTP) _SRVR_HTTP="${__VALU:-"${_SRVR_HTTP:-}"}";;
			SRVR_PROT) _SRVR_PROT="${__VALU:-"${_SRVR_PROT:-}"}";;
			SRVR_NICS) _SRVR_NICS="${__VALU:-"${_SRVR_NICS:-}"}";;
			SRVR_MADR) _SRVR_MADR="${__VALU:-"${_SRVR_MADR:-}"}";;
			SRVR_ADDR) _SRVR_ADDR="${__VALU:-"${_SRVR_ADDR:-}"}";;
			SRVR_CIDR) _SRVR_CIDR="${__VALU:-"${_SRVR_CIDR:-}"}";;
			SRVR_MASK) _SRVR_MASK="${__VALU:-"${_SRVR_MASK:-}"}";;
			SRVR_GWAY) _SRVR_GWAY="${__VALU:-"${_SRVR_GWAY:-}"}";;
			SRVR_NSVR) _SRVR_NSVR="${__VALU:-"${_SRVR_NSVR:-}"}";;
			SRVR_UADR) _SRVR_UADR="${__VALU:-"${_SRVR_UADR:-}"}";;
			NWRK_HOST) _NWRK_HOST="${__VALU:-"${_NWRK_HOST:-}"}";;
			NWRK_WGRP) _NWRK_WGRP="${__VALU:-"${_NWRK_WGRP:-}"}";;
			NICS_NAME) _NICS_NAME="${__VALU:-"${_NICS_NAME:-}"}";;
#			NICS_MADR) _NICS_MADR="${__VALU:-"${_NICS_MADR:-}"}";;
			IPV4_ADDR) _IPV4_ADDR="${__VALU:-"${_IPV4_ADDR:-}"}";;
			IPV4_CIDR) _IPV4_CIDR="${__VALU:-"${_IPV4_CIDR:-}"}";;
			IPV4_MASK) _IPV4_MASK="${__VALU:-"${_IPV4_MASK:-}"}";;
			IPV4_GWAY) _IPV4_GWAY="${__VALU:-"${_IPV4_GWAY:-}"}";;
			IPV4_NSVR) _IPV4_NSVR="${__VALU:-"${_IPV4_NSVR:-}"}";;
#			IPV4_UADR) _IPV4_UADR="${__VALU:-"${_IPV4_UADR:-}"}";;
#			NMAN_NAME) _NMAN_NAME="${__VALU:-"${_NMAN_NAME:-}"}";;
			MENU_TOUT) _MENU_TOUT="${__VALU:-"${_MENU_TOUT:-}"}";;
			MENU_RESO) _MENU_RESO="${__VALU:-"${_MENU_RESO:-}"}";;
			MENU_DPTH) _MENU_DPTH="${__VALU:-"${_MENU_DPTH:-}"}";;
			MENU_MODE) _MENU_MODE="${__VALU:-"${_MENU_MODE:-}"}";;
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
	_DIRS_CHRT="${_DIRS_CHRT//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
#	_PATH_CONF="${_PATH_CONF//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_PATH_MDIA="${_PATH_MDIA//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_PATH_DSTP="${_PATH_DSTP//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
	_CONF_KICK="${_CONF_KICK//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_CLUD="${_CONF_CLUD//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_SEDD="${_CONF_SEDD//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_SEDU="${_CONF_SEDU//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_YAST="${_CONF_YAST//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_CONF_AGMA="${_CONF_AGMA//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
	_SHEL_ERLY="${_SHEL_ERLY//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_LATE="${_SHEL_LATE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_PART="${_SHEL_PART//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
	_SHEL_RUNS="${_SHEL_RUNS//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
#	_SRVR_HTTP="${_SRVR_HTTP:-}"
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
	readonly      _DIRS_CHRT
#	readonly      _PATH_CONF
	readonly      _PATH_MDIA
	readonly      _PATH_DSTP
	readonly      _CONF_KICK
	readonly      _CONF_CLUD
	readonly      _CONF_SEDD
	readonly      _CONF_SEDU
	readonly      _CONF_YAST
	readonly      _CONF_AGMA
	readonly      _SRVR_HTTP
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
	_LIST_DIRS=(                                                                                                                                                                        \
		"${_DIRS_TOPS:?}"                                                                                                                                                               \
		"${_DIRS_HGFS:?}"                                                                                                                                                               \
		"${_DIRS_HTML:?}"                                                                                                                                                               \
		"${_DIRS_SAMB:?}"/{adm/{commands,profiles},pub/{contents/{disc,dlna/{movies,others,photos,sounds}},resource/{image/{linux,windows},source/git},software,hardware,_license},usr} \
		"${_DIRS_TFTP:?}"/{boot/grub/{fonts,i386-{efi,pc},locale,x86_64-efi},ipxe,menu-{bios,efi64}/pxelinux.cfg}                                                                       \
		"${_DIRS_USER:?}"                                                                                                                                                               \
		"${_DIRS_SHAR:?}"                                                                                                                                                               \
		"${_DIRS_CONF:?}"/{agama,autoyast,kickstart,nocloud,preseed,script,windows}                                                                                                     \
		"${_DIRS_DATA:?}"                                                                                                                                                               \
		"${_DIRS_KEYS:?}"                                                                                                                                                               \
		"${_DIRS_TMPL:?}"                                                                                                                                                               \
		"${_DIRS_SHEL:?}"                                                                                                                                                               \
		"${_DIRS_IMGS:?}"                                                                                                                                                               \
		"${_DIRS_ISOS:?}"                                                                                                                                                               \
		"${_DIRS_LOAD:?}"                                                                                                                                                               \
		"${_DIRS_RMAK:?}"                                                                                                                                                               \
		"${_DIRS_CHRT:?}"                                                                                                                                                               \
	)
	readonly      _LIST_DIRS
	# --- symbolic link list --------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	_LIST_LINK=(                                                                                                                                                                        \
		"a  ${_DIRS_CONF:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_IMGS:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_ISOS:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_LOAD:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_RMAK:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_TFTP:?}                                     ${_DIRS_HTML:?}/"                                                                                                       \
		"a  ${_DIRS_CONF:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"a  ${_DIRS_IMGS:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"a  ${_DIRS_ISOS:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"a  ${_DIRS_LOAD:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"a  ${_DIRS_RMAK:?}                                     ${_DIRS_TFTP:?}/"                                                                                                       \
		"r  ${_DIRS_TFTP:?}/${_DIRS_CONF##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                                                                                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                                                                                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                                                                                             \
		"r  ${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}                   ${_DIRS_TFTP:?}/menu-bios/"                                                                                             \
		"r  ${_DIRS_TFTP:?}/menu-bios/syslinux.cfg              ${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"                                                                         \
		"r  ${_DIRS_TFTP:?}/${_DIRS_CONF##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                                                                                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                                                                                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                                                                                            \
		"r  ${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}                   ${_DIRS_TFTP:?}/menu-efi64/"                                                                                            \
		"r  ${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg             ${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"                                                                        \
	)
	readonly      _LIST_LINK
	# --- autoinstall configuration file --------------------------------------
	              _AUTO_INST="autoinst.cfg"
	readonly      _AUTO_INST
	# --- initial ram disk of mini.iso including preseed ----------------------
	              _MINI_IRAM="initps.gz"
	readonly      _MINI_IRAM
	# --- ipxe menu file ------------------------------------------------------
	              _MENU_IPXE="${_DIRS_TFTP}/autoexec.ipxe"
	readonly      _MENU_IPXE
	# --- grub menu file ------------------------------------------------------
	              _MENU_GRUB="${_DIRS_TFTP}/boot/grub/grub.cfg"
	readonly      _MENU_GRUB
	# --- syslinux menu file --------------------------------------------------
	              _MENU_SLNX="${_DIRS_TFTP}/menu-bios/syslinux.cfg"
	readonly      _MENU_SLNX
	              _MENU_UEFI="${_DIRS_TFTP}/menu-efi64/syslinux.cfg"
	readonly      _MENU_UEFI
}

# -----------------------------------------------------------------------------
# descript: create common configuration file
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_conf() {
	fnDebugout ""
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -r    __TMPL="${_PATH_CONF:?}.template"
	declare       __RNAM=""				# rename path
	declare       __PATH=""				# full path
	# --- option parameter ----------------------------------------------------
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			create) shift; break;;
			*     ) __NAME_REFR="${*:-}"; return;;
		esac
	done
	__NAME_REFR="${*:-}"
	# --- check file exists ---------------------------------------------------
	if [[ -f "${__TMPL:?}" ]]; then
		__RNAM="${__TMPL}.$(TZ=UTC find "${__TMPL}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		mv "${__TMPL}" "${__RNAM}"
	fi
	# --- delete old files ----------------------------------------------------
	for __PATH in $(find "${__TMPL%/*}" -name "${__TMPL##*/}"\* | sort -r | tail -n +3 || true)
	do
		rm -f "${__PATH:?}"
	done
	# --- exporting files -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TMPL}" || true
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
		DIRS_CHRT="${_DIRS_CHRT//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"		# container file

		# --- common data file --------------------------------------------------------
		#PATH_CONF="${_PATH_CONF//"${_DIRS_DATA}"/:_DIRS_DATA_:}"	# common configuration file (this file)
		PATH_MDIA="${_PATH_MDIA//"${_DIRS_DATA}"/:_DIRS_DATA_:}"		# media data file
		PATH_DSTP="${_PATH_DSTP//"${_DIRS_DATA}"/:_DIRS_DATA_:}"	# debstrap data file

		# --- pre-configuration file templates ----------------------------------------
		CONF_KICK="${_CONF_KICK//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for rhel
		CONF_CLUD="${_CONF_CLUD//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"		# for ubuntu cloud-init
		CONF_SEDD="${_CONF_SEDD//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for debian
		CONF_SEDU="${_CONF_SEDU//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for ubuntu
		CONF_YAST="${_CONF_YAST//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"		# for opensuse autoyast
		CONF_AGMA="${_CONF_AGMA//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"	# for opensuse agama

		# --- shell script ------------------------------------------------------------
		SHEL_ERLY="${_SHEL_ERLY//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run early
		SHEL_LATE="${_SHEL_LATE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run late
		SHEL_PART="${_SHEL_PART//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run after partition
		SHEL_RUNS="${_SHEL_RUNS//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"	# run preseed/run

		# --- tftp / web server network parameter -------------------------------------
		SRVR_HTTP="${_SRVR_HTTP:-}"						# server connection protocol (http or https)
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
		NTPS_ADDR="ntp.nict.jp"				    # ntp server address
		NTPS_IPV4="61.205.120.130"		    	# ntp server ipv4 address

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

# -----------------------------------------------------------------------------
# descript: create directory
#   n-ref :   $1   : return value : options
#   input :   $@   : input vale
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_directory() {
	fnDebugout ""
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -r    __DATE="$(date +"%Y%m%d%H%M%S")"
	declare       __FORC=""				# force parameter
	declare       __RTIV=""				# add/relative flag
	declare       __TGET=""				# taget path
	declare       __LINK=""				# symlink path
	declare       __BACK=""				# backup path
	declare -a    __LIST=()				# work variable
	declare -i    I=0
	# --- option parameter ----------------------------------------------------
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			create) shift; __FORC="true"; break;;
			update) shift; __FORC=""; break;;
			*     ) __NAME_REFR="${*:-}"; return;;
		esac
	done
	__NAME_REFR="${*:-}"
	# --- create directory ----------------------------------------------------
	mkdir -p "${_LIST_DIRS[@]:?}"
	# --- create symbolic link ------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	for I in "${!_LIST_LINK[@]}"
	do
		read -r -a __LIST < <(echo "${_LIST_LINK[I]}")
		case "${__LIST[0]}" in
			a) ;;
			r) ;;
			*) continue;;
		esac
		__RTIV="${__LIST[0]}"
		__TGET="${__LIST[1]:-}"
		__LINK="${__LIST[2]:-}"
		# --- check target file path ------------------------------------------
		if [[ -z "${__LINK##*/}" ]]; then
			__LINK="${__LINK%/}/${__TGET##*/}"
#		else
#			if [[ ! -e "${__TGET}" ]]; then
#				touch "${__TGET}"
#			fi
		fi
		# --- check target directory ------------------------------------------
		if [[ -z "${__TGET##*/}" ]] && [[ ! -e "${__TGET%%/}"/. ]]; then
			fnPrintf "%20.20s: %s" "create directory" "${__TGET%%/}"
			mkdir -p "${__TGET%%/}"
		fi
		# --- force parameter -------------------------------------------------
#		__BACK="${__LINK}.back.${__DATE}"
#		if [[ -n "${__FORC:-}" ]] && [[ -e "${__LINK}" ]] && [[ ! -e "${__BACK##*/}" ]]; then
#			fnPrintf "%20.20s: %s" "move symlink" "${__LINK} -> ${__BACK##*/}"
#			mv "${__LINK}" "${__BACK}"
#		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${__LINK}" ]]; then
			fnPrintf "%20.20s: %s" "exist symlink" "${__LINK}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${__LINK}/." ]]; then
			fnPrintf "%20.20s: %s" "exist directory" "${__LINK}"
			fnPrintf "%20.20s: %s" "move directory" "${__LINK} -> ${__BACK}"
			mv "${__LINK}" "${__BACK}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${__LINK%/*}"
		# --- create symbolic link --------------------------------------------
		fnPrintf "%20.20s: %s" "create symlink" "${__TGET} -> ${__LINK}"
		case "${__RTIV}" in
			r) ln -sr "${__TGET}" "${__LINK}";;
			*) ln -s  "${__TGET}" "${__LINK}";;
		esac
	done
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
		case "${__LIST[1]}" in
			o) ;;
			*) continue;;
		esac
		case "${__LIST[13]}" in
			-) continue;;
			*) ;;
		esac
		case "${__LIST[25]}" in
			-) continue;;
			*) ;;
		esac
		__TGET="${__LIST[25]}/${__LIST[13]##*/}"
		__LINK="${__LIST[13]}"
		# --- check target file path ------------------------------------------
#		if [[ ! -e "${__TGET}" ]]; then
#			touch "${__TGET}"
#		fi
		# --- check target directory ------------------------------------------
		if [[ -n "${__LIST[25]##*-}" ]] && [[ ! -e "${__LIST[25]}"/. ]]; then
			fnPrintf "%20.20s: %s" "create directory" "${__LIST[25]}"
			mkdir -p "${__LIST[25]}"
		fi
		# --- force parameter -------------------------------------------------
#		__BACK="${__LINK}.back.${__DATE}"
#		if [[ -n "${__FORC:-}" ]] && [[ -e "${__LINK}" ]] && [[ ! -e "${__BACK##*/}" ]]; then
#			fnPrintf "%20.20s: %s" "move symlink" "${__LINK} -> ${__BACK##*/}"
#			mv "${__LINK}" "${__BACK}"
#		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${__LINK}" ]]; then
			fnPrintf "%20.20s: %s" "exist symlink" "${__LINK}"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${__LINK}/." ]]; then
			fnPrintf "%20.20s: %s" "exist directory" "${__LINK}"
			fnPrintf "%20.20s: %s" "move directory" "${__LINK} -> ${__BACK}"
			mv "${__LINK}" "${__BACK}"
		fi
		# --- create destination directory ------------------------------------
		mkdir -p "${__LINK%/*}"
		# --- create symbolic link --------------------------------------------
		fnPrintf "%20.20s: %s" "create symlink" "${__TGET} -> ${__LINK}"
		ln -s "${__TGET}" "${__LINK}"
	done
}
