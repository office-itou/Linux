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
	_SRVR_HTTP="${_SRVR_HTTP:-http}"
	_SRVR_PROT="${_SRVR_PROT:-"${_SRVR_HTTP}"}"
	_SRVR_NICS="${_SRVR_NICS:-"$(LANG=C ip -0 -brief address show scope global | awk '$1!="lo" {print $1;}' || true)"}"
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
#			PATH_CONF) _PATH_CONF="${__VALU:-"${_PATH_CONF:-}"}";;
			PATH_MDIA) _PATH_MDIA="${__VALU:-"${_PATH_MDIA:-}"}";;
			CONF_KICK) _CONF_KICK="${__VALU:-"${_CONF_KICK:-}"}";;
			CONF_CLUD) _CONF_CLUD="${__VALU:-"${_CONF_CLUD:-}"}";;
			CONF_SEDD) _CONF_SEDD="${__VALU:-"${_CONF_SEDD:-}"}";;
			CONF_SEDU) _CONF_SEDU="${__VALU:-"${_CONF_SEDU:-}"}";;
			CONF_YAST) _CONF_YAST="${__VALU:-"${_CONF_YAST:-}"}";;
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
#	readonly      _PATH_CONF
	readonly      _PATH_MDIA
	readonly      _CONF_KICK
	readonly      _CONF_CLUD
	readonly      _CONF_SEDD
	readonly      _CONF_SEDU
	readonly      _CONF_YAST
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
	# --- get media data ------------------------------------------------------
	fnGet_media_data
}

# -----------------------------------------------------------------------------
# descript: create common configuration file
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
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
# descript: get media data
#   input :        : unused
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317
function fnGet_media_data() {
	declare       __PATH=""				# full path
	declare       __LINE=""				# work variable
	# --- list data -----------------------------------------------------------
	_LIST_MDIA=()
	for __PATH in \
		"${PWD:+"${PWD}/${_PATH_MDIA##*/}"}" \
		"${_PATH_MDIA}"
	do
		if [[ ! -s "${__PATH}" ]]; then
			continue
		fi
		while IFS=$'\n' read -r __LINE
		do
			__LINE="${__LINE//:_DIRS_TOPS_:/"${_DIRS_TOPS}"}"
			__LINE="${__LINE//:_DIRS_HGFS_:/"${_DIRS_HGFS}"}"
			__LINE="${__LINE//:_DIRS_HTML_:/"${_DIRS_HTML}"}"
			__LINE="${__LINE//:_DIRS_SAMB_:/"${_DIRS_SAMB}"}"
			__LINE="${__LINE//:_DIRS_TFTP_:/"${_DIRS_TFTP}"}"
			__LINE="${__LINE//:_DIRS_USER_:/"${_DIRS_USER}"}"
			__LINE="${__LINE//:_DIRS_SHAR_:/"${_DIRS_SHAR}"}"
			__LINE="${__LINE//:_DIRS_CONF_:/"${_DIRS_CONF}"}"
			__LINE="${__LINE//:_DIRS_DATA_:/"${_DIRS_DATA}"}"
			__LINE="${__LINE//:_DIRS_KEYS_:/"${_DIRS_KEYS}"}"
			__LINE="${__LINE//:_DIRS_TMPL_:/"${_DIRS_TMPL}"}"
			__LINE="${__LINE//:_DIRS_SHEL_:/"${_DIRS_SHEL}"}"
			__LINE="${__LINE//:_DIRS_IMGS_:/"${_DIRS_IMGS}"}"
			__LINE="${__LINE//:_DIRS_ISOS_:/"${_DIRS_ISOS}"}"
			__LINE="${__LINE//:_DIRS_LOAD_:/"${_DIRS_LOAD}"}"
			__LINE="${__LINE//:_DIRS_RMAK_:/"${_DIRS_RMAK}"}"
			_LIST_MDIA+=("${__LINE}")
		done < "${__PATH:?}"
		if [[ -n "${_DBGS_FLAG:-}" ]]; then
			printf "[%-$((${_SIZE_COLS:-80}-2)).$((${_SIZE_COLS:-80}-2))s]\n" "${_LIST_MDIA[@]}" 1>&2
		fi
		break
	done
	if [[ -z "${_LIST_MDIA[*]}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[91m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "data file not found: [${_PATH_MDIA}]" 1>&2
#		exit 1
	fi
}

# -----------------------------------------------------------------------------
# descript: put media data
#   input :        : unused
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317
function fnPut_media_data() {
	declare       __RNAM=""				# rename path
	declare       __LINE=""				# work variable
	declare -a    __LIST=()				# work variable
	declare -i    I=0
#	declare -i    J=0
	# --- check file exists ---------------------------------------------------
	if [[ -f "${_PATH_MDIA:?}" ]]; then
		__RNAM="${_PATH_MDIA}.$(TZ=UTC find "${_PATH_MDIA}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
		printf "%s: \"%s\"\n" "backup" "${__RNAM}" 1>&2
		cp -a "${_PATH_MDIA}" "${__RNAM}"
	fi
	# --- delete old files ----------------------------------------------------
	while read -r __PATH
	do
		printf "%s: \"%s\"\n" "remove" "${__PATH}" 1>&2
		rm -f "${__PATH:?}"
	done < <(find "${_PATH_MDIA%/*}" -name "${_PATH_MDIA##*/}.[0-9]*" | sort -r | tail -n +3  || true)
	# --- list data -----------------------------------------------------------
	for I in "${!_LIST_MDIA[@]}"
	do
		__LINE="${_LIST_MDIA[I]}"
		__LINE="${__LINE//"${_DIRS_RMAK}"/:_DIRS_RMAK_:}"
		__LINE="${__LINE//"${_DIRS_LOAD}"/:_DIRS_LOAD_:}"
		__LINE="${__LINE//"${_DIRS_ISOS}"/:_DIRS_ISOS_:}"
		__LINE="${__LINE//"${_DIRS_IMGS}"/:_DIRS_IMGS_:}"
		__LINE="${__LINE//"${_DIRS_SHEL}"/:_DIRS_SHEL_:}"
		__LINE="${__LINE//"${_DIRS_TMPL}"/:_DIRS_TMPL_:}"
		__LINE="${__LINE//"${_DIRS_KEYS}"/:_DIRS_KEYS_:}"
		__LINE="${__LINE//"${_DIRS_DATA}"/:_DIRS_DATA_:}"
		__LINE="${__LINE//"${_DIRS_CONF}"/:_DIRS_CONF_:}"
		__LINE="${__LINE//"${_DIRS_SHAR}"/:_DIRS_SHAR_:}"
		__LINE="${__LINE//"${_DIRS_USER}"/:_DIRS_USER_:}"
		__LINE="${__LINE//"${_DIRS_TFTP}"/:_DIRS_TFTP_:}"
		__LINE="${__LINE//"${_DIRS_SAMB}"/:_DIRS_SAMB_:}"
		__LINE="${__LINE//"${_DIRS_HTML}"/:_DIRS_HTML_:}"
		__LINE="${__LINE//"${_DIRS_HGFS}"/:_DIRS_HGFS_:}"
		__LINE="${__LINE//"${_DIRS_TOPS}"/:_DIRS_TOPS_:}"
		read -r -a __LIST < <(echo "${__LINE}")
#		for J in "${!__LIST[@]}"
#		do
#			__LIST[J]="${__LIST[J]:--}"		# empty
#			__LIST[J]="${__LIST[J]// /%20}"	# space
#		done
		printf "%-11s %-3s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-85s %-47s %-15s %-43s %-85s %-47s %-15s %-43s %-85s %-85s %-85s %-47s %-85s %-3s\n" \
			"${__LIST[@]}"
	done > "${_PATH_MDIA:?}"
}

# -----------------------------------------------------------------------------
# descript: create directory
#   n-ref :   $1   : return value : options
#   input :   $@   : input vale
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317
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

# --- media information [new] -------------------------------------------------
#  0: type          ( 11)   TEXT           NOT NULL     media type
#  1: entry_flag    (  3)   TEXT           NOT NULL     [m] menu, [o] output, [else] hidden
#  2: entry_name    ( 39)   TEXT           NOT NULL     entry name (unique)
#  3: entry_disp    ( 39)   TEXT           NOT NULL     entry name for display
#  4: version       ( 23)   TEXT                        version id
#  5: latest        ( 23)   TEXT                        latest version
#  6: release       ( 15)   TEXT                        release date
#  7: support       ( 15)   TEXT                        support end date
#  8: web_regexp    (143)   TEXT                        web file  regexp
#  9: web_path      (143)   TEXT                        "         path
# 10: web_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 11: web_size      ( 15)   BIGINT                      "         file size
# 12: web_status    ( 15)   TEXT                        "         download status
# 13: iso_path      ( 85)   TEXT                        iso image file path
# 14: iso_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 15: iso_size      ( 15)   BIGINT          "           file size
# 16: iso_volume    ( 43)   TEXT            "           volume id
# 17: rmk_path      ( 85)   TEXT            remaster    file path
# 18: rmk_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 19: rmk_size      ( 15)   BIGINT                      "         file size
# 20: rmk_volume    ( 43)   TEXT                        "         volume id
# 21: ldr_initrd    ( 85)   TEXT                        initrd    file path
# 22: ldr_kernel    ( 85)   TEXT                        kernel    file path
# 23: cfg_path      ( 85)   TEXT                        config    file path
# 24: cfg_tstamp    ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
# 25: lnk_path      ( 85)   TEXT                        symlink   directory or file path
# 26: create_flag   (  3)   TEXT                        create flag

# -----------------------------------------------------------------------------
# descript: create preseed.cfg
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317
function fnCreate_preseed() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_SEDD}" "${__TGET_PATH}"
	# --- by generation -------------------------------------------------------
	case "${__TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"               \
			    -e '/packages:/a \    usrmerge '\\
			;;
		*)	;;
	esac
	case "${__TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${__TGET_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"               \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop*)
			sed -i "${__TGET_PATH}"                                              \
			    -e '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+%,\%^#.*[^\\]$% { ' \
			    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                  \
			    -e 's/^#/ /g                                                }'
			;;
		*)	;;
	esac
	# --- for ubiquity --------------------------------------------------------
	case "${__TGET_PATH}" in
		*_ubiquity_*)
			IFS= __WORK=$(
				sed -n '\%^[^#].*preseed/late_command%,\%[^\\]$%p' "${__TGET_PATH}" | \
				sed -e 's/\\/\\\\/g'                                                  \
				    -e 's/d-i/ubiquity/'                                              \
				    -e 's%preseed\/late_command%ubiquity\/success_command%'         | \
				sed -e ':l; N; s/\n/\\n/; b l;' || true
			)
			if [[ -n "${__WORK}" ]]; then
				sed -i "${__TGET_PATH}"                                  \
				    -e '\%^[^#].*preseed/late_command%,\%[^\\]$%     { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } ' \
				    -e '\%^[^#].*ubiquity/success_command%,\%[^\\]$% { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } '
				sed -i "${__TGET_PATH}"                                  \
				    -e "\%ubiquity/success_command%i \\${__WORK}"
			fi
			sed -i "${__TGET_PATH}"                       \
			    -e "\%ubiquity/download_updates% s/^#/ /" \
			    -e "\%ubiquity/use_nonfree%      s/^#/ /" \
			    -e "\%ubiquity/reboot%           s/^#/ /"
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}"
}

# -----------------------------------------------------------------------------
# descript: create nocloud
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317
function fnCreate_nocloud() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_CLUD}" "${__TGET_PATH}"
	# --- by generation -------------------------------------------------------
	case "${__TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"              \
			    -e '/packages:/a \    usrmerge '
			;;
		*)	;;
	esac
	case "${__TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${__TGET_PATH}"              \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"              \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop*)
			sed -i "${__TGET_PATH}"                                            \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	touch -m "${__DIRS}/meta-data"      --reference "${__TGET_PATH}"
	touch -m "${__DIRS}/network-config" --reference "${__TGET_PATH}"
#	touch -m "${__DIRS}/user-data"      --reference "${__TGET_PATH}"
	touch -m "${__DIRS}/vendor-data"    --reference "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	chmod --recursive ugo-x "${__DIRS}"
}

# -----------------------------------------------------------------------------
# descript: create kickstart.cfg
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317
function fnCreate_kickstart() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	declare       __NAME=""				# "            name
	declare       __SECT=""				# "            section
	declare -r    __ARCH="x86_64"		# base architecture
	declare -r    __ADDR="${_SRVR_PROT:+"${_SRVR_PROT}:/"}/${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}"
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_KICK}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
#	__NUMS="\$releasever"
	__VERS="${__TGET_PATH#*_}"
	__VERS="${__VERS%%_*}"
	__NUMS="${__VERS##*-}"
	__NAME="${__VERS%-*}"
	__SECT="${__NAME/-/ }"
	# --- initializing the settings -------------------------------------------
	sed -i "${__TGET_PATH}"                     \
	    -e "/^cdrom$/      s/^/#/             " \
	    -e "/^url[ \t]\+/  s/^/#/g            " \
	    -e "/^repo[ \t]\+/ s/^/#/g            " \
	    -e "s/:_HOST_NAME_:/${__NAME}/        " \
	    -e "s%:_WEBS_ADDR_:%${__ADDR}%g       " \
	    -e "s%:_DISTRO_:%${__NAME}-${__NUMS}%g"
	# --- cdrom, repository ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_dvd*)		# --- cdrom install ---------------------------------------
			sed -i "${__TGET_PATH}"    \
			    -e "/^#cdrom$/ s/^#//"
			;;
		*_net*)		# --- network install -------------------------------------
			sed -i "${__TGET_PATH}"               \
			    -e "/^#.*(${__SECT}).*$/,/^$/ { " \
			    -e "/^#url[ \t]\+/  s/^#//g     " \
			    -e "/^#repo[ \t]\+/ s/^#//g   } "
			;;
		*_web*)		# --- network install [ for pxeboot ] ---------------------
			sed -i "${__TGET_PATH}"                 \
			    -e "/^#.*(web address).*$/,/^$/ { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g    } "
			;;
		*)	;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e "/%packages/,/%end/ {"                      \
	    -e "/desktop/ s/^-//g  }"                      \
	    "${__TGET_PATH}"                               \
	>   "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}" "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
}

# -----------------------------------------------------------------------------
# descript: create autoyast.xml
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317
function fnCreate_autoyast() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_YAST}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__VERS="${__TGET_PATH#*_}"
	__VERS="${__VERS%%_*}"
	__NUMS="${__VERS##*-}"
	# --- by media ------------------------------------------------------------
	case "${__TGET_PATH}" in
		*_web*|\
		*_dvd*)
			sed -i "${__TGET_PATH}"                                   \
			    -e '/<image_installation t="boolean">/ s/false/true/'
			;;
		*)
			sed -i "${__TGET_PATH}"                                   \
			    -e '/<image_installation t="boolean">/ s/true/false/'
			;;
	esac
	# --- by version ----------------------------------------------------------
	case "${__TGET_PATH}" in
		*tumbleweed*)
			sed -i "${__TGET_PATH}"                                    \
			    -e '\%<add_on_products .*>%,\%<\/add_on_products>% { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/             { ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                  } ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                 } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1openSUSE\2%    '
			;;
		*           )
			sed -i "${__TGET_PATH}"                                          \
			    -e '\%<add_on_products .*>%,\%</add_on_products>%        { ' \
			    -e '/<!-- leap/,/leap -->/                               { ' \
			    -e "/<media_url>/ s%/\(leap\)/[0-9.]\+/%/\1/${__NUMS}/%g } " \
			    -e '/<!-- leap$/ s/$/ -->/g                                ' \
			    -e '/^leap -->/  s/^/<!-- /g                             } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1Leap\2%              '
			;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e '/<!-- desktop lxde$/ s/$/ -->/g '          \
	    -e '/^desktop lxde -->/  s/^/<!-- /g'          \
	    "${__TGET_PATH}"                               \
	>   "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}"
}

# -----------------------------------------------------------------------------
# descript: create pre-configuration file templates
#   n-ref :   $1   : return value : options
#   input :   $@   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317
function fnCreate_precon() {
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -a    __OPTN=()				# option parameter
	declare -a    __LIST=()				# data list
	declare       __PATH=""				# full path
	declare       __TYPE=""				# configuration type
#	declare       __WORK=""				# work variables
	declare -a    __LINE=()				# work variable
	declare -i    I=0					# work variables
	# --- option parameter ----------------------------------------------------
	__OPTN=()
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			all      ) shift; __OPTN+=("preseed" "nocloud" "kickstart" "autoyast"); break;;
			preseed  | \
			nocloud  | \
			kickstart| \
			autoyast ) ;;
			*        ) break;;
		esac
		__OPTN+=("$1")
		shift
	done
	__NAME_REFR="${*:-}"
	if [[ -z "${__OPTN[*]}" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create pre-conf file" ""
	# -------------------------------------------------------------------------
	__LIST=()
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a __LINE < <(echo "${_LIST_MDIA[I]}")
		case "${__LINE[1]}" in			# entry_flag
			o) ;;
			*) continue;;
		esac
		case "${__LINE[23]##*/}" in		# cfg_path
			-) continue;;
			*) ;;
		esac
		__PATH="${__LINE[23]}"
		__TYPE="${__PATH%/*}"
		__TYPE="${__TYPE##*/}"
		if ! echo "${__OPTN[*]}" | grep -q "${__TYPE}"; then
			continue
		fi
		__LIST+=("${__PATH}")
		case "${__PATH}" in
			*dvd.*) __LIST+=("${__PATH/_dvd/_web}");;
			*)	;;
		esac
	done
	IFS= mapfile -d $'\n' -t __LIST < <(IFS=  printf "%s\n" "${__LIST[@]}" | sort -Vu || true)
	# -------------------------------------------------------------------------
	for __PATH in "${__LIST[@]}"
	do
		__TYPE="${__PATH%/*}"
		__TYPE="${__TYPE##*/}"
		case "${__TYPE}" in
			preseed  ) fnCreate_preseed   "${__PATH}";;
			nocloud  ) fnCreate_nocloud   "${__PATH}/user-data";;
			kickstart) fnCreate_kickstart "${__PATH}";;
			autoyast ) fnCreate_autoyast  "${__PATH}";;
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
